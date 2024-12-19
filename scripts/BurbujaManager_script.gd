extends Node

@onready var control = get_node("/root/Control")
var burbujas_restantes = []
var indice_burbuja_actual = 0
@onready var explosion_timer = Timer.new()

func _ready():
	add_child(explosion_timer)
	explosion_timer.one_shot = true
	explosion_timer.connect("timeout", Callable(self, "_explotar_siguiente_burbuja"))

func explotar_todas_burbujas():
	burbujas_restantes = get_tree().get_nodes_in_group("burbuja")
	indice_burbuja_actual = 0

	if burbujas_restantes.size() > 0:
		_explotar_siguiente_burbuja()
	else:
		control.timer.stop()  # Detener el timer si no hay burbujas

func _explotar_siguiente_burbuja():
	if indice_burbuja_actual < burbujas_restantes.size():
		var burbuja = burbujas_restantes[indice_burbuja_actual]

		# Lógica de explosión (efectos visuales, sonidos, etc.)
		if burbuja != null:
			burbuja.reproducir_sonido()  # Llamar a la función para reproducir el sonido de la burbuja
			burbuja.queue_free()

		indice_burbuja_actual += 1

		explosion_timer.wait_time = 0.1  # Espera 0.2 segundos entre explosiones (ajusta este valor)
		explosion_timer.start()
	else:
		control.timer.stop()  # Detener el timer una vez que se explotan todas las burbujas

func explotar_todas_burbujas_juntas():
	for burbuja in get_tree().get_nodes_in_group("burbuja"):
		if burbuja != null:
			burbuja.queue_free()
	control.timer.stop()  # Detener el timer si no hay burbujas
