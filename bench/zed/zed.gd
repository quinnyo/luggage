class_name Zed
extends RefCounted


enum ShellType {
	NONE,
	EDIT,
	SIM,
}


enum DatumClass {
	## Invalid class. No extant datum should have this class.
	VOID,
	## Datums that control the object's pose space -- the pose applied to the whole object.
	OBJECT,
	## Datums that influence an object's armature -- its internal spatial configuration.
	ARMATURE,
}


#region entity type IDs
# Zed entity type identifier constants.
# Mostly for use with editor object selection.
const TYPE_PART := &"ZedPart"
const TYPE_ARMATURE_POINT := &"ZedArmaturePoint"
#endregion
