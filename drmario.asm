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
    .word 0x10008000 # NOTE: 0x10009000 and beyond are not shown on screen (use for other storage)
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################

bottle_colour: .word 0xa8a8a8
bottle_x_postition: .word 11
bottle_y_position: .word 28
capsule_isrotated: .word 0


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
    
game_loop:
    # 1a. Check if key has been pressed
    
    
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    


    lw $t1, ADDR_KBRD               # $t1 = base address for keyboard
    lw $t8, 0($t1)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed
    b game_loop
    
    li $v0, 32
	li $a0, 16
	syscall
    
    j game_loop

draw_bottle:
    # Draws the bottle
    # $t0: screen memory address
    # $t1: bottle colour
    
    lw $t0, ADDR_DSPL
    lw $t1, bottle_colour 
    
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
    # t3: incrementing counter
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
    # t3: incrementing counter
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

    jr $ra
    
    
keyboard_input:                     # A key is pressed
    lw $a0, 4($t1)                  # Load second word from keyboard
    beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed

    li $v0, 1                       # ask system to print $a0
    syscall

    b game_loop

respond_to_Q:
	li $v0, 10                      # Quit gracefully
	syscall
	