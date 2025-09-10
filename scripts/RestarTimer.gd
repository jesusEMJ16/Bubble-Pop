extends Label

var tiempo_restante = 30
var is_timer_active = false  

@onready var contador_label = get_node("/root/Control/Contador_label")
@onready var explotadas_label = get_node("/root/Control/Oscuridad_panel/GameOver_panel/VBoxContainer/Labels_panel/VBoxContainer/Explotadas_label")
@onready var record_label = get_node("/root/Control/Oscuridad_panel/GameOver_panel/VBoxContainer/Labels_panel/VBoxContainer/Record_label")
@onready var control = get_node("/root/Control")  # Referencia al Spawner
@onready var burbujamanager = get_node("/root/Control/BurbujaManager")  # Referencia al Spawner

var tiempos_para_temblar = [29, 15, 10, 5, 4, 3, 2, 1, 0]
var ultimo_tiempo_temblado = -1  # Guarda el último tiempo en el que ya se aplicó temblor


func _ready():
	# Inicializa el récord desde el archivo al comenzar el juego
	var record = control.obtener_record()
	record_label.text = "Your Record: " + str(record)  # Mostrar el récord actual

func _process(delta):
	if not is_timer_active:  # Si no está activado, no hacemos nada
		return

	tiempo_restante -= delta
	var tiempo_actual = max(0, int(tiempo_restante))
	text = str(max(0, int(tiempo_restante)))
	
	if tiempo_actual in tiempos_para_temblar and tiempo_actual != ultimo_tiempo_temblado:
		control.temblar_timer()
		ultimo_tiempo_temblado = tiempo_actual  # Evitar que tiemble más de una vez en el mismo segundo
		
	if tiempo_restante <= 0:
		control.mostrar_panel_lose_brevemente()
		# Explotar burbujas al final del tiempo
		burbujamanager.explotar_todas_burbujas()

		# Mostrar resultados en el panel
		get_node("/root/Control/Oscuridad_panel").visible = true
		explotadas_label.text = "Bubbles popped: " + contador_label.text
		# Convertir el texto de `explotadas_label` a un número entero
		var burbujas_explotadas = int(contador_label.text) # Obtener el valor del contador
		
		# Guardar récord si es mayor
		if control.boton_seleccionado == "Timer":
			control.guardar_record(burbujas_explotadas)  # Guardar el récord de Timer
			record_label.text = "Your Record: " + str(control.obtener_record())  # Mostrar el récord de Timer
		elif control.boton_seleccionado == "Survival":
			control.guardar_record_survival(burbujas_explotadas)  # Guardar el récord de Survival
			record_label.text = "Your Record: " + str(control.obtener_record_survival())  # Mostrar el récord de Survival
	
