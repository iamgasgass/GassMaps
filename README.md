# GassMaps

Mappa del mondo reale in stile videogioco per iOS (SwiftUI + MapLibre), interfaccia interamente in **Liquid Glass nativo** (iOS 26).

## Funzioni

- **Splash** animata con logo GassMaps, icone fluttuanti e barra di caricamento
- **Mappa 3D** inclinata con edifici estrusi, nomi delle vie in maiuscolo, frecce dei sensi unici, numeri civici, scudi stradali (SS18…) e icone dei luoghi
- **Freccia utente** con croce di mira, rotazione secondo bussola o direzione di marcia
- **Intestazione** all'avvio con giorno, ora e "Città, Provincia", poi barra superiore con:
  - 🌍 Selezione mappa · 🔍 Ricerca · ◉ Impostazioni
- **Ricerca** con suggerimenti in tempo reale, *Cronologia* (con "Cancella") e *Trova nelle vicinanze* (stazione di servizio, ristorante, caffè, hotel, parcheggio, farmacia, supermercato, ospedale, bancomat, palestra)
- **Posizione fissata**: fumetto sulla mappa, indirizzo, scheda "Nessuno ha ancora esplorato questo posto", pulsanti *Salva* e *Ottieni indicazioni*
  - pulsante centrale blu = fissa la posizione attuale · pressione prolungata sulla mappa = fissa un punto
- **Indicazioni**: percorso viola, "La mia posizione → Posizione fissata", minuti, ETA, km, *Inizia ora*
- **Navigazione**: vista 3D che segue la marcia, arrivo / min / km aggiornati, *Termina percorso*. Arrivando a destinazione il luogo diventa "esplorato"
- **Posizioni salvate** (icona segnalibro)
- **Selezione mappa**: globo 3D che ruota, sfondo stellato, frecce, puntini e *Continua*. 8 temi:

  | # | Tema | Stile |
  |---|------|-------|
  | 1 | Dust Valley | seppia western |
  | 2 | **Vice Noir** (predefinito) | noir urbano grigio |
  | 3 | Bunker OS | terminale verde |
  | 4 | Pixel Land | mondo a blocchi |
  | 5 | Neon District | neon magenta/ciano |
  | 6 | Palm Coast | costa verde soleggiata |
  | 7 | Street Heat | viola notturno |
  | 8 | Old Kingdom | pergamena medievale |

- **Impostazioni**: unità di distanza (KM/MI), icona app (3 icone alternative), condividi, valutaci, community Discord, contattaci, privacy, termini, cancella i miei dati, ripristina acquisti

## Compilare l'IPA non firmata (GitHub Actions)

1. Crea un repository su GitHub e carica **tutto il contenuto** di questa cartella (compresa la cartella nascosta `.github`).
2. Il workflow `.github/workflows/build.yml` parte da solo a ogni push su `main` (oppure da **Actions → Build unsigned IPA → Run workflow**).
3. Al termine scarica l'artifact **GassMaps-unsigned-ipa** → contiene `GassMaps-unsigned.ipa`.
4. Firmala/installala con il tuo strumento (Feather, Sideloadly, AltStore, ESign, TrollStore…).
5. Se crei un tag `v1.0.0`, l'IPA viene pubblicata anche come **Release**.

Se la build fallisce, scarica l'artifact `xcodebuild-log` per vedere l'errore.

## Compilare in locale (Mac)

```bash
brew install xcodegen
xcodegen generate
open GassMaps.xcodeproj
```

## Personalizzazione

- Link (Discord, privacy, termini, email): `GassMaps/App/AppConfig.swift`
- Colori dei temi mappa: `tools/generate_styles.py` → poi `python3 tools/generate_styles.py`
- Nomi, sfondi e icone del globo dei temi: `GassMaps/Models/MapTheme.swift`
- Icone app: `tools/generate_icons.py`

## Dati mappa

Tile vettoriali gratuiti di [OpenFreeMap](https://openfreemap.org) (nessuna API key), dati © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors, rendering con [MapLibre Native](https://maplibre.org). Ricerca e percorsi tramite Apple MapKit.
L'attribuzione OSM resta visibile (pulsante ⓘ in basso a sinistra) come richiesto dalla licenza ODbL.

Requisiti: iOS 26+ (Liquid Glass nativo), iPhone. La build richiede Xcode 26 (il workflow usa il runner macos-26).
