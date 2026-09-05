# Changelog

## 1.4.2 (2026-09-05)

### English

**New: raid mode** (module `FBHealBox_Raid.lua`, on by default, switches in automatically from 11 raid members; *Raid view from N players* is adjustable)

- Compact grid for 20 and 40 player raids: one cell per member in blocks of five per raid group, blocks arranged in rows (*Groups per row*). Empty groups collapse, so a 20-player raid is a single row.
- Each cell: name in class colour, health bar with shield and incoming-heal layers, 3 px mana strip, HP percent or deficit, dispel colouring, dead/ghost/offline text, range fading, line-of-sight eye, buff-watch border.
- Up to four mini buttons per cell, wired to Button 1 to N from the Buttons tab (right-click spells included). Click on a cell targets the unit (or unit menu / move / nothing, as configured for plates).
- Own options tab *Raid mode* with size, spacing, scale, headers, mana strip, HP text mode, title bar, hide-empty-groups and hide-party-plates switches.
- Raid test with 20 or 40 ghosts covering every visual state. `/fbp raid`, `/fbp raidtest 20|40|off`, raid line in `/fbp`.
- Grid position and scale are saved separately from the party plates. Party plates are hidden while the grid is up (switchable).

**New: drag and drop.** Spells can be dragged from the spellbook onto any heal button, raid mini button or options field. Right mouse button fills the right-click side when that option is on. Spells outside the class list are accepted.

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

**Neu: Drag & Drop.** Zauber lassen sich aus dem Zauberbuch auf jeden Heil-Button, Raid-Mini-Button oder jedes Optionsfeld ziehen. Die rechte Maustaste fuellt die Rechtsklick-Seite, wenn die Option an ist. Zauber ausserhalb der Klassenliste werden angenommen.

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
