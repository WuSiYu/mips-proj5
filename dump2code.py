import time

IN_FILE = "dump.txt"
OUT_FILE = "code.txt"

f = open(OUT_FILE, 'w')

for line in open(IN_FILE).readlines():
    for i in range(4):
        f.write(line[i*2 : i*2+2] + '\n')

f.close()
