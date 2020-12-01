    
// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog
// 
// Unidad:
// Ambiente
//
// Propósito General:
// Instanciar,conectar y ejecutar en paralelo cada una 
// de las unidades individuales del testbench


class ambiente #(parameter pckg_sz =64,parameter disps =16,parameter fifo_depth=10);
  
  driver #(.pckg_sz(pckg_sz),.disps(disps),.Fif_Size(fifo_depth)) driver_inst;
  disp #(.pckg_sz(pckg_sz),.Fif_Size(fifo_depth)) disp_inst [disps];
  monitor #(.pckg_sz(pckg_sz)) monitor_inst;
  Generador_Agent #(.pckg_sz(pckg_sz)) aGen_inst; 

  // Declaración de la interface que conecta el DUT 
  virtual intfz #(.pckg_sz(pckg_sz)) _if;

  //declaración de los mailboxes
  mlbx_aGENte_drv     aGENte_drv_mbx;         //mailbox del agente al driver
  mlbx_drv_disp  drv_disp_mbx[disps];        //mailbox del 
  mlbx_aGENte_chckr aGENte_chckr_mbx;              
  mlbx_top_aGENte     top_aGENte_mbx;

  function new();
    // Instanciación de los mailboxes
    aGENte_drv_mbx      = new();
    aGENte_chckr_mbx    = new();
    top_aGENte_mbx      = new();

    foreach(drv_disp_mbx[i]) begin
      drv_disp_mbx[i] = new();
    end


    // instanciación de los componentes del ambiente
    driver_inst         = new();
    monitor_inst        = new();
    aGen_inst           = new();

    foreach(disp_inst [i]) begin
      disp_inst [i]=new();
    end


    // conexion de las interfaces y mailboxes en el ambiente

    driver_inst.aGENte_drv_mbx0 = aGENte_drv_mbx;

    aGen_inst.mlbx_aGENte_drv0  = aGENte_drv_mbx;
    //aGen_inst.mlbx_aGENte_chckr0=;
    aGen_inst.mlbx_top_aGENte0  = top_aGENte_mbx;

    foreach(driver_inst.drv_disp_mbx[i]) begin
      driver_inst.drv_disp_mbx[i]=drv_disp_mbx[i];
    end
    foreach(drv_disp_mbx[i]) begin
      disp_inst[i].drv_disp_mbx=drv_disp_mbx[i];
    end


  endfunction

  virtual task run();


    driver_inst.vif  = _if;
    foreach(disp_inst[i]) begin
      disp_inst[i].vif = _if;
    end

    monitor_inst.vif =_if;
    $display("[%g]  El ambiente fue inicializado",$time);
    fork
      driver_inst.run();
      monitor_inst.run();
      aGen_inst.run();
      foreach (disp_inst[i]) begin
        automatic int var_i = i;
        fork
            disp_inst[var_i].id=var_i;
            disp_inst[var_i].run();
        join_none 
      end

    join_none
  endtask 
endclass