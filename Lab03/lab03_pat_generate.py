from random import sample

PATNUM = 100
NUMBLANK = 15
# MAX_BLANK_NUM = 81  # generate blanks in 0~80 grid
MAX_BLANK_NUM = 50  # generate blanks in 0~50 grid, increase the chance of needing backtrace
FLAG_ILLEGAL = 1    # generate sudoku with solution(FLAG_ILLEGAL=0) or without solution(FLAG_ILLEGAL=1)
BASE = 3
SIDE = 9
f = open("./00_TESTBED/illegal_100.txt", "w")

# print
def print_board(board) :
    for line in board :
        for num in line :
            print(num, end=" ")
        print("")
    print("")

# fprint
def fprint_board(board, fout) :
    for line in board :
        for num in line :
            fout.write(str(num))
            fout.write(" ")
        fout.write("\n")
    fout.write("\n")

# print golden answer
def print_ans(board, blanks) :
    for r in range(SIDE) :
        for c in range(SIDE) :
            if ( r*SIDE + c )in blanks :
                print(board[r][c], end=" ")
    print("")

# fprint golden answer
def fprint_ans(board, blanks, fout) :
    for r in range(SIDE) :
        for c in range(SIDE) :
            if ( r*SIDE + c )in blanks :
                fout.write(str(board[r][c]))
                fout.write(" ")
    fout.write("\n\n")

# pattern for a baseline valid solution
def pattern(r, c) :
    return ( BASE*(r%BASE) + r//BASE + c )%SIDE 

# randomize rows, columns and numbers (of valid base pattern)
def shuffle(s) :
    return sample(s, len(s))

# generate sudoku puzzle
def sudoku_generator(illegal) :
    rBase = range(BASE)
    rows = [ g*BASE + r for g in shuffle(rBase) for r in shuffle(rBase) ]
    if illegal==1 :
        rows = shuffle(rows)
    cols = [ g*BASE + c for g in shuffle(rBase) for c in shuffle(rBase) ]
    nums = shuffle(range(1, SIDE+1 ))
    # produce board using randomized baseline pattern
    board = [ [nums[pattern(r, c)] for c in cols] for r in rows ]    
    # produce blanks
    blanks = sample(range(0,MAX_BLANK_NUM), NUMBLANK)
    for r in range(SIDE) :
        for c in range(SIDE) :
            if ( r*SIDE + c ) in blanks :
                board[r][c] = 0
    return [ board , blanks ]

def is_board_legal(board) :
    # check each number
    for n in range(1, 10) :
        # check each row
        for i in range(SIDE) :
            cnt = 0 
            for j in range(SIDE) :
                if board[i][j]==n :
                    cnt = cnt + 1
            if cnt>1 :
                return False
        # check each column
        for j in range(SIDE) :
            cnt = 0 
            for i in range(SIDE) :
                if board[i][j]==n :
                    cnt = cnt + 1
            if cnt>1 :
                return False
        # check each box
        for i in [1, 4, 7] :
            for j in [1, 4, 7] :
                cnt = 0
                for i_ in range(-1, 2) :
                    for j_ in range(-1, 2) :
                        if board[i+i_][j+j_]==n :
                            cnt = cnt + 1 
                if cnt>1 :
                    return False
    return True


# solve sudoku puzzle using DFS
def sudoku_solver(board, blanks) :
    if is_board_legal(board)==False :
        return False
    if dfs(board, blanks, 0)==True :
        return True
    else :
        print_board(board)
        return False
    # if dfs(board, blanks, 0)==True :
        # return True
        # return board

# is putting n in board[r][c] legal or not
def is_legal(board, r, c, n) :
    for i in range(SIDE) :
        # check row
        if board[r][i]==n : return False
        # check column
        if board[i][c]==n : return False
    r_base = ( r//3 )*3 + 1
    c_base = ( c//3 )*3 + 1
    for i in range(-1,2) :
        for j in range(-1,2) :
            # check box
            if board[r_base+i][c_base+j]==n :
                return False
    return True
    
# DFS
def dfs(board, blanks, i) :
    if i==len(blanks) :
        return True
    r = blanks[i]//SIDE
    c = blanks[i]%SIDE
    for n in range(1, 10) :
        if is_legal(board, r, c, n)==True :
            board[r][c] = n
            if dfs(board, blanks, i+1 )==True :
                return True
            board[r][c] = 0

    return False

# 
f.write(str(PATNUM))
f.write("\n\n")
for patcnt in range(PATNUM) :
    # board, blanks = sudoku_generator( patcnt%5==1 )
    board, blanks = sudoku_generator(FLAG_ILLEGAL)
    blanks = sorted(blanks)
    # print_board(board)
    fprint_board(board, f)
    # puzzle = board.copy()
    if sudoku_solver(board,blanks)==True :
        fprint_ans(board, blanks, f)
    else :
        f.write("10\n\n")
    # print(blanks)
    # print_ans(board, blanks)
    
f.close()