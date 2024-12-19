extends Area2D

signal burbuja_explotada  # Señal que se emite cuando la burbuja explota

# Variables para controlar la burbuja
var velocidad = 100  # Velocidad inicial de la burbuja
var explotada = false  # Bandera para indicar si la burbuja ya ha explotado
var velocidad_incremento = 20  # Incremento de la velocidad después de una explosión
var velocidad_maxima = 300  # Velocidad máxima de la burbuja
var velocidad_horizontal = 0  # Velocidad horizontal de la burbuja
var direccion_horizontal = 0  # Dirección horizontal de la burbuja (-1, 0, 1)
var direccion_vertical = -1  # Dirección vertical de la burbuja (-1 para subir)
var rotacion_velocidad = 0  # Velocidad de rotación de la burbuja
var tiempo_limite = 1.5  # Tiempo límite para ciertas acciones

# Referencias a nodos
@onready var control = get_node("/root/Control")  # Nodo de reproducción de sonido
@onready var sound_player = get_node("/root/Control/SoundPlayer")  # Nodo de reproducción de sonido
@onready var collision_shape = $CollisionShape2D  # Nodo de colisión de la burbuja
@onready var sprite = $burbuja  # Sprite de la burbuja

var sonidos = []  # Lista de sonidos para reproducir cuando la burbuja explota

# Función que se ejecuta cuando la burbuja está lista
func _ready():
	add_to_group("burbuja")  # Añadir la burbuja al grupo "burbuja"

	# Cargar los sonidos de las burbujas en la lista de sonidos
	sonidos.append(load("res://sonidos/pop1.ogg"))
	sonidos.append(load("res://sonidos/pop3.ogg"))
	sonidos.append(load("res://sonidos/pop4.ogg"))
	sonidos.append(load("res://sonidos/pop5.ogg"))
	sonidos.append(load("res://sonidos/pop6.ogg"))
	sonidos.append(load("res://sonidos/pop7.ogg"))
	sonidos.append(load("res://sonidos/pop8.ogg"))
	sonidos.append(load("res://sonidos/pop9.ogg"))
	sonidos.append(load("res://sonidos/pop10.ogg"))
	

	# Establecer la posición inicial aleatoria de la burbuja
	position = Vector2(randf_range(0, get_viewport_rect().size.x), get_viewport_rect().size.y + 100)

	# Establecer un tamaño aleatorio para la burbuja
	var random_size = randi() % 1000
	if random_size < 10:
		if random_size < 5:
			scale = Vector2(4.0, 4.0)  # Tamaño grande
		else:
			scale = Vector2(0.5, 0.5)  # Tamaño pequeño
	elif random_size < 100:
		if random_size < 50:
			scale = Vector2(2.5, 2.5)  # Tamaño medio-grande
		else:
			scale = Vector2(0.75, 0.75)  # Tamaño medio-pequeño
	else:
		var escala = randf_range(1, 1.5)
		scale = Vector2(escala, escala)  # Tamaño entre 1.0 y 1.5

	_update_collision_shape()  # Actualizar la forma de colisión según el tamaño de la burbuja

	# Establecer la dirección y velocidad horizontal de la burbuja de forma aleatoria
	var rng = randi() % 10
	if rng < 2:
		direccion_horizontal = 0
		velocidad_horizontal = 0
		rotacion_velocidad = randf_range(0.05, 0.1)
	else:
		direccion_horizontal = 1 if randi() % 2 == 0 else -1
		velocidad_horizontal = randf_range(50, 100)
		rotacion_velocidad = randf_range(-0.5, 0.5)

# Función que se ejecuta cada frame
func _process(delta):
	# Movimiento de la burbuja en dirección vertical
	position.y += direccion_vertical * velocidad * delta

	# Movimiento de la burbuja en dirección horizontal si tiene velocidad
	if direccion_horizontal != 0:
		position.x += direccion_horizontal * velocidad_horizontal * delta

	# Rotación de la burbuja si tiene velocidad de rotación
	if rotacion_velocidad != 0:
		rotation += rotacion_velocidad * delta

	# Cambiar la dirección horizontal si la burbuja toca los bordes laterales de la pantalla
	if position.x <= 0 or position.x >= get_viewport_rect().size.x:
		direccion_horizontal *= -1
		rotacion_velocidad *= -1

	# Eliminar la burbuja si se sale de la pantalla (por arriba)
	if position.y < -100:
		queue_free()
		
	if control.boton_seleccionado == "Survival" and position.y < 0:  # Verificar si el modo Survival está activo
		control.mostrar_panel_lose_brevemente()
		print("Modo Survival activo")  # Print añadido
		print("Contador:", control.contador_label.contador)  # Print añadido
		control.guardar_record_survival(control.burbujas_explotadas)  # Pasar el valor de burbujas_explotadas del Spawner
		control.mostrar_mensaje_perdiste()  # Llamar a una función en Spawner.gd para mostrar el mensaje
		queue_free()  # Eliminar la burbuja

# Función para actualizar la forma de colisión de la burbuja según su tamaño
func _update_collision_shape():
	if collision_shape.shape:
		collision_shape.shape.set_radius(sprite.texture.get_size().x * scale.x / 2)

# Función que se ejecuta cuando se detecta una entrada de input (como un toque en la pantalla)
func _input(event):
	var button = get_node("/root/Control/Menu_panel/Container/Flechas_button")  # Obtener el TouchScreenButton

	if event is InputEventScreenTouch and event.pressed and not explotada:
		var touch_pos = event.position

		# Verificar si el toque NO está en el Panel ni en el Button (usando shape)
		if not get_node("/root/Control/Menu_panel").get_global_rect().has_point(touch_pos) and \
			not button.shape.get_rect().has_point(button.to_local(touch_pos)):  # Corregido
			
			# Verificar si el toque está dentro del área de colisión de la burbuja
			if collision_shape.shape and collision_shape.shape is CircleShape2D:
				var local_touch_pos = to_local(touch_pos)
				if local_touch_pos.distance_to(Vector2(0, 0)) <= collision_shape.shape.radius:
					# Asegurarse de que solo explote la burbuja más cercana al toque
					var overlapping_areas = get_overlapping_areas()
					if overlapping_areas.size() > 0:
						var closest_bubble = self
						var closest_distance = local_touch_pos.distance_to(Vector2(0, 0))

						# Buscar la burbuja más cercana
						for area in overlapping_areas:
							if area is Area2D and area != self:
								var area_local_pos = area.to_local(touch_pos)
								var distance = area_local_pos.distance_to(Vector2(0, 0))
								if distance < closest_distance:
									closest_bubble = area
									closest_distance = distance

						if closest_bubble == self:
							_on_bubble_popped()
					else:
						_on_bubble_popped()
						
# Función que se ejecuta cuando la burbuja explota
func _on_bubble_popped():
	if not explotada:
		explotada = true
		reproducir_sonido()  # Reproducir sonido de explosión
		emit_signal("burbuja_explotada")  # Emitir señal de explosión
	
		# Aumentar la velocidad de la burbuja después de la explosión
		velocidad = min(velocidad + velocidad_incremento, velocidad_maxima)
		queue_free()  # Liberar la burbuja de la escena
		control.temblar_contador()  # Llamar a la función para temblar el contador


func reproducir_sonido():
	if sound_player:
		var sonido = sonidos[randi() % sonidos.size()]
		sound_player.stream = sonido

		# Ajustar el pitch del sonido dependiendo del tamaño de la burbuja
		if scale.x >= 4.0:
			sound_player.pitch_scale = 0.3
		elif scale.x >= 2.5:
			sound_player.pitch_scale = 0.5
		elif scale.x <= 0.5:
			sound_player.pitch_scale = 1.5
		elif scale.x <= 0.75:
			sound_player.pitch_scale = 1.4
		else:
			sound_player.pitch_scale = clamp(1.5 / scale.x, 0.7, 1.2)

		sound_player.play()
