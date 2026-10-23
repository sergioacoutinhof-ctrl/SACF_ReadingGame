extends Node

signal status_changed
var last_error := ""
var runtime: Object
var wrapper: Object


func _ready() -> void:
	if OS.get_name() == "Android" and Engine.has_singleton("AndroidRuntime"):
		runtime = Engine.get_singleton("AndroidRuntime")
		wrapper = Engine.get_singleton("JavaClassWrapper")


func available() -> bool:
	return runtime != null and wrapper != null


func lock_state() -> int:
	if not available():
		return 0
	var manager: Variant = runtime.getActivity().getSystemService("activity")
	if manager == null:
		return 0
	return int(manager.getLockTaskModeState())


func device_has_pin() -> bool:
	if not available():
		return false
	var manager: Variant = runtime.getActivity().getSystemService("keyguard")
	return manager != null and bool(manager.isDeviceSecure())


func start_pinning() -> bool:
	if not available():
		last_error = "A fixação é usada na versão Android."
		return false
	if not device_has_pin():
		last_error = "Defina um PIN de bloqueio no tablet antes de fixar o jogo."
		return false
	var activity: Variant = runtime.getActivity()
	var action := func():
		activity.startLockTask()
		_check_java_exception.call_deferred()
	activity.runOnUiThread(runtime.createRunnableFromGodotCallable(action))
	last_error = "Confirme a fixação no aviso do Android."
	return true


func stop_pinning() -> void:
	if not available() or lock_state() == 0:
		return
	var activity: Variant = runtime.getActivity()
	var action := func():
		activity.stopLockTask()
		_check_java_exception.call_deferred()
	activity.runOnUiThread(runtime.createRunnableFromGodotCallable(action))


func security_settings() -> void:
	if not available():
		return
	var activity: Variant = runtime.getActivity()
	var action := func():
		var intent_class: Variant = wrapper.wrap("android.content.Intent")
		var intent: Variant = intent_class.Intent()
		intent.setAction("android.settings.SECURITY_SETTINGS")
		activity.startActivity(intent)
		_check_java_exception.call_deferred()
	activity.runOnUiThread(runtime.createRunnableFromGodotCallable(action))


func _check_java_exception() -> void:
	if wrapper != null:
		var error: Variant = wrapper.get_exception()
		if error != null:
			last_error = "O Android não concluiu a ação. Confira a fixação em Segurança."
	status_changed.emit()
