extends Node
## État de la partie en cours. Sauvegardé et rechargé par SaveManager.
## Voir docs/STRUCTURE.md (les axes) et docs/MEMORY_SYSTEM.md (format des sauvegardes).

signal etat_modifie

const LIEN_MAX := {"lumi": 10, "ortie": 5, "cardon": 5, "mirette": 5}
## Boss qui comptent pour la route Violente. À compléter avec les boss des actes 2 et 3.
const BOSS_PRINCIPAUX := ["gardien_puits"]
const SEUIL_VIOLENT := 0.7

var en_partie := false
var progression := 0
var temps_de_jeu := 0.0
var scene := ""
var position_joueur := Vector2.ZERO
var acte := 0
var lanternes := 0
var pacifisme: Dictionary = {}
var liens: Dictionary = {}
var verite: Dictionary = {}
var choix: Dictionary = {}
var inventaire: Array[String] = []


func _ready() -> void:
	reinitialiser()


func _process(delta: float) -> void:
	if en_partie:
		temps_de_jeu += delta


## Remet la partie à zéro (nouvelle partie).
func reinitialiser() -> void:
	progression = 0
	temps_de_jeu = 0.0
	scene = ""
	position_joueur = Vector2.ZERO
	acte = 0
	lanternes = 0
	pacifisme = {"epargnes": 0, "vaincus": 0, "boss_vaincus": []}
	liens = {"lumi": 0, "ortie": 0, "cardon": 0, "mirette": 0}
	verite = {"indices": [], "question_phare": false, "promesse": false}
	choix = {}
	inventaire = []
	etat_modifie.emit()


# --- Progression ------------------------------------------------------------

## À appeler à chaque événement significatif (scène, dialogue, combat, objet).
func avancer_progression() -> void:
	progression += 1
	Carnet.mettre_a_jour_progression(progression)
	etat_modifie.emit()


# --- Choix ------------------------------------------------------------------

## Enregistre un choix majeur. Renvoie true si le joueur a changé d'avis (choix refait).
func faire_choix(choix_id: String, option: String) -> bool:
	choix[choix_id] = option
	var refait: bool = Carnet.enregistrer_choix(choix_id, option)
	avancer_progression()
	return refait


# --- Combats ----------------------------------------------------------------

func terminer_combat(epargne: bool, boss_id: String = "") -> void:
	if epargne:
		pacifisme["epargnes"] += 1
	else:
		pacifisme["vaincus"] += 1
		if boss_id != "":
			(pacifisme["boss_vaincus"] as Array).append(boss_id)
	Carnet.fin_combat()
	avancer_progression()


## "pacifiste", "mixte" ou "violent" (voir docs/STRUCTURE.md, section 2.1).
func get_etat_pacifisme() -> String:
	var vaincus: int = pacifisme["vaincus"]
	var total: int = vaincus + int(pacifisme["epargnes"])
	if vaincus == 0:
		return "pacifiste"
	var boss_vaincus: Array = pacifisme["boss_vaincus"]
	var tous_les_boss := BOSS_PRINCIPAUX.all(func(boss: String) -> bool: return boss_vaincus.has(boss))
	if tous_les_boss and float(vaincus) / total >= SEUIL_VIOLENT:
		return "violent"
	return "mixte"


# --- Liens, vérité, inventaire ----------------------------------------------

func modifier_lien(personnage: String, variation: int) -> void:
	if not liens.has(personnage):
		push_error("GameState : personnage inconnu '%s'" % personnage)
		return
	liens[personnage] = clampi(int(liens[personnage]) + variation, 0, LIEN_MAX[personnage])
	etat_modifie.emit()


func ajouter_indice(numero: int) -> void:
	var indices: Array = verite["indices"]
	if not indices.has(numero):
		indices.append(numero)
		avancer_progression()


func ajouter_objet(objet_id: String) -> void:
	inventaire.append(objet_id)
	avancer_progression()


func retirer_objet(objet_id: String) -> bool:
	var index := inventaire.find(objet_id)
	if index == -1:
		return false
	inventaire.remove_at(index)
	etat_modifie.emit()
	return true


# --- Conversion pour les sauvegardes ----------------------------------------

func vers_dictionnaire() -> Dictionary:
	return {
		"progression": progression,
		"temps_de_jeu": int(temps_de_jeu),
		"scene": scene,
		"position": {"x": position_joueur.x, "y": position_joueur.y},
		"acte": acte,
		"lanternes": lanternes,
		"pacifisme": pacifisme.duplicate(true),
		"liens": liens.duplicate(true),
		"verite": verite.duplicate(true),
		"choix": choix.duplicate(),
		"inventaire": inventaire.duplicate(),
	}


## Restaure l'état depuis une sauvegarde. Les champs absents gardent leur valeur par défaut.
func depuis_dictionnaire(donnees: Dictionary) -> void:
	reinitialiser()
	progression = int(donnees.get("progression", 0))
	temps_de_jeu = float(donnees.get("temps_de_jeu", 0))
	scene = str(donnees.get("scene", ""))
	acte = int(donnees.get("acte", 0))
	lanternes = int(donnees.get("lanternes", 0))

	var position: Dictionary = donnees.get("position", {})
	position_joueur = Vector2(float(position.get("x", 0)), float(position.get("y", 0)))

	# Le JSON lit les nombres comme des décimaux : on remet les entiers.
	var p: Dictionary = donnees.get("pacifisme", {})
	pacifisme["epargnes"] = int(p.get("epargnes", 0))
	pacifisme["vaincus"] = int(p.get("vaincus", 0))
	pacifisme["boss_vaincus"] = (p.get("boss_vaincus", []) as Array).duplicate()

	var l: Dictionary = donnees.get("liens", {})
	for personnage: String in liens:
		liens[personnage] = int(l.get(personnage, 0))

	var v: Dictionary = donnees.get("verite", {})
	var indices: Array = []
	for indice in v.get("indices", []):
		indices.append(int(indice))
	verite["indices"] = indices
	verite["question_phare"] = bool(v.get("question_phare", false))
	verite["promesse"] = bool(v.get("promesse", false))

	choix = (donnees.get("choix", {}) as Dictionary).duplicate()
	inventaire.assign(donnees.get("inventaire", []))
	etat_modifie.emit()
