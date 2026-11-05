class_name ThemePixel
extends RefCounted
## Thème commun de l'interface du jeu : police pixel rendue nette.

const CHEMIN_POLICE := "res://assets/polices/PixelOperator8.ttf"
const TAILLE_POLICE := 8


static func creer() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = TAILLE_POLICE
	if ResourceLoader.exists(CHEMIN_POLICE):
		var police: FontFile = load(CHEMIN_POLICE)
		# Rendu net pour une police pixel : pas de lissage.
		police.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		police.hinting = TextServer.HINTING_NONE
		police.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		theme.default_font = police
	else:
		push_warning("ThemePixel : police introuvable (%s), police par défaut utilisée" % CHEMIN_POLICE)
	return theme
