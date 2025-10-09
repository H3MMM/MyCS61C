.globl factorial

.data
n: .word 10

.text
main:
    la t0, n
    lw a0, 0(t0)
    jal ra, factorial

    addi a1, a0, 0
    addi a0, x0, 1
    ecall # Print Result

    addi a1, x0, '\n'
    addi a0, x0, 11
    ecall # Print newline

    addi a0, x0, 10
    ecall # Exit

factorial:
    addi sp, sp, -8
    sw ra, 4(sp)
    sw a0, 0(sp)

    addi t0, x0, 1
    beq  a0, t0, base
    addi a0, a0, -1
    jal ra, factorial

    lw t1, 0(sp)
    mul a0, t1, a0

    j done

base:
    addi a0, x0, 1

done:
    lw ra, 4(sp)
    addi sp, sp, 8
    jr ra



    