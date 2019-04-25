
//******************************** UART
`define U_IDEL_RECEIVE 0 
`define U_IDEL_SEND 0 

`define U_SENDING 1
`define U_RECIVINNG 1 


module uart(Data_in_u, tx, rx, Data_out_u, Address_u, clk, r, w,reset);
	input [15:0] Data_in_u;
	input [1:0] Address_u;
	input clk,r,w,reset;
	output reg [15:0] Data_out_u;
	output reg tx;
	input rx;
	
	reg [15:0] urat_regs [0:2];
	reg [4:0] counter_Receive,counter_Send;
	reg temp_r;
	reg [1:0] state_Receive=`U_IDEL_RECEIVE
	,state_Send=`U_IDEL_SEND;

    reg stop_Sending;
	reg [17:0] data_for_send , data_for_receive;

//Receive
	always @(posedge clk)
		begin
		   if(reset)begin
		    counter_Receive <=17 ;
			data_for_receive <= 0;
			 urat_regs[2] <= 0;
		   end
		   else begin
          case(state_Receive)
		   `U_IDEL_RECEIVE:begin
		     if(~rx) begin  
			 state_Receive <=`U_RECIVINNG;			 
			 data_for_receive[counter_Receive] <=rx;
			 counter_Receive <=counter_Receive-1;
			 end
		   end
		   `U_RECIVINNG:begin
		      data_for_receive[counter_Receive] <=rx;
			  counter_Receive <=counter_Receive-1;

			  
			  if(counter_Receive <= 0) begin
					 urat_regs[2][1] <= 1;
					 state_Receive <=`U_IDEL_RECEIVE;
					 counter_Receive <=0;
					 urat_regs[0]<=data_for_receive[16:1];
			  end

		   end
		   default: state_Receive <=`U_IDEL_RECEIVE;
		   endcase
		end
	end
		

		//SEND
		always @(posedge clk)begin
		if(reset)begin
		data_for_send <= 0;
		end
		else begin
		case(state_Send)
		 `U_IDEL_SEND:
		 begin
		    stop_Sending <= 0;
		   if(urat_regs[2][0] == 16'b01) 
		   begin
                state_Send <=`U_SENDING;
				counter_Send <=16;
				
				data_for_send<={1'b1 , urat_regs[1] , 1'b0};
		   end
		end
		   `U_SENDING:
		    begin
				tx <= data_for_send[counter_Send];
				counter_Send <= counter_Send-1;

              if(counter_Send <= 1)begin
			     state_Send <=`U_IDEL_SEND;
                 stop_Sending <= 1;
				 state_Send<=3;
				 end
		   end
		   3:begin
			state_Send<=`U_IDEL_SEND;
		   end
		   default: state_Send <=`U_IDEL_SEND;
		 endcase
		end
	end

		
	always@(posedge clk) begin

	if(stop_Sending)
	  urat_regs[2][0] <= 0;
	
	case (Address_u)
     2'b00:begin
       if(r) 
	   begin
	   Data_out_u <= urat_regs[0];
	   temp_r<=0;
	   end
	   else if(w)
	     begin
	     urat_regs[2] <= 16'b010;
		 data_for_send<={1'b1 , urat_regs[0],1'b0};
	  end
	end
	 2'b01:begin
	   if(r) Data_out_u <= urat_regs[1];
	   if(w) urat_regs[1] <= Data_in_u;
	     
	end
	 2'b10:begin
		if(r)
		begin
		Data_out_u<=urat_regs[2];
		end
		else
		begin
		if(w)
		urat_regs[2]<=Data_in_u;
		end
	end
	
	
endcase
	  
	  //TODO else
	end
endmodule