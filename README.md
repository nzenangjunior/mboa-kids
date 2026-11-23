# Mboa Kids ABC & 123

Application Android hors ligne pour apprendre l'alphabet, les nombres, l'écriture et le
vocabulaire en français et en anglais. Voir `CLAUDE.md` pour le cahier des charges complet.

## Installer sur la tablette Lenovo (Android 10) par USB

### 1. Activer le débogage USB sur la tablette (une seule fois)

1. Ouvrir **Paramètres** → **À propos de la tablette**.
2. Taper **7 fois** sur **Numéro de build** jusqu'à voir « Vous êtes maintenant développeur ! ».
3. Revenir dans **Paramètres** → **Options pour les développeurs** (nouvelle entrée, en bas).
4. Activer **Débogage USB**.

### 2. Brancher la tablette

1. Brancher la tablette à l'ordinateur avec un câble USB (data, pas seulement charge).
2. Sur la tablette, une pop-up « Autoriser le débogage USB ? » apparaît : cocher **Toujours
   autoriser depuis cet ordinateur** puis **OK**.
3. Vérifier que l'ordinateur la voit :

   ```
   adb devices
   ```

   La tablette doit apparaître avec le statut `device` (pas `unauthorized` — si c'est le cas,
   débrancher/rebrancher et accepter la pop-up).

### 3. Installer l'application

Deux façons, au choix :

**A. Lancer directement depuis Claude Code / le terminal (pratique en développement) :**

```
flutter run -d <id-tablette>
```

(`<id-tablette>` est l'identifiant affiché par `adb devices`.) L'appli se lance sur la tablette
avec le hot reload actif.

**B. Construire un APK et l'installer (pour un usage normal, sans terminal ouvert) :**

```
flutter build apk --release --split-per-abi
adb install -r build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

(`-r` réinstalle par-dessus une version existante sans perdre les données déjà enregistrées côté
Android — mais voir la note ci-dessous sur la progression.)

L'icône « Mboa Kids ABC & 123 » apparaît alors dans le tiroir d'applications de la tablette,
utilisable sans câble ni ordinateur ensuite (l'appli est 100 % hors ligne, CLAUDE.md règle 1).

### Notes

- La progression (lettres acquises, étoiles, autocollants) est stockée dans une base SQLite
  locale à l'application. Désinstaller l'application efface cette progression ; `adb install -r`
  (réinstallation par-dessus) la conserve.
- Aucune autorisation `INTERNET` n'est demandée à l'installation : c'est normal et volontaire
  (CLAUDE.md règle 1).
- Les voix entendues avant l'ajout des vrais enregistrements sont celles du moteur text-to-speech
  de la tablette elle-même (voix `fr-FR` ou `en-GB` installée sur l'appareil) : si une lettre est
  muette, vérifier que ces voix sont bien installées dans **Paramètres → Langues et saisie →
  Synthèse vocale** sur la tablette.
