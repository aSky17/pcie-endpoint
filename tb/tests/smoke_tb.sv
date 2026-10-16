`timescale 1ns/1ps

module smoke_tb;
  initial begin
    $display("PCIe project smoke test: simulator is running.");
    #10;
    $display("PCIe project smoke test: PASS");
    $finish;
  end
endmodule
