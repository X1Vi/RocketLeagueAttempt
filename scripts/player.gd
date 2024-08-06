extends CharacterBody3D

@export var max_speed = 100.0
@export var acceleration = 10.0
@export var brake_deceleration = 40.0
@export var friction_deceleration = 10.0
@export var steering_sensitivity = 0.5
@export var steering_speed = 5.0
@export var steering_friction = 2.0
@export var gravity = -20
@export var drift_factor = 0.95
@export var handbrake_drift_factor = 0.7
@export var traction_fast = 0.1
@export var traction_slow = 0.7
@export var reverse_friction_deceleration = 15.0  # Added reverse friction deceleration

@export var camera_rotation_speed = 0.1  # Speed at which the camera follows the car

@export var timer: Timer 

var canBoost: bool = true

var speed = 0.0
var steer_angle = 0.0
var current_velocity = Vector3.ZERO
@export var camera : Camera3D  # Reference to the camera node
var mouse_sensitivity = 0.003  # Sensitivity for mouse movement

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)



func _physics_process(delta):
	boost()
	quit()
	apply_gravity()
	movement(delta)

func _input(event):
	if event is InputEventMouseMotion:
		rotate_camera(event.relative)

func movement(delta):
	var throttle = Input.get_action_strength("W") - Input.get_action_strength("S")
	var steer_input = Input.get_action_strength("A") - Input.get_action_strength("D")
	var handbrake = Input.is_action_pressed("S")  # Assuming you've defined a handbrake action
	
	# Apply acceleration and deceleration
	if throttle > 0:
		speed = move_toward(speed, max_speed, acceleration * throttle * delta)
	elif throttle < 0:
		speed = move_toward(speed, -max_speed / 8, brake_deceleration * abs(throttle) * delta)
	else:
		if speed > 0:
			speed = move_toward(speed, 0, friction_deceleration * delta)
		else:
			speed = move_toward(speed, 0, reverse_friction_deceleration * delta)
	
	# Apply steering
	var turn_factor = clamp(abs(speed) / max_speed, 0, 1)  # Use abs(speed) to handle both forward and backward speeds
	if steer_input != 0:
		steer_angle = move_toward(steer_angle, steer_input * steering_sensitivity, steering_speed * turn_factor * delta)
	else:
		steer_angle = move_toward(steer_angle, 0, steering_friction * delta)
	
	# Rotate the car
	rotate_y(steer_angle * delta * sign(speed))  # Apply rotation based on the direction of movement
	
	# Calculate forward velocity
	var forward_velocity = -global_transform.basis.z * speed
	
	# Apply drifting effect
	var drift = drift_factor if not handbrake else handbrake_drift_factor
	current_velocity = current_velocity.lerp(forward_velocity, drift)
	
	# Apply traction
	var traction = lerp(traction_fast, traction_slow, abs(speed) / max_speed)
	current_velocity = current_velocity.lerp(forward_velocity, traction)
	
	# Set velocity
	velocity.x = current_velocity.x
	velocity.z = current_velocity.z
	
	move_and_slide()

func apply_gravity():
	if not is_on_floor():
		velocity.y += gravity * get_physics_process_delta_time()
	else:
		velocity.y += gravity * get_physics_process_delta_time()

func rotate_camera(mouse_delta):
	if camera != null:
		var yaw = -mouse_delta.x * mouse_sensitivity
		var pitch = -mouse_delta.y * mouse_sensitivity

		# Rotate the car's global_transform
		rotate_y(yaw)

		# Rotate the camera's pitch (around its local X axis)
		camera.rotate_x(pitch)
		# Clamp the camera's pitch rotation to avoid flipping
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-30), deg_to_rad(30))
		
func quit():
	if Input.is_action_just_pressed('Quit'):
		get_tree().quit()

func boost():
	if Input.is_action_just_pressed('Spacebar'):
		canBoost = false
		print("boost activated")
		gravity = abs(gravity)   
		speed = speed * 2
		max_speed = 80
		timer.start()
		
		


func _on_timer_timeout():
	canBoost = true
	gravity = -gravity 
	speed = speed / 2
	max_speed = 100
	print("timer deactivated")
