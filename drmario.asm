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
# - Display width in pixels:    64 ???
# - Display height in pixels:   64 ???
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
    
# values stored in memory to represent an object (0=empty):
RED_CAPSULE_VAL:
    .word 1
BLUE_CAPSULE_VAL:
    .word 2
YELLOW_CAPSULE_VAL:
    .word 3
RED_VIRUS_VAL:
    .word 11
BLUE_VIRUS_VAL:
    .word 22
YELLOW_VIRUS_VAL:
    .word 33
    
BTTL_COLOUR: 
    .word 0xa8a8a8
BTTL_0_0_ADDR:
    .word 0x100085B0 # (y down 12, x right 13 from ADDR_DSPL)
    
RED_VIRUS_COLOUR:
    .word 0xff8080
BLUE_VIRUS_COLOUR:
    .word 0x8080ff
YELLOW_VIRUS_COLOUR:
    .word 0xffffaa
RED_CAPSULE_COLOUR:
    .word 0xff0000
BLUE_CAPSULE_COLOUR:
    .word 0x0000ff
YELLOW_CAPSULE_COLOUR:
    .word 0xffdd00

SIDE_CAPSULE_ADDR_DSPL:
    .word 0x10008460
    

##############################################################################
# Mutable Data
##############################################################################

virus_number: .word 4
virus_min_x: .word 0
virus_min_y: .word 8
virus_max_x: .word 7
virus_max_y: .word 15

bottle_spaces: .word 0:128

current_capsule_isrotated: .word 0
current_capsule_1_x: .word 0
current_capsule_1_y: .word 0
current_capsule_2_x: .word 0
current_capsule_2_y: .word 0
current_capsule_value_1: .word 0 #when creating new capsule, set these colours according to the random number generated (6 total types)
current_capsule_value_2: .word 0 #Don't need to consider colours in collision

side_capsule_value_1: .word 0 # the side capsules don't need to have specified colours, just the type? -> use in switch statement to draw correct colour?
side_capsule_value_2: .word 0


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
    jal create_draw_side_capsule
    
    # Wait a bit before starting
    li $v0, 32
	li $a0, 2000
	syscall
    
    jal move_side_capsule_to_current
    jal create_draw_side_capsule
    jal place_current_capsule_uptop
    jal draw_bottle_spaces
    
    la $a0, bottle_spaces
        li $v0, 1                       # ask system to print $a0
        syscall
    
game_loop:
    # jal spawn_capsule
    # 1a. Check if key has been pressed
    lw $t0, 0($s0)                  # Load first word from keyboard
    beq $t0, 1, keyboard_input      # If first word 1, key is pressed
    j game_check_collisions
    
    # 1b. Check which key has been pressed
    keyboard_input:                     # A key is pressed
        lw $a0, 4($s0)                  # Load second word from keyboard
        
        beq $a0, 0x71, quit_game     # Check if the key q was pressed
        # beq $a0, 0x19, rotate_clockwise
        
        beq $a0, 97, move_left
        beq $a0, 100, move_right
        beq $a0, 115, move_down
        beq $a0, 119, rotate_capsule
    
        li $v0, 1                       # ask system to print $a0
        syscall
    
    game_check_collisions:
    
    # 2a. Check for collisions
    
    
	# 2b. Update locations (capsules)
	
	
	# 3. Draw the screen
	
	# Stores important register data into the stack before calling draw_bottle
	jal draw_bottle_spaces
	
	# 4. Sleep
	li $v0, 32
	li $a0, 16
	syscall

    # 5. Go back to Step 1
    j game_loop

quit_game:
	li $v0, 10                      # Quit gracefully
	syscall
	
move_left:
    # $t4: rotated status 
    lw $t4, current_capsule_isrotated
    
    lw $t0, current_capsule_1_x
    beq $t0, 0, quit_move_left  # quits if the capsule is on the left side of the bottle
    
    beq $t4, 0, case_move_left_isnotrotated
    beq $t4, 1, case_move_left_isrotated
    
    case_move_left_isnotrotated:
        # check first cap's left
        lw $a0, current_capsule_1_x
        lw $a1, current_capsule_1_y
        jal check_collide_left
        bne $v0, 0, quit_move_left
        
        jal execute_move_left
        j quit_move_left
        
    case_move_left_isrotated:
        # check first cap's left
        lw $a0, current_capsule_1_x
        lw $a1, current_capsule_1_y
        jal check_collide_left
        bne $v0, 0, quit_move_left
        
        # check second cap's left
        lw $a0, current_capsule_2_x
        lw $a1, current_capsule_2_y
        jal check_collide_left
        bne $v0, 0, quit_move_left
        
        jal execute_move_left
        j quit_move_left
        
        execute_move_left:
            # delete and store new capsule locations
            # for cap 1:
            lw $a0, current_capsule_1_x
            lw $a1, current_capsule_1_y
            addi $sp, $sp, -4
            sw $ra, 0($sp)
        	jal delete_obj_bottle_space
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
            
            lw $a0, current_capsule_1_x
            addi $a0, $a0, -1
            sw $a0, current_capsule_1_x # update x value
            lw $a1, current_capsule_1_y
            lw $a2, current_capsule_value_1
            addi $sp, $sp, -4
            sw $ra, 0($sp)
        	jal place_obj_bottle_space
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
            
            # for cap 2:       
            lw $a0, current_capsule_2_x
            lw $a1, current_capsule_2_y
            addi $sp, $sp, -4
            sw $ra, 0($sp)
        	jal delete_obj_bottle_space
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
            
            lw $a0, current_capsule_2_x
            addi $a0, $a0, -1
            sw $a0, current_capsule_2_x # update x value
            lw $a1, current_capsule_2_y
            lw $a2, current_capsule_value_2
            addi $sp, $sp, -4
            sw $ra, 0($sp)
        	jal place_obj_bottle_space
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
            
            jr $ra
    
    quit_move_left:
        
        j game_check_collisions
    
    
    check_collide_left:
    # returns if the left spot of the given x and y coordinates is empty
    # $v0: value of the left space
    # $a0: x coordinate given (must be 1 or greater)
    # $a1: y coordinate given
        addi $sp, $sp, -4
        sw $ra, 0($sp)
    	jal get_x_y_coordinate_storage_address
    	lw $ra, 0($sp)
    	addi $sp, $sp, 4
        
        lw $v0, -4($v0)
        
        jr $ra
        

move_right:
    # $t4: rotated status 
    lw $t4, current_capsule_isrotated
    
    beq $t4, 0, case_move_right_isnotrotated
    beq $t4, 1, case_move_right_isrotated
    
    case_move_right_isnotrotated:
        # check second cap's right
        lw $a0, current_capsule_2_x
        lw $a1, current_capsule_2_y
        beq $a0, 7, quit_move_right  # quits if the capsule is on the right side of the bottle
        jal check_collide_right
        bne $v0, 0, quit_move_right
        
        jal execute_move_right
        j quit_move_right
        
    case_move_right_isrotated:
        # check first cap's left
        lw $a0, current_capsule_1_x
        lw $a1, current_capsule_1_y
        beq $a0, 7, quit_move_right  # quits if the capsule is on the right side of the bottle
        jal check_collide_right
        bne $v0, 0, quit_move_right
        
        # check second cap's left
        lw $a0, current_capsule_2_x
        lw $a1, current_capsule_2_y
        jal check_collide_right
        bne $v0, 0, quit_move_right
        
        jal execute_move_right
        j quit_move_right
        
        execute_move_right:
            # delete and store new capsule locations
            # for cap 2:       
            lw $a0, current_capsule_2_x
            lw $a1, current_capsule_2_y
            addi $sp, $sp, -4
            sw $ra, 0($sp)
        	jal delete_obj_bottle_space
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
            
            lw $a0, current_capsule_2_x
            addi $a0, $a0, 1
            sw $a0, current_capsule_2_x # update x value
            lw $a1, current_capsule_2_y
            lw $a2, current_capsule_value_2
            addi $sp, $sp, -4
            sw $ra, 0($sp)
        	jal place_obj_bottle_space
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
            
            # for cap 1:
            lw $a0, current_capsule_1_x
            lw $a1, current_capsule_1_y
            addi $sp, $sp, -4
            sw $ra, 0($sp)
        	jal delete_obj_bottle_space
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
            
            lw $a0, current_capsule_1_x
            addi $a0, $a0, 1
            sw $a0, current_capsule_1_x # update x value
            lw $a1, current_capsule_1_y
            lw $a2, current_capsule_value_1
            addi $sp, $sp, -4
            sw $ra, 0($sp)
        	jal place_obj_bottle_space
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
        	
        	jr $ra
    
    quit_move_right:
        
        j game_check_collisions
    
    
    check_collide_right:
    # returns if the left spot of the given x and y coordinates is empty
    # $v0: 0 if there is nothing, 1 if there is something
    # $a0: x coordinate given (must be 6 or less)
    # $a1: y coordinate given
        addi $sp, $sp, -4
        sw $ra, 0($sp)
    	jal get_x_y_coordinate_storage_address
    	lw $ra, 0($sp)
    	addi $sp, $sp, 4
        
        lw $v0, 4($v0)

        jr $ra


move_down:
    # $t4: rotated status 
    lw $t4, current_capsule_isrotated
    lw $t0, current_capsule_1_y
    beq $t0, 15, quit_move_down  # quits if the capsule is on the bottom of the bottle
    
    beq $t4, 0, case_move_down_isnotrotated
    beq $t4, 1, case_move_down_isrotated
    
    case_move_down_isnotrotated:
        # check first cap's down
        lw $a0, current_capsule_1_x
        lw $a1, current_capsule_1_y
        jal check_collide_down
        bne $v0, 0, quit_move_down
        
        # check second cap's down
        lw $a0, current_capsule_2_x
        lw $a1, current_capsule_2_y
        jal check_collide_down
        bne $v0, 0, quit_move_down
        
        jal execute_move_down
        j quit_move_down
        
    case_move_down_isrotated:
        # check first cap's down
        lw $a0, current_capsule_1_x
        lw $a1, current_capsule_1_y
        jal check_collide_down
        bne $v0, 0, quit_move_down
        
        jal execute_move_down
        j quit_move_down
        
        execute_move_down:
            # delete and store new capsule locations
            # for cap 1:
            lw $a0, current_capsule_1_x
            lw $a1, current_capsule_1_y
            addi $sp, $sp, -4
            sw $ra, 0($sp)
        	jal delete_obj_bottle_space
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
            
            lw $a0, current_capsule_1_x
            lw $a1, current_capsule_1_y
            addi $a1, $a1, 1
            sw $a1, current_capsule_1_y # update y value
            lw $a2, current_capsule_value_1
            addi $sp, $sp, -4
            sw $ra, 0($sp)
        	jal place_obj_bottle_space
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
            
            # for cap 2:       
            lw $a0, current_capsule_2_x
            lw $a1, current_capsule_2_y
            addi $sp, $sp, -4
            sw $ra, 0($sp)
        	jal delete_obj_bottle_space
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
            
            lw $a0, current_capsule_2_x
            lw $a1, current_capsule_2_y
            addi $a1, $a1, 1
            sw $a1, current_capsule_2_y # update y value
            lw $a2, current_capsule_value_2
            addi $sp, $sp, -4
            sw $ra, 0($sp)
        	jal place_obj_bottle_space
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
            
            jr $ra
    
    quit_move_down:
        j game_check_collisions
    
    check_collide_down:
    # returns if the left spot of the given x and y coordinates is empty
    # $v0: 0 if there is nothing, 1 if there is something
    # $a0: x coordinate given (must be 1 or greater)
    # $a1: y coordinate given
        addi $sp, $sp, -4
        sw $ra, 0($sp)
    	jal get_x_y_coordinate_storage_address
    	lw $ra, 0($sp)
    	addi $sp, $sp, 4
        
        lw $v0, 32($v0)
        
        jr $ra


rotate_capsule:
    # $t4: rotated status 
    lw $t4, current_capsule_isrotated
    
    beq $t4, 0, case_rotate_isnotrotated
    beq $t4, 1, case_rotate_isrotated
    
    case_rotate_isnotrotated:
        # check first cap's top
        lw $a0, current_capsule_1_x
        lw $a1, current_capsule_1_y
        beq $a1, 0, quit_rotate  # quits if the capsule is on top of the bottle
        jal check_collide_up
        bne $v0, 0, quit_rotate
        
        j execute_rotate_to_straight
        
    case_rotate_isrotated:
        lw $a0, current_capsule_1_x
        lw $a1, current_capsule_1_y
        beq $a0, 7, rotate_shift_case  # special case where it can be shifted left by one
        jal check_collide_right
        bne $v0, 0, rotate_shift_case
        
        j execute_rotate_to_flat
        
        rotate_shift_case:
            #shifts the capsule left then rotates to flat
            lw $a0, current_capsule_1_x
            lw $a1, current_capsule_1_y
            beq $a0, 0, quit_rotate # case where capsule is on the left border
            jal check_collide_left
            bne $v0, 0, quit_rotate
            
            # delete and store new capsule locations
            
            # for cap 1:       
            lw $a0, current_capsule_1_x
            lw $a1, current_capsule_1_y
            jal delete_obj_bottle_space
            
            lw $a0, current_capsule_1_x
            addi $a0, $a0, -1
            sw $a0, current_capsule_1_x # update x value
            lw $a1, current_capsule_1_y
            lw $a2, current_capsule_value_1
            jal place_obj_bottle_space
            
            # for cap 2:       
            lw $a0, current_capsule_2_x
            lw $a1, current_capsule_2_y
            jal delete_obj_bottle_space
            
            lw $a0, current_capsule_2_x
            lw $a1, current_capsule_2_y
            addi $a1, $a1, 1
            sw $a1, current_capsule_2_y # update y value
            lw $a2, current_capsule_value_2
            jal place_obj_bottle_space
            
            sw $zero, current_capsule_isrotated
            
            j quit_rotate
        
        execute_rotate_to_straight:
            # delete and store new capsule locations
            
            #switch cap 1 and cap 2
            lw $t0, current_capsule_1_x
            lw $t1, current_capsule_1_y
            lw $t2, current_capsule_2_x
            lw $t3, current_capsule_2_y
            lw $t4, current_capsule_value_1
            lw $t5, current_capsule_value_2
            
            sw $t0, current_capsule_2_x
            sw $t1, current_capsule_2_y
            sw $t2, current_capsule_1_x
            sw $t3, current_capsule_1_y
            sw $t4, current_capsule_value_2
            sw $t5, current_capsule_value_1
            
            # for cap 2 (now on the left):       
            lw $a0, current_capsule_2_x
            lw $a1, current_capsule_2_y
            jal delete_obj_bottle_space
            
            lw $a0, current_capsule_2_x
            lw $a1, current_capsule_2_y
            addi $a1, $a1, -1
            sw $a1, current_capsule_2_y # update y value
            lw $a2, current_capsule_value_2
            jal place_obj_bottle_space
            
            # for cap 1 (now on the right):       
            lw $a0, current_capsule_1_x
            lw $a1, current_capsule_1_y
            jal delete_obj_bottle_space
            
            lw $a0, current_capsule_1_x
            addi $a0, $a0, -1
            sw $a0, current_capsule_1_x # update x value
            lw $a1, current_capsule_1_y
            lw $a2, current_capsule_value_1
            jal place_obj_bottle_space
            
            addi $t0, $zero, 1
            sw $t0, current_capsule_isrotated
            
            j quit_rotate
        
        execute_rotate_to_flat:
            # delete and store new capsule locations
            # for cap 2:       
            lw $a0, current_capsule_2_x
            lw $a1, current_capsule_2_y
            jal delete_obj_bottle_space
            
            lw $a0, current_capsule_2_x
            addi $a0, $a0, 1
            sw $a0, current_capsule_2_x # update x value
            lw $a1, current_capsule_2_y
            addi $a1, $a1, 1
            sw $a1, current_capsule_2_y # update y value
            lw $a2, current_capsule_value_2
            jal place_obj_bottle_space
            
            sw $zero, current_capsule_isrotated
            
            j quit_rotate
    
    quit_rotate:
        j game_check_collisions
    
    
    check_collide_up:
    # returns if the up spot of the given x and y coordinates is empty
    # $v0: 0 if there is nothing, 1 if there is something
    # $a0: x coordinate given (must be 1 or greater)
    # $a1: y coordinate given
        addi $sp, $sp, -4
        sw $ra, 0($sp)
    	jal get_x_y_coordinate_storage_address
    	lw $ra, 0($sp)
    	addi $sp, $sp, 4
        
        lw $v0, -32($v0)
        
        jr $ra


draw_bottle:
    # Draws the bottle borders
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
            lw $t7, RED_VIRUS_VAL
            j generate_virus
        
        blue_virus:
            lw $t7, BLUE_VIRUS_VAL
            j generate_virus
        
        yellow_virus:
            lw $t7, YELLOW_VIRUS_VAL
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
            
            addi $sp, $sp, -4
            sw $ra, 0($sp)
        	jal get_x_y_coordinate_storage_address
        	lw $ra, 0($sp)
        	addi $sp, $sp, 4
            
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
	
	
get_x_y_coordinate_storage_address: ###########################################################################################################################
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
            lw $a0, 0($t1)  # loads value at the current bottle_space
            
            addi $sp, $sp, -4
            sw $ra, 0($sp)
            jal values_to_colours   # gets the colour of the obj in bottle_space
            lw $ra, 0($sp)
            addi $sp, $sp, 4
            
            sw $v0, 0($t0)
            
            # increments the x value and values of the bottle_space and bitmap mem addresses
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


create_draw_side_capsule:
    # $a0: the colour of the capsule (0:rr, 1:bb, 2:yy)
    # $t0: capsule colour being painted and saved
    # $t1: bitmap memory address of side capsule
    # sets the side_capsule_colour words into new colors and draws them
    li $v0, 42
    li $a0, 0
    li $a1, 6
    syscall     #generates a random number in [0,5] to determine the color 
    
    beq $a0, 0, create_rr_capsule
    beq $a0, 1, create_bb_capsule
    beq $a0, 2, create_yy_capsule
    beq $a0, 3, create_rb_capsule
    beq $a0, 4, create_ry_capsule
    beq $a0, 5, create_by_capsule
    
    create_rr_capsule:
        lw $t0, RED_CAPSULE_VAL
        sw $t0, side_capsule_value_1
        sw $t0, side_capsule_value_2
        j draw_make_side_capsule
        
    create_bb_capsule:
        lw $t0, BLUE_CAPSULE_VAL
        sw $t0, side_capsule_value_1
        sw $t0, side_capsule_value_2
        j draw_make_side_capsule
        
    create_yy_capsule:
        lw $t0, YELLOW_CAPSULE_VAL
        sw $t0, side_capsule_value_1
        sw $t0, side_capsule_value_2
        j draw_make_side_capsule
        
    create_rb_capsule:
        lw $t0, RED_CAPSULE_VAL
        sw $t0, side_capsule_value_1
        lw $t0, BLUE_CAPSULE_VAL
        sw $t0, side_capsule_value_2
        j draw_make_side_capsule
    
    create_ry_capsule:
        lw $t0, RED_CAPSULE_VAL
        sw $t0, side_capsule_value_1
        lw $t0, YELLOW_CAPSULE_VAL
        sw $t0, side_capsule_value_2
        j draw_make_side_capsule
    
    create_by_capsule:
        lw $t0, BLUE_CAPSULE_VAL
        sw $t0, side_capsule_value_1
        lw $t0, YELLOW_CAPSULE_VAL
        sw $t0, side_capsule_value_2
        j draw_make_side_capsule
    
    draw_make_side_capsule:
        lw $t1, SIDE_CAPSULE_ADDR_DSPL
        
        lw $a0, side_capsule_value_1
        addi $sp, $sp, -4
        sw $ra, 0($sp)
        jal values_to_colours   # gets the colour of the cap
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        
        sw $v0, 0($t1)
        
        lw $a0, side_capsule_value_2
        addi $sp, $sp, -4
        sw $ra, 0($sp)
        jal values_to_colours   # gets the colour of the cap
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        
        sw $v0, 4($t1)
        
        jr $ra
        
move_side_capsule_to_current:
    # moves the side_capsule values to the current_capsule colours
    # $t0: capsule value to move
    lw $t0, side_capsule_value_1
    sw $t0, current_capsule_value_1
    lw $t0, side_capsule_value_2
    sw $t0, current_capsule_value_2
    
    jr $ra
    
place_current_capsule_uptop:
    # places the current capsule colours to the top of the bottle
    # $t0: capsule colour to place
    # $t1: bottle_spaces mem addr for the top left corner
    la $t1, bottle_spaces
    lw $t0, current_capsule_value_1
    sw $t0, 12($t1)
    lw $t0, current_capsule_value_2
    sw $t0, 16($t1)
    
    # $t0: x or y coordinate to store to mutable data
    li $t0, 3
    sw $t0, current_capsule_1_x  # sets current_capsule_colour_1_x to 3
    li $t0, 4
    sw $t0, current_capsule_2_x  # sets current_capsule_colour_2_x to 4
    
    li $t0, 0
    sw $t0, current_capsule_1_y  # sets current_capsule_colour_1_y to 0
    sw $t0, current_capsule_2_y  # sets current_capsule_colour_2_y to 0
    
    li $t0, 0
    sw $t0, current_capsule_isrotated  # sets current_capsule_isrotated to 0
    
    jr $ra
    
delete_object_in_bottle_spaces:
    # deletes the value/resets the value to 0 for the specified memory address in bottle_spaces
    # $a0: memory address to delete
    sw $zero, 0($a0)
    jr $ra
    

place_current_capsule_in_memory:
    # places the current capsule value to the designated places in memory 
    # $t0: capsule colour to place
    # $a0: mem addr to be placed in for colour1
    # $a1: mem addr to be placed in for colour2
    
    lw $t0, current_capsule_value_1
    sw $t0, 0($a0)
    lw $t0, current_capsule_value_2
    sw $t0, 0($a1)
    
    jr $ra

delete_obj_bottle_space:
    # Deletes the object in the bottle space at the specified x and y values
    # $a0: x
    # $a1: y
    addi $sp, $sp, -4
    sw $ra, 0($sp)
	jal get_x_y_coordinate_storage_address
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
    sw $zero, 0($v0)  
    jr $ra
    
place_obj_bottle_space:
    # puts the object in the bottle space at the specified x and y values
    # $a0: x
    # $a1: y
    # $a2: value/object to put in
    addi $sp, $sp, -4
    sw $ra, 0($sp)
	jal get_x_y_coordinate_storage_address
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
    sw $a2, 0($v0)
    jr $ra
    
values_to_colours: ###############################################################################3
    # translates the obj value given to its respective color
    # $a0: the value given
    # $v0: the colour of the value
    # $t8: temp for holding the current value being checked for
    beq $a0, 0, return_black_colour
    
    lw $t8, RED_VIRUS_VAL
    beq $a0, $t8, return_red_virus_colour
    
    lw $t8, BLUE_VIRUS_VAL
    beq $a0, $t8, return_blue_virus_colour
    
    lw $t8, YELLOW_VIRUS_VAL
    beq $a0, $t8, return_yellow_virus_colour
    
    lw $t8, RED_CAPSULE_VAL
    beq $a0, $t8, return_red_cap_colour
    
    lw $t8, BLUE_CAPSULE_VAL
    beq $a0, $t8, return_blue_cap_colour
    
    lw $t8, YELLOW_CAPSULE_VAL
    beq $a0, $t8, return_yellow_cap_colour
    
    return_black_colour:
        addi $v0, $zero, 0
        jr $ra
    return_red_virus_colour:
        lw $v0, RED_VIRUS_COLOUR
        jr $ra
    return_blue_virus_colour:
        lw $v0, BLUE_VIRUS_COLOUR
        jr $ra
    return_yellow_virus_colour:
        lw $v0, YELLOW_VIRUS_COLOUR
        jr $ra
    return_red_cap_colour:
        lw $v0, RED_CAPSULE_COLOUR
        jr $ra
    return_blue_cap_colour:
        lw $v0, BLUE_CAPSULE_COLOUR
        jr $ra
    return_yellow_cap_colour:
        lw $v0, YELLOW_CAPSULE_COLOUR
        jr $ra