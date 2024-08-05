extends CharacterBody3D

@export var max_speed = 100.0
@export var acceleration = 10.0
@export var brake_deceleration = 20.0
@export var friction_deceleration = 2.0
@export var steering_sensitivity = 0.5
@export var steering_speed = 5.0
@export var gravity = -9.8
@export var drift_factor = 0.95
@export var handbrake_drift_factor = 0.7
@export var traction_fast = 0.1
@export var traction_slow = 0.7

var speed = 0.0
var steer_angle = 0.0
var current_velocity = Vector3.ZERO

func _physics_process(delta):
	apply_gravity()
	movement(delta)

func movement(delta):
	var throttle = Input.get_action_strength("ui_up") - Input.get_action_strength("ui_down")
	var steer_input = Input.get_action_strength("ui_left") - Input.get_action_strength("ui_right")
	var handbrake = Input.is_action_pressed("ui_down")  # Assuming you've defined a handbrake action
	
	# Apply acceleration and deceleration
	if throttle > 0:
		speed = move_toward(speed, max_speed, acceleration * throttle * delta)
	elif throttle < 0:
		speed = move_toward(speed, -max_speed / 2, brake_deceleration * abs(throttle) * delta)
	else:
		speed = move_toward(speed, 0, friction_deceleration * delta)
	
	# Apply steering
	var turn_factor = clamp(speed / max_speed, 0, 1)
	steer_angle = move_toward(steer_angle, steer_input * steering_sensitivity, steering_speed * turn_factor * delta)
	
	# Rotate the car
	rotate_y(steer_angle * delta)
	
	# Calculate forward velocity
	var forward_velocity = -global_transform.basis.z * speed
	
	# Apply drifting effect
	var drift = drift_factor if not handbrake else handbrake_drift_factor
	current_velocity = current_velocity.lerp(forward_velocity, drift)
	
	# Apply traction
	var traction = lerp(traction_fast, traction_slow, speed / max_speed)
	current_velocity = current_velocity.lerp(forward_velocity, traction)
	
	# Set velocity
	velocity.x = current_velocity.x
	velocity.z = current_velocity.z
	
	move_and_slide()

func apply_gravity():
	if not is_on_floor():
		velocity.y += gravity * get_physics_process_delta_time()
	else:
		velocity.y = 0

func _ready():
	pass
