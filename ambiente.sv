
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


class ambiente #(parameter pckg_sz =16,parameter disps =16,parameter fifo_depth=10);
  
  driver #(.pckg_sz(pckg_sz),.disps(disps),.Fif_Size(fifo_depth)) driver_inst;
  read_dvc #(.pckg_sz(pckg_sz));
  Generador_Agent #(.pckg_sz(pckg_sz)) aGen_inst; 

  
  // Declaración de la interface que conecta el DUT 
  virtual fifo_if  #(.width(width)) _if;

  //declaración de los mailboxes
  trans_fifo_mbx agnt_drv_mbx;           //mailbox del agente al driver
  trans_fifo_mbx drv_chkr_mbx;           //mailbox del driver al checher
  trans_sb_mbx chkr_sb_mbx;              //mailbox del checker al scoreboard
  comando_test_sb_mbx test_sb_mbx;       //mailbox del test al scoreboard
  comando_test_agent_mbx test_agent_mbx; //mailbox del test al agente

  function new();
    // Instanciación de los mailboxes
    drv_chkr_mbx   = new();
    agnt_drv_mbx   = new();
    chkr_sb_mbx    = new();
    test_sb_mbx    = new();
    test_agent_mbx = new();

    // instanciación de los componentes del ambiente
    driver_inst     = new();
    checker_inst    = new();
    scoreboard_inst = new();
    agent_inst      = new();
    // conexion de las interfaces y mailboxes en el ambiente
    driver_inst.vif             = _if;
    driver_inst.drv_chkr_mbx    = drv_chkr_mbx;
    driver_inst.agnt_drv_mbx    = agnt_drv_mbx;
    checker_inst.drv_chkr_mbx   = drv_chkr_mbx;
    checker_inst.chkr_sb_mbx    = chkr_sb_mbx;
    scoreboard_inst.chkr_sb_mbx = chkr_sb_mbx;
    scoreboard_inst.test_sb_mbx = test_sb_mbx;
    agent_inst.test_agent_mbx   = test_agent_mbx;
    agent_inst.agnt_drv_mbx = agnt_drv_mbx;
  endfunction

  virtual task run();
    $display("[%g]  El ambiente fue inicializado",$time);
    fork
      driver_inst.run();
      checker_inst.run();
      scoreboard_inst.run();
      agent_inst.run();
    join_none
  endtask 
endclass