import random
from bitstring import BitArray
# ==================================================
# @1000
# 21 4c // I_inst: load 010 0110 0001 00001 rs =  6, rt =  1, imm =   1
# @1002
# 4d 54 // I_inst: load 0101010001001101 rs = 10, rt =  2, imm =  13
# @1004
# 6e 42 // I_inst: load 0100001001101110 rs =  1, rt =  3, imm =  14
# ==================================================
# @1000
# e1 ff // -31
# @1002
# 1d 00 //  29
# @1004
# f2 ff // -14
# ==================================================

f_DRAM_inst = open('./raw_DRAM_inst.dat', 'w')
f_DRAM_data = open('./DRAM_data.dat', 'w')
f_inst_func = open('./inst_func.txt', 'w')
kAddrMin = 0x1000
kAddrMax = 0x1fff
kDataMin = 0
kDataMax = 100
kFunction = ['ADD', 'SUB', 'SetLessThan', 'Mult', 'Load', 'Load', 'Load', 'Store', 'Store', 'Store', 'BranchOnEqual']     # ['Jump']
kOffset = 0x1000
# ( rs + immediate ) * 2 = 0x000 ~ 0xffe (12-bits)
# ( 0xffe - 0x000 ) / 2 = 4094 / 2 = 2047
# DRAM[ 0 ~ 2047 ]
# ( rs: 4-bits, 0~15 ) ( immediate: 5-bits, 0~31 )

def GenerateDRAM_inst():
    rt_int = -1
    # 'store' values to core_r0 ~ core_r15
    for i in range(kAddrMin, kAddrMin + 32, 2):
        f_DRAM_inst.write('@' + format(i, 'x') + '\n')
        #
        rt_int = rt_int + 1
        rs = '{:0>4b}'.format( random.randint(0, 15), 'x')
        rt = '{:0>4b}'.format( rt_int, 'x')
        immediate = '{:0>5b}'.format( random.randint(0, 15), 'x')
        inst = '010' + rs + rt + immediate
        #
        b = BitArray(bin=inst)
        temp = '{:0>4x}'.format(b.uint, 'x')
        # f_DRAM_inst.write( inst + '\n')
        f_DRAM_inst.write( temp[2] + temp[3] + ' ' + temp[0] + temp[1] + '\n')
        f_inst_func.write('@' + format(i, 'x') + ' : ' + 'Load' + '\n')

    jump_flag = False
    jump_cnt = 0
    for i in range(kAddrMin+32, kAddrMax-2, 2):
        f_DRAM_inst.write('@' + format(i, 'x') + '\n')
        #
        if jump_flag == False:
            func = random.choice(kFunction+['Jump'])
            # func = 'Jump'
        else:
            func = random.choice(kFunction)
        rs = '{:0>4b}'.format(random.randint(0, 15), 'x')
        rt = '{:0>4b}'.format(random.randint(0, 15), 'x')
        rd = '{:0>4b}'.format(random.randint(0, 15), 'x')
        immediate = '{:0>5b}'.format(random.randint(0, 31), 'x')
        if func == 'ADD':
            inst = '000' + rs + rt + rd + '0'
        elif func == 'SUB':
            inst = '000' + rs + rt + rd + '1'
        elif func == 'SetLessThan':
            inst = '001' + rs + rt + rd + '0'
        elif func == 'Mult':
            inst = '001' + rs + rt + rd + '1'
        elif func == 'Load':    # TODO: does not deal with data dependence
            inst = '010' + rs + rt + immediate
        elif func == 'Store':   # TODO: does not deal with data dependence
            inst = '011' + rs + rt + immediate
        elif func == 'BranchOnEqual':
            immediate = random.randint(0, 15)    # only positive values
            # immediate = random.randint(0, 31)
            # if immediate%2==1:
            #     immediate = immediate - 1
            immediate = '{:0>5b}'.format(immediate, 'x')
            inst = '100' + rs + rt + immediate
        elif func == 'Jump':
            jump_flag = True
            #
            a = max(kAddrMin, i - 64 + 1 + 64)
            b = min(kAddrMax, i + 64 + 64)
            addr_int = random.randint(a, b)
            # print(format(i, 'x')+' a = '+str(a)+' b = '+str(b)+' from ' + str(i) + ' to ' + str(addr_int))
            if addr_int%2 == 1:
                addr_int = addr_int - 1
            addr = '{:0>13b}'.format(addr_int, 'x')
            inst = '101' + addr
        #
        if jump_flag == True:
            jump_cnt = jump_cnt + 1
            if jump_cnt == 10:
                jump_flag = False
                jump_cnt = 0
        #
        b = BitArray(bin=inst)
        temp = '{:0>4x}'.format(b.uint, 'x')
        # f_DRAM_inst.write( func + ' : ' + inst + '\n')
        f_DRAM_inst.write(temp[2] + temp[3] + ' ' + temp[0] + temp[1] + '\n')
        f_inst_func.write('@' + format(i, 'x') + ' : ' + func + '\n')
    #
    f_DRAM_inst.write('@' + format(0x1ffe, 'x') + '\n')
    addr_int = random.randint(kAddrMin, kAddrMin + 256)
    if addr_int % 2 == 1:
        addr_int = addr_int - 1
    addr = '{:0>13b}'.format(addr_int, 'x')
    inst = '101' + addr
    b = BitArray(bin=inst)
    temp = '{:0>4x}'.format(b.uint, 'x')
    f_DRAM_inst.write(temp[2] + temp[3] + ' ' + temp[0] + temp[1] + '\n')
    f_inst_func.write('@' + format(0x1ffe, 'x') + ' : ' + func + '\n')

def GenerateDRAM_data():
    j = 0
    for i in range(kAddrMin, kAddrMax, 2):
        f_DRAM_data.write('@' + format(i, 'x') + '\n')
        j = j + 1
        temp = '{:0>4x}'.format( random.randint(kDataMin, kDataMax), 'x')
        f_DRAM_data.write( temp[2] + temp[3] + ' ' + temp[0] + temp[1] + '\n')

if __name__ == '__main__':
    GenerateDRAM_data()
    GenerateDRAM_inst()

f_DRAM_inst.close()
f_DRAM_data.close()
f_inst_func.close()