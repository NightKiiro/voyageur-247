# Voyageur n°247

> Un petit RPG qui se souvient de tout. Surtout de ce que tu aimerais qu'il oublie.

## Pitch

Tu arrives dans la Vallée de Clairmousse, un monde paisible menacé par une étrange Brume.
Lumi, une petite luciole joyeuse, t'accueille, te donne un numéro, et décide de t'accompagner.

Tu es le Voyageur n°247.

Lumi t'aide, te conseille, plaisante pendant les combats.
Mais Lumi remarque des choses. Quand tu recharges une partie. Quand tu quittes en plein combat.
Quand tu reviens en arrière pour effacer une erreur. Quand tu recommences tout depuis le début.

Lumi se souvient. Et Lumi n'a pas envie que tu partes.

## Concept

Un RPG 2D narratif où le jeu garde une **mémoire persistante** de toutes les actions du joueur,
y compris celles qui se passent « hors du jeu » : recharger une sauvegarde, quitter, recommencer.
Les personnages, et surtout Lumi, réagissent à ces actions.

Le jeu propose **plusieurs fins**, déterminées par la façon dont le joueur combat, les liens qu'il
tisse avec les personnages, et la manière dont il traite ses sauvegardes.

## Statut

🟡 **Pré-production** : écriture du lore et du game design.

## Technique

| Élément | Choix |
|---|---|
| Moteur | Godot 4 |
| Langage | GDScript |
| Rendu | Compatibility (OpenGL) |
| Plateformes visées | Linux, Windows, macOS (version complète), Web (démo) |
| Gestion des assets | Git LFS |

## Lancer le projet

1. Installer [Godot 4](https://godotengine.org/download) (version standard, pas .NET)
2. Installer Git LFS puis cloner le dépôt :
   ```bash
   git lfs install
   git clone git@github.com:<pseudo>/voyageur-247.git
   ```
3. Ouvrir Godot, cliquer sur **Import** et sélectionner le fichier `project.godot`

## Documentation

| Document | Contenu |
|---|---|
| [LORE.md](docs/LORE.md) | L'univers, la vérité cachée, le numéro du Voyageur |
| [CHARACTERS.md](docs/CHARACTERS.md) | Les personnages et leurs réactions aux actions méta |
| [GDD.md](docs/GDD.md) | Game design : boucle de jeu, combats, exploration, dialogues |
| [MEMORY_SYSTEM.md](docs/MEMORY_SYSTEM.md) | Catalogue des souvenirs et conception technique de la mémoire |
| [STRUCTURE.md](docs/STRUCTURE.md) | Zones, progression, embranchements et fins |
| [ROADMAP.md](docs/ROADMAP.md) | Étapes de développement et conventions |

## Principes de conception

Le jeu joue avec l'idée qu'il « sait » des choses sur le joueur, mais il respecte toujours sa machine :

- Le jeu n'écrit **que** dans son propre dossier de données (`user://`)
- Le jeu n'empêche **jamais** réellement le joueur de quitter : toute « résistance » est une mise en scène
- Le jeu ne lit **aucune** donnée personnelle en dehors de ses propres fichiers
- Les effets de peur restent dans la fiction

## Crédits

- Police : [Pixel Operator](https://www.dafont.com/pixel-operator.font), par Jayvee Enaguas (CC0)

## Licence

À définir.
