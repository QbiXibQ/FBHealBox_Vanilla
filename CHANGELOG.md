# Changelog

## 1.4.4 (unreleased)

Performance pass. No feature was added or changed; every visible behaviour is meant to be identical. A simulated five-second raid fight (40 players, aura and health events, mana changes, combat log, 60 frames per second) went from about 63,900 API and widget calls to about 14,450, a reduction of 77 %.

### English

**Changed (internals)**

- **Button states centralised.** The up to 260 heal buttons (10 plates x 10, 40 raid cells x 4) no longer carry their own `SPELL_UPDATE_USABLE` / `SPELL_UPDATE_COOLDOWN` handlers. One pass over the *visible* buttons queries usability and cooldown once per spell id and range once per button, and sets colours and cooldown sweeps only when the state changes. Several such events within one frame are merged into one pass.
- **Display caches.** Health text, bar maxima, bar values, bar colour and mana strip visibility are only written when they change. Dispellable debuffs are searched on `UNIT_AURA` only; `UNIT_HEALTH` and the prediction tick reuse the last result.
- **Aura scans shared.** A unit's buff textures are read once per frame and shared between the heal prediction and the buff watch. Buff names resolved through tooltip scans are remembered per texture, so a unit missing the watched buff no longer costs up to 32 tooltip scans per aura event. Raid units are only scanned when something depends on them (own cast pending, tracked HoT or shield, or a visible cell).
- **Cheaper ticks.** Spell timers use precomputed base spell names instead of string parsing per button per tick and skip units without tracked HoTs or shields. Buff icons reuse their work tables, iterate a presorted list instead of sorting per tick, and update on change or once a second instead of five times a second. The attacked-member check skips entirely while there is no hostile target and nothing is marked, and compares names before calling `UnitIsUnit`.
- **Event bursts coalesced.** `PARTY_MEMBERS_CHANGED`, `UNIT_PET` and `RAID_ROSTER_UPDATE` set a flag that is processed once in the next frame instead of rebuilding plates and grid for every event of a burst.
- **Mana ticker.** Enabled/mana/full checks moved from every frame to mana events and option changes; the spark is re-anchored only when it has moved at least half a pixel; sizes and visibility are cached.
- **Combat log.** Heal patterns run only for buff events, the absorb pattern only for hit events that contain the word absorbed. Smart Damage parses damage lines only while enabled and while there is a target being measured or an own cast waiting; its live target line is refreshed only while the options window is open.
- Raid test ghost animation frame is hidden outside the raid test instead of running an empty update every frame.
- **Client API compatibility.** `IsSpellInRange` and `IsUsableSpell` do not exist in the 1.12 client (they came with 2.0). All range and usability checks now go through wrappers that use them when a client offers them and otherwise fall back to 1.12 means: spell range from the tooltip against `UnitXP("distanceBetween")` where available, else `CheckInteractDistance` (28 m, beyond that undecided rather than red); mana cost from the tooltip against your current mana. Because clients differ (2.0 style `(id, "spell", unit)` versus the Turtle client's `(name, unit)`), the addon probes both signatures once at login with `pcall` and uses the one the client understands; a function that keeps throwing is switched off in favour of the fallback. `/fbp` reports the detected form. Without this the new central button pass crashed at login.

**Fixed**

- The old per-button event handler declared `this`, `event` and `arg1` as parameters, which shadowed the 1.12 globals; range colouring and cooldown sweeps on the buttons never worked in the game. They do now.

### Deutsch

**Geaendert (intern)**

- **Button-Zustaende zentral.** Die bis zu 260 Heil-Buttons (10 Plaketten x 10, 40 Raid-Zellen x 4) tragen keine eigenen `SPELL_UPDATE_USABLE`/`SPELL_UPDATE_COOLDOWN`-Handler mehr. Ein Durchgang ueber die *sichtbaren* Buttons fragt Nutzbarkeit und Cooldown je Zauber-ID einmal und die Reichweite je Button ab und setzt Farben und Cooldown-Uhren nur bei Zustandswechsel. Mehrere solche Events in einem Frame werden zu einem Durchgang zusammengefasst.
- **Anzeige-Zwischenspeicher.** Lebenstext, Balkenmaxima, Balkenwerte, Balkenfarbe und Sichtbarkeit des Manastreifens werden nur geschrieben, wenn sie sich aendern. Entfernbare Debuffs werden nur bei `UNIT_AURA` gesucht; `UNIT_HEALTH` und der Vorhersage-Tick nutzen den letzten Befund.
- **Aura-Scans gemeinsam.** Die Buff-Texturen einer Einheit werden je Frame einmal gelesen und von Heilvorhersage und Buff-Wache geteilt. Per Tooltip ermittelte Buffnamen werden je Textur gemerkt, sodass eine Einheit ohne den ueberwachten Buff nicht mehr bis zu 32 Tooltip-Scans je Aura-Event kostet. Raid-Einheiten werden nur gescannt, wenn etwas davon abhaengt (eigener Cast wartet, HoT oder Schild verfolgt, sichtbare Zelle).
- **Guenstigere Ticks.** Zauber-Timer nutzen vorberechnete Basisnamen statt String-Parsing je Button und Tick und ueberspringen Einheiten ohne verfolgten HoT oder Schild. Buff-Icons verwenden ihre Arbeitstabellen wieder, laufen ueber eine vorsortierte Liste statt je Tick zu sortieren und aktualisieren bei Aenderung oder einmal je Sekunde statt fuenfmal. Der Angegriffenen-Abgleich entfaellt ganz, solange kein feindliches Ziel besteht und nichts markiert ist, und vergleicht Namen, bevor `UnitIsUnit` gerufen wird.
- **Event-Salven zusammengefasst.** `PARTY_MEMBERS_CHANGED`, `UNIT_PET` und `RAID_ROSTER_UPDATE` setzen ein Kennzeichen, das im naechsten Frame einmal abgearbeitet wird, statt Plaketten und Raster bei jedem Event einer Salve neu aufzubauen.
- **Mana-Ticker.** Die Pruefungen an/Mana/voll laufen bei Mana-Events und Optionswechseln statt jeden Frame; der Funke wird nur neu verankert, wenn er sich mindestens einen halben Pixel bewegt hat; Groessen und Sichtbarkeit sind zwischengespeichert.
- **Combatlog.** Heilmuster laufen nur bei Buff-Events, das Absorb-Muster nur bei Treffer-Events, die das Wort absorbed enthalten. Smart Damage liest Schadenszeilen nur, solange es an ist und ein Ziel vermessen wird oder ein eigener Cast wartet; die Live-Zielzeile wird nur bei offenem Optionsfenster aktualisiert.
- Der Animationsframe der Raid-Testgeister ist ausserhalb des Raid-Tests ausgeblendet, statt jeden Frame leer zu laufen.
- **Client-API-Kompatibilitaet.** `IsSpellInRange` und `IsUsableSpell` gibt es im 1.12-Client nicht (sie kamen mit 2.0). Alle Reichweiten- und Nutzbarkeitspruefungen laufen jetzt ueber Wrapper, die sie nutzen, wenn ein Client sie anbietet, und sonst auf 1.12-Mittel zurueckfallen: Zauberreichweite aus dem Tooltip gegen `UnitXP("distanceBetween")`, wo vorhanden, sonst `CheckInteractDistance` (28 m, jenseits davon unentschieden statt rot); Manapreis aus dem Tooltip gegen das eigene Mana. Weil Clients sich unterscheiden (2.0-Form `(id, "spell", unit)` gegenueber der Turtle-Form `(name, unit)`), probiert das Addon beide Signaturen beim Login einmal per `pcall` aus und nutzt die verstandene; eine Funktion, die weiter Fehler wirft, wird zugunsten des Rueckfalls abgeschaltet. `/fbp` meldet die erkannte Form. Ohne das brach der neue zentrale Button-Durchgang beim Login ab.

**Behoben**

- Der alte Button-Handler deklarierte `this`, `event` und `arg1` als Parameter und verdeckte damit die 1.12-Globals; Reichweitenfaerbung und Cooldown-Uhr auf den Buttons haben im Spiel nie gearbeitet. Jetzt tun sie es.


## 1.4.3 (2026-09-05)

### English

**New**

- **Languages.** Spanish, French and Italian added to all addon texts (English and German unchanged). The client locale picks the language automatically, the language button lists all five, missing keys fall back to English.
- **Mana ticker** (module `FBHealBox_Ticker.lua`, on by default). A spark travels across your own mana strip every 2 seconds in step with the server's regeneration tick; after spending mana it turns orange and runs the five-second rule down, extended to the first tick after the five seconds. Works on the party plate and on your own raid cell, hidden while mana is full. Detection via `UNIT_MANA` only: grid from observed ticks, re-sync within a tolerance, foreign pulses (totems, Innervate) ignored, potions and runes filtered by size. Own options tab *Ticker*: master switch, five-second rule, tick tolerance, tick offset, spark width. `/fbp ticker` toggles, `/fbp` reports sync state.
- **Smart Healing** (off by default). When on, a click casts the lowest rank of the assigned spell whose expected heal covers the target's missing health (minus incoming healing) plus a safety margin (default 20 %). Never above the assigned rank, direct heals only, always the assigned rank below 30 % health. Learned heal values are used where available. Downsides (no crits in the estimate, burst damage, deliberate overhealing) are explained in the tooltip. Options on the *Buttons* tab; `/fbp debug` logs each decision, `/fbp` shows the state.
- **Cooldown sweep on buttons**, global cooldown excluded. Option *Cooldowns on buttons*.
- **Red border for the attacked member**: the plate or raid cell of the unit your hostile target is targeting. Takes precedence over the buff-watch border. Option *Mark who is attacked*.
- **HoT and shield timers on buttons**: each spell's button shows the remaining seconds of your own HoT (green) or shield (blue) on that unit; after Power Word: Shield the button shows Weakened Soul in red. Option *HoT and shield timers*.
- **Smart Damage** (module `FBHealBox_Damage.lua`, off by default). Attack spells pressed on any action bar or key binding are cast in the lowest rank that still kills the target, never above the rank on the bar. Target health from the server (real values), MobHealth3, MobInfo-2, or the addon's own per-mob-type estimate learned from combat-log damage and percent drops (highest measurement kept). Minimum damage per rank from the tooltip, raised by observed full hits. Section on the *Extras* tab (shared with the ticker) with switch, safety margin, live health-source line and spell list; `/fbp damage`, decisions in `/fbp debug`.
- **Buff icons in the health bar**: buffs with a duration that sit on your buttons (Fortitude, Divine Spirit, Fear Ward, Inner Fire) appear as small 8 px icons on the outer left side of the plate. The icon is a clock: it turns black and white clockwise from twelve o'clock as the time runs out (half left = right half grey). Exact on yourself, counted from your own cast on others, fully coloured when cast by someone else. Raid cells show them outside their left edge; the grid reserves the room. Line-of-sight badge moved to the plate's top-left corner. Units are scanned once after login and group changes so existing buffs appear immediately. `/fbp buffs` for diagnostics. Option *Buff icons in the health bar*.
- Test-mode ghost Dorn demonstrates the red border and the timers.

**Fixed**

- Own buffs were only read at login and on group changes: Vanilla fires `PLAYER_AURAS_CHANGED` for the player instead of `UNIT_AURA`. The addon now listens to it and re-reads your remaining time on every change, and once a second in between (a refresh of a running buff fires no aura event at all), so recasting a buff on yourself resets its clock and cancelling it removes the icon. Refreshing a buff on someone else through a HealBox button is confirmed by the completed cast. Also fixes confirmation of your own HoTs and shields on yourself.
- Raid cell names and percentages were hidden behind the health bar since the bar levels became relative; the texts now live on their own layer above the bars.
- Buff icons stack two high left of the plate; elapsed clock quadrants are drawn dark on a layer above the icon so the split shows on every client. Raid cells use a 3 by 4 grid of 6 px icons (twelve slots); the new raid option *Show buffs* removes icons and strip together. `/fbp buffs` reports the grey count per icon.
- Test modes extended: party ghost Brynn is dead, pet Bramble carries a disease, Dorn carries six and raid ghost 12 twelve buffs, raid ghost 27 a disease. Up to six buff icons per plate.
- Plate names could sit too low on some rows (the name box grew to two lines internally). Name, paw icon and debuff icon are now vertically centred with a fixed one-line height.

- Tooltip parser took durations ("for 30 min", "again for 15 sec") for direct heal amounts, so buffs such as Power Word: Fortitude and the shield reported a tiny "heal" and Smart Healing downranked them. Durations are ignored now, and Smart Healing only touches spells whose tooltip describes a heal and that carry no absorb.

**Changed**

- Option tab buttons are 100 px wide (was 110) so that four tabs fit in the window; class icon shrunk so it no longer overlaps the tabs. Checkbox labels have a fixed width and end with an ellipsis when a translation is long; the tooltip carries the full text. The fourth tab is called *Extras* and holds the ticker and Smart Damage sections.
- Tooltip parser: only `hr`/`hour` count as hours; `Holy` no longer looks like a time unit.
- New core hooks `Loaded`, `Aggro`, `SpellTimers`, `Cooldowns` for modules.

### Deutsch

**Neu**

- **Sprachen.** Spanisch, Franzoesisch und Italienisch fuer alle Addon-Texte hinzugefuegt (Englisch und Deutsch unveraendert). Die Client-Sprache waehlt automatisch, der Sprachknopf listet alle fuenf, fehlende Schluessel fallen auf Englisch zurueck.
- **Mana-Ticker** (Modul `FBHealBox_Ticker.lua`, standardmaessig an). Ein Funke wandert alle 2 Sekunden im Takt des Regenerationsticks ueber deinen eigenen Manastreifen; nach Manaverbrauch wird er orange und laeuft die Fuenf-Sekunden-Regel herunter, verlaengert bis zum ersten Tick nach den fuenf Sekunden. Auf der Gruppenplakette und der eigenen Raid-Zelle, bei vollem Mana ausgeblendet. Erkennung nur ueber `UNIT_MANA`: Raster aus beobachteten Ticks, Neusynchronisation innerhalb einer Toleranz, fremde Pulse (Totems, Anregen) ignoriert, Traenke und Runen nach Groesse gefiltert. Eigener Options-Reiter *Ticker*: Hauptschalter, Fuenf-Sekunden-Regel, Tick-Toleranz, Tick-Vorlauf, Funkenbreite. `/fbp ticker` schaltet um, `/fbp` meldet den Synchronzustand.
- **Smart Healing** (standardmaessig aus). Eingeschaltet wirkt ein Klick den niedrigsten Rang des belegten Zaubers, dessen erwartete Heilung das fehlende Leben des Ziels (abzueglich eingehender Heilung) plus Sicherheitsaufschlag (Standard 20 %) deckt. Nie ueber dem belegten Rang, nur Direktheilungen, unter 30 % Leben immer der belegte Rang. Gelernte Heilwerte werden genutzt, wo vorhanden. Nachteile (keine Crits in der Schaetzung, Schadensspitzen, gewolltes Ueberheilen) erklaert der Tooltip. Optionen im Reiter *Buttons*; `/fbp debug` protokolliert jede Entscheidung, `/fbp` zeigt den Zustand.
- **Cooldown-Uhr auf den Buttons**, globaler Cooldown ausgenommen. Option *Cooldowns auf den Buttons*.
- **Roter Rahmen fuer den Angegriffenen**: Plakette oder Raid-Zelle der Einheit, die dein feindliches Ziel im Ziel hat. Hat Vorrang vor dem Buff-Wache-Rahmen. Option *Angegriffenen markieren*.
- **HoT- und Schild-Timer auf den Buttons**: Der Button jedes Zaubers zeigt die Restsekunden deines eigenen HoTs (gruen) oder Schilds (blau) auf dieser Einheit; nach Machtwort: Schild zeigt der Button rot die Geschwaechte Seele. Option *HoT- und Schild-Timer*.
- **Smart Damage** (Modul `FBHealBox_Damage.lua`, standardmaessig aus). Angriffszauber auf jeder Aktionsleiste oder Taste werden im niedrigsten Rang gewirkt, der das Ziel noch toetet, nie ueber dem Rang auf der Leiste. Ziel-Leben vom Server (echte Werte), MobHealth3, MobInfo-2 oder aus der eigenen Schaetzung je Mobtyp, gelernt aus Combatlog-Schaden und Prozentabfall (hoechste Messung zaehlt). Mindestschaden je Rang aus dem Tooltip, angehoben durch beobachtete Volltreffer. Abschnitt im Reiter *Extras* (gemeinsam mit dem Ticker) mit Schalter, Sicherheitsaufschlag, Live-Zeile zur Lebensquelle und Zauberliste; `/fbp damage`, Entscheidungen in `/fbp debug`.
- **Buff-Icons im Lebensbalken**: Buffs mit Laufzeit, die auf deinen Buttons liegen (Seelenstaerke, Goettlicher Willen, Furchtzauberschutz, Inneres Feuer), erscheinen als kleine 8-px-Icons aussen links neben der Plakette. Das Icon ist eine Uhr: Es wird im Uhrzeigersinn ab zwoelf Uhr schwarz-weiss, je weiter die Zeit ablaeuft (halbe Zeit = rechte Haelfte grau). Exakt bei dir selbst, ab deinem eigenen Cast bei anderen, ganz farbig bei fremdem Cast. Raid-Zellen zeigen sie aussen an ihrer linken Kante; das Raster haelt den Platz frei. Sichtlinien-Abzeichen in die linke obere Plattenecke verlegt. Nach Login und Gruppenwechsel werden alle Einheiten einmal gescannt, damit vorhandene Buffs sofort erscheinen. `/fbp buffs` zur Diagnose. Option *Buff-Icons im Lebensbalken*.
- Testmodus-Geist Dorn zeigt roten Rahmen und Timer.

**Behoben**

- Eigene Buffs wurden nur beim Login und bei Gruppenwechseln gelesen: Vanilla feuert fuer den Spieler `PLAYER_AURAS_CHANGED` statt `UNIT_AURA`. Das Addon hoert jetzt darauf und liest die eigene Restzeit bei jeder Aenderung neu, und dazwischen einmal je Sekunde (ein Refresh eines laufenden Buffs feuert gar kein Aura-Event), sodass ein Neucast auf dich selbst die Uhr zuruecksetzt und ein Wegklicken das Icon entfernt. Ein Refresh auf jemand anderen ueber einen HealBox-Button gilt mit dem abgeschlossenen Cast als bestaetigt. Behebt auch die Bestaetigung eigener HoTs und Schilde auf dir selbst.
- Namen und Prozente der Raid-Zellen lagen seit den relativen Balken-Ebenen hinter dem Lebensbalken; die Texte liegen jetzt auf einer eigenen Ebene ueber den Balken.
- Buff-Icons stapeln sich zu zweit links neben der Plakette; abgelaufene Uhr-Quadranten werden dunkel auf einer Ebene ueber dem Icon gezeichnet, damit die Teilung auf jedem Client sichtbar ist. Raid-Zellen nutzen ein 3-mal-4-Raster aus 6-px-Icons (zwoelf Plaetze); die neue Raid-Option *Buffs anzeigen* entfernt Icons und Streifen gemeinsam. `/fbp buffs` nennt je Icon die Zahl grauer Quadranten.
- Testmodi erweitert: Partygeist Brynn ist tot, Pet Bramble traegt eine Krankheit, Dorn traegt sechs und Raid-Geist 12 zwoelf Buffs, Raid-Geist 27 eine Krankheit. Bis zu sechs Buff-Icons je Plakette.
- Plakettennamen sassen in manchen Zeilen zu tief (die Namensbox wuchs intern auf zwei Zeilen). Name, Pfoten-Icon und Debuff-Icon sind jetzt mit fester Einzeilenhoehe vertikal zentriert.

- Der Tooltip-Leser hielt Zeitangaben ("for 30 min", "again for 15 sec") fuer Heilbetraege, wodurch Buffs wie Machtwort: Seelenstaerke und der Schild eine winzige "Heilung" meldeten und Smart Healing sie abgerangt hat. Zeitangaben werden jetzt uebersprungen, und Smart Healing fasst nur Zauber an, deren Tooltip eine Heilung beschreibt und die keinen Absorb haben.

**Geaendert**

- Reiterknoepfe der Optionen sind 100 px breit (vorher 110), damit vier Reiter ins Fenster passen; Klassen-Icon verkleinert, damit es die Reiter nicht mehr ueberlagert. Schalterbeschriftungen haben eine feste Breite und enden bei langen Uebersetzungen mit Auslassungspunkten; der Tooltip traegt den vollen Text. Der vierte Reiter heisst *Extras* und enthaelt Ticker und Smart Damage.
- Tooltip-Leser: Nur `hr`/`hour` zaehlen als Stunden; `Holy` sieht nicht mehr wie eine Zeiteinheit aus.
- Neue Kern-Hooks `Loaded`, `Aggro`, `SpellTimers`, `Cooldowns` fuer Module.

## 1.4.2 (2026-09-05)

### English

**New: raid mode** (module `FBHealBox_Raid.lua`, on by default, switches in automatically from 11 raid members; *Raid view from N players* is adjustable)

- Compact grid for 20 and 40 player raids: one cell per member in blocks of five per raid group, blocks arranged in rows (*Groups per row*). Empty groups collapse, so a 20-player raid is a single row.
- Each cell: name in class colour, health bar with shield and incoming-heal layers, 3 px mana strip, HP percent or deficit, dispel colouring, dead/ghost/offline text, range fading, line-of-sight eye, buff-watch border.
- Up to four mini buttons per cell, wired to Button 1 to N from the Buttons tab (right-click spells included). Click on a cell targets the unit (or unit menu / move / nothing, as configured for plates).
- Own options tab *Raid mode* with size, spacing, scale, headers, mana strip, HP text mode, title bar, hide-empty-groups and hide-party-plates switches.
- Raid test with 20 or 40 ghosts covering every visual state. `/fbp raid`, `/fbp raidtest 20|40|off`, raid line in `/fbp`.
- Grid position and scale are saved separately from the party plates. Party plates are hidden while the grid is up (switchable).

**New: drag and drop.** Spells can be dragged from the spellbook onto any heal button, raid mini button or options field. Right mouse button, or Shift held while dropping, fills the right-click side when that option is on. Spells outside the class list are accepted.

**Fixed**

- **Double loading.** The `.xml` included `FBHealBox.lua` a second time on top of the `.toc`. Every frame, hook and the options window existed twice. Visible effects: the raid tab was missing (added to the first, overwritten options window), Escape could crash the client (the second hook called itself), and learned absorb values were doubled (two prediction frames counted every absorb line). The `.xml` no longer loads scripts, and both Lua files refuse to run twice.
- Escape hook stores the original in a local upvalue, is installed at most once, and no longer uses a tail call.
- Learned absorb values above 1.5 times the tooltip are dropped on load; doubled values from earlier versions clean themselves up.

**Changed**

- Core gained a hook interface (`FBHealBox_RegisterHook`, `FBHealBox_AddOptionsTab`) so modules can attach without editing the core. No behaviour change for the party display.
- `.toc` now loads `FBHealBox_Raid.lua` after the core; removing that line disables raid mode entirely.

### Deutsch

**Neu: Raidmodus** (Modul `FBHealBox_Raid.lua`, standardmaessig an, schaltet ab 11 Raidmitgliedern automatisch um; *Raid-Ansicht ab N Spielern* ist einstellbar)

- Kompaktes Raster fuer 20er- und 40er-Raids: eine Zelle je Mitglied in Fuenferbloecken je Gruppe, die Bloecke in Zeilen (*Gruppen je Zeile*). Leere Gruppen fallen weg, ein 20er-Raid ist also eine einzige Zeile.
- Jede Zelle: Name in Klassenfarbe, Lebensbalken mit Schild- und Vorhersage-Schicht, 3 px Manastreifen, HP-Prozent oder Defizit, Dispel-Faerbung, Tot/Geist/Offline, Reichweiten-Fading, Sichtlinien-Auge, Buff-Wache-Rahmen.
- Bis zu vier Mini-Buttons je Zelle, belegt wie Button 1 bis N aus dem Reiter Buttons (Rechtsklick-Zauber inklusive). Klick auf die Zelle visiert an (oder Einheitenmenue / Verschieben / Nichts, wie fuer Plaketten eingestellt).
- Eigener Options-Reiter *Raidmodus* mit Groesse, Abstaenden, Skalierung, Gruppenkoepfen, Manastreifen, HP-Text-Modus, Titelleiste, Leere-Gruppen- und Plaketten-Ausblenden-Schaltern.
- Raid-Test mit 20 oder 40 Geistern, die jeden Anzeigezustand abdecken. `/fbp raid`, `/fbp raidtest 20|40|off`, Raid-Zeile in `/fbp`.
- Position und Skalierung des Rasters werden getrennt von den Plaketten gespeichert. Die Gruppenplaketten sind ausgeblendet, solange das Raster steht (abschaltbar).

**Neu: Drag & Drop.** Zauber lassen sich aus dem Zauberbuch auf jeden Heil-Button, Raid-Mini-Button oder jedes Optionsfeld ziehen. Die rechte Maustaste oder gehaltene Shift-Taste beim Ablegen fuellt die Rechtsklick-Seite, wenn die Option an ist. Zauber ausserhalb der Klassenliste werden angenommen.

**Behoben**

- **Doppeltes Laden.** Die `.xml` band `FBHealBox.lua` zusaetzlich zur `.toc` ein zweites Mal ein. Jeder Frame, jeder Hook und das Optionsfenster existierten doppelt. Sichtbare Folgen: der Raid-Reiter fehlte (an das erste, ueberschriebene Optionsfenster gehaengt), Escape konnte den Client zum Absturz bringen (der zweite Hook rief sich selbst auf), und gelernte Absorb-Werte waren verdoppelt (zwei Vorhersage-Frames zaehlten jede Absorb-Zeile). Die `.xml` laedt keine Skripte mehr, beide Lua-Dateien verweigern einen zweiten Durchlauf.
- Der Escape-Hook haelt das Original in einem lokalen Upvalue, wird hoechstens einmal gesetzt und nutzt keinen Tail-Call mehr.
- Gelernte Absorb-Werte ueber dem 1,5-fachen des Tooltips werden beim Laden verworfen; verdoppelte Werte aus frueheren Versionen bereinigen sich selbst.

**Geaendert**

- Der Kern hat eine Hook-Schnittstelle bekommen (`FBHealBox_RegisterHook`, `FBHealBox_AddOptionsTab`), damit Module andocken koennen, ohne den Kern zu aendern. Kein Verhaltensunterschied fuer die Gruppenanzeige.
- Die `.toc` laedt `FBHealBox_Raid.lua` nach dem Kern; wer die Zeile entfernt, hat keinen Raidmodus.

## 1.4.1 (2026-09-04)

### English

**New**

- **Pets.** Every pet in the group (`pet`, `partypet1` to `partypet4`) gets its own plate with the full set of heal buttons, stacked directly below its owner, indented by 12 px, with a paw icon and a light-blue name to tell it apart. Appears and disappears with `UNIT_PET`. Option *Show pets*.
- **Mana bar.** A 5 px blue bar along the bottom edge of the health bar ("bar in bar"), only for units whose power type is mana. Option *Mana bar*.
- **Button and row spacing.** Two sliders, 0 to 20 px each, for the gap between buttons and the gap between plates.
- **Test mode.** Fills the display with ghost players and pets (health, mana, shield, incoming heal, dispellable debuff, missing buff, out of range) so the layout can be arranged without a group. `/fbp test` or the checkbox. Not saved.
- **Options window with two tabs.** *Buttons* holds the button assignment, the button count and the right-click switch; *General* holds scale, spacing, all other switches, language and buff watch.
- **Right-click spell.** Every button can carry a second spell for right click. Off by default and only enabled through the *Buttons* tab; when on, a second column appears in the assignment and a small corner icon on each button shows the right-click spell. Assignments are kept when the switch is off.
- **Click on a plate.** Left and right click on a name or health bar target the unit by default. Both are configurable (*General* tab): Target, Unit menu, Move display, Nothing. Moving the display is now Shift + left drag (or the *Move display* action).
- **Dead / ghost / offline.** Shown as text in the bar instead of 0 %, with an empty grey bar and no mana strip.
- **Line of sight.** An eye badge on the plate's left edge while the unit is out of line of sight: live via the UnitXP client mod, otherwise inferred from the 'not in line of sight' error after your own heal attempt (8 s, cleared when a cast starts or a heal lands). Option *Line of sight*.
- **Debuff icon.** The icon of the first debuff your class can remove is shown next to the name, with its stack count. Option *Debuff icon*.
- **Class colours.** Names in class colour (client `RAID_CLASS_COLORS`, fallback table built in). Option *Class colours*.
- **Buff watch.** Pick one of your buffs; every plate whose unit is missing it gets an orange border. Group versions count as well, even when cast by another healer (texture check first, tooltip name scan as fallback). Pets are excluded unless *Buff watch on pets* is on.
- **Range fading.** Plates including their buttons fade to 50 % when the unit is out of range of your first assigned spell (28 yards without a spell). Option *Range fading*.
- **`/fbp config`** opens the options window; **Escape** closes it (registered in `UISpecialFrames`, plus a hook on `ToggleGameMenu` for clients that ignore that list). `/fbp` ends with a list of all commands.
- **Saved plate position.** The player plate keeps its position across reloads; scaling no longer moves it.

**Changed**

- All UNIT events run through one slot table (`FBPartyUnit`) instead of five copied handlers; `HealBoxAttachMode` and `FBUpdateNames` are loops.
- Spell buttons are created once and only re-assigned afterwards (previously rebuilt on every `SPELLS_CHANGED`, with random global names like `Button3`).
- Settings missing in an old saved-variables table are filled in on load (`FBHealBox_ApplyDefaults`).
- `UNIT_MAXHEALTH` is handled (was missing).

**Fixed**

- Documentation named a wrong client version; the addon targets client 1.12.1.
- Tooltip error on a button whose target does not exist.
- Division by zero for offline members (`UnitHealthMax` = 0).
- Plate position reset on every login.

### Deutsch

**Neu**

- **Begleiter.** Jeder Begleiter in der Gruppe (`pet`, `partypet1` bis `partypet4`) bekommt eine eigene Plakette mit allen Heil-Buttons, direkt unter seinem Besitzer, um 12 px eingerueckt, mit Pfoten-Icon und hellblauem Namen zur Unterscheidung. Kommt und geht mit `UNIT_PET`. Option *Begleiter anzeigen*.
- **Manabalken.** 5 px blau am unteren Rand des Lebensbalkens ("Balken im Balken"), nur bei Einheiten mit Powertyp Mana. Option *Manabalken*.
- **Button- und Zeilen-Abstand.** Zwei Regler, je 0 bis 20 px, fuer den Abstand der Buttons und den Abstand der Plaketten.
- **Testmodus.** Fuellt die Anzeige mit Geisterspielern und -begleitern (Leben, Mana, Schild, eingehende Heilung, entfernbarer Debuff, fehlender Buff, ausser Reichweite), damit sich alles ohne Gruppe einrichten laesst. `/fbp test` oder der Haken. Wird nicht gespeichert.
- **Optionsfenster mit zwei Reitern.** *Buttons* enthaelt die Belegung, die Buttonzahl und den Rechtsklick-Schalter; *Allgemein* enthaelt Skalierung, Abstaende, alle uebrigen Schalter, Sprache und Buff-Wache.
- **Rechtsklick-Zauber.** Jeder Button kann einen zweiten Zauber fuer Rechtsklick tragen. Standardmaessig aus und nur ueber den Reiter *Buttons* einschaltbar; eingeschaltet erscheint eine zweite Spalte in der Belegung und ein kleines Eck-Icon auf jedem Button zeigt den Rechtsklick-Zauber. Die Belegung bleibt bei ausgeschaltetem Schalter erhalten.
- **Klick auf die Plakette.** Links- und Rechtsklick auf Name oder Lebensbalken visieren die Einheit an (Standard). Beides belegbar (Reiter *Allgemein*): Anvisieren, Einheitenmenue, Anzeige verschieben, Nichts. Verschieben geht jetzt per Shift + Linksklick ziehen (oder Aktion *Anzeige verschieben*).
- **Tot / Geist / Offline.** Als Text im Balken statt 0 %, mit leerem grauem Balken und ohne Manastreifen.
- **Sichtlinie.** Augen-Abzeichen am linken Plattenrand, solange die Einheit ausserhalb der Sichtlinie ist: live ueber den Client-Mod UnitXP, sonst aus der Fehlermeldung 'nicht in Sichtlinie' nach einem eigenen Heilversuch abgeleitet (8 s, geloescht sobald ein Cast startet oder eine Heilung ankommt). Option *Sichtlinie*.
- **Debuff-Icon.** Das Icon des ersten von deiner Klasse entfernbaren Debuffs erscheint neben dem Namen, mit Stackzahl. Option *Debuff-Icon*.
- **Klassenfarben.** Namen in Klassenfarbe (`RAID_CLASS_COLORS` des Clients, Ersatztabelle eingebaut). Option *Klassenfarben*.
- **Buff-Wache.** Einen eigenen Buff waehlen; jede Plakette, deren Einheit ihn nicht traegt, bekommt einen orangen Rahmen. Gruppenversionen zaehlen mit, auch von anderen Heilern (erst Texturvergleich, dann Tooltip-Namensscan). Begleiter sind ausgenommen, solange *Buff-Wache auch fuer Begleiter* aus ist.
- **Reichweiten-Fading.** Plaketten samt Buttons werden auf 50 % abgeblendet, wenn die Einheit ausser Reichweite des ersten belegten Zaubers ist (ohne Zauber 28 Meter). Option *Reichweiten-Fading*.
- **`/fbp config`** oeffnet das Optionsfenster; **Escape** schliesst es (in `UISpecialFrames` eingetragen, dazu ein Hook auf `ToggleGameMenu` fuer Clients, die diese Liste ignorieren). `/fbp` endet mit einer Liste aller Befehle.
- **Gespeicherte Plattenposition.** Die Spielerplakette behaelt ihre Position ueber Reloads; Skalieren verschiebt sie nicht mehr.

**Geaendert**

- Alle UNIT-Events laufen ueber eine Slot-Tabelle (`FBPartyUnit`) statt fuenf kopierter Handler; `HealBoxAttachMode` und `FBUpdateNames` sind Schleifen.
- Zauber-Buttons werden einmal angelegt und danach nur umbelegt (frueher bei jedem `SPELLS_CHANGED` neu gebaut, mit zufaelligen Global-Namen wie `Button3`).
- In einer alten SavedVariables-Tabelle fehlende Einstellungen werden beim Laden nachgezogen (`FBHealBox_ApplyDefaults`).
- `UNIT_MAXHEALTH` wird ausgewertet (fehlte).

**Behoben**

- Die Dokumentation nannte eine falsche Client-Version; das Addon zielt auf Client 1.12.1.
- Tooltip-Fehler auf einem Button, dessen Ziel nicht existiert.
- Division durch Null bei Offline-Mitgliedern (`UnitHealthMax` = 0).
- Plattenposition wurde bei jedem Login zurueckgesetzt.

## 1.4

- Vanilla port, cascading spell menu, heal prediction, HealComm sync, German/English localization. See README.
