`timescale 1ns/1ps

module SPI_TOP_tb();
    
    parameter	clk_frequency	= 50_000_000,
                spi_frequency	= 5_000_000,
                data_width		= 8,
                CPOL			= 0,
                CPHA			= 0;
    
    reg	clk;
    reg	rst_n		;
    reg	[data_width-1:0]data_m_in	;
    reg [data_width-1:0]data_s_in	;
    reg	start_m	;
    wire finish_m;
    wire [data_width-1:0]data_m_out	;
    wire [data_width-1:0]data_s_out	;
    wire data_valid_s;
    
    //the clk generation
    initial begin
        clk = 1;
        forever #10 clk = ~clk;
    end
    
    //RESET GEN
    initial begin
        rst_n = 1'b0;
        #22 rst_n = 1'b1;
    end

    initial fork
        data_m_in_generate;
        data_s_in_generate;
        start_change;
    join
    
    //to generate data_m_in
    task data_m_in_generate;
    begin
        data_m_in = 'd0;
        @(posedge rst_n)
        data_m_in <= 8'b10100101;
        @(posedge finish_m)
        data_m_in <= 8'b10011010;
    end
    endtask
    
    //to generate data_s_in
    task data_s_in_generate;
    begin
        data_s_in = 'd0;
        @(posedge rst_n)
        data_s_in <= $random;
        @(posedge finish_m)
        data_s_in <= $random;
        @(negedge data_valid_s)
        ;
        @(negedge data_valid_s)
        #20 $finish;
    end
    endtask
    
    //to generate the start signal
    task start_change;
    begin
        start_m = 1'b0;
        @(posedge rst_n)
        #20 start_m <= 1'b1;
        #20 start_m = 1'b0;
        @(negedge finish_m)
        #20 start_m = 1'b1;
        #20 start_m = 1'b0;
    end
    endtask
    
    //to generate uart_frame_tx_tb.vcd
    initial begin
        $dumpfile("SPI_TOP_tb.vcd");
        $dumpvars();
    end
    
    //Debug information
    reg	data_valid_1;
    reg data_valid_2;
    always @(posedge clk or negedge rst_n) begin
        data_valid_1 <= data_valid_s;
        data_valid_2 <= data_valid_1;
    end
    
    assign data_valid_pos = ~data_valid_2 & data_valid_1;
    
    always @(posedge clk) begin
        if (data_valid_pos)
            if (data_s_out == data_m_in)
                $display("PASS! data_s_out = %h, data_m_in = %h", data_s_out, data_m_in);
            else
                $display("FAIL! data_s_out = %h, data_m_in = %h", data_s_out, data_m_in);
    end

    always @(posedge clk) begin
        if (data_valid_pos)
            if (data_m_out == data_s_in)
                $display("PASS! data_m_out = %h, data_s_in = %h", data_m_out, data_s_in);
            else
                $display("FAIL! data_m_out = %h, data_s_in = %h", data_m_out, data_s_in);
    end

    SPI_TOP #(clk_frequency,spi_frequency ,data_width,CPOL,CPHA)
    u_SPI_TOP(clk, rst_n, data_m_in, data_s_in, start_m, finish_m, data_m_out, data_s_out, data_valid_s);

endmodule 