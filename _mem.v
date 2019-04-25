
module mem(r,w,in,out,address,clk);
	input r,w;
	input [15:0] in;
	output reg [15:0] out;
	input clk;
	input [7:0] address;
	
	reg [15:0] Mem[0:255];
	
	always @(posedge clk)
	begin
		if(r)
			out<=Mem[address];
		else if(w)
			Mem[address]<=in;
	end	
endmodule