class_name Esquive
extends Panel
## Phase d'esquive (voir docs/GDD.md, section 5) : le joueur guide l'Étincelle de Lumi
## pour éviter les projectiles de l'ennemi pendant quelques secondes.

## Émis à chaque fois que l'Étincelle est touchée.
signal touchee(degats: int)
## Émis quand le temps de l'esquive est écoulé.
signal terminee

const TAILLE := Vector2(100, 60)
const TAILLE_ETINCELLE := Vector2(4, 4)
## Seul le centre de l'Étincelle compte pour les collisions : les frôlements ne touchent pas.
const MARGE_COLLISION := 1.0
const TAILLE_PROJECTILE := Vector2(4, 4)
const VITESSE_ETINCELLE := 60.0
const DUREE_INVINCIBILITE := 0.75
const RYTHME_CLIGNOTEMENT := 0.1
## Délai avant le premier projectile, le temps de voir le cadre.
const REPIT_INITIAL := 0.3

const COULEUR_FOND := Color("#14181a")
const COULEUR_CADRE := Color("#f4f4f4")
const COULEUR_ETINCELLE := Color("#f2d16b")
const COULEUR_PROJECTILE := Color("#f4f4f4")

## Réglages de chaque motif : intervalle entre deux tirs (secondes) et vitesse (pixels/seconde).
const MOTIFS := {
	"pluie": {"intervalle": 0.25, "vitesse": 50.0},
	"balayage": {"intervalle": 0.35, "vitesse": 60.0},
	"rafale": {"intervalle": 0.5, "vitesse": 70.0},
}

var _actif := false
var _motif := ""
var _degats := 0
var _temps_restant := 0.0
var _prochain_tir := 0.0
var _invincibilite := 0.0
var _cote_balayage := 1
var _position_etincelle := Vector2.ZERO
var _etincelle: ColorRect
## Chaque projectile : {"noeud": ColorRect, "position": Vector2, "vitesse": Vector2}
var _projectiles: Array[Dictionary] = []


func _ready() -> void:
	size = TAILLE
	clip_contents = true  # Les projectiles hors du cadre ne sont pas dessinés.

	var style := StyleBoxFlat.new()
	style.bg_color = COULEUR_FOND
	style.border_color = COULEUR_CADRE
	style.set_border_width_all(1)
	add_theme_stylebox_override("panel", style)

	_etincelle = ColorRect.new()
	_etincelle.size = TAILLE_ETINCELLE
	_etincelle.color = COULEUR_ETINCELLE
	add_child(_etincelle)
	visible = false


func demarrer(motif: String, degats: int, duree: float) -> void:
	_vider_projectiles()
	if not MOTIFS.has(motif):
		push_warning("Esquive : motif inconnu '%s', pluie utilisée" % motif)
		motif = "pluie"
	_motif = motif
	_degats = degats
	_temps_restant = duree
	_prochain_tir = REPIT_INITIAL
	_invincibilite = 0.0
	_position_etincelle = ((TAILLE - TAILLE_ETINCELLE) / 2).round()
	_etincelle.position = _position_etincelle
	_etincelle.visible = true
	visible = true
	_actif = true


func arreter() -> void:
	_actif = false
	visible = false
	_vider_projectiles()


func _physics_process(delta: float) -> void:
	if not _actif:
		return
	_deplacer_etincelle(delta)
	_tirer(delta)
	_deplacer_projectiles(delta)
	_verifier_collisions(delta)
	if not _actif:
		return  # Le combat a pu arrêter l'esquive (défaite) pendant la collision.

	_temps_restant -= delta
	if _temps_restant <= 0.0:
		arreter()
		terminee.emit()


# --- Étincelle --------------------------------------------------------------

func _deplacer_etincelle(delta: float) -> void:
	var brute := Input.get_vector("deplacer_gauche", "deplacer_droite", "deplacer_haut", "deplacer_bas")
	if brute == Vector2.ZERO:
		return
	# Même arrondi aux 8 directions que le Voyageur : mouvement net au stick.
	var direction := Vector2.from_angle(snappedf(brute.angle(), PI / 4.0)).round()
	_position_etincelle += direction * VITESSE_ETINCELLE * delta
	_position_etincelle = _position_etincelle.clamp(Vector2.ONE, TAILLE - TAILLE_ETINCELLE - Vector2.ONE)
	_etincelle.position = _position_etincelle


# --- Projectiles ------------------------------------------------------------

func _tirer(delta: float) -> void:
	_prochain_tir -= delta
	if _prochain_tir > 0.0:
		return
	var reglages: Dictionary = MOTIFS[_motif]
	var vitesse: float = reglages["vitesse"]
	_prochain_tir = reglages["intervalle"]

	match _motif:
		"pluie":
			var x := randf_range(0, TAILLE.x - TAILLE_PROJECTILE.x)
			_ajouter_projectile(Vector2(x, -TAILLE_PROJECTILE.y), Vector2(0, vitesse))
		"balayage":
			var y := randf_range(0, TAILLE.y - TAILLE_PROJECTILE.y)
			if _cote_balayage > 0:
				_ajouter_projectile(Vector2(-TAILLE_PROJECTILE.x, y), Vector2(vitesse, 0))
			else:
				_ajouter_projectile(Vector2(TAILLE.x, y), Vector2(-vitesse, 0))
			_cote_balayage *= -1
		"rafale":
			var depart := Vector2((TAILLE.x - TAILLE_PROJECTILE.x) / 2, -TAILLE_PROJECTILE.y)
			var direction := (_position_etincelle - depart).normalized()
			_ajouter_projectile(depart, direction * vitesse)


func _ajouter_projectile(depart: Vector2, vitesse: Vector2) -> void:
	var noeud := ColorRect.new()
	noeud.size = TAILLE_PROJECTILE
	noeud.color = COULEUR_PROJECTILE
	noeud.position = depart
	add_child(noeud)
	_projectiles.append({"noeud": noeud, "position": depart, "vitesse": vitesse})


func _deplacer_projectiles(delta: float) -> void:
	var limites := Rect2(-TAILLE_PROJECTILE * 2, TAILLE + TAILLE_PROJECTILE * 4)
	# Parcours à l'envers : on peut retirer des éléments sans sauter le suivant.
	for i in range(_projectiles.size() - 1, -1, -1):
		var projectile := _projectiles[i]
		projectile["position"] += projectile["vitesse"] * delta
		var noeud: ColorRect = projectile["noeud"]
		noeud.position = projectile["position"]
		if not limites.has_point(projectile["position"]):
			noeud.queue_free()
			_projectiles.remove_at(i)


func _vider_projectiles() -> void:
	for projectile in _projectiles:
		(projectile["noeud"] as ColorRect).queue_free()
	_projectiles.clear()


# --- Collisions -------------------------------------------------------------

func _verifier_collisions(delta: float) -> void:
	if _invincibilite > 0.0:
		_invincibilite -= delta
		_etincelle.visible = _invincibilite <= 0.0 or fmod(_invincibilite, RYTHME_CLIGNOTEMENT * 2) > RYTHME_CLIGNOTEMENT
		return

	var zone_etincelle := Rect2(
		_position_etincelle + Vector2.ONE * MARGE_COLLISION,
		TAILLE_ETINCELLE - Vector2.ONE * MARGE_COLLISION * 2)
	for projectile in _projectiles:
		if zone_etincelle.intersects(Rect2(projectile["position"], TAILLE_PROJECTILE)):
			_invincibilite = DUREE_INVINCIBILITE
			touchee.emit(_degats)
			return
