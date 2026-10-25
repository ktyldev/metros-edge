extends CharacterBody3D

# Speed vars
var current_speed = 5.0
const walking_speed = 5.0
const sprinting_speed = 9.5
const crouching_speed = 2.5
const lerp_speed = 10
@export var air_lerp_speed = 2.25

# States
var walking = false
var sprinting = false
var crouching = false
var free_looking = false
var sliding = false

# Slide vars
var slide_timer = 0.0
var slide_timer_max = 1
var slide_vector = Vector2.ZERO
var slide_speed = 10.5
var slide_end_speed_offset = 0.1
var slide_headtilt = 7

## Head bobbing vars
#const head_bobbing_speed_sprinting = 22.0
#const head_bobbing_speed_walking = 14.0
#const head_bobbing_speed_crouching = 10.0
#
#var head_bobbing_intensity_current = 0
#const head_bobbing_intensity_sprinting = 0.2
#const head_bobbing_intensity_walking = 0.1
#const head_bobbing_intensity_crouching = 0.05
#
#var head_bobbing_vector = Vector2.ZERO
#var head_bobbing_index = 0.0


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
#@onready var hand_cam = $SubViewportContainer/SubViewport/HandCam
#@onready var player_arms = $neck/Player_Arms

@onready var ray_cast_3d = $RayCast3D
#@onready var animation_player = $neck/head/eyes/AnimationPlayer
#@onready var audio_stream_player = $AudioStreamPlayer

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
#leftovers kept for comparison
#func _process(delta):
	#
	#hand_cam.global_transform = camera_3d.global_transform
	##make hands follow the camera
	
	
	
func _input(event):
	# Mouse looking logic
	if event is InputEventMouseMotion:
		if free_looking:
			neck.rotate_y(deg_to_rad(-event.relative.x) * mouse_sens) 
			neck.rotation.y = clamp(neck.rotation.y,deg_to_rad(-120),deg_to_rad(120))
		#was (deg_to_rad(-event.relative.x * mouse_sens)) but i felt this made more sense
		#also it's the x axis rotating the character on the body's y axis that's why it looks a little weird
		else:
			rotate_y(deg_to_rad(-event.relative.x) * mouse_sens) 
			head.rotate_x(deg_to_rad(-event.relative.y)*mouse_sens)
			head.rotation.x = clamp(head.rotation.x,deg_to_rad(-98),deg_to_rad(98))
		
func _physics_process(delta):
	
	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")

	#Handle movement state
	# Crouching
	if Input.is_action_pressed("crouch") || sliding:
		current_speed = lerp(current_speed, crouching_speed, delta * lerp_speed)
		
		head.position.y = lerp(head.position.y, crouching_depth, delta*lerp_speed)
		
		standing_collision_shape.disabled = true
		crouching_collision_shape.disabled = false
		
		#slide beginning logic
		if sprinting && input_dir != Vector2.ZERO:
			sliding = true
			slide_timer = slide_timer_max
			slide_vector = input_dir
			#prevent camera from altering slide direction via using free look during slide
			free_looking = true
			print("Slide start")
			
		walking = false
		sprinting = false
		crouching = true
		#could be freelooking or sliding 
		
	# Standing logic
	elif !ray_cast_3d.is_colliding():
		standing_collision_shape.disabled = false
		crouching_collision_shape.disabled = true
		
		head.position.y = lerp(head.position.y, 0.0,delta*lerp_speed)
		
		# Sprinting		
		if Input.is_action_pressed("sprint"):
			current_speed = lerp(current_speed, sprinting_speed, delta * lerp_speed)
			walking = false
			sprinting = true
			crouching = false
		# Walking
		else:
			current_speed = lerp(current_speed, walking_speed, delta * lerp_speed)	
			walking = true
			sprinting = false
			crouching = false
			
	# Handle free look
	if Input.is_action_pressed("free_look") || sliding:
		free_looking = true
		if sliding:
			eyes.rotation.z = lerp(eyes.rotation.z,-deg_to_rad(slide_headtilt),delta*lerp_speed)
		else:
			eyes.rotation.z = -deg_to_rad(neck.rotation.y*free_look_tilt_amount)
	else:
		free_looking = false 
		neck.rotation.y = lerp(neck.rotation.y, 0.0, delta*lerp_speed)
		eyes.rotation.z = lerp(eyes.rotation.z, 0.0, delta*lerp_speed)
	
	# Handle sliding
	if sliding:
		slide_timer -= delta
		if slide_timer <=0:
			sliding = false
			free_looking = false
			print("Slide end")
			
	#direction handling stuff
	if is_on_floor():
		direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerp_speed)
	elif input_dir != Vector2.ZERO:
			direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*air_lerp_speed)
	
	if sliding:
		direction = (transform.basis * Vector3(slide_vector.x, 0, slide_vector.y)).normalized()
		current_speed = (slide_timer + slide_end_speed_offset) * slide_speed		
		
		
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
			
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	## Handle headbob
	#if sprinting:
		#head_bobbing_intensity_current = head_bobbing_intensity_sprinting
		#head_bobbing_index += head_bobbing_speed_sprinting * delta
	#elif walking: 
		#head_bobbing_intensity_current = head_bobbing_intensity_walking
		#head_bobbing_index += head_bobbing_speed_walking * delta
	#elif crouching:
		#head_bobbing_intensity_current = head_bobbing_intensity_crouching
		#head_bobbing_index += head_bobbing_speed_crouching * delta
	#
	#if is_on_floor() && !sliding && input_dir != Vector2.ZERO:
		##for every side to side we go up and down twice
		#head_bobbing_vector.y = sin(head_bobbing_index)
		#head_bobbing_vector.x = sin(head_bobbing_index/2)+0.5
		#eyes.position.y = lerp(eyes.position.y, head_bobbing_vector.y*(head_bobbing_intensity_current/2),delta*lerp_speed)
		#eyes.position.x = lerp(eyes.position.x, head_bobbing_vector.x*head_bobbing_intensity_current,delta*lerp_speed)
	#else:
		#eyes.position.y = lerp(eyes.position.y, 0.0,delta*lerp_speed) 
		#eyes.position.x = lerp(eyes.position.x, 0.0,delta*lerp_speed) 
		
		
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

				var launch := wall_stick.get_normal() * 16.0
				launch += Vector3.UP * jump_velocity * 1.5
				
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

	# if we press "turn" and we then rotate to face the normal
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
