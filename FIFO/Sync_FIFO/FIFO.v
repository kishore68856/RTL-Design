`timescale 1ns / 1ps
module FIFO#(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input wire clk,
    input wire rst,
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] din,

    output reg [DATA_WIDTH-1:0] dout,
    output wire full,
    output wire empty
);

    // Write your implementation here
    localparam pointer_width=$clog2(DEPTH);//4
    
    reg[DATA_WIDTH-1:0]mem[0:DEPTH-1];
    
    reg [pointer_width-1:0]wr_ptr;
    reg [pointer_width-1:0]rd_ptr;
    
    localparam COUNT_WIDTH = $clog2(DEPTH + 1);
    reg [COUNT_WIDTH-1:0] count;
    
    //full and empty condition
    assign full=(count==DEPTH);
    assign empty=(count==0);
    
    //doread and dowrite
    wire do_write=(wr_en &&(count!=DEPTH));
    wire do_read=(rd_en && (count!=0));
    
    //updating pointers
    always @(posedge clk) begin
    if (rst) begin
        wr_ptr <= 0;
        rd_ptr <= 0;
    end
    else begin
        if (do_write) begin
            if (wr_ptr == DEPTH-1)
                wr_ptr <= 0;
            else
                wr_ptr <= wr_ptr + 1'b1;
        end

        if (do_read) begin
            if (rd_ptr == DEPTH-1)
                rd_ptr <= 0;
            else
                rd_ptr <= rd_ptr + 1'b1;
        end
    end
end
    
    // updating memory
    always@(posedge clk)begin
      if(rst)begin
          dout <= 0;
      end   
      else begin
        if(do_write)
             mem[wr_ptr] <= din;
             
        if(do_read)
             dout <= mem[rd_ptr];
      end
    end
    
    //updating count
    always @(posedge clk) begin
    if (rst)
        count <= 0;
    else begin
        case ({do_write, do_read})
               2'b10: count <= count + 1'b1;
               2'b01: count <= count - 1'b1;
               default: count <= count;
       endcase
    end
end

endmodule
