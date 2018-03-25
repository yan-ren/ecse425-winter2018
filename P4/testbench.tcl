proc AddWaves {} {

	add wave -position end sim:/testbench/clock
	add wave -position end sim:/testbench/programend
	add wave -position end sim:/testbench/readfinish
	add wave -position end sim:/testbench/insert_stall
	add wave -position end sim:/testbench/branch_addr
	add wave -position end sim:/testbench/branch_taken
	add wave -position end sim:/testbench/inst_addr
	add wave -position end sim:/testbench/inst
	add wave -position end sim:/testbench/writeback_register_address
	add wave -position end sim:/testbench/writeback_data
	add wave -position end sim:/testbench/EX_control_buffer_from_ex
	add wave -position end sim:/testbench/jump_addr
	add wave -position end sim:/testbench/inst_addr_from_id
	add wave -position end sim:/testbench/rs
	add wave -position end sim:/testbench/rt
	add wave -position end sim:/testbench/des_addr_from_id
	add wave -position end sim:/testbench/funct_from_id
	add wave -position end sim:/testbench/signExtImm
	add wave -position end sim:/testbench/opcode_bt_IdnEx
	add wave -position end sim:/testbench/EX_control_buffer_from_id
	add wave -position end sim:/testbench/MEM_control_buffer_from_id
	add wave -position end sim:/testbench/WB_control_buffer_from_id
	add wave -position end sim:/testbench/MEM_control_buffer_from_mem
	add wave -position end sim:/testbench/WB_control_buffer_from_wb
	add wave -position end sim:/testbench/opcode_bt_ExnMem
	add wave -position end sim:/testbench/ALU_result_from_ex
	add wave -position end sim:/testbench/des_addr_from_ex
	add wave -position end sim:/testbench/rt_data_from_ex
	add wave -position end sim:/testbench/bran_taken_from_ex
	add wave -position end sim:/testbench/bran_addr_from_ex
	add wave -position end sim:/testbench/MEM_control_buffer_from_ex
	add wave -position end sim:/testbench/WB_control_buffer_from_ex
	add wave -position end sim:/testbench/opcode_bt_MemnWb
	add wave -position end sim:/testbench/memory_data
	add wave -position end sim:/testbench/alu_result_from_mem
	add wave -position end sim:/testbench/des_addr_from_mem
	add wave -position end sim:/testbench/WB_control_buffer_from_mem
}

vlib work

vcom testbench.vhd
vcom register_file.vhd
vcom IF.vhd
vcom ID.vhd
vcom EX.vhd
vcom DataMem.vhd
vcom WB.vhd

vsim testbench

force -deposit clock 0 0 ns, 1 0.5 ns -repeat 1 ns

AddWaves

run 10000ns
