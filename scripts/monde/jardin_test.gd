extends Carte
## Deuxième carte de test, reliée à la salle de test, pour essayer les transitions.

const COULEUR_SOL_JARDIN := Color("#4b5e3c")
const COULEUR_HAIE := Color("#5f7d4a")


func _construire() -> void:
	arrivees = {
		"depart": Vector2(40, 90),
		"depuis_salle": Vector2(24, 90),
	}
	_creer_sol(COULEUR_SOL_JARDIN)

	# Haies extérieures, avec un passage à gauche vers la salle
	_creer_mur(Rect2(0, 0, TAILLE.x, EPAISSEUR_MUR), COULEUR_HAIE)
	_creer_mur(Rect2(0, TAILLE.y - EPAISSEUR_MUR, TAILLE.x, EPAISSEUR_MUR), COULEUR_HAIE)
	_creer_mur(Rect2(TAILLE.x - EPAISSEUR_MUR, 0, EPAISSEUR_MUR, TAILLE.y), COULEUR_HAIE)
	_creer_mur(Rect2(0, 0, EPAISSEUR_MUR, 80), COULEUR_HAIE)
	_creer_mur(Rect2(0, 100, EPAISSEUR_MUR, 80), COULEUR_HAIE)
	_creer_sortie(Rect2(0, 80, 6, 20), "salle_test", "depuis_jardin")

	# Haies intérieures
	_creer_mur(Rect2(100, 40, 60, 10), COULEUR_HAIE)
	_creer_mur(Rect2(200, 110, 10, 50), COULEUR_HAIE)

	# Objets
	_creer_objet(Rect2(150, 120, 12, 10), COULEUR_PANNEAU, "panneau_jardin")
	_creer_objet(Rect2(60, 140, 12, 8), COULEUR_HALTE, "halte")
