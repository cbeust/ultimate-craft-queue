--
-- Ultimate Craft Queue
-- Cedric Beust (cedric@beust.com)
--
-- Configure how many glyphs of each class you need and UCQ will
-- add them to the Advanced Trade Skill window.
--
-- Usage:  /ucq
--
-- The latest version of this code can be found at
-- http://github.com/cbeust/ultimate-craft-queue
--
-- Based on Kev's Tool Queue, by Kevin Marquette (www.ithinkincode.com/warcraft)
--

UltimateCraftQueue = LibStub("AceAddon-3.0"):NewAddon("UltimateCraftQueue", "AceConsole-3.0")

AceGUI = LibStub:GetLibrary("AceGUI-3.0")

function UltimateCraftQueue:OnInitialize()
  self:RegisterChatCommand("ucq", "ChatCommand")
  UltimateCraftQueue.message = "welcome"
end

function UltimateCraftQueue:OnEnable()
end

function UltimateCraftQueue:OnDisable()
end

function UltimateCraftQueue:ChatCommand(input)
  if not input or input:trim() == "" then
    ucq_ShowUi()
  else
    LibStub("AceConfigCmd-3.0").HandleCommand(UltimateCraftQueue, "ucq", "UltimateCraftQueue", input)
  end
end

function ucq_GetStackSizeForClass(cls, defaultStackSize)
  result = UltimateCraftQueueDB.stackSizes[cls]
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
      cls = UltimateCraftQueue:ucq_GetClass(itemId)
--      cls = ucq_GetClassOfGlyphByLink(itemLink);
      if (cls ~= nil) then
        realStackSize = ucq_GetStackSizeForClass(cls, stackSize)
        queue, added, bonusQueue = ucq_Process(i, realStackSize, group, itemLink, itemId)
        ucq_LogQueue(itemId, itemLink, queue, bonusQueue)
        totalQueue = totalQueue + queue;
        totalAdded = totalAdded + added;
--      else
--        ucq_LogBlue("No class found for " .. itemLink)
      end
    end -- if

  end -- for

  ucq_LogGreen("")
  ucq_LogGreen("============= Queue summary =============")
  ucq_LogGreen("")
  for k, v in pairs(UCQ_GLYPHS_QUEUED_BY_CLASSES) do
    ucq_LogGreen(k .. ":" .. v)
  end
  ucq_LogGreen("")
  ucq_LogGreen("Total number of glyphs queued: "..totalAdded )
  ucq_LogGreen("Total number of items queued: "..totalQueue)

end

function ucq_Process(i, stackSize, group, itemLink, itemId)
  local totalQueue = 0
  local totalAdded = 0
  local totalSkipped = 0
  local usedBonusQueue = 0
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
      if toQueue == stackSize then
        toQueue = toQueue + UltimateCraftQueueDB.bonusQueue
	usedBonusQueue = UltimateCraftQueueDB.bonusQueue
      end

      --
      -- Compare to the threshold
      local minBuyout = KTQGetLowestPrice(itemLink)
      
      if (minBuyout ~= nil and minBuyout < UltimateCraftQueueDB.threshold) then
        
        ucq_LogYellow("Skipping " .. itemLink
            .." (under threshold "..KTQFormatCopperToText(minBuyout,true) .. ")")
        toQueue = 0
      end
    
      if (not UltimateCraftQueueDB.skipSingles or toQueue > 1) and toQueue ~= 0 then
      -- This is where curse client crashes
        AddToQueue(skillId,i, toQueue)
        totalQueue = totalQueue + toQueue
        totalAdded = totalAdded  + 1
      else
        ucq_LogYellow("Skipping " .. itemLink .. " (skipSingles is on)")
        totalSkipped = totalSkipped  + 1
      end
    end

    return totalQueue, totalAdded, usedBonusQueue
  end
end

-- Map of <string class, int itemCount> to keep track of how many items
-- we created per class
UCQ_GLYPHS_QUEUED_BY_CLASSES = {}

function ucq_ResetVariables()
  local classes = {
    "Death Knight", "Druid", "Hunter", "Mage",
    "Paladin", "Priest", "Rogue", "Shaman",
    "Warlock", "Warrior"
  }
  for i, v in ipairs(classes) do
    UCQ_GLYPHS_QUEUED_BY_CLASSES[v] = 0
  end

end

--
-- Log that an item has just been queued
--
function ucq_LogQueue(itemId, itemLink, itemCount, bonusQueue)
  local h = UCQ_GLYPHS_QUEUED_BY_CLASSES
--  local cls = ucq_GetClassOfGlyphByLink(itemLink)
  local cls = UltimateCraftQueue:ucq_GetClass(itemId)
  if cls ~= nil and itemCount > 0 then
    count = h[cls]
    count = count + itemCount
    h[cls] = count
    bq = ""
    if (bonusQueue > 0) then bq = "*" end
    ucq_LogGreen("Queuing " .. itemCount .. bq .. " " .. itemLink .. " (" .. cls .. ")")
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

UCQ_AUCTIONEER_DETECTED = nil

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
    else if not UCQ_AUCTIONEER_DETECTED then
      ucq_LogRed("Auctioneer not detected, disabling threshold")
      UCQ_AUCTIONEER_DETECTED = true
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

--[[
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
--]]

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
      stackSizes[cls] = nil
      if text ~= nil and tonumber(text) ~= nil then
        stackSizes[cls] = tonumber(text)
        log("New stack size for " .. cls .. ":" .. stackSizes[cls])
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
--[
  if UltimateCraftQueue == nil then
    UltimateCraftQueue = {
      ["stackSize"] = 4,
      ["stackSizes"] = {},
      ["skipSingles"] = true,
      ["bonusQueue"] = 1,
      ["threshold"] = 0
    }
  end
--]
end

--
-- Create a CheckBox tied to a DB key
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

--
-- Create an EditBox tied to a DB keuy
--
function ucq_CreateEditBox(label, text, key, onEnter)
  local eb = AceGUI:Create("EditBox")
  eb:SetLabel(label)
  if text == nil then text = "" end
  eb:SetText(text)
  eb:SetCallback("OnEnterPressed", onEnter)
--  thresholdEditBox:SetFullWidth(true)
  return eb
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

--
-- "Main" tab
--
function DrawGroup1(frame)
  --
  -- Main stack size
  --
  frame:SetLayout("Flow")

  local stackSizeEditBox = ucq_CreateEditBox("Stack size",
      UltimateCraftQueueDB.stackSize,
      "stackSize",
      function(widget, event, text)
        log("stack size:" .. text)
        UltimateCraftQueueDB.stackSize = tonumber(text)
      end)
  frame:AddChild(stackSizeEditBox)

  --
  -- Threshold
  --
  local thresholdEditBox = ucq_CreateEditBox("Threshold (e.g 12g34s56c)",
      KTQFormatCopperToText(UltimateCraftQueueDB.threshold),
      "threshold",
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
--  thresholdEditBox:SetFullWidth(true)
  frame:AddChild(thresholdEditBox)

  --
  -- Bonus queue
  --
  local bq = ucq_CreateEditBox("Bonus queue", UltimateCraftQueueDB.bonusQueue, "bonusQueue", 
      function(widget, event, text)
        log("Bonus queue:" .. text)
        UltimateCraftQueueDB.bonusQueue = tonumber(text)
      end)
  frame:AddChild(bq)

  --
  -- Skip singles
  --
  local skipSingles = ucq_CreateCheckBox("Skip singles", "skipSingles")
  frame:AddChild(skipSingles)
  KTQskipSingles = true

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

local UCQ_LOG_LINES = {}

function ucq_ResetLog()
  UCQ_LOG_LINES = {}
end

function log(s)
  tinsert(UCQ_LOG_LINES, s)
end

function ucq_LogBlue(s)
  log("|cffafeeee" .. s)
end

function ucq_LogRed(s)
  log("|cffff0000" .. s)
end

function ucq_LogYellow(s)
  log("|cffffff00" .. s)
end

function ucq_LogGreen(s)
  log("|cff00ff00" .. s)
end

--
-- "Log" tab
--
function DrawGroup2(frame)
  frame:SetLayout("Fill")
  local scroll = AceGUI:Create("ScrollFrame")
  scroll:SetPoint("TOPLEFT", 20, -100)
  scroll:SetLayout("List")
  scroll:SetWidth(300)
  scroll:SetHeight(300)
  
  frame:AddChild(scroll)

  print("LOG LINES: " .. #UCQ_LOG_LINES)
  for k, v in ipairs(UCQ_LOG_LINES) do
    local l1 = AceGUI:Create("Label")
    l1:SetFullWidth(true)
    l1:SetText(v)
    scroll:AddChild(l1)
  end

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
  frame:SetHeight(500)
  frame:SetPoint("TOPLEFT", 20, -50)
  frame:SetTitle("Ultimate Craft Queue")
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