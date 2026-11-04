extends Node2D
## Salle de test du prototype d'exploration (phase 2). Sera remplacée par de vraies cartes.

const TAILLE := Vector2(320, 180)
const EPAISSEUR_MUR := 8.0
const COULEUR_SOL := Color("#3b4a3f")
const COULEUR_MUR := Color("#8a9a7b")
const POSITION_DEPART := Vector2(60, 60)

const SCENE_VOYAGEUR := preload("res://scenes/personnages/voyageur.tscn")


func _ready() -> void:
	_creer_rectangle(Rect2(Vector2.ZERO, TAILLE), COULEUR_SOL)

	# Murs extérieurs
	_creer_mur(Rect2(0, 0, TAILLE.x, EPAISSEUR_MUR))
	_creer_mur(Rect2(0, TAILLE.y - EPAISSEUR_MUR, TAILLE.x, EPAISSEUR_MUR))
	_creer_mur(Rect2(0, 0, EPAISSEUR_MUR, TAILLE.y))
	_creer_mur(Rect2(TAILLE.x - EPAISSEUR_MUR, 0, EPAISSEUR_MUR, TAILLE.y))

	# Obstacles pour tester les collisions
	_creer_mur(Rect2(140, 70, 40, 24))
	_creer_mur(Rect2(60, 120, 16, 16))

	var voyageur := SCENE_VOYAGEUR.instantiate()
	voyageur.position = POSITION_DEPART
	add_child(voyageur)


func _creer_rectangle(zone: Rect2, couleur: Color) -> void:
	var rectangle := ColorRect.new()
	rectangle.position = zone.position
	rectangle.size = zone.size
	rectangle.color = couleur
	rectangle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rectangle)


## Un mur = un rectangle visible + un corps statique qui bloque le joueur.
func _creer_mur(zone: Rect2) -> void:
	var forme := RectangleShape2D.new()
	forme.size = zone.size

	var collision := CollisionShape2D.new()
	collision.shape = forme

	var corps := StaticBody2D.new()
	corps.position = zone.get_center()
	corps.add_child(collision)
	add_child(corps)

	_creer_rectangle(zone, COULEUR_MUR)
