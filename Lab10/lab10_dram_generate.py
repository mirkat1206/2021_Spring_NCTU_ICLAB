import random as rd

DEPOSIT_MIN = 500
DEPOSIT_MAX = 10000
CROP_CATEGORY = {"No_cat": 0, "Potato": 1, "Corn": 2, "Tomato": 4, "Wheat": 8}
CROP_STATUS = {"No_sta": 1, "Zer_sta": 2, "Fst_sta": 4, "Snd_sta": 8}
FST_WATER = {"No_cat": 0x0000, "Potato": 0x0010, "Corn": 0x0040, "Tomato": 0x0100, "Wheat": 0x0400}
SND_WATER = {"No_cat": 0x0000, "Potato": 0x0080, "Corn": 0x0200, "Tomato": 0x0800, "Wheat": 0x2000}
MAX_WATER = 0x3000
fout = open("./dram.dat", "w")


def DRAM_data():
    # land data
    id = 0
    for addr in range(0x10000, 0x103fc, 4):
        # addr
        fout.write('@' + format(addr, 'x') + '\n')

        # id
        fout.write('{:0>2x}'.format(id, 'x') + ' ')
        id += 1

        # status & crop category
        # print( rd.choice(["No_cat", "Potato", "Corn", "Tomato", "Wheat"]) )
#        crop = rd.choice(["No_cat", "Potato", "Corn", "Tomato", "Wheat"])
        crop = rd.choice(["Potato", "Corn", "Tomato", "Wheat"])
        crop_hex = '{:0>1x}'.format(CROP_CATEGORY[crop], 'x')
        # print( rd.choice(["No_sta", "Zer_sta", "Fst_sta", "Snd_sta"]) )
        if crop == "No_cat":
            status = "No_sta"
        else:
#            status = rd.choice(["Zer_sta", "Fst_sta", "Snd_sta"])
            status = rd.choice(["Zer_sta", "Snd_sta"])
        status_hex = '{:0>1x}'.format(CROP_STATUS[status], 'x')

        fout.write(status_hex + crop_hex + ' ')
        # water amount
        if status=="No_sta":
            water = 0
        elif status=="Zer_sta":
            water = rd.randint(0, FST_WATER[crop]-1)
        elif status=="Fst_sta":
            water = rd.randint(FST_WATER[crop], SND_WATER[crop]-1)
        elif status=="Snd_sta":
            water = rd.randint(SND_WATER[crop], MAX_WATER)
        water_hex = '{:0>4x}'.format(water, 'x')
        fout.write(water_hex[0:2] + ' ' + water_hex[2:4])
        # print(crop, status, water)
        # fout.write('\t\t' + crop + ' ' + status + ' ' + str(water) )

        fout.write('\n')
    # deposit data
    # addr
    fout.write('@' + format(0x103fc, 'x') + '\n')
    # deposit
    temp_int = rd.randint(DEPOSIT_MIN, DEPOSIT_MAX)
    temp_hex = '{:0>8x}'.format(temp_int, 'x')
    print("deposit : ", temp_int)
    # fout.write(temp_hex[6:8] + ' ' + temp_hex[4:6] + ' ' + temp_hex[2:4] + ' ' + temp_hex[0:2] + '\n')
    fout.write(temp_hex[0:2] + ' ' + temp_hex[2:4] + ' ' + temp_hex[4:6] + ' ' + temp_hex[6:8] )
    # fout.write('\t\t' + str(temp_int) )

    fout.write('\n')

DRAM_data()
