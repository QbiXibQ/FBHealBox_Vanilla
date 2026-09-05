-- ==========================================================================
-- Heal Box Vanilla: Raidmodus (Modul, ab v1.4.2)
--
-- Ein Addon im Addon. Diese Datei wird nach FBHealBox.lua geladen und
-- haengt sich ausschliesslich ueber FBHealBox_RegisterHook und
-- FBHealBox_AddOptionsTab in den Kern ein. Ohne diese Datei laeuft der
-- Kern unveraendert wie in 1.4.1.
--
-- Anzeige: kompakte Zellen (Name, Leben mit Schild- und Vorhersage-Schicht,
-- Manastreifen, Zustandstext, Dispel-Farbe, Buff-Wache-Rahmen, LoS-Auge,
-- Reichweiten-Fading) in Gruppenbloecken zu je fuenf, die Bloecke in einem
-- Raster mit einstellbaren Gruppen je Zeile. 20er-Raids: leere Gruppen
-- fallen weg. Je Zelle bis zu vier Mini-Buttons, belegt wie Button 1 bis N
-- aus dem Reiter Buttons (Links- und Rechtsklick-Zauber).
--
-- Eigener Testmodus mit 20 oder 40 Geistern, eigener Options-Reiter
-- "Raidmodus", eigene Events, eigene Position und Skalierung.
--
-- Umschalten geschieht automatisch: Raid-Ansicht erst ab MinPlayers
-- Mitgliedern (Standard 11, also mehr als 10), darunter bleibt die
-- Gruppenansicht. Der Schalter "Raidmodus" ist damit nur ein Notaus.
-- ==========================================================================

if (FBHealBox_RaidLoaded) then return; end
FBHealBox_RaidLoaded = true;

FBRAID_MAX        = 40;
FBRAID_GROUPS     = 8;
FBRAID_PER_GROUP  = 5;
FBRAID_MAX_BUTTONS = 4;
FBRAID_TICK       = 0.5;     -- Sek.: Reichweite und Sichtlinie
FBRAID_MANA_H     = 3;       -- px Manastreifen in der Zelle
FBRAID_LOS_SIZE   = 10;      -- px Sichtlinien-Auge in der Zelle
FBRAID_HEADER_H   = 12;      -- px Gruppenkopf
FBRAID_TITLE_H    = 14;      -- px Titelleiste (Griff zum Verschieben)

-- Vorgaben aller Raid-Einstellungen. Leben in HealBox.Raid.
FBRaidDefaults = {
    Enabled      = 1,        -- Raidmodus an/aus (Notaus; greift ohnehin nur im Raid)
    MinPlayers   = 11,       -- Raid-Ansicht ab so vielen Mitgliedern (darunter Gruppenansicht)
    HideParty    = 1,        -- Gruppenplaketten im Raid ausblenden
    GroupsPerRow = 4,        -- Gruppenbloecke je Zeile (1..8)
    CellW        = 70,       -- Zellenbreite px
    CellH        = 22,       -- Zellenhoehe px
    Buttons      = 2,        -- Mini-Buttons je Zelle (0..4)
    ButtonSize   = 18,       -- px
    CellGap      = 1,        -- px zwischen Zellen
    GroupGap     = 6,        -- px zwischen Gruppenbloecken
    Scale        = 1.0,
    Headers      = 1,        -- Gruppenkoepfe "1".."8"
    ManaBar      = 1,        -- Manastreifen
    HPText       = "percent",-- none | percent | deficit
    HideEmpty    = 1,        -- leere Gruppen ausblenden
    ShowTitle    = 1,        -- Titelleiste anzeigen
    PosX = nil, PosY = nil,  -- Position der linken oberen Ecke (Bildschirmpixel)
};

-- ==========================================================================
-- [ Texte ]
-- ==========================================================================

FBLocale["enUS"].TAB_RAID          = "Raid mode";
FBLocale["enUS"].RAID_TITLE        = "Raid";
FBLocale["enUS"].RAID_ENABLED      = "Raid mode";
FBLocale["enUS"].RAID_ENABLED_TIP  = "Master switch for the compact raid grid: one cell per member, grouped by raid group, with mini heal buttons. The grid appears on its own once your raid has at least the number of players set below; smaller raids keep the party display.";
FBLocale["enUS"].RAID_MINPLAYERS   = "Raid view from |cFFFFFFFF%s|r players";
FBLocale["enUS"].RAID_HIDEPARTY    = "Hide party plates in raid";
FBLocale["enUS"].RAID_HIDEPARTY_TIP = "While the raid grid is shown, the five party plates are hidden. Turn off to keep both.";
FBLocale["enUS"].RAID_HEADERS      = "Group headers";
FBLocale["enUS"].RAID_HEADERS_TIP  = "A small group number above every block.";
FBLocale["enUS"].RAID_MANABAR      = "Mana strip";
FBLocale["enUS"].RAID_MANABAR_TIP  = "A 3 px mana strip at the bottom of each cell, only for mana users.";
FBLocale["enUS"].RAID_HIDEEMPTY    = "Hide empty groups";
FBLocale["enUS"].RAID_HIDEEMPTY_TIP = "Groups without members take no space. A 20-player raid then fills a single row.";
FBLocale["enUS"].RAID_SHOWTITLE    = "Title bar";
FBLocale["enUS"].RAID_SHOWTITLE_TIP = "A thin title bar above the grid that can be dragged. Without it, hold Shift and drag any cell.";
FBLocale["enUS"].RAID_HPTEXT       = "HP text";
FBLocale["enUS"].RAID_HPTEXT_TIP   = "What the right side of a cell shows: nothing, the health percentage, or the missing health (deficit).";
FBLocale["enUS"].RAID_HP_NONE      = "none";
FBLocale["enUS"].RAID_HP_PERCENT   = "percent";
FBLocale["enUS"].RAID_HP_DEFICIT   = "deficit";
FBLocale["enUS"].RAID_GROUPSPERROW = "Groups per row: |cFFFFFFFF%s";
FBLocale["enUS"].RAID_SCALE        = "Raid scale: |cFFFFFFFF%s";
FBLocale["enUS"].RAID_CELLW        = "Cell width: |cFFFFFFFF%s px";
FBLocale["enUS"].RAID_CELLH        = "Cell height: |cFFFFFFFF%s px";
FBLocale["enUS"].RAID_BUTTONS      = "Buttons per unit: |cFFFFFFFF%s";
FBLocale["enUS"].RAID_BTNSIZE      = "Button size: |cFFFFFFFF%s px";
FBLocale["enUS"].RAID_CELLGAP      = "Cell spacing: |cFFFFFFFF%s px";
FBLocale["enUS"].RAID_GROUPGAP     = "Group spacing: |cFFFFFFFF%s px";
FBLocale["enUS"].RAID_TEST         = "Raid test";
FBLocale["enUS"].RAID_TEST_TIP     = "Fills the raid grid with 20 or 40 ghost players so you can arrange it without a raid. Not saved.";
FBLocale["enUS"].RAID_TEST_OFF     = "off";
FBLocale["enUS"].RAID_TEST_20      = "20 players";
FBLocale["enUS"].RAID_TEST_40      = "40 players";
FBLocale["enUS"].RAID_TEST_CLICK   = "Raid test: no cast on a ghost player.";
FBLocale["enUS"].RAID_INFO         = "The mini buttons use the spells of Button 1 to N from the Buttons tab, including right-click spells.";
FBLocale["enUS"].RAID_MOVE_TIP     = "Drag to move the raid grid.";
FBLocale["enUS"].FBP_RAID          = "Raid mode: %s, %d members in %d groups";
FBLocale["enUS"].FBP_RAID_CMDS     = "Raid: /fbp raid (toggle), /fbp raidtest 20|40|off";
FBLocale["enUS"].RAID_LOADED       = "Raid mode module loaded: tab |cFFFFFFFFRaid mode|r in the options, /fbp raid, /fbp raidtest 20|40";

FBLocale["deDE"].TAB_RAID          = "Raidmodus";
FBLocale["deDE"].RAID_TITLE        = "Raid";
FBLocale["deDE"].RAID_ENABLED      = "Raidmodus";
FBLocale["deDE"].RAID_ENABLED_TIP  = "Hauptschalter fuer das kompakte Raid-Raster: eine Zelle je Mitglied, nach Gruppen geordnet, mit Mini-Heil-Buttons. Das Raster erscheint von selbst, sobald dein Schlachtzug mindestens die unten eingestellte Spielerzahl hat; kleinere Raids behalten die Gruppenanzeige.";
FBLocale["deDE"].RAID_MINPLAYERS   = "Raid-Ansicht ab |cFFFFFFFF%s|r Spielern";
FBLocale["deDE"].RAID_HIDEPARTY    = "Gruppenplaketten im Raid ausblenden";
FBLocale["deDE"].RAID_HIDEPARTY_TIP = "Solange das Raid-Raster zu sehen ist, werden die fuenf Gruppenplaketten ausgeblendet. Ausschalten, um beides zu behalten.";
FBLocale["deDE"].RAID_HEADERS      = "Gruppenkoepfe";
FBLocale["deDE"].RAID_HEADERS_TIP  = "Eine kleine Gruppennummer ueber jedem Block.";
FBLocale["deDE"].RAID_MANABAR      = "Manastreifen";
FBLocale["deDE"].RAID_MANABAR_TIP  = "Ein 3 px hoher Manastreifen am unteren Rand jeder Zelle, nur bei Mana-Nutzern.";
FBLocale["deDE"].RAID_HIDEEMPTY    = "Leere Gruppen ausblenden";
FBLocale["deDE"].RAID_HIDEEMPTY_TIP = "Gruppen ohne Mitglieder brauchen keinen Platz. Ein 20er-Raid fuellt dann eine einzige Zeile.";
FBLocale["deDE"].RAID_SHOWTITLE    = "Titelleiste";
FBLocale["deDE"].RAID_SHOWTITLE_TIP = "Eine schmale Titelleiste ueber dem Raster, an der man ziehen kann. Ohne sie: Shift halten und eine beliebige Zelle ziehen.";
FBLocale["deDE"].RAID_HPTEXT       = "HP-Text";
FBLocale["deDE"].RAID_HPTEXT_TIP   = "Was die rechte Seite einer Zelle zeigt: nichts, die Lebensprozente oder die fehlenden Lebenspunkte (Defizit).";
FBLocale["deDE"].RAID_HP_NONE      = "keiner";
FBLocale["deDE"].RAID_HP_PERCENT   = "Prozent";
FBLocale["deDE"].RAID_HP_DEFICIT   = "Defizit";
FBLocale["deDE"].RAID_GROUPSPERROW = "Gruppen je Zeile: |cFFFFFFFF%s";
FBLocale["deDE"].RAID_SCALE        = "Raid-Skalierung: |cFFFFFFFF%s";
FBLocale["deDE"].RAID_CELLW        = "Zellenbreite: |cFFFFFFFF%s px";
FBLocale["deDE"].RAID_CELLH        = "Zellenhoehe: |cFFFFFFFF%s px";
FBLocale["deDE"].RAID_BUTTONS      = "Buttons je Einheit: |cFFFFFFFF%s";
FBLocale["deDE"].RAID_BTNSIZE      = "Buttongroesse: |cFFFFFFFF%s px";
FBLocale["deDE"].RAID_CELLGAP      = "Zellenabstand: |cFFFFFFFF%s px";
FBLocale["deDE"].RAID_GROUPGAP     = "Gruppenabstand: |cFFFFFFFF%s px";
FBLocale["deDE"].RAID_TEST         = "Raid-Test";
FBLocale["deDE"].RAID_TEST_TIP     = "Fuellt das Raid-Raster mit 20 oder 40 Geisterspielern, damit du es ohne Schlachtzug einrichten kannst. Wird nicht gespeichert.";
FBLocale["deDE"].RAID_TEST_OFF     = "aus";
FBLocale["deDE"].RAID_TEST_20      = "20 Spieler";
FBLocale["deDE"].RAID_TEST_40      = "40 Spieler";
FBLocale["deDE"].RAID_TEST_CLICK   = "Raid-Test: kein Cast auf einen Geisterspieler.";
FBLocale["deDE"].RAID_INFO         = "Die Mini-Buttons nutzen die Zauber von Button 1 bis N aus dem Reiter Buttons, einschliesslich der Rechtsklick-Zauber.";
FBLocale["deDE"].RAID_MOVE_TIP     = "Ziehen verschiebt das Raid-Raster.";
FBLocale["deDE"].FBP_RAID          = "Raidmodus: %s, %d Mitglieder in %d Gruppen";
FBLocale["deDE"].FBP_RAID_CMDS     = "Raid: /fbp raid (an/aus), /fbp raidtest 20|40|off";
FBLocale["deDE"].RAID_LOADED       = "Raidmodus-Modul geladen: Reiter |cFFFFFFFFRaidmodus|r in den Optionen, /fbp raid, /fbp raidtest 20|40";

-- ==========================================================================
-- [ Zustand ]
-- ==========================================================================

FBRaidCells    = {};     -- [g][pos] = Zelle
FBRaidGroups   = {};     -- [g] = Gruppenblock-Frame
FBRaidUnitCell = {};     -- ["raid12"] = Zelle (nach jedem Roster-Update neu)
FBRaidMembers  = 0;      -- Anzahl Mitglieder in der aktuellen Anzeige
FBRaidUsedGroups = 0;    -- Anzahl belegter Gruppen
FBRaidTestMode = 0;      -- 0 | 20 | 40
FBRaidTestGhosts = {};   -- [i] = Geist-Datensatz (Testmodus)
FBRaidTickAccum = 0;
FBRaidDragging  = false;

function FBRaid_Cfg()
    if (not HealBox.Raid) then FBRaid_ApplyDefaults(); end
    return HealBox.Raid;
end

function FBRaid_ApplyDefaults()
    if (not HealBox.Raid) then HealBox.Raid = {}; end
    for k, v in pairs(FBRaidDefaults) do
        if (HealBox.Raid[k] == nil) then HealBox.Raid[k] = v; end
    end
    if (HealBox.Raid.HPText ~= "none" and HealBox.Raid.HPText ~= "percent" and HealBox.Raid.HPText ~= "deficit") then
        HealBox.Raid.HPText = "percent";
    end
    return true;
end

-- ==========================================================================
-- [ Roster: echt oder Geister ]
--
-- FBRaid_Roster() liefert eine Liste { unit, name, class, group, index }.
-- Alle Anzeigefunktionen arbeiten nur damit und mit den FBRaid_*-Wrappern,
-- deshalb muss der Rest den Testmodus nicht kennen.
-- ==========================================================================

FBRaidTestNames = {
    "Aldric", "Brynn", "Cerys", "Dorn", "Elowen", "Faelan", "Gwyn", "Hadrik", "Isolde", "Jorund",
    "Kaelith", "Lirien", "Maren", "Nyssa", "Orin", "Perrin", "Quilla", "Rhoswen", "Sable", "Tamsin",
    "Ulric", "Vesna", "Wren", "Xander", "Ysolde", "Zorbek", "Anselm", "Berit", "Corwin", "Dagny",
    "Edric", "Freya", "Garrick", "Helka", "Ingram", "Jessamy", "Kestrel", "Lorcan", "Mirabel", "Nolan",
};
FBRaidTestClasses = { "WARRIOR", "PRIEST", "MAGE", "ROGUE", "HUNTER", "WARLOCK", "DRUID", "PALADIN", "SHAMAN" };
FBRaidNoMana = { WARRIOR = true, ROGUE = true };

function FBRaid_BuildTestGhosts(count)
    FBRaidTestGhosts = {};
    for i = 1, count do
        local class = FBRaidTestClasses[math.mod(i - 1, table.getn(FBRaidTestClasses)) + 1];
        local g = {
            name    = FBRaidTestNames[i] or ("Geist"..i),
            class   = class,
            group   = math.floor((i - 1) / FBRAID_PER_GROUP) + 1,
            hpMax   = 2600 + math.mod(i * 137, 1800),
            hp      = 0.35 + math.mod(i * 53, 60) / 100,
            swing   = 0.05 + math.mod(i, 4) * 0.03,
            hasMana = (not FBRaidNoMana[class]),
            mpMax   = 2000 + math.mod(i * 71, 2500),
            mp      = 0.2 + math.mod(i * 29, 75) / 100,
        };
        -- ein paar Sonderfaelle, damit jeder Zustand zu sehen ist
        if (i == 7)  then g.state = "dead"; end
        if (i == 13) then g.state = "offline"; end
        if (i == 18) then g.state = "ghost"; end
        if (i == 4 or i == 22) then g.debuff = true; end
        if (i == 9 or i == 31) then g.outOfRange = true; end
        if (i == 11) then g.los = true; end
        if (i == 2 or i == 26) then g.buffMissing = true; end
        if (i == 15) then g.shield = 500; end
        if (i == 16 or i == 33) then g.inc = 800; end
        FBRaidTestGhosts[i] = g;
    end
end

function FBRaid_InRaid()
    local n = GetNumRaidMembers();
    return (n and n > 0);
end

-- true, wenn das Raster ueberhaupt gezeigt werden soll
-- true, wenn das Raster ueberhaupt gezeigt werden soll: Raidmodus an,
-- Anzeige an, und entweder Raid-Test oder ein Raid mit mindestens
-- MinPlayers Mitgliedern
function FBRaid_IsActive()
    local cfg = FBRaid_Cfg();
    if (cfg.Enabled ~= 1) then return false; end
    if (HealBox.Active ~= 1) then return false; end
    if (FBRaidTestMode > 0) then return true; end
    local n = GetNumRaidMembers() or 0;
    return (n > 0) and (n >= (cfg.MinPlayers or 11));
end

function FBRaid_Roster()
    local list = {};
    if (FBRaidTestMode > 0) then
        for i, g in ipairs(FBRaidTestGhosts) do
            table.insert(list, { unit = "raid"..i, name = g.name, class = g.class, group = g.group, index = i, ghost = g });
        end
        return list;
    end
    local n = GetNumRaidMembers() or 0;
    for i = 1, n do
        local name, rank, subgroup, level, class, fileName = GetRaidRosterInfo(i);
        if (name) then
            local token = fileName and strupper(fileName) or nil;
            if (not token and class) then token = strupper(class); end
            table.insert(list, { unit = "raid"..i, name = name, class = token, group = subgroup or 1, index = i });
        end
    end
    return list;
end

-- [ Wrapper je Zelle: Geist oder echte Einheit ] -----------------------------

function FBRaid_GhostFraction(g, phase)
    local frac = g.hp + (g.swing or 0) * math.sin((GetTime() * 0.6) + phase);
    if (frac < 0.03) then frac = 0.03; end
    if (frac > 1) then frac = 1; end
    return frac;
end

function FBRaid_Health(cell)
    local g = cell.ghost;
    if (g) then
        return math.floor(g.hpMax * FBRaid_GhostFraction(g, cell.index * 1.3)), g.hpMax;
    end
    return FBUnitHealth(cell.unit);
end

function FBRaid_Mana(cell)
    local g = cell.ghost;
    if (g) then
        if (not g.hasMana) then return 0, 0, false; end
        return math.floor(g.mpMax * g.mp), g.mpMax, true;
    end
    return FBUnitMana(cell.unit);
end

function FBRaid_State(cell)
    if (cell.ghost) then return cell.ghost.state; end
    return FBUnitState(cell.unit);
end

function FBRaid_Dispel(cell)
    local g = cell.ghost;
    if (g) then
        if (g.debuff) then
            for _, dtype in ipairs({ "Magic", "Poison", "Disease", "Curse" }) do
                if (FBDispelColors[dtype]) then return dtype; end
            end
        end
        return nil;
    end
    return FBHealBox_DispelType(cell.unit);
end

function FBRaid_Incoming(cell)
    local g = cell.ghost;
    if (g) then return (g.inc or 0), (g.shield or 0); end
    local name = cell.name;
    return FBGetDirectHeal(name) + FBGetHoTHeal(name) + FBGetCommHeal(name), FBGetShield(name);
end

function FBRaid_InRange(cell)
    if (cell.ghost) then return (not cell.ghost.outOfRange); end
    return FBHealBox_UnitInRange(cell.unit);
end

function FBRaid_LOSBlocked(cell)
    if (cell.ghost) then return (cell.ghost.los == true); end
    return FBUnitLOSBlocked(cell.unit);
end

function FBRaid_HasWatchBuff(cell)
    if (not HealBox.WatchBuff) then return true; end
    if (cell.ghost) then return (not cell.ghost.buffMissing); end
    return FBHealBox_HasWatchBuff(cell.unit);
end

-- ==========================================================================
-- [ Frames ]
-- ==========================================================================

FBRaidFrame = CreateFrame("Frame", "FBHealBoxRaidFrame", UIParent);
FBRaidFrame:SetFrameStrata("MEDIUM");
FBRaidFrame:SetWidth(10);
FBRaidFrame:SetHeight(10);
FBRaidFrame:SetMovable(true);
FBRaidFrame:EnableMouse(false);
FBRaidFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0);
FBRaidFrame:Hide();

-- Titelleiste (Griff)
FBRaidFrame.Title = CreateFrame("Button", "FBHealBoxRaidTitle", FBRaidFrame);
FBRaidFrame.Title:SetHeight(FBRAID_TITLE_H);
FBRaidFrame.Title:SetPoint("TOPLEFT", FBRaidFrame, "TOPLEFT", 0, 0);
FBRaidFrame.Title:SetPoint("TOPRIGHT", FBRaidFrame, "TOPRIGHT", 0, 0);
FBRaidFrame.Title:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    tile = true, tileSize = 16,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
});
FBRaidFrame.Title:SetBackdropColor(0, 0, 0, 0.6);
FBRaidFrame.Title.text = FBRaidFrame.Title:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
FBRaidFrame.Title.text:SetPoint("LEFT", 4, 0);
FBRaidFrame.Title.text:SetTextColor(1, 0.82, 0, 1);
FBRaidFrame.Title:RegisterForDrag("LeftButton");
FBRaidFrame.Title:SetScript("OnDragStart", function() FBRaid_StartDrag(); end);
FBRaidFrame.Title:SetScript("OnDragStop", function() FBRaid_StopDrag(); end);
FBRaidFrame.Title:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
    GameTooltip:SetText(FBT("RAID_MOVE_TIP"));
    GameTooltip:Show();
end);
FBRaidFrame.Title:SetScript("OnLeave", function() GameTooltip:Hide(); end);

function FBRaid_StartDrag()
    FBRaidDragging = true;
    FBRaidFrame:StartMoving();
end

function FBRaid_StopDrag()
    FBRaidDragging = false;
    FBRaidFrame:StopMovingOrSizing();
    FBRaid_SavePosition();
end

function FBRaid_SavePosition()
    local cfg = FBRaid_Cfg();
    local left, top = FBRaidFrame:GetLeft(), FBRaidFrame:GetTop();
    if (not left) or (not top) then return; end
    local s = FBRaidFrame:GetEffectiveScale();
    cfg.PosX = left * s;
    cfg.PosY = top * s;
end

function FBRaid_RestorePosition()
    local cfg = FBRaid_Cfg();
    FBRaidFrame:ClearAllPoints();
    if (cfg.PosX and cfg.PosY) then
        local s = FBRaidFrame:GetEffectiveScale();
        FBRaidFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", cfg.PosX / s, cfg.PosY / s);
    else
        FBRaidFrame:SetPoint("CENTER", UIParent, "CENTER", 0, -150);
    end
end

-- [ Zelle ] ------------------------------------------------------------------

function FBRaid_GetGroupFrame(g)
    if (FBRaidGroups[g]) then return FBRaidGroups[g]; end
    local f = CreateFrame("Frame", "FBHealBoxRaidGroup"..g, FBRaidFrame);
    f.header = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    f.header:SetPoint("TOPLEFT", f, "TOPLEFT", 2, 0);
    f.header:SetTextColor(1, 0.82, 0, 1);
    f.header:SetText(tostring(g));
    f:Hide();
    FBRaidGroups[g] = f;
    return f;
end

function FBRaid_CreateCell(g, pos)
    local parent = FBRaid_GetGroupFrame(g);
    local c = CreateFrame("Frame", "FBHealBoxRaidCell"..g.."_"..pos, parent);
    c:SetFrameStrata("MEDIUM");
    c:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 8,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    });
    c:SetBackdropColor(0, 0, 0, 0.8);
    c:SetBackdropBorderColor(1, 1, 1, 1);
    c.group = g;
    c.pos   = pos;
    c.buttons = {};

    -- Balken: Vorhersage unten, Schild, Leben, Mana oben
    c.IncHealBar = CreateFrame("STATUSBAR", nil, c, "TextStatusBar");
    c.ShieldBar  = CreateFrame("STATUSBAR", nil, c, "TextStatusBar");
    c.HealthBar  = CreateFrame("STATUSBAR", nil, c, "TextStatusBar");
    c.ManaBar    = CreateFrame("STATUSBAR", nil, c, "TextStatusBar");
    -- Ebenen relativ zur Zelle, damit der Zellenhintergrund darunter bleibt
    local base = 0;
    if (c.GetFrameLevel) then base = c:GetFrameLevel() or 0; end
    local bars = { c.IncHealBar, c.ShieldBar, c.HealthBar, c.ManaBar };
    for i, b in ipairs(bars) do
        b:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
        b:SetPoint("TOPLEFT", c, "TOPLEFT", 2, -2);
        b:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -2, 2);
        b:SetMinMaxValues(0, 1);
        b:SetValue(0);
        b:SetFrameStrata("MEDIUM");
        b:SetFrameLevel(base + i);
    end
    c.IncHealBar:SetStatusBarColor(0.4, 1, 0.4, 0.5);
    c.ShieldBar:SetStatusBarColor(0.6, 0.8, 1.0, 0.5);
    c.HealthBar:SetStatusBarColor(0, 1, 0, 1);
    c.ManaBar:ClearAllPoints();
    c.ManaBar:SetPoint("BOTTOMLEFT", c, "BOTTOMLEFT", 2, 2);
    c.ManaBar:SetPoint("BOTTOMRIGHT", c, "BOTTOMRIGHT", -2, 2);
    c.ManaBar:SetHeight(FBRAID_MANA_H);
    c.ManaBar:SetStatusBarColor(FBMANA_BAR_COLOR[1], FBMANA_BAR_COLOR[2], FBMANA_BAR_COLOR[3], FBMANA_BAR_COLOR[4]);
    c.ManaBar.bg = c.ManaBar:CreateTexture(nil, "BACKGROUND");
    c.ManaBar.bg:SetAllPoints(c.ManaBar);
    c.ManaBar.bg:SetTexture(0, 0, 0, FBMANA_BG_ALPHA);
    c.ManaBar:Hide();

    -- Texte
    c.NameText = c:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall");
    c.NameText:SetPoint("LEFT", c, "LEFT", 4, 0);
    c.NameText:SetJustifyH("LEFT");
    c.HPText = c:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall");
    c.HPText:SetPoint("RIGHT", c, "RIGHT", -3, 0);
    c.HPText:SetJustifyH("RIGHT");
    c.HPText:SetTextColor(1, 1, 1, 1);

    -- Sichtlinie: kleines Auge oben links
    c.LOSIcon = c:CreateTexture(nil, "OVERLAY");
    c.LOSIcon:SetWidth(FBRAID_LOS_SIZE);
    c.LOSIcon:SetHeight(FBRAID_LOS_SIZE);
    c.LOSIcon:SetPoint("TOPLEFT", c, "TOPLEFT", -3, 3);
    c.LOSIcon:SetTexture(FBLOS_ICON);
    c.LOSIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93);
    c.LOSIcon:Hide();

    -- Klick: Anvisieren (bzw. Plaketten-Aktion), Shift-Ziehen verschiebt
    c:EnableMouse(true);
    c:SetScript("OnMouseDown", function() FBRaid_CellMouseDown(c); end);
    c:SetScript("OnMouseUp", function() FBRaid_CellMouseUp(c); end);

    -- Mini-Buttons: Kern-Button (Tooltip, Cast, Faerbung), nur kleiner
    for i = 1, FBRAID_MAX_BUTTONS do
        local b = FBHealBoxCreateButton("FBHealBoxRaidCell"..g.."_"..pos.."Btn"..i, c, 1, 0,
                    FBDropDownButtonIcon[i], FBDropDownButton[i], nil, FBActiveSpellIDs[i]);
        b.raidCell = c;
        b.btnIndex = i;
        b:SetScript("OnClick", function()
            if (FBDragSpell) then
                local side = "L";
                if (arg1 == "RightButton" or IsShiftKeyDown()) then side = "R"; end
                if (FBHealBox_DropSpell(i, side)) then return; end
            end
            if (FBRaidTestMode > 0) then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00"..FBADDON_NAME..":|r "..FBT("RAID_TEST_CLICK"));
                return;
            end
            local castString = b.spellName;
            if (arg1 == "RightButton") then
                if (HealBox.RightClick ~= 1) then return; end
                castString = b.spellNameR;
            end
            FBHealBox_CastOn(b, castString);
        end);
        b:Hide();
        c.buttons[i] = b;
    end

    c:Hide();
    return c;
end

function FBRaid_GetCell(g, pos)
    if (not FBRaidCells[g]) then FBRaidCells[g] = {}; end
    if (not FBRaidCells[g][pos]) then FBRaidCells[g][pos] = FBRaid_CreateCell(g, pos); end
    return FBRaidCells[g][pos];
end

-- [ Klick auf eine Zelle ] ------------------------------------------------------

function FBRaid_CellMouseDown(c)
    local action = FBHealBox_PlateAction(arg1);
    if (action == "move" or (arg1 == "LeftButton" and IsShiftKeyDown())) then
        FBRaid_StartDrag();
    end
end

function FBRaid_CellMouseUp(c)
    if (FBRaidDragging) then
        FBRaid_StopDrag();
        return;
    end
    local action = FBHealBox_PlateAction(arg1);
    if (action == "none" or action == "move") or (not c.unit) then return; end
    if (c.ghost) then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00"..FBADDON_NAME..":|r "..FBT("RAID_TEST_CLICK"));
        return;
    end
    if (not UnitExists(c.unit)) then return; end
    if (action == "menu" and FriendsDropDown and RaidFrameDropDown_Initialize and ToggleDropDownMenu) then
        -- wie Blizzards Raid-Fenster: Einheitenmenue ueber FriendsDropDown
        local ok = pcall(function()
            FriendsDropDown.unit = c.unit;
            FriendsDropDown.name = c.name;
            FriendsDropDown.id   = c.index;
            FriendsDropDown.initialize  = RaidFrameDropDown_Initialize;
            FriendsDropDown.displayMode = "MENU";
            ToggleDropDownMenu(1, nil, FriendsDropDown, "cursor");
        end);
        if (ok) then return; end
    end
    TargetUnit(c.unit);
end

-- ==========================================================================
-- [ Roster -> Zellen ]
-- ==========================================================================

function FBRaid_UpdateRoster()
    local cfg = FBRaid_Cfg();
    FBRaidUnitCell = {};
    FBRaidMembers = 0;
    local perGroup = {};
    for g = 1, FBRAID_GROUPS do perGroup[g] = 0; end

    -- alle Zellen zuruecksetzen
    for g = 1, FBRAID_GROUPS do
        for pos = 1, FBRAID_PER_GROUP do
            if (FBRaidCells[g] and FBRaidCells[g][pos]) then
                local c = FBRaidCells[g][pos];
                c.unit = nil; c.name = nil; c.ghost = nil; c.index = nil;
                c:Hide();
            end
        end
    end

    if (FBRaid_IsActive()) then
        for _, m in ipairs(FBRaid_Roster()) do
            local g = m.group;
            if (g >= 1 and g <= FBRAID_GROUPS and perGroup[g] < FBRAID_PER_GROUP) then
                perGroup[g] = perGroup[g] + 1;
                local c = FBRaid_GetCell(g, perGroup[g]);
                c.unit  = m.unit;
                c.name  = m.name;
                c.index = m.index;
                c.ghost = m.ghost;
                c.classToken = m.class;
                c.NameText:SetText(m.name or "");
                local col = nil;
                if (HealBox.ClassColors == 1) then col = FBClassColor(m.class); end
                if (col) then c.NameText:SetTextColor(col.r, col.g, col.b, 1); else c.NameText:SetTextColor(1, 1, 1, 1); end
                FBRaidUnitCell[m.unit] = c;
                FBRaidMembers = FBRaidMembers + 1;
                c:Show();
            end
        end
    end

    FBRaidUsedGroups = 0;
    for g = 1, FBRAID_GROUPS do
        if (perGroup[g] > 0) then FBRaidUsedGroups = FBRaidUsedGroups + 1; end
    end

    FBRaid_LayoutAll();
    FBRaid_UpdateVisibility();
    FBRaid_SyncButtons();
    FBRaid_RefreshAll();
    FBRaid_Tick(true);
end

-- ==========================================================================
-- [ Layout ]
-- ==========================================================================

-- Breite einer Zelle samt ihrer Buttons
function FBRaid_RowWidth(cfg)
    local w = cfg.CellW;
    if (cfg.Buttons > 0) then w = w + cfg.Buttons * (cfg.ButtonSize + 1); end
    return w;
end

function FBRaid_ApplyCellSize(c, cfg)
    c:SetWidth(cfg.CellW);
    c:SetHeight(cfg.CellH);
    -- Namensbreite: Rest neben dem HP-Text
    local nameW = cfg.CellW - 8;
    if (cfg.HPText ~= "none") then nameW = cfg.CellW - 34; end
    if (nameW < 10) then nameW = 10; end
    c.NameText:SetWidth(nameW);
    -- Buttons rechts an der Zelle, quadratisch, vertikal zentriert
    local prev = c;
    for i = 1, FBRAID_MAX_BUTTONS do
        local b = c.buttons[i];
        b:SetWidth(cfg.ButtonSize);
        b:SetHeight(cfg.ButtonSize);
        b:ClearAllPoints();
        b:SetPoint("LEFT", prev, "RIGHT", 1, 0);
        if (i <= cfg.Buttons) then b:Show(); else b:Hide(); end
        prev = b;
    end
end

function FBRaid_LayoutAll()
    local cfg = FBRaid_Cfg();
    local rowW   = FBRaid_RowWidth(cfg);
    local headH  = 0;
    if (cfg.Headers == 1) then headH = FBRAID_HEADER_H; end
    local blockH = headH + FBRAID_PER_GROUP * cfg.CellH + (FBRAID_PER_GROUP - 1) * cfg.CellGap;
    local titleH = 0;
    if (cfg.ShowTitle == 1) then titleH = FBRAID_TITLE_H + 2; FBRaidFrame.Title:Show(); else FBRaidFrame.Title:Hide(); end

    FBRaidFrame:SetScale(cfg.Scale or 1);

    local perRow = cfg.GroupsPerRow;
    if (perRow < 1) then perRow = 1; end
    if (perRow > FBRAID_GROUPS) then perRow = FBRAID_GROUPS; end

    local col, row = 0, 0;
    local maxCols = 0;
    for g = 1, FBRAID_GROUPS do
        local f = FBRaid_GetGroupFrame(g);
        local used = 0;
        if (FBRaidCells[g]) then
            for pos = 1, FBRAID_PER_GROUP do
                local c = FBRaidCells[g][pos];
                if (c and c:IsShown()) then used = used + 1; end
            end
        end
        local show = (used > 0) or (cfg.HideEmpty ~= 1 and FBRaid_IsActive());
        if (show) then
            f:SetWidth(rowW);
            f:SetHeight(blockH);
            f:ClearAllPoints();
            f:SetPoint("TOPLEFT", FBRaidFrame, "TOPLEFT",
                col * (rowW + cfg.GroupGap),
                -(titleH + row * (blockH + cfg.GroupGap)));
            if (cfg.Headers == 1) then f.header:Show(); else f.header:Hide(); end
            -- Zellen im Block
            for pos = 1, FBRAID_PER_GROUP do
                local c = FBRaid_GetCell(g, pos);
                FBRaid_ApplyCellSize(c, cfg);
                c:ClearAllPoints();
                c:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -(headH + (pos - 1) * (cfg.CellH + cfg.CellGap)));
            end
            f:Show();
            col = col + 1;
            if (col > maxCols) then maxCols = col; end
            if (col >= perRow) then col = 0; row = row + 1; end
        else
            f:Hide();
        end
    end

    local rows = row;
    if (col > 0) then rows = rows + 1; end
    if (maxCols < 1) then maxCols = 1; end
    if (rows < 1) then rows = 1; end
    FBRaidFrame:SetWidth(maxCols * rowW + (maxCols - 1) * cfg.GroupGap);
    FBRaidFrame:SetHeight(titleH + rows * blockH + (rows - 1) * cfg.GroupGap);
    FBRaidFrame.Title.text:SetText(FBT("RAID_TITLE").." ("..FBRaidMembers..")");
end

-- Raster zeigen / verstecken, Gruppenplaketten bei Bedarf ausblenden.
-- Was das Modul versteckt hat, gibt es auch selbst wieder frei (etwa wenn
-- der Raid unter die Schwelle faellt und nur RAID_ROSTER_UPDATE feuert).
FBRaidHidParty = false;
function FBRaid_UpdateVisibility()
    local cfg = FBRaid_Cfg();
    if (FBRaid_IsActive()) then
        FBRaidFrame:Show();
        if (cfg.HideParty == 1 and FBHealBox1) then
            FBHealBox1:Hide();
            FBRaidHidParty = true;
        elseif (FBRaidHidParty and FBHealBox1 and HealBox.Active == 1) then
            FBHealBox1:Show();
            FBRaidHidParty = false;
        end
    else
        FBRaidFrame:Hide();
        if (FBRaidHidParty and FBHealBox1 and HealBox.Active == 1) then
            FBHealBox1:Show();
            FBRaidHidParty = false;
        end
    end
end

-- ==========================================================================
-- [ Zelleninhalt ]
-- ==========================================================================

function FBRaid_UpdateCell(c)
    if (not c) or (not c.unit) or (not c:IsShown()) then return; end
    local cfg = FBRaid_Cfg();
    local hp, hpMax = FBRaid_Health(c);
    if (hpMax <= 0) then hpMax = 1; end
    local state = FBRaid_State(c);

    if (state) then
        local key = "STATE_DEAD";
        if (state == "ghost") then key = "STATE_GHOST"; end
        if (state == "offline") then key = "STATE_OFFLINE"; end
        c.HPText:SetText(FBT(key));
        c.HPText:Show();
        c.HealthBar:SetMinMaxValues(0, hpMax); c.HealthBar:SetValue(0);
        c.HealthBar:SetStatusBarColor(0.5, 0.5, 0.5, 1);
        c.ShieldBar:SetMinMaxValues(0, hpMax); c.ShieldBar:SetValue(0);
        c.IncHealBar:SetMinMaxValues(0, hpMax); c.IncHealBar:SetValue(0);
        c.ManaBar:Hide();
        return;
    end

    -- Leben und Schichten
    c.HealthBar:SetMinMaxValues(0, hpMax);
    c.HealthBar:SetValue(hp);
    local inc, shield = FBRaid_Incoming(c);
    local shieldTop = math.min(hpMax, hp + shield);
    c.ShieldBar:SetMinMaxValues(0, hpMax);
    c.ShieldBar:SetValue(shieldTop);
    c.IncHealBar:SetMinMaxValues(0, hpMax);
    c.IncHealBar:SetValue(math.min(hpMax, shieldTop + inc));

    -- HP-Text
    if (cfg.HPText == "percent") then
        c.HPText:SetText(format("%d%%", math.floor(hp / hpMax * 100)));
        c.HPText:Show();
    elseif (cfg.HPText == "deficit") then
        local def = hpMax - hp;
        if (def > 0) then c.HPText:SetText("-"..def); else c.HPText:SetText(""); end
        c.HPText:Show();
    else
        c.HPText:Hide();
    end

    -- Mana
    local mp, mpMax, hasMana = FBRaid_Mana(c);
    if (cfg.ManaBar == 1 and hasMana and mpMax > 0) then
        c.ManaBar:SetMinMaxValues(0, mpMax);
        c.ManaBar:SetValue(mp);
        c.ManaBar:Show();
    else
        c.ManaBar:Hide();
    end

    -- Farbe: Dispel schlaegt HP-Stand
    local frac = hp / hpMax;
    local dtype = FBRaid_Dispel(c);
    if (dtype and FBDispelColors[dtype]) then
        local col = FBDispelColors[dtype];
        c.HealthBar:SetStatusBarColor(col[1], col[2], col[3], col[4]);
    elseif (frac > LowHP) then
        c.HealthBar:SetStatusBarColor(0, 1, 0, 1);
    elseif (frac > VeryLowHP) then
        c.HealthBar:SetStatusBarColor(1, 0.9, 0, 1);
    else
        c.HealthBar:SetStatusBarColor(1, 0, 0, 1);
    end
end

-- Rahmen: Buff-Wache (orange) oder normal
function FBRaid_UpdateBuffBorder(c)
    if (not c) or (not c.unit) then return; end
    local missing = false;
    if (HealBox.WatchBuff and c:IsShown()) then
        missing = (not FBRaid_HasWatchBuff(c));
    end
    if (c.buffMissing ~= missing) then
        c.buffMissing = missing;
        local col = FBBUFF_NORMAL_COLOR;
        if (missing) then col = FBBUFF_MISSING_COLOR; end
        c:SetBackdropBorderColor(col[1], col[2], col[3], col[4]);
    end
end

function FBRaid_RefreshAll()
    if (not FBRaid_IsActive()) then return; end
    for g = 1, FBRAID_GROUPS do
        if (FBRaidCells[g]) then
            for pos = 1, FBRAID_PER_GROUP do
                local c = FBRaidCells[g][pos];
                if (c and c.unit) then FBRaid_UpdateCell(c); end
            end
        end
    end
end

function FBRaid_RefreshBuffBorders()
    for g = 1, FBRAID_GROUPS do
        if (FBRaidCells[g]) then
            for pos = 1, FBRAID_PER_GROUP do
                local c = FBRaidCells[g][pos];
                if (c and c.unit) then FBRaid_UpdateBuffBorder(c); end
            end
        end
    end
end

-- Buttons einer Zelle an die Belegung angleichen (Icons, Zauber, Rechtsklick)
function FBRaid_SyncButtons()
    local rightOn = (HealBox.RightClick == 1);
    for g = 1, FBRAID_GROUPS do
        if (FBRaidCells[g]) then
            for pos = 1, FBRAID_PER_GROUP do
                local c = FBRaidCells[g][pos];
                if (c) then
                    for i = 1, FBRAID_MAX_BUTTONS do
                        local b = c.buttons[i];
                        b.TargetUnit = c.unit;
                        b.spellName  = FBDropDownButton[i];
                        b.id         = FBActiveSpellIDs[i];
                        if (FBDropDownButtonIcon[i]) then
                            b.icon:SetTexture(FBDropDownButtonIcon[i]);
                        else
                            b.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
                        end
                        if (rightOn) then
                            b.spellNameR = FBDropDownButtonR[i];
                            b.idR = FBActiveSpellIDsR[i];
                        else
                            b.spellNameR = nil;
                            b.idR = nil;
                        end
                        if (b.subIcon) then
                            if (b.spellNameR and FBDropDownButtonIconR[i]) then
                                b.subIcon:SetTexture(FBDropDownButtonIconR[i]);
                                b.subIcon:Show();
                            else
                                b.subIcon:Hide();
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Reichweite, Sichtlinie und Geister-Atmung im Takt
function FBRaid_Tick(force)
    if (not FBRaid_IsActive()) then return; end
    for g = 1, FBRAID_GROUPS do
        if (FBRaidCells[g]) then
            for pos = 1, FBRAID_PER_GROUP do
                local c = FBRaidCells[g][pos];
                if (c and c.unit and c:IsShown()) then
                    local faded = false;
                    if (HealBox.RangeFade == 1) then faded = (not FBRaid_InRange(c)); end
                    if (force or c.rangeFaded ~= faded) then
                        c.rangeFaded = faded;
                        if (faded) then c:SetAlpha(FBRANGE_ALPHA); else c:SetAlpha(1); end
                    end
                    local blocked = false;
                    if (HealBox.LOSIcon == 1) then blocked = FBRaid_LOSBlocked(c); end
                    if (force or c.losBlocked ~= blocked) then
                        c.losBlocked = blocked;
                        if (blocked) then c.LOSIcon:Show(); else c.LOSIcon:Hide(); end
                    end
                end
            end
        end
    end
end

-- ==========================================================================
-- [ Events ]
-- ==========================================================================

FBRaidEventFrame = CreateFrame("Frame", "FBHealBoxRaidEvents", UIParent);
FBRaidEventFrame:RegisterEvent("RAID_ROSTER_UPDATE");
FBRaidEventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED");
FBRaidEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
FBRaidEventFrame:RegisterEvent("UNIT_HEALTH");
FBRaidEventFrame:RegisterEvent("UNIT_MAXHEALTH");
FBRaidEventFrame:RegisterEvent("UNIT_MANA");
FBRaidEventFrame:RegisterEvent("UNIT_MAXMANA");
FBRaidEventFrame:RegisterEvent("UNIT_DISPLAYPOWER");
FBRaidEventFrame:RegisterEvent("UNIT_AURA");

FBRaidEventFrame:SetScript("OnEvent", function()
    if (event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" or event == "PLAYER_ENTERING_WORLD") then
        FBRaid_UpdateRoster();
        FBRaid_SyncButtons();
        FBRaid_RefreshBuffBorders();
        return;
    end
    if (FBRaidTestMode > 0) then return; end
    local c = FBRaidUnitCell[arg1];
    if (not c) then return; end
    FBRaid_UpdateCell(c);
    if (event == "UNIT_AURA") then FBRaid_UpdateBuffBorder(c); end
end);

FBRaidEventFrame:SetScript("OnUpdate", function()
    FBRaidTickAccum = FBRaidTickAccum + (arg1 or 0);
    if (FBRaidTickAccum < FBRAID_TICK) then return; end
    FBRaidTickAccum = 0;
    FBRaid_Tick(false);
end);

-- Geister atmen: der Kern ruft RefreshAllBars im 0.2-s-Takt des Testmodus;
-- fuer den Raid-Test haengen wir uns an denselben Takt und fordern ihn an.
FBRaidGhostAccum = 0;
FBRaidEventFrame.ghostTicker = CreateFrame("Frame", nil, UIParent);
FBRaidEventFrame.ghostTicker:SetScript("OnUpdate", function()
    if (FBRaidTestMode == 0) then return; end
    FBRaidGhostAccum = FBRaidGhostAccum + (arg1 or 0);
    if (FBRaidGhostAccum < 0.2) then return; end
    FBRaidGhostAccum = 0;
    FBRaid_RefreshAll();
end);

-- Alle Raid-Einheiten fuer die Aura-Bestaetigung der Vorhersage freischalten
for i = 1, FBRAID_MAX do FBPredictUnits["raid"..i] = 1; end

-- ==========================================================================
-- [ Testmodus ]
-- ==========================================================================

function FBRaid_SetTest(mode)
    mode = tonumber(mode) or 0;
    if (mode ~= 20 and mode ~= 40) then mode = 0; end
    FBRaidTestMode = mode;
    if (mode > 0) then
        FBRaid_BuildTestGhosts(mode);
        if (HealBox.Active ~= 1) then HealBox.Active = 1; end
        if (FBRaid_Cfg().Enabled ~= 1) then
            FBRaid_Cfg().Enabled = 1;
            if (FBRaidEnabledCheck) then FBRaidEnabledCheck:SetChecked(1); end
        end
    end
    FBRaid_UpdateTestLabel();
    FBUpdateNames();              -- Plaketten neu bewerten (Hook ruft unser Roster)
end

function FBRaid_UpdateTestLabel()
    if (not FBRaidTestBtn) then return; end
    local key = "RAID_TEST_OFF";
    if (FBRaidTestMode == 20) then key = "RAID_TEST_20"; end
    if (FBRaidTestMode == 40) then key = "RAID_TEST_40"; end
    FBRaidTestBtn.text:SetText(FBT("RAID_TEST")..": |cFFFFFFFF"..FBT(key));
end

function FBRaid_UpdateHPTextLabel()
    if (not FBRaidHPTextBtn) then return; end
    local cfg = FBRaid_Cfg();
    local key = "RAID_HP_PERCENT";
    if (cfg.HPText == "none") then key = "RAID_HP_NONE"; end
    if (cfg.HPText == "deficit") then key = "RAID_HP_DEFICIT"; end
    FBRaidHPTextBtn.text:SetText(FBT("RAID_HPTEXT")..": |cFFFFFFFF"..FBT(key));
end

-- ==========================================================================
-- [ Options-Reiter "Raidmodus" ]
-- ==========================================================================

FBRaidSliders = {};   -- key -> Slider (fuer Beschriftung und Sync)

function FBRaid_SliderText(slider)
    if (not slider or not slider.Text) then return; end
    local v = slider:GetValue();
    local shown;
    if (slider.decimals) then shown = format("%.1f", v); else shown = tostring(math.floor(v + 0.5)); end
    slider.Text:SetText(format(FBT(slider.labelKey), shown));
end

function FBRaid_CreateSlider(name, parent, x, y, labelKey, cfgKey, minV, maxV, step, decimals, onChange)
    local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate");
    s:SetWidth(128);
    s:SetHeight(16);
    s:SetPoint("TOPLEFT", x, y);
    s:SetMinMaxValues(minV, maxV);
    s:SetValueStep(step);
    s.labelKey = labelKey;
    s.cfgKey = cfgKey;
    s.decimals = decimals;
    s.Text = s:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
    s.Text:SetPoint("CENTER", 0, 15);
    getglobal(name.."Low"):SetText(tostring(minV));
    getglobal(name.."High"):SetText(tostring(maxV));
    s:SetValue(FBRaid_Cfg()[cfgKey] or minV);
    FBRaid_SliderText(s);
    s:SetScript("OnValueChanged", function()
        local v = s:GetValue();
        if (not s.decimals) then v = math.floor(v + 0.5); end
        FBRaid_Cfg()[s.cfgKey] = v;
        FBRaid_SliderText(s);
        if (onChange) then onChange(); end
    end);
    FBRaidSliders[cfgKey] = s;
    return s;
end

function FBRaid_BuildOptions()
    local tab = FBHealBox_AddOptionsTab("TAB_RAID");
    if (not tab) then return; end
    FBRaidOptionsTab = tab;
    local y = FBOPT_CONTENT_Y - 8;

    FBRaidEnabledCheck = FBHealBox_CreateCheck("FBHealBoxRaidEnabledCheck", tab, 40, y, "RAID_ENABLED", "RAID_ENABLED_TIP", function()
        FBRaid_Cfg().Enabled = FBRaidEnabledCheck:GetChecked() and 1 or 0;
        if (FBRaid_Cfg().Enabled == 0 and FBRaidTestMode > 0) then FBRaid_SetTest(0); end
        FBUpdateNames();
    end);
    FBRaidHidePartyCheck = FBHealBox_CreateCheck("FBHealBoxRaidHidePartyCheck", tab, 250, y, "RAID_HIDEPARTY", "RAID_HIDEPARTY_TIP", function()
        FBRaid_Cfg().HideParty = FBRaidHidePartyCheck:GetChecked() and 1 or 0;
        FBUpdateNames();
    end);
    FBRaidHeadersCheck = FBHealBox_CreateCheck("FBHealBoxRaidHeadersCheck", tab, 40, y - 30, "RAID_HEADERS", "RAID_HEADERS_TIP", function()
        FBRaid_Cfg().Headers = FBRaidHeadersCheck:GetChecked() and 1 or 0;
        FBRaid_LayoutAll();
    end);
    FBRaidManaCheck = FBHealBox_CreateCheck("FBHealBoxRaidManaCheck", tab, 250, y - 30, "RAID_MANABAR", "RAID_MANABAR_TIP", function()
        FBRaid_Cfg().ManaBar = FBRaidManaCheck:GetChecked() and 1 or 0;
        FBRaid_RefreshAll();
    end);
    FBRaidHideEmptyCheck = FBHealBox_CreateCheck("FBHealBoxRaidHideEmptyCheck", tab, 40, y - 60, "RAID_HIDEEMPTY", "RAID_HIDEEMPTY_TIP", function()
        FBRaid_Cfg().HideEmpty = FBRaidHideEmptyCheck:GetChecked() and 1 or 0;
        FBRaid_LayoutAll();
    end);
    FBRaidTitleCheck = FBHealBox_CreateCheck("FBHealBoxRaidTitleCheck", tab, 250, y - 60, "RAID_SHOWTITLE", "RAID_SHOWTITLE_TIP", function()
        FBRaid_Cfg().ShowTitle = FBRaidTitleCheck:GetChecked() and 1 or 0;
        FBRaid_LayoutAll();
    end);

    -- HP-Text: Auswahlknopf mit Kaskadenmenue
    FBRaidHPTextBtn = FBHealBox_CreatePickButton("FBHealBoxRaidHPTextBtn", tab, 35, y - 96, 180, 26, 18);
    FBRaidHPTextBtn.icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01");
    FBRaidHPTextBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
        GameTooltip:SetText(FBT("RAID_HPTEXT"));
        GameTooltip:AddLine(FBT("RAID_HPTEXT_TIP"), 1, 1, 1, true);
        GameTooltip:Show();
    end);
    FBRaidHPTextBtn:SetScript("OnLeave", function() GameTooltip:Hide(); end);
    FBRaidHPTextBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn");
        if (FBMenu_IsOpen()) then FBMenu_CloseAll(); return; end
        local entries = {};
        for _, v in ipairs({ { "none", "RAID_HP_NONE" }, { "percent", "RAID_HP_PERCENT" }, { "deficit", "RAID_HP_DEFICIT" } }) do
            local e = {};
            e.text = FBT(v[2]);
            e.mode = v[1];
            e.func = function(entry)
                FBRaid_Cfg().HPText = entry.mode;
                FBRaid_UpdateHPTextLabel();
                FBRaid_LayoutAll();
                FBRaid_RefreshAll();
                FBMenu_CloseAll();
            end
            table.insert(entries, e);
        end
        FBMenu_OpenMenu(entries, FBRaidHPTextBtn);
    end);

    -- Raid-Test: aus / 20 / 40
    FBRaidTestBtn = FBHealBox_CreatePickButton("FBHealBoxRaidTestBtn", tab, 245, y - 96, 180, 26, 18);
    FBRaidTestBtn.icon:SetTexture("Interface\\Icons\\Spell_Shadow_Twilight");
    FBRaidTestBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
        GameTooltip:SetText(FBT("RAID_TEST"));
        GameTooltip:AddLine(FBT("RAID_TEST_TIP"), 1, 1, 1, true);
        GameTooltip:Show();
    end);
    FBRaidTestBtn:SetScript("OnLeave", function() GameTooltip:Hide(); end);
    FBRaidTestBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn");
        if (FBMenu_IsOpen()) then FBMenu_CloseAll(); return; end
        local entries = {};
        for _, v in ipairs({ { 0, "RAID_TEST_OFF" }, { 20, "RAID_TEST_20" }, { 40, "RAID_TEST_40" } }) do
            local e = {};
            e.text = FBT(v[2]);
            e.mode = v[1];
            e.func = function(entry)
                FBRaid_SetTest(entry.mode);
                FBMenu_CloseAll();
            end
            table.insert(entries, e);
        end
        FBMenu_OpenMenu(entries, FBRaidTestBtn);
    end);

    -- Schieberegler (Beschriftung sitzt ueber dem Regler)
    local sy = y - 150;
    FBRaid_CreateSlider("FBRaidGroupsPerRowSlider", tab, 75, sy, "RAID_GROUPSPERROW", "GroupsPerRow", 1, 8, 1, false, FBRaid_LayoutAll);
    FBRaid_CreateSlider("FBRaidScaleSlider", tab, 260, sy, "RAID_SCALE", "Scale", 0.5, 1.5, 0.1, true, FBRaid_LayoutAll);
    FBRaid_CreateSlider("FBRaidCellWSlider", tab, 75, sy - 50, "RAID_CELLW", "CellW", 50, 120, 1, false, FBRaid_LayoutAll);
    FBRaid_CreateSlider("FBRaidCellHSlider", tab, 260, sy - 50, "RAID_CELLH", "CellH", 14, 32, 1, false, FBRaid_LayoutAll);
    FBRaid_CreateSlider("FBRaidButtonsSlider", tab, 75, sy - 100, "RAID_BUTTONS", "Buttons", 0, FBRAID_MAX_BUTTONS, 1, false, FBRaid_LayoutAll);
    FBRaid_CreateSlider("FBRaidBtnSizeSlider", tab, 260, sy - 100, "RAID_BTNSIZE", "ButtonSize", 12, 28, 1, false, FBRaid_LayoutAll);
    FBRaid_CreateSlider("FBRaidCellGapSlider", tab, 75, sy - 150, "RAID_CELLGAP", "CellGap", 0, 10, 1, false, FBRaid_LayoutAll);
    FBRaid_CreateSlider("FBRaidGroupGapSlider", tab, 260, sy - 150, "RAID_GROUPGAP", "GroupGap", 0, 20, 1, false, FBRaid_LayoutAll);
    -- Schwelle: ab wie vielen Mitgliedern die Raid-Ansicht uebernimmt
    FBRaid_CreateSlider("FBRaidMinPlayersSlider", tab, 75, sy - 200, "RAID_MINPLAYERS", "MinPlayers", 2, 40, 1, false, function() FBUpdateNames(); end);

    -- Hinweis zu den Buttons
    FBRaidInfoText = tab:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall");
    FBRaidInfoText:SetPoint("TOPLEFT", tab, "TOPLEFT", 245, sy - 210);
    FBRaidInfoText:SetWidth(185);
    FBRaidInfoText:SetJustifyH("LEFT");
    FBRaidInfoText:SetText(FBT("RAID_INFO"));

    FBRaid_SyncOptions();
end

function FBRaid_SyncOptions()
    local cfg = FBRaid_Cfg();
    if (FBRaidEnabledCheck) then FBRaidEnabledCheck:SetChecked(cfg.Enabled == 1); end
    if (FBRaidHidePartyCheck) then FBRaidHidePartyCheck:SetChecked(cfg.HideParty == 1); end
    if (FBRaidHeadersCheck) then FBRaidHeadersCheck:SetChecked(cfg.Headers == 1); end
    if (FBRaidManaCheck) then FBRaidManaCheck:SetChecked(cfg.ManaBar == 1); end
    if (FBRaidHideEmptyCheck) then FBRaidHideEmptyCheck:SetChecked(cfg.HideEmpty == 1); end
    if (FBRaidTitleCheck) then FBRaidTitleCheck:SetChecked(cfg.ShowTitle == 1); end
    for key, s in pairs(FBRaidSliders) do
        if (cfg[key] ~= nil) then s:SetValue(cfg[key]); end
    end
    FBRaid_UpdateHPTextLabel();
    FBRaid_UpdateTestLabel();
    return true;
end

function FBRaid_ApplyLocale()
    if (FBRaidEnabledCheck) then FBRaidEnabledCheck.Text:SetText(FBT("RAID_ENABLED")); FBRaidEnabledCheck.tooltipText = FBT("RAID_ENABLED_TIP"); end
    if (FBRaidHidePartyCheck) then FBRaidHidePartyCheck.Text:SetText(FBT("RAID_HIDEPARTY")); FBRaidHidePartyCheck.tooltipText = FBT("RAID_HIDEPARTY_TIP"); end
    if (FBRaidHeadersCheck) then FBRaidHeadersCheck.Text:SetText(FBT("RAID_HEADERS")); FBRaidHeadersCheck.tooltipText = FBT("RAID_HEADERS_TIP"); end
    if (FBRaidManaCheck) then FBRaidManaCheck.Text:SetText(FBT("RAID_MANABAR")); FBRaidManaCheck.tooltipText = FBT("RAID_MANABAR_TIP"); end
    if (FBRaidHideEmptyCheck) then FBRaidHideEmptyCheck.Text:SetText(FBT("RAID_HIDEEMPTY")); FBRaidHideEmptyCheck.tooltipText = FBT("RAID_HIDEEMPTY_TIP"); end
    if (FBRaidTitleCheck) then FBRaidTitleCheck.Text:SetText(FBT("RAID_SHOWTITLE")); FBRaidTitleCheck.tooltipText = FBT("RAID_SHOWTITLE_TIP"); end
    if (FBRaidInfoText) then FBRaidInfoText:SetText(FBT("RAID_INFO")); end
    for _, s in pairs(FBRaidSliders) do FBRaid_SliderText(s); end
    FBRaid_UpdateHPTextLabel();
    FBRaid_UpdateTestLabel();
    if (FBRaidFrame and FBRaidFrame.Title) then FBRaidFrame.Title.text:SetText(FBT("RAID_TITLE").." ("..FBRaidMembers..")"); end
    return true;
end

-- ==========================================================================
-- [ Anbindung an den Kern ]
-- ==========================================================================

FBHealBox_RegisterHook("Loaded", function()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00"..FBADDON_NAME..":|r "..FBT("RAID_LOADED"));
    return true;
end);
FBHealBox_RegisterHook("Defaults", function() return FBRaid_ApplyDefaults(); end);
FBHealBox_RegisterHook("SyncOptions", function() return FBRaid_SyncOptions(); end);
FBHealBox_RegisterHook("ApplyLocale", function() return FBRaid_ApplyLocale(); end);

-- Nach jedem Plaketten-Update: Roster neu, Sichtbarkeit (inkl. Ausblenden
-- der Gruppenplaketten) und Position
FBHealBox_RegisterHook("UpdateNames", function()
    FBRaid_RestorePosition();
    FBRaid_UpdateRoster();
    FBRaid_SyncButtons();
    FBRaid_RefreshBuffBorders();
    return true;
end);
FBHealBox_RegisterHook("ActiveToggle", function()
    FBRaid_UpdateVisibility();
    return true;
end);
FBHealBox_RegisterHook("RefreshAllBars", function()
    FBRaid_RefreshAll();
    return true;
end);
FBHealBox_RegisterHook("ButtonsChanged", function()
    FBRaid_SyncButtons();
    return true;
end);
FBHealBox_RegisterHook("Status", function()
    local cfg = FBRaid_Cfg();
    local state = FBT("FBP_STATE_OFF");
    if (cfg.Enabled == 1) then state = FBT("FBP_STATE_ON"); end
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[FBP]|r "..format(FBT("FBP_RAID"), state, FBRaidMembers, FBRaidUsedGroups));
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[FBP]|r "..FBT("FBP_RAID_CMDS"));
    return true;
end);
FBHealBox_RegisterHook("Slash", function(msg)
    if (msg == "raid") then
        local cfg = FBRaid_Cfg();
        if (cfg.Enabled == 1) then cfg.Enabled = 0; else cfg.Enabled = 1; end
        if (cfg.Enabled == 0 and FBRaidTestMode > 0) then FBRaidTestMode = 0; end
        FBRaid_SyncOptions();
        FBUpdateNames();
        return true;
    end
    local _, _, arg = string.find(msg or "", "^raidtest%s*(%w*)$");
    if (arg) then
        if (arg == "off" or arg == "") then FBRaid_SetTest(0); else FBRaid_SetTest(arg); end
        return true;
    end
    return false;
end);

-- Reiter anlegen: das Optionsfenster existiert bereits (Kern laedt zuerst)
FBRaid_ApplyDefaults();
FBRaid_BuildOptions();
