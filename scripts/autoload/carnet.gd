extends Node
## Mémoire persistante de Lumi : le Carnet.
## Survit aux rechargements et aux nouvelles parties. Voir docs/MEMORY_SYSTEM.md.

signal souvenir_enregistre(type: String, donnees: Dictionary)

const VERSION := 1
const CHEMIN := "user://carnet.json"
const CHEMIN_TMP := "user://carnet.json.tmp"
const CHEMIN_BAK := "user://carnet.json.bak"
const DOSSIER_SAUVEGARDES := "user://saves"

const NUMERO_INITIAL := 247
const MAX_SOUVENIRS := 500
const JOURS_LONGUE_ABSENCE := 3
const SECONDES_PAR_JOUR := 86400
const SEL_EMPREINTE := "clairmousse-lumi-247"

const SEUIL_MOYEN := 5
const SEUIL_FORT := 15
const POINTS_MANIPULATION := {
	"RECHARGEMENT": 1,
	"RECHARGEMENT_APRES_DEFAITE": 1,
	"CHOIX_REFAIT": 2,
	"FUITE_EN_COMBAT": 2,
	"RETOUR_ANCIEN_VOYAGEUR": 1,
}
const POINTS_NOUVELLE_PARTIE := 3
const POINTS_NOUVELLE_PARTIE_APRES_FIN := 1

const CHAMPS_ENTIERS := [
	"version", "voyageur_numero", "premier_lancement", "dernier_lancement",
	"nb_lancements", "manipulation", "progression_actuelle",
]

var data: Dictionary = {}


# --- Cycle de vie -----------------------------------------------------------

func _ready() -> void:
	# On gère nous-mêmes la fermeture, pour avoir le temps d'écrire le Carnet.
	get_tree().set_auto_accept_quit(false)

	_charger()
	_verifier_session_precedente()
	_verifier_absence()

	data["nb_lancements"] += 1
	data["dernier_lancement"] = _maintenant()
	var session: Dictionary = data["session"]
	session["ouverte"] = true
	session["en_combat"] = false
	session["combat_id"] = ""

	enregistrer("LANCEMENT")
	_mettre_a_jour_titre()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quitter()


## Fermeture propre du jeu (menu « Quitter » ou croix de la fenêtre).
func quitter() -> void:
	var session: Dictionary = data["session"]
	if session["en_combat"]:
		_ajouter_souvenir("FUITE_EN_COMBAT", {"combat_id": session["combat_id"]})
	session["ouverte"] = false
	session["en_combat"] = false
	session["combat_id"] = ""
	_ecrire()
	get_tree().quit()


# --- API publique : enregistrement --------------------------------------------

## Enregistre un souvenir et écrit immédiatement le Carnet.
func enregistrer(type: String, donnees: Dictionary = {}) -> void:
	_ajouter_souvenir(type, donnees)
	_ecrire()


## Lance une nouvelle partie : le numéro augmente, sauf pour la toute première.
func nouvelle_partie() -> void:
	var points := 0
	if data["partie_commencee"]:
		if _fin_vue_avec_numero(get_numero()):
			points = POINTS_NOUVELLE_PARTIE_APRES_FIN
		else:
			points = POINTS_NOUVELLE_PARTIE
		data["voyageur_numero"] = get_numero() + 1

	data["partie_commencee"] = true
	data["progression_actuelle"] = 0
	data["choix_connus"] = {}
	_ajouter_souvenir("NOUVELLE_PARTIE", {"numero": get_numero()}, points)
	_ecrire()
	_mettre_a_jour_titre()


## Met à jour la position du joueur dans la ligne du temps (sans créer de souvenir).
func mettre_a_jour_progression(progression: int) -> void:
	data["progression_actuelle"] = progression
	_ecrire()


## À appeler au chargement d'une sauvegarde. Détecte les retours en arrière.
func verifier_chargement(progression_sauvegarde: int, numero_sauvegarde: int = -1) -> void:
	var actuelle := get_progression()
	if numero_sauvegarde != -1 and numero_sauvegarde != get_numero():
		# Partie d'un ancien Voyageur : les progressions ne sont pas comparables.
		# Le numéro, lui, ne redescend jamais.
		_ajouter_souvenir("RETOUR_ANCIEN_VOYAGEUR", {"numero_sauvegarde": numero_sauvegarde})
	elif progression_sauvegarde < actuelle:
		var apres_defaite: bool = dernier_souvenir().get("type", "") == "DEFAITE"
		_ajouter_souvenir("RECHARGEMENT", {
			"progression": progression_sauvegarde,
			"depuis": actuelle,
		})
		if apres_defaite:
			_ajouter_souvenir("RECHARGEMENT_APRES_DEFAITE")
	data["progression_actuelle"] = progression_sauvegarde
	_ecrire()


## Enregistre un choix majeur. Renvoie true si le joueur a changé d'avis.
## Le Carnet garde toujours le PREMIER choix.
func enregistrer_choix(choix_id: String, option: String) -> bool:
	var choix: Dictionary = data["choix_connus"]
	if not choix.has(choix_id):
		choix[choix_id] = option
		_ecrire()
		return false
	if choix[choix_id] != option:
		enregistrer("CHOIX_REFAIT", {
			"choix_id": choix_id,
			"premier": choix[choix_id],
			"nouveau": option,
		})
		return true
	return false


func debut_combat(combat_id: String) -> void:
	var session: Dictionary = data["session"]
	session["en_combat"] = true
	session["combat_id"] = combat_id
	_ecrire()


func fin_combat() -> void:
	var session: Dictionary = data["session"]
	session["en_combat"] = false
	session["combat_id"] = ""
	_ecrire()


func defaite() -> void:
	var session: Dictionary = data["session"]
	session["en_combat"] = false
	session["combat_id"] = ""
	enregistrer("DEFAITE")


func rencontrer_boss(boss_id: String) -> void:
	var boss: Array = data["boss_rencontres"]
	if not boss.has(boss_id):
		boss.append(boss_id)
		_ecrire()


func enregistrer_fin(fin_id: String) -> void:
	var fins: Array = data["fins_vues"]
	fins.append({"fin": fin_id, "numero": get_numero(), "date": _maintenant()})
	enregistrer("FIN_VUE", {"fin": fin_id})


func decouvrir_chemin(chemin_id: String) -> void:
	var chemins: Array = data["chemins_decouverts"]
	if not chemins.has(chemin_id):
		chemins.append(chemin_id)
		_ecrire()


# --- API publique : requêtes ---------------------------------------------------

func get_numero() -> int:
	return int(data["voyageur_numero"])


func get_manipulation() -> int:
	return int(data["manipulation"])


func get_progression() -> int:
	return int(data["progression_actuelle"])


func get_niveau_manipulation() -> String:
	var score := get_manipulation()
	if score >= SEUIL_FORT:
		return "fort"
	if score >= SEUIL_MOYEN:
		return "moyen"
	return "faible"


func a_souvenir(type: String) -> bool:
	return compter_souvenirs(type) > 0


func compter_souvenirs(type: String) -> int:
	var total := 0
	for souvenir: Dictionary in data["souvenirs"]:
		if souvenir["type"] == type:
			total += 1
	return total


## Dernier souvenir significatif (les lancements et sauvegardes sont ignorés par défaut).
func dernier_souvenir(ignorer: Array = ["LANCEMENT", "SAUVEGARDE"]) -> Dictionary:
	var souvenirs: Array = data["souvenirs"]
	for i in range(souvenirs.size() - 1, -1, -1):
		var souvenir: Dictionary = souvenirs[i]
		if not ignorer.has(souvenir["type"]):
			return souvenir
	return {}


func a_rencontre_boss(boss_id: String) -> bool:
	return (data["boss_rencontres"] as Array).has(boss_id)


func a_vu_fin(fin_id: String) -> bool:
	for fin: Dictionary in data["fins_vues"]:
		if fin["fin"] == fin_id:
			return true
	return false


# --- Chargement -------------------------------------------------------------

func _charger() -> void:
	var contenu: Variant = _lire_json(CHEMIN)
	if contenu == null:
		contenu = _lire_json(CHEMIN_BAK)
		if contenu != null:
			push_warning("Carnet : fichier principal illisible, copie de secours utilisée")

	if contenu == null:
		data = _carnet_vierge()
		var numero_sauvegardes := _numero_max_sauvegardes()
		if numero_sauvegardes > 0:
			# Des sauvegardes existent, mais plus de Carnet : quelqu'un l'a effacé.
			data["voyageur_numero"] = maxi(numero_sauvegardes, NUMERO_INITIAL)
			data["partie_commencee"] = true
			_ajouter_souvenir("CARNET_DISPARU", {"numero_retrouve": numero_sauvegardes})
		return

	var empreinte_valide := _empreinte_valide(contenu)
	data = _migrer(contenu)
	if not empreinte_valide:
		_ajouter_souvenir("CARNET_ALTERE")


func _lire_json(chemin: String) -> Variant:
	if not FileAccess.file_exists(chemin):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(chemin)) != OK:
		return null  # Fichier illisible : cas prévu, géré par l'appelant.
	if typeof(json.data) != TYPE_DICTIONARY:
		return null
	return json.data


func _carnet_vierge() -> Dictionary:
	var maintenant := _maintenant()
	return {
		"version": VERSION,
		"voyageur_numero": NUMERO_INITIAL,
		"partie_commencee": false,
		"premier_lancement": maintenant,
		"dernier_lancement": maintenant,
		"nb_lancements": 0,
		"manipulation": 0,
		"session": {"ouverte": false, "en_combat": false, "combat_id": ""},
		"progression_actuelle": 0,
		"choix_connus": {},
		"boss_rencontres": [],
		"fins_vues": [],
		"chemins_decouverts": [],
		"oubli_fait": false,
		"souvenirs": [],
		"empreinte": "",
	}


## Complète les champs manquants et met à jour les anciennes versions du Carnet.
func _migrer(source: Dictionary) -> Dictionary:
	var resultat := _carnet_vierge()
	for cle: String in source.keys():
		resultat[cle] = source[cle]

	# Futures migrations : if int(resultat["version"]) < 2: ...
	resultat["version"] = VERSION

	# Le JSON lit tous les nombres comme des décimaux : on remet les entiers.
	for cle: String in CHAMPS_ENTIERS:
		resultat[cle] = int(resultat[cle])
	return resultat


func _numero_max_sauvegardes() -> int:
	var dossier := DirAccess.open(DOSSIER_SAUVEGARDES)
	if dossier == null:
		return 0
	var maximum := 0
	for fichier in dossier.get_files():
		if not fichier.ends_with(".json"):
			continue
		var sauvegarde: Variant = _lire_json(DOSSIER_SAUVEGARDES.path_join(fichier))
		if sauvegarde != null:
			maximum = maxi(maximum, int(sauvegarde.get("voyageur_numero", 0)))
	return maximum


# --- Vérifications au lancement ---------------------------------------------

func _verifier_session_precedente() -> void:
	var session: Dictionary = data["session"]
	if not session.get("ouverte", false):
		return
	if session.get("en_combat", false):
		_ajouter_souvenir("FUITE_EN_COMBAT", {"combat_id": session.get("combat_id", "")})
	else:
		_ajouter_souvenir("FERMETURE_BRUTALE")


func _verifier_absence() -> void:
	if int(data["nb_lancements"]) == 0:
		return
	var ecart := _maintenant() - int(data["dernier_lancement"])
	if ecart < 0:
		return  # Horloge modifiée : on ignore.
	var jours := floori(ecart / float(SECONDES_PAR_JOUR))
	if jours >= JOURS_LONGUE_ABSENCE:
		_ajouter_souvenir("LONGUE_ABSENCE", {"jours": jours})


# --- Écriture ---------------------------------------------------------------

func _ajouter_souvenir(type: String, donnees: Dictionary = {}, points: int = -1) -> void:
	if points < 0:
		points = POINTS_MANIPULATION.get(type, 0)
	data["manipulation"] = get_manipulation() + points

	var souvenirs: Array = data["souvenirs"]
	souvenirs.append({"type": type, "date": _maintenant(), "donnees": donnees})
	while souvenirs.size() > MAX_SOUVENIRS:
		souvenirs.pop_front()

	souvenir_enregistre.emit(type, donnees)


## Écriture sûre : fichier temporaire, copie de secours, puis renommage.
func _ecrire() -> void:
	data["empreinte"] = _calculer_empreinte(data)

	var fichier := FileAccess.open(CHEMIN_TMP, FileAccess.WRITE)
	if fichier == null:
		push_error("Carnet : écriture impossible (%s)" % error_string(FileAccess.get_open_error()))
		return
	fichier.store_string(JSON.stringify(data, "\t"))
	fichier.close()

	var chemin := ProjectSettings.globalize_path(CHEMIN)
	if FileAccess.file_exists(CHEMIN):
		DirAccess.copy_absolute(chemin, ProjectSettings.globalize_path(CHEMIN_BAK))
	var erreur := DirAccess.rename_absolute(ProjectSettings.globalize_path(CHEMIN_TMP), chemin)
	if erreur != OK:
		push_error("Carnet : renommage impossible (%s)" % error_string(erreur))


# --- Empreinte --------------------------------------------------------------

## Narration, pas sécurité : le sel est dans le jeu, l'empreinte est recalculable.
func _calculer_empreinte(source: Dictionary) -> String:
	var copie := source.duplicate(true)
	copie.erase("empreinte")
	# Aller-retour JSON pour que l'écriture et la lecture produisent le même texte.
	var normalise: Variant = JSON.parse_string(JSON.stringify(copie))
	return (SEL_EMPREINTE + JSON.stringify(normalise)).sha256_text()


func _empreinte_valide(source: Dictionary) -> bool:
	return source.get("empreinte", "") == _calculer_empreinte(source)


# --- Utilitaires ------------------------------------------------------------

func _fin_vue_avec_numero(numero: int) -> bool:
	for fin: Dictionary in data["fins_vues"]:
		if int(fin["numero"]) == numero:
			return true
	return false


func _maintenant() -> int:
	return int(Time.get_unix_time_from_system())

## Le titre de la fenêtre porte le numéro actuel du Voyageur.
func _mettre_a_jour_titre() -> void:
	get_window().title = "Voyageur n°%d" % get_numero()
