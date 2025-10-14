.globl dot

.text
# =======================================================
# FUNCTION: Dot product of 2 int vectors
# Arguments:
#   a0 (int*) is the pointer to the start of v0
#   a1 (int*) is the pointer to the start of v1
#   a2 (int)  is the length of the vectors
#   a3 (int)  is the stride of v0
#   a4 (int)  is the stride of v1
# Returns:
#   a0 (int)  is the dot product of v0 and v1
# Exceptions:
# - If the length of the vector is less than 1,
#   this function terminates the program with error code 75.
# - If the stride of either vector is less than 1,
#   this function terminates the program with error code 76.
# =======================================================
dot:
    addi t0, x0, 1
    blt a2, t0, lengthError
    blt a3, t0, strideError
    blt a4, t0, strideError
    # Prologue
    mv t0, x0   #result
    mv t1, x0   #count

loop_start:
    beq t1, a2, loop_end
    
    mul t2, t1, a3
    slli t2, t2, 2  # 1 word = 4 byte 
    add t2, a0, t2  # address of elem of v0
    lw t2, 0(t2)
    mul t3, t1, a4
    slli t3, t3, 2
    add t3, a1, t3
    lw t3, 0(t3)
    mul t4, t2, t3
    add t0, t0, t4
    
    addi t1, t1, 1 #count++

    j loop_start


loop_end:

    mv a0, t0
    # Epilogue

    
    ret

lengthError:
    addi a0, x0, 75
    jal exit2

strideError:
    addi a0, x0, 76
    jal exit2
