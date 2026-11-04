class_name Voyageur
extends CharacterBody2D
## Le personnage joueur : déplacement en 8 directions (voir docs/GDD.md, section 4).

## Vitesse en ligne droite : 60 pixels par seconde, soit exactement 1 pixel par image de physique.
const VITESSE := 60.0
## En diagonale, chaque axe avance à pleine vitesse (1 pixel par image), comme dans Undertale :
## un mouvement parfaitement net, au prix d'une diagonale un peu plus rapide.
const FACTEUR_DIAGONALE := 1.0

## Dernière direction regardée : servira à savoir avec quoi le joueur interagit.
var direction_regard := Vector2.DOWN
## Désactivé pendant les dialogues, les menus et les cinématiques.
var peut_bouger := true


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
	move_and_slide()


## Direction arrondie à l'une des 8 directions, chaque axe valant -1, 0 ou 1.
## Évite le tremblement du stick analogique en pixel art (voir docs/GDD.md, section 4).
func _lire_direction() -> Vector2:
	var brute := Input.get_vector("deplacer_gauche", "deplacer_droite", "deplacer_haut", "deplacer_bas")
	if brute == Vector2.ZERO:
		return Vector2.ZERO
	var angle_arrondi := snappedf(brute.angle(), PI / 4.0)
	return Vector2.from_angle(angle_arrondi).round()
