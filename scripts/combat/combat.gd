extends CanvasLayer
## Combat tour par tour (voir docs/GDD.md, section 5). Autoload : Combat.
## Prototype : la phase d'esquive viendra plus tard ; en attendant, l'ennemi inflige des dégâts fixes.

## Émis à la fin du combat avec "epargne", "vaincu" ou "defaite".
signal combat_termine(issue: String)

const FICHIER_ENNEMIS := "res://data/ennemis/ennemis.json"
const ACTIONS := ["Frapper", "Parler", "Objet", "Lumi"]
const DEGATS_FRAPPE := 5
## Frapper un ennemi presque apaisé fait chuter son apaisement (voir GDD, section 5).
const CHUTE_APAISEMENT_FRAPPE := 30
const SOIN_POTION := 10
## Emplacement rechargé après une défaite, en attendant l'écran de chargement.
const EMPLACEMENT_DEFAITE := 1

const LARGEUR_JAUGE := 80.0
const COULEUR_FOND := Color("#14181a")
const COULEUR_CADRE := Color("#d9c7a3")
const COULEUR_SELECTION := Color("#f2d16b")
const COULEUR_TEXTE := Color("#f4f4f4")
const COULEUR_JAUGE_VIDE := Color("#2a2f31")
const COULEUR_PV := Color("#c0504d")
const COULEUR_APAISEMENT := Color("#6fb3d2")

enum Etat { INACTIF, MESSAGE, MENU, SOUS_MENU }

var _ennemis: Dictionary = {}
var _etat := Etat.INACTIF
var _ennemi_id := ""
var _ennemi: Dictionary = {}
var _pv_ennemi := 0
var _pv_ennemi_max := 1
var _apaisement := 0
var _action := 0
var _selection := 0
var _options: Array[Dictionary] = []
var _messages: Array[String] = []
var _apres_messages: Callable

var _racine: Control
var _nom: Label
var _jauge_pv: ColorRect
var _jauge_apaisement: ColorRect
var _silhouette: ColorRect
var _texte: Label
var _sous_menu: VBoxContainer
var _pv_joueur: Label
var _menu: HBoxContainer


func _ready() -> void:
	layer = 20
	_charger_ennemis()
	_construire_interface()
	_racine.visible = false


func est_actif() -> bool:
	return _etat != Etat.INACTIF


func lancer(ennemi_id: String) -> void:
	if est_actif():
		return
	if not _ennemis.has(ennemi_id):
		push_error("Combat : ennemi inconnu '%s'" % ennemi_id)
		return

	_ennemi_id = ennemi_id
	_ennemi = _ennemis[ennemi_id]
	_pv_ennemi_max = int(_ennemi["pv"])
	_pv_ennemi = _pv_ennemi_max
	_apaisement = 0
	_action = 0

	_figer_voyageur(true)
	Carnet.debut_combat(ennemi_id)
	if _ennemi.get("boss", false):
		Carnet.rencontrer_boss(ennemi_id)

	_nom.text = _ennemi["nom"]
	_silhouette.color = Color(_ennemi.get("couleur", "#ffffff"))
	_mettre_a_jour_jauges()
	_mettre_a_jour_pv_joueur()
	_racine.visible = true
	_afficher_messages([_ennemi["intro"]], _ouvrir_menu)


## _input : le combat consomme les touches avant tout le reste (sauf l'écran F3).
func _input(event: InputEvent) -> void:
	if _etat == Etat.INACTIF:
		return
	var gere := true
	match _etat:
		Etat.MESSAGE:
			if event.is_action_pressed("interagir"):
				_message_suivant()
			else:
				gere = false
		Etat.MENU:
			if event.is_action_pressed("deplacer_gauche"):
				_changer_action(-1)
			elif event.is_action_pressed("deplacer_droite"):
				_changer_action(1)
			elif event.is_action_pressed("interagir"):
				_choisir_action()
			else:
				gere = false
		Etat.SOUS_MENU:
			if event.is_action_pressed("deplacer_haut"):
				_changer_option(-1)
			elif event.is_action_pressed("deplacer_bas"):
				_changer_option(1)
			elif event.is_action_pressed("interagir"):
				_valider_option()
			elif event.is_action_pressed("annuler"):
				_ouvrir_menu()
			else:
				gere = false
	if gere:
		get_viewport().set_input_as_handled()


# --- Messages ---------------------------------------------------------------

## Affiche une suite de messages (E pour passer au suivant), puis appelle `apres`.
func _afficher_messages(messages: Array[String], apres: Callable) -> void:
	_messages = messages.duplicate()
	_apres_messages = apres
	_etat = Etat.MESSAGE
	_sous_menu.visible = false
	_texte.visible = true
	_mettre_a_jour_menu()
	_message_suivant()


func _message_suivant() -> void:
	if _messages.is_empty():
		_apres_messages.call()
		return
	_texte.text = Dialogues.formater(_messages.pop_front())


# --- Menu principal ---------------------------------------------------------

func _ouvrir_menu() -> void:
	_etat = Etat.MENU
	_sous_menu.visible = false
	_texte.visible = true
	_texte.text = "Que fais-tu ?"
	_mettre_a_jour_menu()


func _changer_action(decalage: int) -> void:
	_action = wrapi(_action + decalage, 0, ACTIONS.size())
	_mettre_a_jour_menu()


func _choisir_action() -> void:
	match _action:
		0:
			_frapper()
		1:
			_ouvrir_parler()
		2:
			_utiliser_objet()
		3:
			_demander_a_lumi()


func _frapper() -> void:
	_pv_ennemi = maxi(0, _pv_ennemi - DEGATS_FRAPPE)
	_apaisement = maxi(0, _apaisement - CHUTE_APAISEMENT_FRAPPE)
	_mettre_a_jour_jauges()
	var messages: Array[String] = ["Tu frappes %s. (-%d PV)" % [_ennemi["nom"], DEGATS_FRAPPE]]
	if _pv_ennemi == 0:
		messages.append(_ennemi["texte_vaincu"])
		_afficher_messages(messages, _terminer.bind("vaincu"))
	else:
		_afficher_messages(messages, _tour_ennemi)


func _utiliser_objet() -> void:
	if not GameState.retirer_objet("potion"):
		# Pas d'objet : le tour n'est pas perdu.
		_afficher_messages(["Tu n'as rien à utiliser."], _ouvrir_menu)
		return
	GameState.soigner(SOIN_POTION)
	_mettre_a_jour_pv_joueur()
	_afficher_messages(["Tu bois une potion. (+%d PV)" % SOIN_POTION], _tour_ennemi)


func _demander_a_lumi() -> void:
	var messages: Array[String] = [
		"Lumi observe %s..." % _ennemi["nom"],
		_ennemi.get("indice_lumi", "Lumi ne sait pas quoi te dire."),
	]
	_afficher_messages(messages, _tour_ennemi)


# --- Parler -----------------------------------------------------------------

func _ouvrir_parler() -> void:
	_options.clear()
	if _apaisement >= 100:
		_options.append({"texte": "Épargner", "epargner": true})
	for option: Dictionary in _ennemi.get("options_parler", []):
		_options.append(option)

	for enfant in _sous_menu.get_children():
		_sous_menu.remove_child(enfant)
		enfant.queue_free()
	for i in _options.size():
		_sous_menu.add_child(Label.new())

	_etat = Etat.SOUS_MENU
	_selection = 0
	_texte.visible = false
	_sous_menu.visible = true
	_mettre_a_jour_menu()
	_mettre_a_jour_sous_menu()


func _changer_option(decalage: int) -> void:
	_selection = wrapi(_selection + decalage, 0, _options.size())
	_mettre_a_jour_sous_menu()


func _valider_option() -> void:
	var option := _options[_selection]
	if option.get("epargner", false):
		var fin: Array[String] = [_ennemi["texte_epargne"]]
		_afficher_messages(fin, _terminer.bind("epargne"))
		return

	_apaisement = clampi(_apaisement + int(option.get("apaisement", 0)), 0, 100)
	_mettre_a_jour_jauges()
	var messages: Array[String] = [option.get("reponse", "...")]
	if _apaisement >= 100:
		messages.append("%s ne veut plus se battre." % _ennemi["nom"])
	_afficher_messages(messages, _tour_ennemi)


# --- Tour de l'ennemi et fin ------------------------------------------------

## Prototype : dégâts fixes, en attendant la phase d'esquive.
func _tour_ennemi() -> void:
	var degats := int(_ennemi["attaque"])
	GameState.pv = maxi(0, GameState.pv - degats)
	_mettre_a_jour_pv_joueur()
	var messages: Array[String] = ["%s attaque ! (-%d PV)" % [_ennemi["nom"], degats]]
	if GameState.pv == 0:
		messages.append("Tu t'effondres...")
		_afficher_messages(messages, _defaite)
	else:
		_afficher_messages(messages, _ouvrir_menu)


func _terminer(issue: String) -> void:
	GameState.combats[_ennemi_id] = issue
	var boss_id := _ennemi_id if _ennemi.get("boss", false) else ""
	GameState.terminer_combat(issue == "epargne", boss_id)
	_fermer(issue)


func _defaite() -> void:
	Carnet.defaite()
	_fermer("defaite")
	if not SaveManager.charger(EMPLACEMENT_DEFAITE):
		# Pas de sauvegarde : on remet simplement les PV au maximum.
		GameState.restaurer_pv()


func _fermer(issue: String) -> void:
	_etat = Etat.INACTIF
	_racine.visible = false
	_figer_voyageur(false)
	combat_termine.emit(issue)


func _figer_voyageur(fige: bool) -> void:
	var carte := get_tree().current_scene as Carte
	if carte != null and carte.voyageur != null:
		carte.voyageur.peut_bouger = not fige


# --- Affichage --------------------------------------------------------------

func _mettre_a_jour_jauges() -> void:
	_jauge_pv.size.x = LARGEUR_JAUGE * float(_pv_ennemi) / _pv_ennemi_max
	_jauge_apaisement.size.x = LARGEUR_JAUGE * _apaisement / 100.0


func _mettre_a_jour_pv_joueur() -> void:
	_pv_joueur.text = "Voyageur n°%d   PV %d/%d" % [Carnet.get_numero(), GameState.pv, GameState.pv_max]


func _mettre_a_jour_menu() -> void:
	var etiquettes := _menu.get_children()
	for i in etiquettes.size():
		var choisie := _etat == Etat.MENU and i == _action
		_colorer(etiquettes[i] as Label, ("> " if choisie else "  ") + ACTIONS[i], choisie)


func _mettre_a_jour_sous_menu() -> void:
	var etiquettes := _sous_menu.get_children()
	for i in etiquettes.size():
		var choisie := i == _selection
		_colorer(etiquettes[i] as Label, ("> " if choisie else "  ") + str(_options[i]["texte"]), choisie)


func _colorer(etiquette: Label, texte: String, choisie: bool) -> void:
	etiquette.text = texte
	etiquette.add_theme_color_override("font_color", COULEUR_SELECTION if choisie else COULEUR_TEXTE)


# --- Construction -----------------------------------------------------------

func _charger_ennemis() -> void:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(FICHIER_ENNEMIS)) != OK:
		push_error("Combat : %s, ligne %d : %s" % [FICHIER_ENNEMIS, json.get_error_line(), json.get_error_message()])
		return
	if typeof(json.data) == TYPE_DICTIONARY:
		_ennemis = json.data


func _construire_interface() -> void:
	_racine = Control.new()
	_racine.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_racine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_racine.theme = ThemePixel.creer()
	add_child(_racine)

	var fond := ColorRect.new()
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fond.color = COULEUR_FOND
	fond.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_racine.add_child(fond)

	_nom = _creer_label(Vector2(8, 6))
	_creer_label(Vector2(8, 18)).text = "PV"
	_jauge_pv = _creer_jauge(Vector2(44, 21), COULEUR_PV)
	_creer_label(Vector2(8, 28)).text = "Calme"
	_jauge_apaisement = _creer_jauge(Vector2(44, 31), COULEUR_APAISEMENT)

	_silhouette = ColorRect.new()
	_silhouette.position = Vector2(148, 44)
	_silhouette.size = Vector2(24, 32)
	_racine.add_child(_silhouette)

	var style := StyleBoxFlat.new()
	style.bg_color = COULEUR_FOND
	style.border_color = COULEUR_CADRE
	style.set_border_width_all(1)

	var cadre := Panel.new()
	cadre.position = Vector2(8, 96)
	cadre.size = Vector2(304, 46)
	cadre.add_theme_stylebox_override("panel", style)
	_racine.add_child(cadre)

	_texte = Label.new()
	_texte.position = Vector2(6, 4)
	_texte.size = Vector2(292, 38)
	_texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	cadre.add_child(_texte)

	_sous_menu = VBoxContainer.new()
	_sous_menu.position = Vector2(6, 3)
	_sous_menu.add_theme_constant_override("separation", 0)
	cadre.add_child(_sous_menu)

	_pv_joueur = _creer_label(Vector2(8, 148))

	_menu = HBoxContainer.new()
	_menu.position = Vector2(8, 162)
	_menu.add_theme_constant_override("separation", 20)
	_racine.add_child(_menu)
	for i in ACTIONS.size():
		_menu.add_child(Label.new())


func _creer_label(position_label: Vector2) -> Label:
	var etiquette := Label.new()
	etiquette.position = position_label
	_racine.add_child(etiquette)
	return etiquette


func _creer_jauge(position_jauge: Vector2, couleur: Color) -> ColorRect:
	var vide := ColorRect.new()
	vide.position = position_jauge
	vide.size = Vector2(LARGEUR_JAUGE, 4)
	vide.color = COULEUR_JAUGE_VIDE
	_racine.add_child(vide)

	var remplie := ColorRect.new()
	remplie.size = Vector2(LARGEUR_JAUGE, 4)
	remplie.color = couleur
	vide.add_child(remplie)
	return remplie
