# GassMaps

Mappa del mondo reale in stile videogioco per iOS (SwiftUI + MapLibre), interfaccia interamente in **Liquid Glass nativo** (iOS 26).

## Funzioni

- **Splash** che mostra l'app: città animata nei colori del tema scelto, percorso che si disegna, icone dei luoghi, freccia utente, logo GassMaps su vetro e barra di caricamento
- **Mappa 3D** inclinata con edifici estrusi, nomi delle vie in maiuscolo, frecce dei sensi unici, numeri civici, scudi stradali (SS18…) e icone dei luoghi
- **Freccia utente** uguale in tutti i temi (croce di mira, rotazione secondo bussola o direzione di marcia); in Pixel Land è una freccia pixelata a blocchi
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
  | 9 | Silent Contract | mappa tattica grigia, icone quadrate nere |
  | 10 | Storm Isle | isola cartoon: prati, boschi, sentieri di sabbia, fiumi |
  | 11 | Midnight Route | guida notturna indaco, edifici 3D blu, nomi delle vie nei fumetti, luoghi colorati |

- **Impostazioni** organizzate come Google Maps, in Liquid Glass:
  - *App e display*: tema della mappa, icona app, unità di distanza, bussola, scala, vista inclinata 3D, feedback aptico, accessibilità
  - *Navigazione*: indicazioni vocali, volume e velocità della voce, prova voce, evita autostrade/pedaggi, tachimetro, schermo acceso, modalità predefinita
  - *I tuoi veicoli*: tipo di motore (con auto elettrica/plug-in i pulsanti rapidi propongono la ricarica), veicoli connessi
  - *Posizione e privacy*: stato e precisione della posizione, luoghi esplorati, parcheggio, cronologia (salvataggio e cancellazione), Casa/Lavoro, cancella i miei dati
  - *Mappe offline*: scarica la zona visibile con il tema attuale, avanzamento, aggiorna, elimina, svuota cache
  - *Notifiche*: promemoria parcheggio (1–8 ore), consigli settimanali
  - *Informazioni e termini*: versione, termini, privacy, note legali, valuta l'app, condividi, Discord, contattaci, ripristina acquisti

## Funzioni stile Google Maps

- **Scheda del luogo**: nome, categoria, indirizzo, distanza e tempi in auto/a piedi; pulsanti *Indicazioni*, *Avvia*, *Chiama*, *Salva*, *Condividi*, *Sito web*; menu ••• con *Imposta come Casa/Lavoro*, copia coordinate e indirizzo
- **Tocco sulle icone della mappa** → si apre la scheda del luogo (telefono e sito recuperati automaticamente)
- **Indicazioni**: schede *Auto / A piedi / Mezzi* con i tempi, **percorsi alternativi** (grigi, toccabili sulla mappa o nell'elenco) con "Più veloce", via, pedaggi, autostrade e avvisi; **opzioni** *Evita pedaggi* / *Evita autostrade*; elenco **Passaggi**
- **Navigazione svolta per svolta**: banner con freccia della manovra, distanza e istruzione, "Poi…" per la manovra successiva, **guida vocale in italiano** (disattivabile), **ricalcolo automatico** se esci dal percorso, velocità attuale, tempo/km/orario di arrivo aggiornati, vista d'insieme, ricentra, arrivo a destinazione; funziona anche **a schermo spento**
- **Ricerca**: suggerimenti, invio → elenco risultati sulla mappa con segnaposto; **chip rapidi** (Ristoranti, Benzina, Caffè, Supermercati, Hotel, Farmacie, Parcheggi, Bancomat, Ospedali)
- **Casa e Lavoro** con indicazioni in un tocco; cronologia; posizioni salvate
- **Bussola**: compare quando ruoti la mappa, tocco per tornare al nord
- **Partenza modificabile**, **inverti partenza/destinazione**, **aggiungi tappa** e **orario di partenza** (parti ora o scegli data/ora)
- **Cerca in questa zona** quando sposti la mappa sui risultati; la ricerca usa l'area visibile della mappa
- **Cerca lungo il percorso** durante la navigazione (benzinai, ristoranti, caffè, supermercati, parcheggi, ricarica) con aggiunta della tappa
- **Condividi orario di arrivo** durante la navigazione
- **Salva parcheggio**: ricorda dove hai lasciato l'auto e ti ci riporta
- **Posizione in tempo reale ottimizzata**: Core Location alla massima precisione ("per la navigazione": GPS, Galileo, GLONASS, BeiDou, Wi-Fi, celle), richiesta di precisione completa se è attiva quella approssimativa, filtro di Kalman contro i salti, direzione di marcia calcolata anche senza bussola; la freccia sulla mappa usa la stessa posizione filtrata della navigazione.
  Nota: su iPhone non esiste un "GPS di Google" separato: anche Google Maps per iOS riceve la posizione da Core Location.

- **Navigazione come Google Maps**: freccia posizionata in basso così da vedere più strada davanti, tratto già percorso che sparisce, zoom automatico secondo la velocità
- **Livelli**: mappa del tema o satellite (con strade ed etichette sopra), trasporti pubblici, piste ciclabili
- **Misura distanza** (menu ••• di un luogo): mirino al centro, aggiungi punti, annulla, distanza totale
- **Plus Code** nella scheda del luogo (copiabile), **ricerca per coordinate** ("40.85, 14.26")
- **Ricerca vocale** in italiano (microfono nella barra di ricerca)
- **Elenchi** (Preferiti, Da visitare, Luoghi speciali) e **note personali** sui luoghi; filtri nelle Posizioni salvate
- **Avatar di guida** (Impostazioni → I tuoi veicoli): *Default* (freccia del tema) o *Alternative* (disco blu con freccia bianca), versione a blocchi in Pixel Land
- **La tua posizione**: tocco sulla freccia → indirizzo, precisione, salva parcheggio, condividi, calibra bussola, nelle vicinanze

Limiti (dati non disponibili gratuitamente fuori da Google): traffico in tempo reale, Street View, recensioni e foto dei luoghi,
orari di apertura, tracciato dei mezzi pubblici (per i mezzi l'app mostra il tempo e apre linee e orari in Mappe di Apple), mappe offline.

## Font di GTA San Andreas (Pricedown)

La scritta **GassMaps** della splash usa il font *Pricedown* (quello di GTA San Andreas).
Per licenza non può essere incluso nel repo: scaricalo gratis da Typodermic
(https://typodermicfonts.com/pricedown/) e copia il file `.ttf`/`.otf` in `GassMaps/Fonts/`.
L'app lo trova da sola (nessuna modifica necessaria) e lo usa anche per le etichette del globo dei temi GTA.
Senza il file viene usato un sostituto simile.

## Contenuti di ogni mappa

Ogni tema ha il proprio set di icone sulla mappa e sul globo, nello stile del gioco a cui si ispira:
Vice Noir (radar GTA V, quadrifoglio viola), Palm Coast (icone colorate GTA SA), Dust Valley (badge western),
Bunker OS (esagoni verdi), Pixel Land (oggetti pixelati), Neon District (esagoni neon), Street Heat (corse),
Old Kingdom (medievale). Le categorie: parchi, cinema/teatri, stazioni, biblioteche, carburante, ristoranti,
caffè, bar, negozi, abbigliamento, salute, polizia, banche, alloggi, scuole, parcheggi, sport, luoghi di culto,
musei/attrazioni, auto.

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

Il tema Street Heat usa le immagini satellitari Esri World Imagery (© Esri, Maxar, Earthstar Geographics),
gratuite con attribuzione: per un uso commerciale verifica i termini Esri.
Tile vettoriali gratuiti di [OpenFreeMap](https://openfreemap.org) (nessuna API key), dati © [OpenStreetMap](https://www.openstreetmap.org/copyright) contributors, rendering con [MapLibre Native](https://maplibre.org). Ricerca e percorsi tramite Apple MapKit.
L'attribuzione OSM resta visibile (pulsante ⓘ in basso a sinistra) come richiesto dalla licenza ODbL.

Requisiti: iOS 26+ (Liquid Glass nativo), iPhone. La build richiede Xcode 26 (il workflow usa il runner macos-26).
