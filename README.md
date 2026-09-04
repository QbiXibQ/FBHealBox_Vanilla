# Heal Box Vanilla

ADDON DOCUMENTATION · VERSION 1.4.1 · CLIENT 1.12.1

Party, pet and self heal display with quick-cast buttons for healers. One name plate with a health bar per group slot, plus one for every pet in the group directly below its owner, and next to it up to ten freely assignable spell buttons. A thin mana bar sits inside the health bar for everyone who actually uses mana. On top of that a complete heal prediction (direct heals, remaining HoT ticks and absorb shields) that corrects itself from the combat log and shares its numbers with other healers in the HealComm format. The interface is available in **English and German**, switchable in the options window.

**The short version:** click the minimap button (or type `/fbp config`) → options window → pick a spell for each button → done. Everything else happens on its own. `/fbp` tells you at any time what the prediction currently believes. **New in 1.4.1:** tick *Test mode* to fill the display with ghost players and arrange everything without a group.

\---

## Installation

Download zip, unpack into your Addons folder.

The folder under `Interface\\AddOns` is called **`FBHealBox`** and holds four files:

|File|Contents|
|-|-|
|`FBHealBox.toc`|Metadata, load order, saved variables|
|`FBHealBox.lua`|The entire addon code|
|`FBHealBox.xml`|Only the event frame that calls `FBHealBox\_OnLoad` and `FBHealBox\_OnEvent`|
|`CHANGELOG.md`|What changed in which version|

The folder name must match the name of the `.toc` file, otherwise the addon never starts. If you want to rename the folder, also change the `FBADDON\_FOLDER` constant near the top of `FBHealBox.lua`, because the `ADDON\_LOADED` check depends on it. The display name lives separately in `FBADDON\_NAME` and can be changed freely.

**Optional: SuperWoW.** When detected, the addon prints `\[SuperWoW detected]` at login and casts directly on the group member without touching your current target. Without SuperWoW it briefly switches target for the cast and restores the previous one afterwards.

**No libraries required.** No Ace, no HealComm, no RosterLib. The addon speaks the HealComm protocol directly, see [HealComm sync](#healcomm-sync).

\---

## The display

Ten name plates in two families. `FBHealBox1` is always the player, `FBHealBox2` through `FBHealBox5` are `party1` through `party4`. `FBHealBoxPet1` through `FBHealBoxPet5` are the matching pets (`pet`, `partypet1` through `partypet4`). Each shows name, health percentage and a layered bar. **To move them:** hold **Shift** and drag any plate with the left mouse button, the others are anchored to it and follow. The position is saved per character and survives a reload; changing the scale does not move the plate.

Plates are stacked in the order **owner, then that owner's pet**: you, your pet, party1, party1's pet, and so on. Slots without a unit collapse, so a group with a single hunter shows six plates, not ten. The gap between plates is the *Row spacing* option.

### Clicking a plate

A **left click** on a name or health bar targets that unit; so does a **right click**. Both are configurable on the *General* tab (*Left click on plate* / *Right click on plate*): **Target**, **Unit menu** (Blizzard's own unit menu with whisper, invite, promote, leave, for players and your own pet; group pets fall back to targeting), **Move display** (drag without holding Shift) or **Nothing**. Shift + left drag always moves the display, whatever is set. In test mode clicks on ghosts only print a note.

### Line of sight

While a unit is out of your line of sight an **eye badge** (`FBLOS\_ICON`, the Blind icon) hangs on the left edge of its plate. Vanilla has no API for this, so two paths are used: with the **UnitXP SP3** client mod installed the addon asks `UnitXP("inSight", "player", unit)` every half second, live and exact. Without it, the addon watches for the *not in line of sight* error after one of your heals and marks the unit you tried to heal for `FBLOS\_TIMEOUT` (8) seconds; the mark is cleared as soon as a cast on that unit starts or one of your heals or HoT ticks lands on it. `/fbp` reports which path is active. Option *Line of sight*; badge position via `FBLOS\_ICON\_X/Y`.

### Pets

Every pet in the group gets its own plate with the full set of spell buttons: heal the hunter's cat or the warlock's voidwalker with one click, exactly like a player. Pet plates appear and disappear with `UNIT_PET` (summon, dismiss, death). Three things tell them apart: they are **indented** by `FBPET\_INDENT` (12) px under their owner and narrower by the same amount so the buttons stay aligned, a **paw icon** (`FBPET\_ICON`) sits in front of the name, and the name is **light blue**. Hunter pets run on focus and warlock pets on mana, so only the latter get a mana bar. The *Show pets* option hides the whole family.

### Bar layers

Four status bars sit exactly on top of each other, ordered by fixed frame levels (`FBHealBox\_SetBarStrata`). Mana is the topmost strip, then health, opaque; the shield below it, the heal prediction at the bottom:

|Layer|Colour|Meaning|
|-|-|-|
|Mana|blue, 5 px along the bottom edge|Current mana, a bar inside the bar. Only for units whose power type is mana|
|Health|green / yellow / red, opaque|Current HP. Green above 60 %, yellow 30 to 60 %, red below|
|Shield|light blue, 50 %|Remaining absorb, directly behind the current HP|
|Prediction|light green, 50 %|Incoming healing, behind the shield segment|

Everything is clipped at the end of the bar: a shield exceeding maximum HP stays invisible and the scale stays true to the unit's health.

### Mana bar

The mana bar is `FBMANA\_BAR\_HEIGHT` (5) pixels high and lies on the bottom edge of the health bar. Where mana is missing a darker translucent strip shows through (`FBMANA\_BG\_ALPHA`, 0.35, set to 0 for none). It only appears when the unit's **power type is mana** (`UnitPowerType() == 0`): warriors, rogues, hunter pets and druids in cat or bear form get no strip, and the health bar is visible at full height. The bar follows `UNIT\_MANA`, `UNIT\_MAXMANA` and `UNIT\_DISPLAYPOWER`. The *Mana bar* option switches it off entirely.

### Dispel colouring

If someone carries a debuff **your** class can remove, their health bar takes the debuff colour instead of the HP colour:

|Class|Types detected|
|-|-|
|Priest|Magic (blue), Disease (brown)|
|Paladin|Magic, Poison (green), Disease|
|Shaman|Poison, Disease|
|Druid|Curse (purple), Poison|

The thresholds for the HP colours are `LowHP` (0.6) and `VeryLowHP` (0.3) near the top of the file.

\---

## The spell buttons

Up to ten buttons sit next to each plate, each showing its spell's icon. A **left click** casts that spell on exactly this group member, no matter who you currently have targeted.

**Right-click spell (optional).** Each button can carry a second spell for **right click** (Flash Heal left, Greater Heal right, say), which doubles the density without adding buttons. This is off by default and is enabled only through the switch on the *Buttons* tab. When on, a second column appears in the assignment and a small icon in the bottom-right corner of every button shows its right-click spell; the tooltip lists it as well. Switching it off keeps the assignments, it just stops the buttons from reacting to right click.

**Dead, ghost, offline.** Instead of `0 %` the bar shows *Dead*, *Ghost* or *Offline*, empty and grey, with no mana strip.

**Debuff icon.** When a unit carries a debuff your class can remove, its icon appears right of the name with the stack count (from 2 up). The health bar takes the debuff colour as before.

The icon tints to show the state:

|Icon|State|
|-|-|
|Normal|Spell is castable|
|Bluish|Not enough mana|
|Dark grey|Not castable (cooldown, missing requirement)|
|Reddish|Target out of range|

Hovering shows the full spell tooltip plus the line *Heal Box Vanilla Target: `<name>`*, so it is always clear who this button serves.

\---

## Options window

Opened through the **minimap button**:

|Input|Effect|
|-|-|
|Left click|Toggle the options window|
|Shift + left click|Show/hide the entire display|
|Hold right and drag|Move the minimap button|

The window has two tabs.

### Tab *Buttons*

**Button 1 to 10**: one row each with the *Left click* field (icon and spell name). Clicking a field opens the spell menu (see below). The assignment is saved per character.

**Right-click spell**: enables the second spell per button and reveals the *Right click* column next to the left one. Off by default.

**Show N buttons**: how many of the ten buttons actually appear (0 to 10). Assigned but hidden buttons keep their spell.

### Tab *General*

**Frame scale**: scales the plates from 0.6 to 1.5. Has no effect in party-frame mode.

**Button spacing**: gap between the spell buttons (and between plate and first button), 0 to 20 px. Default 2.

**Row spacing**: vertical gap between the plates, 0 to 20 px. Default 4. Together with button spacing this lets you pack the whole display much tighter.

**Default party frames**: instead of the addon's own plates, the buttons attach to Blizzard's default party frames (`PartyMemberFrameN`); pet buttons attach to `PetFrame` and `PartyMemberFrameNPetFrame`. The addon's name plates and bars are hidden; the heal prediction keeps working invisibly.

**Mana bar**: shows or hides the mana strip inside the health bar. On by default.

**Show pets**: shows or hides all pet plates. On by default.

**Debuff icon**: shows or hides the debuff icon with stack count next to the name. On by default.

**Line of sight**: shows or hides the eye badge for units out of line of sight (see [Line of sight](#line-of-sight)). On by default.

**Left click on plate / Right click on plate**: what a click on a name plate does: Target (default), Unit menu, Move display, Nothing. See [Clicking a plate](#clicking-a-plate).

**Test mode**: fills slots 2 to 10 with ghost players and pets so you can arrange the display without a group (see [Test mode](#test-mode)). Not saved; always off after login.

**Class colours**: colours the name on each plate in the class colour (`RAID_CLASS_COLORS` of the client, with a built-in fallback table). Pets keep their light-blue name. On by default.

**Range fading**: fades a whole plate including its buttons to 50 % (`FBRANGE\_ALPHA`) when the unit is out of range. Range is checked every half second (`FBRANGE\_INTERVAL`) with `IsSpellInRange` on your first assigned button spell; with no spell assigned, `CheckInteractDistance(4)`, that is 28 yards, is used. On by default.

**Buff watch**: a button that opens the cascading menu with your class buffs (Fortitude, Divine Spirit, Mark of the Wild, Blessings, Thorns, Earth Shield, …; only learned ones are listed). Every plate whose unit is **missing** that buff gets an **orange border**. The group version counts too (Prayer of Fortitude for Power Word: Fortitude, Gift of the Wild for Mark of the Wild, Greater Blessings for Blessings), even when cast by another healer: the check first compares buff textures with your spellbook icons and, only if that fails, reads the buff names from a tooltip scan. Checked on `UNIT\_AURA` and after every group change, so nothing runs per frame. Pick *No buff watch* to switch it off. Saved as `WatchBuff`. Pets are left out unless *Buff watch on pets* is ticked.

**Buff watch on pets**: also marks pets missing the watched buff. Off by default.

**HealComm sync**: exchanges heal information with the group, see [HealComm sync](#healcomm-sync). On by default.

**Language / Sprache**: switches between English and German. The button opens the same cascading menu as the spell picker. The change takes effect **immediately**: `FBHealBox\_ApplyLocale()` relabels the already-built interface, no `/reload` needed. On first start `GetLocale()` decides: German clients start in German, everything else in English. The choice is saved per character.

**To move the window:** drag its frame. Close it with the X in the top right, with **Escape**, or with `/fbp config`. Escape is caught by a hook on `ToggleGameMenu` (in addition to `UISpecialFrames`), so it works on clients that do not honour that list; when Blizzard's game menu is open, Escape closes that first as usual.

\---

## Test mode

Tick *Test mode* in the options, or type `/fbp test`. Your own plate stays real; every other slot is filled with a ghost: four players and three pets, so you see the full layout including pets under their owners. If you happen to be in a real group, the ghosts replace it for as long as test mode is on.

The ghosts are built to show every visual state at once:

|Ghost|Shows|
|-|-|
|Brynn|warrior: no mana bar, health near full, **missing buff** (orange border when a buff watch is set)|
|Cerys|warlock: mana bar, an **absorb shield** segment and the **line-of-sight** badge|
|Dorn|hunter: low health (red) with **incoming healing** behind it|
|Elowen|druid: a **dispellable debuff** (the health bar takes the dispel colour of your class) and **out of range** (faded)|
|Fang, Zorbek, Bramble|pets: a focus pet without mana bar, a mana pet with one, and a pet with incoming healing|

Their health drifts slowly up and down so you can watch the yellow and red thresholds come and go. Spell buttons on ghosts do nothing except print a short note; tooltips work. The ghost table is `FBTestGhosts` near the top of the file; names, values and which extras each ghost carries can be edited freely.

Test mode is meant for the addon's own plates; in party-frame mode the ghosts sit at Blizzard's (hidden) frames and are of little use.

\---

## The spell menu

A custom cascading menu, not `UIDropDownMenu`: the 1.12 implementation of the latter closes submenus as soon as the mouse brushes a neighbouring entry, and forces check marks and a click sound.

* **Level 1** lists every learned spell of your class from the spell list, each with its icon.
* **An arrow on the right** means multiple ranks exist. The submenu opens **on hover**, overlaps the parent list by two pixels and has a 14-pixel tolerance zone around it so the mouse never loses it on the way over.
* **Open stays open**: only picking a rank, opening another submenu, or clicking outside closes it. After three seconds without the mouse nearby an emergency timer fires (`FBMENU\_GRACE\_TIME`, set it to 999 to disable).
* **No spell** at the top clears the button again.

The selection is stored as the cast string `Spell(Rank N)`, exactly the form `CastSpellByName` expects, and the reason the prediction knows the precise rank.

\---

## Heal prediction

The heart of the addon. Three independent sources feed the bars.

### Direct heals

`SPELLCAST\_START` provides the spell name and the cast time in milliseconds, regardless of whether the cast came from a Heal Box button, the action bar or a macro. No hook on `CastSpellByName` is required. The preview disappears on `SPELLCAST\_STOP`, `\_FAILED` and `\_INTERRUPTED`; pushback (`SPELLCAST\_DELAYED`) extends it.

Instants deliberately get **no** prediction: the healing has landed before a bar could show it.

### Heal over time

`UnitBuff()` reports no remaining duration for other units, so the addon keeps its own books:

1. The button registers the cast including target and rank.
2. `UNIT\_AURA` confirms the application by comparing the **buff texture** with the spellbook icon (locale independent, no tooltip scan per event).
3. What is shown is `remaining ticks × healing per tick`, with the remaining ticks derived from `(expiry − GetTime()) / interval`. The bar therefore counts down tick by tick.
4. If the buff disappears early (dispel, death, overwritten), the display is gone immediately.

HoTs cast from the action bar are recognised as well, then with the highest known rank; the first combat log tick straightens the value out.

The tick interval cannot be read from the tooltip in Vanilla and therefore lives in `FBPredictTickInterval` (3 seconds by default, Lifebloom 1).

### Absorb shields

Maximum absorb from the spellbook tooltip, consumption from the combat log (`(123 absorbed)`). For `\*\_VS\_SELF\_\*` events the victim is the player, otherwise the message is searched for one of the currently shielded names.

If you absorb more than the tooltip allows (heal gear), the maximum is corrected **upwards** and remembered. That correction is one-directional and therefore safe: more than possible cannot have been absorbed.

Fully absorbed hits report no number in Vanilla. The remaining value then stands until the buff drops and the display is cleared. Likewise absorbs on group members only count as far as the combat log shows them at all; the aura check catches the drift at the end.

### Self-correction and learned values

Tooltips in 1.12 only provide base values **without** +healing, and there is no API for spell power. The combat log, on the other hand, tells the truth:

|Observation|Effect|
|-|-|
|`… gains 194 health from your Renew.`|Sets the real healing per tick for all remaining ticks|
|`Your Flash Heal heals Bob for 1240.`|Settles the estimate in (50/50 averaging)|
|`(342 absorbed)` above the maximum|Raises the assumed shield value|

All of it lands per spell **and rank** in `HealBox.PredictMemory` and survives logout.

Two safeguards keep that memory clean. **Crits are not learned**: the crit wording makes the spell name come through the pattern as "Flash Heal critically", which is in no watch list. And learning only happens with a **confirmed rank**, that is on casts through the Heal Box buttons; otherwise a rank 3 cast from the action bar would be attributed to the maximum rank and drag the prediction down. The live display still corrects itself either way; only the persistent memory is protected.

What a spell can do is decided by its own tooltip, and a spell may be several things at once. Regrowth, for instance, provides an instant portion *and* a HoT, and is treated as both.

\---

## HealComm sync

HealComm-1.0 broadcasts plain text through `SendAddonMessage` with the prefix `HealComm`. Heal Box Vanilla speaks that protocol directly, without embedding the library. Puppeteer, pfUI, Luna Unit Frames, CT\_RaidAssist and everything else HealComm-aware therefore see your announced heals, and you see theirs.

|Message|Meaning|
|-|-|
|`Heal/<target>/<amount>/<cast time ms>/`|Direct heal starts|
|`Healstop`|Cast interrupted|
|`Healdelay/<ms>/`|Pushback|
|`GrpHeal/<amount>/<ms>/<t1>/<t2>/…`|Group heal (Prayer of Healing)|
|`GrpHealstop` · `GrpHealdelay/<ms>/`|Same for group heals|
|`Renew` · `Reju` · `Regr` `/<target>/<duration>/`|HoT applied|

Messages go to the raid, otherwise to the party, otherwise nowhere. The amounts are the self-corrected combat log values, so arguably more accurate than what a real HealComm estimates with ItemBonusLib.

A few details: on a successful cast end **no** `Healstop` is sent; HealComm receivers expire the entry themselves at cast time. Prayer of Healing correctly goes out as `GrpHeal` with every target in range. And a HoT cast from the action bar is reported after the fact on the first own combat log tick, with the duration still remaining, because only "… from **your** Renew" proves that it is yours.

On receive, your own messages are filtered by sender name, and since HealComm stores incoming heals per caster nothing can double up, not even when a real HealComm is broadcasting alongside. HoT messages carry only durations and no amounts; HealComm does not count them in its own `getHeal`, and neither does this addon.

**The protocol knows nothing about absorb shields**: those stay local.

\---

## Slash commands

|Command|Effect|
|-|-|
|`/fbp`|Status report: every tooltip value read per spell (direct, HoT and shield portion, learned values in parentheses), all currently running predictions, the state of the HealComm sync and the incoming heals received|
|`/fbp debug`|Toggles live output. Reports every detected cast, every correction, every absorb and every message sent (`\[FBP>]`)|
|`/fbp reset`|Discards all learned values and re-reads the tooltips|
|`/fbp test`|Toggles test mode (same as the checkbox)|
|`/fbp config`|Opens or closes the options window (same as the minimap button)|

`/fbp` is the first place to look when something is not displayed: if a spell is not listed there, the tooltip parser did not recognise it; the display is not at fault.

\---

## Saved settings

Everything lives in the `HealBox` table, saved **per character**:

|Key|Contents|
|-|-|
|`SpellChoice\[1..10]`|Cast string per button, e.g. `Renew(Rank 10)`|
|`MaxButtons`|How many buttons are shown|
|`Scale`|Scale of the plates|
|`AttachMode`|0 = own plates, 1 = default party frames|
|`Active`|Display on/off (shift + left click on the minimap)|
|`HealComm`|1 = sync on, 0 = off|
|`Locale`|`deDE` or `enUS`|
|`ButtonSpacing`|Gap between the buttons in px (0 to 20)|
|`RowSpacing`|Gap between the plates in px (0 to 20)|
|`ManaBar`|1 = mana strip on, 0 = off|
|`ShowPets`|1 = pet plates on, 0 = off|
|`SpellChoiceR\[1..10]`|Cast string per button for right click|
|`RightClick`|1 = right-click spell on, 0 = off (default)|
|`DebuffIcon`|1 = debuff icon on, 0 = off|
|`LOSIcon`|1 = line-of-sight badge on, 0 = off|
|`PlateLeft` · `PlateRight`|Click action on a plate: `target`, `menu`, `move` or `none`|
|`ClassColors`|1 = names in class colour, 0 = white|
|`RangeFade`|1 = fade plates out of range, 0 = off|
|`WatchBuff`|Spell name of the buff watch, or nil|
|`BuffWatchPets`|1 = buff watch also on pets, 0 = players only (default)|
|`PosX` · `PosY`|Top-left corner of the player plate in screen pixels|
|`PredictMemory`|Learned heal values per spell and rank|

Missing keys, for example in an old `HealBox` table from 1.4, are filled in by `FBHealBox\_ApplyDefaults()` on load. Test mode is deliberately **not** saved.

\---

## Configuration in code

Every knob is a global at the top of its own section and can be changed without touching the logic.

|Constant|Default|Effect|
|-|-|-|
|`LowHP` · `VeryLowHP`|0.6 · 0.3|Thresholds for yellow and red|
|`NamePlateWidth` · `NamePlateHeight`|120 · 28|Size of one plate|
|`FBMANA\_BAR\_HEIGHT`|5|Height of the mana strip in px|
|`FBMANA\_BAR\_COLOR`|`{0.15, 0.4, 1, 1}`|Colour of the mana strip|
|`FBMANA\_BG\_ALPHA`|0.35|Dark strip behind missing mana (0 = off)|
|`FBPET\_NAME\_COLOR`|`{0.75, 0.85, 1, 1}`|Name colour on pet plates|
|`FBPET\_INDENT`|12|Indent (and width reduction) of pet plates|
|`FBPET\_ICON` · `FBPET\_ICON\_SIZE`|footprint · 12|Paw icon in front of pet names|
|`FBDEBUFF\_ICON\_SIZE`|14|Edge length of the debuff icon|
|`FBLOS\_ICON` · `FBLOS\_ICON\_SIZE`|Blind icon · 16|Line-of-sight badge|
|`FBLOS\_ICON\_X` · `FBLOS\_ICON\_Y`|6 · 0|Badge offset from the plate's left edge|
|`FBLOS\_TIMEOUT`|8|Seconds a line-of-sight error stays marked without UnitXP|
|`FBNAME\_WIDTH\_FULL` · `FBNAME\_WIDTH\_ICON`|78 · 60|Width of the name box without / with a visible debuff icon|
|`FBRANGE\_ALPHA` · `FBRANGE\_INTERVAL`|0.5 · 0.5|Faded opacity and check interval of the range fading|
|`FBBUFF\_MISSING\_COLOR`|`{1, 0.5, 0, 1}`|Border colour when the watched buff is missing|
|`FBClassColors`|(table)|Fallback class colours if the client has no `RAID\_CLASS\_COLORS`|
|`FBBuffWatchSpells` · `FBBuffAlternates`|(table)|Buffs offered per class, and which group version counts as the same|
|`FBPartyUnit` · `FBLayoutOrder`|(table)|The ten slots and their display order|
|`FBTestGhosts`|(table)|Names and values of the test-mode ghosts|
|`MaxButtonCount`|10|Maximum number of buttons|
|`FBMENU\_BTN\_HEIGHT` · `FBMENU\_ICON\_SIZE`|17 · 16|Row height and icon size in the menu|
|`FBMENU\_MOUSE\_PAD`|14|Tolerance zone around the menus|
|`FBMENU\_GRACE\_TIME`|3.0|Menu auto-close (999 = off)|
|`FBPREDICT\_TICK\_DEFAULT`|3|Default tick interval for HoTs|
|`FBPREDICT\_THROTTLE`|0.2|Update rate of the prediction|
|`FBPREDICT\_CONFIRM\_TIME`|3.0|Time to wait for the aura confirmation|
|`FBPREDICT\_TARGET\_TIME`|2.0|Lifetime of the remembered cast target|
|`FBPredictTickInterval`|`{Lifebloom = 1}`|Deviating tick intervals|
|`FBCommGroupHeal`|`{Prayer of Healing}`|What is broadcast as `GrpHeal`|
|`FBLocale`|`enUS`, `deDE`|Every visible string, per language|

\---

## Function reference

### Display and frames

|Function|Purpose|
|-|-|
|`FBHealBox\_OnLoad()`|Event registration, startup message|
|`FBHealBox\_OnEvent(event, arg1)`|Central event dispatch|
|`FBHealBoxSetup()`|Creates the ten plates (five players, five pets)|
|`FBHealBoxCreateFrame(…)`|Builds one plate including its four bars|
|`FBHealBox\_SetBarStrata(f, strata)`|Stacks mana / health / shield / prediction|
|`FBHealBox\_SetPlateVisible(f, visible)`|Shows or hides all bars of a plate (party-frame mode)|
|`FBHealBox\_UpdateUnit(unit, frame)`|Writes HP, shield, prediction, mana and dispel colour into a plate|
|`FBHealBox\_UpdateMana(unit, frame)`|The mana strip: shown only for mana users|
|`FBHealBox\_DispelType(unit)`|First debuff your class can remove: type, texture, stacks, or nil|
|`FBHealBox\_UpdateDebuffIcon(frame, tex, count)`|Debuff icon and stack count|
|`FBHealBox\_CastOn(button, castString)`|Casts a button's spell (left or right) on its target|
|`FBHealBox\_ShowTab(n)` · `FBHealBox\_ApplyRightClickLayout()`|Options tabs; show/hide the right-click column|
|`FBHealBox\_PlateMouseDown(f)` · `FBHealBox\_PlateMouseUp(f)` · `FBHealBox\_RunPlateAction(f, action)`|Click and drag on a plate|
|`FBHealBox\_RefreshAllBars()`|Updates all ten|
|`FBUpdateNames()`|Names and visibility after a group or pet change, then re-layout|
|`FBSlotActive(p)`|Is slot p to be shown right now?|
|`FBHealBox\_Layout()`|Stacks the visible plates (owner, then pet) with `RowSpacing`|
|`FBHealBox\_ApplyButtonSpacing()`|Re-chains all buttons with `ButtonSpacing`|
|`FBHealBox\_SavePosition()` · `FBHealBox\_RestorePosition()`|Plate position in the saved variables|
|`FBHealBox\_ApplyDefaults()` · `FBHealBox\_SyncOptions()`|Fill missing settings; align the options window with them|
|`FBHealBox\_ApplyNameColor(unit, f)` · `FBHealBox\_ApplyAllNameColors()`|Name in class colour / pet colour|
|`FBHealBox\_SetWatchBuff(name)` · `FBHealBox\_HasWatchBuff(unit)` · `FBHealBox\_CheckWatchBuff(unit, f)`|Buff watch: select, test one unit, colour the border|
|`FBHealBox\_UnitInRange(unit)` · `FBHealBox\_CheckRangeAll()`|Range fading|
|`FBUnitLOSBlocked(unit)` · `FBLOS\_OnError(msg)` · `FBLOS\_Clear(name)` · `FBHealBox\_CheckLOSAll()`|Line of sight (UnitXP or error-message fallback)|
|`FBMenu\_OpenBuffMenu(anchor)`|The buff picker (same cascading menu)|
|`HealBoxAttachMode(mode)`|Switch between own plates ↔ default party frames|
|`HealBoxScale(this, scale)`|Scaling|

### Units and test mode

The display never calls `UnitExists`, `UnitName`, `UnitHealth` or `UnitMana` directly. It goes through these wrappers, which answer from `FBTestGhosts` while test mode is on and from the real API otherwise:

|Function|Returns|
|-|-|
|`FBUnitExists(unit)`|true / false|
|`FBUnitName(unit)`|Name|
|`FBUnitHealth(unit)`|`hp, hpMax` (hpMax is never 0)|
|`FBUnitMana(unit)`|`mp, mpMax, hasMana`; hasMana only for power type mana|
|`FBUnitClassToken(unit)`|`"PRIEST"`, `"WARRIOR"`, … or nil for pets|
|`FBUnitState(unit)`|nil, `"dead"`, `"ghost"` or `"offline"`|
|`FBChoiceTables(side)`|Runtime and saved tables of the left (`"L"`) or right (`"R"`) assignment|
|`FBTest\_Ghost(unit)`|The ghost record, or nil|
|`FBTest\_Set(on)`|Switch test mode|

### Buttons and spell data

|Function|Purpose|
|-|-|
|`FBHealBoxCreateButton(…)`|One spell button including cast logic and tooltip|
|`FBHealBoxButtons()`|Rebuilds all buttons|
|`FBHealBoxButtonsChanged()`|Refreshes icons and assignment without rebuilding|
|`FBLoadSpellData()`|Scans the spellbook, collects all ranks|
|`FBApplySpellChoice(i, castString)`|Assigns a spell to a button|
|`HealBoxButton\_OnEvent(…)`|Tints the icon by mana, cooldown and range|

### Spell menu

|Function|Purpose|
|-|-|
|`FBMenu\_OpenMenu(entries, anchor)`|Opens any entry list as a menu|
|`FBMenu\_OpenSpellMenu(btnIndex, anchor, side)`|Opens the menu for one options field (`side` = `"L"` or `"R"`)|
|`FBMenu\_OpenLanguageMenu(anchor)`|The language picker|
|`FBMenu\_ShowLevel(level, entries, anchor)`|Builds and positions one menu level|
|`FBMenu\_BuildSpellEntries()`|Level 1: all learned spells|
|`FBMenu\_BuildRankEntries(spellName)`|Level 2: all ranks of one spell|
|`FBMenu\_SelectSpell(entry)` · `FBMenu\_ClearSpell()`|Apply a selection, or clear the button|
|`FBMenu\_CloseAll()` · `FBMenu\_IsOpen()`|Close the menu, query its state|

### Prediction: queries

The four functions that feed the bars. All of them expect a **player name**, not a unit ID:

|Function|Returns|
|-|-|
|`FBGetDirectHeal(name)`|Amount of your running direct cast|
|`FBGetHoTHeal(name)`|Sum of all your outstanding HoT ticks|
|`FBGetShield(name)`|Remaining absorb|
|`FBGetCommHeal(name)`|Healing announced by other healers|

### Prediction: internals

|Function|Purpose|
|-|-|
|`FBPredict\_GetSpellInfo(bookID, name)`|Parses the spellbook tooltip (direct / HoT / shield)|
|`FBPredict\_BuildWatch()`|Builds the watch list after every spellbook scan|
|`FBPredict\_NoteCast(castString, target)`|Registers target and rank **before** the cast|
|`FBPredict\_CastStart(spell, castMs)` · `FBPredict\_CastEnd()`|Start and end a direct heal|
|`FBPredict\_ScanUnit(unit)`|Aura check: confirm application, detect removal|
|`FBPredict\_StartHoT(…)` · `FBPredict\_StartShield(…)`|Arm the tracking|
|`FBPredict\_ParseCombat(event, msg)`|Combat log evaluation|
|`FBPredict\_OnTick(…)` · `FBPredict\_OnDirectHeal(…)` · `FBPredict\_OnAbsorb(…)`|The three correction paths|
|`FBPredict\_Remember(…)` · `FBPredict\_Remembered(…)`|Write and read the learned values|
|`FBPredict\_TicksLeft(e, now)`|Remaining ticks of a HoT|

### HealComm

|Function|Purpose|
|-|-|
|`FBComm\_Enabled()`|Is the sync switched on?|
|`FBComm\_Send(msg)`|Raw send to raid or party|
|`FBComm\_SendHealStart(…)`|`Heal` or `GrpHeal`|
|`FBComm\_SendHealStop()` · `FBComm\_SendHealDelay(ms)`|Interrupt and pushback|
|`FBComm\_SendHoT(spell, target, dur)`|`Renew` / `Reju` / `Regr`|
|`FBComm\_OnMessage(prefix, msg, channel, sender)`|Receive and evaluate|

### Localization

|Function|Purpose|
|-|-|
|`FBT(key)`|Looks up a string in the active language, falls back to English|
|`FBSetLocale(code, apply)`|Switches language and optionally relabels the interface|
|`FBDetectLocale()`|Default language from `GetLocale()`|
|`FBHealBox\_ApplyLocale()`|Relabels the already-built interface|

\---

## Troubleshooting

**A spell does not appear in the menu.** It is not in your class's spell list (`Spell.Name` near the top of the file), or not learned yet. The list can be extended freely.

**No prediction for a particular spell.** Run `/fbp`: if the spell is not among the spells read, the tooltip parser did not recognise it. Wording can differ on custom servers; the patterns all sit in `FBPredict\_GetSpellInfo`.

**Combat log corrections do not take.** The patterns are built from the client's global strings (`PERIODICAURAHEALOTHERSELF`, `HEALEDSELFOTHER`, `ABSORB\_TRAILER`) and otherwise fall back to English defaults. `/fbp debug` shows whether corrections arrive.

**Values are too low.** Before the first observed heal only the tooltip base value without +healing is available. A single cast through the buttons is enough to settle it.

**The HealComm sync seems dead.** It only sends in a party or raid; alone nothing happens. `/fbp` shows the switch state, `/fbp debug` every outgoing message.

**Numbers are off after a gear change.** They correct themselves on the next cast; `/fbp reset` forces a fresh start.

\---

## Class spells

The preset lists, freely extensible in `Spell.Name`:

|Class|Spells|
|-|-|
|Priest|Renew · Flash Heal · Lesser Heal · Heal · Greater Heal · Binding Heal · Prayer of Healing · Prayer of Mending · Circle of Healing · Power Word: Shield · Abolish Disease · Cure Disease · Dispel Magic|
|Druid|Rejuvenation · Regrowth · Lifebloom · Healing Touch · Swiftmend · Remove Curse · Abolish Poison|
|Shaman|Lesser Healing Wave · Healing Wave · Chain Heal · Earth Shield · Cure Poison · Cure Disease|
|Paladin|Flash of Light · Holy Light · Holy Shock · Lay on Hands · Purify · Cleanse · Blessing of Protection|

Entries that do not exist do no harm: if the spellbook scan does not find them, they are quietly skipped.

\---

## Credits

**Original: Heal Box by Dourd** (Argent Dawn EU), UI Overhauled. The core idea, the layout with name plates and quick-cast buttons and the original options window are his. Without that groundwork this addon would not exist. Credit where credit is due.

**Ported to Vanilla and extended 09/2026: Mquadrat.** Ported to client 1.12.1 with optional SuperWoW support, plus:

* a custom cascading menu for spell and rank selection, because `UIDropDownMenu` provides no usable submenus in 1.12
* heal prediction for direct heals, remaining HoT ticks and absorb shields, self-correcting from the combat log
* HealComm sync with Puppeteer, pfUI, Luna and others, without any Ace libraries
* English / German localization, switchable in game
* 1.4.1: pet plates, mana bar inside the health bar, adjustable button and row spacing, test mode with ghost players, saved plate position, class colours, buff watch, range fading, tabbed options, right-click spell, dead/ghost/offline text, debuff icon. See CHANGELOG.md.

\---

Heal Box Vanilla v1.4.1 · original by Dourd, UI Overhauled · ported to Vanilla and extended 09/2026 by Mquadrat

_______________________________________________________________________
GERMAN

# Heal Box Vanilla

ADDON-DOKUMENTATION · VERSION 1.4.1 · CLIENT 1.12.1

Party-, Begleiter- und Selbst-Heilanzeige mit Schnellzugriff-Buttons für Heiler. Für jeden Gruppenplatz eine Namensplakette mit Lebensbalken, dazu eine für jeden Begleiter in der Gruppe direkt unter seinem Besitzer, daneben bis zu zehn frei belegbare Zauber-Buttons. Ein schmaler Manabalken liegt im Lebensbalken, bei allen, die tatsächlich Mana nutzen. Dazu eine vollständige Heilvorhersage (Direktheilung, HoT-Restticks und Absorb-Schilde), die sich über den Combatlog selbst korrigiert und ihre Werte im HealComm-Format mit anderen Heilern teilt. Die Oberfläche gibt es auf **Deutsch und Englisch**, umschaltbar im Optionsfenster.

**Kurzfassung für Ungeduldige:** Minimap-Button anklicken (oder `/fbp config`) → Optionsfenster → für jeden Button einen Zauber wählen → fertig. Alles Weitere passiert von allein. `/fbp` zeigt jederzeit, was die Vorhersage gerade denkt. **Neu in 1.4.1:** *Testmodus* anhaken, dann füllt sich die Anzeige mit Geisterspielern und du kannst alles ohne Gruppe einrichten.

\---

## Installation

Der Ordner unter `Interface\\AddOns` heißt **`FBHealBox`** und enthält vier Dateien:

|Datei|Inhalt|
|-|-|
|`FBHealBox.toc`|Metadaten, Ladereihenfolge, SavedVariables|
|`FBHealBox.lua`|Der komplette Addon-Code|
|`FBHealBox.xml`|Nur der Event-Frame, der `FBHealBox\_OnLoad` und `FBHealBox\_OnEvent` aufruft|
|`CHANGELOG.md`|Was sich in welcher Version geaendert hat|

Der Ordnername muss zum Dateinamen der `.toc` passen, sonst startet das Addon nicht. Willst du den Ordner umbenennen, ändere in `FBHealBox.lua` zusätzlich die Konstante `FBADDON\_FOLDER` am Dateianfang, denn daran hängt der `ADDON\_LOADED`-Abgleich. Der Anzeigename steht getrennt davon in `FBADDON\_NAME` und darf frei geändert werden.

**Optional: SuperWoW.** Wird es erkannt, meldet das Addon beim Login `\[SuperWoW erkannt]` und castet direkt auf das Gruppenmitglied, ohne dein aktuelles Ziel anzufassen. Ohne SuperWoW wechselt das Addon für den Cast kurz das Ziel und stellt das alte danach wieder her.

**Keine Bibliotheken nötig.** Kein Ace, kein HealComm, kein RosterLib. Das Addon spricht das HealComm-Protokoll direkt, siehe [HealComm-Sync](#healcomm-sync).

\---

## Die Anzeige

Zehn Namensplaketten in zwei Familien. `FBHealBox1` ist immer der Spieler selbst, `FBHealBox2` bis `FBHealBox5` sind `party1` bis `party4`. `FBHealBoxPet1` bis `FBHealBoxPet5` sind die zugehörigen Begleiter (`pet`, `partypet1` bis `partypet4`). Jede zeigt Name, Lebensprozent und einen mehrschichtigen Balken. **Verschieben:** mit gehaltener **Shift**-Taste eine beliebige Plakette mit der linken Maustaste ziehen, die anderen hängen daran und folgen. Die Position wird pro Charakter gespeichert und übersteht den Reload; ein Wechsel der Skalierung verschiebt die Platte nicht.

Gestapelt wird in der Reihenfolge **Besitzer, darunter sein Begleiter**: du, dein Pet, party1, das Pet von party1 und so weiter. Leere Plätze fallen weg: Eine Gruppe mit einem einzigen Jäger zeigt sechs Plaketten, nicht zehn. Der Abstand zwischen den Plaketten ist die Option *Zeilen-Abstand*.

### Klick auf eine Plakette

Ein **Linksklick** auf Name oder Lebensbalken visiert die Einheit an; ein **Rechtsklick** ebenfalls. Beides ist im Reiter *Allgemein* belegbar (*Linksklick auf Plakette* / *Rechtsklick auf Plakette*): **Anvisieren**, **Einheitenmenü** (Blizzards eigenes Menü mit Flüstern, Einladen, Befördern, Verlassen, für Spieler und den eigenen Begleiter; Gruppen-Begleiter fallen auf Anvisieren zurück), **Anzeige verschieben** (Ziehen ohne Shift) oder **Nichts**. Shift + Linksklick ziehen verschiebt die Anzeige immer, egal was eingestellt ist. Im Testmodus geben Klicks auf Geister nur eine Chatmeldung.

### Sichtlinie

Solange eine Einheit außerhalb deiner Sichtlinie ist, hängt ein **Augen-Abzeichen** (`FBLOS\_ICON`, das Blenden-Icon) am linken Rand ihrer Plakette. Vanilla hat dafür keine API, deshalb zwei Wege: Ist der Client-Mod **UnitXP SP3** installiert, fragt das Addon alle halbe Sekunde `UnitXP("inSight", "player", unit)` ab, live und exakt. Ohne ihn achtet das Addon auf die Fehlermeldung *nicht in Sichtlinie* nach einer eigenen Heilung und markiert die Einheit, die du heilen wolltest, für `FBLOS\_TIMEOUT` (8) Sekunden; die Markierung verschwindet, sobald ein Cast auf sie startet oder eine eigene Heilung bzw. ein HoT-Tick dort ankommt. `/fbp` zeigt, welcher Weg aktiv ist. Option *Sichtlinie*; Position des Abzeichens über `FBLOS\_ICON\_X/Y`.

### Begleiter

Jeder Begleiter in der Gruppe bekommt eine eigene Plakette mit dem vollen Satz Zauber-Buttons: die Katze des Jägers oder den Leerwandler des Hexers heilt man mit einem Klick, genau wie einen Spieler. Pet-Plaketten kommen und gehen mit `UNIT\_PET` (Beschwören, Wegschicken, Tod). Drei Merkmale unterscheiden sie: Sie sind unter ihrem Besitzer um `FBPET\_INDENT` (12) px **eingerückt** und um denselben Betrag schmaler, damit die Buttons bündig bleiben, ein **Pfoten-Icon** (`FBPET\_ICON`) steht vor dem Namen, und der Name ist **hellblau**. Jägerbegleiter laufen auf Fokus, Hexerbegleiter auf Mana; nur letztere bekommen einen Manabalken. Die Option *Begleiter anzeigen* blendet die ganze Familie aus.

### Balkenaufbau

Vier Statusbalken liegen deckungsgleich übereinander, geregelt über feste Ebenen (`FBHealBox\_SetBarStrata`). Ganz oben der schmale Manastreifen, dann der Lebensbalken, deckend; darunter der Schild, ganz unten die Heilvorhersage:

|Schicht|Farbe|Bedeutung|
|-|-|-|
|Mana|blau, 5 px am unteren Rand|Aktuelles Mana, Balken im Balken. Nur bei Einheiten mit Powertyp Mana|
|Leben|grün / gelb / rot, deckend|Aktuelle HP. Grün über 60 %, gelb 30 bis 60 %, rot darunter|
|Schild|hellblau, 50 %|Verbleibender Absorb, direkt hinter den aktuellen HP|
|Vorhersage|hellgrün, 50 %|Eingehende Heilung, hinter dem Schild-Anteil|

Alles wird am Balkenende abgeschnitten: Ein Schild über der Maximal-HP bleibt unsichtbar, die Skala bleibt maßstabsgetreu.

### Manabalken

Der Manabalken ist `FBMANA\_BAR\_HEIGHT` (5) Pixel hoch und liegt auf der Unterkante des Lebensbalkens. Wo Mana fehlt, scheint ein dunkler, halbtransparenter Streifen durch (`FBMANA\_BG\_ALPHA`, 0.35, auf 0 setzen, wenn unerwünscht). Er erscheint nur, wenn der **Powertyp der Einheit Mana** ist (`UnitPowerType() == 0`): Krieger, Schurken, Jägerbegleiter und Druiden in Katzen- oder Bärengestalt bekommen keinen Streifen, der Lebensbalken ist dann auf voller Höhe zu sehen. Der Balken folgt `UNIT\_MANA`, `UNIT\_MAXMANA` und `UNIT\_DISPLAYPOWER`. Die Option *Manabalken* schaltet ihn ganz ab.

### Dispel-Färbung

Hat jemand einen Debuff, den **deine** Klasse entfernen kann, färbt sich sein Lebensbalken in der Debuff-Farbe statt nach HP-Stand:

|Klasse|Erkannte Typen|
|-|-|
|Priester|Magie (blau), Krankheit (braun)|
|Paladin|Magie, Gift (grün), Krankheit|
|Schamane|Gift, Krankheit|
|Druide|Fluch (violett), Gift|

Die Schwellwerte für die HP-Farben stehen als `LowHP` (0.6) und `VeryLowHP` (0.3) am Dateianfang.

\---

## Die Zauber-Buttons

Rechts neben jeder Plakette liegen bis zu zehn Buttons, jeder mit dem Icon seines Zaubers. Ein **Linksklick** wirkt den Zauber auf genau dieses Gruppenmitglied, unabhängig davon, wen du gerade im Ziel hast.

**Rechtsklick-Zauber (optional).** Jeder Button kann einen zweiten Zauber für **Rechtsklick** tragen (etwa Blitzheilung links, Große Heilung rechts), was die Anzeige verdichtet, ohne Buttons hinzuzufügen. Das ist standardmäßig aus und wird ausschließlich über den Schalter im Reiter *Buttons* eingeschaltet. Eingeschaltet erscheint eine zweite Spalte in der Belegung, und ein kleines Icon unten rechts auf jedem Button zeigt seinen Rechtsklick-Zauber; der Tooltip nennt ihn ebenfalls. Ausschalten behält die Belegung, die Buttons reagieren nur nicht mehr auf Rechtsklick.

**Tot, Geist, Offline.** Statt `0 %` zeigt der Balken *Tot*, *Geist* oder *Offline*, leer und grau, ohne Manastreifen.

**Debuff-Icon.** Trägt eine Einheit einen Debuff, den deine Klasse entfernen kann, erscheint sein Icon rechts neben dem Namen mit Stackzahl (ab 2). Der Lebensbalken nimmt wie bisher die Debuff-Farbe an.

Der Icon-Rand färbt sich mit:

|Icon|Zustand|
|-|-|
|Normal|Zauber wirkbar|
|Bläulich|Nicht genug Mana|
|Dunkelgrau|Nicht wirkbar (Cooldown, Voraussetzung fehlt)|
|Rötlich|Ziel außer Reichweite|

Beim Überfahren erscheint der komplette Zaubertooltip plus die Zeile *Heal Box Vanilla Ziel: `<Name>`*, damit klar ist, wen dieser Button bedient.

\---

## Optionsfenster

Zu öffnen über den **Minimap-Button**:

|Bedienung|Wirkung|
|-|-|
|Linksklick|Optionsfenster auf/zu|
|Shift + Linksklick|Gesamte Anzeige ein-/ausblenden|
|Rechts halten und ziehen|Minimap-Button verschieben|

Das Fenster hat zwei Reiter.

### Reiter *Buttons*

**Button 1 bis 10**: je eine Zeile mit dem Feld *Linksklick* (Icon und Zaubername). Klick auf ein Feld öffnet das Zauber-Menü (siehe unten). Die Belegung wird pro Charakter gespeichert.

**Rechtsklick-Zauber**: schaltet den zweiten Zauber je Button ein und blendet die Spalte *Rechtsklick* neben der linken ein. Standardmäßig aus.

**N Buttons anzeigen**: wie viele der zehn Buttons tatsächlich erscheinen (0 bis 10). Belegte, aber ausgeblendete Buttons behalten ihre Zuordnung.

### Reiter *Allgemein*

**Skalierung**: Skalierung der Plaketten von 0.6 bis 1.5. Wirkt nicht im Party-Frame-Modus.

**Button-Abstand**: Luft zwischen den Zauber-Buttons (und zwischen Plakette und erstem Button), 0 bis 20 px. Standard 2.

**Zeilen-Abstand**: senkrechter Abstand der Plaketten zueinander, 0 bis 20 px. Standard 4. Zusammen mit dem Button-Abstand lässt sich die ganze Anzeige damit deutlich kompakter schieben.

**Standard-Gruppenfenster**: statt eigener Plaketten hängen die Buttons an Blizzards Standard-Gruppenfenstern (`PartyMemberFrameN`); die Pet-Buttons an `PetFrame` bzw. `PartyMemberFrameNPetFrame`. Die eigenen Namensplaketten und Balken werden dabei ausgeblendet; die Heilvorhersage arbeitet unsichtbar weiter.

**Manabalken**: Manastreifen im Lebensbalken an/aus. Standardmäßig an.

**Begleiter anzeigen**: alle Pet-Plaketten an/aus. Standardmäßig an.

**Debuff-Icon**: Debuff-Icon mit Stackzahl neben dem Namen an/aus. Standardmäßig an.

**Sichtlinie**: Augen-Abzeichen für Einheiten außerhalb der Sichtlinie an/aus (siehe [Sichtlinie](#sichtlinie)). Standardmäßig an.

**Linksklick auf Plakette / Rechtsklick auf Plakette**: was ein Klick auf eine Plakette tut: Anvisieren (Standard), Einheitenmenü, Anzeige verschieben, Nichts. Siehe [Klick auf eine Plakette](#klick-auf-eine-plakette).

**Testmodus**: füllt die Plätze 2 bis 10 mit Geisterspielern und -begleitern, damit du die Anzeige ohne Gruppe einrichten kannst (siehe [Testmodus](#testmodus)). Wird nicht gespeichert; nach dem Login immer aus.

**Klassenfarben**: färbt den Namen auf jeder Plakette in der Klassenfarbe (`RAID_CLASS_COLORS` des Clients, mit eingebauter Ersatztabelle). Begleiter behalten ihren hellblauen Namen. Standardmäßig an.

**Reichweiten-Fading**: blendet eine ganze Plakette samt Buttons auf 50 % ab (`FBRANGE\_ALPHA`), wenn die Einheit außer Reichweite ist. Geprüft wird alle halbe Sekunde (`FBRANGE\_INTERVAL`) per `IsSpellInRange` mit dem ersten belegten Button-Zauber; ohne belegten Zauber zählt `CheckInteractDistance(4)`, also 28 Meter. Standardmäßig an.

**Buff-Wache**: ein Knopf, der das Kaskadenmenü mit deinen Klassenbuffs öffnet (Seelenstärke, Göttlicher Willen, Mal der Wildnis, Segen, Dornen, Erdschild, …; nur gelernte erscheinen). Jede Plakette, deren Einheit diesen Buff **nicht** trägt, bekommt einen **orangen Rahmen**. Die Gruppenversion zählt mit (Gebet der Seelenstärke für Machtwort: Seelenstärke, Gabe der Wildnis für Mal der Wildnis, Große Segen für Segen), auch wenn ein anderer Heiler sie gewirkt hat: Die Prüfung vergleicht zuerst die Buff-Texturen mit deinen Zauberbuch-Icons und liest erst, wenn das nicht passt, die Buff-Namen per Tooltip-Scan. Geprüft wird bei `UNIT\_AURA` und nach jedem Gruppenwechsel, nichts läuft pro Frame. *Keine Buff-Wache* schaltet sie ab. Gespeichert als `WatchBuff`. Begleiter bleiben außen vor, solange *Buff-Wache auch für Begleiter* nicht gesetzt ist.

**Buff-Wache auch für Begleiter**: markiert auch Pets, denen der überwachte Buff fehlt. Standardmäßig aus.

**HealComm-Sync**: Austausch der Heilinformationen mit der Gruppe, siehe [HealComm-Sync](#healcomm-sync). Standardmäßig an.

**Sprache / Language**: schaltet zwischen Deutsch und Englisch um. Der Knopf öffnet dasselbe Kaskadenmenü wie die Zauberwahl. Die Umstellung wirkt **sofort**: `FBHealBox\_ApplyLocale()` beschriftet die bereits gebaute Oberfläche neu, ein `/reload` ist nicht nötig. Beim ersten Start entscheidet `GetLocale()`: deutsche Clients starten auf Deutsch, alle anderen auf Englisch. Die Wahl wird pro Charakter gespeichert.

**Fenster verschieben:** am Rahmen ziehen. Schließen über das X oben rechts, mit **Escape** oder per `/fbp config`. Escape wird über einen Hook auf `ToggleGameMenu` abgefangen (zusätzlich zu `UISpecialFrames`), damit es auch auf Clients funktioniert, die diese Liste nicht auswerten; ist Blizzards Spielmenü offen, schließt Escape wie gewohnt zuerst dieses.

## Testmodus

*Testmodus* in den Optionen anhaken oder `/fbp test` eingeben. Die eigene Plakette bleibt echt, jeder andere Platz wird mit einem Geist gefüllt: vier Spieler und drei Begleiter, damit das komplette Layout samt Pets unter ihren Besitzern zu sehen ist. Bist du gerade in einer echten Gruppe, ersetzen die Geister sie, solange der Testmodus an ist.

Die Geister sind so gebaut, dass jeder Anzeigezustand gleichzeitig zu sehen ist:

|Geist|Zeigt|
|-|-|
|Brynn|Krieger: keinen Manabalken, Leben fast voll, **fehlender Buff** (oranger Rahmen, sobald eine Buff-Wache gesetzt ist)|
|Cerys|Hexenmeister: Manabalken, einen **Absorb-Schild**-Anteil und das **Sichtlinien**-Abzeichen|
|Dorn|Jäger: wenig Leben (rot) mit **eingehender Heilung** dahinter|
|Elowen|Druide: einen **entfernbaren Debuff** (der Lebensbalken nimmt die Dispel-Farbe deiner Klasse an) und **außer Reichweite** (abgeblendet)|
|Fang, Zorbek, Bramble|Begleiter: ein Fokus-Pet ohne Manabalken, ein Mana-Pet mit, ein Pet mit eingehender Heilung|

Ihre HP wandern langsam auf und ab, damit man die gelbe und rote Schwelle kommen und gehen sieht. Zauber-Buttons auf Geistern tun nichts außer einer kurzen Chatmeldung; Tooltips funktionieren. Die Geistertabelle heißt `FBTestGhosts` und steht am Dateianfang; Namen, Werte und Extras lassen sich frei ändern.

Der Testmodus ist für die eigenen Plaketten gedacht; im Party-Frame-Modus sitzen die Geister an Blizzards (ausgeblendeten) Frames und nützen wenig.

\---

## Das Zauber-Menü

Ein eigenes Kaskadenmenü, kein `UIDropDownMenu`: Dessen 1.12er Implementierung schließt Untermenüs, sobald die Maus einen Nachbareintrag streift, und erzwingt Haken und Klickgeräusch.

* **Ebene 1** listet alle gelernten Zauber deiner Klasse aus der Zauberliste, jeweils mit Icon.
* **Pfeil rechts** = mehrere Ränge vorhanden. Das Untermenü öffnet **beim Überfahren**, überlappt die Elternliste um zwei Pixel und hat ringsum eine Toleranzzone von 14 Pixeln, damit die Maus auf dem Weg nichts verliert.
* **Offen bleibt offen**: Nur die Auswahl eines Rangs, das Aufklappen eines anderen Untermenüs oder ein Klick daneben schließt es. Nach drei Sekunden ohne Maus in der Nähe greift eine Notbremse (`FBMENU\_GRACE\_TIME`, auf 999 setzen deaktiviert sie).
* **Kein Zauber** ganz oben leert den Button wieder.

Ausgewählt wird als Cast-String `Zauber(Rank N)`, genau die Form, die `CastSpellByName` erwartet, und die Basis dafür, dass die Vorhersage den exakten Rang kennt.

\---

## Heilvorhersage

Der Kern des Addons. Drei unabhängige Quellen speisen die Balken.

### Direktheilung

`SPELLCAST\_START` liefert Zaubernamen und Castdauer in Millisekunden, unabhängig davon, ob der Cast vom HealBox-Button, der Aktionsleiste oder aus einem Makro kommt. Es braucht dafür keinen Hook auf `CastSpellByName`. Die Vorschau verschwindet bei `SPELLCAST\_STOP`, `\_FAILED` und `\_INTERRUPTED`, Pushback (`SPELLCAST\_DELAYED`) verlängert sie.

Instants bekommen bewusst **keine** Vorhersage: Die Heilung ist da, bevor ein Balken sie zeigen könnte.

### Heilung über Zeit

`UnitBuff()` liefert für fremde Einheiten keine Restlaufzeit, das Addon führt deshalb selbst Buch:

1. Der Button meldet den Cast samt Ziel und Rang vor.
2. `UNIT\_AURA` bestätigt die Anwendung über den **Buff-Textur-Vergleich** mit dem Zauberbuch-Icon (locale-unabhängig, kein Tooltip-Scan pro Event).
3. Angezeigt wird `Restticks × Heilung pro Tick`, wobei die Restticks aus `(Ablauf − GetTime()) / Intervall` fallen. Der Balken zählt damit Tick für Tick herunter.
4. Fällt der Buff vorzeitig weg (Dispel, Tod, Überschrieben), ist die Anzeige sofort weg.

HoTs von der Aktionsleiste werden ebenfalls erkannt, dann mit dem höchsten bekannten Rang; der erste Combatlog-Tick zieht den Wert gerade.

Das Tickintervall ist in Vanilla nicht aus dem Tooltip lesbar und steht deshalb in `FBPredictTickInterval` (Standard 3 Sekunden, Lifebloom 1).

### Absorb-Schilde

Maximaler Absorb aus dem Zauberbuch-Tooltip, Verbrauch aus dem Combatlog (`(123 absorbed)`). Bei `\*\_VS\_SELF\_\*`-Events ist das Opfer der Spieler, sonst wird unter den aktuell beschildeten Namen gesucht.

Absorbierst du mehr, als der Tooltip hergibt (Heal-Gear), wird das Maximum **nach oben** korrigiert und gemerkt. Diese Korrektur ist einseitig und damit sicher: Mehr als möglich kann nicht absorbiert worden sein.

Vollständig absorbierte Treffer melden in Vanilla keine Zahl. Der Restwert bleibt dann stehen, bis der Buff fällt und die Anzeige gelöscht wird. Ebenso zählen Absorbs an Gruppenmitgliedern nur, soweit der Combatlog sie überhaupt zeigt; der Aura-Abgleich fängt die Abweichung am Ende wieder ein.

### Selbstkorrektur und Lernspeicher

Tooltips liefern in 1.12 nur Basiswerte **ohne** +Heilung, und eine API für Zaubermacht gibt es nicht. Der Combatlog liefert dagegen die Wahrheit:

|Beobachtung|Wirkung|
|-|-|
|`… gains 194 health from your Renew.`|Setzt die echte Heilung pro Tick für alle Restticks|
|`Your Flash Heal heals Bob for 1240.`|Pendelt die Schätzung ein (50/50-Mittelung)|
|`(342 absorbed)` über dem Maximum|Hebt den angenommenen Schildwert an|

Alles davon landet pro Zauber **und Rang** in `HealBox.PredictMemory` und übersteht den Logout.

Zwei Schutzregeln halten den Speicher sauber. **Crits werden nicht gelernt**: die Crit-Formulierung lässt den Zaubernamen als „Flash Heal critically" durchs Muster fallen, und der steht in keiner Watchlist. Und gelernt wird nur bei **gesichertem Rang**, also bei Casts über die HealBox-Buttons; sonst würde ein Rang-3-Cast von der Aktionsleiste dem Maximalrang zugeschrieben und die Vorhersage nach unten ziehen. Die laufende Anzeige korrigiert sich trotzdem immer, geschützt ist nur der dauerhafte Speicher.

Welcher Zauber was kann, entscheidet der Tooltip selbst; ein Zauber darf mehreres sein. Regrowth etwa liefert Sofortheilung *und* HoT und wird auch so behandelt.

\---

## HealComm-Sync

HealComm-1.0 funkt reinen Klartext über `SendAddonMessage` mit dem Prefix `HealComm`. Heal Box Vanilla spricht dieses Protokoll direkt, ohne die Bibliothek einzubinden. Damit sehen Puppeteer, pfUI, Luna Unit Frames, CT\_RaidAssist und alles andere HealComm-fähige deine angekündigten Heilungen, und du siehst umgekehrt ihre.

|Nachricht|Bedeutung|
|-|-|
|`Heal/<Ziel>/<Betrag>/<Castzeit ms>/`|Direktheilung startet|
|`Healstop`|Cast abgebrochen|
|`Healdelay/<ms>/`|Pushback|
|`GrpHeal/<Betrag>/<ms>/<Z1>/<Z2>/…`|Gruppenheilung (Prayer of Healing)|
|`GrpHealstop` · `GrpHealdelay/<ms>/`|dito für Gruppenheilung|
|`Renew` · `Reju` · `Regr` `/<Ziel>/<Dauer>/`|HoT angewendet|

Gesendet wird ins Raid, sonst in die Gruppe, sonst gar nicht. Die Beträge sind die selbstkorrigierten Combatlog-Werte, also eher genauer als das, was ein echtes HealComm mit ItemBonusLib schätzt.

Ein paar Feinheiten: Bei erfolgreichem Castende geht **kein** `Healstop` raus; HealComm-Empfänger lassen den Eintrag selbst zur Castzeit auslaufen. Prayer of Healing geht korrekt als `GrpHeal` mit allen Zielen in Reichweite raus. Und ein HoT von der Aktionsleiste wird beim ersten eigenen Combatlog-Tick nachgemeldet, mit der dann noch verbleibenden Laufzeit, denn erst „… from **your** Renew" beweist, dass er von dir stammt.

Beim Empfang werden eigene Nachrichten über den Absendernamen gefiltert, und da HealComm eingehende Heilungen pro Caster ablegt, kann sich nichts doppeln, selbst wenn parallel noch ein echtes HealComm mitfunkt. HoT-Nachrichten tragen nur Laufzeiten und keine Beträge; HealComm zählt sie im eigenen `getHeal` nicht mit, hier passiert dasselbe.

**Absorb-Schilde kennt das Protokoll nicht**: die bleiben lokal.

\---

## Slash-Befehle

|Befehl|Wirkung|
|-|-|
|`/fbp`|Statusbericht: alle ausgelesenen Tooltip-Werte je Zauber (Direkt-, HoT- und Schildanteil, gelernte Werte in Klammern), alle gerade laufenden Vorhersagen, der Zustand des HealComm-Sync und die empfangenen Fremdheilungen|
|`/fbp debug`|Live-Ausgabe an/aus. Meldet jeden erkannten Cast, jede Korrektur, jeden Absorb und jede gefunkte Nachricht (`\[FBP>]`)|
|`/fbp reset`|Verwirft alle gelernten Werte und liest die Tooltips neu ein|
|`/fbp test`|Testmodus an/aus (wie der Haken in den Optionen)|
|`/fbp config`|Optionsfenster auf/zu (wie der Minimap-Button)|

`/fbp` ist die erste Anlaufstelle, wenn etwas nicht angezeigt wird: Steht ein Zauber dort nicht drin, hat der Tooltip-Parser ihn nicht erkannt und nicht die Anzeige versagt.

\---

## Gespeicherte Einstellungen

Alles liegt in der Tabelle `HealBox`, gespeichert **pro Charakter**:

|Schlüssel|Inhalt|
|-|-|
|`SpellChoice\[1..10]`|Cast-String je Button, z. B. `Renew(Rank 10)`|
|`MaxButtons`|Wie viele Buttons angezeigt werden|
|`Scale`|Skalierung der Plaketten|
|`AttachMode`|0 = eigene Plaketten, 1 = Standard-Gruppenfenster|
|`Active`|Anzeige ein/aus (Shift + Linksklick auf die Minimap)|
|`HealComm`|1 = Sync an, 0 = aus|
|`Locale`|`deDE` oder `enUS`|
|`ButtonSpacing`|Abstand der Buttons in px (0 bis 20)|
|`RowSpacing`|Abstand der Plaketten in px (0 bis 20)|
|`ManaBar`|1 = Manastreifen an, 0 = aus|
|`ShowPets`|1 = Pet-Plaketten an, 0 = aus|
|`SpellChoiceR\[1..10]`|Cast-String je Button für Rechtsklick|
|`RightClick`|1 = Rechtsklick-Zauber an, 0 = aus (Standard)|
|`DebuffIcon`|1 = Debuff-Icon an, 0 = aus|
|`LOSIcon`|1 = Sichtlinien-Abzeichen an, 0 = aus|
|`PlateLeft` · `PlateRight`|Klickaktion auf einer Plakette: `target`, `menu`, `move` oder `none`|
|`ClassColors`|1 = Namen in Klassenfarbe, 0 = weiß|
|`RangeFade`|1 = Plaketten außer Reichweite abblenden, 0 = aus|
|`WatchBuff`|Zaubername der Buff-Wache oder nil|
|`BuffWatchPets`|1 = Buff-Wache auch für Pets, 0 = nur Spieler (Standard)|
|`PosX` · `PosY`|Linke obere Ecke der Spielerplakette in Bildschirmpixeln|
|`PredictMemory`|Gelernte Heilwerte je Zauber und Rang|

Fehlende Schlüssel, etwa in einer alten `HealBox`-Tabelle aus 1.4, zieht `FBHealBox\_ApplyDefaults()` beim Laden nach. Der Testmodus wird bewusst **nicht** gespeichert.

## Konfiguration im Code

Alle Stellschrauben stehen als Globals oben in ihrem jeweiligen Abschnitt und lassen sich ohne Eingriff in die Logik ändern.

|Konstante|Standard|Wirkung|
|-|-|-|
|`LowHP` · `VeryLowHP`|0.6 · 0.3|Schwellen für gelb und rot|
|`NamePlateWidth` · `NamePlateHeight`|120 · 28|Größe einer Plakette|
|`FBMANA\_BAR\_HEIGHT`|5|Höhe des Manastreifens in px|
|`FBMANA\_BAR\_COLOR`|`{0.15, 0.4, 1, 1}`|Farbe des Manastreifens|
|`FBMANA\_BG\_ALPHA`|0.35|Dunkler Streifen hinter fehlendem Mana (0 = aus)|
|`FBPET\_NAME\_COLOR`|`{0.75, 0.85, 1, 1}`|Namensfarbe auf Pet-Plaketten|
|`FBPET\_INDENT`|12|Einrückung (und Verschmälerung) der Pet-Plaketten|
|`FBPET\_ICON` · `FBPET\_ICON\_SIZE`|Fußabdruck · 12|Pfoten-Icon vor Pet-Namen|
|`FBDEBUFF\_ICON\_SIZE`|14|Kantenlänge des Debuff-Icons|
|`FBLOS\_ICON` · `FBLOS\_ICON\_SIZE`|Blenden-Icon · 16|Sichtlinien-Abzeichen|
|`FBLOS\_ICON\_X` · `FBLOS\_ICON\_Y`|6 · 0|Versatz des Abzeichens vom linken Plattenrand|
|`FBLOS\_TIMEOUT`|8|Sekunden, die ein Sichtlinien-Fehler ohne UnitXP markiert bleibt|
|`FBNAME\_WIDTH\_FULL` · `FBNAME\_WIDTH\_ICON`|78 · 60|Breite der Namensbox ohne / mit sichtbarem Debuff-Icon|
|`FBRANGE\_ALPHA` · `FBRANGE\_INTERVAL`|0.5 · 0.5|Deckkraft und Prüfintervall des Reichweiten-Fadings|
|`FBBUFF\_MISSING\_COLOR`|`{1, 0.5, 0, 1}`|Rahmenfarbe bei fehlendem Wache-Buff|
|`FBClassColors`|(Tabelle)|Ersatz-Klassenfarben, falls der Client kein `RAID\_CLASS\_COLORS` hat|
|`FBBuffWatchSpells` · `FBBuffAlternates`|(Tabelle)|Angebotene Buffs je Klasse und welche Gruppenversion als gleich zählt|
|`FBPartyUnit` · `FBLayoutOrder`|(Tabelle)|Die zehn Plätze und ihre Anzeigereihenfolge|
|`FBTestGhosts`|(Tabelle)|Namen und Werte der Geister im Testmodus|
|`MaxButtonCount`|10|Maximale Buttonzahl|
|`FBMENU\_BTN\_HEIGHT` · `FBMENU\_ICON\_SIZE`|17 · 16|Zeilenhöhe und Icon-Größe im Menü|
|`FBMENU\_MOUSE\_PAD`|14|Toleranzzone um die Menüs|
|`FBMENU\_GRACE\_TIME`|3.0|Auto-Close des Menüs (999 = aus)|
|`FBPREDICT\_TICK\_DEFAULT`|3|Standard-Tickintervall für HoTs|
|`FBPREDICT\_THROTTLE`|0.2|Update-Rate der Vorhersage|
|`FBPREDICT\_CONFIRM\_TIME`|3.0|Wartezeit auf die Aura-Bestätigung|
|`FBPREDICT\_TARGET\_TIME`|2.0|Gültigkeit des gemerkten Cast-Ziels|
|`FBPredictTickInterval`|`{Lifebloom = 1}`|Abweichende Tickintervalle|
|`FBCommGroupHeal`|`{Prayer of Healing}`|Was als `GrpHeal` gefunkt wird|

\---

## Funktionsreferenz

### Anzeige und Rahmen

|Funktion|Zweck|
|-|-|
|`FBHealBox\_OnLoad()`|Event-Registrierung, Startmeldung|
|`FBHealBox\_OnEvent(event, arg1)`|Zentrale Ereignisverteilung|
|`FBHealBoxSetup()`|Legt die zehn Plaketten an (fünf Spieler, fünf Begleiter)|
|`FBHealBoxCreateFrame(…)`|Baut eine Plakette samt der vier Balken|
|`FBHealBox\_SetBarStrata(f, strata)`|Stapelt Mana / Leben / Schild / Vorhersage|
|`FBHealBox\_SetPlateVisible(f, visible)`|Blendet alle Balken einer Plakette ein/aus (Party-Frame-Modus)|
|`FBHealBox\_UpdateUnit(unit, frame)`|Schreibt HP, Schild, Vorhersage, Mana und Dispel-Farbe in eine Plakette|
|`FBHealBox\_UpdateMana(unit, frame)`|Der Manastreifen: nur bei Mana-Nutzern sichtbar|
|`FBHealBox\_DispelType(unit)`|Erster von der eigenen Klasse entfernbarer Debuff: Typ, Textur, Stacks, sonst nil|
|`FBHealBox\_UpdateDebuffIcon(frame, tex, count)`|Debuff-Icon und Stackzahl|
|`FBHealBox\_CastOn(button, castString)`|Wirkt den Zauber eines Buttons (links oder rechts) auf sein Ziel|
|`FBHealBox\_ShowTab(n)` · `FBHealBox\_ApplyRightClickLayout()`|Options-Reiter; Rechtsklick-Spalte ein-/ausblenden|
|`FBHealBox\_PlateMouseDown(f)` · `FBHealBox\_PlateMouseUp(f)` · `FBHealBox\_RunPlateAction(f, action)`|Klick und Ziehen auf einer Plakette|
|`FBHealBox\_RefreshAllBars()`|Aktualisiert alle zehn|
|`FBUpdateNames()`|Namen und Sichtbarkeit nach Gruppen- oder Pet-Wechsel, danach neu anordnen|
|`FBSlotActive(p)`|Ist Platz p gerade anzuzeigen?|
|`FBHealBox\_Layout()`|Stapelt die sichtbaren Plaketten (Besitzer, dann Pet) mit `RowSpacing`|
|`FBHealBox\_ApplyButtonSpacing()`|Verkettet alle Buttons neu mit `ButtonSpacing`|
|`FBHealBox\_SavePosition()` · `FBHealBox\_RestorePosition()`|Plattenposition in den SavedVariables|
|`FBHealBox\_ApplyDefaults()` · `FBHealBox\_SyncOptions()`|Fehlende Einstellungen nachziehen; Optionsfenster daran angleichen|
|`FBHealBox\_ApplyNameColor(unit, f)` · `FBHealBox\_ApplyAllNameColors()`|Name in Klassen- bzw. Pet-Farbe|
|`FBHealBox\_SetWatchBuff(name)` · `FBHealBox\_HasWatchBuff(unit)` · `FBHealBox\_CheckWatchBuff(unit, f)`|Buff-Wache: wählen, eine Einheit prüfen, Rahmen färben|
|`FBHealBox\_UnitInRange(unit)` · `FBHealBox\_CheckRangeAll()`|Reichweiten-Fading|
|`FBUnitLOSBlocked(unit)` · `FBLOS\_OnError(msg)` · `FBLOS\_Clear(name)` · `FBHealBox\_CheckLOSAll()`|Sichtlinie (UnitXP oder Fehlermeldungs-Fallback)|
|`FBMenu\_OpenBuffMenu(anchor)`|Die Buff-Auswahl (dasselbe Kaskadenmenü)|
|`HealBoxAttachMode(mode)`|Umschaltung eigene Plaketten ↔ Standard-Gruppenfenster|
|`HealBoxScale(this, scale)`|Skalierung|

### Einheiten und Testmodus

Die Anzeige ruft `UnitExists`, `UnitName`, `UnitHealth` und `UnitMana` nie direkt auf, sondern geht über diese Wrapper. Im Testmodus antworten sie aus `FBTestGhosts`, sonst aus der echten API:

|Funktion|Liefert|
|-|-|
|`FBUnitExists(unit)`|true / false|
|`FBUnitName(unit)`|Name|
|`FBUnitHealth(unit)`|`hp, hpMax` (hpMax ist nie 0)|
|`FBUnitMana(unit)`|`mp, mpMax, hasMana`; hasMana nur bei Powertyp Mana|
|`FBUnitClassToken(unit)`|`"PRIEST"`, `"WARRIOR"`, … oder nil bei Begleitern|
|`FBUnitState(unit)`|nil, `"dead"`, `"ghost"` oder `"offline"`|
|`FBChoiceTables(side)`|Laufzeit- und Speichertabellen der linken (`"L"`) oder rechten (`"R"`) Belegung|
|`FBTest\_Ghost(unit)`|Den Geist-Datensatz oder nil|
|`FBTest\_Set(on)`|Testmodus umschalten|

### Buttons und Zauberdaten

|Funktion|Zweck|
|-|-|
|`FBHealBoxCreateButton(…)`|Ein Zauber-Button samt Cast-Logik und Tooltip|
|`FBHealBoxButtons()`|Baut alle Buttons neu auf|
|`FBHealBoxButtonsChanged()`|Aktualisiert Icons und Zuordnung ohne Neubau|
|`FBLoadSpellData()`|Scannt das Zauberbuch, sammelt alle Ränge|
|`FBApplySpellChoice(i, castString)`|Weist einem Button einen Zauber zu|
|`HealBoxButton\_OnEvent(…)`|Färbt das Icon nach Mana, Cooldown und Reichweite|

### Zauber-Menü

|Funktion|Zweck|
|-|-|
|`FBMenu\_OpenSpellMenu(btnIndex, anchor, side)`|Öffnet das Menü für ein Optionsfeld (`side` = `"L"` oder `"R"`)|
|`FBMenu\_ShowLevel(level, entries, anchor)`|Baut und positioniert eine Menü-Ebene|
|`FBMenu\_BuildSpellEntries()`|Ebene 1: alle gelernten Zauber|
|`FBMenu\_BuildRankEntries(spellName)`|Ebene 2: alle Ränge eines Zaubers|
|`FBMenu\_SelectSpell(entry)` · `FBMenu\_ClearSpell()`|Auswahl übernehmen bzw. Button leeren|
|`FBMenu\_CloseAll()` · `FBMenu\_IsOpen()`|Menü schließen, Zustand abfragen|

### Vorhersage: Abfrage

Die vier Funktionen, die die Balken speisen. Alle erwarten einen **Spielernamen**, keine Unit-ID:

|Funktion|Liefert|
|-|-|
|`FBGetDirectHeal(name)`|Betrag des laufenden eigenen Direktcasts|
|`FBGetHoTHeal(name)`|Summe aller noch ausstehenden eigenen HoT-Ticks|
|`FBGetShield(name)`|Verbleibender Absorb|
|`FBGetCommHeal(name)`|Angekündigte Heilung anderer Heiler|

### Vorhersage: Innenleben

|Funktion|Zweck|
|-|-|
|`FBPredict\_GetSpellInfo(bookID, name)`|Wertet den Zauberbuch-Tooltip aus (Direkt / HoT / Schild)|
|`FBPredict\_BuildWatch()`|Baut die Watchlist nach jedem Zauberbuch-Scan|
|`FBPredict\_NoteCast(castString, target)`|Merkt Ziel und Rang **vor** dem Cast vor|
|`FBPredict\_CastStart(spell, castMs)` · `FBPredict\_CastEnd()`|Direktheilung starten und beenden|
|`FBPredict\_ScanUnit(unit)`|Aura-Abgleich: Anwendung bestätigen, Wegfall erkennen|
|`FBPredict\_StartHoT(…)` · `FBPredict\_StartShield(…)`|Tracking scharfschalten|
|`FBPredict\_ParseCombat(event, msg)`|Combatlog-Auswertung|
|`FBPredict\_OnTick(…)` · `FBPredict\_OnDirectHeal(…)` · `FBPredict\_OnAbsorb(…)`|Die drei Korrekturpfade|
|`FBPredict\_Remember(…)` · `FBPredict\_Remembered(…)`|Lernspeicher schreiben und lesen|
|`FBPredict\_TicksLeft(e, now)`|Restticks eines HoT|

### HealComm

|Funktion|Zweck|
|-|-|
|`FBComm\_Enabled()`|Ist der Sync eingeschaltet?|
|`FBComm\_Send(msg)`|Rohversand ins Raid bzw. in die Gruppe|
|`FBComm\_SendHealStart(…)`|`Heal` bzw. `GrpHeal`|
|`FBComm\_SendHealStop()` · `FBComm\_SendHealDelay(ms)`|Abbruch und Pushback|
|`FBComm\_SendHoT(spell, target, dur)`|`Renew` / `Reju` / `Regr`|
|`FBComm\_OnMessage(prefix, msg, channel, sender)`|Empfang und Auswertung|

\---

## Fehlersuche

**Ein Zauber taucht im Menü nicht auf.** Er steht nicht in der Zauberliste deiner Klasse (`Spell.Name` am Dateianfang) oder ist noch nicht gelernt. Die Liste lässt sich frei erweitern.

**Keine Vorhersage für einen bestimmten Zauber.** `/fbp` aufrufen: Steht der Zauber nicht in der Liste der ausgelesenen Zauber, hat der Tooltip-Parser ihn nicht erkannt. Auf abweichenden Servern können die Formulierungen abweichen; die Muster sitzen gebündelt in `FBPredict\_GetSpellInfo`.

**Combatlog-Korrekturen greifen nicht.** Die Muster werden aus den GlobalStrings des Clients gebaut (`PERIODICAURAHEALOTHERSELF`, `HEALEDSELFOTHER`, `ABSORB\_TRAILER`) und fallen sonst auf englische Vorgaben zurück. `/fbp debug` zeigt, ob Korrekturen ankommen.

**Werte sind zu niedrig.** Vor der ersten beobachteten Heilung steht nur der Tooltip-Basiswert ohne +Heilung zur Verfügung. Ein einziger Cast über die Buttons genügt zum Einpendeln.

**Der HealComm-Sync scheint tot.** Er sendet nur in Gruppe oder Raid; allein passiert nichts. `/fbp` zeigt den Schaltzustand, `/fbp debug` jede ausgehende Nachricht.

**Nach einem Gear-Wechsel stimmen die Zahlen nicht.** Sie korrigieren sich beim nächsten Cast von selbst; `/fbp reset` erzwingt den Neustart.

\---

## Klassenzauber

Die vorbelegten Listen, frei erweiterbar in `Spell.Name`:

|Klasse|Zauber|
|-|-|
|Priester|Renew · Flash Heal · Lesser Heal · Heal · Greater Heal · Binding Heal · Prayer of Healing · Prayer of Mending · Circle of Healing · Power Word: Shield · Abolish Disease · Cure Disease · Dispel Magic|
|Druide|Rejuvenation · Regrowth · Lifebloom · Healing Touch · Swiftmend · Remove Curse · Abolish Poison|
|Schamane|Lesser Healing Wave · Healing Wave · Chain Heal · Earth Shield · Cure Poison · Cure Disease|
|Paladin|Flash of Light · Holy Light · Holy Shock · Lay on Hands · Purify · Cleanse · Blessing of Protection|

Nicht vorhandene Einträge stören nicht: Findet der Zauberbuch-Scan sie nicht, werden sie stillschweigend übergangen.

\---

## Credits

**Original: Heal Box von Dourd** (Argent Dawn EU), UI Overhauled. Von ihm stammen die Grundidee, der Aufbau mit Namensplaketten und Schnellzugriff-Buttons und das ursprüngliche Optionsfenster. Ohne diese Vorlage gäbe es dieses Addon nicht. Ehre wem Ehre gebührt.

**Vanilla-Portierung und Funktionserweiterung 09/2026: Mquadrat.** Portiert auf Client 1.12.1 mit optionaler SuperWoW-Unterstützung, dazu:

* eigenes Kaskadenmenü für Zauber- und Rangwahl, weil `UIDropDownMenu` in 1.12 keine brauchbaren Untermenüs liefert
* Heilvorhersage für Direktheilung, HoT-Restticks und Absorb-Schilde, selbstkorrigierend über den Combatlog
* HealComm-Sync mit Puppeteer, pfUI, Luna und Co., ohne Ace-Bibliotheken
* Lokalisierung Deutsch / Englisch, im laufenden Spiel umschaltbar
* 1.4.1: Begleiter-Plaketten, Manabalken im Lebensbalken, einstellbare Button- und Zeilenabstände, Testmodus mit Geisterspielern, gespeicherte Plattenposition, Klassenfarben, Buff-Wache, Reichweiten-Fading, Optionen in Reitern, Rechtsklick-Zauber, Tot/Geist/Offline-Text, Debuff-Icon. Siehe CHANGELOG.md.

\---

Heal Box Vanilla v1.4.1 · Original von Dourd, UI Overhauled · Vanilla-Portierung und Erweiterung 09/2026 von Mquadrat

