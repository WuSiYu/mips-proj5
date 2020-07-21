j main

# stop at here if self-check FAILED
error_dected:
j error_dected

# stop at here if self-check PASS
main_end:
j main_end


# 埃拉托斯特尼质数筛
# func range_prime($a0 = range_end, $a1 = mark_value) -> $v0: prime_count
range_prime:
	ori $v0, $zero, 0

	or $t0, $zero, $a1
	andi $t0, $t0, 0xff
	or $t7, $zero, $t0		# $t7 = mark_value byte
	ori $t1, $zero, 8
	sllv $t1, $t0, $t1
	or $t0, $t0, $t1
	sh $t0, 0x2000($zero)	# 0 and 1 are not prime number

	ori $t3, $zero, 1		# i for num loop
	loopA:
		addiu $t3, $t3, 1	# i($t3) start from first prime: 2
		
		lbu $t2, 0x2000($t3)	# - same time
		beq $t3, $a0, end	# -

		beq $t2, $t7, loopA	# go next loopA, if this i is not prime
		
		addiu $v0, $v0, 1	# prime_count++

		addu $t2, $t3, $t3	# j($t2) for ram mark
		loopB:
			subu $t1, $a0, $t2
			blez $t1, loopA
		
			sb $a1, 0x2000($t2)	# - same time
			addu $t2, $t2, $t3	# -
			j loopB
	
		j loopA

	end:
	jr $ra


main:


# slt指令测试
li $t1, -5
slti $t0, $t1, 10
blez $t0, error_dected
slti $t0, $t1, -2
blez $t0, error_dected
li $t1, 7
slti $t0, $t1, 10
blez $t0, error_dected
li $t1, -0x80000000	# 防溢出测试
li $t2, 0x7fffffff
slt $t0, $t1, $t2
blez $t0, error_dected

# lui指令测试
lui $t0, 0x1234
ori $t0, $t0, 0x5678

addiu $t1, $zero, -1

and $t2, $t0, $t1
bne $t2, $t0, error_dected

# 并发控制单元测试
j ctl_hazard
lw $t0, 0x2000($zero)
ctl_hazard:
add $t3, $t0, $zero
sw $t3, 0x2000($zero)
lw $t1, 0x2000($zero)
move $t0, $t1
bne $t0, $t2, error_dected
lw $t1, 0x2000($zero)
lui $t1, 0xffff
ori $t1, $t1, 0xffff
addiu $t1, $t1, 1
xor $t0, $t0, $t1
bne $t0, $t2, error_dected
lw $t7, 0x2000($zero)
move $t0, $zero
sw $zero, 0x2000($zero)
move $t2, $zero
move $t1, $zero
sw $zero, 0x2000($zero)

# 函数调用测试
# call range_prime
ori $a0, $zero, 100
lui $a1, 0x1234		
addiu $a1, $a1, 0x5678	# set a1 = 0x12345678
jal range_prime		# 返回1~100间素数的个数

ori $t0, $zero, 25		# 应为25个
bne $v0, $t0, error_dected

j main_end
