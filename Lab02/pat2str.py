# pat2str.py

# store inputs
nums = []

# input pattern file
PATFILE = "pat.txt"
f = open(PATFILE, 'r')
lines = f.readlines()
for line in lines : 
    words = line.split()
    for word in words :
        # print(repr(word))
        nums.append(word)
# for num in nums :
    # print(num, end=',')
f.close()

cnt = 0 
PATNUM = int(nums[cnt]) 
cnt = cnt + 1
for i in range(PATNUM) :
# for i in range(1) :
    print("PATTERN NO. ", i)
    # string_task
    print("=========== string ===========")
    str_ = ""
    scnum = int(nums[cnt])
    cnt = cnt + 1
    for j in range(scnum) :
        str_ = str_ + chr(int(nums[cnt]))
        cnt = cnt + 1
    print(str_)
    print("==============================")
    # pattern_task
    print("=========== pattern ==========")
    pattern_num = int(nums[cnt])
    cnt = cnt + 1 
    for j in range(pattern_num) :
        pttn = ""
        pcnum = int(nums[cnt])
        cnt = cnt + 1
        for k in range(pcnum) :
            pttn = pttn + chr(int(nums[cnt]))
            cnt = cnt + 1
        print(j, ":\t", pttn, end="")
        match = int(nums[cnt])
        cnt = cnt + 1
        match_index = int(nums[cnt])
        cnt = cnt + 1
        print("\t: ", match, " with pos : ", match_index)
    print("==============================")