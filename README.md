# FinWise — gestion de budget (Flutter : Android, iOS, Windows)

Écrans repris du prototype Figma « FinWise » : Welcome, Login, Create Account,
Mot de passe oublié, Accueil (budget + onglets Jour/Semaine/Mois), Analyse,
Transactions par mois, Notifications, Profil (Modifier le profil, Sécurité,
Réglages, Aide & FAQ, Déconnexion), Supprimer le compte.
En plus : verrouillage biométrique (empreinte / Face ID / Windows Hello),
connexion Google + email, synchronisation cloud (Firestore), interface adaptative
mobile / desktop.

Écarts volontaires avec le prototype : pas de Facebook, pas d'écran « Change Pin »
(le code de l'appareil sert de secours à la biométrie), pas de Notification Settings
(pas de push), pas d'objectifs Travel/Car ni de date de naissance, FAQ sans onglet Contact.

## Démarrage
1. PowerShell dans ce dossier : `.\setup.ps1`
   (crée android/ios/windows, patche la biométrie, `flutter pub get`)
2. Sans cloud : `flutter run -d windows` (ou un émulateur) → « Continuer sans compte ».

## Activer le cloud (Firebase)
1. Créer un projet sur https://console.firebase.google.com
2. Authentication → activer **Google** et **Email/Mot de passe**
3. Firestore Database → créer, puis coller `firestore.rules` dans l'onglet Règles
4. `dart pub global activate flutterfire_cli` puis `flutterfire configure`
   (remplace `lib/firebase_options.dart`)
5. Android + Google : ajouter l'empreinte SHA-1 (`cd android; .\gradlew signingReport`)
   dans les paramètres du projet Firebase, re-télécharger la config via flutterfire.

## Connexion Google sur Windows (bureau)
1. https://console.cloud.google.com → choisir le projet Google Cloud **du même projet Firebase**.
2. API et services → Identifiants → Créer des identifiants → ID client OAuth →
   type **Application de bureau**. (Configurer d'abord l'écran de consentement OAuth
   si demandé ; ajoutez votre Gmail comme utilisateur test.)
3. Lancer avec les identifiants :
   `flutter run -d windows --dart-define=GOOGLE_DESKTOP_CLIENT_ID=xxx --dart-define=GOOGLE_DESKTOP_CLIENT_SECRET=yyy`
   (même options pour `flutter build windows`). Sans eux, le bouton Google est désactivé.
4. Le navigateur s'ouvre, vous choisissez votre compte Google, puis l'app est connectée
   au même compte Firebase que sur le téléphone.
Ne publiez pas le secret dans un dépôt public.

## Limites connues
- Les données créées en « mode local » ne sont pas migrées vers le cloud.
- Windows + Firestore : premier build long ; activer le « Mode développeur » Windows.
