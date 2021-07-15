import random as rd

PATNUM = 10 
MATRIX_A_MAX = 3 	# too big may cause some problem
MATRIX_A_MIN = 0
MATRIX_B_MAX = 1 	# too big may cause some problem
MATRIX_B_MIN = 0
f_DRAM_read = open("./DRAM_read.dat", "w")
f_DRAM1 = open("./DRAM1.dat", "w")


# DRAM_read instruction
def DRAM_read_intruction() :
	for i in range(0x1000, 0x2000, 4) :
		f_DRAM_read.write('@' + format(i, 'x') + '\n')
		# [15: 2] MSB address for DRAM_read
		# [ 1: 0] OP : 00 for multiplication, 11 for convolutioin
		while True :
			temp_hex = rd.randint(int(0x2000), int(0x2fff)-16*16*4)
			if temp_hex%16==0 or temp_hex%16==4 or temp_hex%16==8 or temp_hex%16==12 or temp_hex%16==3 or temp_hex%16==7 or temp_hex%16==11 or temp_hex%16==15 :
				break;
		# temp = 	format(rd.randint(int(0x200), int(0x2ff)), 'x') + format(rd.choice([0, 4, 8, 12, 3, 7, 11, 15]), 'x')
		temp = 	format( temp_hex, 'x')
		# f_DRAM_read.write( temp + " : " )
		f_DRAM_read.write( temp[2:4] + ' ' + temp[0:2] )
		f_DRAM_read.write(' ')
		# [31:18] MSB address for DRAM1
		# [17:16] NA
		while True :
			temp_hex = rd.randint(int(0x1000), int(0x1fff)-16*16*4)
			if temp_hex%16==0 or temp_hex%16==4 or temp_hex%16==8 or temp_hex%16==12 :
				break;
		# temp = 	format(rd.randint(int(0x100), int(0x1ff)), 'x') + format(rd.choice([0, 4, 8, 12]), 'x')
		temp = 	format( temp_hex, 'x')
		# f_DRAM_read.write( temp + " : " )
		f_DRAM_read.write( temp[2:4] + ' ' + temp[0:2] )
		f_DRAM_read.write('\n')

# DRAM_read matrix B`
def DRAM_read_matrix() :
	for i in range(0x2000, 0x3000, 4) :
		f_DRAM_read.write('@' + format(i, 'x') + '\n')
		# 32 bits
		temp = '{:0>4d}'.format(rd.randint(MATRIX_B_MIN, MATRIX_B_MAX), 'x')
		f_DRAM_read.write( temp[3] + ' ' + temp[2] + ' ' + temp[1] + ' ' + temp[0] + '\n' )

# DRAM1 matrix A
def DRAM1_matrix() :
	for i in range(0x1000, 0x2000, 4) :
		f_DRAM1.write('@' + format(i, 'x') + '\n')
		# 32 bits
		temp = '{:0>4d}'.format(rd.randint(MATRIX_A_MIN, MATRIX_A_MAX), 'x')
		f_DRAM1.write( temp[3] + ' ' + temp[2] + ' ' + temp[1] + ' ' + temp[0] + '\n' )

if __name__ == '__main__' :
	DRAM_read_intruction()
	DRAM_read_matrix()
	DRAM1_matrix()

f_DRAM_read.close()
f_DRAM1.close()
