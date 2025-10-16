.globl relu

.text
# ==============================================================================
# FUNCTION: Performs an inplace element-wise ReLU on an array of ints
# Arguments:
# 	a0 (int*) is the pointer to the array
#	a1 (int)  is the # of elements in the array
# Returns:
#	None
# Exceptions:
# - If the length of the vector is less than 1,
#   this function terminates the program with error code 78.
# ==============================================================================
relu:
    li t0, 1
    ble a1, t0, lengthError
    # Prologue
    addi sp, sp, -12
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)
    add s1, a1, x0 #数组长度
    mv s0, a0  # copy a0 to s0
    add s2, x0, x0 

loop_start:
    beq s1, s2, loop_end  # if s1==s2 jump
    lw a0, 0(s0)     # load word from memory
    ble a0, x0, change


loop_continue:
    addi s2, s2, 1 #count++
    addi s0, s0, 4  #i++
    j loop_start

loop_end:
    # Epilogue
    lw s0, 8(sp)
    lw s1, 4(sp)
    lw s2, 0(sp)
    addi sp, sp, 12
	ret
    
change:
    add a0, x0, x0
    sw a0, 0(s0)
    j loop_continue

lengthError:
    li a0, 78
    jal exit2