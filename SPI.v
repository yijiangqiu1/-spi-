`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:25:57 10/29/2018 
// Design Name: 
// Module Name:    SPI 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module SPI( input clk,//50M时钟
            input reset,
				//input miso,//从设备输出，接stm32的miso
				output reg mosi,//主设备输出，接stm32的mosi
				output reg sck,//1M时钟信号
				output  en_1,//片选
				input RamFull,//开始传输标志
				input radarok,//
				output reg [7:0] data
    );
reg sck_flag1;
reg sck_flag2;
wire sck_p;
wire sck_n;
reg en_flag1;
reg en_flag2;
wire en_n;
//wire en_p;
reg r_1;
reg r_2;
wire r_p;
reg ram1;
reg ram2;
wire ram_f;
reg [3:0] count_1;
reg [7:0]  count;
//reg [7:0] data;
reg txd_end;
//wire [7:0] data_test;
reg [3:0] txd_state;
reg [1:0] txd_start;
//assign data_test=8'd6;
assign en_1=0;
reg en;
always@(posedge clk or negedge reset)
begin
 if(!reset)
 begin
   sck_flag1<=1;
   sck_flag2<=1;
   en_flag1<=1;
   en_flag2<=1;
   r_1<=0;
   r_2<=0;
	ram1<=0;
	ram2<=0;
   end
 else
  begin
   sck_flag1<=sck;
   sck_flag2<=sck_flag1;
   en_flag1<=en;
   en_flag2<=en_flag1;
   r_1<=txd_end;
   r_2<=r_1;
	ram1<=RamFull;
	ram2<=ram1;
  end 
end
//assign en=(RamFull)?0:1;
assign sck_p=(!sck_flag2&sck_flag1)?1'b1:1'b0;//捕捉上升沿
assign sck_n=(sck_flag2&!sck_flag1)?1'b1:1'b0;//捕捉上升沿
assign en_n=(en_flag2&!en_flag1)?1'b1:1'b0;//下降沿为1，即捕捉下降沿
//assign en_p=(!en_flag2&en_flag1)?1'b1:1'b0;
assign r_p=(!r_2&r_1)?1'b1:1'b0;
assign ram_f=(!ram2&ram1)?1'b1:1'b0;
always@(posedge clk or negedge reset)
begin
 if(!reset)
    count<=8'b0;
else if((en==1)||(txd_start==2'b00))
    count<=8'b0;
 else if(count==8'b00011010)
    count<=8'b0;
 else 
    count<=count+1;
end
always@(posedge clk or negedge reset)
begin
 if(!reset)
    sck<=1'b1;
else if((en==1)||(txd_start==2'b00))
    sck<=1'b1;
else if(en_n)
  sck<=1'b0;
else if((count==8'b00011010))
    sck<=~sck;
end
always@(posedge clk or negedge reset)
begin
 if(!reset)
  data<=8'b0;
  else if(radarok==0)
  data<=8'b0;
  else if(data==8'd8)
  data<=8'b0;
  else if(r_p)
  data<=data+1;
end
always@(posedge clk or negedge reset)
begin
  if(!reset)
    begin
     txd_state<=4'd0;
     txd_end<=1'b1;
	  txd_start<=1'b0;
	  mosi<=0;
	  en<=1;
	  count_1<=0;
    end
  else 
    case(txd_start)
	  2'b00:
           begin
			    if(ram_f)
				 begin
				   txd_start<=2'b01;
					txd_end<=1'b0;
					txd_state<=4'd0;
					mosi<=1'b0;
					en<=0;
					end
           end	
    2'b01:			  
        begin
		     if(sck_n&(!en)&(!txd_end))
			      mosi<=data[7-txd_state];
	        else if(sck_p&(!en)&(!txd_end))
	           begin
				    txd_state<=txd_state+1;
		   	    if(txd_state==4'd7)
	               begin
	                 txd_end<=1'b1;
	                 txd_state<=4'd0;
				        txd_start<=2'b10;
					     mosi<=1'b0;
						//  en<=1;
	               end
               end
				else 
				 begin
				    mosi<=mosi;
				    txd_state<=txd_state;
				    txd_start<=txd_start;
					 en<=en;
				end
        end
		2'b10:
		  begin
		    if(count_1==4'b1111)
			 begin
		      en<=1;
            txd_start<=2'b00;
				count_1<=0;
				end
			 else
			   count_1<=count_1+1;
		  end
		default:
		  begin
		     mosi<=0;
			  txd_state<=4'd0;
			  txd_start<=0;
			  txd_end<=1'b1;
			  en<=1;
			end
	endcase
end
endmodule