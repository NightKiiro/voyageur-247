class_name Interactable
extends Area2D
## Zone avec laquelle le Voyageur peut interagir : PNJ, objet, halte...
## Le Voyageur la détecte quand elle se trouve juste devant lui.

## Émis quand le joueur interagit. Les PNJ et les objets peuvent s'y abonner pour réagir.
signal interagi(voyageur: Voyageur)

## Dialogue lancé automatiquement à l'interaction (voir data/dialogues/). Vide : aucun.
@export var dialogue_id := ""


func _init() -> void:
	# La zone n'a pas besoin de détecter quoi que ce soit : c'est le Voyageur qui la détecte.
	monitoring = false
	monitorable = true


func interagir(voyageur: Voyageur) -> void:
	if dialogue_id != "":
		BoiteDialogue.demarrer(dialogue_id, voyageur)
	interagi.emit(voyageur)
