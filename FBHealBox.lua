-- ==========================================================================
-- Heal Box Vanilla
--
-- Original: "Heal Box" von Dourd (Argent Dawn EU) - UI Overhauled.
-- Portierung auf Vanilla 1.12 / Client 1.21.1 (optional SuperWoW) sowie
-- Ausbau des Funktionsumfangs 09/2026 durch Mquadrat:
--   * eigenes Kaskadenmenue fuer die Zauber- und Rangwahl
--   * Heilvorhersage fuer Direktheilung, HoT-Restticks und Absorb-Schilde,
--     selbstkorrigierend ueber den Combatlog
--   * HealComm-Sync mit Puppeteer, pfUI, Luna und Co.
--   * Lokalisierung Deutsch / Englisch, im Optionsfenster umschaltbar
--
-- Ehre wem Ehre gebuehrt: Aufbau, Namensplaketten und Grundidee stammen
-- aus dem Original.
-- ========================================================================== 

FBHasSuperWoW = (SUPERWOW_VERSION ~= nil); 
FBClass = UnitClass("player"); 

-- [[ Globals ]] -- 
HealBox = { 
    MaxButtons = 5, 
    Scale = 1.0, 
    AttachMode = 0, 
    Active = 1, 
    SpellChoice = {}, 
}; 
-- Anzeigename des Addons. FBADDON_FOLDER muss dem Ordnernamen unter
-- Interface\AddOns entsprechen (dort liegt auch die .toc) - nur dann
-- feuert ADDON_LOADED fuer uns.
FBADDON_NAME   = "Heal Box Vanilla";
FBADDON_FOLDER = "FBHealBox";
HealBoxVersion = "|cFFFFFF00v1.4|r"; 

-- ==========================================================================
-- [ Lokalisierung / Localization ]
--
-- Alle sichtbaren Texte liegen in FBLocale. Die aktive Sprache haengt in
-- FBL, abgefragt wird ueber FBT("SCHLUESSEL"). Fehlt ein Schluessel in der
-- gewaehlten Sprache, faellt er auf Englisch zurueck.
--
-- Umgeschaltet wird im Optionsfenster; FBHealBox_ApplyLocale() beschriftet
-- die bereits gebaute Oberflaeche neu, ein /reload ist nicht noetig.
--
-- Hinweis: In den angezeigten Texten bewusst ae/oe/ue/ss statt Umlauten -
-- der 1.12-Client behandelt Umlaute je nach Locale und Schriftart
-- unterschiedlich.
-- ==========================================================================

FBLocale = {};

FBLocale["enUS"] = {
    LANG_NAME     = "English",
    LANGUAGE      = "Language",

    LOADED        = "loaded|r - the minimap button opens the options, /fbp reports the heal prediction.",
    SUPERWOW      = " |cFF55FF55[SuperWoW detected]|r",
    CREDITS       = "|cFFAAAAAAOriginal by Dourd (Argent Dawn EU) - ported to Vanilla and extended 09/2026 by Mquadrat|r",

    TT_NO_SPELL   = "|cFFFFFFFFNo spell\n|cFF00FF00Pick a spell in the options window.",
    TT_TARGET     = "Target",
    NOT_IN_GROUP  = " is not in your group.",

    SELECT_SPELL  = "Select spell...",
    BUTTON        = "Button",
    MENU_NO_SPELL = "|cFF999999No spell|r",
    RANK_DEFAULT  = "Default",

    PANEL_SUB     = "Options for %s.\nChoose how many buttons to show\nand which spell each button casts.",
    SHOW_BUTTONS  = "Show |cFFFFFFFF%s|r buttons",
    SCALE         = "Frame scale: |cFFFFFFFF%s",
    SMALL         = "Small",
    LARGE         = "Large",

    ATTACH        = "Default party frames",
    ATTACH_TIP    = "Attaches the heal buttons to Blizzard's default party frames instead of using the addon's own movable name plates.",
    COMM          = "HealComm sync",
    COMM_TIP      = "Broadcasts your heals in the HealComm format so Puppeteer, pfUI, Luna and others can display them, and feeds the heals announced by other healers into your own prediction.",
    LANG_TIP      = "Switches every text in the addon. Takes effect immediately, no reload required.",

    ABOUT         = "%s %s |cFFAAAAAA- original by Dourd, UI Overhauled|r\n|cFFAAAAAAPorted to Vanilla and extended 09/2026 by Mquadrat|r",
    MM_TIP        = "Left: options\nHold right: move this button\nShift + left: show/hide the display",

    FBP_WATCHED   = "Spells read from the spellbook:",
    FBP_ACTIVE    = "Currently active:",
    FBP_DIRECT    = "direct",
    FBP_SHIELD    = "shield",
    FBP_LEARNED   = "learned",
    FBP_EVERY     = "every",
    FBP_TICKSOF   = "ticks of",
    FBP_CAST      = "Cast",
    FBP_ON        = "on",
    FBP_OF        = "of",
    FBP_FOR       = "for",
    FBP_SYNC      = "HealComm sync:",
    FBP_STATE_ON  = "on",
    FBP_STATE_OFF = "off",
    FBP_INCOMING  = "Incoming",
    FBP_DEBUG     = "Debug:",
    FBP_RESET     = "Learned values discarded.",

    DBG_HOT       = "HoT %s on %s: %d per tick, %ds",
    DBG_SHIELD    = "Shield %s on %s: %d absorb, %ds",
    DBG_CAST      = "Cast %s on %s: %d",
    DBG_TICK      = "Tick corrected: %s = %d",
    DBG_HEAL      = "Heal %s = %d (estimate now %d)",
    DBG_ABSORB    = "Absorb %d on %s (%d left)",
};

FBLocale["deDE"] = {
    LANG_NAME     = "Deutsch",
    LANGUAGE      = "Sprache",

    LOADED        = "geladen|r - der Minimap-Button oeffnet die Optionen, /fbp zeigt den Stand der Heilvorhersage.",
    SUPERWOW      = " |cFF55FF55[SuperWoW erkannt]|r",
    CREDITS       = "|cFFAAAAAAOriginal von Dourd (Argent Dawn EU) - Vanilla-Portierung und Erweiterung 09/2026 von Mquadrat|r",

    TT_NO_SPELL   = "|cFFFFFFFFKein Zauber\n|cFF00FF00Waehle in den Optionen einen Zauber aus.",
    TT_TARGET     = "Ziel",
    NOT_IN_GROUP  = " ist nicht in der Gruppe.",

    SELECT_SPELL  = "Zauber waehlen...",
    BUTTON        = "Button",
    MENU_NO_SPELL = "|cFF999999Kein Zauber|r",
    RANK_DEFAULT  = "Standard",

    PANEL_SUB     = "Optionen fuer %s.\nUnten legst du fest, wie viele Buttons erscheinen\nund welcher Zauber auf welchem Button liegt.",
    SHOW_BUTTONS  = "|cFFFFFFFF%s|r Buttons anzeigen",
    SCALE         = "Skalierung: |cFFFFFFFF%s",
    SMALL         = "Klein",
    LARGE         = "Gross",

    ATTACH        = "Standard-Gruppenfenster",
    ATTACH_TIP    = "Heftet die Heil-Buttons an Blizzards Standard-Gruppenfenster, statt eigene, frei platzierbare Namensplaketten zu verwenden.",
    COMM          = "HealComm-Sync",
    COMM_TIP      = "Sendet deine Heilungen im HealComm-Format an die Gruppe (Puppeteer, pfUI, Luna und Co. zeigen sie an) und uebernimmt umgekehrt die angekuendigten Heilungen anderer Heiler in die eigene Vorhersage.",
    LANG_TIP      = "Stellt alle Texte des Addons um. Wirkt sofort, ein /reload ist nicht noetig.",

    ABOUT         = "%s %s |cFFAAAAAA- Original von Dourd, UI Overhauled|r\n|cFFAAAAAAVanilla-Portierung und Erweiterung 09/2026 von Mquadrat|r",
    MM_TIP        = "Links: Optionen\nRechts halten: Button verschieben\nShift + Links: Anzeige ein/aus",

    FBP_WATCHED   = "Ausgelesene Zauber:",
    FBP_ACTIVE    = "Aktiv:",
    FBP_DIRECT    = "Direkt",
    FBP_SHIELD    = "Schild",
    FBP_LEARNED   = "gelernt",
    FBP_EVERY     = "alle",
    FBP_TICKSOF   = "Ticks a",
    FBP_CAST      = "Cast",
    FBP_ON        = "auf",
    FBP_OF        = "von",
    FBP_FOR       = "fuer",
    FBP_SYNC      = "HealComm-Sync:",
    FBP_STATE_ON  = "an",
    FBP_STATE_OFF = "aus",
    FBP_INCOMING  = "Fremdheilung",
    FBP_DEBUG     = "Debug:",
    FBP_RESET     = "Gelernte Werte verworfen.",

    DBG_HOT       = "HoT %s auf %s: %d pro Tick, %ds",
    DBG_SHIELD    = "Schild %s auf %s: %d Absorb, %ds",
    DBG_CAST      = "Cast %s auf %s: %d",
    DBG_TICK      = "Tick korrigiert: %s = %d",
    DBG_HEAL      = "Heilung %s = %d (Schaetzung jetzt %d)",
    DBG_ABSORB    = "Absorb %d auf %s (Rest %d)",
};

FBL = nil;

-- Client-Sprache als Vorgabe
function FBDetectLocale()
    if (GetLocale and GetLocale() == "deDE") then return "deDE"; end
    return "enUS";
end

-- Textabfrage mit Rueckfall auf Englisch
function FBT(key)
    local t = FBL or FBLocale["enUS"];
    local s = t[key];
    if (s == nil) then s = FBLocale["enUS"][key]; end
    if (s == nil) then return key; end
    return s;
end

function FBSetLocale(code, apply)
    if (not code) or (not FBLocale[code]) then code = "enUS"; end
    FBL = FBLocale[code];
    if (HealBox) then HealBox.Locale = code; end
    if (apply) then FBHealBox_ApplyLocale(); end
end

FBL = FBLocale[FBDetectLocale()];
xSpacing = 2; 
LowHP = 0.6; 
VeryLowHP = 0.3; 
NamePlateWidth = 120; 
NamePlateHeight = 28; 
FBDropDown = {}; 
FBDropDownButtonValue = {}; 
FBDropDownButton = {}; 
FBDropDownButtonIcon = {}; 

ClassIcon = { 
    Druid = "Interface/Icons/INV_Misc_MonsterClaw_04", 
    Warlock = "Interface/Icons/Spell_Nature_FaerieFire", 
    Hunter = "Interface/Icons/INV_Weapon_Bow_07", 
    Mage = "Interface/Icons/INV_Staff_13", 
    Priest = "Interface/Icons/INV_Staff_30", 
    Warrior = "Interface/Icons/INV_Sword_27", 
    Shaman = "Interface/Icons/Spell_Nature_BloodLust", 
    Paladin = "Interface/Icons/Ability_ThunderBolt", 
    Rogue = "Interface/AddOns/ChatIcons/images/UI-CharacterCreate-Classes_Rogue", 
} 

Spell = { 
    Name = {}, 
    Icon = {}, 
    ID = {}, 
}; 

if (FBClass == "Druid") then  
    Spell.Name[1] = "Rejuvenation"; 
    Spell.Name[2] = "Regrowth"; 
    Spell.Name[3] = "Lifebloom"; 
    Spell.Name[4] = "Healing Touch"; 
    Spell.Name[5] = "Swiftmend"; 
    Spell.Name[6] = "Remove Curse"; 
    Spell.Name[7] = "Abolish Poison"; 
end 

if (FBClass == "Priest") then  
    Spell.Name[1] = "Renew"; 
    Spell.Name[2] = "Flash Heal"; 
    Spell.Name[3] = "Lesser Heal"; 
    Spell.Name[4] = "Heal"; 
    Spell.Name[5] = "Greater Heal"; 
    Spell.Name[6] = "Binding Heal"; 
    Spell.Name[7] = "Prayer of Healing"; 
    Spell.Name[8] = "Prayer of Mending"; 
    Spell.Name[9] = "Circle of Healing"; 
    Spell.Name[10] = "Power Word: Shield"; 
    Spell.Name[11] = "Abolish Disease"; 
    Spell.Name[12] = "Cure Disease"; 
    Spell.Name[13] = "Dispel Magic"; 
end 

if (FBClass == "Shaman") then 
    Spell.Name[1] = "Lesser Healing Wave"; 
    Spell.Name[2] = "Healing Wave"; 
    Spell.Name[3] = "Chain Heal"; 
    Spell.Name[4] = "Earth Shield"; 
    Spell.Name[5] = "Cure Poison"; 
    Spell.Name[6] = "Cure Disease"; 
end 

if (FBClass == "Paladin") then 
    Spell.Name[1] = "Flash of Light"; 
    Spell.Name[2] = "Holy Light"; 
    Spell.Name[3] = "Holy Shock"; 
    Spell.Name[4] = "Lay on Hands"; 
    Spell.Name[5] = "Purify"; 
    Spell.Name[6] = "Cleanse"; 
    Spell.Name[7] = "Blessing of Protection"; 
end 

FBParty1 = {}; 
FBParty2 = {}; 
FBParty3 = {}; 
FBParty4 = {}; 
FBParty5 = {}; 
MaxButtonCount = 10; 

-- Speichert alle verfügbaren Zauber und Ränge 
FBPlayerSpells = {}; 
FBActiveSpellIDs = {}; 
FBSpellBtns = {}; 

function FBHealBox_OnLoad() 
    local swowTag = ""; 
    if (FBHasSuperWoW) then 
        swowTag = FBT("SUPERWOW"); 
    end 
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00"..FBADDON_NAME.."|r  "..HealBoxVersion.." : |cFF00FF00"..FBT("LOADED")..swowTag); 
    DEFAULT_CHAT_FRAME:AddMessage(FBT("CREDITS")); 
    this:RegisterEvent("ADDON_LOADED"); 
    this:RegisterEvent("PARTY_MEMBERS_CHANGED"); 
    this:RegisterEvent("PLAYER_ENTERING_WORLD"); 
    this:RegisterEvent("SPELLS_CHANGED"); 
    this:RegisterEvent("UNIT_HEALTH"); 
    this:RegisterEvent("SPELL_UPDATE_COOLDOWN"); 
    this:RegisterEvent("VARIABLES_LOADED"); 
    this:RegisterEvent("UNIT_AURA"); 
end 

function FBUnitGUID(unit) 
    if (FBHasSuperWoW and UnitExists(unit)) then 
        local exists, guid = UnitExists(unit); 
        return guid; 
    end 
    return nil; 
end 

-- [ Zauberbuch scannen und Ränge sammeln ] -- 
function FBLoadSpellData() 
    FBPlayerSpells = {}; 
    local i = 1; 
    while true do 
        local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL); 
        if not spellName then break; end 
        local isHealBoxSpell = false; 
        for _, v in ipairs(Spell.Name) do 
            if v == spellName then  
                isHealBoxSpell = true;  
                break;  
            end 
        end 
        
        if isHealBoxSpell then 
            if not FBPlayerSpells[spellName] then 
                FBPlayerSpells[spellName] = {}; 
            end 
            local icon = GetSpellTexture(i, BOOKTYPE_SPELL); 
            table.insert(FBPlayerSpells[spellName], { rank = spellRank, id = i, icon = icon }); 
        end 
        i = i + 1; 
    end 
    
    -- Tooltips auswerten: welche dieser Zauber sind HoTs bzw. Absorb-Schilde?
    FBPredict_BuildWatch();

    for btnIndex = 1, MaxButtonCount, 1 do 
        local saved = HealBox.SpellChoice[btnIndex]; 
        if type(saved) == "number" then 
            HealBox.SpellChoice[btnIndex] = nil; 
            saved = nil; 
        end 
        FBApplySpellChoice(btnIndex, saved); 
    end 
end 

function FBApplySpellChoice(i, castString)
    if type(castString) == "number" then return; end
    
    FBDropDownButton[i] = castString;
    FBDropDownButtonIcon[i] = "Interface\\Icons\\INV_Misc_QuestionMark";
    FBActiveSpellIDs[i] = nil;
    
    if castString then
        for baseName, ranks in pairs(FBPlayerSpells) do
            for _, spellData in ipairs(ranks) do
                local cmpString = baseName;
                if spellData.rank and spellData.rank ~= "" then
                    cmpString = baseName .. "(" .. spellData.rank .. ")";
                end
                if cmpString == castString then
                    FBDropDownButtonIcon[i] = spellData.icon;
                    FBActiveSpellIDs[i] = spellData.id;
                    break;
                end
            end
        end
    end

    if FBSpellBtns[i] then
        if castString and FBDropDownButtonIcon[i] then
            FBSpellBtns[i].text:SetText(castString);
            FBSpellBtns[i].icon:SetTexture(FBDropDownButtonIcon[i]);
            FBSpellBtns[i].icon:Show();
        else
            FBSpellBtns[i].text:SetText(FBT("SELECT_SPELL"));
            FBSpellBtns[i].icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark");
            FBSpellBtns[i].icon:Show();
        end
    end
end

-- ==========================================================================
-- [ FB Cascading Menu - eigenes Menuesystem fuer Vanilla 1.12 / Lua 5.0 ]
--
-- Warum kein UIDropDownMenu mehr?
--   * 1.12 loest Level-2 ueber UIDROPDOWNMENU_OPEN_MENU (ein STRING) auf und
--     ruft dort ToggleDropDownMenu(level+1, ...) ohne Frame-Referenz auf ->
--     bei Custom-Frames im displayMode "MENU" bricht die Kette regelmaessig.
--   * UIDropDownMenuButton_OnEnter ruft bei JEDEM Eintrag ohne hasArrow
--     CloseDropDownMenus(level+1) -> das Untermenue stirbt, sobald die Maus
--     ueber einen Nachbareintrag wandert.
--   * info.func + keepShownOnClick erzeugt zwangsweise Haken + Check-Sound.
--
-- Dieses Menue: Hover oeffnet, nichts schliesst es ausser Auswahl / anderes
-- Untermenue / Klick daneben. Icon links, Text linksbuendig, kein Sound.
-- ==========================================================================

FBMENU_MAX_LEVELS  = 2;     -- Anzahl Menue-Ebenen
FBMENU_BTN_HEIGHT  = 17;    -- Zeilenhoehe
FBMENU_ICON_SIZE   = 16;    -- Icon-Kantenlaenge
FBMENU_TEXT_GAP    = 6;     -- Abstand Icon -> Text
FBMENU_PAD         = 8;     -- Innenabstand der Liste
FBMENU_ARROW_SPACE = 18;    -- Platz fuer den Pfeil rechts
FBMENU_MOUSE_PAD   = 14;    -- Toleranzzone: Bruecke zwischen L1 und L2
FBMENU_GRACE_TIME  = 3.0;   -- Sek. ausserhalb -> Auto-Close (999 = aus)

FBMenuList           = {};  -- [level] = Frame
FBMenuActiveButtonID = 1;   -- welcher Options-Slot wird gerade belegt
FBMenuOpenSubValue   = nil; -- welcher Zauber haengt gerade im Untermenue
FBMenuOutTimer       = 0;

-- Treiber fuer den Auto-Close (OnUpdate laeuft nur solange sichtbar)
FBMenuDriver = CreateFrame("Frame", "FBMenuDriver", UIParent);
FBMenuDriver:Hide();
FBMenuDriver:SetScript("OnUpdate", function()
    FBMenu_OnUpdate(arg1);
end);

-- Unsichtbarer Klickfaenger hinter dem Menue (Klick daneben schliesst)
FBMenuCloser = CreateFrame("Button", "FBMenuCloser", UIParent);
FBMenuCloser:SetAllPoints(UIParent);
FBMenuCloser:SetFrameStrata("FULLSCREEN");
FBMenuCloser:EnableMouse(true);
FBMenuCloser:RegisterForClicks("LeftButtonUp", "RightButtonUp");
FBMenuCloser:SetScript("OnClick", function() FBMenu_CloseAll(); end);
FBMenuCloser:Hide();

-- [ Hilfsfunktionen ] ------------------------------------------------------

function FBMenu_MouseOver(frame)
    if (not frame) or (not frame:IsVisible()) then return false; end
    local left = frame:GetLeft();
    if (not left) then return false; end
    local scale = frame:GetEffectiveScale();
    local x, y = GetCursorPosition();
    x = x / scale;
    y = y / scale;
    local pad = FBMENU_MOUSE_PAD;
    return (x >= left - pad) and (x <= frame:GetRight() + pad)
       and (y >= frame:GetBottom() - pad) and (y <= frame:GetTop() + pad);
end

function FBMenu_GetList(level)
    if (FBMenuList[level]) then return FBMenuList[level]; end

    local f = CreateFrame("Frame", "FBMenuList"..level, UIParent);
    f:SetFrameStrata("FULLSCREEN_DIALOG");
    f:SetFrameLevel(10 + level * 5);
    f:SetToplevel(true);
    f:EnableMouse(true);
    f:SetBackdrop({
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 14,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    });
    f:SetBackdropColor(0, 0, 0, 0.92);
    f.buttons = {};
    f:Hide();

    FBMenuList[level] = f;
    return f;
end

function FBMenu_GetButton(list, index)
    if (list.buttons[index]) then return list.buttons[index]; end

    local yOff = -FBMENU_PAD - ((index - 1) * FBMENU_BTN_HEIGHT);
    local b = CreateFrame("Button", list:GetName().."Button"..index, list);
    b:SetHeight(FBMENU_BTN_HEIGHT);
    b:SetPoint("TOPLEFT",  list, "TOPLEFT",   FBMENU_PAD, yOff);
    b:SetPoint("TOPRIGHT", list, "TOPRIGHT", -FBMENU_PAD, yOff);

    b.icon = b:CreateTexture(nil, "ARTWORK");
    b.icon:SetWidth(FBMENU_ICON_SIZE);
    b.icon:SetHeight(FBMENU_ICON_SIZE);
    b.icon:SetPoint("LEFT", b, "LEFT", 0, 0);
    b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93);

    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    b.text:SetPoint("LEFT", b, "LEFT", FBMENU_ICON_SIZE + FBMENU_TEXT_GAP, 0);
    b.text:SetJustifyH("LEFT");

    b.arrow = b:CreateTexture(nil, "ARTWORK");
    b.arrow:SetWidth(16);
    b.arrow:SetHeight(16);
    b.arrow:SetPoint("RIGHT", b, "RIGHT", 2, 0);
    b.arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow");
    b.arrow:Hide();

    b.hl = b:CreateTexture(nil, "HIGHLIGHT");
    b.hl:SetAllPoints(b);
    b.hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
    b.hl:SetBlendMode("ADD");

    b:RegisterForClicks("LeftButtonUp");
    b:SetScript("OnEnter", function() FBMenu_ButtonOnEnter(); end);
    b:SetScript("OnClick", function() FBMenu_ButtonOnClick(); end);

    list.buttons[index] = b;
    return b;
end

-- [ Menue-Ebene aufbauen und anzeigen ] ------------------------------------
-- entries = Array aus { text, icon, hasArrow, submenu, value, spellID, func, isTitle }
-- anchor  = Level 1: der Options-Button;  Level >1: der Eintrag mit dem Pfeil

function FBMenu_ShowLevel(level, entries, anchor)
    local list  = FBMenu_GetList(level);
    local count = table.getn(entries);
    if (count == 0) then list:Hide(); return; end

    local maxText  = 0;
    local anyArrow = false;

    for i = 1, count do
        local e = entries[i];
        local b = FBMenu_GetButton(list, i);
        b.entry = e;
        b.level = level;

        b.text:SetText(e.text);
        if (e.isTitle) then
            b.text:SetTextColor(1, 0.82, 0);
            b.hl:SetAlpha(0);
        else
            b.text:SetTextColor(1, 1, 1);
            b.hl:SetAlpha(1);
        end

        if (e.icon) then
            b.icon:SetTexture(e.icon);
            b.icon:Show();
        else
            b.icon:Hide();
        end

        if (e.hasArrow) then
            b.arrow:Show();
            anyArrow = true;
        else
            b.arrow:Hide();
        end

        b:Show();

        local w = b.text:GetStringWidth();
        if (w > maxText) then maxText = w; end
    end

    -- ueberzaehlige Buttons aus einem frueheren Aufruf verstecken
    local j = count + 1;
    while (list.buttons[j]) do
        list.buttons[j]:Hide();
        j = j + 1;
    end

    local width = (FBMENU_PAD * 2) + FBMENU_ICON_SIZE + FBMENU_TEXT_GAP + maxText;
    if (anyArrow) then width = width + FBMENU_ARROW_SPACE; end
    if (width < 130) then width = 130; end
    list:SetWidth(width);
    list:SetHeight((FBMENU_PAD * 2) + (count * FBMENU_BTN_HEIGHT));

    list:ClearAllPoints();
    if (level == 1) then
        list:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2);
    else
        -- 2px Ueberlappung mit der Elternliste: kein Loch, das die Maus verliert
        list:SetPoint("TOPLEFT", anchor, "TOPRIGHT", FBMENU_PAD - 2, FBMENU_PAD);
    end
    list:Show();

    -- Ragt es rechts aus dem Bildschirm? Dann nach links klappen.
    if (level > 1) and list:GetRight() and (list:GetRight() > UIParent:GetRight()) then
        list:ClearAllPoints();
        list:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -(FBMENU_PAD - 2), FBMENU_PAD);
    end
end

-- [ Maus-Handler ] ---------------------------------------------------------

function FBMenu_ButtonOnEnter()
    local e = this.entry;
    if (not e) or e.isTitle then return; end

    if (e.hasArrow) then
        -- Hover oeffnet das Untermenue (nur neu bauen, wenn ein anderer Zauber)
        if (FBMenuOpenSubValue ~= e.submenu) then
            FBMenuOpenSubValue = e.submenu;
            FBMenu_ShowLevel(this.level + 1, FBMenu_BuildRankEntries(e.submenu), this);
        end
    end
    -- Eintraege OHNE Pfeil lassen ein offenes Untermenue absichtlich stehen.
    -- (Blizzards Original wuerde hier CloseDropDownMenus() feuern.)
end

function FBMenu_ButtonOnClick()
    local e = this.entry;
    if (not e) or e.isTitle then return; end

    if (e.hasArrow) then
        FBMenuOpenSubValue = e.submenu;
        FBMenu_ShowLevel(this.level + 1, FBMenu_BuildRankEntries(e.submenu), this);
        return;
    end

    if (e.func) then e.func(e); end
end

function FBMenu_OnUpdate(elapsed)
    if (not elapsed) then return; end

    local over = false;
    for lvl = 1, FBMENU_MAX_LEVELS do
        if (FBMenu_MouseOver(FBMenuList[lvl])) then
            over = true;
            break;
        end
    end

    if (over) then
        FBMenuOutTimer = 0;
    else
        FBMenuOutTimer = FBMenuOutTimer + elapsed;
        if (FBMenuOutTimer > FBMENU_GRACE_TIME) then
            FBMenu_CloseAll();
        end
    end
end

-- [ Oeffnen / Schliessen ] -------------------------------------------------

function FBMenu_IsOpen()
    return (FBMenuList[1] and FBMenuList[1]:IsVisible());
end

function FBMenu_CloseAll()
    for lvl = 1, FBMENU_MAX_LEVELS do
        if (FBMenuList[lvl]) then FBMenuList[lvl]:Hide(); end
    end
    FBMenuOpenSubValue = nil;
    FBMenuOutTimer = 0;
    FBMenuDriver:Hide();
    FBMenuCloser:Hide();
end

-- Beliebige Eintragsliste als Menue oeffnen (Zauberwahl, Sprachwahl, ...)
function FBMenu_OpenMenu(entries, anchorFrame)
    FBMenu_CloseAll();
    FBMenu_ShowLevel(1, entries, anchorFrame);
    FBMenuOutTimer = 0;
    FBMenuCloser:Show();
    FBMenuDriver:Show();
end

function FBMenu_OpenSpellMenu(btnIndex, anchorFrame)
    -- gleicher Slot nochmal geklickt -> zu
    if (FBMenu_IsOpen() and FBMenuActiveButtonID == btnIndex) then
        FBMenu_CloseAll();
        return;
    end

    FBMenuActiveButtonID = btnIndex;
    FBMenu_OpenMenu(FBMenu_BuildSpellEntries(), anchorFrame);
end

-- Sprachumschaltung im Optionsfenster
function FBMenu_OpenLanguageMenu(anchorFrame)
    if (FBMenu_IsOpen()) then
        FBMenu_CloseAll();
        return;
    end

    local entries = {};
    local codes = { "deDE", "enUS" };
    for _, code in ipairs(codes) do
        local e = {};
        e.text = FBLocale[code].LANG_NAME;
        e.code = code;
        e.func = function(entry)
            FBSetLocale(entry.code, true);
            FBMenu_CloseAll();
        end
        table.insert(entries, e);
    end
    FBMenu_OpenMenu(entries, anchorFrame);
end

-- [ Inhalte ] --------------------------------------------------------------

function FBMenu_MakeCastString(spellName, rank)
    if (rank and rank ~= "") then
        return spellName.."("..rank..")";
    end
    return spellName;
end

function FBMenu_BuildSpellEntries()
    local entries = {};

    local clear = {};
    clear.text = FBT("MENU_NO_SPELL");
    clear.icon = "Interface\\Icons\\INV_Misc_QuestionMark";
    clear.func = FBMenu_ClearSpell;
    table.insert(entries, clear);

    for _, spellName in ipairs(Spell.Name) do
        local ranks = FBPlayerSpells[spellName];
        if (ranks) then
            local numRanks = table.getn(ranks);
            local e = {};
            e.text = spellName;
            e.icon = ranks[1].icon;

            if (numRanks > 1) then
                e.hasArrow = true;
                e.submenu  = spellName;
            else
                e.value   = FBMenu_MakeCastString(spellName, ranks[1].rank);
                e.spellID = ranks[1].id;
                e.func    = FBMenu_SelectSpell;
            end

            table.insert(entries, e);
        end
    end

    return entries;
end

function FBMenu_BuildRankEntries(spellName)
    local entries = {};
    local ranks = FBPlayerSpells[spellName];
    if (not ranks) then return entries; end

    local title = {};
    title.text    = spellName;
    title.isTitle = true;
    title.icon    = ranks[1].icon;
    table.insert(entries, title);

    for _, sd in ipairs(ranks) do
        local e = {};
        e.text = sd.rank;
        if (not e.text) or (e.text == "") then e.text = FBT("RANK_DEFAULT"); end
        e.icon    = sd.icon;
        e.value   = FBMenu_MakeCastString(spellName, sd.rank);
        e.spellID = sd.id;
        e.func    = FBMenu_SelectSpell;
        table.insert(entries, e);
    end

    return entries;
end

function FBMenu_SelectSpell(entry)
    local btnID = FBMenuActiveButtonID;
    HealBox.SpellChoice[btnID] = entry.value;
    FBApplySpellChoice(btnID, entry.value);
    FBHealBoxButtonsChanged();
    FBMenu_CloseAll();
end

function FBMenu_ClearSpell()
    local btnID = FBMenuActiveButtonID;
    HealBox.SpellChoice[btnID] = nil;
    FBApplySpellChoice(btnID, nil);
    FBHealBoxButtonsChanged();
    FBMenu_CloseAll();
end

function FBHealBox_OnEvent(event, arg1) 
    if ((event == "ADDON_LOADED") and (arg1 == FBADDON_FOLDER)) then 
        if (not HealBox.SpellChoice) then 
            HealBox.SpellChoice = {}; 
        end 
        if (HealBox.Active == nil) then 
            HealBox.Active = 1; 
        end 
        if (HealBox.HealComm == nil) then 
            HealBox.HealComm = 1; 
        end 
        if (HealBox.Locale == nil) then 
            HealBox.Locale = FBDetectLocale(); 
        end 
        FBSetLocale(HealBox.Locale, 1); 
        FBUpdateNames(); 
        MaxButtonSlider:SetValue(HealBox.MaxButtons); 
        HealBoxAttachMode(HealBox.AttachMode); 
    end 
    
    if (event == "PLAYER_ENTERING_WORLD" or event == "SPELLS_CHANGED") then 
        FBLoadSpellData(); 
        FBHealBoxButtons(); 
        if (FBRegisterMinimapButtonWithMBB) then 
            FBRegisterMinimapButtonWithMBB(); 
        end 
        FBHealBox_RefreshAllBars(); 
    end 
    
    if (event == "VARIABLES_LOADED") then 
        if (not HealBox.SpellChoice) then 
            HealBox.SpellChoice = {}; 
        end 
        if (HealBox.HealComm == nil) then 
            HealBox.HealComm = 1; 
        end 
        if (HealBox.Locale == nil) then 
            HealBox.Locale = FBDetectLocale(); 
        end 
        FBSetLocale(HealBox.Locale, 1); 
        FBLoadSpellData(); 
        FBHealBoxButtons(); 
        HealBoxScale(FBHealBox1, HealBox.Scale); 
        ScaleSlider:SetValue(HealBox.Scale); 
        AttachModeCheck:SetChecked(HealBox.AttachMode); 
        HealCommCheck:SetChecked(HealBox.HealComm == 1); 
        FBUpdateNames(); 
        if (HealBox.AttachMode == 0) then 
            FBHealBox1:SetScale(HealBox.Scale); 
        else 
            FBHealBox1:SetScale(1); 
        end 
    end 
    
    if (event == "PARTY_MEMBERS_CHANGED") then 
        FBUpdateNames(); 
    end 
    
    if ((event == "UNIT_HEALTH" ) and  (arg1 == "player")) then 
        HPPercent = UnitHealth("player") / UnitHealthMax("player"); 
        FBHealBox1.HPText:SetText(format("%d%%", HPPercent*100)); 
        FBHealBox1.HealthBar:SetMinMaxValues(0, UnitHealthMax("player")); 
        FBHealBox1.HealthBar:SetValue(UnitHealth("player")); 
        if (HPPercent > LowHP) then FBHealBox1.HealthBar:SetStatusBarColor(0,1,0,1); end; 
        if (HPPercent < LowHP) then FBHealBox1.HealthBar:SetStatusBarColor(1,0.9,0,1); end; 
        if (HPPercent < VeryLowHP) then FBHealBox1.HealthBar:SetStatusBarColor(1,0,0,1); end; 
    end 
    
    if ((event == "UNIT_HEALTH" ) and (arg1 == "party1")) then 
        HPPercent = UnitHealth("party1") / UnitHealthMax("party1"); 
        FBHealBox2.HPText:SetText(format("%d%%", HPPercent*100)); 
        FBHealBox2.HealthBar:SetMinMaxValues(0, UnitHealthMax("party1")); 
        FBHealBox2.HealthBar:SetValue(UnitHealth("party1")); 
        if (HPPercent > LowHP) then FBHealBox2.HealthBar:SetStatusBarColor(0,1,0,1); end; 
        if (HPPercent < LowHP) then FBHealBox2.HealthBar:SetStatusBarColor(1,0.9,0,1); end; 
        if (HPPercent < VeryLowHP) then FBHealBox2.HealthBar:SetStatusBarColor(1,0,0,1); end; 
    end 
    
    if ((event == "UNIT_HEALTH" ) and (arg1 == "party2")) then 
        HPPercent = UnitHealth("party2") / UnitHealthMax("party2"); 
        FBHealBox3.HPText:SetText(format("%d%%", HPPercent*100)); 
        FBHealBox3.HealthBar:SetMinMaxValues(0, UnitHealthMax("party2")); 
        FBHealBox3.HealthBar:SetValue(UnitHealth("party2")); 
        if (HPPercent > LowHP) then FBHealBox3.HealthBar:SetStatusBarColor(0,1,0,1); end; 
        if (HPPercent < LowHP) then FBHealBox3.HealthBar:SetStatusBarColor(1,0.9,0,1); end; 
        if (HPPercent < VeryLowHP) then FBHealBox3.HealthBar:SetStatusBarColor(1,0,0,1); end; 
    end 
    
    if ((event == "UNIT_HEALTH" ) and (arg1 == "party3")) then 
        HPPercent = UnitHealth("party3") / UnitHealthMax("party3"); 
        FBHealBox4.HPText:SetText(format("%d%%", HPPercent*100)); 
        FBHealBox4.HealthBar:SetMinMaxValues(0, UnitHealthMax("party3")); 
        FBHealBox4.HealthBar:SetValue(UnitHealth("party3")); 
        if (HPPercent > LowHP) then FBHealBox4.HealthBar:SetStatusBarColor(0,1,0,1); end; 
        if (HPPercent < LowHP) then FBHealBox4.HealthBar:SetStatusBarColor(1,0.9,0,1); end; 
        if (HPPercent < VeryLowHP) then FBHealBox4.HealthBar:SetStatusBarColor(1,0,0,1); end; 
    end 
    
    if ((event == "UNIT_HEALTH" ) and (arg1 == "party4")) then 
        HPPercent = UnitHealth("party4") / UnitHealthMax("party4"); 
        FBHealBox5.HPText:SetText(format("%d%%", HPPercent*100)); 
        FBHealBox5.HealthBar:SetMinMaxValues(0, UnitHealthMax("party4")); 
        FBHealBox5.HealthBar:SetValue(UnitHealth("party4")); 
        if (HPPercent > LowHP) then FBHealBox5.HealthBar:SetStatusBarColor(0,1,0,1); end; 
        if (HPPercent < LowHP) then FBHealBox5.HealthBar:SetStatusBarColor(1,0.9,0,1); end; 
        if (HPPercent < VeryLowHP) then FBHealBox5.HealthBar:SetStatusBarColor(1,0,0,1); end; 
    end 
    
    if event == "UNIT_HEALTH" or event == "UNIT_AURA" then 
        if arg1 == "player" then FBHealBox_UpdateUnit("player", FBHealBox1) end 
        if arg1 == "party1" then FBHealBox_UpdateUnit("party1", FBHealBox2) end 
        if arg1 == "party2" then FBHealBox_UpdateUnit("party2", FBHealBox3) end 
        if arg1 == "party3" then FBHealBox_UpdateUnit("party3", FBHealBox4) end 
        if arg1 == "party4" then FBHealBox_UpdateUnit("party4", FBHealBox5) end 
    end 
end 

-- Alle drei Balken in dieselbe Ebene legen und stabil stapeln:
-- HP deckend oben, darunter der Schild-Anteil, ganz unten die Heilvorhersage.
function FBHealBox_SetBarStrata(f, strata)
    if (not f) or (not f.HealthBar) then return; end
    f.IncHealBar:SetFrameStrata(strata);
    f.ShieldBar:SetFrameStrata(strata);
    f.HealthBar:SetFrameStrata(strata);
    f.IncHealBar:SetFrameLevel(1);
    f.ShieldBar:SetFrameLevel(2);
    f.HealthBar:SetFrameLevel(3);
end

function FBHealBoxCreateFrame(FrameName,ParentFrame,FrameTexture,FrameWidth,FrameHeight,FrameAlpha,Unit) 
    local f = CreateFrame("Frame", FrameName, ParentFrame); 
    f:SetFrameStrata("MEDIUM"); 
    icon = f:CreateTexture(nil, "BACKGROUND"); 
    icon:SetAllPoints(); 
    f:SetBackdrop({bgFile = nil, edgeFile = "Interface/Tooltips/UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 10, insets = { left = 4, right = 4, top = 4, bottom = 4 }}); 
    f:SetAlpha(FrameAlpha); 
    f:SetHeight(FrameHeight); 
    f:SetWidth(FrameWidth); 
    
    f.NameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); 
    f.NameText:SetPoint("TOPLEFT", f, "TOPRIGHT", -120, -8); 
    f.NameText:SetText(""); 
    f.NameText:SetTextColor(1, 1, 1, 1); 
    f.NameText:SetWidth(NamePlateWidth - 40); 
    
    f.HPText = f:CreateFontString(nil, "OVERLAY", "NumberFontNormalYellow"); 
    f.HPText:SetPoint("RIGHT", -5, 0); 
    f.HPText:SetText("100%"); 
    f.HPText:SetTextColor(1, 1, 1, 1); 
    
    f.HealthBar = CreateFrame("STATUSBAR", nil, f, "TextStatusBar");
    f.HealthBar:SetWidth(NamePlateWidth - 5);
    f.HealthBar:SetHeight(NamePlateHeight - 5);
    f.HealthBar:SetPoint("TOPLEFT", 2, -3);
    f.HealthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
    f.HealthBar:SetMinMaxValues(0, UnitHealthMax(Unit));
    f.HealthBar:SetValue(UnitHealth(Unit));
    f.HealthBar:SetStatusBarColor(0, 1, 0, 1);
    f.HealthBar:Show();

    -- Absorb-Schild als halbtransparentes "Pseudoleben" hinter dem HP-Balken
    f.ShieldBar = CreateFrame("STATUSBAR", nil, f, "TextStatusBar");
    f.ShieldBar:SetWidth(NamePlateWidth - 5);
    f.ShieldBar:SetHeight(NamePlateHeight - 5);
    f.ShieldBar:SetPoint("TOPLEFT", 2, -3);
    f.ShieldBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
    f.ShieldBar:SetMinMaxValues(0, UnitHealthMax(Unit));
    f.ShieldBar:SetValue(UnitHealth(Unit));
    f.ShieldBar:SetStatusBarColor(0.6, 0.8, 1.0, 0.5);
    f.ShieldBar:Show();

    -- Eingehende Heilung (Direktheilung + HoT-Restticks)
    f.IncHealBar = CreateFrame("STATUSBAR", nil, f, "TextStatusBar");
    f.IncHealBar:SetWidth(NamePlateWidth - 5);
    f.IncHealBar:SetHeight(NamePlateHeight - 5);
    f.IncHealBar:SetPoint("TOPLEFT", 2, -3);
    f.IncHealBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar");
    f.IncHealBar:SetMinMaxValues(0, UnitHealthMax(Unit));
    f.IncHealBar:SetValue(UnitHealth(Unit));
    f.IncHealBar:SetStatusBarColor(0.4, 1, 0.4, 0.5);
    f.IncHealBar:Show();

    -- Reihenfolge: HP oben (deckend), darunter Schild, darunter Heilvorhersage
    FBHealBox_SetBarStrata(f, "LOW");
    
    f:SetMovable(true); 
    f:EnableMouse(true); 
    f:SetScript("OnMouseDown", function() FBHealBox1:StartMoving() end); 
    f:SetScript("OnMouseUp", function() FBHealBox1:StopMovingOrSizing() end); 
    
    return f; 
end 

function FBHealBoxCreateButton(FBButtonName, FBParentFrame, xoffset, yoffset, texture, tooltiptext, targetUnit, spellID) 
    if (FBButtonName == "") then 
        FBButtonName = "Button"..random(10); 
    end 
    
    local button = CreateFrame("Button", FBButtonName, FBParentFrame); 
    button:SetPoint("LEFT", FBParentFrame, "RIGHT", xoffset, yoffset); 
    
    button.icon = button:CreateTexture("icon", "BACKGROUND"); 
    button.icon:SetAllPoints(); 
    
    local highlight = button:CreateTexture(nil, "HIGHLIGHT"); 
    highlight:SetAllPoints(); 
    highlight:SetBlendMode("ADD"); 
    highlight:SetTexture("Interface/Buttons/ButtonHilight-Square"); 
    
    button:SetPushedTexture("Interface/Buttons/UI-Quickslot-Depress"); 
    
    if (texture) then 
        button.icon:SetTexture(texture); 
    else 
        button.icon:SetTexture("Interface/Icons/INV_Misc_QuestionMark"); 
    end 
    
    button:EnableMouse(1); 
    button:SetHeight(28); 
    button:SetWidth(28); 
    button.TargetUnit = targetUnit; 
    button.spellName = tooltiptext; 
    button.id = spellID; 
    
    button:SetScript("OnEnter", function() 
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT", -30, 5); 
        if (tooltiptext == nil or button.id == nil) then  
            GameTooltip:SetText(FBT("TT_NO_SPELL")); 
        else 
            GameTooltip_SetDefaultAnchor(GameTooltip, this); 
            GameTooltip:SetSpell(this.id, SpellBookFrame.bookType); 
            GameTooltip:AddLine(FBADDON_NAME.." "..FBT("TT_TARGET")..": |cFF00FF00"..UnitName(this.TargetUnit), 1, 1, 1); 
        end 
        GameTooltip:Show(); 
    end); 
    
    button:SetScript("OnLeave", function() 
        GameTooltip:Hide(); 
    end); 
    
    button:RegisterForClicks("LeftButtonUp"); 
    
    button:SetScript("OnClick", function()
        if (not button.spellName) then return; end
        local castTarget = button.TargetUnit or "player";

        if (castTarget == "player") then
            -- Ziel VOR dem Cast merken: SPELLCAST_START feuert sofort
            FBPredict_NoteCast(button.spellName, UnitName("player"));
            CastSpellByName(button.spellName, 1);
            return;
        end

        if (not UnitExists(castTarget)) then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000"..FBADDON_NAME..":|r "..castTarget..FBT("NOT_IN_GROUP"));
            return;
        end

        if (SUPERWOW_VERSION or SUPERWOW_STRING) then
            FBPredict_NoteCast(button.spellName, UnitName(castTarget));
            CastSpellByName(button.spellName, castTarget);
        else
            local hadTarget = UnitExists("target");
            local targetWasSame = false;
            if (hadTarget and UnitIsUnit) then
                targetWasSame = UnitIsUnit("target", castTarget);
            end
            if (not targetWasSame) then TargetUnit(castTarget); end
            FBPredict_NoteCast(button.spellName, UnitName(castTarget));
            CastSpellByName(button.spellName);
            if (not targetWasSame) then
                if (hadTarget) then TargetLastTarget(); else ClearTarget(); end
            end
        end
    end);
    
    button:RegisterEvent("SPELL_UPDATE_USABLE"); 
    button:SetScript("OnEvent", HealBoxButton_OnEvent); 
    return button; 
end 

function FBHealBoxSetup() 
    FBHealBox1=FBHealBoxCreateFrame("FBHealBox1",UIParent,"Interface/DialogFrame/UI-DialogBox-Background",NamePlateWidth,NamePlateHeight,1,"player") 
    FBHealBox2=FBHealBoxCreateFrame("FBHealBox2",FBHealBox1,"Interface/DialogFrame/UI-DialogBox-Background",NamePlateWidth,NamePlateHeight,1,"party1") 
    FBHealBox3=FBHealBoxCreateFrame("FBHealBox3",FBHealBox1,"Interface/DialogFrame/UI-DialogBox-Background",NamePlateWidth,NamePlateHeight,1,"party2") 
    FBHealBox4=FBHealBoxCreateFrame("FBHealBox4",FBHealBox1,"Interface/DialogFrame/UI-DialogBox-Background",NamePlateWidth,NamePlateHeight,1,"party3") 
    FBHealBox5=FBHealBoxCreateFrame("FBHealBox5",FBHealBox1,"Interface/DialogFrame/UI-DialogBox-Background",NamePlateWidth,NamePlateHeight,1,"party4") 
    FBPartyFrame = { FBHealBox1, FBHealBox2, FBHealBox3, FBHealBox4, FBHealBox5 }; 
    FBPartyTable = { FBParty1, FBParty2, FBParty3, FBParty4, FBParty5 }; 
    HealBoxAttachMode(HealBox.AttachMode);  
end 

function FBHealBox_RefreshAllBars() 
    if (not FBHealBox1) or (not FBHealBox1.ShieldBar) then return; end
    if (UnitExists("player")) then FBHealBox_UpdateUnit("player", FBHealBox1); end 
    if (UnitExists("party1")) then FBHealBox_UpdateUnit("party1", FBHealBox2); end 
    if (UnitExists("party2")) then FBHealBox_UpdateUnit("party2", FBHealBox3); end 
    if (UnitExists("party3")) then FBHealBox_UpdateUnit("party3", FBHealBox4); end 
    if (UnitExists("party4")) then FBHealBox_UpdateUnit("party4", FBHealBox5); end 
end 

function FBUpdateNames() 
    FBHealBox1:Hide(); 
    FBHealBox2:Hide(); 
    FBHealBox3:Hide(); 
    FBHealBox4:Hide(); 
    FBHealBox5:Hide(); 
    FBPlayerName = strupper(GetUnitName("player")); 
    
    if (HealBox.Active == 1) then FBHealBox1:Show(); end 
    
    if(UnitExists("party1")) then  
        FBParty1Name = strupper(GetUnitName("party1")); 
        FBHealBox2:Show(); 
    end 
    
    if(UnitExists("party2")) then  
        FBParty2Name = strupper(GetUnitName("party2")); 
        FBHealBox3.HealthBar:SetMinMaxValues(0,UnitHealth("party2")); 
        FBHealBox3:Show(); 
    end 
    
    if(UnitExists("party3")) then  
        FBParty3Name = strupper(GetUnitName("party3")); 
        FBHealBox4.HealthBar:SetMinMaxValues(0,UnitHealth("party3")); 
        FBHealBox4:Show(); 
    end 
    
    if(UnitExists("party4")) then  
        FBParty4Name = strupper(GetUnitName("party4")); 
        FBHealBox5.HealthBar:SetMinMaxValues(0,UnitHealth("party4")); 
        FBHealBox5:Show(); 
    end 
    
    FBHealBox1.NameText:SetText(FBPlayerName); 
    FBHealBox2.NameText:SetText(FBParty1Name); 
    FBHealBox3.NameText:SetText(FBParty2Name); 
    FBHealBox4.NameText:SetText(FBParty3Name); 
    FBHealBox5.NameText:SetText(FBParty4Name); 
end 

-- Beschriftet die bereits gebaute Oberflaeche neu. Wird beim Bauen des
-- Optionsfensters, beim Laden der gespeicherten Sprache und bei jedem
-- Sprachwechsel aufgerufen - ein /reload ist nie noetig.
function FBHealBox_ApplyLocale()
    if (MMButton) then MMButton.tooltipText = FBT("MM_TIP"); end
    if (not panel) then return; end

    panel.TitleText:SetText(FBADDON_NAME .. " " .. HealBoxVersion);
    panel.TitleSubText:SetText(format(FBT("PANEL_SUB"), FBADDON_NAME));
    panel.AboutText:SetText(format(FBT("ABOUT"), FBADDON_NAME, HealBoxVersion));

    for i = 1, MaxButtonCount, 1 do
        local b = FBSpellBtns[i];
        if (b) then
            if (b.label) then b.label:SetText(FBT("BUTTON") .. " " .. i); end
            -- belegte Buttons zeigen den Zaubernamen, der bleibt wie er ist
            if (not FBDropDownButton[i]) then b.text:SetText(FBT("SELECT_SPELL")); end
        end
    end

    FBUpdateButtonSliderText();
    FBUpdateScaleSliderText();
    if (ScaleSlider) then
        getglobal(ScaleSlider:GetName() .. "Low"):SetText(FBT("SMALL"));
        getglobal(ScaleSlider:GetName() .. "High"):SetText(FBT("LARGE"));
    end

    if (AttachModeCheck) then
        AttachModeCheck.Text:SetText(FBT("ATTACH"));
        AttachModeCheck.tooltipText = FBT("ATTACH_TIP");
    end
    if (HealCommCheck) then
        HealCommCheck.Text:SetText(FBT("COMM"));
        HealCommCheck.tooltipText = FBT("COMM_TIP");
    end
    if (FBLangBtn) then
        FBLangBtn.text:SetText(FBT("LANGUAGE") .. ": |cFFFFFFFF" .. FBT("LANG_NAME"));
    end
end

-- [ Options-Fenster ] -- 
function FBHealBoxCreateAddonOptionFrame() 
    panel = CreateFrame("FRAME", "HealBoxOptionsFrame", UIParent); 
    panel.name = FBADDON_NAME; 
    panel:SetWidth(460); 
    panel:SetHeight(620); 
    panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0); 
    panel:SetFrameStrata("DIALOG"); 
    panel:SetBackdrop({ 
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background", 
        edgeFile = "Interface/DialogFrame/UI-DialogBox-Border", 
        tile = true, tileSize = 32, edgeSize = 32, 
        insets = { left = 11, right = 12, top = 12, bottom = 11 } 
    }); 
    panel:SetMovable(true); 
    panel:EnableMouse(true); 
    panel:RegisterForDrag("LeftButton"); 
    panel:SetScript("OnDragStart", function() panel:StartMoving(); end); 
    panel:SetScript("OnDragStop", function() panel:StopMovingOrSizing(); end); 
    panel:Hide(); 
    
    panel.CloseButton = CreateFrame("Button", "HealBoxOptionsFrameClose", panel, "UIPanelCloseButton"); 
    panel.CloseButton:SetPoint("TOPRIGHT", -5, -5); 
    panel.CloseButton:SetScript("OnClick", function() FBMenu_CloseAll(); panel:Hide(); end); 
    
    panel.TitleText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); 
    panel.TitleText:SetPoint("TOPLEFT", 25, -18); 
    panel.TitleText:SetText(FBADDON_NAME .. " " .. HealBoxVersion); 
    
    panel.TitleSubText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall"); 
    panel.TitleSubText:SetPoint("TOPLEFT", 25, -38); 
    panel.TitleSubText:SetJustifyH("LEFT"); 
    panel.TitleSubText:SetText(format(FBT("PANEL_SUB"), FBADDON_NAME)); 
    panel.TitleSubText:SetTextColor(1, 1, 1, 1); 
    
    local classIcon = CreateFrame("Frame", nil, panel); 
    classIcon:SetPoint("TOPRIGHT", -25, -20); 
    classIcon:SetWidth(70); 
    classIcon:SetHeight(70); 
    classIcon.tex = classIcon:CreateTexture(nil, "BACKGROUND"); 
    classIcon.tex:SetAllPoints(); 
    classIcon.tex:SetTexture(ClassIcon[FBClass]); 
    classIcon.text = classIcon:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); 
    classIcon.text:SetText(strupper(FBClass)); 
    classIcon.text:SetPoint("CENTER", 0, -45); 
    classIcon.text:SetTextColor(1, 1, 0.2, 1); 
    
    -- 10 Buttons für Zauber mit Rank-Auswahl 
    for i = 1, MaxButtonCount do 
        local col = (i > 5) and 1 or 0; 
        local row = (i > 5) and (i - 5) or i; 
        local xPos = 35 + (col * 210); 
        local yPos = -130 - ((row - 1) * 58); 
        
        local btn = CreateFrame("Button", "FBHealBoxBtn"..i, panel); 
        btn:SetWidth(180); 
        btn:SetHeight(28); 
        btn:SetPoint("TOPLEFT", panel, "TOPLEFT", xPos, yPos); 
        btn:SetBackdrop({ 
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", 
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
            tile = true, tileSize = 16, edgeSize = 12, 
            insets = { left = 3, right = 3, top = 3, bottom = 3 } 
        }); 
        btn:SetBackdropColor(0, 0, 0, 0.8); 
        btn:SetBackdropBorderColor(0.6, 0.6, 0.6, 1); 
        
        btn.icon = btn:CreateTexture(nil, "ARTWORK"); 
        btn.icon:SetWidth(20); 
        btn.icon:SetHeight(20); 
        btn.icon:SetPoint("LEFT", 4, 0); 
        btn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); 
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); 
        btn.text:SetPoint("LEFT", btn.icon, "RIGHT", 8, 0); 
        btn.text:SetPoint("RIGHT", -8, 0); 
        btn.text:SetJustifyH("LEFT"); 
        btn.text:SetText(FBT("SELECT_SPELL")); 
        
        btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal"); 
        btn.label:SetPoint("BOTTOMLEFT", btn, "TOPLEFT", 2, 2); 
        btn.label:SetText(FBT("BUTTON") .. " " .. i); 
        
        local hl = btn:CreateTexture(nil, "HIGHLIGHT"); 
        hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight"); 
        hl:SetBlendMode("ADD"); 
        hl:SetAllPoints(btn); 
        
        local btnIndex = i;
        btn:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn");
            FBMenu_OpenSpellMenu(btnIndex, btn);
        end);
        
        FBSpellBtns[i] = btn; 
    end 
    
    MaxButtonSlider = CreateFrame("Slider", "MaxButtonSlider", panel, "OptionsSliderTemplate"); 
    MaxButtonSlider:SetWidth(128); 
    MaxButtonSlider:SetHeight(16); 
    MaxButtonSlider:SetPoint("TOPLEFT", 75, -460); 
    MaxButtonSlider:SetMinMaxValues(0, MaxButtonCount); 
    MaxButtonSlider:SetValueStep(1); 
    MaxButtonSlider:SetValue(HealBox.MaxButtons); 
    MaxButtonSlider.Text = MaxButtonSlider:CreateFontString(nil, "BACKGROUND", "GameFontNormalLarge"); 
    MaxButtonSlider.Text:SetPoint("CENTER", 0, 17); 
    FBUpdateButtonSliderText(); 
    getglobal(MaxButtonSlider:GetName() .. "Low"):SetText("0"); 
    getglobal(MaxButtonSlider:GetName() .. "High"):SetText(tostring(MaxButtonCount)); 
    MaxButtonSlider:SetScript("OnValueChanged", MaxButtonSlider_Update); 
    
    ScaleSlider = CreateFrame("Slider", "ScaleSlider", panel, "OptionsSliderTemplate"); 
    ScaleSlider:SetWidth(100); 
    ScaleSlider:SetHeight(16); 
    ScaleSlider:SetPoint("TOPLEFT", 260, -460); 
    ScaleSlider:SetMinMaxValues(0.6, 1.5); 
    ScaleSlider:SetValueStep(0.1); 
    ScaleSlider:SetValue(HealBox.Scale); 
    ScaleSlider.Text = ScaleSlider:CreateFontString(nil, "BACKGROUND", "GameFontNormalLarge"); 
    ScaleSlider.Text:SetPoint("CENTER", -5, 17); 
    FBUpdateScaleSliderText(); 
    getglobal(ScaleSlider:GetName() .. "Low"):SetText(FBT("SMALL")); 
    getglobal(ScaleSlider:GetName() .. "High"):SetText(FBT("LARGE")); 
    ScaleSlider:SetScript("OnValueChanged", function() 
        HealBox.Scale = ScaleSlider:GetValue(); 
        HealBoxScale(FBHealBox1, HealBox.Scale); 
        FBUpdateScaleSliderText(); 
    end); 
    
    AttachModeCheck = CreateFrame("CheckButton", "$parentCheckButton", panel, "OptionsCheckButtonTemplate"); 
    AttachModeCheck:SetPoint("TOPLEFT", 40, -500); 
    AttachModeCheck.Text = AttachModeCheck:CreateFontString(nil, "BACKGROUND", "GameFontNormal"); 
    AttachModeCheck.Text:SetPoint("LEFT", AttachModeCheck, "RIGHT", 4, 1); 
    AttachModeCheck.Text:SetText(FBT("ATTACH")); 
    AttachModeCheck.tooltipText = FBT("ATTACH_TIP"); 
    AttachModeCheck:SetScript("OnEnter", function() 
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT"); 
        GameTooltip:SetText(FBT("ATTACH")); 
        GameTooltip:AddLine(this.tooltipText, 1, 1, 1, true); 
        GameTooltip:Show(); 
    end); 
    AttachModeCheck:SetScript("OnLeave", function() GameTooltip:Hide(); end); 
    AttachModeCheck:SetScript("OnClick", function() 
        HealBox.AttachMode = AttachModeCheck:GetChecked(); 
        HealBoxAttachMode(HealBox.AttachMode); 
        FBUpdateNames(); 
    end); 
    
    HealCommCheck = CreateFrame("CheckButton", "FBHealBoxHealCommCheck", panel, "OptionsCheckButtonTemplate");
    HealCommCheck:SetPoint("TOPLEFT", 250, -500);
    HealCommCheck:SetChecked(1);
    HealCommCheck.Text = HealCommCheck:CreateFontString(nil, "BACKGROUND", "GameFontNormal");
    HealCommCheck.Text:SetPoint("LEFT", HealCommCheck, "RIGHT", 4, 1);
    HealCommCheck.Text:SetText(FBT("COMM"));
    HealCommCheck.tooltipText = FBT("COMM_TIP");
    HealCommCheck:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
        GameTooltip:SetText(FBT("COMM"));
        GameTooltip:AddLine(this.tooltipText, 1, 1, 1, true);
        GameTooltip:Show();
    end);
    HealCommCheck:SetScript("OnLeave", function() GameTooltip:Hide(); end);
    HealCommCheck:SetScript("OnClick", function()
        HealBox.HealComm = HealCommCheck:GetChecked() and 1 or 0;
        if (HealBox.HealComm == 0) then
            FBCommHeals = {};
            FBHealBox_RefreshAllBars();
        end
    end);

    -- Sprachumschalter: nutzt dasselbe Kaskadenmenue wie die Zauberwahl
    FBLangBtn = CreateFrame("Button", "FBHealBoxLangBtn", panel);
    FBLangBtn:SetWidth(180);
    FBLangBtn:SetHeight(26);
    FBLangBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 35, -535);
    FBLangBtn:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    });
    FBLangBtn:SetBackdropColor(0, 0, 0, 0.8);
    FBLangBtn:SetBackdropBorderColor(0.6, 0.6, 0.6, 1);

    FBLangBtn.text = FBLangBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    FBLangBtn.text:SetPoint("LEFT", 10, 0);
    FBLangBtn.text:SetPoint("RIGHT", -10, 0);
    FBLangBtn.text:SetJustifyH("LEFT");

    local langHl = FBLangBtn:CreateTexture(nil, "HIGHLIGHT");
    langHl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight");
    langHl:SetBlendMode("ADD");
    langHl:SetAllPoints(FBLangBtn);

    FBLangBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
        GameTooltip:SetText(FBT("LANGUAGE"));
        GameTooltip:AddLine(FBT("LANG_TIP"), 1, 1, 1, true);
        GameTooltip:Show();
    end);
    FBLangBtn:SetScript("OnLeave", function() GameTooltip:Hide(); end);
    FBLangBtn:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn");
        FBMenu_OpenLanguageMenu(FBLangBtn);
    end);

    panel.AboutText = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall"); 
    panel.AboutText:SetPoint("BOTTOM", panel, "BOTTOM", 0, 14); 
    panel.AboutText:SetWidth(400); 
    panel.AboutText:SetJustifyH("CENTER"); 
    panel.AboutText:SetText(format(FBT("ABOUT"), FBADDON_NAME, HealBoxVersion)); 

    FBHealBox_ApplyLocale(); 
end 

-- [ Namensplaketten Buttons ] -- 
FBPartyUnit = { "player", "party1", "party2", "party3", "party4" }; 
FBPartyFrame = {}; 
FBPartyTable = {}; 

function FBHealBoxButtons() 
    for p=1, 5, 1 do 
        for i=1, MaxButtonCount, 1 do 
            if (FBPartyTable[p][i]) then FBPartyTable[p][i]:Hide(); end; 
        end 
    end 
    for p=1, 5, 1 do 
        local unit = FBPartyUnit[p]; 
        local parentFrame = FBPartyFrame[p]; 
        local prevButton = nil; 
        for i=1, MaxButtonCount, 1 do 
            local anchor = prevButton or parentFrame; 
            FBPartyTable[p][i] = FBHealBoxCreateButton("", anchor, xSpacing, 0, FBDropDownButtonIcon[i], FBDropDownButton[i], unit, FBActiveSpellIDs[i]); 
            FBPartyTable[p][i].TargetUnit = unit; 
            FBPartyTable[p][i].spellName = FBDropDownButton[i]; 
            prevButton = FBPartyTable[p][i]; 
        end 
    end 
    for p=1, 5, 1 do 
        for i=1, MaxButtonCount, 1 do 
            FBPartyTable[p][i]:Hide(); 
        end 
    end 
    for p=1, 5, 1 do 
        for i=1, HealBox.MaxButtons, 1 do 
            FBPartyTable[p][i]:Show(); 
        end 
    end 
end 

function FBHealBoxButtonsChanged() 
    for p=1, 5, 1 do 
        for i=1, MaxButtonCount, 1 do 
            if (FBPartyTable[p][i]) then FBPartyTable[p][i]:Hide(); end; 
        end 
    end 
    for p=1, 5, 1 do 
        local unit = FBPartyUnit[p]; 
        for i=1, MaxButtonCount, 1 do 
            if (FBPartyTable[p][i]) then 
                FBPartyTable[p][i].TargetUnit = unit; 
                FBPartyTable[p][i].spellName = FBDropDownButton[i]; 
                FBPartyTable[p][i].id = FBActiveSpellIDs[i]; 
                if FBDropDownButtonIcon[i] then 
                    FBPartyTable[p][i].icon:SetTexture(FBDropDownButtonIcon[i]); 
                else 
                    FBPartyTable[p][i].icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); 
                end 
            end 
        end 
    end 
    for p=1, 5, 1 do 
        for i=1, HealBox.MaxButtons, 1 do 
            if (FBPartyTable[p][i]) then FBPartyTable[p][i]:Show(); end; 
        end 
    end 
end 

-- Sliderbeschriftungen: eigene Funktionen, damit der Sprachwechsel sie neu setzen kann
function FBUpdateButtonSliderText()
    if (MaxButtonSlider and MaxButtonSlider.Text) then
        MaxButtonSlider.Text:SetText(format(FBT("SHOW_BUTTONS"), MaxButtonSlider:GetValue()));
    end
end

function FBUpdateScaleSliderText()
    if (ScaleSlider and ScaleSlider.Text) then
        ScaleSlider.Text:SetText(format(FBT("SCALE"), format("%.1f", ScaleSlider:GetValue())));
    end
end

function MaxButtonSlider_Update() 
    FBUpdateButtonSliderText(); 
    HealBox.MaxButtons = MaxButtonSlider:GetValue(); 
    FBHealBoxButtonsChanged(); 
end 

function CreateMiniMapButton() 
    local button = CreateFrame("Button", "FBHealMiniMap", Minimap); 
    button:SetFrameStrata("MEDIUM"); 
    button:SetFrameLevel(8); 
    button:SetWidth(31); 
    button:SetHeight(31); 
    button:EnableMouse(1); 
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp"); 
    button:RegisterForDrag("RightButton"); 
    
    button.icon = button:CreateTexture("FBHealMiniMapIcon", "BACKGROUND"); 
    button.icon:SetWidth(17); 
    button.icon:SetHeight(17); 
    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 7, -6); 
    button.icon:SetTexture("Interface/Icons/Spell_Holy_GreaterHeal"); 
    button.icon:SetTexCoord(0.075, 0.925, 0.075, 0.925); 
    
    button.border = button:CreateTexture("FBHealMiniMapBorder", "OVERLAY"); 
    button.border:SetWidth(53); 
    button.border:SetHeight(53); 
    button.border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0); 
    button.border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder"); 
    
    button:SetHighlightTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight", "ADD"); 
    button.tooltipTitle = FBADDON_NAME; 
    button.tooltipText = FBT("MM_TIP"); 
    
    local mmAngle = math.rad(225); 
    button:SetPoint("TOPLEFT", "Minimap", "TOPLEFT", 52-(80*cos(mmAngle)), (80*sin(mmAngle))-52); 
    button:Show(); 
    
    button:SetScript("OnEnter", function() 
        GameTooltip:SetOwner(this, "ANCHOR_LEFT"); 
        GameTooltip:SetText(this.tooltipTitle); 
        GameTooltip:AddLine(this.tooltipText, 1, 1, 1); 
        GameTooltip:Show(); 
    end); 
    
    button:SetScript("OnLeave", function() 
        GameTooltip:Hide(); 
    end); 
    
    button:SetMovable(true); 
    button:SetScript("OnMouseDown", function() 
        if (arg1 == "RightButton") then this:StartMoving(); end 
    end); 
    
    button:SetScript("OnMouseUp", function() 
        if (arg1 == "RightButton") then this:StopMovingOrSizing(); end 
    end); 
    
    button:SetScript("OnClick", function() 
        if (arg1 == "LeftButton") then 
            if (IsShiftKeyDown()) then 
                HealBox.Active = 1 - HealBox.Active; 
                if (HealBox.Active == 1) then FBHealBox1:Show(); else FBHealBox1:Hide(); end 
            else 
                if (panel:IsVisible()) then FBMenu_CloseAll(); panel:Hide(); else panel:Show(); end 
            end 
        end 
    end); 
    return button; 
end 

function FBGetSpellID(spell, rank, debug) 
    local i = 1; 
    local spellID; 
    local highestRank; 
    while true do 
        local spellName = GetSpellName(i, SpellBookFrame.bookType); 
        if (not spellName) then break; end 
        if (spellName == spell) then 
            spellID = i; 
            highestRank = spellRank; 
        end 
        i = i + 1; 
        if (i > 300) then break; end 
    end            
    return spellID, highestRank; 
end 

function HealBoxButton_OnEvent(this, event, arg1) 
    if (HealBox.Active == 0) then return 0; end 
    if event=="SPELL_UPDATE_USABLE" then 
        if (this.id) then 
            local isUsable, noMana = IsUsableSpell(this.id, BOOKTYPE_SPELL); 
            icon = getglobal(this:GetName()); 
            if isUsable then 
                this.icon:SetVertexColor(1.0, 1.0, 1.0); 
            elseif noMana then 
                this.icon:SetVertexColor(0.5, 0.5, 1.0); 
            else 
                this.icon:SetVertexColor(0.3, 0.3, 0.3); 
            end 
            local inRange = IsSpellInRange(this.id, BOOKTYPE_SPELL, this.TargetUnit); 
            if (inRange == 0) then  
                this.icon:SetVertexColor(1.0, 0.3, 0.3); 
            end 
        end 
    end 
end 

function HealBoxScale(this, scale) 
    this:SetScale(scale); 
end 

function HealBoxAttachMode(mode) 
    local xoffset = 119; 
    local yoffset = 6; 
    
    if (mode == 1) then 
        FBHealBox1:SetScale(1); 
        FBHealBox2:SetPoint("LEFT", PartyMemberFrame1, "LEFT", xoffset, yoffset); 
        FBHealBox2:SetBackdropColor(0,0,0,0.8); 
        FBHealBox2:SetWidth(1); 
        FBHealBox2:SetHeight(1); 
        FBHealBox2.NameText:Hide(); 
        FBHealBox2.HPText:Hide(); 
        FBHealBox2.HealthBar:Hide(); FBHealBox2.ShieldBar:Hide(); FBHealBox2.IncHealBar:Hide(); 
        FBHealBox2:SetFrameStrata("LOW"); 
        FBHealBox2:Hide(); 
        
        FBHealBox3:SetPoint("LEFT", PartyMemberFrame2, "LEFT", xoffset, yoffset); 
        FBHealBox3:SetBackdropColor(0,0,0,0.8); 
        FBHealBox3:SetWidth(1); 
        FBHealBox3:SetHeight(1); 
        FBHealBox3.NameText:Hide(); 
        FBHealBox3.HPText:Hide(); 
        FBHealBox3.HealthBar:Hide(); FBHealBox3.ShieldBar:Hide(); FBHealBox3.IncHealBar:Hide(); 
        FBHealBox3:SetFrameStrata("LOW"); 
        FBHealBox3:Hide(); 
        
        FBHealBox4:SetPoint("LEFT", PartyMemberFrame3, "LEFT", xoffset, yoffset); 
        FBHealBox4:SetBackdropColor(0,0,0,0.8); 
        FBHealBox4:SetWidth(1); 
        FBHealBox4:SetHeight(1); 
        FBHealBox4.NameText:Hide(); 
        FBHealBox4.HPText:Hide(); 
        FBHealBox4.HealthBar:Hide(); FBHealBox4.ShieldBar:Hide(); FBHealBox4.IncHealBar:Hide(); 
        FBHealBox4:SetFrameStrata("LOW"); 
        FBHealBox4:Hide(); 
        
        FBHealBox5:SetPoint("LEFT", PartyMemberFrame4, "LEFT", xoffset, yoffset); 
        FBHealBox5:SetBackdropColor(0,0,0,0.8); 
        FBHealBox5:SetWidth(1); 
        FBHealBox5:SetHeight(1); 
        FBHealBox5.NameText:Hide(); 
        FBHealBox5.HPText:Hide(); 
        FBHealBox5.HealthBar:Hide(); FBHealBox5.ShieldBar:Hide(); FBHealBox5.IncHealBar:Hide(); 
        FBHealBox5:SetFrameStrata("LOW"); 
        FBHealBox5:Hide(); 
    else 
        FBHealBox1:SetScale(HealBox.Scale); 
        FBHealBox1:SetPoint("LEFT", WorldFrame, "LEFT", 100, 22); 
        FBHealBox1:SetBackdropColor(0,0,0,0.8); 
        FBHealBox1.NameText:Show(); 
        FBHealBox1.HPText:Show(); 
        FBHealBox1.HealthBar:Show(); FBHealBox1.ShieldBar:Show(); FBHealBox1.IncHealBar:Show(); 
        FBHealBox1:Hide(); 
        
        FBHealBox2:SetPoint("LEFT", FBHealBox1, "LEFT", 0, -32); 
        FBHealBox2:SetBackdropColor(0,0,0,0.8); 
        FBHealBox2:SetWidth(NamePlateWidth); 
        FBHealBox2:SetHeight(NamePlateHeight); 
        FBHealBox2.NameText:Show(); 
        FBHealBox2.HPText:Show(); 
        FBHealBox2.HealthBar:Show(); FBHealBox2.ShieldBar:Show(); FBHealBox2.IncHealBar:Show(); 
        FBHealBox_SetBarStrata(FBHealBox2, "BACKGROUND"); 
        FBHealBox2:Hide(); 
        
        FBHealBox3:SetPoint("LEFT", FBHealBox2, "LEFT", 0, -32); 
        FBHealBox3:SetBackdropColor(0,0,0,0.8); 
        FBHealBox3:SetWidth(NamePlateWidth); 
        FBHealBox3:SetHeight(NamePlateHeight); 
        FBHealBox3.NameText:Show(); 
        FBHealBox3.HPText:Show(); 
        FBHealBox3.HealthBar:Show(); FBHealBox3.ShieldBar:Show(); FBHealBox3.IncHealBar:Show(); 
        FBHealBox_SetBarStrata(FBHealBox3, "BACKGROUND"); 
        FBHealBox3:Hide(); 
        
        FBHealBox4:SetPoint("LEFT", FBHealBox3, "LEFT", 0, -32); 
        FBHealBox4:SetBackdropColor(0,0,0,0.8); 
        FBHealBox4:SetWidth(NamePlateWidth); 
        FBHealBox4:SetHeight(NamePlateHeight); 
        FBHealBox4.NameText:Show(); 
        FBHealBox4.HPText:Show(); 
        FBHealBox4.HealthBar:Show(); FBHealBox4.ShieldBar:Show(); FBHealBox4.IncHealBar:Show(); 
        FBHealBox_SetBarStrata(FBHealBox4, "BACKGROUND"); 
        FBHealBox4:Hide(); 
        
        FBHealBox5:SetPoint("LEFT", FBHealBox4, "LEFT", 0, -32); 
        FBHealBox5:SetBackdropColor(0,0,0,0.8); 
        FBHealBox5:SetWidth(NamePlateWidth); 
        FBHealBox5:SetHeight(NamePlateHeight); 
        FBHealBox5.NameText:Show(); 
        FBHealBox5.HPText:Show(); 
        FBHealBox5.HealthBar:Show(); FBHealBox5.ShieldBar:Show(); FBHealBox5.IncHealBar:Show(); 
        FBHealBox_SetBarStrata(FBHealBox5, "BACKGROUND"); 
        FBHealBox5:Hide(); 
    end 
end 

-- ==========================================================================
-- [ FB Heal Prediction :  Direktheilung + HoT-Ticks + Absorb-Schilde ]
--
-- Ersetzt FBHealCommLite komplett. Ein Tooltip-Parser, ein Lernspeicher,
-- ein Balken-Update - statt zwei Systemen, die sich gegenseitig ins
-- Gehege kommen.
--
--  1) Direktheilung (Flash Heal, Greater Heal, Healing Wave, ...)
--     SPELLCAST_START liefert Zaubername UND Castdauer - unabhaengig
--     davon, ob der Cast vom HealBox-Button, der Aktionsleiste oder aus
--     einem Makro kommt. Kein Hook auf CastSpellByName noetig.
--     Instants brauchen keine Vorhersage: die Heilung ist da, bevor ein
--     Balken sie anzeigen koennte.
--
--  2) HoT-Vorhersage (Renew, Rejuvenation, Regrowth-Anteil, ...)
--     UnitBuff() liefert fuer fremde Einheiten keine Restlaufzeit, also
--     fuehren wir selbst Buch: Cast vormerken -> UNIT_AURA bestaetigt die
--     Anwendung ueber die Buff-Textur -> Restticks aus
--     (Ablauf - GetTime()) / Intervall. Faellt der Buff weg, ist die
--     Anzeige sofort weg.
--
--  3) Schild-Vorhersage (Power Word: Shield, ...)
--     Maximaler Absorb aus dem Tooltip, Verbrauch aus dem Combatlog
--     ("(123 absorbed)").
--
--  Selbstkorrektur: Tooltips liefern in 1.12 nur Basiswerte ohne
--  +Heilung. Der Combatlog liefert die Wahrheit - jeder beobachtete
--  Tick, jede angekommene Direktheilung und jeder Absorb ueber dem
--  Tooltip-Wert schaerft die Schaetzung nach und wird pro Zauber+Rang
--  in den SavedVariables gemerkt. Crits werden dabei ignoriert (sie
--  wuerden die Vorhersage dauerhaft aufblasen).
--
--  Debug:  /fbp        Status + ausgelesene Tooltip-Werte
--          /fbp debug  Live-Ausgabe an/aus
--          /fbp reset  Gelernte Werte verwerfen
-- ==========================================================================

FBPREDICT_TICK_DEFAULT = 3;     -- Standard-Tickintervall in Sekunden
FBPREDICT_THROTTLE     = 0.2;   -- Update-Rate der Vorhersage
FBPREDICT_CONFIRM_TIME = 3.0;   -- Wartezeit auf Aura-Bestaetigung nach Cast
FBPREDICT_TARGET_TIME  = 2.0;   -- wie lange ein gemerktes Cast-Ziel gilt
FBPredictDebug = false;

-- Zauber mit abweichendem Tickintervall
FBPredictTickInterval = {
    ["Lifebloom"] = 1,
};

FBHoTs    = {};          -- [Name] = { [Zauber] = {rank, perTick, interval, expires} }
FBShields = {};          -- [Name] = { spell, rank, max, absorbed, expires }
FBPredictDirect = nil;   -- laufender Direktcast { target, spell, rank, amount, finish }

FBPredictWatch      = {};    -- [Zauber] = { tex, bookID, rank, hasDirect, hasHoT, hasShield }
FBPredictInfo       = {};    -- Cache: [bookID] = Tooltip-Auswertung
FBPredictPending    = nil;   -- eigener Cast, wartet auf Aura-Bestaetigung
FBPredictCastTarget = nil;   -- exaktes Ziel des letzten Button-Casts
FBPredictCastTime   = 0;
FBPredictAccum      = 0;

FBPredictUnits = {
    ["player"] = 1, ["party1"] = 1, ["party2"] = 1, ["party3"] = 1, ["party4"] = 1,
};

-- [ Tooltip-Scanner ] ------------------------------------------------------

FBPredictTip = CreateFrame("GameTooltip", "FBHealBoxScanTip", nil, "GameTooltipTemplate");
FBPredictTip:SetOwner(UIParent, "ANCHOR_NONE");

function FBPredict_TooltipText(bookID)
    if (not bookID) then return ""; end
    FBPredictTip:SetOwner(UIParent, "ANCHOR_NONE");
    FBPredictTip:ClearLines();
    FBPredictTip:SetSpell(bookID, BOOKTYPE_SPELL);

    local txt = "";
    local i = 1;
    while (i <= 30) do
        local fs = getglobal("FBHealBoxScanTipTextLeft"..i);
        if (not fs) then break; end
        local line = fs:GetText();
        if (line) then txt = txt.." "..line; end
        i = i + 1;
    end
    return txt;
end

function FBPredict_Find1(txt, patterns)
    for _, p in ipairs(patterns) do
        local _, _, a = string.find(txt, p);
        if (a) then return a; end
    end
    return nil;
end

function FBPredict_Find2(txt, patterns)
    for _, p in ipairs(patterns) do
        local _, _, a, b = string.find(txt, p);
        if (a and b) then return a, b; end
    end
    return nil;
end

-- Wertet den Zauberbuch-Tooltip aus. Ein Zauber kann mehrere Anteile
-- haben (Regrowth: Sofortheilung UND HoT), deshalb keine Entweder-Oder-
-- Klassifizierung, sondern drei unabhaengige Felder.
function FBPredict_GetSpellInfo(bookID, spellName)
    if (not bookID) then return nil; end
    if (FBPredictInfo[bookID] ~= nil) then
        if (FBPredictInfo[bookID] == false) then return nil; end
        return FBPredictInfo[bookID];
    end

    local txt  = FBPredict_TooltipText(bookID);
    local info = { direct = nil, hot = nil, shield = nil };
    local found = false;

    -- --- Absorb-Schild ---
    local absorb = FBPredict_Find1(txt, {
        "absorbing%s+(%d+)",
        "absorbs%s+(%d+)%s+damage",
    });
    if (absorb) then
        -- "Lasts 30 sec" bevorzugen; sonst die groesste Sekundenangabe,
        -- damit nicht die Zauberzeit ("1.5 sec cast") erwischt wird.
        local dur = FBPredict_Find1(txt, { "[Ll]asts%s+(%d+)%s+sec" });
        if (not dur) then
            local best = 0;
            for n in string.gfind(txt, "(%d+)%s+sec") do
                if (tonumber(n) > best) then best = tonumber(n); end
            end
            if (best > 0) then dur = best; end
        end
        info.shield = { amount = tonumber(absorb), duration = tonumber(dur) or 30 };
        found = true;
    end

    -- --- Heilung ueber Zeit ---
    local total, dur = FBPredict_Find2(txt, {
        "(%d+)%s+damage%s+over%s+(%d+)%s+sec",
        "(%d+)%s+over%s+(%d+)%s+sec",
        "for%s+(%d+)[^%d]-over%s+(%d+)%s+sec",
    });
    if (not total) then
        -- Notfall: letzte Zahl vor "over X sec" nehmen
        local s, _, d = string.find(txt, "over%s+(%d+)%s+sec");
        if (s) then
            local head = string.sub(txt, 1, s);
            local last = nil;
            for n in string.gfind(head, "(%d+)") do last = n; end
            if (last) then total = last; dur = d; end
        end
    end
    if (total and dur) then
        local interval = FBPredictTickInterval[spellName] or FBPREDICT_TICK_DEFAULT;
        local ticks = math.floor((tonumber(dur) / interval) + 0.5);
        if (ticks < 1) then ticks = 1; end
        info.hot = {
            total    = tonumber(total),
            duration = tonumber(dur),
            interval = interval,
            ticks    = ticks,
            perTick  = tonumber(total) / ticks,
        };
        found = true;
    end

    -- --- Sofortheilung ---
    -- "for 887 to 1033"  ->  Mittelwert
    local lo, hi = FBPredict_Find2(txt, { "(%d+)%s+to%s+(%d+)" });
    if (lo and hi) then
        info.direct = (tonumber(lo) + tonumber(hi)) / 2;
        found = true;
    else
        -- Einzelwert, aber nicht den HoT-Betrag doppelt zaehlen
        local one = FBPredict_Find1(txt, { "for%s+(%d+)" });
        if (one) and ((not info.hot) or (tonumber(one) ~= info.hot.total)) then
            info.direct = tonumber(one);
            found = true;
        end
    end

    if (found) then
        FBPredictInfo[bookID] = info;
        return info;
    end
    FBPredictInfo[bookID] = false;
    return nil;
end

-- Nach jedem Zauberbuch-Scan: was koennen die gelernten Zauber ueberhaupt?
function FBPredict_BuildWatch()
    FBPredictWatch = {};
    FBPredictInfo  = {};

    for spellName, ranks in pairs(FBPlayerSpells) do
        local top  = ranks[table.getn(ranks)];
        local info = FBPredict_GetSpellInfo(top.id, spellName);
        if (info) then
            FBPredictWatch[spellName] = {
                tex       = strupper(top.icon or ""),
                bookID    = top.id,
                rank      = top.rank,
                hasDirect = (info.direct ~= nil),
                hasHoT    = (info.hot ~= nil),
                hasShield = (info.shield ~= nil),
            };
        end
    end
end

-- [ Lernspeicher (wandert in die SavedVariables) ] --------------------------

function FBPredict_MemKey(kind, spell, rank)
    return kind.."|"..spell.."|"..(rank or "");
end

function FBPredict_Remembered(kind, spell, rank)
    if (not HealBox) or (not HealBox.PredictMemory) then return nil; end
    return HealBox.PredictMemory[FBPredict_MemKey(kind, spell, rank)];
end

function FBPredict_Remember(kind, spell, rank, value)
    if (not HealBox) then return; end
    if (not HealBox.PredictMemory) then HealBox.PredictMemory = {}; end
    HealBox.PredictMemory[FBPredict_MemKey(kind, spell, rank)] = value;
end

-- [ Tracking starten ] -----------------------------------------------------

function FBPredict_FindBookID(spellName, rank)
    local ranks = FBPlayerSpells[spellName];
    if (not ranks) then return nil; end
    for _, sd in ipairs(ranks) do
        if (sd.rank == rank) then return sd.id; end
    end
    return ranks[table.getn(ranks)].id;
end

-- rankKnown = true nur, wenn der Rang aus einem eigenen Button-Cast stammt.
-- Nur dann darf der beobachtete Wert dauerhaft gemerkt werden - sonst
-- wuerde ein Rang-3-Cast von der Aktionsleiste die Schaetzung fuer den
-- Maximalrang verderben.
function FBPredict_StartHoT(unitName, spellName, rank, bookID, rankKnown)
    local info = FBPredict_GetSpellInfo(bookID, spellName);
    if (not info) or (not info.hot) then return false; end

    local perTick = FBPredict_Remembered("tick", spellName, rank) or info.hot.perTick;
    if (not FBHoTs[unitName]) then FBHoTs[unitName] = {}; end
    FBHoTs[unitName][spellName] = {
        rank      = rank,
        rankKnown = rankKnown,
        perTick  = perTick,
        interval = info.hot.interval,
        expires  = GetTime() + info.hot.duration,
    };

    if (FBPredictDebug) then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[FBP]|r "..format(FBT("DBG_HOT"),
            spellName, unitName, math.floor(perTick), info.hot.duration));
    end

    -- Nur gesicherte eigene Casts funken. Ein per Aura entdeckter HoT
    -- koennte auch von einem anderen Heiler stammen - der erste eigene
    -- Combatlog-Tick holt das unten nach.
    if (rankKnown) then
        FBHoTs[unitName][spellName].commSent = true;
        FBComm_SendHoT(spellName, unitName, info.hot.duration);
    end
    return true;
end

function FBPredict_StartShield(unitName, spellName, rank, bookID, rankKnown)
    local info = FBPredict_GetSpellInfo(bookID, spellName);
    if (not info) or (not info.shield) then return false; end

    local amount = FBPredict_Remembered("absorb", spellName, rank) or info.shield.amount;
    FBShields[unitName] = {
        spell     = spellName,
        rank      = rank,
        rankKnown = rankKnown,
        max      = amount,
        absorbed = 0,
        expires  = GetTime() + info.shield.duration,
    };

    if (FBPredictDebug) then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[FBP]|r "..format(FBT("DBG_SHIELD"),
            spellName, unitName, math.floor(amount), info.shield.duration));
    end
    return true;
end

-- [ Abfrage durch die Balken ] ---------------------------------------------

function FBPredict_TicksLeft(e, now)
    local left = e.expires - now;
    if (left <= 0) then return 0; end
    return math.ceil((left / e.interval) - 0.05);
end

-- Summe aller noch ausstehenden HoT-Ticks
function FBGetHoTHeal(unitName)
    if (not unitName) then return 0; end
    local t = FBHoTs[unitName];
    if (not t) then return 0; end

    local now = GetTime();
    local sum = 0;
    for _, e in pairs(t) do
        local n = FBPredict_TicksLeft(e, now);
        if (n > 0) then sum = sum + (n * e.perTick); end
    end
    return sum;
end

-- Laufender Direktcast auf diese Einheit
function FBGetDirectHeal(unitName)
    local d = FBPredictDirect;
    if (not d) or (not unitName) then return 0; end
    if (d.target ~= unitName) then return 0; end
    if (GetTime() > d.finish) then return 0; end
    return d.amount;
end

-- Verbleibender Absorb
function FBGetShield(unitName)
    if (not unitName) then return 0; end
    local s = FBShields[unitName];
    if (not s) then return 0; end
    if (GetTime() > s.expires) then return 0; end

    local rem = s.max - s.absorbed;
    if (rem < 0) then rem = 0; end
    return rem;
end

-- [ Eigenen Cast vormerken (aus dem HealBox-Button) ] -----------------------

function FBPredict_SplitCast(castString)
    local _, _, base, rank = string.find(castString, "^(.+)%((.+)%)$");
    if (base) then return base, rank; end
    return castString, nil;
end

-- WICHTIG: direkt VOR CastSpellByName aufrufen - SPELLCAST_START feuert
-- sofort und braucht das Ziel bereits.
function FBPredict_NoteCast(castString, targetName)
    if (not castString) or (not targetName) then return; end

    FBPredictCastTarget = targetName;
    FBPredictCastTime   = GetTime();

    local base, rank = FBPredict_SplitCast(castString);
    if (not FBPredictWatch[base]) then return; end

    FBPredictPending = {
        spell  = base,
        rank   = rank,
        target = targetName,
        bookID = FBPredict_FindBookID(base, rank),
        t      = GetTime(),
    };
end

function FBPredict_ResolveTarget()
    if (FBPredictCastTarget and (GetTime() - FBPredictCastTime) <= FBPREDICT_TARGET_TIME) then
        return FBPredictCastTarget;
    end
    if (UnitExists("target") and UnitIsFriend("player", "target")) then
        return UnitName("target");
    end
    return UnitName("player");
end

-- [ Direktheilung: SPELLCAST_* ] -------------------------------------------

function FBPredict_CastStart(spellName, castMs)
    if (not spellName) then return; end
    local w = FBPredictWatch[spellName];
    if (not w) or (not w.hasDirect) then return; end

    local rank      = w.rank;
    local bookID    = w.bookID;
    local rankKnown = false;
    if (FBPredictPending and FBPredictPending.spell == spellName) then
        rank      = FBPredictPending.rank or rank;
        bookID    = FBPredictPending.bookID or bookID;
        rankKnown = true;
    end

    local info = FBPredict_GetSpellInfo(bookID, spellName);
    if (not info) or (not info.direct) then return; end

    local amount = FBPredict_Remembered("direct", spellName, rank) or info.direct;
    FBPredictDirect = {
        target    = FBPredict_ResolveTarget(),
        spell     = spellName,
        rank      = rank,
        rankKnown = rankKnown,
        amount    = amount,
        finish = GetTime() + ((castMs or 0) / 1000) + 0.3,
    };

    if (FBPredictDebug) then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[FBP]|r "..format(FBT("DBG_CAST"),
            spellName, FBPredictDirect.target, math.floor(amount)));
    end

    -- an andere Heiler funken (Puppeteer & Co. lesen mit)
    FBComm_SendHealStart(spellName, FBPredictDirect.target, amount, castMs);

    FBHealBox_RefreshAllBars();
end

function FBPredict_CastEnd()
    if (FBPredictDirect) then
        FBPredictDirect = nil;
        FBHealBox_RefreshAllBars();
    end
end

-- [ Aura-Scan: Anwendung bestaetigen, Wegfall erkennen ] --------------------

function FBPredict_ScanUnit(unit)
    if (not unit) or (not FBPredictUnits[unit]) then return; end
    if (not UnitExists(unit)) then return; end

    local name = UnitName(unit);
    if (not name) then return; end

    local textures = {};
    local i = 1;
    while (i <= 32) do
        local tex = UnitBuff(unit, i);
        if (not tex) then break; end
        textures[strupper(tex)] = true;
        i = i + 1;
    end

    local dirty = false;

    -- 1) Eigener Cast wartet auf Bestaetigung? Der hat Vorrang, damit auch
    --    ein Refresh (Nachcasten) die Uhr neu stellt.
    if (FBPredictPending and FBPredictPending.target == name) then
        local w = FBPredictWatch[FBPredictPending.spell];
        if (w and textures[w.tex]) then
            if (w.hasHoT) then
                dirty = FBPredict_StartHoT(name, FBPredictPending.spell,
                            FBPredictPending.rank, FBPredictPending.bookID, true) or dirty;
            end
            if (w.hasShield) then
                dirty = FBPredict_StartShield(name, FBPredictPending.spell,
                            FBPredictPending.rank, FBPredictPending.bookID, true) or dirty;
            end
            FBPredictPending = nil;
        end
    end

    -- 2) Generischer Abgleich: Buff da / Buff weg
    for spellName, w in pairs(FBPredictWatch) do
        local present = textures[w.tex];

        if (w.hasHoT) then
            local tracked = FBHoTs[name] and FBHoTs[name][spellName];
            if (present and not tracked) then
                -- z.B. von der Aktionsleiste: hoechster bekannter Rang,
                -- der erste Combatlog-Tick korrigiert den Wert ohnehin
                dirty = FBPredict_StartHoT(name, spellName, w.rank, w.bookID) or dirty;
            elseif (tracked and not present) then
                FBHoTs[name][spellName] = nil;
                dirty = true;
            end
        end

        if (w.hasShield) then
            local tracked = FBShields[name];
            if (present and ((not tracked) or tracked.spell ~= spellName)) then
                dirty = FBPredict_StartShield(name, spellName, w.rank, w.bookID) or dirty;
            elseif (tracked and tracked.spell == spellName and not present) then
                -- Schild gebrochen (vor Ablauf) -> Maximum nach oben lernen
                if (tracked.rankKnown and GetTime() < tracked.expires
                    and tracked.absorbed > tracked.max) then
                    FBPredict_Remember("absorb", tracked.spell, tracked.rank, tracked.absorbed);
                end
                FBShields[name] = nil;
                dirty = true;
            end
        end
    end

    if (dirty) then FBHealBox_RefreshAllBars(); end
end

-- [ Combatlog ] ------------------------------------------------------------

function FBPredict_ToPattern(gs, anchor)
    if (not gs) then return nil; end
    local p = string.gsub(gs, "([%^%$%(%)%.%[%]%*%+%-%?])", "%%%1");
    p = string.gsub(p, "%%s", "(.+)");
    p = string.gsub(p, "%%d", "(%%d+)");
    if (anchor) then return "^"..p.."$"; end
    return p;
end

function FBPredict_InitPatterns()
    -- "%s gains %d health from your %s."
    FBPredictPatHoTOther = FBPredict_ToPattern(PERIODICAURAHEALOTHERSELF, true)
                        or "^(.+) gains (%d+) health from your (.+)%.$";
    -- "You gain %d health from your %s."
    FBPredictPatHoTSelf  = FBPredict_ToPattern(PERIODICAURAHEALSELFSELF, true)
                        or "^You gain (%d+) health from your (.+)%.$";
    -- "Your %s heals %s for %d."   (Crits haben eine eigene Formulierung und
    --  laufen deshalb ins Leere - genau so gewollt)
    FBPredictPatHealOther = FBPredict_ToPattern(HEALEDSELFOTHER, true)
                        or "^Your (.+) heals (.+) for (%d+)%.$";
    -- "Your %s heals you for %d."
    FBPredictPatHealSelf  = FBPredict_ToPattern(HEALEDSELFSELF, true)
                        or "^Your (.+) heals you for (%d+)%.$";
    -- " (%d absorbed)"
    FBPredictPatAbsorb    = FBPredict_ToPattern(ABSORB_TRAILER, false)
                        or "%((%d+) absorbed%)";
end

-- Events, bei denen das Opfer immer der Spieler selbst ist
FBPredictSelfDamage = {
    ["CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS"]   = 1,
    ["CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE"]  = 1,
    ["CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE"]     = 1,
    ["CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF"]    = 1,
};

function FBPredict_ResolveVictim(event, msg)
    if (FBPredictSelfDamage[event]) then return UnitName("player"); end

    for name, _ in pairs(FBShields) do
        if (string.find(msg, name, 1, true)) then return name; end
    end

    if (string.find(msg, " you", 1, true) or string.find(msg, "You ", 1, true)) then
        return UnitName("player");
    end
    return nil;
end

function FBPredict_OnTick(unitName, amount, spellName)
    if (not unitName) or (not amount) or (not spellName) then return; end
    local t = FBHoTs[unitName];
    if (not t) or (not t[spellName]) then return; end

    local e = t[spellName];

    -- "... from your Renew" beweist: der HoT ist von uns. Falls er ueber
    -- die Aktionsleiste kam und noch nicht gefunkt wurde, jetzt nachholen.
    if (not e.commSent) then
        e.commSent = true;
        FBComm_SendHoT(spellName, unitName, e.expires - GetTime());
    end

    if (amount > 0 and e.perTick ~= amount) then
        e.perTick = amount;
        if (e.rankKnown) then
            FBPredict_Remember("tick", spellName, e.rank, amount);
        end
        if (FBPredictDebug) then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[FBP]|r "..format(FBT("DBG_TICK"),
                spellName, amount));
        end
    end
    FBHealBox_RefreshAllBars();
end

function FBPredict_OnDirectHeal(spellName, targetName, amount)
    if (not spellName) or (not amount) then return; end
    local w = FBPredictWatch[spellName];
    if (not w) then return; end   -- faengt auch die Crit-Formulierung ab

    -- Nur lernen, wenn der gecastete Rang gesichert ist (Button-Cast).
    -- Ein Downrank von der Aktionsleiste wuerde sonst dem Maximalrang
    -- zugeschrieben und die Vorhersage nach unten ziehen.
    if (FBPredictDirect and FBPredictDirect.spell == spellName and FBPredictDirect.rankKnown) then
        local rank = FBPredictDirect.rank;
        -- Heilungen streuen innerhalb einer Spanne -> sanft einpendeln
        local old = FBPredict_Remembered("direct", spellName, rank);
        local value = amount;
        if (old) then value = (old + amount) / 2; end
        FBPredict_Remember("direct", spellName, rank, value);

        if (FBPredictDebug) then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[FBP]|r "..format(FBT("DBG_HEAL"),
                spellName, amount, math.floor(value)));
        end
    end

    if (FBPredictDirect and FBPredictDirect.target == targetName) then
        FBPredictDirect = nil;
    end
    FBHealBox_RefreshAllBars();
end

function FBPredict_OnAbsorb(unitName, amount)
    local s = FBShields[unitName];
    if (not s) or (not amount) then return; end

    s.absorbed = s.absorbed + amount;
    if (s.absorbed > s.max) then
        -- mehr absorbiert als der Tooltip hergibt (+Heilung) -> anheben
        s.max = s.absorbed;
        if (s.rankKnown) then
            FBPredict_Remember("absorb", s.spell, s.rank, s.max);
        end
    end

    if (FBPredictDebug) then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[FBP]|r "..format(FBT("DBG_ABSORB"),
            amount, unitName, math.floor(s.max - s.absorbed)));
    end
    FBHealBox_RefreshAllBars();
end

function FBPredict_ParseCombat(event, msg)
    if (not msg) then return; end

    -- Direktheilung auf jemand anderen: "Your Flash Heal heals Bob for 1240."
    local _, _, spell, who, amt = string.find(msg, FBPredictPatHealOther);
    if (spell and who and amt) then
        FBPredict_OnDirectHeal(spell, who, tonumber(amt));
        return;
    end

    -- Direktheilung auf mich: "Your Flash Heal heals you for 1240."
    local _, _, spell2, amt2 = string.find(msg, FBPredictPatHealSelf);
    if (spell2 and amt2) then
        FBPredict_OnDirectHeal(spell2, UnitName("player"), tonumber(amt2));
        return;
    end

    -- HoT-Tick auf jemand anderen: "Bob gains 194 health from your Renew."
    local _, _, who3, amt3, spell3 = string.find(msg, FBPredictPatHoTOther);
    if (who3 and amt3 and spell3) then
        FBPredict_OnTick(who3, tonumber(amt3), spell3);
        return;
    end

    -- HoT-Tick auf mich: "You gain 194 health from your Renew."
    local _, _, amt4, spell4 = string.find(msg, FBPredictPatHoTSelf);
    if (amt4 and spell4) then
        FBPredict_OnTick(UnitName("player"), tonumber(amt4), spell4);
        return;
    end

    -- Absorb-Anteil: "... hits Bob for 120. (80 absorbed)"
    local _, _, abs = string.find(msg, FBPredictPatAbsorb);
    if (abs) then
        local victim = FBPredict_ResolveVictim(event, msg);
        if (victim) then FBPredict_OnAbsorb(victim, tonumber(abs)); end
    end
end

-- [ Event-Frame ] ----------------------------------------------------------

FBPredictEvents = {
    "UNIT_AURA",
    "CHAT_MSG_ADDON",
    -- eigener Cast
    "SPELLCAST_START",
    "SPELLCAST_STOP",
    "SPELLCAST_FAILED",
    "SPELLCAST_INTERRUPTED",
    "SPELLCAST_DELAYED",
    -- angekommene Heilung + HoT-Ticks
    "CHAT_MSG_SPELL_SELF_BUFF",
    "CHAT_MSG_SPELL_PARTY_BUFF",
    "CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF",
    "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS",
    "CHAT_MSG_SPELL_PERIODIC_PARTY_BUFFS",
    "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS",
    "CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS",
    -- Schaden mit Absorb-Anteil
    "CHAT_MSG_COMBAT_CREATURE_VS_SELF_HITS",
    "CHAT_MSG_COMBAT_CREATURE_VS_PARTY_HITS",
    "CHAT_MSG_COMBAT_HOSTILEPLAYER_HITS",
    "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE",
    "CHAT_MSG_SPELL_CREATURE_VS_PARTY_DAMAGE",
    "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE",
    "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",
    "CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE",
    "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE",
    "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE",
    "CHAT_MSG_SPELL_DAMAGESHIELDS_ON_SELF",
};

FBPredictFrame = CreateFrame("Frame", "FBHealBoxPredict", UIParent);
for _, ev in ipairs(FBPredictEvents) do
    pcall(function() FBPredictFrame:RegisterEvent(ev); end);
end

FBPredictFrame:SetScript("OnEvent", function()
    if (event == "UNIT_AURA") then
        FBPredict_ScanUnit(arg1);

    elseif (event == "CHAT_MSG_ADDON") then
        FBComm_OnMessage(arg1, arg2, arg3, arg4);

    elseif (event == "SPELLCAST_START") then
        FBPredict_CastStart(arg1, tonumber(arg2));

    elseif (event == "SPELLCAST_STOP") then
        -- Erfolgreich beendet: HealComm-Empfaenger lassen den Eintrag
        -- selbst auslaufen, hier wird bewusst kein Healstop gefunkt.
        FBPredict_CastEnd();

    elseif (event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED") then
        if (FBPredictDirect) then FBComm_SendHealStop(); end
        FBPredict_CastEnd();

    elseif (event == "SPELLCAST_DELAYED") then
        if (FBPredictDirect and arg1) then
            FBPredictDirect.finish = FBPredictDirect.finish + (tonumber(arg1) / 1000);
            FBComm_SendHealDelay(arg1);
        end

    else
        FBPredict_ParseCombat(event, arg1);
    end
end);

FBPredictFrame:SetScript("OnUpdate", function()
    FBPredict_OnUpdate(arg1);
end);

function FBPredict_OnUpdate(elapsed)
    FBPredictAccum = FBPredictAccum + (elapsed or 0);
    if (FBPredictAccum < FBPREDICT_THROTTLE) then return; end
    FBPredictAccum = 0;

    local now   = GetTime();
    local dirty = false;

    for _, spells in pairs(FBHoTs) do
        for spellName, e in pairs(spells) do
            if (now >= e.expires) then
                spells[spellName] = nil;
                dirty = true;
            else
                local n = FBPredict_TicksLeft(e, now);
                if (n ~= e.lastTicks) then
                    e.lastTicks = n;
                    dirty = true;
                end
            end
        end
    end

    for name, s in pairs(FBShields) do
        if (now >= s.expires) then
            FBShields[name] = nil;
            dirty = true;
        end
    end

    for _, casters in pairs(FBCommHeals) do
        for caster, info in pairs(casters) do
            if (now >= info.expires) then
                casters[caster] = nil;
                dirty = true;
            end
        end
    end

    if (FBPredictDirect and now > FBPredictDirect.finish) then
        FBPredictDirect = nil;
        dirty = true;
    end

    if (FBPredictPending and (now - FBPredictPending.t) > FBPREDICT_CONFIRM_TIME) then
        FBPredictPending = nil;
    end

    if (dirty) then FBHealBox_RefreshAllBars(); end
end

FBPredict_InitPatterns();

-- ==========================================================================
-- [ HealComm-Protokoll ]  Interop mit Puppeteer, pfUI, Luna, CT_RaidAssist ...
--
-- HealComm-1.0 (Ace2) funkt reinen Klartext ueber SendAddonMessage mit dem
-- Prefix "HealComm". Wir sprechen dieselbe Sprache - ohne die Bibliothek
-- einzubinden:
--
--   Heal/<Ziel>/<Betrag>/<Castzeit ms>/     Direktheilung startet
--   Healstop                                Cast abgebrochen
--   Healdelay/<ms>/                         Pushback
--   GrpHeal/<Betrag>/<ms>/<Z1>/<Z2>/...     Gruppenheilung (Prayer of Healing)
--   GrpHealstop  /  GrpHealdelay/<ms>/
--   Renew|Reju|Regr/<Ziel>/<Dauer sec>/     HoT angewendet
--
-- Empfaenger ignorieren die eigenen Nachrichten (Absender == man selbst),
-- und HealComm legt eingehende Heilungen pro Caster ab - doppelt gesendete
-- Nachrichten (z.B. wenn parallel noch ein echtes HealComm laeuft)
-- ueberschreiben denselben Eintrag statt sich zu addieren.
--
-- Die Betraege sind unsere selbstkorrigierten Werte aus dem Combatlog,
-- also inkl. +Heilung und Talenten - kein ItemBonusLib noetig.
-- ==========================================================================

FBCOMM_PREFIX   = "HealComm";
FBCommHeals     = {};      -- [Ziel] = { [Caster] = { amount, expires } }
FBCommSentGroup = false;   -- war der zuletzt gesendete Cast ein Gruppenheal?

FBCommHoTCode = {
    ["Renew"]        = "Renew",
    ["Rejuvenation"] = "Reju",
    ["Regrowth"]     = "Regr",
};

FBCommGroupHeal = {
    ["Prayer of Healing"] = 1,
};

function FBComm_Enabled()
    return (HealBox and HealBox.HealComm and HealBox.HealComm ~= 0);
end

function FBComm_Send(msg)
    if (not FBComm_Enabled()) then return; end

    local n = GetNumRaidMembers();
    if (n and n > 0) then
        SendAddonMessage(FBCOMM_PREFIX, msg, "RAID");
    else
        n = GetNumPartyMembers();
        if (n and n > 0) then
            SendAddonMessage(FBCOMM_PREFIX, msg, "PARTY");
        else
            return;  -- allein: niemand da, der zuhoert
        end
    end

    if (FBPredictDebug) then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF88CCFF[FBP>]|r "..msg);
    end
end

-- [ Senden ] ---------------------------------------------------------------

function FBComm_SendHealStart(spellName, target, amount, castMs)
    if (not FBComm_Enabled()) or (not target) then return; end

    amount = math.floor(amount or 0);
    castMs = math.floor(castMs or 0);
    if (amount <= 0) then return; end

    if (FBCommGroupHeal[spellName]) then
        -- Gruppenheilung: alle Ziele in Reichweite mitschicken
        local names = UnitName("player").."/";
        for i = 1, 4 do
            local u = "party"..i;
            if (UnitExists(u) and CheckInteractDistance(u, 4)) then
                names = names..UnitName(u).."/";
            end
        end
        FBCommSentGroup = true;
        FBComm_Send("GrpHeal/"..amount.."/"..castMs.."/"..names);
    else
        FBCommSentGroup = false;
        FBComm_Send("Heal/"..target.."/"..amount.."/"..castMs.."/");
    end
end

function FBComm_SendHealStop()
    if (FBCommSentGroup) then
        FBComm_Send("GrpHealstop");
    else
        FBComm_Send("Healstop");
    end
end

function FBComm_SendHealDelay(ms)
    ms = tonumber(ms);
    if (not ms) then return; end
    if (FBCommSentGroup) then
        FBComm_Send("GrpHealdelay/"..math.floor(ms).."/");
    else
        FBComm_Send("Healdelay/"..math.floor(ms).."/");
    end
end

function FBComm_SendHoT(spellName, target, duration)
    local code = FBCommHoTCode[spellName];
    if (not code) or (not target) or (not duration) then return; end
    if (duration < 1) then return; end
    FBComm_Send(code.."/"..target.."/"..math.floor(duration).."/");
end

-- [ Empfangen ] ------------------------------------------------------------

function FBComm_Split(str)
    local t = {};
    for w in string.gfind(str, "([^/]+)") do
        table.insert(t, w);
    end
    return t;
end

-- Ein Caster hat immer nur einen Heilzauber unterwegs
function FBComm_ClearCaster(caster)
    for _, casters in pairs(FBCommHeals) do
        if (casters[caster]) then casters[caster] = nil; end
    end
end

function FBComm_DelayCaster(caster, ms)
    local add = (tonumber(ms) or 0) / 1000;
    for _, casters in pairs(FBCommHeals) do
        if (casters[caster]) then
            casters[caster].expires = casters[caster].expires + add;
        end
    end
end

function FBComm_OnMessage(prefix, msg, channel, sender)
    if (prefix ~= FBCOMM_PREFIX) or (not msg) or (not sender) then return; end
    if (sender == UnitName("player")) then return; end   -- eigene Nachrichten ignorieren
    if (not FBComm_Enabled()) then return; end

    local p     = FBComm_Split(msg);
    local cmd   = p[1];
    local now   = GetTime();
    local dirty = false;

    if (cmd == "Heal" and p[2] and p[3] and p[4]) then
        FBComm_ClearCaster(sender);
        if (not FBCommHeals[p[2]]) then FBCommHeals[p[2]] = {}; end
        FBCommHeals[p[2]][sender] = {
            amount  = tonumber(p[3]) or 0,
            expires = now + ((tonumber(p[4]) or 0) / 1000),
        };
        dirty = true;

    elseif (cmd == "GrpHeal" and p[2] and p[3]) then
        FBComm_ClearCaster(sender);
        local amount  = tonumber(p[2]) or 0;
        local expires = now + ((tonumber(p[3]) or 0) / 1000);
        local i = 4;
        while (p[i]) do
            if (not FBCommHeals[p[i]]) then FBCommHeals[p[i]] = {}; end
            FBCommHeals[p[i]][sender] = { amount = amount, expires = expires };
            i = i + 1;
        end
        dirty = true;

    elseif (cmd == "Healstop" or cmd == "GrpHealstop") then
        FBComm_ClearCaster(sender);
        dirty = true;

    elseif ((cmd == "Healdelay" or cmd == "GrpHealdelay") and p[2]) then
        FBComm_DelayCaster(sender, p[2]);
        dirty = true;
    end
    -- HoT-Nachrichten (Renew/Reju/Regr) tragen nur Laufzeiten, keine
    -- Betraege - HealComm selbst zaehlt sie ebenfalls nicht zur
    -- eingehenden Heilung. Wir ignorieren sie deshalb hier.

    if (dirty) then FBHealBox_RefreshAllBars(); end
end

-- Eingehende Heilung anderer Heiler auf diese Einheit
function FBGetCommHeal(unitName)
    if (not unitName) then return 0; end
    local casters = FBCommHeals[unitName];
    if (not casters) then return 0; end

    local now = GetTime();
    local sum = 0;
    for _, info in pairs(casters) do
        if (info.expires > now) then sum = sum + info.amount; end
    end
    return sum;
end

-- [ Debug-Kommando ] -------------------------------------------------------

SLASH_FBHEALPREDICT1 = "/fbp";
SlashCmdList["FBHEALPREDICT"] = function(msg)
    if (msg == "debug") then
        FBPredictDebug = not FBPredictDebug;
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[FBP]|r "..FBT("FBP_DEBUG").." "..tostring(FBPredictDebug));
        return;
    end

    if (msg == "reset") then
        if (HealBox) then HealBox.PredictMemory = {}; end
        FBPredictInfo = {};
        FBPredict_BuildWatch();
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[FBP]|r "..FBT("FBP_RESET"));
        return;
    end

    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[FBP]|r "..FBT("FBP_WATCHED"));
    for spellName, w in pairs(FBPredictWatch) do
        local info = FBPredict_GetSpellInfo(w.bookID, spellName);
        if (info) then
            local parts = "";
            if (info.direct) then
                local learned = FBPredict_Remembered("direct", spellName, w.rank);
                parts = parts.." "..FBT("FBP_DIRECT").."="..math.floor(info.direct);
                if (learned) then
                    parts = parts.."("..FBT("FBP_LEARNED").." "..math.floor(learned)..")";
                end
            end
            if (info.hot) then
                parts = parts.." HoT="..math.floor(info.hot.perTick).."x"..info.hot.ticks
                        .." "..FBT("FBP_EVERY").." "..info.hot.interval.."s";
            end
            if (info.shield) then
                parts = parts.." "..FBT("FBP_SHIELD").."="..info.shield.amount
                        .."/"..info.shield.duration.."s";
            end
            DEFAULT_CHAT_FRAME:AddMessage("   "..spellName.." ("..tostring(w.rank)..")"..parts);
        end
    end

    local now = GetTime();
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[FBP]|r "..FBT("FBP_ACTIVE"));
    if (FBPredictDirect) then
        DEFAULT_CHAT_FRAME:AddMessage("   "..FBT("FBP_CAST").." "..FBPredictDirect.spell
            .." "..FBT("FBP_ON").." "..FBPredictDirect.target..": "
            ..math.floor(FBPredictDirect.amount));
    end
    for name, spells in pairs(FBHoTs) do
        for spellName, e in pairs(spells) do
            DEFAULT_CHAT_FRAME:AddMessage("   HoT "..name.." / "..spellName..": "
                ..FBPredict_TicksLeft(e, now).." "..FBT("FBP_TICKSOF").." "
                ..math.floor(e.perTick));
        end
    end
    for name, s in pairs(FBShields) do
        DEFAULT_CHAT_FRAME:AddMessage("   "..FBT("FBP_SHIELD").." "..name.." / "..s.spell
            ..": "..math.floor(s.max - s.absorbed).." "..FBT("FBP_OF").." "
            ..math.floor(s.max));
    end

    local state = FBT("FBP_STATE_OFF");
    if (FBComm_Enabled()) then state = FBT("FBP_STATE_ON"); end
    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFF[FBP]|r "..FBT("FBP_SYNC").." "..state);
    for target, casters in pairs(FBCommHeals) do
        for caster, info in pairs(casters) do
            if (info.expires > now) then
                DEFAULT_CHAT_FRAME:AddMessage("   "..FBT("FBP_INCOMING").." "..caster
                    .." -> "..target..": "..math.floor(info.amount));
            end
        end
    end
end

function FBHealBox_UpdateUnit(unit, frame) 
    if not UnitExists(unit) then return end 
    local hp = UnitHealth(unit); 
    local hpMax = UnitHealthMax(unit); 
    local hpPercent = hp / hpMax; 
    frame.HPText:SetText(format("%d%%", hpPercent * 100)); 
    frame.HealthBar:SetMinMaxValues(0, hpMax); 
    frame.HealthBar:SetValue(hp); 
    
    local name = UnitName(unit);

    -- Eigener Direktcast + eigene HoT-Restticks + Heilung anderer Heiler
    local incHeal = FBGetDirectHeal(name) + FBGetHoTHeal(name) + FBGetCommHeal(name);

    -- Absorb-Schild als Pseudoleben direkt hinter den aktuellen HP
    local shieldTop = math.min(hpMax, hp + FBGetShield(name));
    frame.ShieldBar:SetMinMaxValues(0, hpMax);
    frame.ShieldBar:SetValue(shieldTop);

    -- Heilvorhersage haengt hinter dem Schild-Anteil
    frame.IncHealBar:SetMinMaxValues(0, hpMax);
    frame.IncHealBar:SetValue(math.min(hpMax, shieldTop + incHeal));
    
    local dispellableTypes = {}; 
    if FBClass == "Priest" then 
        dispellableTypes["Magic"] = {0.2, 0.6, 1, 1}; 
        dispellableTypes["Disease"] = {0.6, 0.4, 0, 1}; 
    elseif FBClass == "Paladin" then 
        dispellableTypes["Magic"] = {0.2, 0.6, 1, 1}; 
        dispellableTypes["Poison"] = {0, 0.6, 0, 1}; 
        dispellableTypes["Disease"] = {0.6, 0.4, 0, 1}; 
    elseif FBClass == "Shaman" then 
        dispellableTypes["Poison"] = {0, 0.6, 0, 1}; 
        dispellableTypes["Disease"] = {0.6, 0.4, 0, 1}; 
    elseif FBClass == "Druid" then 
        dispellableTypes["Curse"] = {0.6, 0, 1, 1}; 
        dispellableTypes["Poison"] = {0, 0.6, 0, 1}; 
    end 
    
    local hasDebuff = false; 
    for i = 1, 16 do 
        local texture, count, debuffType = UnitDebuff(unit, i); 
        if not texture then break end 
        if debuffType and dispellableTypes[debuffType] then 
            local color = dispellableTypes[debuffType]; 
            frame.HealthBar:SetStatusBarColor(color[1], color[2], color[3], color[4]); 
            hasDebuff = true; 
            break; 
        end 
    end 
    
    if not hasDebuff then 
        if hpPercent > LowHP then  
            frame.HealthBar:SetStatusBarColor(0, 1, 0, 1); 
        elseif hpPercent > VeryLowHP then  
            frame.HealthBar:SetStatusBarColor(1, 0.9, 0, 1); 
        else  
            frame.HealthBar:SetStatusBarColor(1, 0, 0, 1); 
        end 
    end 
end 

MMButton = CreateMiniMapButton(); 
FBHealBoxSetup(); 
FBHealBoxCreateAddonOptionFrame();