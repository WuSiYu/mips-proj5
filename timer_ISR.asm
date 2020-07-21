addi $sp, $sp, -12
sw $t0, 8($sp)
sw $s0, 4($sp)
sw $s1, 0($sp)

lw $s0, 0($gp)
lw $s1, 4($gp)
# $s0 旧读入值
# $s1 旧读入值累加

addiu $s1, $s1, 1
lw $t0, 0x7900($zero)
beq $s0, $t0, not_changed
move $s0, $t0
move $s1, $t0
not_changed:
sw $s1, 0x7800($zero)



#li $t0, 0x02FAF080	# 50M
li $t0, 100
sw $t0, 0x7F04($zero)	# set it to timer's [preset] reg

sw $s0, 0($gp)
sw $s1, 4($gp)

lw $t0, 8($sp)
lw $s0, 4($sp)
lw $s1, 0($sp)
addi $sp, $sp, 12

eret
