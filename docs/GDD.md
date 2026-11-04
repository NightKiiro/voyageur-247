# Game Design Document

> Comment on joue à Voyageur n°247. Les valeurs chiffrées sont **provisoires**.

## 1. Fiche du jeu

| | |
|---|---|
| **Genre** | RPG narratif 2D, combat tour par tour avec phases d'esquive |
| **Vue** | Vue du dessus |
| **Durée visée** | 3 à 5 heures pour une partie, plus pour voir toutes les fins |
| **Plateformes** | Linux, Windows, macOS, démo web |
| **Moteur** | Godot 4, GDScript |
| **Inspirations** | Undertale (combat, méta), Detroit: Become Human (embranchements), Cult of the Lamb (mignon et sombre) |

## 2. Piliers de design

Chaque décision de design doit servir au moins un de ces piliers :

1. **Mignon, puis inquiétant** : le confort du début rend la bascule plus forte
2. **Le jeu se souvient** : toute action du joueur peut avoir un écho, même hors de la partie
3. **Les choix comptent** : chaque choix majeur a une conséquence visible, tôt ou tard
4. **Respect du joueur** : on fait peur, on ne piège jamais, on ne punit jamais la curiosité

## 3. Boucle de jeu

```
Explorer une zone → Parler aux habitants → Rencontrer un obstacle ou un ennemi
→ Combattre ou apaiser → Progresser (indice, objet, lien) → Se reposer à une halte (sauvegarde)
→ Zone suivante
```

Par-dessus cette boucle, une **boucle méta** : chaque sauvegarde, rechargement ou nouvelle partie
nourrit le Carnet de Lumi, qui modifie à son tour les dialogues, les indices disponibles et l'ambiance.

## 4. Exploration

### Déplacement

- Déplacement en 8 directions, y compris au stick (la direction est arrondie à la plus proche)
- Vitesse de 60 pixels par seconde, soit 1 pixel par image : un mouvement net en pixel art
- En diagonale, chaque axe avance à pleine vitesse (1 pixel par image, comme dans Undertale) : un mouvement net, avec une diagonale un peu plus rapide

### Interactions

- Touche d'action devant un PNJ, un objet ou un élément du décor
- Les éléments interactifs ont un léger scintillement (sauf les indices cachés)

### Haltes (points de sauvegarde)

Le joueur ne peut sauvegarder qu'aux **haltes** : de petites pierres moussues où Lumi se pose pour se reposer.

- Sauvegarder restaure tous les points de vie
- Lumi dit une courte phrase à chaque halte, qui évolue selon le Carnet
- **Pourquoi pas une sauvegarde libre** : les haltes donnent du poids à chaque sauvegarde et à chaque rechargement.
  Revenir à la dernière halte est un acte conscient, que Lumi peut commenter

### Emplacements

3 emplacements de sauvegarde. Le menu affiche pour chacun : la zone, le temps de jeu et **le numéro du Voyageur**
(un emplacement d'une ancienne partie affiche un ancien numéro, ce qui crée un malaise volontaire).

## 5. Combat

### Déroulement d'un tour

1. **Phase de choix** : le joueur choisit une action dans un menu
2. **Phase d'esquive** : l'ennemi attaque, le joueur contrôle **l'Étincelle** (un fragment de la lumière de Lumi)
   dans un cadre et doit éviter les projectiles
3. Retour à la phase de choix

### Actions

| Action | Effet |
|---|---|
| **Frapper** | Inflige des dégâts. Un mini-jeu de timing (une jauge qui défile) détermine la puissance |
| **Parler** | Ouvre une liste d'options propres à chaque ennemi. Les bonnes options augmentent l'apaisement |
| **Objet** | Utiliser un objet de l'inventaire (soin principalement) |
| **Lumi** | Lumi observe l'ennemi et donne un indice sur la bonne option de dialogue. Coûte le tour |

### Fin d'un combat

Chaque ennemi a deux jauges :

| Jauge | Si elle atteint son seuil |
|---|---|
| **Points de vie** à 0 | L'ennemi est **vaincu** : `combats_vaincus` +1 |
| **Apaisement** à 100 % | L'option **Épargner** apparaît dans Parler : `combats_epargnes` +1 |

Frapper un ennemi presque apaisé fait chuter son apaisement : le joueur doit choisir une voie.

### Statistiques

Volontairement minimales :

| Statistique | Évolution |
|---|---|
| Points de vie (PV) | Augmentent à chaque Lanterne obtenue |
| Attaque, défense | Dépendent de l'équipement trouvé |

**Pas d'expérience ni de niveaux** : le joueur n'est pas récompensé mécaniquement pour la violence.
Un joueur pacifiste n'est jamais en retard sur un joueur violent.

### Défaite

Écran de défaite avec une réplique de Lumi (qui évolue avec le nombre de défaites dans le Carnet),
puis retour au menu de chargement.

### Lumi en combat

- Commente le combat (blagues au début, inquiétude plus tard)
- Si le boss a déjà été rencontré dans une autre partie, ses indices deviennent précis : « Il aime qu'on lui parle de la mousse. Je le sais, on l'a déjà fait. »
- Selon la tendance à la violence (voir STRUCTURE.md, section 2.1), Lumi parle de moins en moins, puis presque plus du tout

## 6. Dialogues

### Format

Les dialogues sont écrits dans des fichiers JSON dans `data/dialogues/`, séparés du code.
Chaque réplique peut avoir des **conditions** qui interrogent le Carnet ou l'état de la partie.

```json
{
  "id": "lumi_halte_puits",
  "repliques": [
    {
      "perso": "lumi",
      "humeur": "inquiete",
      "texte": "Tu reviens toujours ici, hein…",
      "condition": { "souvenir_min": { "type": "RECHARGEMENT", "nombre": 3 } }
    },
    {
      "perso": "lumi",
      "humeur": "joyeuse",
      "texte": "Une petite pause ? Bonne idée !"
    }
  ]
}
```

La première réplique dont la condition est remplie est affichée.
Une réplique sans condition sert de réplique par défaut.

### Choix

```json
{
  "id": "cardon_apres_entrainement",
  "choix": {
    "choix_id": "cardon_entrainement",
    "options": [
      { "id": "ridiculiser", "texte": "« C'était facile. »", "effets": { "lien_cardon": -1 } },
      { "id": "encourager", "texte": "« Tu t'es bien battu. »", "effets": { "lien_cardon": 2 } }
    ]
  }
}
```

Chaque choix passe par `Carnet.enregistrer_choix()`, ce qui permet de détecter les choix refaits.

### Affichage

- Boîte de dialogue en bas de l'écran, portrait du personnage à gauche
- Texte qui s'affiche lettre par lettre, avec un son par personnage
- Le portrait de Lumi change selon son humeur (couleur de sa lumière)

## 7. Contrôles

| Action | Clavier | Manette |
|---|---|---|
| Se déplacer | Flèches ou ZQSD | Stick gauche, croix |
| Interagir, valider | Entrée ou E | A / Croix |
| Annuler, retour | Échap ou Retour arrière | B / Rond |
| Menu | Tab | Start |
| Accélérer le texte | Maintenir valider | Maintenir A |

Toutes les touches sont configurables dans les options.
Le déplacement utilise la **position physique** des touches : ZQSD sur un clavier AZERTY, WASD sur un clavier QWERTY.

## 8. Interface

| Écran | Contenu |
|---|---|
| **Écran titre** | Titre, « Nouvelle partie », « Continuer », « Options ». Le titre affiche le numéro actuel du Voyageur |
| **HUD** | Rien en exploration. En combat : PV, menu d'actions, cadre d'esquive |
| **Menu pause** | Inventaire, statut, options, quitter |
| **Menu de sauvegarde** | 3 emplacements (zone, temps, numéro du Voyageur) |
| **Écran d'embranchements** | Après chaque fin (voir STRUCTURE.md, section 7) |
| **Fenêtre** | Le titre de la fenêtre affiche le numéro actuel du Voyageur (« Voyageur n°249 ») |

## 9. Direction artistique

| Élément | Choix |
|---|---|
| Style | Pixel art |
| Tuiles | 16 × 16 pixels |
| Résolution interne | 320 × 180, agrandie en plein écran (×4 en 1280 × 720, ×6 en 1920 × 1080) |
| Palette | Pastels chauds au début (verts mousse, jaunes doux, roses) |
| Personnages | Têtes rondes, gros yeux, silhouettes simples |
| Outil | Pixelorama |

### Dégradation visuelle

Le décor se dégrade selon le temps de révélation et le niveau de manipulation :

| Niveau | Effets |
|---|---|
| 0 | Aucun |
| 1 | Couleurs légèrement désaturées près des haltes |
| 2 | Petits glitchs ponctuels (tuile qui saute, PNJ qui clignote) |
| 3 | Brume visible en bord d'écran, palette froide, sons déformés |

Les effets sont faits avec des **shaders** appliqués à l'écran, pour ne pas devoir redessiner les décors.

## 10. Son

- Musiques douces et simples (piano, boîte à musique, petites percussions)
- Les musiques se déforment légèrement aux niveaux de dégradation 2 et 3 (ralentissement, désaccord)
- Chaque personnage a un son de « voix » pour le texte
- Ressources : compositions personnelles ou ressources sous licence libre (CC0, CC-BY), toujours créditées

## 11. Périmètre de la version 1.0

| Inclus | Exclu (pour plus tard, peut-être) |
|---|---|
| Prologue, 3 actes, final | Quêtes secondaires nombreuses |
| 5 fins et leurs variantes | Traduction anglaise |
| 4 boss, une dizaine d'ennemis | Succès Steam |
| Écran d'embranchements | Mode New Game+ spécifique |
| Démo web (prologue + acte 1) | Version mobile |
