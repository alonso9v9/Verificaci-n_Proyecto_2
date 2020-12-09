    
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


class ambiente #(parameter pckg_sz =40,parameter disps =16,parameter fifo_depth=10);
  
  // Módulos del ambiente
  driver #(.pckg_sz(pckg_sz),.disps(disps),.Fif_Size(fifo_depth)) driver_inst;
  disp #(.pckg_sz(pckg_sz),.Fif_Size(fifo_depth)) disp_inst [disps];
  monitor #(.pckg_sz(pckg_sz)) monitor_inst;
  Generador_Agent #(.pckg_sz(pckg_sz)) aGen_inst;
  Checker #(.ROWS(4), .COLUMS(4), .pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) chckr_inst;
  scoreboard #(.pckg_sz(pckg_sz)) sb_inst;

  // Declaración de la interfaz que conecta el DUT 
  virtual intfz #(.pckg_sz(pckg_sz)) _if;

  // Interfaz para conectar el emulador del DUT
  virtual intfz #(.pckg_sz(pckg_sz)) emu_if;

  // Declaración de los mailboxes
  mlbx_aGENte_drv     aGENte_drv_mbx;         // Mailbox del agente al driver
  mlbx_drv_disp  drv_disp_mbx[disps];         // Mailbox del controlador del driver a los dispositivos
  mlbx_drv_disp disp_chckr_mbx[disps];        // Mailbox de los disp al checker
  mlbx_aGENte_sb aGENte_sb_mbx;               // Mailbox del agente al scoreboard
  mlbx_top_aGENte     top_aGENte_mbx;         // Mailbox del test (Top) al agente
  mlbx_mntr_chckr chckr_mntr_mbx;             // Mailbox del monitor al checker
  mlbx_mntr_chckr chckr_sb_mbx;               // Mailbox del checker al scoreboard 

  function new();
    // Instanciación de los mailboxes
    aGENte_drv_mbx  = new();
    aGENte_sb_mbx   = new();
    top_aGENte_mbx  = new();
    chckr_sb_mbx    = new();
    chckr_mntr_mbx  = new();

    foreach(disp_chckr_mbx[i]) begin
      disp_chckr_mbx[i] = new();
    end

    foreach(drv_disp_mbx[i]) begin
      drv_disp_mbx[i] = new();
    end


    // instanciación de los componentes del ambiente
    driver_inst         = new();
    monitor_inst        = new();
    aGen_inst           = new();
    chckr_inst          = new();
    sb_inst             = new();

    foreach(disp_inst [i]) begin
      disp_inst [i]=new();
    end


    // conexion de las interfaces y mailboxes en el ambiente

    driver_inst.aGENte_drv_mbx0 = aGENte_drv_mbx;

    aGen_inst.mlbx_aGENte_drv0  = aGENte_drv_mbx;
    
    aGen_inst.mlbx_top_aGENte0  = top_aGENte_mbx;

    aGen_inst.mlbx_aGENte_sb0   = aGENte_sb_mbx;

    sb_inst.from_agnt_mlbx      = aGENte_sb_mbx;

    sb_inst.from_chckr_mlbx     = chckr_sb_mbx;

    chckr_inst.to_sb_mlbx       = chckr_sb_mbx;

    chckr_inst.from_mntr_mlbx   = chckr_mntr_mbx;

    monitor_inst.to_chckr_mlbx_p= chckr_mntr_mbx;

    foreach(driver_inst.drv_disp_mbx[i]) begin
      driver_inst.drv_disp_mbx[i]=drv_disp_mbx[i];
    end
    foreach(drv_disp_mbx[i]) begin
      disp_inst[i].drv_disp_mbx = drv_disp_mbx[i];
    end
    foreach(disp_chckr_mbx[i]) begin
      disp_inst[i].disp_chckr_mbx = disp_chckr_mbx[i];
    end      
    foreach(chckr_inst.from_drvr_mlbx[i]) begin
      chckr_inst.from_drvr_mlbx[i] = disp_chckr_mbx[i];
    end      
  endfunction

  virtual task run(event fin, event sb_done);

    driver_inst.vif  = _if;
    foreach(disp_inst[i]) begin
      disp_inst[i].vif = _if;
    end



    chckr_inst.vif = emu_if;

    monitor_inst.vif =_if;

    foreach(monitor_inst.dvcs[i]) begin
      monitor_inst.dvcs[i].vif = _if;
    end
    $display("[%g]  El ambiente fue inicializado",$time);
    fork
      driver_inst.run();
      monitor_inst.run();
      aGen_inst.run();
      sb_inst.run(fin, sb_done);
      chckr_inst.run(fin);
      // driver_inst.drvr_chckr_com();
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