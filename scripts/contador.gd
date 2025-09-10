extends Label

@export var contador = 0


func _ready():
	# Inicializa el Label en 0
	text = str(contador)

	# Conectar todas las burbujas que ya existan en la escena al cargar
	conectar_burbujas_existentes()

	# Conectar nuevas burbujas generadas en tiempo real usando Callable correctamente
	get_tree().connect("node_added", Callable(self, "_on_node_added"))

# Conectar todas las burbujas actuales al contador
func conectar_burbujas_existentes():
	for burbuja in get_tree().get_nodes_in_group("burbuja"):
		conectar_burbuja(burbuja)

# Se ejecuta cada vez que se agrega un nuevo nodo a la escena
func _on_node_added(node):
	if node.is_in_group("burbuja"):
		conectar_burbuja(node)

# Función para conectar la señal burbuja_explotada al contador
func conectar_burbuja(burbuja):
	if not burbuja.is_connected("burbuja_explotada", Callable(self, "_on_bubble_popped")):
		burbuja.connect("burbuja_explotada", Callable(self, "_on_bubble_popped"))
		print("Burbuja conectada al contador.")  # Mensaje de depuración para confirmar la conexión

# Función que se ejecuta cuando se recibe la señal 'burbuja_explotada'
func _on_bubble_popped():
	# Incrementa el contador y actualiza el Label
	contador += 1
	update_label()

	print("Contador actualizado: ", contador)  # Mensaje de depuración para confirmar el incremento

func reiniciar_contador():
	contador = 0
	update_label()
# Función para actualizar el Label con el valor del contador
func update_label():
	text = str(contador)
