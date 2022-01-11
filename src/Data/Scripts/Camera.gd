extends Camera

signal single_rightclick() # Rightclick without moving the mouse

# General purpose configurable camera script
# later getting things like "follow player" for camera at stations

export var flyspeed: float = 0.5
export var mouseSensitivity: float = 10
export var cameraFactor: float = 0.1 ## The Factor, how much the camera moves at acceleration and braking

var yaw: float = 0
var pitch: float = 0

onready var cameraY: float = rotation_degrees.y - 90.0
onready var cameraX: float = -rotation_degrees.x

# whether the camera is tied to a point or can move around with wasd
export var fixed: bool = true

# whether to apply or not acceleration effect on camera
export var accel: bool = false

# Saves the camera position at the beginning. The Camera Position will be changed, when the train is accelerating, or braking
onready var cameraZeroTransform: Transform = transform

# Reference delta at 60fps
const refDelta: float = 0.0167 # 1.0 / 60

var world: Node
var player: LTSPlayer

var mouseMotion: Vector2 = Vector2(0,0)
var saved_mouse_position: Vector2 = Vector2(0,0)
var mouse_not_moved: bool = false


func _ready() -> void:
	self.set_process_input(true)
	self.set_process(true)
	Root.connect("world_origin_shifted", self, "_on_world_origin_shifted")


func _on_world_origin_shifted(delta: Vector3):
	translation += delta


func _input(event) -> void:
	if Root.Editor and get_parent().get_node("EditorHUD").mouse_over_ui:
		return

	if current and event is InputEventMouseMotion and (not Root.Editor or Input.is_mouse_button_pressed(BUTTON_RIGHT)):
		mouseMotion = mouseMotion + event.relative
		if event.relative != Vector2(0,0):
			mouse_not_moved = false

	if current and event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed == true:
		saved_mouse_position = get_viewport().get_mouse_position()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_not_moved = true

	if current and event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed == false and Root.Editor:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_viewport().warp_mouse(saved_mouse_position)

	if current and event is InputEventMouseButton and event.button_index == BUTTON_RIGHT and event.pressed == false and mouse_not_moved:
		emit_signal("single_rightclick")


func _process(delta: float) -> void:
	if get_tree().paused and not Root.ingame_pause:
		return
	if not current:
		pass
	if not world:
		world = find_parent("World")
	if not player and world != null:
		player = world.find_node("Player")

	cameraY = rotation_degrees.y - 90.0
	cameraX = -rotation_degrees.x
	#mouse movement

	if not Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and not Root.mobile_version and not Root.Editor and not Root.pause_mode:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if mouseMotion.length() > 0 and (not Root.Editor or Input.is_mouse_button_pressed(BUTTON_RIGHT)):
		var motionFactor: float = (refDelta / delta * refDelta) * mouseSensitivity
		cameraY += -mouseMotion.x * motionFactor
		cameraX += +mouseMotion.y * motionFactor
		if cameraX > 85:
			cameraX = 85
		if cameraX < -85:
			cameraX = -85
		rotation_degrees.y = cameraY +90
		rotation_degrees.x = -cameraX
		mouseMotion = Vector2(0,0)


	if accel and player:
		var currentRealAcceleration = player.currentRealAcceleration
		var speed = player.speed
		var sollCameraPosition = cameraZeroTransform.origin.x + (currentRealAcceleration * -cameraFactor)
		if speed == 0:
			sollCameraPosition = cameraZeroTransform.origin.x
		var missingCameraPosition = translation.x - sollCameraPosition
		translation.x -= missingCameraPosition * delta

	if not fixed and (not Root.Editor or Input.is_mouse_button_pressed(BUTTON_RIGHT)):
		var deltaFlyspeed: float = (delta / refDelta) * flyspeed

		if(Input.is_key_pressed(KEY_W)):
			self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(0,0,1) * deltaFlyspeed)
		if(Input.is_key_pressed(KEY_S)):
			self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(0,0,1) * -deltaFlyspeed)
		if(Input.is_key_pressed(KEY_A) and not Input.is_key_pressed(KEY_CONTROL)):
			self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(1,0,0) * deltaFlyspeed)
		if(Input.is_key_pressed(KEY_D)):
			self.set_translation(self.get_translation() - get_global_transform().basis*Vector3(1,0,0) * -deltaFlyspeed)
		if(Input.is_key_pressed(KEY_SHIFT)):
			flyspeed = 2
		else:
			flyspeed = 0.5
