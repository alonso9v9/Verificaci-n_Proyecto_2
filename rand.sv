// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog


module random;
  
  class Params;
    int unsigned ROWS = 4; 
    int unsigned COLUMS =4; 
    rand int unsigned pckg_sz;
    rand int unsigned fifo_depth;
    bit bdcst= {8{1'b1}};

    constraint pckg {pckg_sz<100;pckg_sz>32}

    function void printPackage;
        automatic f = $fopen("Rand_Parameters.sv");
        $fdisplay(f, "package Rand_Parameters;");
        $fdisplay(f, "  parameter ROWS = %0d;",ROWS);
        $fdisplay(f, "  parameter COLUMS = %0d;",COLUMS);
        $fdisplay(f, "  parameter pckg_sz = %0d;",pckg_sz);
        $fdisplay(f, "  parameter fifo_depth = %0d;",fifo_depth);
        $fdisplay(f, "  parameter bdcst = %0b;",bdcst);
        $fdisplay(f, "endpackage");
    endfunction

  endclass

  Params a;
  
  initial begin
      a = new();
      a.randomize();
      a.printPackage();
  end

endmodule