extends Sprite2D

var velocidad_horizontal = 0.0  # Velocidad horizontal

func _ready():
	velocidad_horizontal = randf_range(5, 10)  # Asignar una velocidad aleatoria
	position.y = randf_range(100, get_viewport_rect().size.y - 100)  # Posición Y aleatoria

func _process(delta):
	# Mover la nube hacia la derecha
	position.x += velocidad_horizontal * delta

	# Si la nube sale de la pantalla por la derecha, la eliminamos
	if position.x > get_viewport_rect().size.x + 100:
		queue_free()  # Eliminar la nube
