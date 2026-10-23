extends SceneTree

const RUN = preload("res://bonus_run.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var run = RUN.new()
	run.reset(123)
	var first_layout: Array[Rect2] = run.platforms.duplicate()
	run.reset(123)
	assert(run.platforms == first_layout, "Um mesmo curso pode ser reproduzido no teste.")
	# A recompensa termina mesmo sem qualquer toque.
	run.advance(14.99)
	assert(not run.is_finished())
	assert(run.feet_y <= run.GROUND_Y)
	run.advance(0.02)
	assert(run.is_finished() and run.age == 15.0)
	assert(is_equal_approx(run.distance, run.SPEED * 15.0))
	var end_distance: float = run.distance
	run.advance(4)
	assert(run.distance == end_distance, "O bônus não deve continuar após 15 segundos.")
	# Pulo em um toque, com proteção contra saltos extras no ar.
	run.reset()
	run.request_jump()
	run.advance(0.05)
	assert(run.total_jumps == 1 and run.feet_y < run.GROUND_Y)
	for index in 8:
		run.request_jump()
		run.advance(0.01)
	assert(run.total_jumps == 1)
	# Um toque pouco antes da aterrissagem deve ser aproveitado.
	run.reset()
	run.feet_y = run.GROUND_Y - 15
	run.velocity_y = 200
	run.grounded = false
	run.coyote = 0.0
	run.request_jump()
	run.advance(0.15)
	assert(run.total_jumps == 1 and run.velocity_y < 0)
	# A plataforma deve sustentar a personagem após uma queda por cima.
	run.reset()
	var platform: Rect2 = run.platforms[0]
	run.distance = platform.position.x - run.RUNNER_X + 70
	run.feet_y = platform.position.y - 2
	run.velocity_y = 120
	run.grounded = false
	run.advance(0.05)
	assert(run.grounded and is_equal_approx(run.feet_y, platform.position.y))
	# Há tolerância para tocar logo depois de sair da borda.
	run.distance = platform.end.x + 26 - run.RUNNER_X
	run.advance(0.016)
	assert(not run.grounded)
	run.request_jump()
	run.advance(0.016)
	assert(run.total_jumps == 1 and run.velocity_y < 0)
	# Cada estrela pode ser premiada apenas uma vez.
	run.reset()
	run.stars.clear()
	run.stars.append({"position": Vector2(run.RUNNER_X + 2, run.GROUND_Y - 70), "collected": false})
	assert(run.advance(0.016).size() == 1)
	assert(run.advance(0.1).is_empty() and run.collected == 1)
	# Quadros lentos e passos pequenos devem produzir a mesma distância.
	run.reset(5)
	var slow = RUN.new()
	slow.reset(5)
	run.request_jump()
	slow.request_jump()
	run.advance(1.5)
	for index in 180:
		slow.advance(1.0 / 120.0)
	assert(absf(run.distance - slow.distance) < 0.01)
	assert(absf(run.feet_y - slow.feet_y) < 0.01)
	print("BONUS_OK: 15 segundos, salto único, tolerância de toque, plataformas, coleta única e quadros lentos")
	quit()
