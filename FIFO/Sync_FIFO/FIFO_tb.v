
`timescale 1ns / 1ps

module FIFO_tb;

    parameter DATA_WIDTH = 8;
    parameter DEPTH = 10;

    reg clk;
    reg rst;
    reg wr_en;
    reg rd_en;
    reg [DATA_WIDTH-1:0] din;

    wire [DATA_WIDTH-1:0] dout;
    wire full;
    wire empty;

    integer errors;
    integer i;
    reg [DATA_WIDTH-1:0] expected;

    FIFO #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty)
    );

    // 10 ns clock period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test tasks
    task write_data;
        input [DATA_WIDTH-1:0] data;
        begin
            @(negedge clk);
            din = data;
            wr_en = 1;
            rd_en = 0;
            @(negedge clk);
            wr_en = 0;
        end
    endtask

    task read_check;
        input [DATA_WIDTH-1:0] exp_data;
        begin
            @(negedge clk);
            rd_en = 1;
            wr_en = 0;
            @(posedge clk);
            #1;
            if (dout !== exp_data) begin
                $display("FAIL: Expected %h, got %h at time %0t",
                         exp_data, dout, $time);
                errors = errors + 1;
            end else begin
                $display("PASS: Read %h at time %0t", dout, $time);
            end
            @(negedge clk);
            rd_en = 0;
        end
    endtask

    initial begin
        errors = 0;
        rst = 1;
        wr_en = 0;
        rd_en = 0;
        din = 0;

        // 1. Reset test
        repeat (2) @(negedge clk);
        rst = 0;
        #1;
        if (empty && !full)
            $display("PASS: Reset");
        else begin
            $display("FAIL: Reset flags");
            errors = errors + 1;
        end

        // 2. Write and read one item
        write_data(8'hA5);
        if (!empty) $display("PASS: Write makes FIFO non-empty");
        else begin
            $display("FAIL: FIFO remained empty after write");
            errors = errors + 1;
        end
        read_check(8'hA5);

        // 3. FIFO ordering
        write_data(8'h11);
        write_data(8'h22);
        write_data(8'h33);
        read_check(8'h11);
        read_check(8'h22);
        read_check(8'h33);

        // 4. Fill FIFO to capacity
        for (i = 0; i < DEPTH; i = i + 1)
            write_data(i);

        if (full && !empty)
            $display("PASS: FIFO full");
        else begin
            $display("FAIL: Full flag");
            errors = errors + 1;
        end

        // 5. Attempt a write while full; it must be rejected
        write_data(8'hEE);
        if (full)
            $display("PASS: Rejected write while full");
        else begin
            $display("FAIL: Full flag changed unexpectedly");
            errors = errors + 1;
        end

        // 6. Drain FIFO in order
        for (i = 0; i < DEPTH; i = i + 1)
            read_check(i);

        if (empty)
            $display("PASS: FIFO empty after draining");
        else begin
            $display("FAIL: Empty flag");
            errors = errors + 1;
        end

        // 7. Attempt a read while empty
        @(negedge clk);
        rd_en = 1;
        @(negedge clk);
        rd_en = 0;
        if (empty)
            $display("PASS: Read while empty rejected");
        else begin
            $display("FAIL: Empty flag changed unexpectedly");
            errors = errors + 1;
        end

        // 8. Pointer wraparound
        // Repeat write/read cycles beyond DEPTH
        for (i = 0; i < DEPTH + 3; i = i + 1) begin
            write_data(i + 8'h40);
            read_check(i + 8'h40);
        end
        $display("Pointer wraparound test completed");

        // 9. Simultaneous read/write with data already queued
        write_data(8'h51);
        write_data(8'h52);

        @(negedge clk);
        din = 8'h53;
        wr_en = 1;
        rd_en = 1;
        @(posedge clk);
        #1;
        if (dout !== 8'h51) begin
            $display("FAIL: Simultaneous operation read data");
            errors = errors + 1;
        end else begin
            $display("PASS: Simultaneous read/write");
        end
        @(negedge clk);
        wr_en = 0;
        rd_en = 0;

        read_check(8'h52);
        read_check(8'h53);

        // Final result
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d error(s)", errors);

        $finish;
    end

endmodule
