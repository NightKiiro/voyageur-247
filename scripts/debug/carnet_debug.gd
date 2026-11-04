extends Control
## Scène de test de la mémoire (Carnet, GameState, SaveManager). Ne fait pas partie du jeu final.

const TAILLE_TEXTE := 16
const MARGE := 12

var _infos: Label


func _ready() -> void:
	# Outil de débogage : on désactive la mise à l'échelle pixel art pour un texte lisible.
	get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED

	var marge := MarginContainer.new()
	marge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for cote in ["left", "top", "right", "bottom"]:
		marge.add_theme_constant_override("margin_" + cote, MARGE)
	add_child(marge)

	var colonnes := HBoxContainer.new()
	colonnes.add_theme_constant_override("separation", MARGE)
	marge.add_child(colonnes)

	var boutons := VBoxContainer.new()
	boutons.add_theme_constant_override("separation", 1)
	colonnes.add_child(boutons)

	_infos = Label.new()
	_infos.add_theme_font_size_override("font_size", TAILLE_TEXTE)
	_infos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_infos.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	colonnes.add_child(_infos)

	_ajouter_bouton(boutons, "Nouvelle partie", SaveManager.nouvelle_partie)
	_ajouter_bouton(boutons, "Progresser (+10)", _progresser)
	_ajouter_bouton(boutons, "Sauver 1", SaveManager.sauvegarder.bind(1))
	_ajouter_bouton(boutons, "Charger 1", SaveManager.charger.bind(1))
	_ajouter_bouton(boutons, "Sauver 2", SaveManager.sauvegarder.bind(2))
	_ajouter_bouton(boutons, "Charger 2", SaveManager.charger.bind(2))
	_ajouter_bouton(boutons, "Choix A", GameState.faire_choix.bind("test_choix", "A"))
	_ajouter_bouton(boutons, "Choix B", GameState.faire_choix.bind("test_choix", "B"))
	_ajouter_bouton(boutons, "Debut combat", Carnet.debut_combat.bind("test_combat"))
	_ajouter_bouton(boutons, "Combat epargne", GameState.terminer_combat.bind(true))
	_ajouter_bouton(boutons, "Combat vaincu (creature)", GameState.terminer_combat.bind(false))
	_ajouter_bouton(boutons, "Combat vaincu (boss)", GameState.terminer_combat.bind(false, "gardien_puits"))
	_ajouter_bouton(boutons, "Defaite", Carnet.defaite)
	_ajouter_bouton(boutons, "Fin vue", Carnet.enregistrer_fin.bind("au_revoir"))
	_ajouter_bouton(boutons, "Quitter", Carnet.quitter)

	Carnet.souvenir_enregistre.connect(_on_souvenir_enregistre)
	_rafraichir()


func _process(_delta: float) -> void:
	# Rafraîchit en continu pour voir le temps de jeu avancer.
	_rafraichir()


func _ajouter_bouton(parent: Container, texte: String, action: Callable) -> void:
	var bouton := Button.new()
	bouton.text = texte
	bouton.add_theme_font_size_override("font_size", TAILLE_TEXTE)
	bouton.pressed.connect(_on_bouton_presse.bind(action))
	parent.add_child(bouton)


func _on_bouton_presse(action: Callable) -> void:
	action.call()
	_rafraichir()


func _on_souvenir_enregistre(type: String, donnees: Dictionary) -> void:
	print("[Carnet] %s %s" % [type, donnees])


func _progresser() -> void:
	for i in 10:
		GameState.avancer_progression()


func _rafraichir() -> void:
	var data: Dictionary = Carnet.data
	var lignes := PackedStringArray()

	lignes.append("=== CARNET ===")
	lignes.append("Voyageur n°%d" % Carnet.get_numero())
	lignes.append("Manipulation : %d (%s)" % [Carnet.get_manipulation(), Carnet.get_niveau_manipulation()])
	lignes.append("Progression (Carnet) : %d" % Carnet.get_progression())
	lignes.append("Lancements : %d   Fins : %d" % [int(data["nb_lancements"]), (data["fins_vues"] as Array).size()])
	lignes.append("Session : %s" % data["session"])
	lignes.append("Choix connus : %s" % data["choix_connus"])

	lignes.append("")
	lignes.append("=== PARTIE ===")
	lignes.append("En partie : %s   Temps : %d s" % [GameState.en_partie, int(GameState.temps_de_jeu)])
	lignes.append("Progression (partie) : %d" % GameState.progression)
	lignes.append("Pacifisme : %s (%s)" % [GameState.pacifisme, GameState.get_etat_pacifisme()])
	lignes.append("Choix : %s" % GameState.choix)

	lignes.append("")
	lignes.append("=== SAUVEGARDES ===")
	for emplacement in range(1, SaveManager.NB_EMPLACEMENTS + 1):
		var infos := SaveManager.infos_emplacement(emplacement)
		if infos.is_empty():
			lignes.append("Emplacement %d : vide" % emplacement)
		else:
			lignes.append("Emplacement %d : Voyageur n°%d, %d s" % [
				emplacement, infos["voyageur_numero"], infos["temps_de_jeu"]])

	lignes.append("")
	lignes.append("Derniers souvenirs :")
	var souvenirs: Array = data["souvenirs"]
	for i in range(maxi(0, souvenirs.size() - 6), souvenirs.size()):
		lignes.append("  - %s" % souvenirs[i]["type"])
	_infos.text = "\n".join(lignes)
