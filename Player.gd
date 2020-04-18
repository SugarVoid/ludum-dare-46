extends KinematicBody2D


export (int) var speed = 100


var movement_direction: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if movement_direction != Vector2.ZERO:
		move_and_slide(movement_direction * speed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("down"):
		movement_direction.y += 1
	if event.is_action_pressed("up"):
		movement_direction.y += -1
	if event.is_action_pressed("left"):
		movement_direction.x += -1
	if event.is_action_pressed("right"):
		movement_direction.x += 1

	if event.is_action_released("down"):
		movement_direction.y -= 1
	if event.is_action_released("up"):
		movement_direction.y -= -1
	if event.is_action_released("left"):
		movement_direction.x -= -1
	if event.is_action_released("right"):
		movement_direction.x -= 1
