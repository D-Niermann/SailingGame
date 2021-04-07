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
var targetVector = Vector3(1,0,0)
export var windVec = Vector3(1,0,0)
var currentAngle = 0
var broadSideVec
export var parallelWeight = 0.2
export var windWeight  = 0.5
var towardsWeight = 1  #this can be negative as well to drive away from enemy, now gets set automatically based on optimalDistance
export var broadsideWeight = 0.2
export var optimalDistance = 4
func _ready():
    org_transform = global_transform
    enemy = get_node("../Enemy")

func _process(delta):
    up = transform.basis.y.normalized()
    forward = transform.basis.x.normalized()
    right = transform.basis.z.normalized()
    var towardsEnemy = ((enemy.global_transform.origin - global_transform.origin)).normalized()
    var distToEnemy = (enemy.global_transform.origin - global_transform.origin).length()
    towardsWeight = clamp((distToEnemy-optimalDistance)*0.1,-1,1)
    if signedAngle(forward,towardsEnemy,up)>=0:
        broadSideVec = towardsEnemy.rotated(up, PI/2)
    else:
        broadSideVec = towardsEnemy.rotated(up, -PI/2)
    targetVector = enemy.transform.basis.x * parallelWeight + windVec.normalized() * windWeight + towardsEnemy * towardsWeight + broadSideVec * broadsideWeight
    # currentAngle = rad2deg(forward.angle_to(Vector3(1,0,0)))
    # translation+=forward*0.02
    rotateToAngle()

func rotateToAngle():
    angleDiff = signedAngle(targetVector,forward,up)*0.08
    rotate(up, angleDiff)

func getAngleDist_deg(from, to):
    var max_angle = 360
    var difference = fmod(to - from, max_angle)
    return fmod(2 * difference, max_angle) - difference

func signedAngle(from: Vector3, to: Vector3, up1: Vector3):
    return atan2(to.cross(from).dot(up1), from.dot(to))
