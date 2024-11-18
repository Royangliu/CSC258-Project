################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Dr Mario.
#
# Student 1: Roy, 1010331062
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1
# - Unit height in pixels:      1
# - Display width in pixels:    32
# - Display height in pixels:   32
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
BTTL_COLOUR: 
    .word 0xa8a8a8
RED_VIRUS_COLOUR:
    .word 0xff1111
BLUE_VIRUS_COLOUR:
    .word 0x1111ff
YELLOW_VIRUS_COLOUR:
    .word 0xffff11

##############################################################################
# Mutable Data
##############################################################################

capsule_isrotated: .word 0

virus_number: .word 4
virus_min_x: .word 0
virus_min_y: .word 8
virus_max_x: .word 7
virus_max_y: .word 15

bottle_spaces: .word 0:512

current_capsule_colour: .word 0
side_capsule_colour: .word 0


##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    jal draw_bottle
    jal spawn_viruses
    
    # Wait a bit before starting
    li $v0, 32
	li $a0, 2000
	syscall
    
    jal create_side_capsule
    jal spawn_capsule
    
    lw $s0, ADDR_KBRD               # $s0 = base address for keyboard
    
game_loop:
    # $s1
    


    # 1a. Check if key has been pressed
    lw $t0, 0($s0)                  # Load first word from keyboard
    beq $t0, 1, keyboard_input      # If first word 1, key is pressed
    
    j check_collisions
    
    # 1b. Check which key has been pressed
    keyboard_input:                     # A key is pressed
        lw $a0, 4($t1)                  # Load second word from keyboard
        beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
        beq $a0, 0x71, respond_to_W
        beq $a0, 0x71, respond_to_A
        beq $a0, 0x71, respond_to_S
        beq $a0, 0x71, respond_to_D
    
        li $v0, 1                       # ask system to print $a0
        syscall
    
    # 2a. Check for collisions
    
    
	# 2b. Update locations (capsules)
	
	
	# 3. Draw the screen
	addi $sp, $sp, -4
    sw $t0, 0($sp)
    addi $sp, $sp, -4
    sw $t1, 0($sp)
    addi $sp, $sp, -4
    sw $t3, 0($sp)
    addi $sp, $sp, -4
    sw $a0, 0($sp)
	jal draw_bottle
	lw $a0, 0($sp)
	addi $sp, $sp, 4
	lw $t3, 0($sp)
	addi $sp, $sp, 4
	lw $t1, 0($sp)
	addi $sp, $sp, 4
	lw $t0, 0($sp)
	addi $sp, $sp, 4
	
	jal update_screen
	
	# 4. Sleep
	li $v0, 32
	li $a0, 16
	syscall

    # 5. Go back to Step 1
    j game_loop






#Draws the borders of the bottle
draw_bottle:
    # Draws the bottle
    # $t0: screen memory address
    # $t1: bottle colour
    
    lw $t0, ADDR_DSPL
    lw $t1, BTTL_COLOUR
    
    # Loads $t0 to have the address for the upper left corner of the bottle
    addi $t0, $t0, 44
    addi $t0, $t0, 1280
    
    # addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Draws the bottle
    li $a0 18
    li $t3, 0
    jal draw_verticle_line
    subi $t0, $t0, 128
    
    li $a0 10
    li $t3, 0
    jal draw_horizontal_line
    subi $t0, $t0, 4
    
    subi $t0, $t0, 2176
    li $a0 18
    li $t3, 0
    jal draw_verticle_line
    
    subi $t0, $t0, 2304
    subi $t0, $t0, 32
    li $a0 3
    li $t3, 0
    jal draw_horizontal_line
    
    addi $t0, $t0, 8
    li $a0 3
    li $t3, 0
    jal draw_horizontal_line

    subi $t0, $t0, 256
    subi $t0, $t0, 24
    li $a0 2
    li $t3, 0
    jal draw_verticle_line
    
    subi $t0, $t0, 256
    addi $t0, $t0, 12
    li $a0 2
    li $t3, 0
    jal draw_verticle_line

    lw $ra, 0($sp)
    jr $ra

# Draws line from top to down
draw_verticle_line:
    # $a0: line height
    # $t3: incrementing counter
    li $t3, 0
    
    draw_verticle_line_loop:
        beq $t3, $a0, quit_draw_verticle_line
        sw $t1, 0($t0)
        addi $t3, $t3, 1
        addi $t0, $t0, 128
        j draw_verticle_line_loop
    
    quit_draw_verticle_line:
        jr $ra

# Draws line from left to right
draw_horizontal_line:
    # $a0: line width
    # $t3: incrementing counter
    li $t3, 0
    
    draw_horizontal_line_loop:
        beq $t3, $a0, quit_draw_horizontal_line
        sw $t1, 0($t0)
        addi $t3, $t3, 1
        addi $t0, $t0, 4
        j draw_horizontal_line_loop
    
    quit_draw_horizontal_line:
        jr $ra



spawn_viruses:
    # $t0: counter for viruses made
    # $t1: total virus number
    li $t0, 0
    lw $t1, virus_number

    generate_random_virus:
        # $t7: virus colour
        # $a0: virus colour (0=red, 1=blue, 2=yellow)
        beq $t0, $t1, quit_spawn_viruses # quits function when all viruses are made
        li $v0, 42
        li $a0, 0
        li $a1, 3
        syscall 
        
        beq $a0, 0, generate_red_virus
        beq $a0, 1, generate_blue_virus
        beq $a0, 2, generate_yellow_virus
        
        generate_red_virus:
            # $t
            # $t8: virus x position
            # $t9: virus y position
            
            li $v0, 42
            li $a0, 0
            li $a1, 7
            syscall 
            lw $t8, 0($a0) # stores random x value
            
            li $v0, 42
            li $a0, 0
            li $a1, 15
            syscall 
            lw $t9, 0($a0) # stores random y value
            
            
            
            j finish_virus
        
        generate_blue_virus:
        
        j finish_virus
        
        generate_yellow_virus:
        
        j finish_virus
        
        finish_virus:
            addi $t0, $t0, 1
            j generate_random_virus
    
    quit_spawn_viruses:
        jr $ra

respond_to_Q:
	li $v0, 10                      # Quit gracefully
	syscall
	
get_x_y_coordinate_address:
    