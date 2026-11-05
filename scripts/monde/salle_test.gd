extends Node2D
## Salle de test du prototype d'exploration (phase 2). Sera remplacée par de vraies cartes.

const NOM_SCENE := "salle_test"
const TAILLE := Vector2(320, 180)
const EPAISSEUR_MUR := 8.0
const COULEUR_SOL := Color("#3b4a3f")
const COULEUR_MUR := Color("#8a9a7b")
const COULEUR_PANNEAU := Color("#9c6b3f")
const COULEUR_PIERRE := Color("#6f7a86")
const COULEUR_LUMI := Color("#f2d16b")
const COULEUR_HALTE := Color("#7fa36b")
const POSITION_DEPART := Vector2(60, 60)
## Marge autour d'un objet dans laquelle on peut interagir avec lui.
const MARGE_INTERACTION := 4.0
## Emplacement continué au lancement, en attendant l'écran titre.
const EMPLACEMENT_PROTOTYPE := 1

const SCENE_VOYAGEUR := preload("res://scenes/personnages/voyageur.tscn")

var _voyageur: Voyageur


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

	# Objets et personnages pour tester les interactions et les dialogues
	_creer_objet(Rect2(250, 40, 12, 10), COULEUR_PANNEAU, "panneau_brindille")
	_creer_objet(Rect2(230, 130, 14, 10), COULEUR_PIERRE, "pierre_mousse")
	_creer_objet(Rect2(104, 36, 8, 8), COULEUR_LUMI, "lumi_salut")
	_creer_objet(Rect2(110, 142, 12, 8), COULEUR_HALTE, "halte")

	_voyageur = SCENE_VOYAGEUR.instantiate() as Voyageur
	_voyageur.position = POSITION_DEPART
	add_child(_voyageur)

	SaveManager.partie_chargee.connect(_on_partie_chargee)
	_demarrer_partie()


## Continue la partie sauvegardée s'il y en a une, sinon en commence une nouvelle.
func _demarrer_partie() -> void:
	if SaveManager.emplacement_existe(EMPLACEMENT_PROTOTYPE):
		SaveManager.charger(EMPLACEMENT_PROTOTYPE)
	else:
		SaveManager.nouvelle_partie()
		GameState.scene = NOM_SCENE
		GameState.position_joueur = POSITION_DEPART


## Après un chargement, le Voyageur réapparaît là où la partie a été sauvegardée.
func _on_partie_chargee(_emplacement: int) -> void:
	var position_sauvegardee := GameState.position_joueur
	if position_sauvegardee == Vector2.ZERO:
		position_sauvegardee = POSITION_DEPART
	_voyageur.position = position_sauvegardee


func _creer_rectangle(zone: Rect2, couleur: Color) -> void:
	var rectangle := ColorRect.new()
	rectangle.position = zone.position
	rectangle.size = zone.size
	rectangle.color = couleur
	rectangle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rectangle)


## Un mur = un rectangle visible + un corps statique qui bloque le joueur.
func _creer_mur(zone: Rect2, couleur: Color = COULEUR_MUR) -> void:
	var forme := RectangleShape2D.new()
	forme.size = zone.size

	var collision := CollisionShape2D.new()
	collision.shape = forme

	var corps := StaticBody2D.new()
	corps.position = zone.get_center()
	corps.add_child(collision)
	add_child(corps)

	_creer_rectangle(zone, couleur)


## Un objet = un mur avec lequel on peut aussi interagir (il lance un dialogue).
func _creer_objet(zone: Rect2, couleur: Color, dialogue_id: String) -> void:
	_creer_mur(zone, couleur)

	var forme := RectangleShape2D.new()
	forme.size = zone.size + Vector2.ONE * MARGE_INTERACTION * 2

	var collision := CollisionShape2D.new()
	collision.shape = forme

	var interactable := Interactable.new()
	interactable.dialogue_id = dialogue_id
	interactable.position = zone.get_center()
	interactable.add_child(collision)
	add_child(interactable)
