class_name Interactable
extends Area2D
## Zone avec laquelle le Voyageur peut interagir : PNJ, objet, halte...
## Le Voyageur la détecte quand elle se trouve juste devant lui.

## Émis quand le joueur interagit. Les PNJ et les objets s'y abonnent pour réagir.
signal interagi(voyageur: Voyageur)

## Message provisoire affiché dans le terminal, en attendant le système de dialogues.
@export_multiline var texte_test := ""


func _init() -> void:
	# La zone n'a pas besoin de détecter quoi que ce soit : c'est le Voyageur qui la détecte.
	monitoring = false
	monitorable = true


func interagir(voyageur: Voyageur) -> void:
	if texte_test != "":
		print("[Interaction] %s" % texte_test)
	interagi.emit(voyageur)
