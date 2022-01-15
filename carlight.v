module carlight(RA,RB,RC,LA,LB,LC,clk,rst,LEFT,RIGHT,led1,led2,seg_led_1);
  input clk,rst;
  input   LEFT,RIGHT;
 // input [3:0] seg_data_1;						//数码管需要显示0~9十个数字，所以最少需要4位输入做译码;
  output  reg LA,LB,LC,RA,RB,RC;
  output  reg led1,led2;
  output  reg[8:0] seg_led_1;						//在小脚丫上控制一个数码管需要9个信号 MSB~LSB=DIG、DP、G、
 // reg [8:0] seg [9:0];                    //定义了一个reg型的数组变量，相当于一个10*9的存储器，存储器一共有10个数，每个数有9位宽
  
  
  reg[2:0] state,next_state;
  reg [24:0] cnt1;       //计数器1
  reg [24:0] cnt2;       //计数器2
  reg flag;              //呼吸灯变亮和变暗的标志
  parameter   CNT_NUM = 2400;	//计数器的最大值 period = (2400^2)*2 = 24000000 = 2s
  
  parameter[2:0] IDLE=3'b000,
                 L1=3'b001,//1
					  L2=3'b010,//2
					  L3=3'b011,//3
					  R1=3'b100,//4
					  R2=3'b101,//5
					  R3=3'b110,//6
					  LR3=3'b111;//7
//数字存储
//  initial                                                         //在过程块中只能给reg型变量赋值，Verilog中有两种过程块always和initial
//                                                                        //initial和always不同，其中语句只执行一次
//	    begin
//         seg[0] = 9'h3f;                                           //对存储器中第一个数赋值9'b00_0011_1111,相当于共阴极接地，DP点变低不亮，7段显示数字  0
//	      seg[1] = 9'h06;                                           //7段显示数字  1
//	      seg[2] = 9'h5b;                                           //7段显示数字  2
//		 end
//时钟分频			 
	wire clk1h;
	divide #(.WIDTH(32),.N(12000000)) u2 (         //传递参数
			.clk(clk),
			.rst_n(rst),                   //例化的端口信号都连接到定义好的信号
			.clkout(clk1h)
			);               

//产生计数器cnt1
	always@(posedge clk or negedge rst) begin 
		if(!rst) begin
			cnt1<=13'd0;
			end 
        else if(cnt1>=CNT_NUM-1) 
				cnt1<=1'b0;
		     else 
                cnt1<=cnt1+1'b1; 
		end
//产生计数器cnt2
	always@(posedge clk or negedge rst) 
	begin 
		if(!rst) begin
			cnt2<=13'd0;
			flag<=1'b0;
			end 
        else if(cnt1==CNT_NUM-1) begin //当计数器1计满时计数器2开始计数加一或减一
			if(!flag) begin            //当标志位为0时计数器2递增计数，表示呼吸灯效果由暗变亮
				if(cnt2>=CNT_NUM-1)    //计数器2计满时，表示亮度已最大，标志位变高，之后计数器2开始递减
					flag<=1'b1;
				else
					cnt2<=cnt2+1'b1;
				end
			else begin
				if(cnt2<=0)      //当标志位为高时计数器2递减计数
					flag<=1'b0;		   //计数器2级到0，表示亮度已最小，标志位变低，之后计数器2开始递增
				else 	
					cnt2<=cnt2-1'b1;
				end		
 
			end
		else 
			cnt2<=cnt2;                //计数器1在计数过程中计数器2保持不变
	end	
		
//时序逻辑	 
	 always @(posedge clk1h or negedge rst) 
	 begin 
	   if(~rst)//低电平复位
		  state<=IDLE;
		else
		   state<=next_state;
	 end
//组合逻辑
    always@(state or LEFT or RIGHT)
	 begin 
	      next_state=3'bxxx; //随机态
			case(state)
			  IDLE:     //复位情况
			    begin
				  if(LEFT&&(!RIGHT))
				    next_state=L1;
				  else if(RIGHT&&(!LEFT))
				    next_state=R1;
				  else if(LEFT&&RIGHT)
				    next_state=LR3;
				  else 
				    next_state=IDLE;
	          end
		     L1:
			    begin
				  if(!(LEFT&&RIGHT))//不是刹车
				    next_state=L2;
				  else
				    next_state=LR3;
				 end
			  L2:
			    begin
				  if(!(LEFT&&RIGHT))
				    next_state=L3;
				  else
				    next_state=LR3;
				 end
			  L3:
			    begin
				    next_state=IDLE;
				 end
				    
		     R1:
			    begin
				  if(!(LEFT&&RIGHT))//不是刹车
				    next_state=R2;
				  else
				    next_state=LR3;
				 end
			  R2:
			    begin
				  if(!(LEFT&&RIGHT))
				    next_state=R3;
				  else
				    next_state=LR3;
				 end
			  R3:
			    begin
				    next_state=IDLE;
				 end
			  LR3:
			    begin 
				    next_state=IDLE;
			    end
			 endcase
	 end
//组合逻辑
    always@(state or LEFT or RIGHT)
    begin	 
	      if(~rst)
			  begin
			    LC=1'b1;LB=1'b1;LA=1'b1;RC=1'b1;RB=1'b1;RA=1'b1;
			  end
			  
			 else
			   begin
				LC=1'b1;LB=1'b1;LA=1'b1;RC=1'b1;RB=1'b1;RA=1'b1;
				
				case(state)
				IDLE:begin LC=1'b1;LB=1'b1;LA=1'b1;RC=1'b1;RB=1'b1;RA=1'b1;    end
				L1:  begin LC=1'b1;LB=1'b1;LA=1'b0;RC=1'b1;RB=1'b1;RA=1'b1;    end
				L2:  begin LC=1'b1;LB=1'b0;LA=1'b1;RC=1'b1;RB=1'b1;RA=1'b1;    end
				L3:  begin LC=1'b0;LB=1'b1;LA=1'b1;RC=1'b1;RB=1'b1;RA=1'b1;    end
				R1:  begin LC=1'b1;LB=1'b1;LA=1'b1;RC=1'b1;RB=1'b1;RA=1'b0;    end
            R2:  begin LC=1'b1;LB=1'b1;LA=1'b1;RC=1'b1;RB=1'b0;RA=1'b1;    end
            R3:  begin LC=1'b1;LB=1'b1;LA=1'b1;RC=1'b0;RB=1'b1;RA=1'b1;    end        
            LR3: begin LC=1'b0;LB=1'b0;LA=1'b0;RC=1'b0;RB=1'b0;RA=1'b0;    end
				endcase
			   end
	 end
           
//呼吸灯	 和数码管
	 always@(state or LEFT or RIGHT)
	 begin	    
	    if(~rst)
		   begin
			  led1=1'b1;led2=1'b1;
		     seg_led_1 = 9'h1ff; 
			end
		 
		 else
		   begin
				led1=1'b1;led2=1'b1;
				if(LEFT&&(!RIGHT))
				  begin 	led1= (cnt1<cnt2)?1'b0:1'b1; 
	                  led2=1'b1;
					seg_led_1 = 9'h4f; 
//			     seg_led_1=1'b1;
//				  seg_led_2=1'b0;
							
				  end
				else if((~LEFT)&&RIGHT) 
				  begin 	led2= (cnt1<cnt2)?1'b0:1'b1; 
				         led1=1'b1;
						 	seg_led_1 = 9'h79;

				  end
				else  if(LEFT&&RIGHT)
				  begin
				  	led2= (cnt1<cnt2)?1'b0:1'b1;
				 	led1= (cnt1<cnt2)?1'b0:1'b1;
					seg_led_1 = 9'h49;

				  end
				else
				  begin 
				  led1=1'b1;
				  led2=1'b1;
              seg_led_1 = 9'h1ff;
			     end  
			end
	 end
	 
endmodule

				
				
				
	
	
					 
					 
	   
		  
    
