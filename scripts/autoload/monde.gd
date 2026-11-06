extends CanvasLayer
## Changements de carte avec fondu au noir. Autoload : Monde.
## Ouvre aussi la carte sauvegardée après chaque chargement.

const DUREE_FONDU := 0.25
const CARTE_DEPART := "salle_test"
## Toutes les cartes du jeu, par identifiant (celui stocké dans les sauvegardes).
const CARTES := {
	"salle_test": "res://scenes/monde/salle_test.tscn",
	"jardin_test": "res://scenes/monde/jardin_test.tscn",
}

var _rideau: ColorRect
var _en_transition := false


func _ready() -> void:
	layer = 50
	_rideau = ColorRect.new()
	_rideau.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rideau.color = Color(0, 0, 0, 0)
	_rideau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rideau)
	SaveManager.partie_chargee.connect(_on_partie_chargee)


func est_en_transition() -> bool:
	return _en_transition


## Le joueur emprunte une sortie : compte comme une progression.
func aller_a(carte_id: String, arrivee: String) -> void:
	if _en_transition:
		return
	GameState.avancer_progression()
	_changer_carte(carte_id, arrivee)


## Entre dans une carte sans progression (début de partie).
func entrer(carte_id: String, arrivee: String) -> void:
	if _en_transition:
		return
	_changer_carte(carte_id, arrivee)


## Après un chargement : la carte et la position viennent de la sauvegarde.
func _on_partie_chargee(_emplacement: int) -> void:
	_changer_carte(GameState.scene, "")


## arrivee vide = utiliser la position enregistrée dans GameState.
func _changer_carte(carte_id: String, arrivee: String) -> void:
	if not CARTES.has(carte_id):
		push_warning("Monde : carte inconnue '%s', retour au départ" % carte_id)
		carte_id = CARTE_DEPART
		arrivee = "depart"
	if arrivee == "" and GameState.position_joueur == Vector2.ZERO:
		arrivee = "depart"

	_en_transition = true
	await _fondu(1.0)
	GameState.scene = carte_id
	get_tree().change_scene_to_file(CARTES[carte_id])
	await get_tree().scene_changed

	var carte := get_tree().current_scene as Carte
	if carte != null:
		var position_arrivee: Vector2 = GameState.position_joueur
		if arrivee != "":
			position_arrivee = carte.get_arrivee(arrivee)
		carte.placer_voyageur(position_arrivee)

	await _fondu(0.0)
	_en_transition = false


func _fondu(opacite: float) -> void:
	var tween := create_tween()
	tween.tween_property(_rideau, "color:a", opacite, DUREE_FONDU)
	await tween.finished
