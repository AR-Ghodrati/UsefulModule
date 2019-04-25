
`define S_idle			0
`define S_fetch1	 	1
`define S_fetch2	 	2
`define S_fetch3	 	3

`define S_decode_exec 	4
`define S_mem_wait		5
`define S_mem			6	
`define S_last			7

//*************************
`define NOP		4'b0000
`define ADD		4'b0001
`define SUB		4'b0010
`define MUL		4'b0011
`define AND		4'b0100
`define NOT		4'b0101
`define CPM		4'b0110
`define JMP		4'b0111
`define BEQ	    4'b1000
`define BLT		4'b1001
`define BGT		4'b1010
`define LOAD	4'b1011
`define STORE	4'b1100
`define MOV		4'b1101
`define HALT	4'b1111



module cpu(start,Data_out_mem,Data_in_mem,Address,r,w,reset,clk);
	input start;
	input  [15:0] Data_out_mem;
	output reg [15:0] Data_in_mem;
	output reg [7:0] Address;
	output reg r,w;
	input clk,reset;
	reg L,G,E;
	reg [2:0] state, next_state;
	reg load_IR,load_PC,load_RegFile,inc_PC, load_L, load_G, load_E;
	reg [7:0] Data_in_PC;
	reg [15:0] Data_in_RegFile;
	reg Data_in_L, Data_in_G, Data_in_E;
	
	reg load_r;
	reg load_w;
	reg data_in_r;
	reg data_in_w;
	
	reg Data_in_mem_load;
	reg [15:0] Data_in_mem_data;
	
	


	reg[7:0] PC;
	reg[15:0] IR;
	reg[15:0] RegFile[0:15];
	
	reg Load_Address;
	reg [15:0] Data_in_Address;
	always @*
	begin
		load_r=0;
		load_w=0;
		data_in_r=0;
		data_in_w=0;
		next_state=0;
		load_PC=0;
		load_IR=0;
		load_RegFile=0;
		Data_in_RegFile=0;
		Data_in_PC=0;
		inc_PC=0;
		Data_in_mem_data=0;
		Data_in_mem_load=0;
		load_L=0;
		load_G=0;
		load_E=0;
		Load_Address=0;
		Data_in_Address=0;
		case (state)
			`S_idle:
			begin
				if(start)
					next_state=`S_fetch1;
				else
					next_state=`S_idle;
			end
			`S_fetch1:
			begin
				data_in_r=1;
				load_r=1;
				Load_Address=1;
				Data_in_Address=PC;
				next_state=`S_fetch2;
			end
			`S_fetch2:
			begin
				next_state=`S_fetch3;
			end
			
			`S_fetch3:
			begin
				load_IR=1;
				next_state=`S_decode_exec;
				load_r=1;
				data_in_r=0;
				load_w=1;
				data_in_w=0;
				
			end
			
			`S_decode_exec:
			begin
				case (IR[15:12])
					`ADD:
					begin
						load_RegFile=1;	
						Data_in_RegFile=RegFile[IR[7:4]]+RegFile[IR[3:0]];
						inc_PC=1;
						next_state=`S_fetch1;
						$display("ADD R%d R%d R%d", IR[11:8], IR[7:4], IR[3:0]);
					end
					`SUB:
					begin
						load_RegFile=1;	
						Data_in_RegFile=RegFile[IR[7:4]]-RegFile[IR[3:0]];
						inc_PC=1;
						next_state=`S_fetch1;
						$display("SUB R%d R%d R%d", IR[11:8], IR[7:4], IR[3:0]);
					end

                    `MUL:
					begin
						load_RegFile=1;	
						Data_in_RegFile=RegFile[IR[7:4]]*RegFile[IR[3:0]];
						inc_PC=1;
						next_state=`S_fetch1;
						$display("MUL R%d R%d R%d", IR[11:8], IR[7:4], IR[3:0]);
					end
					`AND:
					begin
						load_RegFile=1;	
						Data_in_RegFile=RegFile[IR[7:4]]&RegFile[IR[3:0]];
						inc_PC=1;
						next_state=`S_fetch1;
						$display("AND R%d R%d R%d", IR[11:8], IR[7:4], IR[3:0]);
					end
					`NOT:
					begin
						load_RegFile=1;	
						Data_in_RegFile=~RegFile[IR[7:4]];
						inc_PC=1;
						next_state=`S_fetch1;
						$display("NOT R%d R%d", IR[11:8], IR[7:4]);
					end					
					`CPM:
					begin
						load_L=1;
						load_G=1;
						load_E=1;
						Data_in_L= (RegFile[IR[11:8]]<RegFile[IR[7:4]]) ? 1 : 0;
						Data_in_G= (RegFile[IR[11:8]]>RegFile[IR[7:4]]) ? 1 : 0;
						Data_in_E= (RegFile[IR[11:8]]==RegFile[IR[7:4]]) ? 1 : 0;
						inc_PC=1;
						next_state=`S_fetch1;
						$display("CMP R%d R%d", IR[11:8], IR[7:4]);
					end
					`JMP:
					begin
						load_PC=1;
						Data_in_PC=IR[7:0];
						next_state=`S_fetch1;		
						$display("JMP [%h]", IR[7:0]);						
					end					
				    `BEQ:
					begin
						if(E==1)
						begin
							load_PC=1;
							Data_in_PC=IR[7:0];
						end
						else
							inc_PC=1;
						next_state=`S_fetch1;	
						$display("BEQ [0x%h]", IR[7:0]);	
					end
					`BLT:
					begin
						if(L==1)
						begin
							load_PC=1;
							Data_in_PC=IR[7:0];
						end
						else
							inc_PC=1;
						next_state=`S_fetch1;	
						$display("BLT [0x%h]", IR[7:0]);	
					end
					`BGT:
					begin
						if(G==1)
						begin
							load_PC=1;
							Data_in_PC=IR[7:0];
						end
						else
							inc_PC=1;
						next_state=`S_fetch1;					
						$display("BGT [0x%h]", IR[7:0]);	
					end
					`LOAD:
					begin
						inc_PC=1;
						Load_Address=1;
						Data_in_Address=IR[7:0];
						data_in_r=1;
						load_r=1;
						next_state=`S_mem_wait;
						$display("LOAD R%d [0x%h]", IR[11:8], IR[7:0]);
					end	
					`STORE:
					begin
						inc_PC=1;
						Load_Address=1;
						Data_in_Address=IR[7:0];
						
						Data_in_mem_data=RegFile[IR[11:8]];
						Data_in_mem_load=1;
						data_in_w=1;
						load_w=1;
						next_state=`S_mem_wait;
						$display("STORE R%d [0x%h]", IR[11:8], IR[7:0]);
					end	
					
					`MOV:
					begin
						load_RegFile=1;	
						Data_in_RegFile={8'b0,IR[7:0]};
						inc_PC=1;
						next_state=`S_fetch1;
						$display("MOV R%d 0x%h", IR[11:8], IR[7:0]);
					end
					
					
					`HALT:
					begin
						next_state=`S_last;
					end
					default:
						$display("invalid opcode %b\n", IR[15:12]);
				endcase
			end			
			`S_mem_wait:
			begin
				next_state = `S_mem;
			end
			`S_mem:
			begin
				if(IR[15:12]==`LOAD)
				begin
					load_RegFile=1;
					Data_in_RegFile=Data_out_mem;
				end
				load_r=1;
				data_in_r=0;
				load_w=1;
				data_in_w=0;
				next_state=`S_fetch1;
			end
			`S_last:
				next_state=`S_last;
			default:
				next_state=`S_idle;

		endcase
	end
	
	always @(posedge clk)
	begin
		if(reset==1)
		begin
			state<=`S_idle;
			PC<=0;
			IR<=0;
			E<=0;
			L<=0;
			G<=0;
			r<=0;
			w<=0;
		end
		else
		begin
			state<=next_state;
			if(load_PC)
				PC<=Data_in_PC;
			else if(inc_PC)
				PC<=PC+1;
			
			if(load_IR)
				IR<=Data_out_mem;			
			if(load_RegFile)
				RegFile[IR[11:8]]<=Data_in_RegFile;
				
			if(load_E)
				E<=Data_in_E;
			if(load_G)
				G<=Data_in_G;
			if(load_E)
				L<=Data_in_L;
			if(Load_Address)
				Address<=Data_in_Address;
			if(load_r)
				r<=data_in_r;
			if(load_w)
				w<=data_in_w;			
			if(Data_in_mem_load)
				Data_in_mem <= Data_in_mem_data;
		end
	end
	
endmodule