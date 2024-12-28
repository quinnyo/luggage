class_name Qb
extends RefCounted


## Returns true if [param script] inherits from [param base].
static func script_has_base_script(script: Script, base: Script) -> bool:
	assert(script != null)
	assert(base != null)
	while script && script != base:
		script = script.get_base_script()
	return script == base
