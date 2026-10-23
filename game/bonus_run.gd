extends RefCounted

const DURATION := 15.0
const GROUND_Y := 600.0
const RUNNER_X := 280.0
const PLAYER_HEIGHT := 198.0
const SPEED := 210.0
const GRAVITY := 1350.0
const JUMP_SPEED := -690.0
const JUMP_BUFFER := 0.24
const COYOTE_TIME := 0.12

var age := 0.0
var distance := 0.0
var feet_y := GROUND_Y
var velocity_y := 0.0
var grounded := true
var jump_buffer := 0.0
var coyote := COYOTE_TIME
var collected := 0
var total_jumps := 0
var platforms: Array[Rect2] = []
var stars: Array[Dictionary] = []


func reset(seed_value: int = 0) -> void:
	age = 0.0
	distance = 0.0
	feet_y = GROUND_Y
	velocity_y = 0.0
	grounded = true
	jump_buffer = 0.0
	coyote = COYOTE_TIME
	collected = 0
	total_jumps = 0
	platforms.clear()
	stars.clear()
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	for index in 6:
		var base := 550.0 + index * 690.0
		var top := 536.0 if index % 2 == 0 else 516.0
		top += random.randi_range(-6, 6)
		platforms.append(Rect2(base, top, 205, 29))
		for point in [Vector2(base - 180, 523), Vector2(base - 75, 487),
				Vector2(base + 42, top - 117), Vector2(base + 140, top - 117),
				Vector2(base + 285, 512)]:
			stars.append({"position": point, "collected": false})


func request_jump() -> void:
	if not is_finished():
		jump_buffer = JUMP_BUFFER


func is_finished() -> bool:
	return age >= DURATION


func remaining() -> float:
	return maxf(0.0, DURATION - age)


func advance(delta: float) -> Array[Vector2]:
	var pickups: Array[Vector2] = []
	var remaining_step := minf(maxf(delta, 0.0), remaining())
	# Subdividir protege aterrissagens e coleta quando um quadro demora.
	while remaining_step > 0.000001:
		var step := minf(remaining_step, 1.0 / 120.0)
		_step(step, pickups)
		remaining_step -= step
	age = minf(DURATION, age + maxf(delta, 0.0))
	return pickups


func _step(delta: float, pickups: Array[Vector2]) -> void:
	if grounded:
		coyote = COYOTE_TIME
	else:
		coyote = maxf(0.0, coyote - delta)
	if jump_buffer > 0.0 and (grounded or coyote > 0.0):
		velocity_y = JUMP_SPEED
		grounded = false
		coyote = 0.0
		jump_buffer = 0.0
		total_jumps += 1
	else:
		jump_buffer = maxf(0.0, jump_buffer - delta)
	var previous_y := feet_y
	distance += SPEED * delta
	velocity_y += GRAVITY * delta
	feet_y += velocity_y * delta
	grounded = false
	var landing_y := GROUND_Y
	if velocity_y >= 0.0:
		for platform in platforms:
			var world_x := RUNNER_X + distance
			if world_x + 26.0 >= platform.position.x and world_x - 26.0 <= platform.end.x:
				if previous_y <= platform.position.y + 0.1 and feet_y >= platform.position.y:
					landing_y = minf(landing_y, platform.position.y)
		if feet_y >= landing_y:
			feet_y = landing_y
			velocity_y = 0.0
			grounded = true
	var body := Rect2(RUNNER_X + distance - 45.0, feet_y - PLAYER_HEIGHT + 15.0, 90.0, PLAYER_HEIGHT - 15.0).grow(18.0)
	for star in stars:
		if not star["collected"] and body.has_point(star["position"]):
			star["collected"] = true
			collected += 1
			pickups.append(star["position"] - Vector2(distance, 0))
