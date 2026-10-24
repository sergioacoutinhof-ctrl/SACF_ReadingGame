extends RefCounted

const DURATION := 15.0
const GROUND_Y := 600.0
const RUNNER_X := 280.0
const PLAYER_HEIGHT := 198.0
const SPEED := 210.0
const GRAVITY := 1350.0
const JUMP_SPEED := -690.0
const JUMP_BUFFER := 0.24
const COYOTE_TIME := 0.16

var age := 0.0
var distance := 0.0
var feet_y := GROUND_Y
var velocity_y := 0.0
var grounded := true
var jump_buffer := 0.0
var coyote := COYOTE_TIME
var collected := 0
var pickup_letters: Array[String] = []
var total_jumps := 0
var failed := false
var word := "BOLA"
var platforms: Array[Rect2] = []
var holes: Array[Rect2] = []
var stars: Array[Dictionary] = []


func reset(seed_value: int = 0, target_word: String = "BOLA", with_holes: bool = true) -> void:
	age = 0.0
	distance = 0.0
	feet_y = GROUND_Y
	velocity_y = 0.0
	grounded = true
	jump_buffer = 0.0
	coyote = COYOTE_TIME
	collected = 0
	total_jumps = 0
	failed = false
	word = target_word
	platforms.clear()
	holes.clear()
	stars.clear()
	pickup_letters.clear()
	var random := RandomNumberGenerator.new()
	random.seed = seed_value
	var spacing := 2220.0 / maxf(1.0, word.length() - 1.0)
	for index in word.length():
		var x := 650.0 + spacing * index + random.randf_range(-14.0, 14.0)
		stars.append({"position": Vector2(x, 432.0), "collected": false, "letter": word.substr(index, 1), "index": index})
	if with_holes:
		var chosen: Array[int] = []
		for index in [0, word.length() / 2, word.length() - 1]:
			var i := int(index)
			if i < 0 or i >= stars.size() or i in chosen:
				continue
			chosen.append(i)
			holes.append(Rect2(stars[i]["position"].x + 30.0, GROUND_Y, 96.0, 150.0))
	# Plataformas baixas opcionais, sem fechar a passagem dos buracos.
	for x in [1240.0, 2180.0]:
		var safe := true
		for hole in holes:
			if Rect2(x - 80.0, 0, 300, 720).intersects(hole):
				safe = false
		if safe:
			platforms.append(Rect2(x, 552, 150, 28))


func request_jump() -> void:
	if not is_finished():
		jump_buffer = JUMP_BUFFER


func is_finished() -> bool:
	return failed or age >= DURATION


func won() -> bool:
	return not failed and collected == stars.size()


func remaining() -> float:
	return maxf(0.0, DURATION - age)


func has_floor(world_x: float) -> bool:
	for hole in holes:
		if world_x > hole.position.x and world_x < hole.end.x:
			return false
	return true


func advance(delta: float) -> Array[Vector2]:
	var pickups: Array[Vector2] = []
	pickup_letters.clear()
	if is_finished():
		return pickups
	var duration := minf(maxf(delta, 0.0), remaining())
	var left := duration
	while left > 0.000001 and not failed:
		var step := minf(left, 1.0 / 120.0)
		_step(step, pickups)
		left -= step
	age = minf(DURATION, age + (duration - left if failed else duration))
	return pickups


func _step(delta: float, pickups: Array[Vector2]) -> void:
	var world_x := RUNNER_X + distance
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
	world_x = RUNNER_X + distance
	velocity_y += GRAVITY * delta
	feet_y += velocity_y * delta
	grounded = false
	var landing_y := GROUND_Y if has_floor(world_x) and previous_y <= GROUND_Y + 2.0 else INF
	if velocity_y >= 0.0:
		for platform in platforms:
			if world_x + 22.0 >= platform.position.x and world_x - 22.0 <= platform.end.x:
				if previous_y <= platform.position.y + 0.1 and feet_y >= platform.position.y:
					landing_y = minf(landing_y, platform.position.y)
		if feet_y >= landing_y:
			feet_y = landing_y
			velocity_y = 0.0
			grounded = true
	if feet_y > 920.0:
		failed = true
		return
	var body := Rect2(world_x - 57.0, feet_y - PLAYER_HEIGHT, 114.0, PLAYER_HEIGHT).grow(18.0)
	for star in stars:
		# É preciso saltar; a tolerância grande aceita contatos perto da letra.
		if not grounded and not star["collected"] and body.has_point(star["position"]):
			star["collected"] = true
			collected += 1
			pickup_letters.append(str(star["letter"]))
			pickups.append(star["position"] - Vector2(distance, 0))
