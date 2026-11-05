extends CanvasLayer
## Boîte de dialogue à l'écran : texte lettre par lettre, lumière de Lumi, choix.
## Autoload : BoiteDialogue. Voir docs/GDD.md, section 6.

signal dialogue_termine

## Caractères affichés par seconde.
const VITESSE_TEXTE := 40.0
const COULEUR_FOND := Color("#1d2420")
const COULEUR_BORDURE := Color("#d9c7a3")
## Emplacement utilisé par les haltes, en attendant le menu des 3 emplacements.
const EMPLACEMENT_HALTE := 1

const NOMS := {
	"lumi": "Lumi",
	"ortie": "Ortie",
	"cardon": "Cardon",
	"mirette": "Mirette",
	"narrateur": "",
}
## Couleur de la lumière de Lumi selon son humeur (voir docs/CHARACTERS.md).
const COULEURS_HUMEUR := {
	"joyeuse": Color("#f2d16b"),
	"triste": Color("#9cc3e6"),
	"inquiete": Color("#f4f4f4"),
	"panique": Color("#a8323e"),
}

var _actif := false
var _en_choix := false
var _variante: Dictionary = {}
var _lignes: Array = []
var _index := -1
var _defilement := 0.0
var _selection := 0
var _textes_choix: Array[String] = []
var _voyageur: Voyageur = null

var _cadre: Panel
var _portrait: ColorRect
var _nom: Label
var _texte: Label
var _cadre_choix: PanelContainer
var _liste_choix: VBoxContainer


func _ready() -> void:
	layer = 10
	_construire_interface()
	_cacher()


func est_actif() -> bool:
	return _actif


## Lance un dialogue. Le Voyageur (facultatif) est immobilisé jusqu'à la fin.
func demarrer(dialogue_id: String, voyageur: Voyageur = null) -> void:
	if _actif:
		return
	var variante: Dictionary = Dialogues.obtenir(dialogue_id)
	if variante.is_empty():
		return
	_actif = true
	_voyageur = voyageur
	if _voyageur != null:
		_voyageur.peut_bouger = false
	_cadre.visible = true
	_jouer_variante(variante)


func _process(delta: float) -> void:
	if not _actif or _en_choix or _texte_complet():
		return
	_defilement += delta * VITESSE_TEXTE
	_texte.visible_characters = mini(int(_defilement), _texte.get_total_character_count())


## _input passe avant _unhandled_input : la boîte consomme les touches avant le Voyageur.
func _input(event: InputEvent) -> void:
	if not _actif:
		return
	if _en_choix:
		if event.is_action_pressed("deplacer_haut"):
			_changer_selection(-1)
		elif event.is_action_pressed("deplacer_bas"):
			_changer_selection(1)
		elif event.is_action_pressed("interagir"):
			_valider_choix()
		else:
			return
	elif event.is_action_pressed("interagir"):
		if _texte_complet():
			_ligne_suivante()
		else:
			_texte.visible_characters = -1  # Affiche tout d'un coup.
	else:
		return
	get_viewport().set_input_as_handled()


# --- Déroulement ------------------------------------------------------------

func _jouer_variante(variante: Dictionary) -> void:
	_variante = variante
	_lignes = variante.get("lignes", [])
	_index = -1
	_ligne_suivante()


func _ligne_suivante() -> void:
	_index += 1
	if _index < _lignes.size():
		_afficher_ligne(_lignes[_index])
	elif _variante.has("choix"):
		_afficher_choix(_variante["choix"])
	elif _variante.has("suite"):
		_enchainer(_variante["suite"])
	else:
		_terminer()


func _enchainer(dialogue_id: String) -> void:
	var variante: Dictionary = Dialogues.obtenir(dialogue_id)
	if variante.is_empty():
		_terminer()
	else:
		_jouer_variante(variante)


func _afficher_ligne(ligne: Dictionary) -> void:
	var perso: String = ligne.get("perso", "narrateur")
	_nom.text = NOMS.get(perso, perso.capitalize())
	_portrait.visible = perso == "lumi"
	_portrait.color = COULEURS_HUMEUR.get(ligne.get("humeur", "joyeuse"), COULEURS_HUMEUR["joyeuse"])
	_texte.text = Dialogues.formater(str(ligne.get("texte", "")))
	_texte.visible_characters = 0
	_defilement = 0.0


func _texte_complet() -> bool:
	return _texte.visible_characters == -1 or _texte.visible_characters >= _texte.get_total_character_count()


func _terminer() -> void:
	_actif = false
	_en_choix = false
	_cacher()
	Dialogues.choix_refait_recent = ""
	if is_instance_valid(_voyageur):
		_voyageur.peut_bouger = true
	_voyageur = null
	dialogue_termine.emit()


# --- Choix ------------------------------------------------------------------

func _afficher_choix(choix: Dictionary) -> void:
	_en_choix = true
	_selection = 0
	_texte.visible_characters = -1
	_textes_choix.clear()
	for enfant in _liste_choix.get_children():
		_liste_choix.remove_child(enfant)
		enfant.queue_free()
	for option: Dictionary in choix.get("options", []):
		_textes_choix.append(Dialogues.formater(str(option.get("texte", ""))))
		_liste_choix.add_child(Label.new())
	_cadre_choix.visible = true
	_mettre_a_jour_choix()


func _changer_selection(decalage: int) -> void:
	_selection = wrapi(_selection + decalage, 0, _textes_choix.size())
	_mettre_a_jour_choix()


func _mettre_a_jour_choix() -> void:
	var etiquettes := _liste_choix.get_children()
	for i in etiquettes.size():
		var marque := "> " if i == _selection else "  "
		(etiquettes[i] as Label).text = marque + _textes_choix[i]


func _valider_choix() -> void:
	var choix: Dictionary = _variante["choix"]
	var option: Dictionary = (choix["options"] as Array)[_selection]
	_en_choix = false
	_cadre_choix.visible = false

	# Un choix sans choix_id est un simple menu (par exemple une halte) : le Carnet l'ignore.
	var choix_id: String = choix.get("choix_id", "")
	Dialogues.choix_refait_recent = ""
	if choix_id != "":
		var refait: bool = GameState.faire_choix(choix_id, option["id"])
		if refait:
			Dialogues.choix_refait_recent = choix_id
	_appliquer_effets(option.get("effets", {}))

	if option.has("suite"):
		_enchainer(option["suite"])
	else:
		_terminer()


## Effets d'une option, par exemple {"lien_lumi": 1} ou {"sauvegarder": true}.
func _appliquer_effets(effets: Dictionary) -> void:
	for cle: String in effets:
		if cle.begins_with("lien_"):
			GameState.modifier_lien(cle.trim_prefix("lien_"), int(effets[cle]))
		elif cle == "sauvegarder":
			SaveManager.sauvegarder(EMPLACEMENT_HALTE)
		elif cle == "charger":
			if not SaveManager.charger(EMPLACEMENT_HALTE):
				push_warning("BoiteDialogue : aucune sauvegarde à charger")
		else:
			push_warning("BoiteDialogue : effet inconnu '%s'" % cle)


# --- Interface --------------------------------------------------------------

func _construire_interface() -> void:
	var racine := Control.new()
	racine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	racine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	racine.theme = ThemePixel.creer()
	add_child(racine)

	_cadre = Panel.new()
	_cadre.position = Vector2(8, 118)
	_cadre.size = Vector2(304, 54)
	_cadre.add_theme_stylebox_override("panel", _creer_style())
	racine.add_child(_cadre)

	_portrait = ColorRect.new()
	_portrait.position = Vector2(6, 6)
	_portrait.size = Vector2(14, 14)
	_cadre.add_child(_portrait)

	_nom = Label.new()
	_nom.position = Vector2(26, 3)
	_nom.size = Vector2(272, 12)
	_nom.add_theme_color_override("font_color", COULEUR_BORDURE)
	_cadre.add_child(_nom)

	_texte = Label.new()
	_texte.position = Vector2(26, 15)
	_texte.size = Vector2(272, 36)
	_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_texte.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_cadre.add_child(_texte)

	_cadre_choix = PanelContainer.new()
	_cadre_choix.position = Vector2(196, 70)
	_cadre_choix.add_theme_stylebox_override("panel", _creer_style())
	racine.add_child(_cadre_choix)

	_liste_choix = VBoxContainer.new()
	_liste_choix.add_theme_constant_override("separation", 0)
	_cadre_choix.add_child(_liste_choix)


func _creer_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COULEUR_FOND
	style.border_color = COULEUR_BORDURE
	style.set_border_width_all(1)
	style.set_content_margin_all(4)
	return style


func _cacher() -> void:
	_cadre.visible = false
	_cadre_choix.visible = false
