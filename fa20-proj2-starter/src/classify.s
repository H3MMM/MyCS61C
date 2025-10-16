.globl classify

.text
classify:
    # =====================================
    # COMMAND LINE ARGUMENTS
    # =====================================
    # Args:
    #   a0 (int)    argc
    #   a1 (char**) argv
    #   a2 (int)    print_classification, if this is zero, 
    #               you should print the classification. Otherwise,
    #               this function should not print ANYTHING.
    # Returns:
    #   a0 (int)    Classification
    # Exceptions:
    # - If there are an incorrect number of command line args,
    #   this function terminates the program with exit code 89.
    # - If malloc fails, this function terminats the program with exit code 88.
    #
    # Usage:
    #   main.s <M0_PATH> <M1_PATH> <INPUT_PATH> <OUTPUT_PATH>

    # Prologue
    li t0, 5
    bne a0, t0, commandError
    #save data
    addi sp, sp, -44
    sw ra, 40(sp)
    sw s1, 36(sp) 
    sw s2, 32(sp) 
    sw s3, 28(sp) 
    sw s4, 24(sp) 
    sw s5, 20(sp) 
    sw s6, 16(sp)
    sw s7, 12(sp)
    sw s8, 8(sp)
    sw s9, 4(sp)  #pointer the result of m0 * input
    sw s10, 0(sp) #pointer the result of m1 * ReLU(m0 * input)

    lw s1, 4(a1) # M0_Path
    lw s2, 8(a1) # M1_Path
    lw s3, 12(a1) # Input_Path
    lw s4, 16(a1) # Output_Path
    mv s5, a2 # print status  if s5 == 0,print, else print nothing 


	# =====================================
    # LOAD MATRICES
    # =====================================

    # Load pretrained m0

    addi sp, sp, -8
    sw t0, 4(sp)
    sw t1, 0(sp)
    mv t3, sp
    mv a0, s1
    mv a2, t3  # t1 is the pointer to set it to the num of cols
    addi t3, sp, 4
    mv a1, t3  # t0 is the pointer to set it to the num of rows
    jal read_matrix
    mv s6, a0  #  pointer to M0


    # Load pretrained m1
    addi sp, sp, -8
    sw t0, 4(sp)
    sw t1, 0(sp)
    mv t3, sp
    mv a0, s2
    mv a2, t3  # t1 is the pointer to set it to the num of cols
    addi t3, sp, 4
    mv a1, t3  # t0 is the pointer to set it to the num of rows
    jal read_matrix
    mv s7, a0  #  pointer to M1


    # Load input matrix
    addi sp, sp, -8
    sw t0, 4(sp)
    sw t1, 0(sp)
    mv t3, sp
    mv a0, s3
    mv a2, t3  # t1 is the pointer to set it to the num of cols
    addi t3, sp, 4
    mv a1, t3  # t0 is the pointer to set it to the num of rows
    jal read_matrix
    mv s8, a0  #  pointer to Input

  
    # now:
    # 0(sp) input_cols
    # 4(sp) input_rows
    # 8(sp) m1_cols
    # 12(sp) m1_rows
    # 16(sp) m0_cols
    # 20(sp) m0_rows



    # =====================================
    # RUN LAYERS
    # =====================================
    # 1. LINEAR LAYER:    m0 * input
    # 2. NONLINEAR LAYER: ReLU(m0 * input)
    # 3. LINEAR LAYER:    m1 * ReLU(m0 * input)
runLayers:
    #malloc for m0 * input
    lw t0, 20(sp) # m0_row
    lw t2, 0(sp)  #input_col
    mul a0, t0, t2
    li t3, 4
    mul a0, a0, t3
    jal malloc
    mv s9, a0  #now s9 is malloced for m0 * input
    
    #start matmul(m0, input)
    mv a0, s6
    lw a1, 20(sp) # m0_row
    lw a2, 16(sp) # m0_col
    mv a3, s8
    lw a4, 4(sp)  #input_row
    lw a5, 0(sp)  #input_col
    mv a6, s9
    jal matmul

    # ReLU(m0 * input)
    mv a0, s9
    lw t0, 20(sp) # m0_row
    lw t2, 0(sp)  #input_col
    mul a1, t0, t2
    jal relu

    #malloc for m1 * ReLU(m0 * input)
    lw t0, 12(sp) # m1_row
    lw t2, 0(sp)  #input_col
    mul a0, t0, t2
    li t3, 4
    mul a0, a0, t3
    jal malloc
    mv s10, a0  #now s10 is malloced for m1 * ReLU(m0 * input)

    #start matmul(m1 , ReLU(m0 * input))
    mv a0, s7
    lw a1, 12(sp) #m1_row
    lw a2, 8(sp) #m1_col
    mv a3, s9
    lw a4, 20(sp) #m0_row
    lw a5, 0(sp)  #input_col
    mv a6, s10
    jal matmul 

    # =====================================
    # WRITE OUTPUT
    # =====================================
    # Write output matrix
    mv a0, s4
    mv a1, s10
    lw a2, 12(sp) # result.row = m1_row 
    lw a3, 0(sp) # result.col = input_col
    jal write_matrix


    # =====================================
    # CALCULATE CLASSIFICATION/LABEL
    # =====================================
    # Call argmax
    mv a0, s10
    lw t0, 12(sp) # result.row = m1_row 
    lw t1, 0(sp) # result.col = input_col
    mul a1, t0, t1
    jal argmax
    
    mv s1, a0
    # now s1 and a0 is the result after classfication
    

    # Print classification
    bne  s5, x0, end
printClassification:
    mv a1, a0
    jal print_int



    # Print newline afterwards for clarity

end:
    # free malloced
    mv a0, s9
    jal free
    mv a0, s10
    jal free

    #Epilogue
    lw s10, 24(sp)
    lw s9, 28(sp)
    lw s8, 32(sp)
    lw s7, 36(sp)
    lw s6, 40(sp)
    lw s5, 44(sp)
    lw s4, 48(sp)
    lw s3, 52(sp)
    lw s2, 56(sp)
    lw s1, 60(sp)
    lw ra, 64(sp)
    addi sp, sp, 68

    mv a0, s1
    ret


commandError:
    li a0, 89
    jal exit2

mallocError:
    li a0, 88
    jal exit2