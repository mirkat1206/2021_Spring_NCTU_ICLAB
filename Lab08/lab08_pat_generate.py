import random as rd

PATNUM = 1000
PRIME = 509
fin = open("./in.txt", "w")
fout = open("./out.txt", "w")
fbug = open("./debug.txt", "w")


def step0():
    a = [rd.randint(1, PRIME - 1) for x in range(6)]
    return a


def step1(a, mode0):
    if mode0 == '0':
        return a
    else:
        b = []
        for n in a:
            # algorithm 1
            m = format(507, "09b")
            A = 1
            B = n
            for i in range(8, -1, -1):
                # print(m[i], end=" : ")
                if m[i] == '1': A = (A * B) % PRIME
                B = (B * B) % PRIME
                # print(A, " ", B)
            b.append(A)
        return b


def step2(b, mode1):
    if mode1 == '0':
        return b
    else:
        c_origin = b[0] * b[1] * b[2] *b[3] * b[4] * b[5]
        c = [c_origin for x in range(6)]
        for i in range(6):
            c[i] = int((c[i] / b[i]) % PRIME)
        return c


def step3(c, mode2):
    if mode2 == '0':
        return c
    else:
        return sorted(c)


def step4(a, b, c, d):
    e = []
    for i in range(6):
        e.append((a[i] + b[i] + c[i] + d[i]) % PRIME)
    return e


def fprint_in(mode, a):
    fin.write(str(mode+"    "))
    for n in a:
        fin.write(str(str(n) + " "))
    fin.write("\n")


def fprint_out(e):
    for n in e:
        fout.write(str(str(n) + " "))
    fout.write("\n")


def fprint_debug(patcount, a, b, c, d, e):
    # fbug.write(str("NO." + str(patcount) + "\n"))
    fbug.write("\n")
    for n in a:
        fbug.write(str(str(n) + " "))
    fbug.write("\n")
    for n in b:
        fbug.write(str(str(n) + " "))
    fbug.write("\n")
    for n in c:
        fbug.write(str(str(n) + " "))
    fbug.write("\n")
    for n in d:
        fbug.write(str(str(n) + " "))
    fbug.write("\n")
    for n in e:
        fbug.write(str(str(n) + " "))
    fbug.write("\n")


def file_print(patcount, mode, a, b, c, d, e):
    fprint_in(mode, a)
    fprint_out(e)
    fprint_debug(patcount, a, b, c, d, e)


# main
fin.write(str(PATNUM))
fin.write("\n")
for patcount in range(PATNUM):
    # for mode_int in range(8) :
    mode_int = rd.randint(0, 7)
    mode = format(mode_int, "03b")
    # verilog : [2:0] in_mode
    # PDF : in_mode[0](MI), in_mode[1](MM), in_mode[2](Sort)
    # python : mode[0], mode[1], mode[2]
    # ------------------------------------------------------
    # mode[0]->in_mode[2] : Sort
    # mode[1]->in_mode[1] : MM
    # mode[2]->in_mode[0] : MI
    # print(mode)
    # print(str(mode[0])," ",str(mode[1])," ",str(mode[2]))
    a = step0()
    # a = [410, 125, 423, 212, 499, 96]
    # a = [13]
    # print(a)
    b = step1(a, mode[2])
    # print(b, " : ", mode[2])
    c = step2(b, mode[1])
    # print(c, " : ", mode[1])
    d = step3(c, mode[0])
    # print(d, " : ", mode[0])
    e = step4(a, b, c, d)
    # print(e)
    # print()
    file_print(patcount, mode, a, b, c, d, e)

fin.close()
fout.close()
fbug.close()
