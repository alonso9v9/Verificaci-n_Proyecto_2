#!/usr/bin/env bash

##################################################################################
# Title:        synopsys_tools.sh
# Description:  Punteros a ejecutables herramientas de Synopsys y la tecnonologia
#               xh018 de XFAB
# Dependencies: Ninguna.
# Project:	TECRISCV
# Author:       Reinaldo Castro Gonzalez (RCG)       
# Institution:  Instituto Tecnologico de Costa Rica. DCILab.                                    
# Date:         21 de Marzo de 2018                                                                   
# Notes:	Actualizado por Alfonso Chacon Rodriguez (ACR)
# Version:      2.2                                                                             
# Revision:     28/08/2018                                                              
#		
#		(ACR).	Se actualiza ICC, DC, PrimeTime, MilkyWay 28/08/2018
#		(ACR).	Se actualiza ICValidator, StarRC, DC, ICC, Custom_Compiler,
#			WaveView, VCS, HSPICE.
#		(ACR).	Se actualizan a versiones 7.0 ICV, PDK, celdas estandar
#		(ACR).	Se actualiza a v2.0.2 kit A/MS por error en PEX, LVS
#		(ACR).	Se actualizan herramientas 2016, 2017
#		(ACR).	Se actualizan herramientas 2015, kits AMS XH018 de XFAB
#		(ACR).	Se actualizan herramientas 2014, kits de XFAB
#		(RCG).  Se annade la variable SNPSLMD_QUEUE. 
#
##################################################################################

# Bash para definir caminos a las herramientas de Synopsys. Actualizado al 20-03-2018 (ACR).

# Direccion de la licencia
SNPSLMD_LICENSE_FILE=27000@172.21.9.211; # Es importante verificar con el tecnico si el archivo 
					  # de la licencia se encuentra en esta direccion
SNPSLMD_QUEUE=TRUE;	# Variable de ambiente para que Synopsys espere la validacion de las 
			# todas las licencias solicitadas.
export SNPSLMD_QUEUE
export SNPSLMD_LICENSE_FILE 

SYNOPSYS_HOME=/mnt/vol_NFS_Zener/tools/synopsys/apps
export SYNOPSYS_HOME

# La siguiente variable es necesaria para la aplicacion Tetramax de Synopsys
SYNOPSYS=/mnt/vol_NFS_Zener/tools/synopsys/apps/syn2/N-2017.09-SP4
export SYNOPSYS

######### Variables para el PyCells Studio, OA cell lybrary ######
CNI_ROOT=$SYNOPSYS_HOME/PyCell_Studio/N-2017.12_Py262;
export CNI_ROOT

#############################################################################
### Variables de ruta para las aplicaciones de diseño Custom de Synopsys ####
#############################################################################

## Custom Compiler
PATH=$PATH:${SYNOPSYS_HOME}/customcompiler/N-2017.12-3/bin
export PATH

## WaveViewer
PATH=$PATH:${SYNOPSYS_HOME}/wv/N-2017.12-1/bin
export PATH

## ICValidator
ICV_HOME_DIR=${SYNOPSYS_HOME}/icvalidator/N-2017.12-SP1-2
export ICV_HOME_DIR
PATH=$PATH:${ICV_HOME_DIR}/bin/LINUX.64
export PATH

## HSPICE
PATH=$PATH:${SYNOPSYS_HOME}/hspice/M-2017.03/hspice/bin
export PATH

## StarRC
PATH=$PATH:${SYNOPSYS_HOME}/starrc/M-2017.06-SP3/bin 
export PATH

## XA CustomSim
PATH=$PATH:${SYNOPSYS_HOME}/custom_sim/xa/N-2017.12-SP1/bin
export PATH

################ Kit xh018 de XFAB, AMS ##################
##   Version v2_0_12 Custom Compiler Kit,  v7.0 xh018   ##
##########################################################

FTK_KIT_DIR=/mnt/vol_NFS_Zener/tools/synopsys/pdks/xh018-ams/XFAB_snps_CustomDesigner_kit_v2_1_0
export FTK_KIT_DIR

# A continuacion se debe definir la ruta al disenno, dentro del directorio base de su proyecto
# con una variable propia. Luego descomente las siguientes 2 lineas.

# DESIGN_HOME=/.../<ruta_absoluta_al_directorio_base_de_su_proyecto>/
# export DESIGN_HOME

# Se define un machote de configuracion para las simulaciones de su proyecto. Descomentar
# las siguientes 2 lineas una vez haya definido la variable DESIGN_HOME

# SYNOPSYS_SIM_SETUP=$DESIGN_HOME/synopsys_sim.setup
# export SYNOPSYS_SIM_SETUP

# Desactive el siguiente comentario; solo cuando ya tenga la biblioteca instalada. Para uso exclusivo de (ACR).
# source $CNI_ROOT/quickstart/bashrc 

# Se define el editor de texto para CustomCompiler. Puede re-emplazarlo por "nano", "vim" o cualquier
# editor de su preferencia.

EDITOR=gedit;
export EDITOR

### Ruta para correr el XLIBD (visor de datos tecnologia XFAB) ############

XLIBD_RUN=$FTK_KIT_DIR/x_all/utilities/XLIBD/v2_0/bin/linux_x86_64/v2_0_3
export XLIBD_RUN

#PARA Ejectuar el xlibd correr en la terminal source $XLIBD_RUN/xlibd.csh


##################################################################################
### Variables de ruta para las aplicaciones de disenno Semi-Custom de Synopsys ###
##################################################################################

## Design Compiler
PATH=$PATH:$SYNOPSYS_HOME/syn2/N-2017.09-SP4/bin/
export PATH

## IC Compiler
PATH=$PATH:${SYNOPSYS_HOME}/icc2/N-2017.09-SP4/bin
export PATH

## Tetramax | Herramienta para ATPG
PATH=$PATH:$SYNOPSYS/linux64/syn/bin
export PATH

## Prime Time
PATH=$PATH:${SYNOPSYS_HOME}/pts2/N-2017.12-SP2/bin     
export PATH

## Milkyway
PATH=$PATH:${SYNOPSYS_HOME}/mw2/N-2017.09-SP1/bin    
export PATH

### Library Compiler
PATH=$PATH:$SYNOPSYS_HOME/lc/M-2017.06-SP2/linux64/syn/bin
export PATH

###  Nueva version de VCS Mixed, 64 bits
VCS_HOME=${SYNOPSYS_HOME}/vcs-mx2/M-2017.03-SP2-5
export VCS_HOME
PATH=$PATH:${VCS_HOME}/bin
export PATH

