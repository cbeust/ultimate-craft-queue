UltimateCraftQueue = LibStub("AceAddon-3.0"):NewAddon("UltimateCraftQueue", "AceConsole-3.0")

AceGUI = LibStub:GetLibrary("AceGUI-3.0")

function UltimateCraftQueue:OnInitialize()
  self:RegisterChatCommand("ucq", "ChatCommand")
  UltimateCraftQueue.message = "welcome"
    -- Called when the addon is loaded
end

function UltimateCraftQueue:OnEnable()
end

function UltimateCraftQueue:OnDisable()
    -- Called when the addon is disabled
end

function UltimateCraftQueue:ChatCommand(input)
  print("input:" .. input)
  if not input or input:trim() == "" then
    ucq_ShowUi()
  else
    LibStub("AceConfigCmd-3.0").HandleCommand(UltimateCraftQueue, "ucq", "UltimateCraftQueue", input)
  end
end


-- Kevin Marquette
-- www.ithinkincode.com/warcraft

local frame = CreateFrame("FRAME", "KevToolQueueFrame");

function KevToolQueue_OnLoad()
  --math.randomseed();

  log("Loading UCQ");  
  SLASH_ULTIMATECRAFTQUEUE1 = "/ultimatecraftqueue";
  SLASH_ULTIMATECRAFTQUEUE2 = "/ucq";
  SlashCmdList["ULTIMATECRAFTQUEUE"] = function(msg)
    KTQSlashCommandHandler(msg:upper(),msg);
  end  
  
  if not KTQuseBonusQueue then
    KTQuseBonusQueue = false
  end
  
  
  if not KTQBonusQueue then
    KTQBonusQueue = 2
  end
  
--  if not KTQskipSingles then
--    KTQskipSingles = false
--  end
  if not KTQuseThreshold then
    KTQuseThreshold = false
  end
  
  if not KTQThreshold then
    KTQThreshold = 50000
  end
  
  if not KTQuseFallback then
    KTQuseFallback = false
  end
  
  if not KTQuseQuickAuction then
    KTQuseQuickAuction = false
    KTQuseAucAdvanced = true
  end
  log("UltimateCraftQueue loaded: type /ucq for options");
end

function ucq_HandleOverrides(msg)
 log("Overrides:@" .. msg .. "@")
  local tbl = {}
  i = 0
  for v in string.gmatch(msg, "[^ ]+") do
    if i >= 2 then
      log("inserting " .. v)
      tinsert(tbl, v)
    end
    i = i + 1
  end
  if OverridesDB == nil then
    OverridesDB = {}
  end
  for i = 1, #tbl, 2 do
    cls = tbl[i]
    value = tbl[i + 1]
    log("OVERRIDE " .. cls .. ":" .. value)
    OverridesDB[cls] = value
  end

end

if UltimateCraftQueueDB == nil then
  UltimateCraftQueueDB = {
    ["stackSizes"] = {
      ["Death Knight"] = 6,
      ["Paladin"] = 0
    },
    ["stackSize"] = 4,
  }
end

function ucq_GetStackSize(cls, defaultStackSize)
  stackSizes = { ["Death Knight"] = 6, ["Paladin"] = 0 }
  result = stackSizes[cls]
  if (result == nil) then
    result = defaultStackSize
  end

  return result
end  
  
function KTQQueueItem(stackSize, group)
  local totalQueue = 0
  local totalAdded = 0
  for i = 1, GetNumTradeSkills() do
    local itemLink = GetTradeSkillItemLink(i)

    if (itemLink ~= nil) then
      local itemId = Skillet:GetItemIDFromLink(itemLink)
      cls = ucq_GetClass(itemId)
--      cls = ucq_GetClassOfGlyphByLink(itemLink);
      if (cls ~= nil) then
        realStackSize = ucq_GetStackSize(cls, stackSize)
        queue, added = ucq_Process(i, realStackSize, group, itemLink, itemId)
        ucq_LogQueue(itemId, itemLink, queue)
        totalQueue = totalQueue + queue;
        totalAdded = totalAdded + added;
--      else
--        ucq_LogBlue("No class found for " .. itemLink)
      end
    end -- if

  end -- for

  ucq_LogGreen("============= Summary =============")
  for k, v in pairs(ucq_GLYPHS_QUEUED_BY_CLASSES) do
    ucq_LogGreen(k .. ":" .. v)
  end
  ucq_LogGreen("Total number of glyph added: "..totalAdded )
  ucq_LogGreen("Total number of items added: "..totalQueue)

end

function ucq_Process(i, stackSize, group, itemLink, itemId)
  local totalQueue = 0
  local totalAdded = 0
  local totalSkipped = 0
  --Figure out if its an enchant or not
  _, _, _, _, altVerb = GetTradeSkillInfo(i)
  if LSW.scrollData[itemId] ~= nil and altVerb == 'Enchant' then
     -- Ask LSW for the correct scroll
     itemId = LSW.scrollData[itemId]["scrollID"]
  end
  
  local skillName, skillType, numAvailable, isExpanded, altVerb = GetTradeSkillInfo(i)
  local enchantLink = GetTradeSkillRecipeLink(i)
  
  if enchantLink ~= nil and (KTQIsMatch(skillName, group) == true or group == tostring(itemId)) then
    local count = Altoholic:GetItemCount(itemId)
    if count < stackSize then
    
    local found, _, skillString = string.find(enchantLink, "^|%x+|H(.+)|h%[.+%]")
    local _, skillId = strsplit(":", skillString )
    local toQueue = stackSize - count
    if KTQuseBonusQueue == true and toQueue == stackSize then
      toQueue = toQueue + KTQBonusQueue
    end

    --
    -- Compare to the threshold
    local minBuyout = KTQGetLowestPrice(itemLink)
      
    if (minBuyout ~= nil and minBuyout < ucq_GetThreshold()) then
        
      ucq_LogRed("Skipping " .. itemLink
          .." (under threshold "..KTQFormatCopperToText(minBuyout,true) .. ")")
      toQueue = 0
    end
    
    if (not ucq_GetSkipSingles() or toQueue > 1) and toQueue ~= 0 then
    -- This is where curse client crashes
      AddToQueue(skillId,i, toQueue)
      totalQueue = totalQueue + toQueue
      totalAdded = totalAdded  + 1
    else
      ucq_LogRed("Skipping " .. itemLink .. " (skipSingles is on)")
      totalSkipped = totalSkipped  + 1
    end
  end

  return totalQueue, totalAdded;

--  DEFAULT_CHAT_FRAME:AddMessage("Keyword: "..group)
--  DEFAULT_CHAT_FRAME:AddMessage("Stack Size: "..stackSize)
--  DEFAULT_CHAT_FRAME:AddMessage("Total Added: "..totalQueue)
--  DEFAULT_CHAT_FRAME:AddMessage("Items Added: "..totalAdded )
--  DEFAULT_CHAT_FRAME:AddMessage("Items Skipped: "..totalSkipped)
end
end

ucq_GLYPHS_QUEUED_BY_CLASSES = {}

function ucq_ResetVariables()
  ucq_GLYPHS_QUEUED_BY_CLASSES = {}
end

function ucq_LogQueue(itemId, itemLink, itemCount)
  local h = ucq_GLYPHS_QUEUED_BY_CLASSES
--  local cls = ucq_GetClassOfGlyphByLink(itemLink)
  local cls = ucq_GetClass(itemId)
  if cls ~= nil and itemCount > 0 then
    count = h[cls]
    if (count == nil) then
      count = 0
    end
    count = count + itemCount
    h[cls] = count
    ucq_LogGreen("Queuing " .. itemCount .. " " .. itemLink .. " (" .. cls .. ")")
--  else
--    ucq_LogBlue("Couldn't find a class for " .. itemLink .. " id:" .. itemId)
  end
end

function AddToQueue(skillId, skillIndex, toQueue)
  if Skillet == nil then
    log("Skillet not loaded")
  end
  if Skillet.QueueCommandIterate ~= nil then
    local queueCommand = Skillet:QueueCommandIterate(tonumber(skillId), toQueue)
    Skillet:AddToQueue(queueCommand)
  else
    Skillet.stitch:AddToQueue(skillIndex, toQueue)
  end
end

function KTQIsMatch(skillName, group)

  if skillName == nil then return false end

  -- Glyphs
  if string.find(skillName,"Glyph of") ~= nil and group == "Glyphs" then
    return true
  end

  -- Epic Gems
  if string.find(skillName,"Cardinal Ruby") ~= nil and group == "EpicGems" then
    return true
  end
  if string.find(skillName,"Ametrine") ~= nil and group == "EpicGems" then
    return true
  end
  if string.find(skillName,"King's Amber") ~= nil and group == "EpicGems" then
    return true
  end
  if string.find(skillName,"Eye of Zul") ~= nil and group == "EpicGems" then
    return true
  end
  if string.find(skillName,"Majestic Zircon") ~= nil and group == "EpicGems" then
    return true
  end
  if string.find(skillName,"Dreadstone") ~= nil and group == "EpicGems" then
    return true
  end

  -- Rare Gems
  if string.find(skillName,"Scarlet Ruby") ~= nil and group == "RareGems" then
    return true
  end
  if string.find(skillName,"Monarch Topaz") ~= nil and group == "RareGems" then
    return true
  end
  if string.find(skillName,"Autumn's Glow") ~= nil and group == "RareGems" then
    return true
  end
  if string.find(skillName,"Forest Emerald") ~= nil and group == "RareGems" then
    return true
  end
  if string.find(skillName,"Sky Sapphire") ~= nil and group == "RareGems" then
    return true
  end
  if string.find(skillName,"Twilight Opal") ~= nil and group == "RareGems" then
    return true
  end

  -- Everything else
  if string.find(skillName:upper(),group:upper()) ~= nil then
    return true
  end

end

ucq_AUCTIONEER_DETECTED = nil

function KTQGetLowestPrice(itemLink)
  if itemLink then
    if KTQuseAucAdvanced == true and AucAdvanced and AucAdvanced.Version then
      local imgSeen, image, matchBid, matchBuy, lowBid, lowBuy, aveBuy, aSeen 
          = AucAdvanced.Modules.Util.SimpleAuction.Private.GetItems(itemLink)

      ucq_LogBlue(itemLink
          .. " matchBid:" .. (matchBid or "")
          .. " matchBuy:" .. (matchBuy or "")
          .. " lowBid:" .. lowBid
	  .. " lowBuy:" .. lowBuy)
      local KTQFallback = 0
      if KTQuseFallback == true then
          KTQFallback = 9999999  
      end
      if imgSeen > 0 then
        if lowBuy ~= nil then
          return lowBuy
        else
          return KTQFallback
        end
      else
        return KTQFallback
      end
    else if not ucq_AUCTIONEER_DETECTED then
      ucq_LogRed("Auctioneer not detected, disabling threshold")
      ucq_AUCTIONEER_DETECTED = true
    end
  end  -- if itemLink
end -- function
end

-- All Currency processing and formatting Stolen form QuickAuction
-- Stolen from Tekkub!
local GOLD_TEXT = "|cffffd700g|r"
local SILVER_TEXT = "|cffc7c7cfs|r"
local COPPER_TEXT = "|cffeda55fc|r"
local COPPER_PER_SILVER = 100
local COPPER_PER_GOLD = 10000

-- Truncate tries to save space, after 10g stop showing copper, after 100g stop showing silver
function KTQFormatCopperToText(money, truncate)
  if money == nil then
    money = 0
  end
  
  local gold = math.floor(money / COPPER_PER_GOLD)
  local silver = math.floor((money - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER)
  local copper = math.floor(math.fmod(money, COPPER_PER_SILVER))
  local text = ""
  
  -- Add gold
  if( gold > 0 ) then
    text = string.format("%d%s ", gold, GOLD_TEXT)
  end
  
  -- Add silver
  if( silver > 0 and ( not truncate or gold < 100 ) ) then
    text = string.format("%s%d%s ", text, silver, SILVER_TEXT)
  end
  
  -- Add copper if we have no silver/gold found, or if we actually have copper
  if( text == "" or ( copper > 0 and ( not truncate or gold <= 10 ) ) ) then
    text = string.format("%s%d%s ", text, copper, COPPER_TEXT)
  end
  
  return string.trim(text)
end

function KTQConvertTextToCopper(text)

  text = string.lower(text)
  local gold = tonumber(string.match(text, "([0-9]+)g"))
  local silver = tonumber(string.match(text, "([0-9]+)s"))
  local copper = tonumber(string.match(text, "([0-9]+)c"))
  
  if( not gold and not silver and not copper ) then
    log("Invalid money format: #g#s#c")
    return nil
  end
  
  -- Convert it all into copper
  copper = (copper or 0) + ((gold or 0) * COPPER_PER_GOLD) + ((silver or 0) * COPPER_PER_SILVER) or 0
  
  return copper
end

function ucq_GetSkipSingles()
  return UltimateCraftQueueDB.skipSingles
end

function ucq_GetThreshold()
  return UltimateCraftQueueDB.threshold
end

function ucq_GetStackSize()
  return UltimateCraftQueueDB.stackSize
end

function ucq_GetBonusQueue()
  return UltimateCraftQueueDB.bonusQueue
end

function ucq_GetClassOfGlyphByName(itemName)
  ScanningTooltip:ClearLines();

  local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount,
    itemEquipLoc, itemTexture, itemSellPrice
        = GetItemInfo(itemName);

  return ucq_GetClassOfGlyphByLink(itemLink)
end

function ucq_GetClassOfGlyphByLink(itemLink)
  local result
  ScanningTooltip:SetHyperlink(itemLink);

  local line3 = getglobal("ScanningTooltipTextLeft3")

  cls = getglobal("ScanningTooltipTextLeft3"):GetText()
  if (cls ~= nil) then
    ucq_LogBlue("[TooltipScan] Scanning tooltip for " .. itemLink
        .. " line3:@" .. line3:GetText() .. "@")
    result = strmatch(cls, "Classes: ([%w%s]+)");
  end

  if (result ~= nil) then
    ucq_LogBlue("[TooltipScan] Returning class:" .. result)
  else
    ucq_LogBlue("[TooltipScan] Couldn't find a class for " .. itemLink)
  end
  return result;
end

--
-- Create an edit box to change the stack size for a class
--
function ucq_CreateClassStackSize(cls)
  local stackSizes = UltimateCraftQueueDB.stackSizes
  local result = AceGUI:Create("EditBox")
  result:SetLabel(cls)
  result:SetWidth(100)
  if stackSizes[cls] ~= nil then
    result:SetText(stackSizes[cls])
  else
    result:SetText("")
  end
  result:SetCallback("OnEnterPressed",
    function(widget, event, text)
      if text ~= nil then
        n = tonumber(text)
	if (n ~= nil) then
	  stackSizes[cls] = n
          log("New stack size for " .. cls .. ":" .. stackSizes[cls])
	end
      else
        stackSizes[cls] = nil
      end
    end
  )

  return result
end

--
-- Receives a table of class names, create a Flow container
-- to contain them all and create an EditBox for each of them
--
function ucq_CreateClassPanel(parent, classes)
  container = AceGUI:Create("SimpleGroup")
  container:SetLayout("Flow")
  container:SetFullWidth(true)
  for k, v in ipairs(classes) do
    container:AddChild(ucq_CreateClassStackSize(v))
  end
  parent:AddChild(container)
end

--
-- Initialize the db (only useful for first runs)
--
function ucq_InitializeDB()
  if UltimateCraftQueue == nil then
    UltimateCraftQueue = {
      ["stackSize"] = 4,
      ["stackSizes"] = {},
      ["skipSingles"] = true,
      ["bonusQueue"] = false,
      ["threshold"] = 0
    }
  end
end

--
-- Create a check box tied to a DB key
--
function ucq_CreateCheckBox(label, key)
  local result = AceGUI:Create("CheckBox")
  result:SetLabel(label)
  result:SetValue(UltimateCraftQueueDB[key])
  result:SetCallback("OnValueChanged",
    function(widget, event, value)
      log(label .. " is now " .. tostring(value))
      UltimateCraftQueueDB[key] = value
    end)

  return result
end

-- Callback function for OnGroupSelected
function SelectGroup(container, event, group)
  container:ReleaseChildren()
  if group == "tab1" then
    DrawGroup1(container)
  elseif group == "tab2" then
    DrawGroup2(container)
  end
end

function DrawGroup1(frame)
  --
  -- Main stack size
  --
  frame:SetLayout("Flow")
  local line1 = AceGUI:Create("SimpleGroup")
  line1:SetLayout("Flow")
  frame:AddChild(line1)

  local stackSize  
  local stackSizeEditBox = AceGUI:Create("EditBox")
  stackSizeEditBox:SetLabel("Stack size")
  ss = UltimateCraftQueueDB.stackSize
  if ss ~= nil then
    stackSizeEditBox:SetText(ss)
  end
  stackSizeEditBox:SetCallback("OnEnterPressed",
    function(widget, event, text)
      log("stack size:" .. text)
      UltimateCraftQueueDB.stackSize = tonumber(text)
    end)
  line1:AddChild(stackSizeEditBox)

  --
  -- Threshold
  --
  local thresholdEditBox = AceGUI:Create("EditBox")
  thresholdEditBox:SetLabel("Threshold (e.g 12g34s56c)")
  thresholdEditBox:SetText(
      KTQFormatCopperToText(UltimateCraftQueueDB.threshold))
  thresholdEditBox:SetCallback("OnEnterPressed",
    function(widget, event, text)
      log("Trying to convert '" .. text .. "'")
      copper = KTQConvertTextToCopper(text)
      if (copper ~= nil) then
        log("New copper value: " .. copper)
        UltimateCraftQueueDB.threshold = copper
      else
        log("Couldn't convert '" .. text .. "'")
      end
    end)
  thresholdEditBox:SetFullWidth(true)
  line1:AddChild(thresholdEditBox)

  --
  -- Skip singles
  --
  local skipSingles = ucq_CreateCheckBox("Skip singles", "skipSingles")
  line1:AddChild(skipSingles)
  KTQskipSingles = true

  --
  -- Bonus queue
  --
  local bonusQueueCb = ucq_CreateCheckBox("Bonus queue", "bonusQueue")
  bonusQueueCb:SetFullWidth(true)
  line1:AddChild(bonusQueueCb)
  KTQuseBonusQueue = false

  --
  -- Class stack size overrides
  --
  local classes = {
    { "Death Knight", "Druid", "Hunter", "Mage" },
    { "Paladin", "Priest", "Rogue", "Shaman" },
    { "Warlock", "Warrior" }
  }

  local container = AceGUI:Create("InlineGroup")
  container:SetTitle("Stack size class overrides")
  container:SetFullWidth(true)
  container:SetLayout("List")
  frame:AddChild(container)

  for k, v in ipairs(classes) do
    ucq_CreateClassPanel(container, v)
  end

  --
  -- "Create queue" button
  --
  local button = AceGUI:Create("Button")
  button:SetText("Create Queue")
  button:SetCallback("OnClick",
    function()
      stackSize = UltimateCraftQueueDB.stackSize
      ucq_ResetLog()
      ucq_ResetVariables()
      KTQQueueItem(stackSize, "Glyphs");
    end)
  frame:AddChild(button)
end

local ucq_LOG_LINES = {}

function ucq_ResetLog()
  ucq_LOG_LINES = {}
end

function log(s)
  print("Log:" .. s)
  tinsert(ucq_LOG_LINES, s)
end

function ucq_LogBlue(s)
  log("|cffafeeee" .. s)
end

function ucq_LogRed(s)
  log("|cffff0000" .. s)
end

function ucq_LogGreen(s)
  log("|cff00ff00" .. s)
end

function DrawGroup2(frame)
  frame:SetLayout("Fill")
  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetPoint("TOPLEFT", 20, -100)
  scroll:SetLayout("List")
  scroll:SetWidth(300)
  scroll:SetHeight(300)
  
  frame:AddChild(scroll)

  print("LOG LINES: " .. #ucq_LOG_LINES)
  for k, v in ipairs(ucq_LOG_LINES) do
    local l1 = AceGUI:Create("Label")
    l1:SetFullWidth(true)
    l1:SetText(v)
    scroll:AddChild(l1)
  end

end

ucq_GLYPHS = {
  ["Druid"] = {
    [40896] = true, [40897] = true, [40899] = true, [40900] = true, [40901] = true,
    [40902] = true, [40903] = true, [40906] = true, [40908] = true, [40909] = true,
    [40912] = true, [40913] = true, [40914] = true, [40915] = true, [40916] = true,
    [40919] = true, [40920] = true, [40921] = true, [40922] = true, [40923] = true,
    [40924] = true, [43316] = true, [43331] = true, [43332] = true, [43334] = true,
    [43335] = true, [43674] = true, [44922] = true, [44928] = true, [45601] = true,
    [45602] = true, [45603] = true, [45604] = true, [45622] = true, [45623] = true,
    [46372] = true, [48720] = true, [50125] = true,
  },
  ["Hunter"] = {
    [42897] = true, [42898] = true, [42899] = true, [42900] = true, [42901] = true,
    [42902] = true, [42903] = true, [42904] = true, [42905] = true, [42906] = true,
    [42907] = true, [42908] = true, [42909] = true, [42910] = true, [42911] = true,
    [42912] = true, [42913] = true, [42914] = true, [42915] = true, [42916] = true,
    [42917] = true, [43338] = true, [43350] = true, [43351] = true, [43354] = true,
    [43355] = true, [43356] = true, [45625] = true, [45731] = true, [45732] = true,
    [45733] = true, [45734] = true, [45735] = true,

  },
  ["Mage"] = {
    [42734] = true, [42735] = true, [42736] = true, [42737] = true, [42738] = true,
    [42739] = true, [42740] = true, [42741] = true, [42742] = true, [42743] = true,
    [42744] = true, [42745] = true, [42746] = true, [42747] = true, [42748] = true,
    [42749] = true, [42750] = true, [42751] = true, [42752] = true, [42753] = true,
    [42754] = true, [43339] = true, [43357] = true, [43359] = true, [43360] = true,
    [43361] = true, [43364] = true, [44684] = true, [44920] = true, [44955] = true,
    [45736] = true, [45737] = true, [45738] = true, [45739] = true, [45740] = true,
    [50045] = true,
  },
  ["Priest"] = {
    [42396] = true, [42397] = true, [42398] = true, [42399] = true, [42400] = true,
    [42401] = true, [42402] = true, [42403] = true, [42404] = true, [42405] = true,
    [42406] = true, [42407] = true, [42408] = true, [42409] = true, [42410] = true,
    [42411] = true, [42412] = true, [42414] = true, [42415] = true, [42416] = true,
    [42417] = true, [43342] = true, [43370] = true, [43371] = true, [43372] = true,
    [43373] = true, [43374] = true, [45753] = true, [45755] = true, [45756] = true,
    [45757] = true, [45758] = true, [45760] = true,
  },
  ["Rogue"] = {
    [42954] = true, [42955] = true, [42956] = true, [42957] = true, [42958] = true,
    [42959] = true, [42960] = true, [42961] = true, [42962] = true, [42963] = true,
    [42964] = true, [42965] = true, [42966] = true, [42967] = true, [42968] = true,
    [42969] = true, [42970] = true, [42971] = true, [42972] = true, [42973] = true,
    [42974] = true, [43343] = true, [43376] = true, [43377] = true, [43378] = true,
    [43379] = true, [43380] = true, [45761] = true, [45762] = true, [45764] = true,
    [45766] = true, [45767] = true, [45768] = true, [45769] = true,
  },
  ["Shaman"] = {
    [41517] = true, [41518] = true, [41524] = true, [41526] = true, [41527] = true,
    [41529] = true, [41530] = true, [41531] = true, [41532] = true, [41533] = true,
    [41534] = true, [41535] = true, [41536] = true, [41537] = true, [41538] = true,
    [41539] = true, [41540] = true, [41541] = true, [41542] = true, [41547] = true,
    [41552] = true, [43344] = true, [43381] = true, [43385] = true, [43386] = true,
    [43388] = true, [43725] = true, [44923] = true, [45770] = true, [45771] = true,
    [45772] = true, [45775] = true, [45776] = true, [45777] = true, [45778] = true,
  },
  ["Warlock"] = {
    [42453] = true, [42454] = true, [42455] = true, [42456] = true, [42457] = true,
    [42458] = true, [42459] = true, [42460] = true, [42461] = true, [42462] = true,
    [42463] = true, [42464] = true, [42465] = true, [42466] = true, [42467] = true,
    [42468] = true, [42469] = true, [42470] = true, [42471] = true, [42472] = true,
    [42473] = true, [43389] = true, [43390] = true, [43391] = true, [43392] = true,
    [43393] = true, [43394] = true, [45779] = true, [45780] = true, [45781] = true,
    [45782] = true, [45783] = true, [45785] = true, [45789] = true, [50077] = true,
  },
  ["Warrior"] = {
    [43395] = true, [43396] = true, [43397] = true, [43398] = true, [43399] = true,
    [43400] = true, [43412] = true, [43413] = true, [43414] = true, [43415] = true,
    [43416] = true, [43417] = true, [43418] = true, [43419] = true, [43420] = true,
    [43421] = true, [43422] = true, [43423] = true, [43424] = true, [43425] = true,
    [43426] = true, [43427] = true, [43428] = true, [43429] = true, [43430] = true,
    [43431] = true, [43432] = true, [45790] = true, [45792] = true, [45793] = true,
    [45794] = true, [45795] = true, [45797] = true, [49084] = true,
  },
  ["Death Knight"] = {
    [43533] = true, [43534] = true, [43535] = true, [43536] = true, [43537] = true,
    [43538] = true, [43539] = true, [43541] = true, [43542] = true, [43543] = true,
    [43544] = true, [43545] = true, [43546] = true, [43547] = true, [43548] = true,
    [43549] = true, [43550] = true, [43551] = true, [43552] = true, [43553] = true,
    [43554] = true, [43671] = true, [43672] = true, [43673] = true, [43825] = true,
    [43826] = true, [43827] = true, [45799] = true, [45800] = true, [45803] = true,
    [45804] = true, [45805] = true, [45806] = true,
  },
  ["Paladin"] = {
    [43368] = true, [43367] = true, [41099] = true, [41094] = true, [45741] = true,
    [41109] = true, [41103] = true, [41104] = true, [41105] = true, [43365] = true,
    [43366] = true, [43340] = true, [43868] = true, [41097] = true, [41098] = true,
    [45744] = true, [41100] = true, [45742] = true, [43869] = true, [41107] = true,
    [41096] = true, [41101] = true, [45746] = true, [45743] = true, [45747] = true,
    [41092] = true, [41095] = true, [41108] = true, [45745] = true, [43369] = true,
    [41106] = true, [43867] = true, [41102] = true, [41110] = true,
  }
}

function ucq_GetClass(id)
  for k, v in pairs(ucq_GLYPHS) do
    if v[id] ~= nil then
      return k
    end
  end
  return nil
end

--
-- main
--
function ucq_ShowUi()
--  GlyphClasses:ppp("CALLING GLYPH_CLASSES")
  ucq_InitializeDB()
  KTQuseQuickAuction = true

  local frame = AceGUI:Create("Frame")
  frame:SetWidth(550)
  frame:SetHeight(600)
  frame:SetPoint("TOPLEFT", 20, -100)
  frame:SetTitle("Ultimate Craft Queue")
  frame:SetStatusText("Nothing to report")
  frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
  frame:SetLayout("Fill")

  local tab =  AceGUI:Create("TabGroup")
  tab:SetLayout("Flow")
  tab:SetTabs({{text="Main", value="tab1"}, {text="Log", value="tab2"}})
  tab:SetCallback("OnGroupSelected", SelectGroup)
  tab:SelectTab("tab1")

  frame:AddChild(tab)

  log("Welcome to UltimateCraftQueue")
end

-- /run print(GetClassOfGlyph(41104));
-- /run print(GetClassOfGlyph(43538));