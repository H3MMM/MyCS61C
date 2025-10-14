.globl matmul

.text
# =======================================================
# FUNCTION: Matrix Multiplication of 2 integer matrices
# 	d = matmul(m0, m1)
# Arguments:
# 	a0 (int*)  is the pointer to the start of m0 
#	a1 (int)   is the # of rows (height) of m0
#	a2 (int)   is the # of columns (width) of m0
#	a3 (int*)  is the pointer to the start of m1
# 	a4 (int)   is the # of rows (height) of m1
#	a5 (int)   is the # of columns (width) of m1
#	a6 (int*)  is the pointer to the the start of d
# Returns:
#	None (void), sets d = matmul(m0, m1)
# Exceptions:
#   Make sure to check in top to bottom order!
#   - If the dimensions of m0 do not make sense,
#     this function terminates the program with exit code 72.
#   - If the dimensions of m1 do not make sense,
#     this function terminates the program with exit code 73.
#   - If the dimensions of m0 and m1 don't match,
#     this function terminates the program with exit code 74.
# =======================================================
matmul:

    # Error checks
    addi t0, x0, 1
    blt a1, t0, m0DimensionsError
    blt a2, t0, m0DimensionsError
    blt a4, t0, m1DimensionsError
    blt a5, t0, m1DimensionsError
    bne a2, a4, matchError

    # Prologue
    addi sp, sp, -44

    sw ra, 0(sp)
    sw s1, 4(sp) #start of m0
    sw s2, 8(sp) #rows of m0
    sw s3, 12(sp) #cols of m0
    sw s4, 16(sp) #start of m1
    sw s5, 20(sp) #rows of m1
    sw s6, 24(sp) #cols of m1
    sw s7, 28(sp) #point to d
    sw s8, 32(sp) #point to d
    sw s9, 36(sp) #point to d
    sw s10, 40(sp) #curIndex of array2

    mv s1, a0
    mv s2, a1
    mv s3, a2
    mv s4, a3
    mv s5, a4
    mv s6, a5
    mv s7, a6
    mv s8, x0 #outCount

outer_loop_start:
    beq s8, s2, outer_loop_end
    mv s10, s4
    mv s9, x0

inner_loop_start:
    beq s9, s6, inner_loop_end
    mv a0, s1
    mv a1, s10
    mv a2, s3
    li a3, 1
    mv a4, s6
    jal dot
    sw a0, 0(s7)
    addi s10, s10, 4 #col + 1
    addi s7, s7, 4 #d[count++]
    addi s9, s9, 1 #j++
    j inner_loop_start

inner_loop_end:
    addi s8, s8, 1
    mv t0, s3
    slli t0, t0, 2
    add s1, s1, t0
    j outer_loop_start

outer_loop_end:
    lw ra, 0(sp)
    lw s1, 4(sp) #start of m0
    lw s2, 8(sp) #rows of m0
    lw s3, 12(sp) #cols of m0
    lw s4, 16(sp) #start of m1
    lw s5, 20(sp) #rows of m1
    lw s6, 24(sp) #cols of m5
    lw s7, 28(sp) #point to d
    lw s8, 32(sp) #point to d
    lw s9, 36(sp) #point to d
    lw s10, 40(sp)
    addi sp, sp, 44
    # Epilogue
    
    
    ret

m0DimensionsError:
    li a0, 72
    jal exit2
    

m1DimensionsError:
    li a0, 73
    jal exit2

matchError:
    li a0, 74
    jal exit2
