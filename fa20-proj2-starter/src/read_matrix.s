.globl read_matrix

.text
# ==============================================================================
# FUNCTION: Allocates memory and reads in a binary file as a matrix of integers
#
# FILE FORMAT:
#   The first 8 bytes are two 4 byte ints representing the # of rows and columns
#   in the matrix. Every 4 bytes afterwards is an element of the matrix in
#   row-major order.
# Arguments:
#   a0 (char*) is the pointer to string representing the filename
#   a1 (int*)  is a pointer to an integer, we will set it to the number of rows
#   a2 (int*)  is a pointer to an integer, we will set it to the number of columns
# Returns:
#   a0 (int*)  is the pointer to the matrix in memory
# Exceptions:
# - If malloc returns an error,
#   this function terminates the program with error code 88.
# - If you receive an fopen error or eof, 
#   this function terminates the program with error code 90.
# - If you receive an fread error or eof,
#   this function terminates the program with error code 91.
# - If you receive an fclose error or eof,
#   this function terminates the program with error code 92.
# ==============================================================================
read_matrix:
    
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
    mv s1, a0  #the pointer to string representing the filename
    mv s2, a1  #set it to the number of rows
    mv s3, a2  #set it to the number of columns


    #fopen
    mv a1, a0  
    li a2, 0
    jal fopen
    # now a0 is unique integer tied to the file
    addi t0, x0, -1
    beq a0, t0, fopenError
    mv s1, a0 #unique integer tied to the file

    #get row and col
    mv a1, s1
    mv a2, s2
    li a3, 4
    jal fread  #get rows successful
    addi t0, x0, 4
    bne a0, t0, freadError
    mv a1, s1
    mv a2, s3
    jal fread  #get cols successful
    addi t0, x0, 4
    bne a0, t0, freadError

    #malloc matrix
    lw t0, 0(s2) #rows
    lw t1, 0(s3) #cols
    mul t0, t0, t1  # M*N
    addi t0, t0, 2  # 2+M*N
    li t1, 4        # sizeof(int) = 4
    mul t0, t0, t1  # 4 * (2 + M*N)
    mv a0, t0       
    jal malloc
    addi t0, x0, -1
    beq a0, t0, mallocError      
    mv s4, a0       # s4 is the pointer to malloced matrix now
    mv s7, a0       # s7 is curIndex of malloced matrix 

    # start read matrix
    li a0, 4
loopStart:
    #when a0 != 4,the file read over 
    li t0, 4
    bne a0, t0, loopEnd  
    mv a1, s1
    mv a2, s7
    li a3, 4
    jal fread

    #
    addi s7, s7, 4
    j loopStart

loopEnd:
    #fclose
    mv a1, s1
    jal fclose
    bne a0, x0, fcloseError 

    #return a0
    mv a0, s4

    # Epilogue
    lw s1, 0(sp)
    lw s2, 4(sp)
    lw s3, 8(sp)
    lw s4, 12(sp)
    lw s5, 16(sp)
    lw s6, 20(sp)
    lw s7, 24(sp)
    lw ra, 28(sp)
    addi sp, sp, 32


    ret

mallocError:
    addi a0, x0, 88
    jal exit2

fopenError:
    addi a0, x0, 90
    jal exit2

freadError:
    addi a0, x0, 91
    jal exit2

fcloseError:
    addi a0, x0, 92
    jal exit2