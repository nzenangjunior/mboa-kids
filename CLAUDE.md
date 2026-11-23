# CLAUDE.md — Mboa Kids ABC & 123

Ce fichier guide Claude Code sur ce dépôt. Lis-le en entier avant toute modification.
Cahier des charges complet : https://claude.ai/artifact/2VgN2hvV1kzZp9hUmVrCtF (référence fonctionnelle).

## 1. Le produit en bref

Appli Android **hors ligne** pour apprendre à une enfant de 4 ans (Estrella) :
l'alphabet, les nombres, l'écriture (tracé au doigt) et le vocabulaire, en **français** et en
**anglais britannique**, avec une félicitation à chaque réussite.

- Phase 1 : usage familial, APK installé à la main sur une **tablette Lenovo Android 10 (API 29)**.
- Phase 2 (plus tard, hors périmètre) : Play Store, paiement, plusieurs profils.
- L'utilisatrice **ne sait pas lire** : aucune consigne écrite, tout passe par la voix, les images et le toucher.

## 2. Règles non négociables

1. **100 % hors ligne.** Aucun appel réseau. Ne jamais ajouter la permission `INTERNET` dans
   `android/app/src/main/AndroidManifest.xml` (elle n'existe que dans les manifestes debug/profile).
2. **Aucune pub, aucun SDK d'analytics, aucun crash reporter tiers, aucun compte.** (Préparation du
   programme Familles de Google Play.)
3. **Pas de texte à lire pour l'enfant.** Chaque écran enfant a une consigne audio, rejouable en
   touchant la mascotte. Le texte n'est autorisé que dans l'espace parent.
4. **Cibles tactiles ≥ 64 dp.** 3 choix maximum par question (2 en mode aidé).
5. **Pas de punition.** Une erreur = son doux + la bonne réponse est montrée. Jamais d'écran « perdu »,
   jamais de score négatif.
6. **Deux mondes jamais mélangés** dans une même séance : monde français, monde anglais.
7. **Anglais britannique** : Z se dit « zed ».
8. Orientation **paysage** uniquement.
9. Le contenu (lettres, nombres, mots, limites, paquets) vit dans des **fichiers JSON**, jamais en dur
   dans le code. Ajouter un thème de vocabulaire ne doit demander aucun code.

## 3. Stack

| Besoin | Choix |
| --- | --- |
| Framework | Flutter (stable), Dart, null-safety |
| Navigation | go_router |
| État | flutter_riverpod |
| Persistance locale | drift (SQLite) |
| Audio | just_audio (clips embarqués .ogg/.mp3) |
| Voix de secours en dev | flutter_tts, **uniquement** derrière l'interface `AudioService` (voir §6) |
| Enregistrement voix parent | record + permission micro |
| Animations | lottie, confetti |
| Tracé | CustomPainter maison |
| Tests | flutter_test, tests unitaires sur la logique (progression, sélection des jeux, tracé) |

`applicationId` / package : `com.nzenang.mboakids`. minSdk ≥ 21. Appareil de test : API 29.

## 4. Arborescence cible

```
lib/
  main.dart
  app/                 # router, thème (rose/violet), constantes de taille
  core/
    audio/             # AudioService (interface), ClipAudioService, TtsFallbackAudioService
    content/           # modèles + chargement des JSON de contenu
    progress/          # moteur de progression, répétition espacée, base drift
    session/           # minuteur de séance, parcours du jour
  features/
    home/              # accueil + mascotte + bouton Jouer + cadenas parent
    world_select/      # choix du monde FR / EN
    daily_path/        # parcours du jour + carte des 4 îles
    alphabet/
    numbers/
    vocabulary/
    tracing/
    rewards/           # écran Bravo, étoiles, confettis, album d'autocollants
    parent/            # gate (calcul), réglages, suivi, enregistrement voix
  shared/widgets/      # BigTapTarget, Mascot, ChoiceCard, ...
assets/
  content/fr/*.json  content/en/*.json
  audio/fr/...  audio/en/...  audio/sfx/...
  images/...  lottie/...  tracing/*.json   # points clés du tracé par glyphe
test/
```

## 5. Modèle de contenu (JSON)

Un fichier par monde et par module. Exemple `assets/content/en/alphabet.json` :

```json
{
  "world": "en",
  "module": "alphabet",
  "packSize": 3,
  "items": [
    { "id": "en.letter.A", "glyph": "A", "lower": "a", "audio": "audio/en/letters/a.ogg",
      "word": { "label": "apple", "image": "images/vocab/apple.webp", "audio": "audio/en/words/apple.ogg" } }
  ]
}
```

Nombres : `assets/content/<world>/numbers.json` avec des **paliers paramétrables** :

```json
{ "recognize": [[0,20],[21,50],[51,100]], "countObjectsMax": 20, "writeMax": 20, "countByTensMax": 100 }
```

Vocabulaire : un fichier par thème (`vocab_animals.json`, `vocab_colors.json`), chaque mot a
`label_en`, `label_fr`, `image`, `audio_en`, `audio_fr`.

Les identifiants d'items sont stables (`en.letter.F`, `fr.number.12`, `en.word.cat`) : la progression
est stockée par id.

## 6. Audio

- Interface `AudioService` : `playPrompt(key)`, `playItem(itemId)`, `playSfx(name)`, `playPraise()`.
- `ClipAudioService` lit les clips embarqués. Si un clip manque, il **retombe** sur
  `TtsFallbackAudioService` (flutter_tts, voix `en-GB` ou `fr-FR` de l'appareil) et logue l'id manquant.
- Les vrais clips (voix neuronale britannique et française) seront ajoutés plus tard par Louis, sans
  changer le code : on dépose les fichiers aux chemins indiqués dans les JSON.
- Les félicitations utilisent en priorité les enregistrements du parent (stockés dans le dossier
  documents de l'appli), tirés au hasard, sinon des clips par défaut.

## 7. Progression (logique à tester unitairement)

- États d'un item : `aApprendre`, `enCours`, `aRevoir`, `acquis`.
- Point de départ monde anglais : A–E et 1–10 en `aRevoir`. Nouveautés à partir de F et de 11.
- Point de départ monde français : **jeu-découverte** à la première séance (A–J, 1–10) ; trouvé du
  premier coup → `aRevoir`, sinon `aApprendre`.
- Nouveaux items par **paquets de 3**. Paquet suivant débloqué quand le paquet courant est acquis.
- `acquis` = 3 bonnes réponses **du premier coup**, sur **au moins 2 jours différents**.
- Révisions espacées : J+1, J+3, J+7 après acquisition.
- **Mode aidé** : 2 erreurs de suite sur un item → 2 choix au lieu de 3, la bonne réponse brille.
- Un jeu = 5 questions, commence par une révision, mélange ~2 connus pour 1 nouveau.
- **Parcours du jour** : ~40 % révision, 40 % en cours, 20 % nouveautés, en alternant les modules.
  Ces ratios sont des constantes de config.
- Le tracé ne propose que des lettres déjà reconnues, sauf le **prénom** (tracé dès le début).
- La séance s'arrête à la durée choisie (5/10/15 min) après le jeu en cours → écran « la mascotte dort ».

## 8. Récompenses

- Bonne réponse : son + petite animation + voix courte.
- Fin de jeu : confettis + 1 à 3 étoiles + voix du parent avec le prénom.
- Item acquis : autocollant ajouté à l'album.
- Intensité réglable : `calme` / `normal` (défaut) / `fete`.

## 9. Espace parent

Accès par un cadenas, protégé par un calcul (ex. « 7 + 5 = ? », clavier numérique, 3 choix interdits).
Contient : prénom, mascotte, cases « déjà connu » par monde ou relance du jeu-découverte, consignes en
anglais oui/non, durée de séance, intensité des félicitations, enregistrement des ~10 phrases de
félicitation (enregistrer / réécouter / refaire), suivi (acquis, en cours, confusions fréquentes),
réinitialisation.

## 10. Ordre de construction

Une étape = une branche courte ou un commit propre sur `main`, l'appli **doit compiler et tourner** à la
fin de chaque étape. Après chaque étape : `flutter analyze`, `flutter test`, commit, push.

1. **Socle** : `flutter create --org com.nzenang --project-name mboa_kids`, paysage forcé, thème
   rose/violet, go_router, Riverpod, écrans vides reliés (accueil → monde → parcours → jeu → bravo).
2. **Contenu + audio** : modèles, chargement JSON, `AudioService` avec repli TTS, JSON alphabet et
   nombres 0–20 pour les deux mondes.
3. **Premier jeu** : alphabet « écoute et touche la lettre » (3 choix), feedback bonne/mauvaise réponse.
4. **Progression** : base drift, états, paquets, répétition espacée, mode aidé. Tests unitaires.
   Sélection des questions pilotée par la vraie progression (révision d'abord, ~2 connus pour 1
   nouveau), reprise automatique après erreur, panneau de debug `/debug/progress`.
5. **Récompenses** : écran Bravo, étoiles, confettis, album d'autocollants, intensité.
6. **Tracé** : CustomPainter, points clés par glyphe (JSON), tolérance large, flèches et point de départ,
   prénom.
7. **Nombres** : écoute et touche, compte les objets, glisse le chiffre dans sa silhouette, dizaines.
8. **Vocabulaire** : animaux et couleurs, image → mot, pont FR → EN.
9. **Espace parent** : gate, réglages, enregistrement voix, suivi.
10. **Parcours du jour + monde français** : sélection automatique, jeu-découverte, minuteur de séance.
11. **Finition** : performances sur la tablette Android 10, taille de l'APK (< 80 Mo), icône, build
    release signé, `README.md` d'installation.

## 11. Conventions

- Code et noms en anglais ; textes de l'espace parent en français.
- Widgets petits et testables ; aucune logique métier dans les widgets (elle va dans `core/`).
- Commits en français, à l'impératif, préfixés : `feat:`, `fix:`, `test:`, `chore:`, `docs:`.
- Ne jamais commiter de keystore, de mot de passe ou de fichier `key.properties`.
- En cas de doute fonctionnel, s'arrêter et poser la question à Louis plutôt que d'inventer.

## 12. Commandes utiles

```
flutter pub get
flutter analyze
flutter test
flutter run -d <id-tablette>          # tablette branchée en USB, débogage USB activé
flutter build apk --release --split-per-abi
adb install build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

## 13. Protocole de test

En attendant la tablette, chaque bloc de travail est testé dans l'aperçu web (Chrome) avant
d'être rendu à Louis. À appliquer à la fin de chaque bloc, dans cet ordre :

1. Lancer l'aperçu web et l'ouvrir dans Chrome.
2. Jouer au moins une partie complète dans le monde anglais avec au moins 2 erreurs volontaires,
   en lisant la console pendant toute la partie.
3. Vérifier chaque point du bloc un par un. Pour ce qui se mesure (étoiles, autocollants, états),
   utiliser le panneau `/debug/progress` et son bouton « Simuler +1 jour ».
4. Recharger la page et vérifier que les données sont toujours là.
5. Corriger ce qui ne va pas et retester. Ne pas rendre la main avant que tout passe.

Rapport de test attendu ensuite : chaque point du bloc avec OK/KO et ce qui a été observé, les
erreurs de la console (ou « console propre »), des captures d'écran des écrans nouveaux ou
modifiés, le numéro du commit et l'adresse de l'aperçu. Ne jamais écrire qu'une chose « devrait »
marcher : décrire ce qui a été vu. Si un point n'a pas pu être testé, l'écrire clairement.
