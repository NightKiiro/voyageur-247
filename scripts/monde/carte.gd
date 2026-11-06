class_name Carte
extends Node2D
## Base de toutes les cartes du monde : sol, murs, objets, sorties, points d'arrivée et Voyageur.
## Chaque carte hérite de cette classe et décrit son contenu dans _construire().

const TAILLE := Vector2(320, 180)
const EPAISSEUR_MUR := 8.0
const COULEUR_SOL := Color("#3b4a3f")
const COULEUR_MUR := Color("#8a9a7b")
const COULEUR_SORTIE := Color("#2c3830")
const COULEUR_PANNEAU := Color("#9c6b3f")
const COULEUR_HALTE := Color("#7fa36b")
## Marge autour d'un objet dans laquelle on peut interagir avec lui.
const MARGE_INTERACTION := 4.0

const SCENE_VOYAGEUR := preload("res://scenes/personnages/voyageur.tscn")

## Points d'arrivée de la carte, par nom (par exemple "depart", "depuis_jardin").
var arrivees: Dictionary = {}
var voyageur: Voyageur


func _ready() -> void:
	_construire()
	voyageur = SCENE_VOYAGEUR.instantiate() as Voyageur
	voyageur.position = get_arrivee("depart")
	add_child(voyageur)


## À redéfinir dans chaque carte : crée le décor et remplit `arrivees`.
func _construire() -> void:
	pass


func get_arrivee(nom: String) -> Vector2:
	if not arrivees.has(nom):
		push_warning("Carte : point d'arrivée inconnu '%s'" % nom)
		return TAILLE / 2
	return arrivees[nom]


func placer_voyageur(position_arrivee: Vector2) -> void:
	voyageur.position = position_arrivee
	GameState.position_joueur = position_arrivee


# --- Outils de construction -------------------------------------------------

func _creer_sol(couleur: Color = COULEUR_SOL) -> void:
	_creer_rectangle(Rect2(Vector2.ZERO, TAILLE), couleur)


func _creer_rectangle(zone: Rect2, couleur: Color) -> void:
	var rectangle := ColorRect.new()
	rectangle.position = zone.position
	rectangle.size = zone.size
	rectangle.color = couleur
	rectangle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rectangle)


## Un mur = un rectangle visible + un corps statique qui bloque le joueur.
func _creer_mur(zone: Rect2, couleur: Color = COULEUR_MUR) -> void:
	var corps := StaticBody2D.new()
	corps.position = zone.get_center()
	corps.add_child(_creer_collision(zone.size))
	add_child(corps)
	_creer_rectangle(zone, couleur)


## Un objet = un mur avec lequel on peut aussi interagir (il lance un dialogue).
func _creer_objet(zone: Rect2, couleur: Color, dialogue_id: String) -> void:
	_creer_mur(zone, couleur)
	var interactable := Interactable.new()
	interactable.dialogue_id = dialogue_id
	interactable.position = zone.get_center()
	interactable.add_child(_creer_collision(zone.size + Vector2.ONE * MARGE_INTERACTION * 2))
	add_child(interactable)


## Une sortie = une zone qui envoie le Voyageur vers un point d'arrivée d'une autre carte.
func _creer_sortie(zone: Rect2, carte_cible: String, arrivee: String) -> void:
	_creer_rectangle(zone, COULEUR_SORTIE)
	var sortie := Area2D.new()
	sortie.monitorable = false
	sortie.position = zone.get_center()
	sortie.add_child(_creer_collision(zone.size))
	sortie.body_entered.connect(_on_sortie_atteinte.bind(carte_cible, arrivee))
	add_child(sortie)


func _creer_collision(taille: Vector2) -> CollisionShape2D:
	var forme := RectangleShape2D.new()
	forme.size = taille
	var collision := CollisionShape2D.new()
	collision.shape = forme
	return collision


func _on_sortie_atteinte(corps: Node2D, carte_cible: String, arrivee: String) -> void:
	if corps is Voyageur:
		Monde.aller_a(carte_cible, arrivee)
