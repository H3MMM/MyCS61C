.globl write_matrix

.text
# ==============================================================================
# FUNCTION: Writes a matrix of integers into a binary file
# FILE FORMAT:
#   The first 8 bytes of the file will be two 4 byte ints representing the
#   numbers of rows and columns respectively. Every 4 bytes thereafter is an
#   element of the matrix in row-major order.
# Arguments:
#   a0 (char*) is the pointer to string representing the filename
#   a1 (int*)  is the pointer to the start of the matrix in memory
#   a2 (int)   is the number of rows in the matrix
#   a3 (int)   is the number of columns in the matrix
# Returns:
#   None
# Exceptions:
# - If you receive an fopen error or eof,
#   this function terminates the program with error code 93.
# - If you receive an fwrite error or eof,
#   this function terminates the program with error code 94.
# - If you receive an fclose error or eof,
#   this function terminates the program with error code 95.
# ==============================================================================
write_matrix:
     # Prologue
    addi sp, sp, -32
    sw ra, 28(sp)
    sw s7, 24(sp)
    sw s6, 20(sp)
    sw s5, 16(sp)
    sw s4, 12(sp) #point to malloced matrix
    sw s3, 8(sp)
    sw s2, 4(sp)
    sw s1, 0(sp) 

    #store data
    mv s1, a0  # the pointer to string representing the filename
    mv s2, a1  # the pointer to the start of the matrix in memory
    mv s3, a2  # the number of rows in the matrix
    mv s4, a3  # the number of cols in the matrix


    #fopen
    mv a1, a0  
    li a2, 0
    jal fopen
    # now a0 is unique integer tied to the file
    addi t0, x0, -1
    beq a0, t0, fopenError









    # Epilogue


    ret
