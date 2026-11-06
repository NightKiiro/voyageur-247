extends Carte
## Salle de test du prototype d'exploration (phase 2). Sera remplacée par de vraies cartes.

const COULEUR_PIERRE := Color("#6f7a86")
const COULEUR_LUMI := Color("#f2d16b")


func _construire() -> void:
	arrivees = {
		"depart": Vector2(60, 60),
		"depuis_jardin": Vector2(296, 90),
	}
	_creer_sol()

	# Murs extérieurs, avec un passage à droite vers le jardin
	_creer_mur(Rect2(0, 0, TAILLE.x, EPAISSEUR_MUR))
	_creer_mur(Rect2(0, TAILLE.y - EPAISSEUR_MUR, TAILLE.x, EPAISSEUR_MUR))
	_creer_mur(Rect2(0, 0, EPAISSEUR_MUR, TAILLE.y))
	_creer_mur(Rect2(TAILLE.x - EPAISSEUR_MUR, 0, EPAISSEUR_MUR, 80))
	_creer_mur(Rect2(TAILLE.x - EPAISSEUR_MUR, 100, EPAISSEUR_MUR, 80))
	_creer_sortie(Rect2(TAILLE.x - 6, 80, 6, 20), "jardin_test", "depuis_salle")

	# Obstacles pour tester les collisions
	_creer_mur(Rect2(140, 70, 40, 24))
	_creer_mur(Rect2(60, 120, 16, 16))

	# Objets et personnages
	_creer_objet(Rect2(250, 40, 12, 10), COULEUR_PANNEAU, "panneau_brindille")
	_creer_objet(Rect2(230, 130, 14, 10), COULEUR_PIERRE, "pierre_mousse")
	_creer_objet(Rect2(104, 36, 8, 8), COULEUR_LUMI, "lumi_salut")
	_creer_objet(Rect2(110, 142, 12, 8), COULEUR_HALTE, "halte")
