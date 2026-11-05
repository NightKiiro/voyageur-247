extends Node
## Charge les dialogues (data/dialogues/*.json) et choisit la variante à jouer selon des conditions.
## Autoload : Dialogues. Voir docs/GDD.md, section 6.

const DOSSIER := "res://data/dialogues"
const NIVEAUX_MANIPULATION := ["faible", "moyen", "fort"]

## Identifiant du choix que le joueur vient de refaire autrement (vide sinon).
## Mis à jour par BoiteDialogue juste après chaque choix.
var choix_refait_recent := ""

var _dialogues: Dictionary = {}


func _ready() -> void:
	_charger_tout()


## Renvoie la première variante dont la condition est remplie, ou {} si aucune.
func obtenir(dialogue_id: String) -> Dictionary:
	if not _dialogues.has(dialogue_id):
		push_error("Dialogues : dialogue inconnu '%s'" % dialogue_id)
		return {}
	for variante: Dictionary in _dialogues[dialogue_id].get("variantes", []):
		if condition_remplie(variante.get("condition", {})):
			return variante
	push_warning("Dialogues : aucune variante possible pour '%s'" % dialogue_id)
	return {}


## Toutes les conditions du dictionnaire doivent être vraies (un « ET »).
func condition_remplie(condition: Dictionary) -> bool:
	for cle: String in condition:
		if not _verifier(cle, condition[cle]):
			return false
	return true


## Remplace les variables d'un texte, par exemple {numero}.
func formater(texte: String) -> String:
	return texte.format({"numero": Carnet.get_numero()})


func _verifier(cle: String, valeur: Variant) -> bool:
	match cle:
		"souvenir_min":
			return Carnet.compter_souvenirs(valeur["type"]) >= int(valeur["nombre"])
		"choix_refait":
			return choix_refait_recent == valeur
		"choix_fait":
			return GameState.choix.has(valeur)
		"choix_pas_fait":
			return not GameState.choix.has(valeur)
		"choix_partie":
			return GameState.choix.get(valeur["choix_id"], "") == valeur["option"]
		"manipulation_min":
			return NIVEAUX_MANIPULATION.find(Carnet.get_niveau_manipulation()) >= NIVEAUX_MANIPULATION.find(valeur)
		"numero_min":
			return Carnet.get_numero() >= int(valeur)
		"lien_min":
			return int(GameState.liens.get(valeur["perso"], 0)) >= int(valeur["valeur"])
		"palier_violence":
			return GameState.get_palier_violence() == valeur
		"boss_rencontre":
			return Carnet.a_rencontre_boss(valeur)
	push_error("Dialogues : condition inconnue '%s'" % cle)
	return false


func _charger_tout() -> void:
	var dossier := DirAccess.open(DOSSIER)
	if dossier == null:
		push_error("Dialogues : dossier introuvable (%s)" % DOSSIER)
		return
	for fichier in dossier.get_files():
		if not fichier.ends_with(".json"):
			continue
		var json := JSON.new()
		if json.parse(FileAccess.get_file_as_string(DOSSIER.path_join(fichier))) != OK:
			push_error("Dialogues : %s, ligne %d : %s" % [fichier, json.get_error_line(), json.get_error_message()])
			continue
		if typeof(json.data) != TYPE_DICTIONARY:
			push_error("Dialogues : %s doit contenir un objet JSON" % fichier)
			continue
		for dialogue_id: String in json.data:
			if _dialogues.has(dialogue_id):
				push_warning("Dialogues : '%s' défini plusieurs fois (%s)" % [dialogue_id, fichier])
			_dialogues[dialogue_id] = json.data[dialogue_id]
