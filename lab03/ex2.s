.globl main

.data
source:
    .word   3
    .word   1
    .word   4
    .word   1
    .word   5
    .word   9
    .word   0
dest:
    .word   0
    .word   0
    .word   0
    .word   0
    .word   0
    .word   0
    .word   0
    .word   0
    .word   0
    .word   0

.text
fun:
    addi t0, a0, 1
    sub t1, x0, a0
    mul a0, t0, t1
    jr ra

main:
    # BEGIN PROLOGUE
    addi sp, sp, -20
    sw s0, 0(sp)
    sw s1, 4(sp)
    sw s2, 8(sp)
    sw s3, 12(sp)
    sw ra, 16(sp)
    # END PROLOGUE
    addi t0, x0, 0  # t0表示k
    addi s0, x0, 0  # t1表示sum
    la s1, source
    la s2, dest
loop:
    slli s3, t0, 2  #左移两位，乘4，s3表示需要移动4*k个字节
    add t1, s1, s3  #t1表示source[k]
    lw t2, 0(t1)    
    beq t2, x0, exit
    add a0, x0, t2 # a0是函数调用的参数，给fun用
    addi sp, sp, -8
    # k和source[k]待会还要用，所以存起来
    sw t0, 0(sp)
    sw t2, 4(sp)
    #开始进入fun函数
    jal fun  
    # 恢复寄存器
    lw t0, 0(sp)
    lw t2, 4(sp)
    addi sp, sp, 8
    # RISCV规定a0存函数返回值，这里是把函数返回值传给t2
    add t2, x0, a0  
    add t3, s2, s3  #t3表示dest[k]
    sw t2, 0(t3)
    add s0, s0, t2
    addi t0, t0, 1
    #无条件跳转回 loop 标签,x0表示不需要存返回值
    jal x0, loop
exit:
    add a0, x0, s0
    # BEGIN EPILOGUE
    lw s0, 0(sp)
    lw s1, 4(sp)
    lw s2, 8(sp)
    lw s3, 12(sp)
    lw ra, 16(sp)
    addi sp, sp, 20
    # END EPILOGUE
    jr ra
