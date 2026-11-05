extends CanvasLayer
## Écran de débogage (F3) : le Carnet et la partie en direct, par-dessus le jeu.
## Autoload : DebugCarnet. N'existe que dans les versions de développement.

## Rafraîchissement en secondes (inutile de recalculer à chaque image).
const INTERVALLE := 0.25
const NB_SOUVENIRS := 4
const LARGEUR := 230.0

var _panneau: PanelContainer
var _texte: Label
var _attente := 0.0


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	layer = 100
	_construire_interface()


## _input : F3 fonctionne même quand une boîte de dialogue est ouverte.
func _input(event: InputEvent) -> void:
	var touche := event as InputEventKey
	if touche == null or not touche.pressed or touche.echo or touche.physical_keycode != KEY_F3:
		return
	_panneau.visible = not _panneau.visible
	if _panneau.visible:
		_rafraichir()
	get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _panneau.visible:
		return
	_attente -= delta
	if _attente > 0.0:
		return
	_attente = INTERVALLE
	_rafraichir()


func _rafraichir() -> void:
	var session: Dictionary = Carnet.data["session"]
	var souvenirs: Array = Carnet.data["souvenirs"]
	var lignes := PackedStringArray()

	lignes.append("Voyageur n°%d   manip %d (%s)" % [
		Carnet.get_numero(), Carnet.get_manipulation(), Carnet.get_niveau_manipulation()])
	lignes.append("Progression   carnet %d / partie %d" % [Carnet.get_progression(), GameState.progression])
	lignes.append("Session %s   combat %s" % [
		"ouverte" if session["ouverte"] else "fermee",
		session["combat_id"] if session["en_combat"] else "non"])
	lignes.append("Partie %s   %d s   %s" % [
		"en cours" if GameState.en_partie else "aucune", int(GameState.temps_de_jeu), GameState.scene])
	lignes.append("Position %d, %d" % [int(GameState.position_joueur.x), int(GameState.position_joueur.y)])
	lignes.append("Pacifisme %d/%d (%s)   violence %d%% (%s)" % [
		int(GameState.pacifisme["epargnes"]), int(GameState.pacifisme["vaincus"]),
		GameState.get_etat_pacifisme(), roundi(GameState.get_tendance_violence() * 100),
		GameState.get_palier_violence()])
	lignes.append("Liens   Lumi %d  Ortie %d  Cardon %d  Mirette %d" % [
		int(GameState.liens["lumi"]), int(GameState.liens["ortie"]),
		int(GameState.liens["cardon"]), int(GameState.liens["mirette"])])
	lignes.append("Choix %s" % GameState.choix)
	lignes.append("Souvenirs :")
	for i in range(maxi(0, souvenirs.size() - NB_SOUVENIRS), souvenirs.size()):
		lignes.append("  %s" % souvenirs[i]["type"])

	_texte.text = "\n".join(lignes)


func _construire_interface() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.75)
	style.set_content_margin_all(3)

	_panneau = PanelContainer.new()
	_panneau.position = Vector2(4, 4)
	_panneau.theme = ThemePixel.creer()
	_panneau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panneau.add_theme_stylebox_override("panel", style)
	_panneau.visible = false
	add_child(_panneau)

	_texte = Label.new()
	_texte.custom_minimum_size.x = LARGEUR
	_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panneau.add_child(_texte)
