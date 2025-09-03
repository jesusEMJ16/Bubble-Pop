extends Control

signal pressed

@onready var timer = $Timer  # Referencia al nodo Timer
@onready var contador_label = $Contador_label  # Referencia al nodo Label para el contador
@onready var timer_label = $Timer60_label  # Referencia al nodo Label para el contador
var posicion_original: Vector2
var posicion_originalTimer: Vector2
var shaking: bool = false # Variable para evitar múltiples tweens simultáneos

@onready var btn_home = get_node("Menu_panel/HBoxContainer/Home_button")
@onready var btn_timer = get_node("Menu_panel/HBoxContainer/Timer_button")
@onready var btn_survival = get_node("Menu_panel/HBoxContainer/Survival_button")
@onready var burbujamanager = get_node("/root/Control/BurbujaManager")  # Referencia al Spawner

var menu_visible = true  # Controla la visibilidad del menú
var tween: Tween  # Referencia al nodo Tween
var menu_height  # Declarar menu_height como variable de instancia
var menu_y_original  # Variable para almacenar la posición y original del Panel
var record_survival = 0

var boton_seleccionado = "Home"  # Variable para almacenar el botón seleccionado
# Variables generales para el comportamiento del sistema de burbujas

@export var duracion_objetivo := 60.0  # Duración para alcanzar la dificultad máxima
@export var tiempo_max_inicial := 0.5  # Tiempo inicial entre apariciones de burbujas
@export var tiempo_max_final := 0.1  # Tiempo mínimo entre apariciones de burbujas
@export var velocidad_inicial := 150.0  # Velocidad inicial de las burbujas
@export var velocidad_objetivo := 300.0  # Velocidad máxima de las burbujas
@export var cantidad_inicial := 3  # Cantidad inicial de burbujas por explosión
@export var cantidad_objetivo := 8  # Máxima cantidad de burbujas por explosión
var max_burbujas = 30  # Limitar a 20 burbujas en pantalla
var burbujas_explotadas = 0  # Contador de burbujas explotadas

var tiempo_max := tiempo_max_inicial
var velocidad_burbujas := velocidad_inicial
var cantidad_burbujas_por_explosion := cantidad_inicial

var tiempo_transcurrido := 0.0
var tiempo_curve := Curve.new()
var velocidad_curve := Curve.new()
var cantidad_curve := Curve.new()

func _ready():
        posicion_original = contador_label.position
        posicion_originalTimer = timer_label.position

        menu_height = $Menu_panel.size.y  # Asignar el valor en _ready()
        menu_y_original = $Menu_panel.position.y  # Guardar la posición y original

        get_node("/root/Control/Menu_panel/Container/Flechas_button").connect("pressed", Callable(self, "animar_menu"))
        print("Comenzando juego")
        # Inicializar el estado de los botones
        _actualizar_estado_botones()
        timer.connect("timeout", Callable(self, "_on_timeout"))  # Conectar el temporizador al evento de timeout
        timer.wait_time = tiempo_max
        timer.start()  # Iniciar el temporizador
        # Configurar curvas de dificultad
        _actualizar_curvas()
        # Conectar las burbujas existentes al inicio
        conectar_burbujas_existentes()

func _actualizar_curvas():
        tiempo_curve.clear_points()
        tiempo_curve.add_point(Vector2(0, tiempo_max_inicial))
        tiempo_curve.add_point(Vector2(1, tiempo_max_final))
        velocidad_curve.clear_points()
        velocidad_curve.add_point(Vector2(0, velocidad_inicial))
        velocidad_curve.add_point(Vector2(1, velocidad_objetivo))
        cantidad_curve.clear_points()
        cantidad_curve.add_point(Vector2(0, cantidad_inicial))
        cantidad_curve.add_point(Vector2(1, cantidad_objetivo))
	
func guardar_record(burbujas_explotadas):
	var config = ConfigFile.new()
	# Cargar el archivo existente o crear uno nuevo
	if config.load("user://record.cfg") != OK:
		print("El archivo de récord no existe, será creado.")
	# Obtener el récord actual
	var record_actual = obtener_record()
	print("Récord actual:", record_actual)  # Debug
	# Comparar y guardar el nuevo récord si es mayor
	if burbujas_explotadas > record_actual:
		print("Nuevo récord encontrado:", burbujas_explotadas)
		config.set_value("record", "burbujas_explotadas", burbujas_explotadas)
	# Guardar el archivo y confirmar el éxito
		if config.save("user://record.cfg") == OK:
			print("¡Nuevo récord guardado exitosamente!")
		else:
			print("Error al guardar el archivo de récord.")
	else:
		print("No hay nuevo récord. El valor actual permanece:", record_actual)

func obtener_record():
	print("Obteniendo récord...")  # Debug
	var config = ConfigFile.new()

	# Cargar el archivo y obtener el récord almacenado
	if config.load("user://record.cfg") == OK:
		var record = config.get_value("record", "burbujas_explotadas", 0)
		print("Récord obtenido:", record)
		return record
	else:
		print("No se pudo cargar el archivo de récord. Se devolverá 0 por defecto.")
		return 0
		
func _actualizar_estado_botones():
	# Poner todos los botones en blanco
	btn_home.modulate = Color(1, 1, 1)
	btn_timer.modulate = Color(1, 1, 1)
	btn_survival.modulate = Color(1, 1, 1)

	# Colorear el botón seleccionado de azul
	if boton_seleccionado == "Home":
		btn_home.modulate = Color(0, 0, 1)
	elif boton_seleccionado == "Timer":
		btn_timer.modulate = Color(0, 0, 1)
        elif boton_seleccionado == "Survival":
                btn_survival.modulate = Color(0, 0, 1)


func _process(delta):
        tiempo_transcurrido += delta
        var progreso = clamp(tiempo_transcurrido / duracion_objetivo, 0.0, 1.0)
        tiempo_max = tiempo_curve.sample(progreso)
        velocidad_burbujas = velocidad_curve.sample(progreso)
        cantidad_burbujas_por_explosion = int(round(cantidad_curve.sample(progreso)))


func _input(event):
	if event is InputEventScreenDrag:
		# Aquí puedes manejar el evento de arrastre si lo necesitas
		pass 
	elif event is InputEventScreenTouch and event.pressed:  # Verificar 'pressed' solo para toques
		if get_global_rect().has_point(event.position):
			emit_signal("pressed")
			

func _on_boton_presionado(boton):
	boton_seleccionado = boton.name
	_actualizar_estado_botones()
	print("Botón presionado:", boton.name)  # Añadir print

func conectar_burbujas_existentes():
	for burbuja in get_tree().get_nodes_in_group("burbuja"):
		conectar_burbuja(burbuja)

func conectar_burbuja(burbuja):
	if not burbuja.is_connected("burbuja_explotada", Callable(self, "_on_bubble_popped")):
		burbuja.connect("burbuja_explotada", Callable(self, "_on_bubble_popped"))

func _on_timeout():
        if get_tree().get_nodes_in_group("burbuja").size() < max_burbujas:
                generar_burbuja()
        timer.wait_time = tiempo_max
        timer.start()

func generar_burbuja():
	var burbuja = preload("res://burbuja.tscn").instantiate()
	burbuja.position = Vector2(randf_range(50, get_viewport_rect().size.x - 50), get_viewport_rect().size.y + 100)
	burbuja.velocidad = velocidad_burbujas
	add_child(burbuja)
	burbuja.add_to_group("burbuja")
	conectar_burbuja(burbuja)

func _on_bubble_popped():
        burbujas_explotadas += 1
        print("Burbujas explotadas:", burbujas_explotadas)  # Print añadido
        contador_label.text = str(burbujas_explotadas)

func animar_menu():
	var tween = create_tween()
	if menu_visible:
		print("Escondiendo menú")
		$Bajar_audio.pitch_scale = randf_range(1.8, 2.2)  # Asignar pitch aleatorio
		$Bajar_audio.play() 
		tween.tween_property($Menu_panel, "position:y", $Menu_panel.position.y + self.menu_height, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		$Menu_panel/Container/Flechas_button.texture_normal = load("res://iconos/flecha_arriba.png")  # Cambiar imagen del TouchScreenButton

	else:
		print("Mostrando menú")
		$Subir_audio.pitch_scale = randf_range(1.8, 2.2)  # Asignar pitch aleatorio
		$Subir_audio.play()
		tween.tween_property($Menu_panel, "position:y", menu_y_original, 0.5).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		$Menu_panel/Container/Flechas_button.texture_normal = load("res://iconos/flecha_abajo.png")  # Cambiar imagen del TouchScreenButton

	menu_visible = !menu_visible
	tween.play()


func guardar_record_survival(burbujas_explotadas):
	print(burbujas_explotadas)
	print("Guardando récord de Survival...")  # Print añadido
	var record_actual = obtener_record_survival()
	print("Récord actual de Survival:", record_actual)  # Print añadido

	if burbujas_explotadas > record_actual:
		var config = ConfigFile.new()
		config.load("user://record.cfg")  # Cargar el archivo de configuración
		config.set_value("record", "burbujas_explotadas_survival", burbujas_explotadas)  # Guardar el nuevo récord de Survival
		config.save("user://record.cfg")
		print("¡Nuevo récord en Survival! Burbujas explotadas: ", burbujas_explotadas)
		
func obtener_record_survival():
	print("Obteniendo récord de Survival...")  # Print añadido
	var config = ConfigFile.new()
	if config.load("user://record.cfg") == OK:
		var record = config.get_value("record", "burbujas_explotadas_survival", 0)  # Obtener el récord de Survival, o 0 si no existe
		print("Récord de Survival obtenido:", record)  # Print añadido
		return record
	else:
		return 0
		
		
		
func mostrar_mensaje_perdiste():
	$Oscuridad_panel.visible = true  # Mostrar el panel de "Game Over"
	$Oscuridad_panel/GameOver_panel/VBoxContainer/Labels_panel/VBoxContainer/Explotadas_label.text = "Bubbles popped: " + str(burbujas_explotadas)  # Mostrar las burbujas explotadas
	$Oscuridad_panel/GameOver_panel/VBoxContainer/Labels_panel/VBoxContainer/Record_label.text = "Your Record: " + str(obtener_record_survival())  # Mostrar el récord de Survival
	burbujamanager.explotar_todas_burbujas()  # Explotar todas las burbujas juntas
	timer.stop()
	mostrar_anuncio()
	print("mostrar mensaje de perder")

func mostrar_anuncio():
	print("ANUNCIOO")

	# Obtén la instancia del AdMob Interstitial
	var interstitial = get_node("Interstitial")  # Obtener la referencia al nodo instanciado
	# Llama a la función _on_load_pressed() del script Interstitial para cargar el anuncio
	interstitial._on_load_pressed()
	# Espera a que el anuncio se cargue
	await interstitial.on_interstitial_ad_loaded  # Espera la señal on_interstitial_ad_loaded
	# Muestra el anuncio
	interstitial._on_show_pressed()

func _on_interstitial_closed():
	#logica para despues de cerrar anuncio
	if boton_seleccionado == "Timer":
		_on_timer_pressed()
		print("cerrar anuncio")

	elif boton_seleccionado == "Survival":
		_on_survival_pressed()
		print("mostrar anuncio survival")

		
	
func temblar_contador():
	if shaking: # Si ya está temblando, salir
		return

	shaking = true # Marcar que está temblando
	var tween = create_tween()
	var offset = 5 # Valor de desplazamiento

	tween.tween_property(contador_label, "position", posicion_original + Vector2(offset, offset), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(contador_label, "position", posicion_original + Vector2(-offset, -offset), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Reiniciar la posición al final de la animación, con un pequeño retraso
	tween.tween_callback(Callable(self, "_reset_shaking"))
	tween.play()

func _reset_shaking():
	timer_label.position = posicion_originalTimer # Restablecer la posición ORIGINAL

	contador_label.position = posicion_original # Restablecer la posición ORIGINAL
	shaking = false # Desmarcar que está temblando
	
func temblar_timer():
	if shaking: # Si ya está temblando, salir
		return

	shaking = true # Marcar que está temblando
	var tween = create_tween()
	var offset = 5 # Valor de desplazamiento

	tween.tween_property(timer_label, "position", posicion_originalTimer + Vector2(offset, offset), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(timer_label, "position", posicion_originalTimer + Vector2(-offset, -offset), 0.05).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	# Reiniciar la posición al final de la animación, con un pequeño retraso
	tween.tween_callback(Callable(self, "_reset_shaking"))
	tween.play()
	
func _on_contador_label_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		$button_click_audio.pitch_scale = randf_range(1.8,2.2)
		$button_click_audio.play()
		temblar_contador() # Llamar a la función de temblar aquí


func emitir_senal_boton():
	$Menu_panel/Container/Flechas_button.emit_signal("pressed")

func _on_button_pressed() -> void:
	pass  # Replace with function body.


func _on_home_pressed() -> void:
        tiempo_max_inicial = 0.5
        tiempo_max_final = 0.1
        velocidad_inicial = 150
        velocidad_objetivo = 200
        cantidad_inicial = 3
        cantidad_objetivo = 5
        duracion_objetivo = 60
        max_burbujas = 30
        tiempo_max = tiempo_max_inicial
        velocidad_burbujas = velocidad_inicial
        cantidad_burbujas_por_explosion = cantidad_inicial
        tiempo_transcurrido = 0.0
        _actualizar_curvas()
        burbujamanager.explotar_todas_burbujas_juntas()
        $button_click_audio.pitch_scale = randf_range(0.8, 1.2)  # Asignar pitch aleatorio
        $button_click_audio.play()  # Reproducir el sonido
        boton_seleccionado = "Home"
        print("Botón Home presionado en:")
        $Timer60_label.tiempo_restante = 60 # Reiniciar el temporizador
        $Timer60_label.visible = false # Mostrar el Timer60
        $Contador_label.reiniciar_contador()
        burbujas_explotadas = 0
        $Timer60_label.is_timer_active = false  # Sincroniza el estado del temporizador
        get_node("/root/Control/Oscuridad_panel").visible = false  # Mostrar el panel Oscuridad_panel
        timer.wait_time = tiempo_max
        timer.start()
        _actualizar_estado_botones()
	

func _on_timer_pressed() -> void:
        tiempo_max_inicial = 0.1
        tiempo_max_final = 0.1
        velocidad_inicial = 500
        velocidad_objetivo = 600
        cantidad_inicial = 30
        cantidad_objetivo = 30
        duracion_objetivo = 30
        max_burbujas = 80
        tiempo_max = tiempo_max_inicial
        velocidad_burbujas = velocidad_inicial
        cantidad_burbujas_por_explosion = cantidad_inicial
        tiempo_transcurrido = 0.0
        _actualizar_curvas()
        burbujamanager.explotar_todas_burbujas_juntas()
        $Oscuridad_panel/GameOver_panel/VBoxContainer/Finish_label.text = "Finish Time!"  # Cambiar el texto del Label
        $button_click_audio.pitch_scale = randf_range(0.8, 1.2)  # Asignar pitch aleatorio
        $button_click_audio.play()  # Reproducir el sonido
        boton_seleccionado = "Timer"
        $Timer60_label.is_timer_active = true  # Sincroniza el estado del temporizador
        #Contador Timer60
        $Timer60_label.tiempo_restante = 30 # Reiniciar el temporizador
        $Timer60_label.visible = true # Mostrar el Timer60
        $Contador_label.reiniciar_contador()
        burbujas_explotadas = 0
        get_node("/root/Control/Oscuridad_panel").visible = false  # Mostrar el panel Oscuridad_panel
        timer.wait_time = tiempo_max
        timer.start()
        _actualizar_estado_botones()


func _on_survival_pressed() -> void:
        tiempo_max_inicial = 0.5
        tiempo_max_final = 0.1
        velocidad_inicial = 150
        velocidad_objetivo = 500
        cantidad_inicial = 1
        cantidad_objetivo = 8
        duracion_objetivo = 120
        max_burbujas = 30
        tiempo_max = tiempo_max_inicial
        velocidad_burbujas = velocidad_inicial
        cantidad_burbujas_por_explosion = cantidad_inicial
        tiempo_transcurrido = 0.0
        _actualizar_curvas()
        burbujamanager.explotar_todas_burbujas_juntas()
        $Oscuridad_panel/GameOver_panel/VBoxContainer/Finish_label.text = "Finish Survival!"  # Cambiar el texto del Label
        $button_click_audio.pitch_scale = randf_range(0.8, 1.2)  # Asignar pitch aleatorio
        $button_click_audio.play()  # Reproducir el sonido
        $Timer60_label.tiempo_restante = 60 # Reiniciar el temporizador
        $Timer60_label.visible = false # Mostrar el Timer60
        boton_seleccionado = "Survival"
        $Contador_label.reiniciar_contador()
        burbujas_explotadas = 0
        $Timer60_label.is_timer_active = false  # Sincroniza el estado del temporizador
        get_node("/root/Control/Oscuridad_panel").visible = false  # Mostrar el panel Oscuridad_panel
        timer.wait_time = tiempo_max
        timer.start()
	_actualizar_estado_botones()


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	pass # Replace with function body.


func _on_timer_60_label_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		$button_click_audio.pitch_scale = randf_range(1.8,2.2)
		$button_click_audio.play()
		temblar_timer() # Llamar a la función de temblar aquí

func mostrar_panel_lose_brevemente():
	$Panel_lose.visible = true  # Hacer visible el Panel_lose

	var timer = Timer.new()
	timer.wait_time = 0.1  # Esperar 0.1 segundos
	timer.one_shot = true  # Configurar el temporizador para que se ejecute una sola vez
	timer.connect("timeout", Callable(self, "_on_timer_timeout_panel_lose"))  # Conectar la señal "timeout" a la función _on_timer_timeout_panel_lose
	add_child(timer)
	timer.start()  # Iniciar el temporizador

func _on_timer_timeout_panel_lose():
	$Panel_lose.visible = false  # Ocultar el Panel_lose
	# Puedes eliminar el temporizador aquí si ya no lo necesitas:
	# get_node("Timer").queue_free() 


func _on_reset_button_pressed() -> void:
	if boton_seleccionado == "Timer":
		_on_timer_pressed()
	elif boton_seleccionado == "Survival":
		_on_survival_pressed()
	
