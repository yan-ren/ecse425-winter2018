library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;
--use IEEE.std_logic_arith.all;

entity EX is

	PORT(
              clk: in  std_logic;
              bran_taken_in: in std_logic;-- from mem
               -- from id stage
              instruction_addr_in: in std_logic_vector(31 downto 0);
              jump_addr : in std_logic_vector( 25 downto 0);
              rs:  in std_logic_vector(31 downto 0);
              rt:  in  std_logic_vector(31 downto 0);
              des_addr: in std_logic_vector(4 downto 0);
              signExtImm: in  std_logic_vector(31 downto 0);
              EX_control_buffer: in std_logic_vector(10 downto 0); --  for ex stage provide information for forward and harzard detect, first bit for mem_read, 9-5 for rt, 4-0 for rs
              MEM_control_buffer: in std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
              WB_control_buffer: in std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
              opcode_in: in  std_logic_vector(5 downto 0);
              funct_in: in std_logic_vector(5 downto 0) ;

             -- from mem stage
              MEM_control_buffer_before: in std_logic_vector(5 downto 0); --control buffer from last instruction which is in mem stage now
             -- MEM_result: in std_logic_vector(31 downto 0); -- if last inst is load word, its data from mem
             -- last_opcode : in std_logic_vector(5 downto 0);  -- opcode of last instruction

              -- from wb stage
              WB_control_buffer_before: in std_logic_vector(5 downto 0); --control buffer from the one before last instruction which is in wb stage now
              writeback_data: in std_logic_vector(31 downto 0); -- data for forwarding of last last instruction



              -- for mem stage
	          branch_addr: out std_logic_vector(31 downto 0);
              bran_taken: out std_logic;
              opcode_out: out std_logic_vector(5 downto 0);
              des_addr_out: out std_logic_vector(4 downto 0);
              ALU_result: out std_logic_vector(31 downto 0);
              rt_data: out std_logic_vector(31 downto 0);
              MEM_control_buffer_out: out std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
              WB_control_buffer_out: out std_logic_vector(5 downto 0); --  for mem stage, provide info for forward and hazard detect, first bit for wb_signal, 4-0 for des_adr
             -- for id stage
	      EX_control_buffer_out: out std_logic_vector(10 downto 0) --  for ex stage provide information for forward and harzard detect, first bit for mem_read, 9-5 for rt, 4-0 for rs

	);
end EX;

architecture behaviour of EX is

      signal opcode: std_logic_vector(5 downto 0):= (others =>'0');
      signal funct: std_logic_vector(5 downto 0):= (others =>'0');
      signal temp_bran_taken: std_logic:= '0';
      signal temp_branch_addr: std_logic_vector(31 downto 0):= (others =>'0');
      signal pc_plus_4 : std_logic_vector(31 downto 0):= (others =>'0');
      signal ALU_opcode: std_logic_vector(3 downto 0):= (others =>'0');
      signal data0 : std_logic_vector(31 downto 0):= (others =>'0');
      signal data1 : std_logic_vector(31 downto 0):= (others =>'0');
      signal rs_content: integer:=0;
      signal rt_content: integer:=0;
      signal imm_content: integer:=0;
      signal b_rs : std_logic_vector(31 downto 0):= (others =>'0');
      signal b_rt : std_logic_vector(31 downto 0):= (others =>'0');
    -- from alu.vhd implemented by Kristin
        signal temp_result : std_logic_vector(31 downto 0):= (others =>'0');
	signal temp_HILO : std_logic_vector(63 downto 0):= (others =>'0');
	--signal temp_zero : std_logic;
	--signal temp_lui : std_logic_vector(32 downto 0);
     -- from forward_unit implemented by Zhong
          signal reg_rs_ex :  std_logic_vector (4 downto 0):= (others =>'0')
        ; signal reg_rt_ex :  std_logic_vector (4 downto 0):= (others =>'0')
        ; signal reg_des_mem  :  std_logic_vector (4 downto 0):= (others =>'0')
        ; signal reg_des_wb   :   std_logic_vector (4 downto 0):= (others =>'0')
        ; signal reg_wb_mem       :  std_logic:='0'
        ; signal reg_wb_wb        :   std_logic:='0'

        ; signal data_rs_forward_mem_en :  std_logic:='0'
        ; signal data_rt_forward_mem_en :  std_logic:='0'
        ; signal data_rs_forward_wb_en :  std_logic:='0'
        ; signal data_rt_forward_wb_en :  std_logic:='0';

         signal rt_flag: std_logic:='0';
         signal rs_flag: std_logic:='0';
         signal isSWforward: std_logic:= '0';



begin

opcode <= opcode_in;
funct <= funct_in;



ALU_result <= temp_result;

reg_rs_ex <= EX_control_buffer(4 downto 0);
reg_rt_ex <= EX_control_buffer(9 downto 5);
reg_des_mem <= MEM_control_buffer_before(4 downto 0);
reg_des_wb <= WB_control_buffer_before(4 downto 0);
reg_wb_mem <= MEM_control_buffer_before(5);
reg_wb_wb <= WB_control_buffer_before(5);

pc_plus_4 <= std_logic_vector((unsigned(instruction_addr_in))+ 4);


--ex_cbuffer_broadcast: process(bran_taken_in,EX_control_buffer)
--begin
   -- if(bran_taken_in = '0') then
    EX_control_buffer_out <= EX_control_buffer;
   -- else
   -- EX_control_buffer_out <= (others => '0');
  --  end if;
--end process;


forward_detection: process(opcode,data_rs_forward_mem_en,data_rt_forward_mem_en ,data_rs_forward_wb_en ,data_rt_forward_wb_en ) -- mainly works for branch, also pre dect for alu
begin
-- detect forward situation for different current opcode
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

 -- forward part for  branch detection
          b_rs <= rs;
          b_rt <= rt;

        -- replace rs or rt if they are forwarded
          if(data_rs_forward_mem_en = '1')then
               b_rs <= temp_result; -- the result from last instruction
          end if;
          if(data_rt_forward_mem_en = '1')then
               b_rt <= temp_result; -- the result from last instruction
          end if;
          if(data_rs_forward_wb_en = '1')then
               b_rs <= writeback_data; -- the result from last last instruction
          end if;
          if(data_rt_forward_wb_en = '1')then
               b_rt <= writeback_data; -- the result from last last  instruction
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

            -----------------------------
           -- last instruction forward detection
            -----------------------------
            if (reg_wb_mem = '1') and (reg_des_mem /= "00000")and (reg_des_mem = reg_rs_ex)
            then
              data_rs_forward_mem_en <= '1';
            end if;

            if (reg_wb_mem = '1')and (reg_des_mem /= "00000") and (reg_des_mem = reg_rt_ex)
            then
              data_rt_forward_mem_en <= '1';
            end if;

            -----------------------------
           -- last  last instruction forward detection
            -----------------------------

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
-- part for forward detect, this part is build to fit the forwarding according to the current opcode

          if(bran_taken_in = '0') then

       case opcode is
        -- beq
        when "000100" =>
          temp_branch_addr <= pc_plus_4 + std_logic_vector(unsigned(signExtImm)sll  2);
         if(b_rs = b_rt) then
          temp_bran_taken <= '1';
         else
          temp_bran_taken <= '0';
          end if;

     -- bne
         when "000101" =>
          temp_branch_addr <= pc_plus_4 +std_logic_vector(unsigned(signExtImm)sll  2);
         if(b_rs = b_rt) then
          temp_bran_taken <= '0';
         else
          temp_bran_taken <= '1';
          end if;
         -- j
          when "000010" =>
           temp_branch_addr (31 downto 28) <= pc_plus_4(31 downto 28);
           temp_branch_addr (27 downto 2) <= jump_addr;
           temp_branch_addr(1 downto 0) <= "00";
           temp_bran_taken <= '1';
         -- jal
           when "000011" =>
           temp_branch_addr (31 downto 28) <= pc_plus_4(31 downto 28);
           temp_branch_addr (27 downto 2) <= jump_addr;
           temp_branch_addr(1 downto 0) <= "00";
           temp_bran_taken <= '1';
          -- jr
          when "000000" =>
         -- replace rs or rt if they are forwarded

            if(funct = "001000")then
              temp_branch_addr <= b_rs;
              temp_bran_taken <= '1';
            end if;
          when others =>
             temp_bran_taken <= '0';
             temp_branch_addr <=(others => '0');
      end case;
      else
      temp_bran_taken <= '0';
      temp_branch_addr <=(others => '0');
      end if;
      end if;
end process;

-- the ALU and controller code is implemented by Kristin, and modified accordlingly to fit this stage process


alu_process: process(clk,writeback_data)
begin
   if(rising_edge(clk) and clk'event )then
     --rs_content <= to_integer(unsigned(rs));
    -- rt_content <= to_integer(unsigned(rt));
    -- imm_content <= to_integer(unsigned(imm));
    case opcode is

			-- R type instruction
			when "000000" =>

				case funct is

					-- add
					when "100000" =>
						ALU_opcode <= "0000";
                                                data0 <= rs;
                                                data1 <= rt;

					-- sub
					when "100010" =>
						ALU_opcode <= "0001";
                                                data0 <= rs;
                                                data1 <= rt;

					-- mult
					when "011000" =>
						ALU_opcode <= "0010";
                                                data0 <= rs;
                                                data1 <= rt;

					-- div
					when "011010" =>
						ALU_opcode <= "0011";
                                                data0 <= rs;
                                                data1 <= rt;

					-- slt
					when "101010" =>
						ALU_opcode <= "0100";
                                                data0 <= rs;
                                                data1 <= rt;

					-- and
					when "100100" =>
						ALU_opcode <= "0101";
                                                data0 <= rs;
                                                data1 <= rt;

					-- or
					when "100101" =>
						ALU_opcode <= "0110";
                                                data0 <= rs;
                                                data1 <= rt;

					-- nor
					when "100111" =>
						ALU_opcode <= "0111";
                                                data0 <= rs;
                                                data1 <= rt;

					-- xor
					--when "101000" => -- Aaron : xor should be "100110" instead of 101000
					when "100110" =>
						ALU_opcode <= "1000";
                                                data0 <= rs;
                                                data1 <= rt;

					-- mfhi
					when "010000" =>
						ALU_opcode <= "1001";
                                                data0 <=(others =>'0');
                                                data1 <=(others =>'0');

					-- mflo
					when "010010" =>
						ALU_opcode <= "1010";
                                                data0 <=(others =>'0');
                                                data1 <=(others =>'0');

					-- sll
					when "000000" =>
						ALU_opcode <= "1100";
                                                data0 <= rt;
                                                data1 <= signExtImm ;

					-- srl
					when "000010" =>
						ALU_opcode <= "1101";
                                                data0 <= rt;
                                                data1 <= signExtImm ;

					-- sra
					when "000011" =>
						ALU_opcode <= "1110";
                                                data0 <= rt;
                                                data1 <= signExtImm ;


					when others =>
						null;

				end case; -- end R type

			-- I type
			-- slti
			when "001010" =>
				ALU_opcode <= "0100";
                                data0 <= rs;
                                data1 <= signExtImm ;
                        -- addi
                        when "001000"  =>
                                ALU_opcode <= "0000";
                                data0 <= rs;
                                data1 <= signExtImm ;
			-- andi
			when "001100" =>
				ALU_opcode <= "0101";
                                data0 <= rs;
                                data1 <= signExtImm ;

			-- ori
			when "001101" =>
				ALU_opcode <= "0110";
                                data0 <= rs;
                                data1 <= signExtImm ;

			-- xori
			when "001110" =>
				ALU_opcode <= "1000";
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
                               data0 <= instruction_addr_in;
                               data1 <= x"00000008";

			when others =>
				ALU_opcode <= "1111";
                                data0 <=(others =>'0');
                                data1 <=(others =>'0');

		end case;
           -- replace data0 and data1 when forward happend for last intruction
          if(data_rs_forward_mem_en = '1' and rs_flag = '1')then
               data0 <= temp_result; -- the result from last instruction
          end if;
          if(data_rt_forward_mem_en = '1' and rt_flag = '1')then
               data1 <= temp_result; -- the result from last instruction
          end if;
        end if;

        if(writeback_data' event) then
          -- replace data0 and data1 when forward happend for last last instruction

          if(data_rs_forward_wb_en = '1' and  rs_flag = '1')then
               data0 <= writeback_data; -- the result from last last instruction
          end if;
          if(data_rt_forward_wb_en = '1' and  rt_flag = '1')then
              data1 <= writeback_data; -- the result from last last  instruction
          end if;
          end if;


    if(falling_edge(clk) and clk'event ) then


             -- for SW instructon forward, to deal with the rt data passed to mem stage
                    if(bran_taken_in = '1') then
                        rt_data <= (others => '0');
                     else
                        if(isSWforward = '1' and (data_rt_forward_mem_en = '1')) then
                          rt_data <= temp_result;
                        elsif(isSWforward = '1' and (data_rt_forward_wb_en = '1'))then
                          rt_data <= writeback_data;
                        else
                          rt_data <= rt;
                       end if;
                    end if;

          if(bran_taken_in = '0') then
                        case ALU_opcode is
				--add, addi, sw,lw
				when "0000" =>
					temp_result <= std_logic_vector(signed(data0) + signed(data1));

				--sub
				when "0001" =>
					temp_result <= std_logic_vector(signed(data0) - signed(data1));

				--mult
				when "0010" =>
					temp_HILO <= std_logic_vector(signed(data0) * signed(data1));

				--div
				when "0011" =>
					temp_HILO <= std_logic_vector(signed(data0) mod signed(data1)) & std_logic_vector(signed(data0) / signed(data0));

				--slt, slti
				when "0100" =>
					if (signed(data0) < signed(data1)) then
						temp_result <= "00000000000000000000000000000001";
					else
						temp_result <= "00000000000000000000000000000000";
					end if;

				--and, andi
				when "0101" =>
					temp_result <= data0 AND data1;

				--or, ori
				when "0110" =>
					temp_result <= data0 OR data1;

				--nor
				when "0111" =>
					temp_result <= data0 NOR data1;

				--xor, xori
				when "1000" =>
					temp_result <= data0 XOR data1;

				--mfhi
				when "1001" =>
					temp_result <= temp_HILO(63 downto 32);

				--mflo
				when "1010" =>
					temp_result <= temp_HILO(31 downto 0);

				--lui
				when "1011" =>
					temp_result <= to_stdlogicvector(to_bitvector(data1) sll 16); -- it should be data1 instead of data_b?

				--sll
				when "1100" =>	-- sll: R[rd] = R[rt] << shamt, shamt is data1(10 downto 6)
						-- Aaron: should use the data1(10 downto 6) instead of whole 32 bits data1
					temp_result <= std_logic_vector(signed(data0) sll to_integer(signed(data1(10 downto 6))));

				--srl
				when "1101" =>	-- srl: R[rd] = R[rt] >> shamt, shamt is data1(10 downto 6)
						-- Aaron: should use the data1(10 downto 6) instead of whole 32 bits data1
					temp_result <= std_logic_vector(signed(data0) srl to_integer(signed(data1(10 downto 6))));

				--sra
				when "1110" =>	-- sra: R[rd] = R[rt] >>> shamt, shamt is data1(10 downto 6)
						-- Aaron: it should use the data1(10 downto 6) instead of whole 32 bits data1
					temp_result <= std_logic_vector(shift_right(signed(data0) , to_integer(signed(data1(10 downto 6)))));

				--beq, bne
				--when "1111" =>
					--if (signed(data0) = signed(data1)) then
					--	temp_zero <= '1';
					--else
					--	temp_zero <= '0';
					--end if;

				-- j, jr, jal

				when others =>
					--temp_zero <= '0';
					temp_result <= (others => '0');

			     end case;
                   else
                 temp_result <= (others => '0');
                 end if;
                    -- save others things to buffer

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
                     bran_taken<= temp_bran_taken;
                    branch_addr <= temp_branch_addr;
                    end if;

    end if;

end process;
end behaviour;
