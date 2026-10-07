class_name SwarmUnits
extends RefCounted
func setup(_body, _data) -> void: pass
func update(_dt, _body) -> void: pass
func alive_count() -> int: return 10
func before_damage(_c, _r) -> void: pass
func after_damage(_b) -> void: pass
