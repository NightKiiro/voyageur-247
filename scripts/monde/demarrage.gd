extends Node
## Scène de démarrage : continue la partie sauvegardée, ou en commence une nouvelle.
## Sera remplacée par l'écran titre.

## Emplacement continué au lancement, en attendant le menu des 3 emplacements.
const EMPLACEMENT_PROTOTYPE := 1


func _ready() -> void:
	_demarrer.call_deferred()


func _demarrer() -> void:
	# Si le chargement réussit, Monde ouvre la carte sauvegardée tout seul.
	if SaveManager.emplacement_existe(EMPLACEMENT_PROTOTYPE) and SaveManager.charger(EMPLACEMENT_PROTOTYPE):
		return
	SaveManager.nouvelle_partie()
	Monde.entrer(Monde.CARTE_DEPART, "depart")
