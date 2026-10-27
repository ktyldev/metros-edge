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
@export var ground_acceleration = 10.0
var horizontal_velocity = Vector3.ZERO
@export var accel_to_max_speed_time = 2.5
@export var accel_to_max_speed_timer = 0.0

# will leave/rename after rewriting
var lerp_speed = 10
@export var air_drag = 2.25

# States
var jogging = false
var sprinting = false # might be useful to state if we're at max running speed to call that sprinting?
var crouching = false
var free_looking = false
var sliding = false

# Slide vars
# Consider slide_min_speed and just a way to get out of sliding via jumping out of it or if slowed down enough automatic standing up again, make it feel more momentum-y and natural
var slide_min_speed = 7.0
#@export var slide_timer = 0.0
#@export var slide_timer_max = 1.0
var slide_vector = Vector2.ZERO
var slide_speed = 10.5
var slide_end_speed_offset = 0.1
var slide_headtilt = 7.0


# Movement vars
const jump_velocity = 5.5
var crouching_depth = -0.5
var free_look_tilt_amount = 7
var last_velocity = Vector3.ZERO

# Wall stick vars
const wall_stick_wait_time = 1.0
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


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		
func _input(event):
	# Mouse looking logic
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
			head.rotation.x = clamp(head.rotation.x,deg_to_rad(-98),deg_to_rad(98))
		
func _physics_process(delta):
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")

	#Handle movement state

	# Sync horizontal_velocity with the actual movement velocity.
	horizontal_velocity = Vector3(velocity.x, 0.0, velocity.z)

	# Build up speed while jogging forward.
	if is_on_floor() and input_dir.y < -0.1 and not sliding and not crouching:
		accel_to_max_speed_timer = min(accel_to_max_speed_timer + delta,accel_to_max_speed_time)
	else:
		accel_to_max_speed_timer = max(accel_to_max_speed_timer-delta*2.0,0.0)

	current_speed = lerp(jogging_speed,max_speed,accel_to_max_speed_timer/accel_to_max_speed_time)

	# Handle slide initiation.
	if Input.is_action_pressed("crouch") and not sliding:
		if is_on_floor() and horizontal_velocity.length() >= slide_min_speed:
			sliding = true
			#slide_timer = slide_timer_max

			# Preserve the direction of the current momentum.
			slide_vector = Vector2(horizontal_velocity.dot(transform.basis.x),horizontal_velocity.dot(-transform.basis.z)).normalized()
			free_looking = true

	# Handle crouching and standing.
	if Input.is_action_pressed("crouch") or sliding:
		head.position.y = lerp(head.position.y,crouching_depth,delta*lerp_speed)
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		jogging = false
		crouching = true
	else:
		if not ray_cast_3d.is_colliding():
			standing_collision_shape.disabled = false
			crouching_collision_shape.disabled = true
			head.position.y = lerp(head.position.y,0.0,delta*lerp_speed)
		crouching = false

	# Handle free look.
	if Input.is_action_pressed("free_look") or sliding:
		free_looking = true

		if sliding:
			eyes.rotation.z = lerp(eyes.rotation.z,-deg_to_rad(slide_headtilt),delta*lerp_speed)
		else:
			eyes.rotation.z = -deg_to_rad(neck.rotation.y*free_look_tilt_amount)
	else:
		free_looking = false
		neck.rotation.y = lerp(neck.rotation.y,0.0,delta*lerp_speed)
		eyes.rotation.z = lerp(eyes.rotation.z,0.0,delta*lerp_speed)

	# Direction handling and movement.
	if sliding:
		#slide using momentum
		#slide_timer -= delta

		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO,slide_friction*delta)

		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z

		if  horizontal_velocity.length() <= 0.1:
			sliding = false
			#slide_timer = 0.0
			print("Slide end")

	else:
		# Normal ground steering.
		if is_on_floor() and input_dir != Vector2.ZERO:
			direction = (transform.basis * Vector3(input_dir.x,0,input_dir.y)).normalized()

		## Air steering.
		# leftovers i believe, do we want air steering? i think stopping in air is already maybe something i'd consider removing if anything, we gotta pick between realism and expected-gamey stuff
		#elif input_dir != Vector2.ZERO:
			#direction = direction.lerp(
				#(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),
				#delta * air_drag
			#).normalized()

		# Accelerate toward the jogging/sprinting target speed.
		if input_dir != Vector2.ZERO and direction.length() > 0.01:
			var target_velocity = direction * current_speed

			if is_on_floor():
				horizontal_velocity = horizontal_velocity.move_toward(target_velocity,ground_acceleration * delta)
			else:
				horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO,air_drag * delta)
		else:
			# Decelerate when there is no input.
			var rate = ground_friction if is_on_floor() else air_drag			
			horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO,rate * delta)

		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z

	var look_dir := global_basis.get_rotation_quaternion() * Vector3(0, 0, -1)

	# Add the gravity.
	if not is_on_floor() and not wall_stick:
		velocity.y -= gravity * delta

	# don't want to move if we are wall sticking
	if wall_stick:
		input_dir = Vector2.ZERO
		velocity = Vector3.ZERO
		wall_stick_timer -= delta
		if wall_stick_timer <= 0.0:
			wall_stick_timer = 0.0
			wall_stick = null
		print("wall_stick_timer: ", wall_stick_timer)

	# Handle Jump.
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = jump_velocity
			#animation_player.play("jump")
			#audio_stream_player.play()
			#cancel slide when jumping
			sliding = false
			crouching = false
		elif wall_stick:
			if wall_stick_timer > 0.0:
				#was 16.0
				var launch := wall_stick.get_normal() * 5.5
				# was * 1.5
				launch += Vector3.UP * jump_velocity 
				
				velocity = launch
				look_at(position + wall_stick.get_normal())

				wall_stick = null
				wall_stick_timer = 0.0

				turn_to_face_timer = 0.0
				turn_to_face_target = Vector3.ZERO
				turn_to_face_angle = 0.0

				sliding = false
				crouching = false


	## Handle Landing
	#if is_on_floor():
		#if last_velocity.y < -10.0:
			#animation_player.play("rolling")
		#elif last_velocity.y < -4.0:
			#animation_player.play("landing")
			
	# Handle wall stick
	last_velocity = velocity
	move_and_slide()

	var collision := _get_wall_stick_collision()
	if collision and wall_stick_ready:
		var normal := collision.get_normal()
		var look_normal_dot := normal.dot(look_dir)

		# if we're facing towards the wall then we should start sticking to it
		if look_normal_dot < -0.8 and wall_stick_timer == 0.0:
			wall_stick_timer = wall_stick_wait_time
			wall_stick = collision
			wall_stick_ready = false
	

		# if we're facing along but a bit into the wall then we can wallrun
		# # TODO: wallrun

	# if we press "turn" (Q) and we then rotate to face the normal
	if Input.is_action_just_pressed("turn") and turn_to_face_timer == 0.0:
		if wall_stick:
			turn_to_face_timer = turn_to_face_time
			turn_to_face_target = wall_stick.get_normal()
			# TODO: pick direction based on which way is closer
			turn_to_face_angle = turn_to_face_target.signed_angle_to(look_dir, Vector3.UP)
		elif is_on_floor():
			turn_to_face_timer = turn_to_face_time
			turn_to_face_target = look_dir.rotated(Vector3.UP, PI)
			# TODO: pick direction based on which way is closer
			turn_to_face_angle = turn_to_face_target.signed_angle_to(look_dir, Vector3.UP)


	if turn_to_face_timer > 0.0:
		var t := turn_to_face_timer / turn_to_face_time
		var angle := t * turn_to_face_angle
		var new_look_dir := turn_to_face_target.rotated(Vector3.UP, angle)
		look_at(global_position + new_look_dir)

		turn_to_face_timer -= delta
		if turn_to_face_timer < 0.0:
			turn_to_face_timer = 0.0

	
	if not is_on_wall() and is_on_floor() and not wall_stick_ready:
		wall_stick_ready = true


func _get_wall_stick_collision() -> KinematicCollision3D:
	if not is_on_wall_only():
		return null

	if get_slide_collision_count() != 1:
		return null

	return get_slide_collision(0)


#
#func _on_end_zone_body_entered(body):
	#if body.is_in_group("Player"):
		#print("Entered the end zone")		
		#get_tree().change_scene_to_file("res://scenes/Level2.tscn")
