// Curso: EL-5811 Verificación Funcional de Circuitos integrados
// Tecnologico de Costa Rica (www.tec.ac.cr)
// Profesor: Ronny García Ramírez 
// Desarrolladores:
// Felipe Josue Rojas-Barrantes (fjrojas.cr@gmail.com)
// José Agustín Delgado-Sancho (ahusjads@gmail.com)
// Luis Alonso Vega-Badilla (alonso9v9@gmail.com)
// Este script esta estructurado en System Verilog


module random; //modulo para generar parametros aleatorios
  
  class Params;
    bit [2:0]ROWS = 3'd4; 
    bit [2:0]COLUMS = 3'd4; 
    rand int pckg_sz;
    rand int fifo_depth;
    bit [7:0]bdcst= 8'b11111111;

    constraint pckg {pckg_sz<80;pckg_sz>20;}
    constraint fifs {fifo_depth<100;fifo_depth>32;}
    

    function void printPackage;
        int f = $fopen("./Rand_Parameters.sv","w");
        if(f) $display("[%0g] Archivo abierto",f);
        else $display("No se pudo abrir el archivo");
        $fdisplay(f, "package Rand_Parameters;");
        $fdisplay(f, "  parameter ROWS = %0d;",ROWS);
        $fdisplay(f, "  parameter COLUMS = %0d;",COLUMS);
        $fdisplay(f, "  parameter pckg_sz = %0d;",pckg_sz);
        $fdisplay(f, "  parameter fifo_depth = %0d;",fifo_depth);
        $fdisplay(f, "  parameter bdcst = %b;",bdcst);
        $fdisplay(f, "endpackage");
	      $fclose(f);
	      $display("[%0g] Archivo creado",f);
    endfunction 

  endclass

  Params a;
  
  initial begin
    a = new();
    a.srandom(10);
    void'(a.randomize());
    a.printPackage();
  end

endmodule