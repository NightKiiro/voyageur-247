# Roadmap

> Ordre de construction du jeu. Chaque phase a une **définition de terminé** : on ne passe à la suivante
> que lorsqu'elle est remplie.

## Phase 0 — Pré-production ✅

- [x] Lore, personnages
- [x] Structure et fins
- [x] Système de mémoire
- [x] GDD et roadmap

## Phase 1 — Fondations techniques ✅

Objectif : la mémoire du jeu fonctionne, avant même d'avoir un seul sprite.

- [x] Arborescence du projet (voir plus bas)
- [x] Réglages du projet : résolution 320 × 180, mise à l'échelle, filtre pixel art
- [x] Autoload `Carnet` : lecture, écriture sûre, souvenirs, session, empreinte
- [x] Autoload `GameState` : axes, compteur de progression, inventaire
- [x] Autoload `SaveManager` : 3 emplacements, sauvegarde, chargement, nouvelle partie
- [x] Scène de débogage du Carnet et des sauvegardes

**Terminé quand :** les 13 scénarios de test de `MEMORY_SYSTEM.md` passent, avec de simples boutons à la place du jeu.

## Phase 2 — Prototype d'exploration

Objectif : se déplacer et parler, avec des carrés de couleur à la place des graphismes.

- [x] Actions de contrôle (clavier et manette)
- [x] Personnage jouable et déplacement 8 directions
- [x] Une scène de test avec collisions
- [x] Système d'interaction
- [x] Système de dialogues (JSON, conditions, choix)
- [ ] Une halte fonctionnelle
- [ ] Transitions entre scènes
- [ ] Écran de débogage F3 par-dessus le jeu (contenu du Carnet en direct)

**Terminé quand :** on peut parler à Lumi, faire un choix, sauvegarder à une halte, recharger,
refaire le choix, et Lumi le remarque.

## Phase 3 — Prototype de combat

- [ ] Phase de choix (Frapper, Parler, Objet, Lumi)
- [ ] Phase d'esquive avec l'Étincelle et 3 motifs d'attaque
- [ ] Jauges de PV et d'apaisement, option Épargner
- [ ] Défaite et retour au chargement
- [ ] Combat contre Cardon (version grise)

**Terminé quand :** on peut gagner, épargner et perdre contre Cardon, et le Carnet enregistre tout.

## Phase 4 — Tranche verticale (prologue + acte 1)

Objectif : 20 à 30 minutes de jeu représentatives du jeu final.

- [ ] Graphismes du village de Brindille et du puits
- [ ] Sprites et portraits de Lumi, Ortie, Cardon, Mirette, le Gardien du Puits
- [ ] Tous les dialogues du prologue et de l'acte 1, avec les réactions méta
- [ ] Combat du Gardien du Puits
- [ ] Indices 1 à 4
- [ ] Premier shader de dégradation (niveaux 0 à 2)
- [ ] Musiques et sons de base

**Terminé quand :** au moins 3 personnes qui ne connaissent pas le concept y ont joué,
et au moins l'une d'elles a eu le moment « attends… il se souvient ? ».

## Phase 5 — Démo web

- [ ] Export web de la tranche verticale
- [ ] Désactivation des fonctionnalités non fiables sur le web (voir `MEMORY_SYSTEM.md`, section 9)
- [ ] Mise en ligne sur le site de jeux

**Terminé quand :** la démo est jouable en ligne et une fiche du jeu existe sur le site.

## Phase 6 — Contenu complet

- [ ] Acte 2 : Forêt des Murmures (boss, indices 5 à 7, scène où Lumi s'égare)
- [ ] Acte 3 : Ruines du Phare (boss, indices 8 et 9, question du Phare, promesse)
- [ ] Final : Cœur de la Vallée, combat contre Lumi
- [ ] Les 5 fins et les épilogues des personnages
- [ ] Comportements après une fin (STRUCTURE.md, section 6)

**Terminé quand :** les 5 fins sont atteignables du début à la fin.

## Phase 7 — Finitions

- [ ] Écran d'embranchements
- [ ] Shaders de dégradation complets (niveau 3)
- [ ] Musiques définitives et déformations
- [ ] Options (touches, volume, plein écran)
- [ ] Équilibrage des seuils (manipulation, pacifisme, indices)
- [ ] Session de test complète par des joueurs extérieurs

**Terminé quand :** aucune erreur bloquante, toutes les fins testées par au moins une personne extérieure.

## Phase 8 — Sortie

- [ ] Builds Linux, Windows, macOS
- [ ] Publication sur le site de jeux (avec empreintes SHA-256 des fichiers)
- [ ] Page de présentation, captures, bande-annonce courte
- [ ] Choix de la licence

## Arborescence du projet

```
voyageur-247/
├── assets/
│   ├── audio/
│   │   ├── musiques/
│   │   └── sons/
│   ├── polices/
│   ├── shaders/
│   └── sprites/
│       ├── personnages/
│       ├── portraits/
│       └── tuiles/
├── data/
│   └── dialogues/
├── docs/
├── scenes/
│   ├── combat/
│   ├── debug/
│   ├── monde/
│   ├── personnages/
│   └── ui/
├── scripts/
│   ├── autoload/
│   ├── combat/
│   ├── dialogues/
│   └── monde/
└── project.godot
```

## Conventions

| Élément | Convention | Exemple |
|---|---|---|
| Fichiers et dossiers | `snake_case` | `save_manager.gd`, `village_brindille.tscn` |
| Classes GDScript | `PascalCase` | `class_name DialogueBox` |
| Variables et fonctions | `snake_case` | `get_niveau_manipulation()` |
| Constantes | `MAJUSCULES` | `const MAX_SOUVENIRS := 500` |
| Branches Git | `type/description` | `feat/carnet`, `fix/rechargement`, `docs/structure` |
| Commits | Anglais, format conventionnel | `feat: add Carnet autoload with safe write` |
