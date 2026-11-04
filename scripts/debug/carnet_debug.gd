extends Control
## Scène de test du Carnet (phase 1 de la roadmap). Ne fait pas partie du jeu final.

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
	marge.add_child(colonnes)

	var boutons := VBoxContainer.new()
	boutons.add_theme_constant_override("separation", 1)
	colonnes.add_child(boutons)

	_infos = Label.new()
	_infos.add_theme_font_size_override("font_size", TAILLE_TEXTE)
	_infos.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	colonnes.add_child(_infos)

	_ajouter_bouton(boutons, "Nouvelle partie", Carnet.nouvelle_partie)
	_ajouter_bouton(boutons, "Progresser (+10)", _progresser)
	_ajouter_bouton(boutons, "Recharger (-30)", _recharger)
	_ajouter_bouton(boutons, "Choix A", Carnet.enregistrer_choix.bind("test_choix", "A"))
	_ajouter_bouton(boutons, "Choix B", Carnet.enregistrer_choix.bind("test_choix", "B"))
	_ajouter_bouton(boutons, "Debut combat", Carnet.debut_combat.bind("test_combat"))
	_ajouter_bouton(boutons, "Fin combat", Carnet.fin_combat)
	_ajouter_bouton(boutons, "Defaite", Carnet.defaite)
	_ajouter_bouton(boutons, "Fin vue", Carnet.enregistrer_fin.bind("au_revoir"))
	_ajouter_bouton(boutons, "Quitter", Carnet.quitter)

	Carnet.souvenir_enregistre.connect(_on_souvenir_enregistre)
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
	Carnet.mettre_a_jour_progression(Carnet.get_progression() + 10)


func _recharger() -> void:
	Carnet.verifier_chargement(maxi(0, Carnet.get_progression() - 30))


func _rafraichir() -> void:
	var data: Dictionary = Carnet.data
	var lignes := PackedStringArray()
	lignes.append("Voyageur n°%d" % Carnet.get_numero())
	lignes.append("Manipulation : %d (%s)" % [Carnet.get_manipulation(), Carnet.get_niveau_manipulation()])
	lignes.append("Progression : %d" % Carnet.get_progression())
	lignes.append("Lancements : %d" % int(data["nb_lancements"]))
	lignes.append("Session : %s" % data["session"])
	lignes.append("Choix : %s" % data["choix_connus"])
	lignes.append("Fins : %d" % (data["fins_vues"] as Array).size())
	lignes.append("Derniers souvenirs :")
	var souvenirs: Array = data["souvenirs"]
	for i in range(maxi(0, souvenirs.size() - 6), souvenirs.size()):
		lignes.append("  - %s" % souvenirs[i]["type"])
	_infos.text = "\n".join(lignes)
