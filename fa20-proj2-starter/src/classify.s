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
    addi sp, sp, -68
    sw ra, 64(sp)
    sw s1, 60(sp) 
    sw s2, 56(sp) 
    sw s3, 52(sp) 
    sw s4, 48(sp) 
    sw s5, 44(sp) 

    lw s1, 4(a1) # M0_Path
    lw s2, 8(a1) # M1_Path
    lw s3, 12(a1) # Input_Path
    lw s4, 16(a1) # Output_Path
    mv s5, a2 # print status  if s5 == 0,print, else print nothing 


	# =====================================
    # LOAD MATRICES
    # =====================================

    # m0_col            40(sp)
    # m0_row            36(sp)
    # pointer to m0     32(sp)
    # m1_col            28(sp)
    # m1_row            24(sp)
    # pointer to m1     20(sp)
    # input_col         16(sp)
    # input_row         12(sp)
    # pointer to input  8(sp)
    # pointer to m0 * input  4(sp)
    # pointer to m1 * ReLU(m0 * input)  0(sp)


    # Load pretrained m0
    
    mv a0, s1
    addi t0, sp, 36
    mv a1, t0  # a1 is the pointer to set it to the num of rows
    addi t0, sp, 40
    mv a2, t0  # a2 is the pointer to set it to the num of cols
    jal read_matrix
    sw a0, 32(sp) #  pointer to M0


    # Load pretrained m1
    mv a0, s2
    addi t0, sp, 24
    mv a1, t0  # a1 is the pointer to set it to the num of rows
    addi t0, sp, 28
    mv a2, t0  # a2 is the pointer to set it to the num of cols
    jal read_matrix
    sw a0, 20(sp)  #  pointer to M1


    # Load input matrix
    mv a0, s3
    addi t0, sp, 12
    mv a1, t0  # a1 is the pointer to set it to the num of rows
    addi t0, sp, 16
    mv a2, t0  # a2 is the pointer to set it to the num of cols
    jal read_matrix
    sw a0, 8(sp)  #  pointer to Input
  



    # =====================================
    # RUN LAYERS
    # =====================================
    # 1. LINEAR LAYER:    m0 * input
    # 2. NONLINEAR LAYER: ReLU(m0 * input)
    # 3. LINEAR LAYER:    m1 * ReLU(m0 * input)
runLayers:
    #malloc for m0 * input
    lw t0, 36(sp) # m0_row
    lw t2, 16(sp)  #input_col
    mul a0, t0, t2
    li t3, 4
    mul a0, a0, t3
    jal malloc
    sw a0, 4(sp)  #now s9 is malloced for m0 * input
    
    #start matmul(m0, input)
    lw a0, 32(sp) # pointer to m0
    lw a1, 36(sp) # m0_row
    lw a2, 40(sp) # m0_col
    lw a3, 8(sp) # pointer to input
    lw a4, 12(sp)  #input_row
    lw a5, 16(sp)  #input_col
    lw a6, 4(sp)
    jal matmul

    # ReLU(m0 * input)
    lw a0, 4(sp) #pointer to m0 * input
    lw t0, 36(sp) # m0_row
    lw t2, 16(sp)  #input_col
    mul a1, t0, t2
    jal relu

    #malloc for m1 * ReLU(m0 * input)
    lw t0, 24(sp) # m1_row
    lw t2, 16(sp)  #input_col
    mul a0, t0, t2
    li t3, 4
    mul a0, a0, t3
    jal malloc
    sw a0, 0(sp)  #pointer to  for m1 * ReLU(m0 * input)

    #start matmul(m1 , ReLU(m0 * input))
    lw a0, 20(sp) #pointer to m1
    lw a1, 24(sp) #m1_row
    lw a2, 28(sp) #m1_col
    lw a3, 4(sp)  #pointer to m0 * input
    lw a4, 36(sp) #m0_row
    lw a5, 16(sp)  #input_col
    lw a6, 0(sp)  # pointer to m1 * ReLU(m0 * input)
    jal matmul 

    # =====================================
    # WRITE OUTPUT
    # =====================================
    # Write output matrix
    mv a0, s4
    lw a1, 0(sp)  # pointer to m1 * ReLU(m0 * input)
    lw a2, 24(sp) # result.row = m1_row 
    lw a3, 16(sp) # result.col = input_col
    jal write_matrix


    # =====================================
    # CALCULATE CLASSIFICATION/LABEL
    # =====================================
    # Call argmax
    lw a0, 0(sp)  # pointer to m1 * ReLU(m0 * input)
    lw t0, 24(sp) # result.row = m1_row 
    lw t1, 16(sp) # result.col = input_col
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
    lw a0, 4(sp) #pointer to m0 * input
    jal free
    lw a0, 0(sp) #pointer to m1 * ReLU(m0 * input)
    jal free
    
    #recover a0
    mv a0, s1

    #Epilogue
    lw s5, 44(sp)
    lw s4, 48(sp)
    lw s3, 52(sp)
    lw s2, 56(sp)
    lw s1, 60(sp)
    lw ra, 64(sp)
    addi sp, sp, 68

    ret


commandError:
    li a0, 89
    jal exit2

mallocError:
    li a0, 88
    jal exit2