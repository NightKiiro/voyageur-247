extends Node
## Sauvegardes des parties (3 emplacements). Voir docs/MEMORY_SYSTEM.md, section 4.2.
## Les sauvegardes peuvent être rechargées ; le Carnet, jamais.

signal partie_sauvegardee(emplacement: int)
signal partie_chargee(emplacement: int)

const VERSION := 1
const NB_EMPLACEMENTS := 3
const DOSSIER := "user://saves"


func nouvelle_partie() -> void:
	Carnet.nouvelle_partie()
	GameState.reinitialiser()
	GameState.en_partie = true


func sauvegarder(emplacement: int) -> bool:
	if not _emplacement_valide(emplacement):
		return false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DOSSIER))

	var donnees := GameState.vers_dictionnaire()
	donnees["version"] = VERSION
	donnees["voyageur_numero"] = Carnet.get_numero()
	donnees["date"] = int(Time.get_unix_time_from_system())

	if not _ecrire_json(_chemin(emplacement), donnees):
		return false
	Carnet.enregistrer("SAUVEGARDE", {"emplacement": emplacement, "progression": GameState.progression})
	partie_sauvegardee.emit(emplacement)
	return true


func charger(emplacement: int) -> bool:
	var donnees := _lire(emplacement)
	if donnees.is_empty():
		return false
	GameState.depuis_dictionnaire(donnees)
	# Le Carnet décide s'il s'agit d'un retour en arrière (et ne se recharge jamais lui-même).
	Carnet.verifier_chargement(GameState.progression, int(donnees.get("voyageur_numero", Carnet.get_numero())))
	GameState.en_partie = true
	partie_chargee.emit(emplacement)
	return true


func emplacement_existe(emplacement: int) -> bool:
	return _emplacement_valide(emplacement) and FileAccess.file_exists(_chemin(emplacement))


## Résumé d'un emplacement pour le menu (vide si l'emplacement est libre).
func infos_emplacement(emplacement: int) -> Dictionary:
	var donnees := _lire(emplacement)
	if donnees.is_empty():
		return {}
	return {
		"voyageur_numero": int(donnees.get("voyageur_numero", 0)),
		"scene": str(donnees.get("scene", "")),
		"temps_de_jeu": int(donnees.get("temps_de_jeu", 0)),
		"date": int(donnees.get("date", 0)),
	}


func _lire(emplacement: int) -> Dictionary:
	if not emplacement_existe(emplacement):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(_chemin(emplacement))) != OK \
			or typeof(json.data) != TYPE_DICTIONARY:
		push_warning("SaveManager : emplacement %d illisible" % emplacement)
		return {}
	return json.data


## Écriture sûre : fichier temporaire puis renommage.
func _ecrire_json(chemin: String, donnees: Dictionary) -> bool:
	var chemin_tmp := chemin + ".tmp"
	var fichier := FileAccess.open(chemin_tmp, FileAccess.WRITE)
	if fichier == null:
		push_error("SaveManager : écriture impossible (%s)" % error_string(FileAccess.get_open_error()))
		return false
	fichier.store_string(JSON.stringify(donnees, "\t"))
	fichier.close()

	var erreur := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(chemin_tmp), ProjectSettings.globalize_path(chemin))
	if erreur != OK:
		push_error("SaveManager : renommage impossible (%s)" % error_string(erreur))
		return false
	return true


func _chemin(emplacement: int) -> String:
	return DOSSIER.path_join("slot_%d.json" % emplacement)


func _emplacement_valide(emplacement: int) -> bool:
	return emplacement >= 1 and emplacement <= NB_EMPLACEMENTS
