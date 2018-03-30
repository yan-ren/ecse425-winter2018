library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;


entity EX is
        
	PORT( 
              clk: in  std_logic;
	     
              
              -- input from id stage
              instruction_addr: in std_logic_vector(31 downto 0);
              jump_addr : in std_logic_vector( 25 downto 0);
              rs:  in std_logic_vector(31 downto 0);
              rt:  in  std_logic_vector(31 downto 0);  
              des_addr: in std_logic_vector(4 downto 0);
              signExtImm: in  std_logic_vector(31 downto 0);
	      --  first bit for mem_read, 9-5 for rt, 4-0 for rs
              EX_control_buffer: in std_logic_vector(10 downto 0); 
	      --  first bit for wb_signal, 4-0 for des_adr
              MEM_control_buffer: in std_logic_vector(5 downto 0); 
	      --  first bit for wb_signal, 4-0 for des_adr
              WB_control_buffer: in std_logic_vector(5 downto 0); 
              opcode_in: in  std_logic_vector(5 downto 0);
              funct_in: in std_logic_vector(5 downto 0) ;
              
      
              -- input from wb stage
              WB_control_buffer_before: in std_logic_vector(5 downto 0); 
              writeback_data: in std_logic_vector(31 downto 0); 
       
             
              -- for mem stage 
	      MEM_control_buffer_before: in std_logic_vector(5 downto 0); 
	      bran_taken_in: in std_logic;	
	      branch_addr: out std_logic_vector(31 downto 0);
              bran_taken: out std_logic;
              opcode_out: out std_logic_vector(5 downto 0);
              des_addr_out: out std_logic_vector(4 downto 0);
              ALU_result: out std_logic_vector(31 downto 0);
              rt_data: out std_logic_vector(31 downto 0);
	      --   first bit for wb_signal, 4-0 for des_adr
              MEM_control_buffer_out: out std_logic_vector(5 downto 0); 
	      --  first bit for wb_signal, 4-0 for des_adr
              WB_control_buffer_out: out std_logic_vector(5 downto 0); 
              -- for id stage 
	      EX_control_buffer_out: out std_logic_vector(10 downto 0) --  first bit for mem_read, 9-5 for rt, 4-0 for rs
	      
	);
end EX;

architecture behaviour of EX is 
       
        signal opcode: std_logic_vector(5 downto 0):= (others =>'0');
        signal funct: std_logic_vector(5 downto 0):= (others =>'0');
        signal branch_taken_temp: std_logic:= '0';
        signal branch_addr_temp: std_logic_vector(31 downto 0):= (others =>'0');
        signal pc_plus_4 : std_logic_vector(31 downto 0):= (others =>'0');
        signal ALU_opcode: std_logic_vector(3 downto 0):= (others =>'0');
        signal data0 : std_logic_vector(31 downto 0):= (others =>'0');
        signal data1 : std_logic_vector(31 downto 0):= (others =>'0');
        signal rs_content: integer:=0;
        signal rt_content: integer:=0;
        signal imm_content: integer:=0;
        signal b_rs : std_logic_vector(31 downto 0):= (others =>'0');
	signal b_rt : std_logic_vector(31 downto 0):= (others =>'0');
   
	signal result_temp : std_logic_vector(31 downto 0):= (others =>'0');
	signal HILO_temp : std_logic_vector(63 downto 0):= (others =>'0');
	

        signal reg_rs_ex :  std_logic_vector (4 downto 0):= (others =>'0');
        signal reg_rt_ex :  std_logic_vector (4 downto 0):= (others =>'0');
        signal reg_des_mem  :  std_logic_vector (4 downto 0):= (others =>'0');
        signal reg_des_wb   :   std_logic_vector (4 downto 0):= (others =>'0');
        signal reg_wb_mem   :  std_logic:='0';
        signal reg_wb_wb    :   std_logic:='0';

        signal data_rs_forward_mem_en :  std_logic:='0';
        signal data_rt_forward_mem_en :  std_logic:='0';
        signal data_rs_forward_wb_en :  std_logic:='0';
        signal data_rt_forward_wb_en :  std_logic:='0';
            
        signal rt_flag: std_logic:='0';
        signal rs_flag: std_logic:='0';
        signal isSWforward: std_logic:= '0';
 
  
     
begin 
        
opcode <= opcode_in;
funct <= funct_in;



ALU_result <= result_temp; 

reg_rs_ex <= EX_control_buffer(4 downto 0);
reg_rt_ex <= EX_control_buffer(9 downto 5);
reg_des_mem <= MEM_control_buffer_before(4 downto 0);
reg_des_wb <= WB_control_buffer_before(4 downto 0);
reg_wb_mem <= MEM_control_buffer_before(5);
reg_wb_wb <= WB_control_buffer_before(5);

pc_plus_4 <= std_logic_vector((unsigned(instruction_addr))+ 4);

EX_control_buffer_out <= EX_control_buffer;

forward_detection: process(opcode,data_rs_forward_mem_en,data_rt_forward_mem_en ,data_rs_forward_wb_en ,data_rt_forward_wb_en ) 
begin
--detect for forward control
rt_flag <= '1';
  rs_flag <= '1';
  isSWforward <= '0';
   if(opcode = "000000" and (funct = "000011" or funct = "000010" or funct = "000000")) then 
      rs_flag <= '0';
   elsif(opcode = "100011" or opcode = "001110" or opcode = "001101" or  opcode = "001100" or opcode = "001010" or opcode = "001000" or (opcode = "000000" and funct = "001000") ) then
      rt_flag <= '0';
   elsif(opcode = "001111" or opcode = "000011") then 
      rt_flag <= '0';
      rs_flag <= '0';
  elsif(opcode = "101011") then 
      rt_flag <= '0';
      isSWforward <= '1';
  end if;
    
          b_rs <= rs;
          b_rt <= rt;
        
          if(data_rs_forward_mem_en = '1')then 
               b_rs <= result_temp; -- the result from last instruction
          end if;    
          if(data_rt_forward_mem_en = '1')then 
               b_rt <= result_temp; 
          end if;    
          if(data_rs_forward_wb_en = '1')then 
               b_rs <= writeback_data; 
          end if;    
          if(data_rt_forward_wb_en = '1')then 
               b_rt <= writeback_data; 
          end if;    


end process;




forwarding_logic: process ( reg_rs_ex
                		, reg_rt_ex
                		, reg_des_mem
                		, reg_des_wb
                		, reg_wb_mem
                		, reg_wb_wb
                		)
        		begin

            data_rs_forward_mem_en <= '0';
            data_rt_forward_mem_en <= '0';
            data_rs_forward_wb_en <= '0';
            data_rt_forward_wb_en <= '0';


            if (reg_wb_mem = '1') and (reg_des_mem /= "00000")and (reg_des_mem = reg_rs_ex) 
            then 
              data_rs_forward_mem_en <= '1';
            end if;
            
            if (reg_wb_mem = '1')and (reg_des_mem /= "00000") and (reg_des_mem = reg_rt_ex)
            then 
              data_rt_forward_mem_en <= '1';
            end if;
            


            if (reg_wb_wb = '1') and (reg_des_wb /= "00000") and (reg_des_wb = reg_rs_ex)
            then
              data_rs_forward_wb_en <= '1';
            end if;
            
            if (reg_wb_wb = '1') and (reg_des_wb /= "00000")and (reg_des_wb = reg_rt_ex)
            then
              data_rt_forward_wb_en <= '1';
            end if;

        end process;






branch_detect_process: process(clk)
begin
       
      if(rising_edge(clk))then 

        
          if(bran_taken_in = '0') then 
  
       case opcode is
        -- beq         
        when "000100" => 
          branch_addr_temp <= pc_plus_4 + std_logic_vector(unsigned(signExtImm)sll  2);      
         if(b_rs = b_rt) then 
          branch_taken_temp <= '1';
         else 
          branch_taken_temp <= '0';
          end if;
        
        -- bne
         when "000101" =>
          branch_addr_temp <= pc_plus_4 +std_logic_vector(unsigned(signExtImm)sll  2); 
         if(b_rs = b_rt) then 
          branch_taken_temp <= '0';
         else 
          branch_taken_temp <= '1';
          end if;
         -- j 
          when "000010" => 
           branch_addr_temp (31 downto 28) <= pc_plus_4(31 downto 28);
           branch_addr_temp (27 downto 2) <= jump_addr; 
           branch_addr_temp(1 downto 0) <= "00";
           branch_taken_temp <= '1';
         -- jal 
           when "000011" => 
           branch_addr_temp (31 downto 28) <= pc_plus_4(31 downto 28);
           branch_addr_temp (27 downto 2) <= jump_addr; 
           branch_addr_temp(1 downto 0) <= "00";
           branch_taken_temp <= '1';
          -- jr
          when "000000" =>
    
          
            if(funct = "001000")then 
              branch_addr_temp <= b_rs;
              branch_taken_temp <= '1';
            end if;
          when others =>
             branch_taken_temp <= '0'; 
             branch_addr_temp <=(others => '0');
      end case;
      else 
      branch_taken_temp <= '0';
      branch_addr_temp <=(others => '0');
      end if;
      end if; 
end process;



alu_process: process(clk,writeback_data)
begin
   if(rising_edge(clk) and clk'event )then 
   
    case opcode is

			-- R type instruction
			when "000000" =>

				case funct is
                                             
					-- add
					when "100000" =>
						ALU_opcode <= "0000";
                                                data0 <= rs;
                                                data1 <= rt;
                                       
					-- mflo
					when "010010" =>
						ALU_opcode <= "1010";
                                                data0 <=(others =>'0');
                                                data1 <=(others =>'0');


					when others =>
						null;

				end case; -- end R type

			-- I type
			
                        -- addi
                        when "001000"  =>
                                ALU_opcode <= "0000";
                                data0 <= rs;
                                data1 <= signExtImm ;   
			
			-- lui
			when "001111" =>
				ALU_opcode <= "1011";
                                data0 <= (others =>'0');
                                data1 <= signExtImm ;

			-- sw 
			when "101011" =>
				ALU_opcode <= "0000";
                                data0 <= rs;
                                data1 <= signExtImm ;

			-- lw 
			when "100011" =>
				ALU_opcode <= "0000";
                                data0 <= rs;
                                data1 <= signExtImm ;
                        -- jal 
                        when "000011" =>
                               ALU_opcode <= "0000";  
                               data0 <= instruction_addr;
                               data1 <= x"00000008"; 

			when others =>
				ALU_opcode <= "1111";
                                data0 <=(others =>'0');
                                data1 <=(others =>'0');

		end case;
          
          if(data_rs_forward_mem_en = '1' and rs_flag = '1')then 
               data0 <= result_temp; -- the result from last instruction
          end if;    
          if(data_rt_forward_mem_en = '1' and rt_flag = '1')then 
               data1 <= result_temp; 
          end if;    
        end if;
        
        if(writeback_data' event) then   
        
          if(data_rs_forward_wb_en = '1' and  rs_flag = '1')then 
               data0 <= writeback_data;
          end if;    
          if(data_rt_forward_wb_en = '1' and  rt_flag = '1')then 
              data1 <= writeback_data; 
          end if;  
          end if;
           
    
    if(falling_edge(clk) and clk'event ) then 
    
                    if(bran_taken_in = '1') then 
                        rt_data <= (others => '0');
                     else
                        if(isSWforward = '1' and (data_rt_forward_mem_en = '1')) then 
                          rt_data <= result_temp;
                        elsif(isSWforward = '1' and (data_rt_forward_wb_en = '1'))then
                          rt_data <= writeback_data;
                        else
                          rt_data <= rt;
                       end if;
                    end if;
          
          if(bran_taken_in = '0') then 


			case opcode is
				when "000000" =>

				case funct is
					--when "100000" =>
						--result_temp <= std_logic_vector(signed(rs) + signed(rt));
                                             
					-- sub
					when "100010" =>
						result_temp <= std_logic_vector(signed(rs) - signed(rt));
					
					--mul
					when "011000" =>
						HILO_temp <= std_logic_vector(signed(rs) * signed(rt));
					--div
					when "011010" =>
						HILO_temp <= std_logic_vector(signed(rs) mod signed(rt)) & std_logic_vector(signed(rs) / signed(rs));
					--slt
					when "101010" =>
						if (signed(rs) < signed(rt)) then
						result_temp <= "00000000000000000000000000000001";
					else
						result_temp <= "00000000000000000000000000000000";
					end if;
					--and
					when "100100" =>
						result_temp <= rs AND rt;
					--or
					when "100101" =>
						result_temp <= rs OR rt;

					-- nor
					when "100111" =>
						result_temp <= rs NOR rt;
						
					-- xor
					when "100110" =>
						result_temp <= rs XOR rt;
					--mfhi
					when "010000" =>
						result_temp <= HILO_temp(63 downto 32);

					-- sll
					when "000000" =>
						result_temp <= std_logic_vector(signed(rt) sll to_integer(signed(signExtImm(10 downto 6))));

					-- srl
					when "000010" =>
						result_temp <= std_logic_vector(signed(rt) srl to_integer(signed(signExtImm(10 downto 6))));

					-- sra
					when "000011" =>
						result_temp <= std_logic_vector(shift_right(signed(rt) , to_integer(signed(signExtImm(10 downto 6)))));
					when others =>
					null;
				end case;
				-- slti
				when "001010" =>
					if (signed(rs) < signed(signExtImm)) then
						result_temp <= "00000000000000000000000000000001";
					else
						result_temp <= "00000000000000000000000000000000";
					end if;
				-- andi
				when "001100" =>
					result_temp <= rs AND signExtImm;

				-- ori
				when "001101" =>
					result_temp <= rs OR signExtImm;

				-- xori
				when "001110" =>
					result_temp <= rs XOR signExtImm;
				when others =>
				null;
			end case;



                        case ALU_opcode is
				--add,addi,sw,lw
				when "0000" =>
					result_temp <= std_logic_vector(signed(data0) + signed(data1));
				--mflo
				when "1010" =>
					result_temp <= HILO_temp(31 downto 0);

				--lui
				when "1011" =>  
					result_temp <= to_stdlogicvector(to_bitvector(data1) sll 16); 
						
				when others =>
					--temp_zero <= '0';
					result_temp <= (others => '0');

			     end case;
                   else 
                   result_temp <= (others => '0');
                   end if;
                  
                    
                    if(bran_taken_in = '1') then 
                    opcode_out <=  (others => '0');
                    des_addr_out <= (others => '0');
                    MEM_control_buffer_out <=  (others => '0');     
                    WB_control_buffer_out <= (others => '0');
                    bran_taken<= '0';
                    branch_addr <=  (others => '0');
                    else 
                    opcode_out <=  opcode;
                    des_addr_out <= des_addr; 
                    MEM_control_buffer_out <=   MEM_control_buffer;       
                    WB_control_buffer_out <= WB_control_buffer;
                     bran_taken<= branch_taken_temp;
                    branch_addr <= branch_addr_temp;
                    end if;

    end if;

end process;
end behaviour;




--citation
--https://github.com/klee-17/ECSE425-project/tree/master/deliverable4