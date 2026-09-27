# Fizika za I razred gimnazije

Flutter aplikacija za adaptivno vežbanje fizike (I razred gimnazije). Radi offline; baza pitanja je ugrađena u aplikaciju i tiho se ažurira sa GitHub-a kada ima mreže.

## Šta aplikacija radi

- **Vežbaj / Personalizuj vežbanje**: nasumični zadaci, po izboru oblasti i vrste (teorijski, računski, mešovito).
- **Formativna provera časa**: kratka provera po temi sa povratnom informacijom.
- **Test**: MASTER test od 16 pitanja (8 × N1, 5 × N2, 3 × N3; 7–9 teorijskih i 7–9 računskih; najmanje 2 grafika, 1 tabela i 1 šema), bez ponavljajućih obrazaca u odgovorima.
- **Moj napredak**: napredak po oblastima (čuva se lokalno, SQLite).

## Pokretanje

`android/` i `ios/` nisu u repou (osim ikonica), generišu se:

```sh
flutter create --platforms=android --org rs.fizika.gimnazija --project-name fizika_adaptivno_vezbanje .
rm -f test/widget_test.dart
flutter pub get
flutter run
```

Za Android build treba JDK 17+.

## Provere (iste kao u CI-ju)

```sh
python3 tool/validate_content.py
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --release
```

`dart format` pokretati tek posle `flutter pub get`, inače formatira drugačije nego CI.

## Sadržaj (baza pitanja)

- `assets/content/g1_fizika_1.3.0_PASS.json`: sva pitanja.
- `assets/content/manifest.json`: verzija, `current_unlock_order` i SHA-256 paketa.

Posle svake izmene JSON-a:

1. Upisati novi SHA-256 u `manifest.json` (`shasum -a 256 assets/content/g1_fizika_1.3.0_PASS.json`).
2. Pokrenuti `python3 tool/validate_content.py`.

Aplikacija preuzima `manifest.json` sa grane `main` i instalira novi paket samo ako se SHA-256 poklapa. Pogrešan hash znači da ažuriranje tiho ne prolazi.

**Otključavanje novih lekcija:** granica (`35`) je zapisana i u `manifest.json` i u `lib/presentation/screens/home_screen.dart` (dva mesta). Pre podizanja granice, pitanja KIN-000016, 000020, 000024 i 000036 treba prevesti sa `mixed`/`N4` na `theory`/`calculation` i `N1`–`N3`.

## CI

`.github/workflows/flutter-k7.yml` se pokreće na svaki PR ka `main`: Android (provere + APK, artifact `fizika-android-apk`) i iOS (build bez potpisivanja).

## Struktura

```
lib/domain/        adaptivni mehanizam, generator testa, napredak
lib/data/          SQLite, učitavanje i ažuriranje sadržaja
lib/presentation/  ekrani i widgeti
tool/              validacija sadržaja
```
