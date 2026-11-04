# Système de mémoire

> Conception de la mémoire persistante du jeu : le **Carnet de Lumi**.
> Les valeurs chiffrées sont **provisoires**.

## 1. Principe

Le jeu utilise deux types de fichiers, qui n'ont pas du tout le même rôle :

| | Sauvegarde | Carnet |
|---|---|---|
| **Ce que c'est** | L'état d'**une partie** | La mémoire de **Lumi** |
| **Nombre** | Un fichier par emplacement | Un seul fichier |
| **Rechargeable par le joueur** | Oui | **Jamais** |
| **Remis à zéro par une nouvelle partie** | Oui | **Non** |
| **Contenu** | Position, inventaire, axes pacifisme / liens / vérité | Numéro du Voyageur, manipulation, historique des actions méta, fins vues |

La règle fondamentale : **le jeu ne lit jamais le Carnet depuis une sauvegarde, et ne le restaure jamais.**
Quand le joueur charge une partie, il remonte le temps dans la sauvegarde, mais le Carnet, lui, continue d'avancer.
C'est cette asymétrie qui permet à Lumi de se souvenir.

## 2. Emplacement des fichiers

Tous les fichiers sont dans le dossier de données du jeu, `user://` dans Godot :

```
user://
├── carnet.json           # Le Carnet de Lumi
├── carnet.json.bak       # Copie de secours du Carnet
└── saves/
    ├── slot_1.json
    ├── slot_2.json
    └── slot_3.json
```

| Système | Chemin réel de `user://` |
|---|---|
| Linux | `~/.local/share/voyageur-247/` |
| Windows | `%APPDATA%\voyageur-247\` |
| macOS | `~/Library/Application Support/voyageur-247/` |
| Web | Stockage du navigateur (IndexedDB) |

Le nom du dossier est fixé par le réglage `application/config/custom_user_dir_name`, indépendamment du titre du jeu :
changer le titre ne fera jamais perdre leurs données aux joueurs.

**Conformément aux principes du README**, le jeu ne lit et n'écrit **rien** en dehors de ce dossier.

## 3. Catalogue des souvenirs

Chaque action méta détectée devient un **souvenir** enregistré dans le Carnet.

| Identifiant | Action | Détection | Manipulation |
|---|---|---|---|
| `LANCEMENT` | Le jeu démarre | Au démarrage | 0 |
| `NOUVELLE_PARTIE` | Le joueur commence une nouvelle partie | Menu « Nouvelle partie » | +3, ou +1 si une fin a été vue avec le numéro actuel |
| `SAUVEGARDE` | Le joueur sauvegarde | Appel à la sauvegarde | 0 |
| `RECHARGEMENT` | Le joueur charge une sauvegarde **antérieure** à sa progression | Comparaison des compteurs (voir 5.1) | +1 |
| `RECHARGEMENT_APRES_DEFAITE` | Rechargement juste après un game over | Dernier souvenir = `DEFAITE` | +1 (en plus) |
| `CHOIX_REFAIT` | Le joueur refait un choix de dialogue différemment | Comparaison avec les choix connus (voir 5.2) | +2 |
| `DEFAITE` | Game over | Fin de combat perdu | 0 |
| `FUITE_EN_COMBAT` | Le jeu a été fermé pendant un combat | Session restée ouverte en combat (voir 5.3) | +2 |
| `FERMETURE_BRUTALE` | Le jeu a été fermé sans passer par le menu | Session restée ouverte hors combat | 0 |
| `LONGUE_ABSENCE` | Le joueur revient après longtemps | Écart de date depuis le dernier lancement (voir 5.4) | 0 |
| `FIN_VUE` | Le joueur atteint une fin | Déclenchement d'une fin | 0 |
| `CARNET_ALTERE` | Le Carnet a été modifié à la main | Empreinte invalide (voir 6.2) | 0 |
| `CARNET_DISPARU` | Le Carnet a été supprimé alors que des sauvegardes existent | Carnet absent, sauvegardes présentes (voir 6.3) | 0 |

## 4. Format des fichiers

Les fichiers sont en **JSON** : lisible, facile à déboguer, et natif dans Godot.

### 4.1 Le Carnet

```json
{
  "version": 1,
  "voyageur_numero": 247,
  "premier_lancement": 1793635200,
  "dernier_lancement": 1793721600,
  "nb_lancements": 12,
  "manipulation": 7,
  "session": {
    "ouverte": false,
    "en_combat": false,
    "combat_id": ""
  },
  "partie_commencee": true,
  "progression_actuelle": 1834,
  "choix_connus": {
    "prologue_numero": "demander",
    "cardon_entrainement": "encourager"
  },
  "boss_rencontres": ["gardien_puits"],
  "fins_vues": [
    { "fin": "au_revoir", "numero": 247, "date": 1793700000 }
  ],
  "chemins_decouverts": ["prologue_numero:demander", "acte1_gardien:epargner"],
  "oubli_fait": false,
  "souvenirs": [
    { "type": "RECHARGEMENT", "date": 1793710000, "donnees": { "scene": "foret_entree" } }
  ],
  "empreinte": "3f2a..."
}
```

| Champ | Rôle |
|---|---|
| `voyageur_numero` | Numéro actuel du joueur, commence à 247, ne redescend jamais |
| `manipulation` | Score de manipulation cumulé, toutes parties confondues |
| `session` | Permet de détecter une fermeture anormale au lancement suivant |
| `partie_commencee` | Indique si une première partie a déjà été lancée (sinon la prochaine sera celle du n°247) |
| `progression_actuelle` | Position du joueur dans la ligne du temps **pour le numéro actuel**, mise à jour à chaque chargement |
| `choix_connus` | Premier choix fait pour chaque décision, **pour le numéro actuel** |
| `boss_rencontres` | Boss déjà affrontés, toutes parties confondues (réactions de Lumi) |
| `fins_vues` | Fins atteintes, avec le numéro du Voyageur à ce moment |
| `chemins_decouverts` | Alimente l'écran d'embranchements |
| `oubli_fait` | Seul indicateur conservé après la fin L'Oubli |
| `souvenirs` | Historique des actions méta (limité aux 500 plus récents) |
| `empreinte` | Permet de détecter une modification manuelle du fichier |

### 4.2 Une sauvegarde

```json
{
  "version": 1,
  "voyageur_numero": 247,
  "progression": 1290,
  "date": 1793715000,
  "temps_de_jeu": 5420,
  "scene": "foret_entree",
  "position": { "x": 320, "y": 184 },
  "acte": 2,
  "lanternes": 1,
  "pacifisme": { "epargnes": 4, "vaincus": 1, "boss_vaincus": [] },
  "liens": { "lumi": 6, "ortie": 3, "cardon": 2, "mirette": 1 },
  "verite": { "indices": [1, 2, 4], "question_phare": false, "promesse": false },
  "choix": { "prologue_numero": "demander" },
  "inventaire": ["potion", "potion", "cle_puits"]
}
```

## 5. Détection des actions méta

### 5.1 Le rechargement

Le jeu tient un **compteur de progression** : un entier qui augmente à chaque événement de jeu significatif
(changement de scène, dialogue terminé, combat terminé, objet ramassé).

- La sauvegarde stocke la valeur du compteur au moment où elle est faite
- Le Carnet stocke `progression_actuelle`, la position du joueur dans la ligne du temps

Au chargement d'une sauvegarde :

```
si sauvegarde.progression < carnet.progression_actuelle :
    → le joueur remonte dans le temps : souvenir RECHARGEMENT
progression_actuelle = sauvegarde.progression
```

Charger une sauvegarde juste après l'avoir faite (par exemple après avoir quitté proprement) ne crée aucun souvenir.
En revanche, jouer sans sauvegarder puis recharger la dernière halte est bien un retour en arrière :
Lumi a vu des événements qui ont disparu.

**Pourquoi un compteur et pas la date ?** Le joueur peut changer l'heure de son ordinateur.
Le compteur, lui, ne dépend que de ce qui s'est passé en jeu.

### 5.2 Le choix refait

Chaque choix majeur a un identifiant unique (par exemple `cardon_entrainement`).

```
au moment où le joueur fait un choix :
    si le choix n'est pas dans carnet.choix_connus :
        → on enregistre ce premier choix
    sinon si l'option est différente de celle enregistrée :
        → souvenir CHOIX_REFAIT
```

Le Carnet garde **le premier choix**, jamais le plus récent : Lumi se souvient de « la première fois ».

### 5.3 La fuite en combat et la fermeture brutale

Le Carnet contient un bloc `session` :

| Moment | Action sur le Carnet |
|---|---|
| Lancement du jeu | Vérifier la session précédente, puis `ouverte = true` |
| Début d'un combat | `en_combat = true`, `combat_id = "..."` |
| Fin d'un combat | `en_combat = false` |
| Fermeture propre (menu ou croix de la fenêtre) | `ouverte = false` |

Au lancement suivant, si `session.ouverte` est encore à `true`, le jeu n'a pas été fermé proprement :
- avec `en_combat == true` → souvenir `FUITE_EN_COMBAT`
- sinon → souvenir `FERMETURE_BRUTALE`

**Point important :** fermer la fenêtre avec la croix ou Alt+F4 envoie une demande de fermeture que Godot intercepte
(`NOTIFICATION_WM_CLOSE_REQUEST`). Le jeu peut donc l'enregistrer. Ainsi, quitter pendant un combat avec la croix est
bien détecté comme une fuite, alors qu'un plantage ou un `kill` est détecté au lancement suivant grâce à la session restée ouverte.

### 5.4 La longue absence

Au lancement, on compare la date actuelle avec `dernier_lancement`.
Si l'écart dépasse **3 jours** *(provisoire)* → souvenir `LONGUE_ABSENCE`, avec le nombre de jours dans les données.
Si la date actuelle est **antérieure** au dernier lancement (horloge modifiée), on ignore simplement le calcul.

### 5.5 La nouvelle partie

```
quand le joueur lance une nouvelle partie :
    si aucune partie n'a jamais été commencée :
        numéro = 247 (premier lancement, pas d'incrément)
    sinon :
        si une fin a été vue avec le numéro actuel → manipulation +1
        sinon → manipulation +3
        numéro += 1
    progression_actuelle = 0
    choix_connus = {}
    souvenir NOUVELLE_PARTIE
```

`progression_actuelle` et `choix_connus` sont remis à zéro parce qu'ils concernent **un Voyageur précis**.
Le numéro, la manipulation, les boss rencontrés et les fins vues, eux, restent.

## 6. Robustesse

### 6.1 Écriture sûre

Le Carnet est réécrit à chaque souvenir. Pour qu'une coupure de courant ou un plantage pendant l'écriture
ne le corrompe jamais :

1. Écrire le nouveau contenu dans `carnet.json.tmp`
2. Copier l'ancien `carnet.json` vers `carnet.json.bak`
3. Renommer `carnet.json.tmp` en `carnet.json`

Le renommage est une opération quasi instantanée : à tout moment, il existe un Carnet complet et valide.
Au chargement, si `carnet.json` est illisible, on utilise `carnet.json.bak`.

### 6.2 Détection d'une modification manuelle

Le Carnet contient une `empreinte` : un hash SHA-256 de son contenu, combiné à une valeur fixe propre au jeu.
Si le joueur modifie le fichier à la main, l'empreinte ne correspond plus.

Le jeu **ne rejette pas** le Carnet modifié : il l'utilise tel quel, et ajoute un souvenir `CARNET_ALTERE`.
Lumi le remarque : « Quelqu'un a écrit dans mon carnet… Ce n'est pas mon écriture. »

**Ce n'est pas une mesure de sécurité**, seulement un élément de narration : la valeur fixe est dans le jeu,
donc un joueur motivé peut recalculer l'empreinte. Et c'est très bien comme ça : un joueur qui fait cet effort
mérite de tromper Lumi.

### 6.3 Carnet supprimé

Si le Carnet est absent mais que des sauvegardes existent (quel que soit leur numéro),
le joueur a essayé d'effacer la mémoire de Lumi.

Le jeu recrée un Carnet en reprenant le **numéro le plus élevé trouvé dans les sauvegardes**
(le numéro ne redescend jamais) et ajoute un souvenir `CARNET_DISPARU`.
Lumi ne se souvient plus des détails, mais elle sent qu'il manque quelque chose : « J'ai l'impression d'avoir perdu… des pages. »

### 6.4 Migration

Chaque fichier a un champ `version`. Si la structure change en cours de développement,
une fonction de migration met à jour les anciens fichiers au chargement au lieu de les casser.

## 7. Architecture du code

### 7.1 Autoloads

Trois scripts globaux (autoloads), accessibles depuis n'importe quelle scène :

| Autoload | Fichier | Rôle |
|---|---|---|
| `Carnet` | `scripts/autoload/carnet.gd` | Lecture, écriture et requêtes sur le Carnet |
| `SaveManager` | `scripts/autoload/save_manager.gd` | Sauvegarde, chargement, nouvelle partie |
| `GameState` | `scripts/autoload/game_state.gd` | État de la partie en cours (axes, scène, inventaire, progression) |

Ordre de chargement : `Carnet` → `GameState` → `SaveManager`.

### 7.2 API prévue du Carnet

```gdscript
# Signal émis à chaque nouveau souvenir (les dialogues et Lumi peuvent s'y abonner)
signal souvenir_enregistre(type: String, donnees: Dictionary)

func enregistrer(type: String, donnees: Dictionary = {}) -> void
func get_numero() -> int
func get_manipulation() -> int
func get_niveau_manipulation() -> String          # "faible", "moyen" ou "fort"
func a_souvenir(type: String) -> bool
func compter_souvenirs(type: String) -> int
func dernier_souvenir() -> Dictionary
func a_rencontre_boss(boss_id: String) -> bool
func a_vu_fin(fin_id: String) -> bool
func enregistrer_choix(choix_id: String, option: String) -> void
func debut_combat(combat_id: String) -> void
func fin_combat() -> void
```

### 7.3 Exemple : écriture sûre

```gdscript
const CHEMIN := "user://carnet.json"
const CHEMIN_TMP := "user://carnet.json.tmp"
const CHEMIN_BAK := "user://carnet.json.bak"

func _ecrire() -> void:
	data["empreinte"] = _calculer_empreinte()
	var fichier := FileAccess.open(CHEMIN_TMP, FileAccess.WRITE)
	if fichier == null:
		push_error("Carnet : impossible d'écrire le fichier temporaire")
		return
	fichier.store_string(JSON.stringify(data, "\t"))
	fichier.close()

	if FileAccess.file_exists(CHEMIN):
		DirAccess.copy_absolute(CHEMIN, CHEMIN_BAK)
	DirAccess.rename_absolute(CHEMIN_TMP, CHEMIN)
```

### 7.4 Exemple : détecter une fermeture

```gdscript
func _ready() -> void:
	# On gère nous-mêmes la fermeture pour avoir le temps d'écrire le Carnet
	get_tree().set_auto_accept_quit(false)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if data["session"]["en_combat"]:
			enregistrer("FUITE_EN_COMBAT", {"combat_id": data["session"]["combat_id"]})
		data["session"]["ouverte"] = false
		_ecrire()
		get_tree().quit()
```

## 8. Utilisation dans les dialogues

Les dialogues interrogent le Carnet pour choisir leurs répliques. Exemple pour Lumi au début d'un combat :

```gdscript
if Carnet.a_rencontre_boss("gardien_puits"):
	lumi.dire("Laisse-moi lui parler. Je sais ce qu'il veut entendre. On a déjà fait ça.")
elif Carnet.dernier_souvenir().get("type") == "RECHARGEMENT_APRES_DEFAITE":
	lumi.dire("Tu as perdu ici, tout à l'heure. Je l'ai vu.")
else:
	lumi.dire("Allez, on y va ! Je suis juste derrière toi !")
```

Le système de dialogues sera décrit dans le GDD.

## 9. Export web (démo)

Dans un navigateur, `user://` est stocké dans IndexedDB, et la fermeture d'un onglet n'est pas détectable de façon fiable.

| Fonctionnalité | Version complète | Démo web |
|---|---|---|
| Carnet persistant | Oui | Oui (tant que le joueur ne vide pas les données du site) |
| Rechargement, choix refait | Oui | Oui |
| Fuite en combat | Oui | Non fiable, désactivé |
| Carnet altéré ou supprimé | Oui | Non |

La démo web se concentre donc sur le prologue et l'acte 1, avec les réactions au rechargement.

## 10. Scénarios de test

| N° | Scénario | Résultat attendu |
|---|---|---|
| 1 | Premier lancement, nouvelle partie | Numéro 247, manipulation 0 |
| 2 | Sauvegarder, quitter par le menu, relancer, charger | Aucun souvenir `RECHARGEMENT` |
| 3 | Sauvegarder, avancer, charger la sauvegarde | Souvenir `RECHARGEMENT`, manipulation +1 |
| 4 | Perdre un combat, charger | `RECHARGEMENT` + `RECHARGEMENT_APRES_DEFAITE`, manipulation +2 |
| 5 | Faire un choix, recharger, choisir autre chose | Souvenir `CHOIX_REFAIT`, `choix_connus` garde le premier choix |
| 6 | Fermer la fenêtre pendant un combat | Au lancement suivant, aucun nouveau souvenir (dé
à enregistré à la fermeture) et `FUITE_EN_COMBAT` présent |
| 7 | Tuer le processus pendant un combat (`kill -9`) | Au lancement suivant, souvenir `FUITE_EN_COMBAT` |
| 8 | Nouvelle partie sans fin vue | Numéro +1, manipulation +3 |
| 9 | Nouvelle partie après une fin | Numéro +1, manipulation +1 |
| 10 | Modifier `carnet.json` à la main | Souvenir `CARNET_ALTERE`, le jeu fonctionne |
| 11 | Supprimer `carnet.json` (sauvegardes conservées) | Numéro repris depuis les sauvegardes, souvenir `CARNET_DISPARU` |
| 12 | Supprimer `carnet.json` et `carnet.json.bak` alors que `carnet.json` est corrompu | Le jeu redémarre proprement sans planter |
| 13 | Corrompre `carnet.json` (contenu invalide) | Le jeu utilise `carnet.json.bak` |
