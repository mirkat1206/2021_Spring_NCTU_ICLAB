import random
from bitstring import Bits

f_DRAM_data = open('./DRAM_data.dat', 'r')
# 1st: recreate illegal operation
# f_DRAM_inst = open('./raw_DRAM_inst.dat', 'r')
# f_new_DRAM_inst = open('./DRAM_inst0.dat', 'w')
# 2nd: verify 1st
# f_DRAM_inst = open('./DRAM_inst0.dat', 'r')
# f_new_DRAM_inst = open('./DRAM_inst1.dat', 'w')
# 3rd: verify 2st
f_DRAM_inst = open('./DRAM_inst1.dat', 'r')
f_new_DRAM_inst = open('./DRAM_inst.dat', 'w')

kPATNUM = 1000
kAddrMin = 0x1000
kAddrMax = 0x1fff
kFunction = ['ADD', 'SUB', 'SetLessThan', 'Mult', 'Load', 'Store', 'BranchOnEqual', 'Jump']
kOffset = 0x1000

core_reg = [0 for i in range(16)]
DRAM_data = {}
DRAM_inst = {}
operation_cnt = {'ADD': 0, 'SUB': 0, 'SetLessThan': 0, 'Mult': 0,'Load': 0, 'Store': 0, 'BranchOnEqual': 0, 'Jump': 0}

def char2int(c):
    if c>='0' and c<='9':
        return ord(c) - ord('0')
    elif c=='a':
        return 10
    elif c=='b':
        return 11
    elif c=='c':
        return 12
    elif c=='d':
        return 13
    elif c=='e':
        return 14
    elif c=='f':
        return 15

def read_DRAM(f, DRAM):
    lines = []
    for line in f:
        lines.append(line.rstrip())
    for i in range(0, len(lines), 2):
        addr = lines[i].replace('@', '')
        value = char2int(lines[i+1][3])*16*16*16 + char2int(lines[i+1][4])*16*16 + char2int(lines[i+1][0])*16 + char2int(lines[i+1][1])
        DRAM[addr] = value

def create_inst(pc):
    func = random.choice(kFunction)
    rs = '{:0>4b}'.format(random.randint(0, 15), 'x')
    rt = '{:0>4b}'.format(random.randint(0, 15), 'x')
    rd = '{:0>4b}'.format(random.randint(0, 15), 'x')
    immediate = '{:0>5b}'.format(random.randint(0, 31), 'x')
    # func = 'Jump'
    if func == 'ADD':
        inst = '000' + rs + rt + rd + '0'
    elif func == 'SUB':
        inst = '000' + rs + rt + rd + '1'
    elif func == 'SetLessThan':
        inst = '001' + rs + rt + rd + '0'
    elif func == 'Mult':
        inst = '001' + rs + rt + rd + '1'
    elif func == 'Load':  # TODO: does not deal with data dependence
        inst = '010' + rs + rt + immediate
    elif func == 'Store':  # TODO: does not deal with data dependence
        inst = '011' + rs + rt + immediate
    elif func == 'BranchOnEqual':
        immediate = '{:0>5b}'.format(random.randint(0, 15), 'x')  # only positive values
        inst = '100' + rs + rt + immediate
    elif func == 'Jump':
        a = max(kAddrMin, pc - 64 + 1)
        b = min(kAddrMax, pc + 64)
        # -------------
        a = a + 64           # TODO: does not deal with data dependence
        b = b + 2000
        a = max(kAddrMin, a)
        b = min(kAddrMax, b)
        # -------------
        addr_int = random.randint(a, b)
        print('a = ' + str(a) + ' b = ' + str(b) + ' from ' + str(pc) + ' to ' + str(addr_int))
        if addr_int % 2 == 1:
            addr_int = addr_int - 1
        addr = '{:0>13b}'.format(addr_int, 'x')
        inst = '101' + addr
    return Bits(bin=inst).uint

def simulate(pc):
    patcnt = 0
    recreate_cnt = 0
    while True:
        inst = '{:0>16b}'.format(DRAM_inst['{:0>4x}'.format( pc, 'x')])
        opcode = inst[0:3]
        rs = inst[3:7]
        rt = inst[7:11]
        rd = inst[11:15]
        rs_int = int(inst[3:7], 2)
        rt_int = int(inst[7:11], 2)
        rd_int = int(inst[11:15], 2)
        func = inst[15]
        imm = inst[11:16]
        imm_int = Bits(bin=imm).int
        addr = inst[3:16]
        # 16-bits integer range : -32, 768 to 32, 767
        is_legal = 0
        if opcode == '000' and func == '0':  # ADD
            print('ADD')
            temp = core_reg[rs_int] + core_reg[rt_int]
            if temp >= -32768 and temp <= 32767:
                operation_cnt['ADD'] = operation_cnt['ADD'] + 1
                core_reg[rd_int] = temp
                is_legal = True
        elif opcode == '000' and func == '1':  # SUB
            print('SUB')
            temp = core_reg[rs_int] - core_reg[rt_int]
            if temp >= -32768 and temp <= 32767:
                operation_cnt['SUB'] = operation_cnt['SUB'] + 1
                core_reg[rd_int] = temp
                is_legal = True
        elif opcode == '001' and func == '0':  # SetLessThan
            print('SetLessThan')
            if core_reg[rs_int] < core_reg[rt_int]:
                core_reg[rd_int] = 1
            else:
                core_reg[rd_int] = 0
            operation_cnt['SetLessThan'] = operation_cnt['SetLessThan'] + 1
            is_legal = True
        elif opcode == '001' and func == '1':  # Mult
            print('Mult')
            temp = core_reg[rs_int] * core_reg[rt_int]
            if temp >= -32768 and temp <= 32767:
                operation_cnt['Mult'] = operation_cnt['Mult'] + 1
                core_reg[rd_int] = temp
                is_legal = True
        elif opcode == '010':  # Load
            print('Load')
            temp = (core_reg[rs_int] + imm_int) * 2 + kOffset
            if temp >= kAddrMin and temp <= kAddrMax:
                operation_cnt['Load'] = operation_cnt['Load'] + 1
                core_reg[rt_int] = DRAM_data['{:0>4x}'.format(temp, 'x')]
                is_legal = True
        elif opcode == '011':  # Store
            print('Store')
            temp = (core_reg[rs_int] + imm_int) * 2 + kOffset
            if temp >= kAddrMin and temp <= kAddrMax:
                operation_cnt['Store'] = operation_cnt['Store'] + 1
                DRAM_data['{:0>4x}'.format(temp, 'x')] = core_reg[rt_int]
                is_legal = True
        elif opcode == '100':  # BranchOnEqual
            print('BranchOnEqual')
            temp = pc + 2 + imm_int*2       # fuck u bug
            if temp >= kAddrMin and temp <= kAddrMax and temp%2 == 0:
                operation_cnt['BranchOnEqual'] = operation_cnt['BranchOnEqual'] + 1
                if core_reg[rs_int] == core_reg[rt_int]:
                    print("yes")
                    new_pc = temp
                    new_flag = 1
                else:
                    new_flag = 0
                is_legal = True
        elif opcode == '101':  # Jump
            print('Jump')
            temp_ = '000' + addr
            temp = Bits(bin=temp_).int
            print(temp_ + ' : ' + str(temp))
            if temp >= kAddrMin and temp <= kAddrMax and temp%2 == 0:
                print('from '+str(pc)+' to '+str(temp))
                operation_cnt['Jump'] = operation_cnt['Jump'] + 1
                new_pc = temp
                is_legal = True
        else:
            print('Error: wrong instruction ' + inst)
            exit(-1)
        #
        if is_legal == True:
            patcnt = patcnt + 1
            # print(str(patcnt) + '  --  ' + '{:0>4x}'.format( pc, 'x') + ', ' + str(pc) + ' : ' + inst + ' ' + '{:0>4x}'.format(DRAM_inst['{:0>4x}'.format( pc, 'x')]) )
            print(str(patcnt) + '  --  ' + '{:0>4x}'.format( pc, 'x') + ', ' + str((pc-16*16*16)//2) + ' : ' + inst + ' ' + '{:0>4x}'.format(DRAM_inst['{:0>4x}'.format( pc, 'x')]) )
            print_core_reg()
            if opcode =='101':
                pc = new_pc
            elif opcode == '100' and new_flag == 1:
                pc = new_pc
            else:
                pc = pc + 2
            if patcnt == kPATNUM:
                break
            print('\n')
        else:
            recreate_cnt = recreate_cnt + 1
            new_inst = create_inst(pc)
            print('{:0>4x}'.format( pc, 'x') + ' : ' + 'recreate instruction')
            print('old : ' + '{:0>16b}'.format(DRAM_inst['{:0>4x}'.format( pc, 'x')] ,'x') + '\tnew : ' + '{:0>16b}'.format(new_inst ,'x'))
            DRAM_inst['{:0>4x}'.format( pc, 'x')] = new_inst
        #
        if patcnt%100 == 0:
            print_core_reg()

    return recreate_cnt

def write_DRAM(DRAM):
    for i in range(kAddrMin, kAddrMax, 2):
        f_new_DRAM_inst.write('@' + format(i, 'x') + '\n')
        temp = '{:0>4x}'.format(DRAM_inst[format(i, 'x')], 'x')
        f_new_DRAM_inst.write(temp[2] + temp[3] + ' ' + temp[0] + temp[1] + '\n')


def print_summary():
    #
    print('total operation count:')
    print('ADD = ' + str(operation_cnt['ADD']))
    print('SUB = ' + str(operation_cnt['SUB']))
    print('SetLessThan = ' + str(operation_cnt['SetLessThan']))
    print('Mult = ' + str(operation_cnt['Mult']))
    print('Load = ' + str(operation_cnt['Load']))
    print('Store = ' + str(operation_cnt['Store']))
    print('BranchOnEqual = ' + str(operation_cnt['BranchOnEqual']))
    print('Jump = ' + str(operation_cnt['Jump']))
    print('recreate_cnt = ' + str(recreate_cnt))

def print_core_reg():
    for i in range(16):
        print(str(i) + ' : ' + str(core_reg[i]), end='\t')
        if i%8 == 7:
            print()

if __name__ == '__main__':
    read_DRAM(f_DRAM_data, DRAM_data)
    read_DRAM(f_DRAM_inst, DRAM_inst)
    print(DRAM_data)
    print(DRAM_inst)
    #
    recreate_cnt = simulate(16*16*16)      # 0x1000
    write_DRAM(DRAM_inst)
    #
    print('----------------------------------------------')
    print_summary()
    print_core_reg()
    print('----------------------------------------------')


f_DRAM_data.close()
f_DRAM_inst.close()
f_new_DRAM_inst.close()



