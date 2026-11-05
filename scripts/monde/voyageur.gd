class_name Voyageur
extends CharacterBody2D
## Le personnage joueur : déplacement en 8 directions et interactions (voir docs/GDD.md, section 4).

## Vitesse en ligne droite : 60 pixels par seconde, soit exactement 1 pixel par image de physique.
const VITESSE := 60.0
## En diagonale, chaque axe avance à pleine vitesse (1 pixel par image), comme dans Undertale :
## un mouvement parfaitement net, au prix d'une diagonale un peu plus rapide.
const FACTEUR_DIAGONALE := 1.0

## Centre de la collision des pieds (voir la scène voyageur.tscn).
const CENTRE_PIEDS := Vector2(0, -3)
## Distance entre les pieds et le détecteur d'interaction.
const DISTANCE_INTERACTION := 8.0
const TAILLE_DETECTEUR := Vector2(8, 8)

## Dernière direction regardée : sert à savoir avec quoi le joueur interagit.
var direction_regard := Vector2.DOWN
## Désactivé pendant les dialogues, les menus et les cinématiques.
var peut_bouger := true

var _detecteur: Area2D


func _ready() -> void:
	_creer_detecteur()


func _physics_process(_delta: float) -> void:
	if not peut_bouger:
		velocity = Vector2.ZERO
		return

	var direction := _lire_direction()
	var vitesse := VITESSE
	if direction.x != 0 and direction.y != 0:
		vitesse *= FACTEUR_DIAGONALE
	velocity = direction * vitesse

	if direction != Vector2.ZERO:
		direction_regard = direction.normalized()
		_placer_detecteur()
	move_and_slide()
	GameState.position_joueur = global_position


func _unhandled_input(event: InputEvent) -> void:
	if not peut_bouger or not event.is_action_pressed("interagir"):
		return
	var cible := _trouver_interactable()
	if cible != null:
		cible.interagir(self)
		get_viewport().set_input_as_handled()


## Direction arrondie à l'une des 8 directions, chaque axe valant -1, 0 ou 1.
## Évite le tremblement du stick analogique en pixel art (voir docs/GDD.md, section 4).
func _lire_direction() -> Vector2:
	var brute := Input.get_vector("deplacer_gauche", "deplacer_droite", "deplacer_haut", "deplacer_bas")
	if brute == Vector2.ZERO:
		return Vector2.ZERO
	var angle_arrondi := snappedf(brute.angle(), PI / 4.0)
	return Vector2.from_angle(angle_arrondi).round()


# --- Interactions -----------------------------------------------------------

## Petite zone invisible placée devant les pieds, dans la direction du regard.
func _creer_detecteur() -> void:
	var forme := RectangleShape2D.new()
	forme.size = TAILLE_DETECTEUR

	var collision := CollisionShape2D.new()
	collision.shape = forme

	_detecteur = Area2D.new()
	_detecteur.monitorable = false
	_detecteur.add_child(collision)
	add_child(_detecteur)
	_placer_detecteur()


func _placer_detecteur() -> void:
	_detecteur.position = CENTRE_PIEDS + direction_regard * DISTANCE_INTERACTION


## L'Interactable le plus proche du détecteur, ou null s'il n'y en a aucun.
func _trouver_interactable() -> Interactable:
	var meilleure: Interactable = null
	var meilleure_distance := INF
	for zone in _detecteur.get_overlapping_areas():
		if not zone is Interactable:
			continue
		var distance := _detecteur.global_position.distance_squared_to(zone.global_position)
		if distance < meilleure_distance:
			meilleure = zone
			meilleure_distance = distance
	return meilleure
