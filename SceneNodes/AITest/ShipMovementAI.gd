tool
extends Spatial

var enemy
var up
var forward
var right
var rotateSpeed = 0.05
var targetRot : Vector3
var org_transform
var angleDiff = 0
export var targetAngle = 0
var currentAngle = 0
func _ready():
    org_transform = global_transform
    enemy = get_node("../Enemy")

func _process(delta):
    up = transform.basis.y.normalized()
    forward = transform.basis.x.normalized()
    right = transform.basis.z.normalized()
    # currentAngle = rad2deg(forward.angle_to(Vector3(1,0,0)))
    rotateToAngle(deg2rad(targetAngle))

func rotateToAngle(angle_rad):
    angleDiff = signedAngle(Vector3(1,0,0).rotated(up,(-angle_rad)),forward,up)*0.08
    rotate(up, angleDiff)

func getAngleDist_deg(from, to):
    var max_angle = 360
    var difference = fmod(to - from, max_angle)
    return fmod(2 * difference, max_angle) - difference

func signedAngle(from: Vector3, to: Vector3, up1: Vector3):
    return atan2(to.cross(from).dot(up1), from.dot(to))
