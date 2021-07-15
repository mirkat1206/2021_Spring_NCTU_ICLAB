import random as rd
import numpy as np 

# Lab05: Matrix Computation {setup, addition, multiplication, transpose, mirror, rotate counterclockwise}

PATNUM = 10     # number of setup
OP_NUM = 100    # number of operations after a setup
MATRIX_SIZE = [2, 4, 8, 16]     # possible size of a matrix : 2x2, 4x4, 8x8, 16x16
MATRIX_SIZE_MAX_INDEX = 3       # 3: regular patterns, 0~2: debug use
PRIME = 2**31 - 1
# PRIME = 2**3 - 1      # debug use
# 0: setup, 1: addition(41%), 2: multiplication(41%), 3: transpose(6%), 4: mirror(6%), 5: rotate counter clockwise(6%)
# most are addition and multiplication
OPERATIONS = ["addition"]*41 + ["multiplication"]*41 + ["transpose"]*6 + ["mirror"]*6 + ["rotate"]*6
f = open("./pat5.txt", "w")

# fprint
def fprint_matrix(matrix, fout) :
    for line in matrix :
        for num in line :
            fout.write(str(num))
            fout.write(" ")
        fout.write("\n")
    fout.write("\n")


f.write(str(PATNUM))
f.write("\n")
f.write(str(OP_NUM))
f.write("\n\n\n")

for patcnt in range(PATNUM) :
    # decide matrix size
    size_index = rd.randint(0,MATRIX_SIZE_MAX_INDEX)
    size = MATRIX_SIZE[size_index]
    # setup
    # matrix_c = np.random.randint(0, PRIME-1, size=size).reshape((size,size))
    matrix_c = np.array([[rd.randint(0,8-1) for i in range(size)] for j in range(size)], dtype=object)
    # matrix_c = np.array([[rd.randint(0,PRIME-1) for i in range(size)] for j in range(size)], dtype=object)
    # print(matrix_c)
    f.write("0\n")
    f.write(str(size_index))
    f.write("\n")
    fprint_matrix(matrix_c, f)
    fprint_matrix(matrix_c, f)
    # 
    for op_cnt in range(OP_NUM) :
        opcode = rd.choice(OPERATIONS)

        # print(opcode)

        if opcode=="addition" :
            matrix_m = np.array([[rd.randint(0,8-1) for i in range(size)] for j in range(size)], dtype=object)
            # matrix_m = np.array([[rd.randint(0,PRIME-1) for i in range(size)] for j in range(size)], dtype=object)
            matrix_c = np.add(matrix_m, matrix_c)
            matrix_c = np.remainder(matrix_c, PRIME)

            # print(matrix_m)
            f.write("1\n")
            fprint_matrix(matrix_m, f)
            fprint_matrix(matrix_c, f)

        elif opcode=="multiplication" :
            matrix_m = np.array([[rd.randint(0,8-1) for i in range(size)] for j in range(size)], dtype=object)
            # matrix_m = np.array([[rd.randint(0,PRIME-1) for i in range(size)] for j in range(size)], dtype=object)
            matrix_c = np.dot(matrix_m, matrix_c)
            matrix_c = np.remainder(matrix_c, PRIME)

            # print(matrix_m)
            f.write("2\n")
            fprint_matrix(matrix_m, f)
            fprint_matrix(matrix_c, f)

        elif opcode=="transpose" :
            matrix_c = matrix_c.T 
            
            f.write("3\n")
            f.write("0\n\n")

        elif opcode=="mirror" :
            matrix_c = np.flip(matrix_c, axis=1)

            f.write("4\n")
            f.write("0\n\n")

        elif opcode=="rotate" :
            matrix_c = np.rot90(matrix_c)

            f.write("5\n")
            f.write("0\n\n")

        # print(matrix_c)

f.close()
