extends Node2D

@onready var timer_nubes = $Timer

func _ready():
	timer_nubes.connect("timeout", Callable(self, "generar_nube"))
	timer_nubes.start()

func generar_nube():
	var nube = preload("res://Nube.tscn").instantiate()
	print("Generando nube")
	
	# Asigna una velocidad horizontal lenta
	nube.velocidad_horizontal = randf_range(5, 10)  # Velocidad más lenta
	
	# Asigna una escala pequeña y variable
	var escala = randf_range(0.3, 0.5)
	nube.scale = Vector2(escala, escala)
	
	# Escoge una nube aleatoria
	var random_nube = "res://nubes/nube" + str(randi() % 5 + 1) + ".png"
	nube.texture = load(random_nube)

	# Posición aleatoria en el eje vertical, con un desplazamiento mayor a la izquierda
	var y_pos = randf_range(100, get_viewport_rect().size.y - 100)
	nube.position = Vector2(-100, y_pos)  # Aparece más lejos de la pantalla para entrar suavemente

	add_child(nube)

	# Conectar para que se eliminen cuando salgan de la pantalla
	nube.connect("tree_exiting", Callable(self, "_on_nube_salir").bind(nube))  # Conectar la señal sin enviar argumentos

func _on_nube_salir(nube):
	nube.queue_free()  # Eliminar nube cuando salga

func _process(delta):
	for nube in get_children():
		if nube is Sprite2D:  # Solo afectar a los objetos de tipo Sprite2D (nubes)
			if nube.position.x >= get_viewport_rect().size.x + 100:  # Si sale por la derecha
				nube.queue_free()  # Eliminar nube cuando salga
			else:
				nube.position.x += nube.velocidad_horizontal * delta  # Mover la nube horizontalmente
