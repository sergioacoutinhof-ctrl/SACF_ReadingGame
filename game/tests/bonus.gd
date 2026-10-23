extends SceneTree

const RUN = preload("res://bonus_run.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var run = RUN.new()
	run.reset(123, "MAMÃE")
	assert(run.stars.size() == 5 and run.holes.size() == 3)
	var word := ""
	for token in run.stars:
		word += token["letter"]
	assert(word == "MAMÃE", "O bônus repete todas as letras, inclusive acentos e repetições.")
	var first_layout: Array = run.holes.duplicate()
	run.reset(123, "MAMÃE")
	assert(run.holes == first_layout)
	# Sem pular, é possível perder o bônus em um buraco.
	run.advance(15.0)
	assert(run.failed and run.age < 15.0 and not run.won())
	var stopped: float = run.distance
	run.advance(3.0)
	assert(run.distance == stopped)
	# O modo sem buracos mantém o desafio de pegar as letras pulando.
	run.reset(5, "BOLA", false)
	assert(run.holes.is_empty())
	run.advance(14.99)
	assert(not run.is_finished() and not run.failed)
	run.advance(0.02)
	assert(run.is_finished() and is_equal_approx(run.age, 15.0))
	assert(not run.won(), "Não coletar as letras não deve contar como vitória.")
	# Repetição no ar não dá pulos extras.
	run.reset()
	run.request_jump()
	run.advance(0.05)
	assert(run.total_jumps == 1 and run.feet_y < run.GROUND_Y)
	for index in 8:
		run.request_jump()
		run.advance(0.01)
	assert(run.total_jumps == 1)
	# Toque pouco antes de aterrissar é aceito.
	run.reset()
	run.feet_y = run.GROUND_Y - 15
	run.velocity_y = 200
	run.grounded = false
	run.coyote = 0.0
	run.request_jump()
	run.advance(0.15)
	assert(run.total_jumps == 1 and run.velocity_y < 0)
	# Contato andando não coleta; salto coleta uma só vez.
	run.reset(0, "A", false)
	run.platforms.clear()
	run.stars[0]["position"] = Vector2(run.RUNNER_X + 8, 432)
	assert(run.advance(0.016).is_empty())
	run.request_jump()
	assert(run.advance(0.03).size() == 1)
	assert(run.advance(0.03).is_empty() and run.collected == 1 and run.won())
	# Simulação automática confirma que todas as letras e buracos são alcançáveis.
	for target in ["PÉ", "BOLA", "MAMÃE", "CAVALEIRO", "ABACAXIZEIROS"]:
		run.reset(4, target)
		for frame in 2100:
			if run.is_finished():
				break
			if run.grounded:
				for token in run.stars:
					var ahead: float = token["position"].x - run.RUNNER_X - run.distance
					if not token["collected"] and ahead > 0 and ahead < 68:
						run.request_jump()
				for hole in run.holes:
					var ahead: float = hole.position.x - run.RUNNER_X - run.distance
					if ahead > 0 and ahead < 52:
						run.request_jump()
			run.advance(1.0 / 120.0)
		assert(not run.failed and run.won(), "Curso deve ser possível: " + target)
	# Quadros lentos não atravessam o solo nem pulam colisões.
	run.reset(5, "BOLA", false)
	var slow = RUN.new()
	slow.reset(5, "BOLA", false)
	run.request_jump()
	slow.request_jump()
	run.advance(1.5)
	for index in 180:
		slow.advance(1.0 / 120.0)
	assert(absf(run.distance - slow.distance) < 0.01 and absf(run.feet_y - slow.feet_y) < 0.01)
	print("BONUS_OK: letras da palavra, acentos, coleta por salto, queda, vitória, opção sem buracos, cursos possíveis e quadros lentos")
	quit()
