extends Node3D
signal buckled
signal state_changed

const Solver = preload("res://scripts/crush_solver.gd")
const TABLE: float = 1.0
const HOME: float = 3.15
var solver = Solver.new()
var solver_script: Script = Solver
var underside: float = HOME
var pressure: float = 100.0
var speed: float = 0.34
var fast_approach: bool = false
var return_speed: float = 0.65
var state: String = "READY"
var captured: bool = false
var plate: Node3D
var target: Node3D
var query := PhysicsShapeQueryParameters3D.new()
var sweep := BoxShape3D.new()
var structural_hold: float = 0.0
var burst_remaining: float = 0.0

func _ready() -> void:
	sweep.size = Vector3(2.55, 0.025, 2.0)
	query.shape = sweep
	query.collision_mask = 2
	query.margin = 0.002

func start() -> void:
	if solver.compression < solver.profile.max_compression-0.001:
		state = "PRESSING"
		state_changed.emit()

func stop() -> void:
	state = "PAUSED"
	state_changed.emit()

func retract() -> void:
	state = "RETURNING"
	state_changed.emit()

func reset() -> void:
	if absf(underside - HOME) > 0.005:
		return
	solver = solver_script.new()
	captured = false
	burst_remaining = 0.0
	structural_hold = 0.0
	state = "READY"
	if target and target.has_method("set_compression"):
		target.set_compression(0.0, true)
	state_changed.emit()

func _physics_process(dt: float) -> void:
	if state == "RETURNING":
		solver.resistance = 0.0
		underside = minf(HOME, underside + dt * return_speed)
		if underside >= HOME:
			state = "READY"
	elif state == "PRESSING":
		structural_hold = maxf(0,structural_hold-dt)
		# Bound even malformed speed values; never teleport through the crush sequence.
		var requested: float = minf(speed * dt, 0.02) if structural_hold <= 0 else 0.0
		var top: float = TABLE + solver.height()
		# Extra motion is only permitted well above the material. Contact uses the
		# original integration step and original solver timing.
		if fast_approach and not captured and underside-top>0.16 and requested>0:
			var steps: int = clampi(int((underside-top-0.16)/requested),1,5)
			requested *= steps
		query.transform = Transform3D(Basis.IDENTITY, Vector3(0, underside + 0.015, 0))
		query.motion = Vector3(0, -requested, 0)
		var hit: PackedFloat32Array = get_world_3d().direct_space_state.cast_motion(query)
		var overlaps: Array = get_world_3d().direct_space_state.intersect_shape(query, 1)
		var gap: float = maxf(underside - top, 0.0)
		if not captured and (hit[0] < 1.0 or not overlaps.is_empty() or gap <= requested + 0.004):
			captured = true
		var free_travel: float = minf(gap, requested)
		underside -= free_travel
		requested -= free_travel
		if captured and requested > 0.0:
			var multiplier: float = 1.75 if burst_remaining>0.0 else (0.88 if solver.has_method("recover") else 0.62)
			burst_remaining = maxf(0.0,burst_remaining-dt)
			var result: Dictionary = solver.step(minf(requested*multiplier,0.02), true, pressure, top - underside)
			underside -= result.travel
			if result.event:
				structural_hold = 0.067
				burst_remaining = 0.30
				if solver.has_method("recover"):
					structural_hold = 0.035
					burst_remaining = 0
				buckled.emit()
			if solver.compression >= solver.profile.max_compression-0.001:
				state = "COMPACTED"
		underside = maxf(underside, TABLE + solver.height())
	if solver.has_method("recover"):
		if state=="RETURNING" or state=="READY": solver.recover(dt,underside-TABLE)
		if target: target.permanent_damage = solver.permanent_damage
	if plate:
		plate.position.y = underside + 0.14
	if target and target.has_method("set_compression"):
		target.set_compression(solver.compression, state == "READY")
