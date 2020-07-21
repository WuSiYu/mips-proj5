li $sp, 0x3000
li $gp, 0x2000

mfc0 $t0, $12
ori $t0, 0xfc01		# set im, ie (111111 00 000000 0 1)
mtc0 $t0, $12

#li $t0, 0x02FAF080	# 50M
li $t0, 100
sw $t0, 0x7F04($zero)	# set it to timer's [preset] reg
li $t0, 0x9		# timer im=1, mode=00, en=1
sw $t0, 0x7F00($zero)

loop:
	li $a0, 0
	li $a1, 0
	jal eight_queens
	sw $v0, 0x78fc($zero)
stuck:  j stuck
j loop


eight_queens:	# func eight_queens(a0:depth, a1:*array) -> v0:count
	addi $sp, $sp, -20
	sw $s0, 16($sp)
	sw $s1, 12($sp)
	sw $s2, 8($sp)
	sw $s3, 4($sp)
	sw $ra, 0($sp)

	
	li $t0, 5
	bne $t0, $a0, dfs_not_end
	li $v0, 1
	j func_end
	
	
	dfs_not_end:
	li $s2, 0	# the counter
	
	li $s0, 5	# for 0~7 new pos try
	pos_loop_continue:
	blez $s0, pos_loop_end
		addi $s0, $s0, -1
		
		move $s1, $a0		# for 0 ~ depth check scan
		scan_loop_continue:
		blez $s1, scan_loop_end
			addi $s1, $s1, -1
			add $t0, $a1, $s1	# t0 = &array[s1]
			lb $t1, ($t0)
			# if (pos == old_pos) continue;
			beq $t1, $s0, pos_loop_continue
			# if (abs(pos - old_pos) == (col - old_col) continue;
			sub $t2, $a0, $s1
			sub $t3, $s0, $t1
			beq $t2, $t3, pos_loop_continue
			sub $t3, $zero, $t3
			beq $t2, $t3, pos_loop_continue
			
			j scan_loop_continue
		scan_loop_end:
		
		add $t0, $a0, $a1
		sb $s0, ($t0)
		addi $a0, $a0, 1
		jal eight_queens
		addi $a0, $a0, -1
		add $s2, $s2, $v0
	
		j pos_loop_continue

	pos_loop_end:
	move $v0, $s2
	
	func_end:
	lw $s0, 16($sp)
	lw $s1, 12($sp)
	lw $s2, 8($sp)
	lw $s3, 4($sp)
	lw $ra, 0($sp)
	addi $sp, $sp, 20
	jr $ra
