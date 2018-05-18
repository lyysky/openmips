//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2014 leishangwen@163.com                       ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
// Module:  cp0_reg
// File:    cp0_reg.v
// Author:  Lei Silei
// E-mail:  leishangwen@163.com
// Description:ʵ����CP0�е�һЩ�Ĵ����������У�count��compare��status��
//             cause��EPC��config��PrId
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module cp0_reg(

	input	wire										clk,
	input wire										rst,
	
	
	input wire                    we_i,
	input wire[4:0]               waddr_i,
	input wire[4:0]               raddr_i,
	input wire[`RegBus]           data_i,
	
	input wire[31:0]              excepttype_i,
	input wire[7:0]               int_i,
	input wire[`RegBus]           current_inst_addr_i,
	input wire                    is_in_delayslot_i,
	
	output reg[`RegBus]           data_o,
	output reg[`RegBus]           count_o,
	output reg[`RegBus]           compare_o,
	output reg[`RegBus]           status_o,
	output reg[`RegBus]           cause_o,
	output reg[`RegBus]           epc_o,
	output reg[`RegBus]           config_o,
	output reg[`RegBus]           prid_o    
	
);

	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			count_o <= `ZeroWord;
			compare_o <= `ZeroWord;
			//status�Ĵ�����CUΪ0001����ʾЭ������CP0����
			status_o <= 32'b00010000000000000000000000000000;
			cause_o <= `ZeroWord;
			epc_o <= `ZeroWord;
			//config�Ĵ�����BEΪ1����ʾBig-Endian��MTΪ11����ʾFixed Mapping MMU
			config_o <= 32'b00000000000000001000000110000000;
			//��������L����Ӧ����0x48��������0x1���������ͣ��汾����1.0
			prid_o <= 32'b00000000010011000000000100000010;
//			timer_int <= `InterruptNotAssert;
		end else begin
		
			if(compare_o != `ZeroWord && count_o == compare_o) begin
				//do nothing
			end else if(compare_o == `ZeroWord) begin
				count_o <= `ZeroWord;
				//timer_int <= `InterruptNotAssert;
			end else begin
				count_o <= count_o + 1 ;
				//timer_int <= `InterruptNotAssert;
			end
					
			if(we_i == `WriteEnable) begin
				case (waddr_i) 
					`CP0_REG_COUNT:		begin
						count_o <= data_i;
					end
					`CP0_REG_COMPARE:	begin
						compare_o <= data_i;
						count_o <= `ZeroWord;
//						timer_int <= `InterruptNotAssert;
					end
					`CP0_REG_STATUS:	begin
						status_o <= data_i;
					end
					`CP0_REG_EPC:	begin
						epc_o <= data_i;
					end
					`CP0_REG_CAUSE:	begin
						cause_o <= data_i;
					end					
				endcase  //case addr_i
			end
			
			case (excepttype_i)
				32'h00000001:		begin
					if(is_in_delayslot_i == `InDelaySlot ) begin
						epc_o <= current_inst_addr_i - 4 ;
						cause_o[31] <= 1'b1;
					end else begin
					  epc_o <= current_inst_addr_i;
					  cause_o[31] <= 1'b0;
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b00001;
					cause_o[15:8] <= int_i;
				end
				32'h00000008:		begin
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01000;			
				end
				32'h0000000a:		begin
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01010;					
				end
				32'h0000000d:		begin
					if(status_o[1] == 1'b0) begin
						if(is_in_delayslot_i == `InDelaySlot ) begin
							epc_o <= current_inst_addr_i - 4 ;
							cause_o[31] <= 1'b1;
						end else begin
					  	epc_o <= current_inst_addr_i;
					  	cause_o[31] <= 1'b0;
						end
					end
					status_o[1] <= 1'b1;
					cause_o[6:2] <= 5'b01101;					
				end
				32'h0000000e:   begin
					status_o[1] <= 1'b0;
				end
				default:				begin
				end
			endcase
			
		end    //if
	end      //always
			
	always @ (*) begin
		if(rst == `RstEnable) begin
			data_o <= `ZeroWord;
		end else begin
				case (raddr_i) 
					`CP0_REG_COUNT:		begin
						data_o <= count_o ;
					end
					`CP0_REG_COMPARE:	begin
						data_o <= compare_o ;
					end
					`CP0_REG_STATUS:	begin
						data_o <= status_o ;
					end
					`CP0_REG_CAUSE:	begin
						data_o <= cause_o ;
					end
					`CP0_REG_EPC:	begin
						data_o <= epc_o ;
					end
					`CP0_REG_PrId:	begin
						data_o <= prid_o ;
					end
					`CP0_REG_CONFIG:	begin
						data_o <= config_o ;
					end	
					default: 	begin
					end			
				endcase  //case addr_i			
		end    //if
	end      //always

endmodule