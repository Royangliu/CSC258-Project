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
BTTL_0_0_ADDR:
    .word 0x100085B0 #(y down 12, x right 13 from ADDR_DSPL)
RED_VIRUS_COLOUR:
    .word 0xff1111
BLUE_VIRUS_COLOUR:
    .word 0x1111ff
YELLOW_VIRUS_COLOUR:
    .word 0xffff11

##############################################################################
# Mutable Data
##############################################################################

virus_number: .word 4
virus_min_x: .word 0
virus_min_y: .word 8
virus_max_x: .word 7
virus_max_y: .word 15

bottle_spaces: .word 0:128

capsule_isrotated: .word 0
current_capsule_colour_1: .word 0 #when creating new capsule, set these colours according to the random number generated (6 total types)
current_capsule_colour_2: .word 0

side_capsule_colour_1: .word 0
side_capsule_colour_2: .word 0


##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    
    lw $s0, ADDR_KBRD       # saves address of keyboard
    
    jal draw_bottle
    jal spawn_viruses
    jal draw_bottle_spaces
    jal create_side_capsule
    jal display_side_capsule
    
    # Wait a bit before starting
    li $v0, 32
	li $a0, 2000
	syscall
    
    # jal spawn_capsule
    
game_loop:
    # 1a. Check if key has been pressed
    lw $t0, 0($s0)                  # Load first word from keyboard
    beq $t0, 1, keyboard_input      # If first word 1, key is pressed
    
    # j check_collisions
    
    # 1b. Check which key has been pressed
    keyboard_input:                     # A key is pressed
        lw $a0, 4($t1)                  # Load second word from keyboard
        beq $a0, 0x71, respond_to_Q     # Check if the key q was pressed
        # beq $a0, 0x71, respond_to_W
        # beq $a0, 0x71, respond_to_A
        # beq $a0, 0x71, respond_to_S
        # beq $a0, 0x71, respond_to_D
    
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
	
	# jal update_screen
	
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
        # $t7: virus colour in hex
        # $a0: virus colour (0=red, 1=blue, 2=yellow)
        beq $t0, $t1, quit_spawn_viruses # quits function when all viruses are made
        li $v0, 42
        li $a0, 0
        li $a1, 3
        syscall 
        
        beq $a0, 0, red_virus
        beq $a0, 1, blue_virus
        beq $a0, 2, yellow_virus
        
        red_virus:
            lw $t7, RED_VIRUS_COLOUR
            j generate_virus
        
        blue_virus:
            lw $t7, BLUE_VIRUS_COLOUR
            j generate_virus
        
        yellow_virus:
            lw $t7, YELLOW_VIRUS_COLOUR
            j generate_virus
            
        generate_virus:
            # $t8: x coords for virus
            # $t9: y coords for virus
            # $t2: the contents in address pointed from the generated x and y values 
            
            li $v0, 42
            li $a0, 0
            li $a1, 8
            syscall 
            add $t8, $zero, $a0 # stores random x value
            
            li $v0, 42
            li $a0, 0
            li $a1, 8
            syscall 
            addi $a0, $a0, 8    # adds 8 so y value is in the bottom half of the bottle
            add $t9, $zero, $a0 # stores random y value
            
            addi $sp, $sp, -4
            sw $t0, 0($sp)
            addi $sp, $sp, -4
            sw $ra, 0($sp)
            addi $sp, $sp, -4
            sw $a0, 0($sp)
            addi $sp, $sp, -4
            sw $a1, 0($sp)
            
            add $a0, $zero, $t8
            add $a1, $zero, $t9
            jal get_x_y_coordinate_storage_address # $v0 contains memory address to given x and y coords
            
            lw $a1, 0($sp)
            addi $sp, $sp, 4
            lw $a0, 0($sp)
            addi $sp, $sp, 4
            lw $ra, 0($sp)
            addi $sp, $sp, 4
            lw $t0, 0($sp)
            addi $sp, $sp, 4
            
            lw $t2, 0($v0)
            bne $t2, 0, generate_virus
            
            sw $t7, 0($v0)
            
            j finish_virus
        
        
        finish_virus:
            addi $t0, $t0, 1
            j generate_random_virus
    
    quit_spawn_viruses:
        jr $ra

respond_to_Q:
	li $v0, 10                      # Quit gracefully
	syscall
	
get_x_y_coordinate_storage_address:
    # returns the memory address in bottle_spaces based on x and y values
    # $a0: x coordinate relative to bottle
    # $a1: y coordinate relative to bottle
    # $t0: temp register for calculations
    # $v0: output containing the storage memory address for the given x and y coordinates
    la $v0, bottle_spaces
    
    li $t0, 4
    mult $a0, $t0
    mflo $t0
    add $v0, $v0, $t0
    
    li $t0, 32
    mult $a1, $t0
    mflo $t0
    add $v0, $v0, $t0
    
    jr $ra
    
draw_bottle_spaces:
    # Draws the values stored in bottle_storage onto the bitmap
    # $t0: bitmap address being painted
    # $t1: bottle_spaces address being read
    # $t9: bottle_spaces value being read
    # $t2: x counter
    # $t3: y counter
    lw $t0, BTTL_0_0_ADDR
    la $t1, bottle_spaces

    li $t3, 0
    y_loop:
        beq $t3, 16, quit_draw_bottle_spaces
        li $t2, 0
        x_loop:
            beq $t2, 8, end_x_loop
            
            # Draws the current points in memory and incremement both addresses to the next value
            lw $t9, 0($t1)
            sw $t9, 0($t0)
            addi $t2, $t2, 1
            addi $t0, $t0, 4
            addi $t1, $t1, 4
            
            j x_loop
            
        end_x_loop:
            addi $t3, $t3, 1
            addi $t0, $t0, -32 # moves the memory address for the bit map to the beginning of the row
            addi $t0, $t0, 128 # moves the memory address for the bit map to the beginning of the next row
            j y_loop
            
    quit_draw_bottle_spaces:
        jr $ra

create_side_capsule:
    # sets the side_capsule_colour .words into new colors