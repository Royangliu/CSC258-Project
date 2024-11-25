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
    .word 0xffffbb
RED_CAPSULE_COLOUR:
    .word 0xff0000
BLUE_CAPSULE_COLOUR:
    .word 0x0000ff
YELLOW_CAPSULE_COLOUR:
    .word 0xffbb00

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

bottle_spaces: .word 0:128  # initializes 128 bytes as 0 for storage
delete_spaces: .word 0:128  # initializes 128 bytes as 0; if 1, then it is being marked for deletion
cap_connected_spaces: .word 0:128   # initializes 128 bytes as 0; if 1, then the cap is connected to the right; if 2, then the cap is connected to the left

current_capsule_isrotated: .word 0
current_capsule_1_x: .word 0
current_capsule_1_y: .word 0
current_capsule_2_x: .word 0
current_capsule_2_y: .word 0
current_capsule_value_1: .word 0 #when creating new capsule, set these colours according to the random number generated (6 total types)
current_capsule_value_2: .word 0 #Don't need to consider colours in collision

side_capsule_value_1: .word 0 # the side capsules don't need to have specified colours, just the type? -> use in switch statement to draw correct colour?
side_capsule_value_2: .word 0
side_capsule_values: .word 0:8

saved_capsule_value_1: .word 0
saved_capsule_value_2: .word 0

gravity_max: .word 60  # gravity happens after this many input loops
gravity_counter_max_min: .word 10 # the lowest the counter max can go
gravity_increase_counter_max: .word 600 # number of input game loops for gravity_max to decrease by 10 (600 = once every 10s)

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    # $s0: keyboard mem address
    # $s1: gravity counter max
    # $s2: gravity counter min
    # $s3: gravity counter
    # $s4: gravity increase counter max
    # $s5: gravity increase counter
    
    lw $s0, ADDR_KBRD       # saves address of keyboard
    
    main_menu:
        
        jal draw_home
        
        main_menu_loop:
            lw $t0, 0($s0)                  # Load first word from keyboard
            beq $t0, 1, main_menu_input         # If first word 1, key is pressed
            
            jal sleep_60fps
            j main_menu_loop
        
        main_menu_input:
            lw $t0, 4($s0)      # Load second word from keyboard
            beq $t0, 101, set_easy
            beq $t0, 109, set_medium
            beq $t0, 104, set_hard
            
            j main_menu_loop
            
        set_easy:
            li $t0, 4
            sw $t0, virus_number
            li $t0, 100
            sw $t0, gravity_max
            li $t0, 60
            sw $t0, gravity_counter_max_min
            li $t0, 1200
            sw $t0, gravity_increase_counter_max
            jal clear_screen
            j initialize_game
            
        set_medium:
            li $t0, 6
            sw $t0, virus_number
            li $t0, 60
            sw $t0, gravity_max
            li $t0, 30
            sw $t0, gravity_counter_max_min
            li $t0, 800
            sw $t0, gravity_increase_counter_max
            jal clear_screen
            j initialize_game
            
        set_hard:
            li $t0, 8
            sw $t0, virus_number
            li $t0, 40
            sw $t0, gravity_max
            li $t0, 10
            sw $t0, gravity_counter_max_min
            li $t0, 600
            sw $t0, gravity_increase_counter_max
            jal clear_screen
            j initialize_game
            
    initialize_game:
        lw $s1, gravity_max     # saves gravity counter max
        lw $s2, gravity_counter_max_min    # saves gravity counter max
        
        addi $s3, $zero, 0      # sets gravity counter to 0
        
        lw $s4, gravity_increase_counter_max     # saves gravity counter max
        addi $s5, $zero, 0      # sets gravity increase counter to 0
        
        jal clear_bottle_spaces
        jal clear_delete_spaces
        jal clear_cap_connected_spaces
        
        # li $a0, 0     #for testing 
        # li $a1, 15
        # lw $a2, BLUE_CAPSULE_VAL
        # jal place_obj_bottle_space
        # li $a0, 0
        # li $a1, 14
        # lw $a2, BLUE_CAPSULE_VAL
        # jal place_obj_bottle_space
        # li $a0, 0
        # li $a1, 13
        # lw $a2, BLUE_CAPSULE_VAL
        # jal place_obj_bottle_space
        # li $a0, 0
        # li $a1, 11
        # lw $a2, BLUE_VIRUS_VAL
        # jal place_obj_bottle_space
        
        jal draw_side_capsule_panel
        jal draw_bottle
        jal spawn_viruses
        jal draw_bottle_spaces
        jal create_all_side_capsules
        jal draw_all_side_capsules
        
        # Wait a bit before starting
        li $v0, 32
    	li $a0, 2000
    	syscall
        
        # la $a0, bottle_spaces
        # li $v0, 1                       # ask system to print $a0 FOR TESTING
        # syscall
        
        # la $a0, delete_spaces
        # li $v0, 1                       # ask system to print $a0 FOR TESTING
        # syscall
        
        # la $a0, cap_connected_spaces
        # li $v0, 1                       # ask system to print $a0 FOR TESTING
        # syscall
        
        j start_new_capsule
    
game_loop: 
    do_gravity_and_reset_counter:
        addi $s3, $zero, 0
        j execute_capsule_gravity
        
    increase_gravity_check:
        addi $s5, $zero, 0      # sets gravity increase counter to 0
        bgt $s1, $s2, increase_gravity
        j input_loop
        
        increase_gravity:
            # decreases amount of loops for gravity to happen by 10
            addi $s1, $s1, -10
            j input_loop
        
    start_new_capsule:
        jal place_capsule
        
    input_loop:
        bge $s3, $s1, do_gravity_and_reset_counter # check if gravity has reached the max
        bge $s5, $s4, increase_gravity_check

        # 1a. Check if key has been pressed
        lw $t0, 0($s0)                  # Load first word from keyboard
        beq $t0, 1, keyboard_input      # If first word 1, key is pressed
        j game_check_collisions
        
        # 1b. Check which key has been pressed
        keyboard_input:                     # A key is pressed
            lw $a0, 4($s0)                  # Load second word from keyboard
            
            beq $a0, 0x71, quit_game     # Check if the key q was pressed
            beq $a0, 97, move_left
            beq $a0, 100, move_right
            beq $a0, 115, move_down
            beq $a0, 119, rotate_capsule
            beq $a0, 112, pause_game
    
    game_check_collisions:
        # increment gravity counter
        addi $s3, $s3, 1
        addi $s5, $s5, 1
    	
    	# Draw the screen
    	jal draw_bottle_spaces
    	jal check_if_win
    	
    	# Sleep (set to ~60fps)
    	jal sleep_60fps
    
        # Go back to input loop
        j input_loop
    
    pause_game:
        lw $a0, ADDR_DSPL
        li $a1, 0xffffff
        jal draw_paused
    
        pause_loop: 
            lw $t0, 0($s0)                  # Load first word from keyboard
            beq $t0, 1, pause_input      # If first word 1, key is pressed
    
            jal sleep_60fps
            j pause_loop
    	
        pause_input:
            lw $a0, 4($s0)      # Load second word from keyboard
            beq $a0, 112, quit_pause
            beq $a0, 0x71, quit_game
            j pause_loop
        
        quit_pause:
            lw $a0, ADDR_DSPL
            li $a1, 0
            jal draw_paused
            j game_check_collisions
    
    game_over:
        jal draw_retry_screen
        
            game_over_loop:
                lw $t0, 0($s0)                  # Load first word from keyboard
                beq $t0, 1, game_over_input         # If first word 1, key is pressed
            
                jal sleep_60fps
                j game_over_loop
                
            game_over_input:
                lw $t0, 4($s0)      # Load second word from keyboard
                beq $t0, 0x71, quit_game
                beq $t0, 114, main_menu
                
                j game_over_loop
                
    win_game:
        lw $a0, ADDR_DSPL
        li $a1, 0xffffff
        jal draw_w
        j quit_game

quit_game:
	li $v0, 10                      # Quit gracefully
	syscall
	

sleep_60fps:
    # sleeps in a rate of 60fps when inside a loop
    li $v0, 32
	li $a0, 16
	syscall
	
	jr $ra

execute_capsule_gravity:
    # checks if the capsule can be moved down. Places the current capsule if not
    # $t0: current rotation status
    lw $t0, current_capsule_isrotated
    beq $t0, 1, case_gravity_capsule_isrotated
    
    case_gravity_capsule_notrotated:
        lw $t0, current_capsule_1_y
        beq $t0, 15, place_capsule  # places capsule if at the bottom of the bottle
        # check bottom of cap 1
        lw $a0, current_capsule_1_x
        lw $a1, current_capsule_1_y
        addi $sp, $sp, -4
        sw $ra, 0($sp)
        jal check_collide_down
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        bne $v0, 0, start_new_capsule
        
        # check bottom of cap 2
        lw $a0, current_capsule_2_x
        lw $a1, current_capsule_2_y
        addi $sp, $sp, -4
        sw $ra, 0($sp)
        jal check_collide_down
        lw $ra, 0($sp)
        addi $sp, $sp, 4        
        bne $v0, 0, start_new_capsule
        
        j move_down
    
    case_gravity_capsule_isrotated:
        lw $t0, current_capsule_1_y
        beq $t0, 15, place_capsule  # places capsule if at the bottom of the bottle
        # check bottom of cap 1
        lw $a0, current_capsule_1_x
        lw $a1, current_capsule_1_y
        addi $sp, $sp, -4
        sw $ra, 0($sp)
        jal check_collide_down
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        
        bne $v0, 0, place_capsule
        
        j move_down


place_capsule:
    # First, marks the spots of the capsules as connected if not rotated.
    # Checks if the capsules can clear any lines around it. Then, checks if there are places to start a new capsule and loses if not. if there is space, does everything to start a new capsule
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # marks the caps as connected in cap_connected_spaces
    lw $t0, current_capsule_isrotated
    beq $t0, 1, skip_marking_connected
    lw $t0, current_capsule_value_1
    beq $t0, 0, skip_marking_connected
    lw $a0, current_capsule_1_x
    lw $a1, current_capsule_1_y
    jal mark_x_y_connected_to_right
    lw $a0, current_capsule_2_x
    lw $a1, current_capsule_2_y
    jal mark_x_y_connected_to_left
    
    skip_marking_connected:
    
    jal check_clear_lines
    jal delete_at_marked
    jal clear_delete_spaces
    jal draw_bottle_spaces # for testing
    
    check_floating_caps_loop:
        jal check_for_floating_caps # $v0 is 1 if something moved down
        addi $sp, $sp, -4
        sw $v0, 0($sp)
        jal check_clear_lines
        jal delete_at_marked
        jal clear_delete_spaces
        jal draw_bottle_spaces  # for testing
        lw $v0, 0($sp)
        addi $sp, $sp, 4
        beq $v0, 1, check_floating_caps_loop
    
    jal check_if_lose
    jal move_side_capsule_to_current
    jal shift_side_capsules_up
    
    la $a3, side_capsule_values
    addi $a3, $a3, 24
    jal create_one_side_capsule
    
    jal draw_all_side_capsules
    jal place_current_capsule_uptop
    jal draw_bottle_spaces
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
	

check_if_lose:
    # gives a gameover if there is not space on the capsule spawn tiles
    # check first spot
    addi $a0, $zero, 3
    addi $a1, $zero, 0
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal check_obj_bottle_space
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    bne $v0, 0, game_over
    
    # check second spot
    addi $a0, $zero, 4
    addi $a1, $zero, 0
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal check_obj_bottle_space
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    bne $v0, 0, game_over
    
    jr $ra


check_if_win:
    # $t0, bottle spaces mem address to check
    # $t1: red virus value
    # $t2: blue virus value
    # $t3: yellow virus value
    # $t4: value of current bottle space
    # $t9: bottle spaces counter
    la $t0, bottle_spaces
    lw $t1, RED_VIRUS_VAL
    lw $t2, BLUE_VIRUS_VAL
    lw $t3, YELLOW_VIRUS_VAL
    li $t9, 0
    
    check_win_loop:
        beq $t9, 128, win_game
        
        lw $t4, 0($t0)
        beq $t4, $t1, quit_check_win
        beq $t4, $t2, quit_check_win
        beq $t4, $t3, quit_check_win
        
        addi $t9, $t9, 1
        addi $t0, $t0, 4
        j check_win_loop
    
    quit_check_win:
        jr $ra
    

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
    # returns the bottom spot of the given x and y coordinates
    # $v0: the value of the spot below the x and y
    # $a0: x coordinate given
    # $a1: y coordinate given (must be 14 or less)
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
        
        
create_all_side_capsules:
    # sets values to all side capsule values
    # $t9: counter for the side capsules
    
    la $a3, side_capsule_values
    li $t9, 0
    
    create_side_capsule_loop:
        beq $t9, 4, quit_create_side_capsules
        
        addi $sp, $sp, -4
        sw $ra, 0($sp)
        jal create_one_side_capsule
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        
        addi $a3, $a3, 8
        addi $t9, $t9, 1
        j create_side_capsule_loop
    
    quit_create_side_capsules:
        jr $ra


draw_all_side_capsules:
    # $t0: bitmap memory address of side capsule values
    # $t1: bitmap memory address of side capsule
    # $t9: counter for the side capsules
    
    la $t0, side_capsule_values
    lw $t1, SIDE_CAPSULE_ADDR_DSPL
    li $t9, 0
    
    draw_side_capsule_loop:
        beq $t9, 4, quit_draw_side_capsule
        lw $a0, 0($t0)
        addi $sp, $sp, -4
        sw $ra, 0($sp)
        jal values_to_colours   # gets the colour of the cap
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        
        sw $v0, 0($t1)
        
        lw $a0, 4($t0)
        addi $sp, $sp, -4
        sw $ra, 0($sp)
        jal values_to_colours   # gets the colour of the cap
        lw $ra, 0($sp)
        addi $sp, $sp, 4
        
        sw $v0, 4($t1)
        
        addi $t0, $t0, 8
        addi $t1, $t1, 256
        addi $t9, $t9, 1
        
        j draw_side_capsule_loop
    
    quit_draw_side_capsule:
        jr $ra
        

move_side_capsule_to_current:
    # moves the side_capsule values to the current_capsule colours
    # $t0: capsule value to move
    # $t1: bitmap memory address of side capsule values
    la $t1, side_capsule_values
    
    lw $t0, 0($t1)
    sw $t0, current_capsule_value_1
    lw $t0, 4($t1)
    sw $t0, current_capsule_value_2
    
    jr $ra
    
    
shift_side_capsules_up:
    # $t0: bitmap memory address of side capsule values
    # $t1: temp cap 1 value
    # $t2: temp cap 2 value
    # $t9: counter for the side capsules
    la $t0, side_capsule_values
    li $t9, 0
    
    shift_side_capsules_loop:
        beq $t9, 4, quit_shift_side_capsules
        
        lw $t1, 8($t0)
        lw $t2, 12($t0)
        sw $t1, 0($t0)
        sw $t2, 4($t0)
        
        addi $t0, $t0, 8
        addi $t9, $t9, 1
        j shift_side_capsules_loop
    
    quit_shift_side_capsules:
        jr $ra
    

create_one_side_capsule:
    # creates new side capsule values for the designated mem address
    # $a3: memory address of the cap being stored
    # $t0: capsule colour being painted and saved
    
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
        sw $t0, 0($a3)
        sw $t0, 4($a3)
        jr $ra
        
    create_bb_capsule:
        lw $t0, BLUE_CAPSULE_VAL
        sw $t0, 0($a3)
        sw $t0, 4($a3)
        jr $ra
        
    create_yy_capsule:
        lw $t0, YELLOW_CAPSULE_VAL
        sw $t0, 0($a3)
        sw $t0, 4($a3)
        jr $ra
        
    create_rb_capsule:
        lw $t0, RED_CAPSULE_VAL
        sw $t0, 0($a3)
        lw $t0, BLUE_CAPSULE_VAL
        sw $t0, 4($a3)
        jr $ra
    
    create_ry_capsule:
        lw $t0, RED_CAPSULE_VAL
        sw $t0, 0($a3)
        lw $t0, YELLOW_CAPSULE_VAL
        sw $t0, 4($a3)
        jr $ra
    
    create_by_capsule:
        lw $t0, BLUE_CAPSULE_VAL
        sw $t0, 0($a3)
        lw $t0, YELLOW_CAPSULE_VAL
        sw $t0, 4($a3)
        jr $ra


draw_side_capsule_panel:
    lw $a0, SIDE_CAPSULE_ADDR_DSPL
    li $a1, 4
    li $a2, 9
    li $a3, 0x555555
    
    addi $a0, $a0, -132
    addi $sp, $sp, -4
    sw $ra, 0($sp)
	jal draw_rectangle
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	lw $a0, SIDE_CAPSULE_ADDR_DSPL
	li $a3, 0x333333
	sw $a3, -128($a0)
	sw $a3, -124($a0)
    
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
    
check_obj_bottle_space:
    # check the value at the specified x and y values
    # $a0: x
    # $a1: y
    # $v0: value of spot
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal get_x_y_coordinate_storage_address
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    lw $v0, 0($v0)
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
        
draw_paused:
    # draws the paused message using the specified colour
    # $a1: colour of paused message
    # $a0: mem address of top left corner
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal draw_p
    addi $a0, $a0, 16
    jal draw_a
    addi $a0, $a0, 16
    jal draw_u
    addi $a0, $a0, 16
    jal draw_s
    addi $a0, $a0, 16
    jal draw_e
    addi $a0, $a0, 16
    jal draw_d
	lw $ra, 0($sp)
	addi $sp, $sp, 4
    
    jr $ra
    
    draw_p:
        # draws a p with the specified mem address and colour
        # $a1: colour of paused message
        # $a0: mem address of top left corner
        sw $a1, 0($a0)
        sw $a1, 128($a0)
        sw $a1, 256($a0)
        
        sw $a1, 4($a0)
        sw $a1, 8($a0)
        sw $a1, 136($a0)
        sw $a1, 264($a0)
        sw $a1, 260($a0)
        
        sw $a1, 384($a0)
        sw $a1, 512($a0)
        
        jr $ra
    
    draw_a:
        # draws an a with the specified mem address and colour
        # $a1: colour of paused message
        # $a0: mem address of top left corner
        sw $a1, 0($a0)
        sw $a1, 128($a0)
        sw $a1, 256($a0)
        sw $a1, 384($a0)
        sw $a1, 512($a0)
        
        sw $a1, 4($a0)
        sw $a1, 260($a0)
        
        sw $a1, 8($a0)
        sw $a1, 136($a0)
        sw $a1, 264($a0)
        sw $a1, 392($a0)
        sw $a1, 520($a0)
        
        jr $ra
        
    draw_u:
        sw $a1, 0($a0)
        sw $a1, 128($a0)
        sw $a1, 256($a0)
        sw $a1, 384($a0)
        sw $a1, 512($a0)
        
        sw $a1, 8($a0)
        sw $a1, 136($a0)
        sw $a1, 264($a0)
        sw $a1, 392($a0)
        sw $a1, 520($a0)
        
        sw $a1, 516($a0)
        
        jr $ra
        
    draw_s:
        sw $a1, 0($a0)
        sw $a1, 128($a0)
        sw $a1, 256($a0)
        sw $a1, 512($a0)
        
        sw $a1, 8($a0)
        sw $a1, 264($a0)
        sw $a1, 392($a0)
        sw $a1, 520($a0)
        
        sw $a1, 4($a0)
        sw $a1, 260($a0)
        sw $a1, 516($a0)
        
        jr $ra
        
    draw_e:
        sw $a1, 0($a0)
        sw $a1, 128($a0)
        sw $a1, 256($a0)
        sw $a1, 384($a0)
        sw $a1, 512($a0)
        
        sw $a1, 8($a0)
        sw $a1, 264($a0)
        sw $a1, 520($a0)
        
        sw $a1, 4($a0)
        sw $a1, 260($a0)
        sw $a1, 516($a0)
        
        jr $ra
        
    draw_d:
        sw $a1, 0($a0)
        sw $a1, 128($a0)
        sw $a1, 256($a0)
        sw $a1, 384($a0)
        sw $a1, 512($a0)
            
        sw $a1, 136($a0)
        sw $a1, 264($a0)
        sw $a1, 392($a0)
        
        sw $a1, 4($a0)
        sw $a1, 516($a0)
        
        jr $ra
        
    draw_m:
        sw $a1, 0($a0)
        sw $a1, 128($a0)
        sw $a1, 256($a0)
        sw $a1, 384($a0)
        sw $a1, 512($a0)
        
        sw $a1, 132($a0)
        sw $a1, 264($a0)
        sw $a1, 140($a0)
        
        sw $a1, 16($a0)
        sw $a1, 144($a0)
        sw $a1, 272($a0)
        sw $a1, 400($a0)
        sw $a1, 528($a0)
        
        jr $ra
    
    draw_h:
        sw $a1, 0($a0)
        sw $a1, 128($a0)
        sw $a1, 256($a0)
        sw $a1, 384($a0)
        sw $a1, 512($a0)
        
        sw $a1, 8($a0)
        sw $a1, 136($a0)
        sw $a1, 264($a0)
        sw $a1, 392($a0)
        sw $a1, 520($a0)
        
        sw $a1, 260($a0)
        
        jr $ra
    
    draw_r:
        sw $a1, 0($a0)
        sw $a1, 128($a0)
        sw $a1, 256($a0)
        sw $a1, 384($a0)
        sw $a1, 512($a0)
        
        sw $a1, 8($a0)
        sw $a1, 136($a0)
        sw $a1, 264($a0)
        sw $a1, 520($a0)
        
        sw $a1, 4($a0)
        sw $a1, 260($a0)
        sw $a1, 388($a0)
        
        jr $ra
    
    draw_t:
        sw $a1, 0($a0)
        sw $a1, 8($a0)
        
        sw $a1, 4($a0)
        sw $a1, 132($a0)
        sw $a1, 260($a0)
        sw $a1, 388($a0)
        sw $a1, 516($a0)
        
        jr $ra
    
    draw_y:
        sw $a1, 0($a0)
        sw $a1, 8($a0)
    
        sw $a1, 132($a0)
        sw $a1, 260($a0)
        sw $a1, 388($a0)
        sw $a1, 516($a0)
    
        jr $ra
        
    draw_i:
        sw $a1, 4($a0)
        sw $a1, 132($a0)
        sw $a1, 260($a0)
        sw $a1, 388($a0)
        sw $a1, 516($a0)
        
        sw $a1, 0($a0)
        sw $a1, 512($a0)
        
        sw $a1, 8($a0)
        sw $a1, 520($a0)
   
        jr $ra
    
    draw_w: 
        sw $a1, 0($a0)
        sw $a1, 128($a0)
        sw $a1, 256($a0)
        sw $a1, 384($a0)
        
        sw $a1, 516($a0)
        sw $a1, 392($a0)
        sw $a1, 524($a0)
        
        sw $a1, 16($a0)
        sw $a1, 144($a0)
        sw $a1, 272($a0)
        sw $a1, 400($a0)
        
        jr $ra
        
        
draw_home:
    # draws the home page with the difficulty selections
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal clear_screen
	
	lw $a0, ADDR_DSPL
	addi $a0, $a0, 12
	addi $a0, $a0, 384
	li $a1, 0x00ff00
	jal draw_e
	
	addi $a0, $a0, 44
	li $a1, 0xffff00
	jal draw_m
	
	addi $a0, $a0, 48
	li $a1, 0xff0000
	jal draw_h
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	jr $ra


draw_retry_screen:

    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal clear_screen
    
    lw $a0, ADDR_DSPL
    li $a1, 0xffffff
    addi $a0, $a0, 396
    jal draw_d
    addi $a0, $a0, 16
    jal draw_i
    addi $a0, $a0, 16
    jal draw_e
    addi $a0, $a0, 16
    jal draw_d
    
    lw $a0, ADDR_DSPL
    
    addi $a0, $a0, 1164
    jal draw_r
    addi $a0, $a0, 16
    jal draw_e
    addi $a0, $a0, 16
    jal draw_t
    addi $a0, $a0, 16
    jal draw_r
    addi $a0, $a0, 16
    jal draw_y
    addi $a0, $a0, 32
    jal draw_r
    lw $ra, 0($sp)
	addi $sp, $sp, 4
	
    jr $ra
    

draw_rectangle:
    # $a0: mem address for the beginning of the lane being cleared
    # $a1: rectangle x value
    # $a2: rectangle y value
    # $a3: rectangle colour
    # $t0: memory address being cleared
    # $t8: counter for lane being cleared
    # $t9: counter for column being drawn
    li $t9, 0

    draw_rectangle_loop:
        beq $t9, $a2, quit_draw_rectangle
        
        draw_lane:
            li $t8, 0
            addi $t0, $a0, 0
            
            draw_lane_loop:
                beq $t8, $a1, quit_draw_lane
                
                sw $a3, 0($t0)
                
                addi $t8, $t8, 1
                addi $t0, $t0, 4
                j draw_lane_loop
            
            quit_draw_lane:
        
        addi $t9, $t9, 1
        addi $a0, $a0, 128
        j draw_rectangle_loop
    
    quit_draw_rectangle:
        jr $ra
    

clear_screen:
    # clears the screen in black
    lw $a0, ADDR_DSPL
    li $a1, 32
    li $a2, 32
    li $a3, 0
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal draw_rectangle
    lw $ra, 0($sp)
	addi $sp, $sp, 4
    
    jr $ra
    
    
clear_bottle_spaces:
    # $t0: bottle spaces mem address
    # $t1: mem address counter
    la $t0, bottle_spaces
    li $t1, 0
    
    clear_bottle_loop:
        beq $t1, 128, quit_clear_bottle
        
        sw $zero, 0($t0)
        addi $t1, $t1, 1
        addi $t0, $t0, 4
        
        j clear_bottle_loop
    
    quit_clear_bottle:
        jr $ra
        

check_clear_lines:
    # checks for line clears in every spot in bottle spaces
    li $a1, 0
    check_clear_lines_y_loop:
        beq $a1, 16 quit_clear_lines
        
        li $a0, 0
        check_clear_lines_x_loop:
            beq $a0, 8, quit_clear_lines_x
            
            addi $sp, $sp, -4
            sw $ra, 0($sp)
            jal check_clear_value_at_x_y
            lw $ra, 0($sp)
        	addi $sp, $sp, 4
            
            addi $a0, $a0, 1
            j check_clear_lines_x_loop
        
        quit_clear_lines_x:
            addi $a1, $a1, 1
            j check_clear_lines_y_loop
    
    quit_clear_lines:
        jr $ra
    
check_clear_value_at_x_y:
    # checks from the current x and y value to see if any lines can be cleared
    # $a0: x
    # $a1: y
    # $t0: temp to store the values of viruses and caps to check with $t1
    # $t1: value at the x and y coords
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal get_x_y_coordinate_storage_address
    lw $ra, 0($sp)
	addi $sp, $sp, 4
	
	lw $t1, 0($v0)
	
	lw $t0, RED_CAPSULE_VAL
	beq $t1, $t0, check_clear_line_red
	lw $t0, RED_VIRUS_VAL
	beq $t1, $t0, check_clear_line_red
	
	lw $t0, BLUE_CAPSULE_VAL
	beq $t1, $t0, check_clear_line_blue
	lw $t0, BLUE_VIRUS_VAL
	beq $t1, $t0, check_clear_line_blue
	
	lw $t0, YELLOW_CAPSULE_VAL
	beq $t1, $t0, check_clear_line_yellow
	lw $t0, YELLOW_VIRUS_VAL
	beq $t1, $t0, check_clear_line_yellow
	
	jr $ra 
	
	check_clear_line_red:
	   lw $a2, RED_VIRUS_VAL
	   lw $a3, RED_CAPSULE_VAL
	   j check_clear_line
	   
	check_clear_line_blue:
	   lw $a2, BLUE_VIRUS_VAL
	   lw $a3, BLUE_CAPSULE_VAL
	   j check_clear_line
	   
	check_clear_line_yellow:
	   lw $a2, YELLOW_VIRUS_VAL
	   lw $a3, YELLOW_CAPSULE_VAL
	   j check_clear_line
	
	check_clear_line:
	    # $v0: memory address for current x and y
        # $a0: x
        # $a1: y
        # $a2: virus value
        # $a3: cap value
        
        # $t0: left/up count
        # $t1: right/down count
        # $t4: direction total (clear if 4 or more)
        
        # $t6: temp value on spot being checked
        # $t7: mem address for current spot being checked
        # $t8: temp x being checked
        # $t9: temp y being checked
        li $t0, 0
        li $t1, 0
        addi $t7, $v0, 0
        addi $t8, $a0, 0
        addi $t9, $a1, 0
        check_left_loop:
            beq $t8, 0, quit_left
            
            addi $t7, $t7, -4   # check spot on the left
            addi $t8, $t8, -1
            
            lw $t6, 0($t7) 
            
            beq $t6, $a2, increment_left
            beq $t6, $a3, increment_left
            j quit_left
            
            increment_left:
                addi $t0, $t0, 1
                j check_left_loop
           
        quit_left:
        
        addi $t7, $v0, 0
        addi $t8, $a0, 0
        addi $t9, $a1, 0
        check_right_loop:
            beq $t8, 7, quit_right
            
            addi $t7, $t7, 4   # check spot on the right
            addi $t8, $t8, 1
            
            lw $t6, 0($t7) 
            
            beq $t6, $a2, increment_right
            beq $t6, $a3, increment_right
            j quit_right
            
            increment_right:
                addi $t1, $t1, 1
                j check_right_loop
           
        quit_right:
            
            add $t4, $t0, $t1
            addi $t4, $t4, 1
            
            bge $t4, 4, delete_left_right
            j quit_left_right
            
            delete_left_right:
                
                addi $sp, $sp, -4
                sw $a0, 0($sp)
                addi $sp, $sp, -4
                sw $a1, 0($sp)
                
                addi $sp, $sp, -4
                sw $ra, 0($sp)
                addi $sp, $sp, -4
                sw $t0, 0($sp)
                addi $sp, $sp, -4
                sw $t1, 0($sp)
                jal mark_x_y_delete     
                lw $t1, 0($sp)                 
            	addi $sp, $sp, 4
            	lw $t0, 0($sp)
            	addi $sp, $sp, 4
            	lw $ra, 0($sp)
            	addi $sp, $sp, 4
                delete_left_loop:
                    beq $t0, 0, quit_delete_left
                    addi $a0, $a0, -1
                    
                    addi $sp, $sp, -4
                    sw $ra, 0($sp)
                    addi $sp, $sp, -4
                    sw $t0, 0($sp)
                    addi $sp, $sp, -4
                    sw $t1, 0($sp)
                    jal mark_x_y_delete     
                    lw $t1, 0($sp)                 
                	addi $sp, $sp, 4
                	lw $t0, 0($sp)
                	addi $sp, $sp, 4
                	lw $ra, 0($sp)
                	addi $sp, $sp, 4
                    
                    addi $t0, $t0, -1
                    j delete_left_loop
                    
                quit_delete_left:
                    lw $a1, 0($sp)
                	addi $sp, $sp, 4
                	lw $a0, 0($sp)
                	addi $sp, $sp, 4
                
                addi $sp, $sp, -4
                sw $a0, 0($sp)
                addi $sp, $sp, -4
                sw $a1, 0($sp)
                delete_right_loop:
                    beq $t1, 0, quit_delete_right
                    addi $a0, $a0, 1
                    
                    addi $sp, $sp, -4
                    sw $ra, 0($sp)
                    addi $sp, $sp, -4
                    sw $t0, 0($sp)
                    addi $sp, $sp, -4
                    sw $t1, 0($sp)
                    jal mark_x_y_delete     
                    lw $t1, 0($sp)                 
                	addi $sp, $sp, 4
                	lw $t0, 0($sp)
                	addi $sp, $sp, 4
                	lw $ra, 0($sp)
                	addi $sp, $sp, 4
                    
                    addi $t1, $t1, -1
                    j delete_right_loop
                    
                quit_delete_right:
                    lw $a1, 0($sp)
                	addi $sp, $sp, 4
                	lw $a0, 0($sp)
                	addi $sp, $sp, 4
            
    quit_left_right:
        
        li $t0, 0
        li $t1, 0
        addi $t7, $v0, 0
        addi $t8, $a0, 0
        addi $t9, $a1, 0
        check_up_loop:
            beq $t9, 0, quit_up
            
            addi $t7, $t7, -32   # check spot on the up
            addi $t9, $t9, -1
            
            lw $t6, 0($t7) 
            
            beq $t6, $a2, increment_up
            beq $t6, $a3, increment_up
            j quit_up
            
            increment_up:
                addi $t0, $t0, 1
                j check_up_loop
           
        quit_up:
        
        addi $t7, $v0, 0
        addi $t8, $a0, 0
        addi $t9, $a1, 0
        check_down_loop:
            beq $t9, 15, quit_down
            
            addi $t7, $t7, 32   # check spot on the down
            addi $t9, $t9, 1
            
            lw $t6, 0($t7) 
            
            beq $t6, $a2, increment_down
            beq $t6, $a3, increment_down
            j quit_down
            
            increment_down:
                addi $t1, $t1, 1
                j check_down_loop
           
        quit_down:
            
            add $t4, $t0, $t1
            addi $t4, $t4, 1
            
            bge $t4, 4, delete_up_down
            j quit_up_down
            
            delete_up_down:
                
                addi $sp, $sp, -4
                sw $a0, 0($sp)
                addi $sp, $sp, -4
                sw $a1, 0($sp)
                
                addi $sp, $sp, -4
                sw $ra, 0($sp)
                addi $sp, $sp, -4
                sw $t0, 0($sp)
                addi $sp, $sp, -4
                sw $t1, 0($sp)
                jal mark_x_y_delete     
                lw $t1, 0($sp)                 
            	addi $sp, $sp, 4
            	lw $t0, 0($sp)
            	addi $sp, $sp, 4
            	lw $ra, 0($sp)
            	addi $sp, $sp, 4
                delete_up_loop:
                    beq $t0, 0, quit_delete_up
                    addi $a1, $a1, -1
                    
                    addi $sp, $sp, -4
                    sw $ra, 0($sp)
                    addi $sp, $sp, -4
                    sw $t0, 0($sp)
                    addi $sp, $sp, -4
                    sw $t1, 0($sp)
                    jal mark_x_y_delete     
                    lw $t1, 0($sp)                 
                	addi $sp, $sp, 4
                	lw $t0, 0($sp)
                	addi $sp, $sp, 4
                	lw $ra, 0($sp)
                	addi $sp, $sp, 4
                    
                    addi $t0, $t0, -1
                    j delete_up_loop
                    
                quit_delete_up:
                    lw $a1, 0($sp)
                	addi $sp, $sp, 4
                	lw $a0, 0($sp)
                	addi $sp, $sp, 4
                
                addi $sp, $sp, -4
                sw $a0, 0($sp)
                addi $sp, $sp, -4
                sw $a1, 0($sp)
                delete_down_loop:
                    beq $t1, 0, quit_delete_down
                    addi $a1, $a1, 1
                    
                    addi $sp, $sp, -4
                    sw $ra, 0($sp)
                    addi $sp, $sp, -4
                    sw $t0, 0($sp)
                    addi $sp, $sp, -4
                    sw $t1, 0($sp)
                    jal mark_x_y_delete     
                    lw $t1, 0($sp)                 
                	addi $sp, $sp, 4
                	lw $t0, 0($sp)
                	addi $sp, $sp, 4
                	lw $ra, 0($sp)
                	addi $sp, $sp, 4
                    
                    addi $t1, $t1, -1
                    j delete_down_loop
                    
                quit_delete_down:
                    lw $a1, 0($sp)
                	addi $sp, $sp, 4
                	lw $a0, 0($sp)
                	addi $sp, $sp, 4
            
    quit_up_down:
        jr $ra
        
mark_x_y_delete:
    # marks the spot on the delete_spaces for deletion
    # $a0: x
    # $a1: y
    # $t0: temp for calculations
    # $t1: holds the mem address for the spot being deleted
    la $t1, delete_spaces
    
    li $t0, 4
    mult $a0, $t0
    mflo $t0
    add $t1, $t1, $t0
    
    li $t0, 32
    mult $a1, $t0
    mflo $t0
    add $t1, $t1, $t0
    
    li $t0, 1
    sw $t0, 0($t1)
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    jal mark_x_y_unconnected
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
    

delete_at_marked:
    # deleted things in bottle spaces if the corresponding spot in delete_spaces is 1
    # $a0: DO NOT INITIALIZE, temp x
    # $a1: DO NOT INITIALIZE, temp y
    # $t0: mem address for delete_spaces
    # $t1: value in delete_spaces being checked
    la $t0, delete_spaces
    li $a1, 0
    delete_marked_y_loop:
        beq $a1, 16, quit_delete_marked
    
        li $a0, 0
        delete_marked_x_loop:
            beq $a0, 8, quit_delete_marked_x
            
            lw $t1, 0($t0)
            
            beq $t1, 1, delete_marked_spot
            j skip_delete_spot
    
                delete_marked_spot:
                    addi $sp, $sp, -4
                    sw $ra, 0($sp)
                    addi $sp, $sp, -4
                    sw $t0, 0($sp)
                    addi $sp, $sp, -4
                    sw $t1, 0($sp)
                    jal delete_obj_bottle_space
                    lw $t1, 0($sp)
                	addi $sp, $sp, 4
                	lw $t0, 0($sp)
                	addi $sp, $sp, 4
                    lw $ra, 0($sp)
                	addi $sp, $sp, 4
                    
                skip_delete_spot:
                
            addi $a0, $a0, 1
            addi $t0, $t0, 4
            j delete_marked_x_loop
            
            quit_delete_marked_x:
                addi $a1, $a1, 1
                j delete_marked_y_loop
    
    quit_delete_marked:
        jr $ra
        
clear_delete_spaces:
    # clears deleted_spaces
    # $t0: delete spaces mem address
    # $t1: mem address counter
    la $t0, delete_spaces
    li $t1, 0
    
    clear_delete_spaces_loop:
        beq $t1, 128, quit_clear_delete_spaces
        
        sw $zero, 0($t0)
        addi $t1, $t1, 1
        addi $t0, $t0, 4
        
        j clear_delete_spaces_loop
    
    quit_clear_delete_spaces:
        jr $ra
        
        
mark_x_y_connected_to_right:
    # marks the spot on the cap_connected_spaces to 1
    # $a0: x
    # $a1: y
    # $t0: temp for calculations
    # $t1: holds the mem address for the spot being marked
    la $t1, cap_connected_spaces
    
    li $t0, 4
    mult $a0, $t0
    mflo $t0
    add $t1, $t1, $t0
    
    li $t0, 32
    mult $a1, $t0
    mflo $t0
    add $t1, $t1, $t0
    
    li $t0, 1
    sw $t0, 0($t1)
    
    jr $ra
    
    
mark_x_y_connected_to_left:
    # marks the spot on the cap_connected_spaces to 2
    # $a0: x
    # $a1: y
    # $t0: temp for calculations
    # $t1: holds the mem address for the spot being marked
    la $t1, cap_connected_spaces
    
    li $t0, 4
    mult $a0, $t0
    mflo $t0
    add $t1, $t1, $t0
    
    li $t0, 32
    mult $a1, $t0
    mflo $t0
    add $t1, $t1, $t0
    
    li $t0, 2
    sw $t0, 0($t1)
    
    jr $ra
    
    
mark_x_y_unconnected:
    # marks the spot on the cap_connected_spaces to 0
    # $a0: x
    # $a1: y
    # $t0: temp for calculations
    # $t1: holds the mem address for the spot being deleted
    la $t1, cap_connected_spaces
    
    li $t0, 4
    mult $a0, $t0
    mflo $t0
    add $t1, $t1, $t0
    
    li $t0, 32
    mult $a1, $t0
    mflo $t0
    add $t1, $t1, $t0
    
    lw $t0, 0($t1)
    beq $t0, 1, case_unmark_right
    beq $t0, 2, case_unmark_left
    
    jr $ra
    
    case_unmark_right:
        sw $zero, 0($t1)
        sw $zero, 4($t1)
        jr $ra
        
    case_unmark_left:
        sw $zero, 0($t1)
        sw $zero, -4($t1)
        jr $ra
    
    
get_connectedness_x_y:
    # gets the connected value at specified x and y
    # $a0: x
    # $a1: y
    # $t0: temp for calculations
    # $v0: contains the value at the x and y
    la $v1, cap_connected_spaces
    
    li $t0, 4
    mult $a0, $t0
    mflo $t0
    add $v1, $v1, $t0
    
    li $t0, 32
    mult $a1, $t0
    mflo $t0
    add $v1, $v1, $t0
    
    lw $v0, 0($v1)
    
    jr $ra
    
    
clear_cap_connected_spaces:
    # clears cap_connected_spaces
    # $t0: delete spaces mem address
    # $t1: mem address counter
    la $t0, cap_connected_spaces
    li $t1, 0
    
    clear_cap_connected_loop:
        beq $t1, 128, quit_clear_cap_connected_spaces
        
        sw $zero, 0($t0)
        addi $t1, $t1, 1
        addi $t0, $t0, 4
        
        j clear_cap_connected_loop
    
    quit_clear_cap_connected_spaces:
        jr $ra
        

check_for_floating_caps:
    # $a0: DO NOT INITIATE, x counter
    # $a1: DO NOT INITIATE, y counter
    # $t2: virus values used to compare to $t1
    # $t9: temp holding 1 if something moved down
    # $v0: at the end, contains 1 if something moved down
    li $t9, 0
    
    li $a1, 0
    check_for_floating_y_loop:
        beq $a1, 15, quit_check_floating_caps
        
        li $a0, 0
        check_for_floating_x_loop:
            beq $a0, 8, quit_check_floating_x
        
            addi $sp, $sp, -4
            sw $ra, 0($sp)
            jal check_obj_bottle_space
            lw $ra, 0($sp)
            addi $sp, $sp, 4
            
            lw $t2, RED_VIRUS_VAL
            beq $v0, $t2, skip_check_under
            lw $t2, BLUE_VIRUS_VAL
            beq $v0, $t2, skip_check_under
            lw $t2, YELLOW_VIRUS_VAL
            beq $v0, $t2, skip_check_under
            beq $v0, 0, skip_check_under
            
            addi $sp, $sp, -4
            sw $ra, 0($sp)
            jal get_connectedness_x_y
            lw $ra, 0($sp)
            addi $sp, $sp, 4
            
            beq $v0, 0, case_check_unconnected_fall
            beq $v0, 1, case_check_connected_fall
            beq $v0, 2, skip_check_under
            
            case_check_unconnected_fall:
                addi $sp, $sp, -4
                sw $ra, 0($sp)
                jal check_collide_down
                lw $ra, 0($sp)
                addi $sp, $sp, 4
                
                beq $v0, 0, do_unconnected_fall
                j skip_check_under
                
                do_unconnected_fall:
                    # move the value down once (don't need to change any connected values since its already 0)
                    li $t9, 1
                    
                    addi $sp, $sp, -4
                    sw $ra, 0($sp)
                    jal check_obj_bottle_space
                    lw $ra, 0($sp)
                    addi $sp, $sp, 4
                    
                    addi $sp, $sp, -4
                    sw $v0, 0($sp)
                    addi $sp, $sp, -4
                    sw $ra, 0($sp)
                    jal delete_obj_bottle_space
                    lw $ra, 0($sp)
                    addi $sp, $sp, 4
                    lw $v0, 0($sp)
                    addi $sp, $sp, 4
                    
                    
                    addi $sp, $sp, -4
                    sw $ra, 0($sp)
                    
                    addi $a1, $a1, 1
                    addi $a2, $v0, 0
                    jal place_obj_bottle_space
                    addi $a1, $a1, -1
                    
                    lw $ra, 0($sp)
                    addi $sp, $sp, 4
                    
                    j skip_check_under
                    
                
            case_check_connected_fall:
                addi $sp, $sp, -4
                sw $ra, 0($sp)
                jal check_collide_down
                lw $ra, 0($sp)
                addi $sp, $sp, 4
                
                bne $v0, 0, skip_check_under
                
                addi $sp, $sp, -4
                sw $ra, 0($sp)
                
                addi $a0, $a0, 1
                jal check_collide_down
                addi $a0, $a0, -1
                
                lw $ra, 0($sp)
                addi $sp, $sp, 4
                
                bne $v0, 0, skip_check_under
                j do_connected_fall
                
                do_connected_fall:
                    # move delete the value in bottle spaces one by one. then move the value in cap_connectedness one by one
                    li $t9, 1
                    
                    # moves the first cap and its connected value down
                    addi $sp, $sp, -4
                    sw $ra, 0($sp)
                    jal check_obj_bottle_space
                    lw $ra, 0($sp)
                    addi $sp, $sp, 4
                    
                    addi $sp, $sp, -4
                    sw $v0, 0($sp)
                    addi $sp, $sp, -4
                    sw $ra, 0($sp)
                    jal delete_obj_bottle_space
                    lw $ra, 0($sp)
                    addi $sp, $sp, 4
                    lw $v0, 0($sp)
                    addi $sp, $sp, 4
                    
                    addi $sp, $sp, -4
                    sw $ra, 0($sp)
                    addi $sp, $sp, -4
                    sw $t1, 0($sp)
                    jal mark_x_y_unconnected
                    lw $t1, 0($sp)
                    addi $sp, $sp, 4
                    lw $ra, 0($sp)
                    addi $sp, $sp, 4
                    
                    addi $a1, $a1, 1
                        addi $sp, $sp, -4
                        sw $ra, 0($sp)
                    addi $a2, $v0, 0
                    jal place_obj_bottle_space
                        lw $ra, 0($sp)
                        addi $sp, $sp, 4
                    
                    
                        addi $sp, $sp, -4
                        sw $ra, 0($sp)
                        addi $sp, $sp, -4
                        sw $t1, 0($sp)
                    jal mark_x_y_connected_to_right
                        lw $t1, 0($sp)
                        addi $sp, $sp, 4
                        lw $ra, 0($sp)
                        addi $sp, $sp, 4
                    addi $a1, $a1, -1
                    
                    
                    # moves the second cap and its connected value down
                    addi $a0, $a0, 1 # moves the next x value
                    
                    addi $sp, $sp, -4
                    sw $ra, 0($sp)
                    jal check_obj_bottle_space
                    lw $ra, 0($sp)
                    addi $sp, $sp, 4
                    
                    addi $sp, $sp, -4
                    sw $v0, 0($sp)
                    addi $sp, $sp, -4
                    sw $ra, 0($sp)
                    jal delete_obj_bottle_space
                    lw $ra, 0($sp)
                    addi $sp, $sp, 4
                    lw $v0, 0($sp)
                    addi $sp, $sp, 4
                       
                   addi $a1, $a1, 1
                        addi $sp, $sp, -4
                        sw $ra, 0($sp)
                    addi $a2, $v0, 0
                    jal place_obj_bottle_space
                        lw $ra, 0($sp)
                        addi $sp, $sp, 4
                    
                    
                        addi $sp, $sp, -4
                        sw $ra, 0($sp)
                        addi $sp, $sp, -4
                        sw $t1, 0($sp)
                    jal mark_x_y_connected_to_left
                        lw $t1, 0($sp)
                        addi $sp, $sp, 4
                        lw $ra, 0($sp)
                        addi $sp, $sp, 4
                    addi $a1, $a1, -1
                    
                    addi $a0, $a0, -1   # goes back to original x value
                    
            skip_check_under:        
            
            addi $a0, $a0, 1
            j check_for_floating_x_loop
        
        quit_check_floating_x:
        
            addi $a1, $a1, 1
            j check_for_floating_y_loop
            
    quit_check_floating_caps:
        addi $v0, $t9, 0
        jr $ra