# Bosi Hou
# boh24

# need this early included so we have constants for declaring arrays in data seg
.include "game_constants.asm"
.data

# set to 1 to make it impossible to get a game over!
.eqv GRADER_MODE 0

# player's score and number of lives
score: .word 0
lives: .word 3

# boolean (1 means the game is over)
game_over: .word 0

# how many active objects there are. this many slots of the below arrays represent
# active objects.
cur_num_objs: .word 0

# Object arrays. These are parallel arrays. The player object is in slot 0,
# so the "player_x", "player_y", "player_timer" etc. labels are pointing to the
# same place as slot 0 of those arrays.

object_type: .byte 0:MAX_NUM_OBJECTS
player_x:
object_x: .byte 0:MAX_NUM_OBJECTS
player_y:
object_y: .byte 0:MAX_NUM_OBJECTS
player_timer:
object_timer: .byte 0:MAX_NUM_OBJECTS
player_delay:
object_delay: .byte 0: MAX_NUM_OBJECTS
player_vel:
object_vel: .byte 0:MAX_NUM_OBJECTS

# this is the 2d array for our map
tilemap: .byte 0:MAP_SIZE

.text

#-------------------------------------------------------------------------------------------------
# include AFTER our initial data segment stuff for easier memory debugging

.include "display_2227_0611.asm"
.include "map.asm"
.include "textures.asm"
.include "obj.asm"

#-------------------------------------------------------------------------------------------------

.globl main
main:
	# this populates the tilemap array and the object arrays
	jal load_map

	# do...
	_game_loop:
		jal check_input
		jal update_all
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	# ...while(!game_over)
	lw t0, game_over
	beq t0, 0, _game_loop

	# show the game over screen and exit
	jal show_game_over
syscall_exit

#-------------------------------------------------------------------------------------------------

show_game_over:
enter
	jal display_update_and_clear

	li   a0, 5
	li   a1, 10
	lstr a2, "GAME OVER"
	li   a3, COLOR_YELLOW
	jal  display_draw_colored_text

	li   a0, 5
	li   a1, 30
	lstr a2, "SCORE: "
	jal  display_draw_text

	li   a0, 41
	li   a1, 30
	lw   a2, score
	jal  display_draw_int

	jal display_update
leave

#-------------------------------------------------------------------------------------------------

update_all:
enter
	jal obj_move_all
	jal maybe_spawn_object
	jal player_collision
	jal offscreen_obj_removal
leave

#-------------------------------------------------------------------------------------------------

draw_all:
enter
	jal draw_tilemap
	jal obj_draw_all
	jal draw_hud
leave

#-------------------------------------------------------------------------------------------------



draw_tilemap:
enter s0, s1
	
	# s0 is the row index, s1 is the column index
	
	li s0, 0
	_loop1: 
  		li s1, 0
		_loop2: 
  			
  			# a0 is the screen X coordinate
		        # a0 = (col * 5) - 3;
		        move a0, s1
		        mul a0, a0, 5
		        sub a0, a0, 3

		
		        # a1 is the screen Y coordinate
		        # a1 = (row * 5) + 4;
		        move a1, s0
		        mul a1, a1, 5
		        add a1, a1, 4
		         
		         
		
		        # first get the tile at (row, col).
		        # remember that tilemap is a BYTE array. so what load instruction will you use?
		        # t0 = tilemap[(row * MAP_WIDTH) + col]; 
			
			
			move t0, s0
			mul t0, t0, MAP_WIDTH
			add t0, t0, s1
			lb t0, tilemap(t0)
			

		        # then get the actual tile texture into a2.
		        # texture_atlas is a .word array given in textures.asm. woooooord array.
		        # a2 = texture_atlas[t0 * 4];
		        mul t0, t0, 4
		        lw a2, texture_atlas(t0)
		        

		         
		
		        # finally, call display_blit_5x5_trans.
		        # it takes 3 arguments which we already set into a0, a1, and a2.
		        jal display_blit_5x5_trans
  			

  		
  			add s1, s1, 1
			blt s1, MAP_WIDTH, _loop2
  		
  		
  		
  		add s0, s0, 1
		blt s0, MAP_HEIGHT, _loop1
		
		
leave s0, s1




draw_hud:
enter s0
	
	li a0, 0
	li a1, 4
	lw a2, score
	jal display_draw_int
	
	
	
	
	li s0, 0
	_loop3:
		lw t9, lives # t1 = 3
		move a0, s0
		mul a0, a0, 5
	
		li a1, 59
		
		la a2, tex_heart
		
		jal display_blit_5x5_trans
		
		
		add s0, s0, 1
		blt s0, t9, _loop3
	
# display_blit_5x5_trans
# lives	
			
leave s0


obj_draw_all:
enter s0
	# for(s0 = cur_num_objs - 1; s0 >= 0; s0--)
	
	lw s0, cur_num_objs
	sub s0, s0, 1
	_loop:
	
		lb a0, object_x(s0)
		lb a1, object_y(s0)
		
		lb a2, object_type(s0)
		mul a2, a2, 4
		lw a2, obj_textures(a2)
		
		
		jal display_blit_5x5_trans
		
		
		sub s0, s0, 1
		bge s0, 0, _loop
	
	
	
leave s0




obj_move_all:
enter s0

	li s0, 0
	lw t0, cur_num_objs
	
	_loop:
		# object_timer[i]--
		lb t1, object_timer(s0)
		
		sub t1, t1, 1
		sb t1, object_timer(s0)
		
		bgt t1, 0, _endif
			lb t3, object_x(s0)
			lb t4, object_vel(s0)
			add t3, t3, t4
			sb t3, object_x(s0)
			
			
			lb t2, object_delay(s0)
			sb t2, object_timer(s0)
			
			# object_timer[i] = object_delay[i]
			
			j _endif
		_endif:
	
		# if (t1 <= 0): object_x[i] = object_x[i] + object_vel[i]
		
		
		
		
		
		add s0, s0, 1
		blt s0, t0, _loop



leave s0





check_input:
enter
	jal input_get_keys_pressed
	
	
	
	lb t0, player_x
	lb t1, player_y
	
	
	
	beq v0, KEY_L, _case_left
	beq v0, KEY_R, _case_right
	beq v0, KEY_U, _case_up
	beq v0, KEY_D, _case_down
	j _break
	
	
	
	
	
	_case_left:
		# if(player_x > PLAYER_MIN_X) { player_x -= PLAYER_VELOCITY; }
		ble t0, PLAYER_MIN_X, _endif1
			
			# player_x -= PLAYER_VELOCITY;
			sub t0, t0, PLAYER_VELOCITY
			sb t0, player_x
			
			j _endif1
		_endif1:
		
		
		j _case_done_moving
		
		
		
	_case_right:
		# if(player_x < PLAYER_MAX_X) { player_x += PLAYER_VELOCITY; }
		bge t0, PLAYER_MAX_X, _endif2
			
			add t0, t0, PLAYER_VELOCITY
			sb t0, player_x
			
			j _endif2
		_endif2:
		
		j _case_done_moving
		
		
		
	_case_up:
		# if(player_y > PLAYER_MIN_Y) { player_y -= PLAYER_VELOCITY; }
		ble t1, PLAYER_MIN_Y, _endif3
			sub t1, t1, PLAYER_VELOCITY
			sb t1, player_y
		
			
			j _endif3
		
		_endif3:
		
		j _case_done_moving
		
		
		
	_case_down:
		# if(player_y < PLAYER_MAX_Y) { player_y += PLAYER_VELOCITY; }
		bge t1, PLAYER_MAX_Y, _endif4
			add t1, t1, PLAYER_VELOCITY
			sb t1, player_y
		
			
			j _endif4
		
		_endif4:
		
		j _case_done_moving
	
	
	
	_case_done_moving:
		sb zero, player_delay
		sb zero, player_vel
		sb zero, player_timer
		
		j _break
	
			
					
		
		
	_break:	

		
leave



# detect collision
player_collision:
enter s0, s1
	
	
	# # t0 = tilemap[(row * MAP_WIDTH) + col]; 
	
	lb t0, player_y
	div t0, t0, 5     # now t0 is row
	#mul t0, t0, 5
	#sub t0, t0, 3
	
	lb t1, player_x
	div t1, t1, 5
	add t1, t1, 1     # now t1 is col
	
	
	
	mul t2, t0, MAP_WIDTH
	add t2, t2, t1
	
	lb s0, tilemap(t2)
	
	# if it’s equal to TILE_OUCH, call kill_player
	bne s0, TILE_OUCH, _endif1
		
		jal kill_player
		
		j _return

		j _endif1
		
	_endif1:
	
	
	
	
	li s1, 0
	lw t4, cur_num_objs
	
	_loop1:
	
		# a0 = player_x
		lb a0, player_x
		# a1 = player_y
		lb a1, player_y
		# a2 = object_x[i]
		lb a2, object_x(s1)
		# a3 = object_y[i]
		lb a3, object_y(s1)
		
		
		jal bounds_check
		
		bne v0, 1, _endif2
		
			# object_type[i]
			lb t5, object_type(s1)
			
			# OBJ_CAR_FAST or OBJ_CAR_SLOW
			# OBJ_LOG or OBJ_CROC
			
			beq t5, OBJ_CAR_FAST, _case_kill_player
			beq t5, OBJ_CAR_SLOW, _case_kill_player
			beq t5, OBJ_LOG, _case_ride_on_it
			beq t5, OBJ_CROC, _case_ride_on_it
			beq t5, OBJ_GOAL, _case_get_the_goal
			j _endif2
			
			
			_case_kill_player:
				
				jal kill_player
				
				j _return
				
			_case_ride_on_it:
				
				move a0, s1
				
				jal player_move_with_object
			
				j _return
				
			
			_case_get_the_goal:
			
				move a0, s1
				
				jal player_get_goal
			
				j _return
			


			j _endif2
		
		_endif2:
	
	
	
	
	
	
	
		add s1, s1, 1
		lw t4, cur_num_objs
		blt s1, t4, _loop1


	# if (that tile == TILE_WATER): call kill_player
	bne s0, TILE_WATER, _endif3
	
		jal kill_player
		j _endif3
	_endif3:
	
	
	
	
 	_return:	
	
	
leave s0, s1




kill_player:
enter
	# if (lives > 0): 
	#    lives-- 
	
	# if (lives <= 0 and grader_mode == 0) 
	#    
	#    game_over = 1
	
	# player_x = PLAYER_START_X
	# player_y = PLAYER_START_Y
	# player_delay, player_vel, and player_timer = 0
	
	lw t0, lives
	ble t0, 0, _endif1
		sub t0, t0,1
		sw t0, lives
		
		j _endif1
	_endif1:
	
	
	lw t0, lives
	li t9, GRADER_MODE
	
	bgt t0, 0, _endif2
	bne t9, 0, _endif2
		
		li t1, 1
		sw t1, game_over
		
		
		j _endif2
	
	_endif2:
	
	
	# When loading constant, using load immediate
	li t2, PLAYER_START_X
	sb t2, player_x
		
	li t2, PLAYER_START_Y
	sb t2, player_y
		
	sb zero, player_delay
	sb zero, player_vel
	sb zero, player_timer
	
	
	
leave





player_get_goal:
enter
	
	jal remove_obj # delete the goal object from the screen
	
	# score += GOAL_SCORE
	lw t0, score
	add t0, t0, GOAL_SCORE
	sw t0, score
	
	
	lw t0, score
	# if (score == MAX_SCORE): game_over = 1
	bne t0, MAX_SCORE, _endif1
		
		li t1, 1
		sw t1, game_over
	
		j _endif1
	_endif1:
	
	
	# player_x = PLAYER_START_X, player_y = PLAYER_START_Y
	# player_delay = 0, player_vel = 0, and player_timer = 0
	li t2, PLAYER_START_X
	sb t2, player_x
		
	li t2, PLAYER_START_Y
	sb t2, player_y
		
	sb zero, player_delay
	sb zero, player_vel
	sb zero, player_timer
	
	
	
leave













