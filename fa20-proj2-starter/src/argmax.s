.globl argmax

.text
# =================================================================
# FUNCTION: Given a int vector, return the index of the largest
#	element. If there are multiple, return the one
#	with the smallest index.
# Arguments:
# 	a0 (int*) is the pointer to the start of the vector
#	a1 (int)  is the # of elements in the vector
# Returns:
#	a0 (int)  is the first index of the largest element
# Exceptions:
# - If the length of the vector is less than 1,
#   this function terminates the program with error code 77.
# =================================================================
argmax:
    addi t0, x0, 1
    blt a1, t0, lengthError
    # Prologue
    addi t0, a0, 4  #the pointer to element
    addi t1, x0, 1  #curindex
    lw t2, 0(a0)    #maxelement  
    add t3, x0, x0  #maxindex

loop_start:
    beq t1, a1, loop_end
    lw  a0, 0(t0)
    bgt a0, t2, change

loop_continue:
    addi t1, t1, 1
    addi t0, t0, 4
    j loop_start  
    

loop_end:
    
    mv a0,t3
    # Epilogue

    ret


lengthError:
    li a0, 77
    jal exit2

change:
    mv t2, a0
    mv t3, t1
    j loop_continue 
    
    