extends CharacterBody3D

# Speed vars
# i believe it's preferred to have it consts if we're not changing it during gameplay
var current_speed = 0
var crouching_speed = 2.5
var jogging_speed = 5.0 # note : all "walking" is now jogging, as we don't really have walking in this
var max_speed = 12.0
# Accel + Decel
@export var ground_friction = 20.0
var slide_friction = ground_friction * 0.25
var slide_friction_multiplier = 1
@export var ground_acceleration = 10.0
var horizontal_velocity = Vector3.ZERO
@export var ground_turn_acceleration = 80
@export var accel_to_max_speed_time = 0.5
@export var accel_to_max_speed_timer = 0.0

# will leave/rename after rewriting
var lerp_speed = 10
#@export var air_drag = 0.25

# States
var jogging = false
var sprinting = false # might be useful to state if we're at max running speed to call that sprinting?
var crouching = false
var free_looking = false
var sliding = false
var wall_running = false

# Slide vars
# Consider slide_min_speed and just a way to get out of sliding via jumping out of it or if slowed down enough automatic standing up again, make it feel more momentum-y and natural
var slide_min_speed = 7.0
#@export var slide_timer = 0.0
#@export var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.5
var slide_end_speed_offset = 0.1
var slide_headtilt = 7.0

#Wall running vars
var wall_run_vector = Vector2.ZERO #i'm just looking at how we did the slide, useful here to not turn away from wall run?
var wall_run_deceleration = 1.0 #guesswork, unsure if used yet
var wall_run_gravity = 3.0 
var wall_run_min_speed = 7.0
var wall_run_normal: Vector3 = Vector3.ZERO

# Movement vars
@export var jump_velocity: float = 3.0
var crouching_depth = -1.0
var free_look_tilt_amount = 7
var last_velocity = Vector3.ZERO

# Wall stick vars
const wall_stick_wait_time = 1.0
var wall_normal: Vector3 = Vector3.ZERO
var wall_stick_timer := 0.0
var wall_stick_ready := true
var wall_stick: KinematicCollision3D = null

# Turning vars
const turn_to_face_time: float = 0.3
var turn_to_face_timer: float = 0.0
var turn_to_face_target: Vector3 = Vector3.ZERO
var turn_to_face_angle: float = 0.0

# Input vars
var direction = Vector3.ZERO
@export var mouse_sens = 0.4

#player nodes
@onready var standing_collision_shape = $standing_collision_shape
@onready var crouching_collision_shape = $crouching_collision_shape
@onready var neck = $neck
@onready var head = $neck/head
@onready var eyes = $neck/head/eyes
@onready var camera_3d = $neck/head/eyes/Camera3D


@onready var ray_cast_3d = $RayCast3D

#debug stuff
enum states {running, w_stick, w_run, crouch, slide, jump, falling}
var current_state: states = states.running
@onready var state_label = $StateLabel
@onready var penalty_label = $PenaltyLabel

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _input(event):
	# Mouse looking logic
	if current_state != states.slide:
		if event is InputEventMouseMotion:
			if free_looking:
				neck.rotate_y(deg_to_rad(-event.relative.x) * mouse_sens) 
				neck.rotation.y = clamp(neck.rotation.y,deg_to_rad(-120),deg_to_rad(120))
			#was (deg_to_rad(-event.relative.x * mouse_sens)) but i felt this made more sense
			#also it's the x axis rotating the character on the body's y axis that's why it looks a little weird
			else:
				var turn_amount: float = deg_to_rad(-event.relative.x) * mouse_sens 
				rotate_y(turn_amount)
				direction = direction.rotated(Vector3.UP,turn_amount)
				head.rotate_x(deg_to_rad(-event.relative.y)*mouse_sens)
				head.rotation.x = clamp(head.rotation.x,deg_to_rad(-89),deg_to_rad(89))

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	state_label.text = states.find_key(current_state)

func handle_movement(delta):
	var input_dir = Input.get_vector("left", "right", "forward", "backward").normalized()
	
	var current_speed = Vector3(velocity.x, 0, velocity.z).length()
	var current_direction = Vector3(velocity.x, 0, velocity.z).normalized()
	
	# Handle velocity direction
	var facing_dir = camera_3d.global_basis.z
	facing_dir.y = 0
	facing_dir = facing_dir.normalized()
	var target_h_velocity_dir = (camera_3d.global_basis * Vector3(input_dir.x, 0, input_dir.y))
	target_h_velocity_dir.y = 0
	target_h_velocity_dir = target_h_velocity_dir.normalized()
	var new_direction = current_direction.move_toward(target_h_velocity_dir, delta)
	#print("current direction: " + str(current_direction))
	#print("new direction: " + str(new_direction))
	
	# Handle turn penality
	var angle_to_new = current_direction.angle_to(target_h_velocity_dir)
	var penalty_multiplyer = max(1 - (float(abs(int(rad_to_deg(angle_to_new)))) / 10), 0)
	penalty_label.text = str(penalty_multiplyer)
	#current_speed *= penalty_multiplyer
	
	# Handle velocity magnitude
	var target_speed = max_speed * input_dir.length() * penalty_multiplyer
	#var new_speed = move_toward(current_speed, target_speed * penalty_multiplyer, (max_speed / accel_to_max_speed_time) * delta)
	var new_speed = 0
	if target_speed >= current_speed:
		new_speed = current_speed + ((max_speed / accel_to_max_speed_time) * delta)
	if target_speed < current_speed:
		new_speed = current_speed - ((max_speed / accel_to_max_speed_time) * delta)
	
	if penalty_multiplyer == 0:
		new_speed = 0
	#new_speed *= clamp(penalty_multiplyer * 10, 0, 1)
	
	new_speed = clamp(new_speed, 0, max_speed)
	if is_on_floor():
		if input_dir:
			velocity.x = target_h_velocity_dir.x * new_speed
			velocity.z = target_h_velocity_dir.z * new_speed
		else:
			velocity.x = current_direction.x * new_speed
			velocity.z = current_direction.z * new_speed
	else:
		if input_dir:
			velocity.x = move_toward(velocity.x, target_h_velocity_dir.x * max_speed, (max_speed / accel_to_max_speed_time) * delta)
			velocity.z = move_toward(velocity.z, target_h_velocity_dir.z * max_speed, (max_speed / accel_to_max_speed_time) * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, (max_speed / accel_to_max_speed_time) * delta)
			velocity.z = move_toward(velocity.z, 0, (max_speed / accel_to_max_speed_time) * delta)
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			return
		if Input.is_action_pressed("crouch"):
			set_crouch_camera(true)
			if new_speed >= slide_min_speed:
				current_state = states.slide
				start_slide(target_h_velocity_dir)
				return

func set_crouch_camera(now_crouching):
	var tween = get_tree().create_tween()
	if now_crouching:
		tween.tween_property(head, "position:y", crouching_depth, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	else:
		tween.tween_property(head, "position:y", 0.0, 0.5).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

func start_slide(slide_dir):
	velocity.x = slide_dir.x * slide_speed
	velocity.z = slide_dir.z * slide_speed
	standing_collision_shape.disabled = true
	crouching_collision_shape.disabled = false
	#free_looking = true

func end_slide():
	standing_collision_shape.disabled = false
	crouching_collision_shape.disabled = true
	#free_looking = false

func check_wall_stick():
	var look_dir = Vector3(last_velocity.x, 0, last_velocity.z).normalized()
	var collision := _get_wall_stick_collision()
	if collision and wall_stick_ready:
		var normal := collision.get_normal()
		print(normal)
		var look_normal_dot := normal.dot(look_dir)
		# if we're facing towards the wall then we should start sticking to it
		if look_normal_dot < -0.8: #and wall_stick_timer == 0.0:
			wall_stick_timer = wall_stick_wait_time
			wall_stick = collision
			#wall_stick_ready = false
			wall_normal = normal
			start_wall_stick()
			current_state = states.w_stick
		else:
			wall_normal = normal
			wall_run_vector = Vector3(last_velocity.x, 0, last_velocity.z).normalized().slide(normal).normalized()
			#print(collision.get_angle())
			start_wall_run()
			current_state = states.w_run

func start_wall_stick():
	velocity = Vector3.ZERO
	velocity.y = jump_velocity

func start_wall_run():
	print(wall_run_vector)
	velocity = wall_run_vector * max_speed
	velocity.y = jump_velocity

func _get_wall_stick_collision() -> KinematicCollision3D:
	if not is_on_wall_only():
		return null
	
	if get_slide_collision_count() != 1:
		return null
	
	return get_slide_collision(0)

func apply_gravity(delta):
	velocity.y -= gravity * delta

func _physics_process(delta: float) -> void:
	if current_state not in [states.w_stick, states.w_run]:
		apply_gravity(delta)
	last_velocity = velocity
	move_and_slide()
	state_label.text = states.find_key(current_state)
	
	if current_state == states.running:
		handle_movement(delta)
		check_wall_stick()
		return
	
	if current_state == states.slide:
		velocity = velocity.move_toward(Vector3.ZERO, (max_speed / (accel_to_max_speed_time * 3)) * delta)
		if Input.is_action_just_released("crouch"):
			set_crouch_camera(false)
			end_slide()
			current_state = states.running
			return
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			var dir = Vector3(velocity.x, 0, velocity.z).normalized()
			velocity.x = dir.x * max_speed
			velocity.z = dir.z * max_speed
			set_crouch_camera(false)
			end_slide()
			current_state = states.running
			return
	
	if current_state == states.w_stick:
		velocity.y -= (gravity * delta) / 1.2
		if is_on_floor():
			current_state = states.running
			return
		if Input.is_action_just_pressed("jump"):
			velocity.x = wall_normal.x * max_speed * 0.3
			velocity.z = wall_normal.z * max_speed * 0.3
			velocity.y = jump_velocity
			current_state = states.running 
			return
	
	if current_state == states.w_run:
		velocity.y -= (gravity * delta) / 1.2
		if is_on_floor():
			current_state = states.running
			return
		if Input.is_action_just_pressed("jump"):
			velocity.x += wall_normal.x * max_speed * 0.3
			velocity.z += wall_normal.z * max_speed * 0.3
			velocity.y = jump_velocity
			current_state = states.running 
			return
#############
# OLD STUFF #
#############

#func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#
	#state_label.text = "Idle"
#func _input(event):
	## Mouse looking logic
	#if event is InputEventMouseMotion:
		#if free_looking:
			#neck.rotate_y(deg_to_rad(-event.relative.x) * mouse_sens) 
			#neck.rotation.y = clamp(neck.rotation.y,deg_to_rad(-120),deg_to_rad(120))
		##was (deg_to_rad(-event.relative.x * mouse_sens)) but i felt this made more sense
		##also it's the x axis rotating the character on the body's y axis that's why it looks a little weird
		#else:
			#var turn_amount: float = deg_to_rad(-event.relative.x) * mouse_sens 
			#rotate_y(turn_amount)
			#direction = direction.rotated(Vector3.UP,turn_amount)
			#head.rotate_x(deg_to_rad(-event.relative.y)*mouse_sens)
			#head.rotation.x = clamp(head.rotation.x,deg_to_rad(-98),deg_to_rad(98))
		#
#func _physics_process(delta):
	#
	## Get the input direction and handle the movement/deceleration.
	#var input_dir = Input.get_vector("left", "right", "forward", "backward")
#
	##Handle movement state
#
	## Sync horizontal_velocity with the actual movement velocity.
	#horizontal_velocity = Vector3(velocity.x, 0.0, velocity.z)
#
	## Build up speed while jogging forward.
	#if is_on_floor() and input_dir.y < -0.1 and not sliding and not crouching:
		#accel_to_max_speed_timer = min(accel_to_max_speed_timer + delta,accel_to_max_speed_time)
	#else:
		#accel_to_max_speed_timer = max(accel_to_max_speed_timer-delta*2.0,0.0)
		##decel
#
	#current_speed = lerp(jogging_speed,max_speed,accel_to_max_speed_timer/accel_to_max_speed_time)
#
	## Handle slide initiation.
	#if Input.is_action_pressed("crouch") and not sliding:
		#if is_on_floor() and horizontal_velocity.length() >= slide_min_speed:
			#sliding = true
			##slide_timer = slide_timer_max
#
			## Preserve the direction of the current momentum.
			#slide_vector = Vector2(horizontal_velocity.dot(transform.basis.x),horizontal_velocity.dot(-transform.basis.z)).normalized()
			#free_looking = true
#
	## Handle crouching and standing.
	#if Input.is_action_pressed("crouch") or sliding:
		#head.position.y = lerp(head.position.y,crouching_depth,delta*lerp_speed)
		#standing_collision_shape.disabled = true
		#crouching_collision_shape.disabled = false
		#jogging = false
		#crouching = true
	#else:
		#if not ray_cast_3d.is_colliding():
			#standing_collision_shape.disabled = false
			#crouching_collision_shape.disabled = true
			#head.position.y = lerp(head.position.y,0.0,delta*lerp_speed)
		#crouching = ray_cast_3d.is_colliding()
#
	## Handle free look.
	#if Input.is_action_pressed("free_look") or sliding:
		#free_looking = true
#
		#if sliding:
			#eyes.rotation.z = lerp(eyes.rotation.z,-deg_to_rad(slide_headtilt),delta*lerp_speed)
		#else:
			#eyes.rotation.z = -deg_to_rad(neck.rotation.y*free_look_tilt_amount)
	#else:
		#free_looking = false
		#neck.rotation.y = lerp(neck.rotation.y,0.0,delta*lerp_speed)
		#eyes.rotation.z = lerp(eyes.rotation.z,0.0,delta*lerp_speed)
#
	## Direction handling and movement.
	#if sliding:
		##slide using momentum		
		##Velocity determines also which slide_friction multiplier we want, slowing down more rapidly if going slower than 3.5
		#if horizontal_velocity.length()>=3.5:			
			#slide_friction_multiplier = 1			
		#elif horizontal_velocity.length()<= 3.5:			
			#slide_friction_multiplier = 2.5
		##The deceleration math itself	
		#horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO,slide_friction*slide_friction_multiplier*delta)
		#velocity.x = horizontal_velocity.x
		#velocity.z = horizontal_velocity.z
#
		#if  horizontal_velocity.length() <= crouching_speed or not is_on_floor() or Input.is_action_pressed("jump") or (sliding and Input.is_action_just_released("crouch")):
			#sliding = false
			#crouching = false
			##slide_timer = 0.0
			#print("Slide end")
#
	#else:
		## Normal ground steering.
		#if is_on_floor() and input_dir != Vector2.ZERO:
			#direction = (transform.basis * Vector3(input_dir.x,0,input_dir.y)).normalized()
#
		## Accelerate toward the jogging/sprinting target speed.
		#if input_dir != Vector2.ZERO and direction.length() > 0.01:
			#var target_velocity = direction * (crouching_speed if crouching else current_speed)
#
			#if is_on_floor(): #Causes issue if holding down w and using mouse to steer, feels icey. must fine tune or change.
				#if horizontal_velocity.length()>0.1 and horizontal_velocity.normalized().dot(direction)<0.5:
					#horizontal_velocity = horizontal_velocity.move_toward(target_velocity,ground_turn_acceleration*delta)
				#else: 
					#horizontal_velocity = horizontal_velocity.move_toward(target_velocity,ground_acceleration*delta)
			##else: #not on floor, so in air, use air drag instead (make sure air drag is minimal, otherwise ignore completely?
				##horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO,air_drag * delta)
		#else:
			## Decelerate when there is no input.
			#var rate = ground_friction if is_on_floor() else 0.0
			#horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO,rate * delta)
#
		#velocity.x = horizontal_velocity.x
		#velocity.z = horizontal_velocity.z
#
	#var look_dir := global_basis.get_rotation_quaternion() * Vector3(0, 0, -1)
#
	## Add the gravity.
	#if not is_on_floor() and not wall_stick and not wall_running:
		#velocity.y -= gravity * delta
#
	## don't want to move if we are wall sticking
	#if wall_stick:
		#input_dir = Vector2.ZERO
		#velocity.x = 0.0
		#velocity.z = 0.0
		#wall_stick_timer -= delta
		#if wall_stick_timer <= 0.0:
			#wall_stick_timer = 0.0
			#wall_stick = null
	##special lower 'gravity' for wall running so we stay on the wall longer
	#elif wall_running: 		
		#velocity.y -= wall_run_gravity * delta
		#velocity -= wall_run_normal * 0.5
#
	## Handle Jump.
	#if Input.is_action_just_pressed("jump"):
		#if is_on_floor() and not crouching:
			#velocity.y = jump_velocity
			##animation_player.play("jump")
			##audio_stream_player.play()			
			#sliding = false
			#crouching = false
			#wall_running = false			
		#elif is_on_floor() and crouching: 
			#sliding = false
			#crouching = false
			#wall_running = false		
		#
		#elif wall_stick:
			#if wall_stick_timer > 0.0:
				##was 16.0
				#var launch := wall_stick.get_normal() * 5.5
				## was * 1.5
				#launch += Vector3.UP * jump_velocity 
				#
				#velocity = launch
				#look_at(position + wall_stick.get_normal())
#
				#wall_stick = null
				#wall_stick_timer = 0.0
#
				#turn_to_face_timer = 0.0
				#turn_to_face_target = Vector3.ZERO
				#turn_to_face_angle = 0.0
#
				#sliding = false
				#crouching = false
				#wall_running = false
		#
			##TODO: special jump from wall when wall running ?
		#elif wall_running:
			#var jump_direction = -neck.global_basis.z
			#jump_direction.y = 0.0
			#jump_direction = jump_direction.normalized()
			#velocity.x = jump_direction.x * jump_velocity
			#velocity.z = jump_direction.z * jump_velocity
			#velocity.y = jump_velocity			
			#wall_running = false
			#free_looking = false
#
#
	### Handle Landing
	##if is_on_floor():
		##if last_velocity.y < -10.0:
			##animation_player.play("rolling")
		##elif last_velocity.y < -4.0:
			##animation_player.play("landing")
			#
	## Handle wall stick
	#last_velocity = velocity
	#move_and_slide()
#
	#if wall_running and not is_on_wall_only():
		#wall_running = false
#
	#var collision := _get_wall_stick_collision()
	#if collision and wall_stick_ready:
		#var normal := collision.get_normal()
		#var look_normal_dot := normal.dot(look_dir)
#
		## if we're facing towards the wall then we should start sticking to it
		#if look_normal_dot < -0.8 and wall_stick_timer == 0.0:
			#wall_stick_timer = wall_stick_wait_time
			#wall_stick = collision
			#wall_stick_ready = false
	#
#
		## if we're facing along but a bit into the wall then we can wallrun		
		#if look_normal_dot < 0.3 and wall_stick_timer == 0.0 and horizontal_velocity.length() >= wall_run_min_speed and not wall_running:
			#wall_running = true
			#free_looking = true #think it would feel natural
			#wall_run_normal = normal
			##velocity.y = 0 # kill the upwards motion when touching the wall
			#wall_run_vector = Vector2(horizontal_velocity.dot(transform.basis.x),horizontal_velocity.dot(-transform.basis.z)).normalized()			
#
	## if we press "turn" (Q) and we then rotate to face the normal
	#if Input.is_action_just_pressed("turn") and turn_to_face_timer == 0.0:
		#if wall_stick:
			#turn_to_face_timer = turn_to_face_time
			#turn_to_face_target = wall_stick.get_normal()
			## TODO: pick direction based on which way is closer
			#turn_to_face_angle = turn_to_face_target.signed_angle_to(look_dir, Vector3.UP)
			##straight up copying that one
		#elif wall_running:
			#turn_to_face_timer = turn_to_face_time
			#turn_to_face_target = wall_run_normal
			#turn_to_face_angle = turn_to_face_target.signed_angle_to(look_dir,Vector3.UP)
		#elif is_on_floor():
			#turn_to_face_timer = turn_to_face_time
			#turn_to_face_target = look_dir.rotated(Vector3.UP, PI)
			## TODO: pick direction based on which way is closer
			#turn_to_face_angle = turn_to_face_target.signed_angle_to(look_dir, Vector3.UP)
#
#
	#if turn_to_face_timer > 0.0:
		#var t := turn_to_face_timer / turn_to_face_time
		#var angle := t * turn_to_face_angle
		#var new_look_dir := turn_to_face_target.rotated(Vector3.UP, angle)
		#look_at(global_position + new_look_dir)
#
		#turn_to_face_timer -= delta
		#if turn_to_face_timer < 0.0:
			#turn_to_face_timer = 0.0
#
	#
	#if not is_on_wall() and is_on_floor() and not wall_stick_ready:
		#wall_stick_ready = true
	#
	##check state of character
	#var active_states = []
	#if sliding:
		#active_states.append("sliding")
	#if crouching:
		#active_states.append("crouching")
	#if wall_running:
		#active_states.append("wall_running")
	#if wall_stick:
		#active_states.append("wall_stick")
	##state_label.text = ", ".join(active_states)
	#
	#current_state = handle_states()
	#state_label.text = states.find_key(current_state)
#


#func handle_states() -> states:
	#if wall_running:
		#return states.w_run
	#if wall_stick:
		#return states.w_stick
	#if sliding:
		#return states.slide
	#if crouching:
		#return states.crouch
	#
	#if not is_on_floor():
		#if velocity.y > 0:
			#return states.jump
		#else:
			#return states.falling
	#
	#if Vector3(velocity.x, 0.0, velocity.z).length() > 0:
		#return states.running
	#
	#return states.idle

#
#func _on_end_zone_body_entered(body):
	#if body.is_in_group("Player"):
		#print("Entered the end zone")		
		#get_tree().change_scene_to_file("res://scenes/Level2.tscn")
