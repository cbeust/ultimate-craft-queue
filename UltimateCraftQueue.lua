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

function log(s)
  print(s)
end

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
  
  if not KTQskipSingles then
    KTQskipSingles = false
  end
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

function KTQSlashCommandHandler(msg)

  if msg ~= nil then
    local arg0,arg1,arg2  = strsplit(" ",msg)
    if arg0 == "DISABLE" then
      if arg1 == "BONUSQUEUE" then        
          KTQuseBonusQueue = false
          print("KevTool Queue: BonusQueue Disabled");  
      elseif arg1 == "SKIPSINGLES" then        
          KTQskipSingles = false
          print("KevTool Queue: SkipSingles Disabled");        
      elseif arg1 == "THRESHOLD" then        
          KTQuseThreshold = false
          print("KevTool Queue: Threshold Disabled");          
      elseif arg1 == "FALLBACK" then        
          KTQuseFallback = false
          print("KevTool Queue: Fallback Disabled");      
      else
        KTQShowHelp()
      end
    elseif arg0 == "UI" then
      ucq_ShowUi()
    elseif arg0 == "ENABLE" then
      if arg1 == "BONUSQUEUE" then
        KTQuseBonusQueue = true    
        print("KevTool Queue: BonusQueue Enabled");        
      elseif arg1 == "SKIPSINGLES" then
        KTQskipSingles = true    
        print("KevTool Queue: SkipSingles Enabled");
      elseif arg1 == "THRESHOLD" then    
        KTQuseThreshold = true    
        print("KevTool Queue: Threshold Enabled");      
      elseif arg1 == "FALLBACK" then        
        KTQuseFallback = true    
        print("KevTool Queue: Fallback Enabled");      
      else
        KTQShowHelp()
      end  
    elseif arg0 == "SHOW" then
      if KTQuseBonusQueue then
        print("KevTool Queue: BonusQueue "..KTQBonusQueue);
      else    
        print("KevTool Queue: BonusQueue is Disabled");
      end  
      if KTQskipSingles then
        print("KevTool Queue: Skipping Singles is Enabled");
      else    
        print("KevTool Queue: Skipping Singles is Disabled");
      end  
      if KTQuseThreshold then
        print("KevTool Queue: Threshold "..KTQFormatCopperToText(KTQThreshold, false));
      else    
        print("KevTool Queue: Threshold is Disabled");
      end  
      if KTQuseFallback then
        print("KevTool Queue: Fallback is Enabled");
      else    
        print("KevTool Queue: Fallback is Disabled");
      end
      if OverridesDB ~= nil then
        print("UCQ Overrides: " .. OverridesDB["PALADIN"] .. " " .. OverridesDB["DEATH KNIGHT"])
      else
        print("No overrides")
      end
    elseif arg0 == "SET" then
      if arg2 ~= nil then
        local value = tonumber(arg2)
        if arg1 ~= nil then
          if arg1 == "BONUSQUEUE" then
            KTQBonusQueue = value
            print("KevTool Queue: BonusQueue "..KTQBonusQueue);
          elseif arg1 == "THRESHOLD" then
            value = KTQConvertTextToCopper(arg2)
            if value ~= nil then
              KTQThreshold = value
              print("KevTool Queue: Threshold "..KTQFormatCopperToText(KTQThreshold,false));
            end
	  elseif arg1 == "OVERRIDES" then
	    ucq_HandleOverrides(msg);
          end
        end
      
      else
        KTQShowHelp()
      end
    elseif arg0 == "QUEUE" then
      KTQQueue(msg)      
    else
    KTQShowHelp()
    end
  else
    KTQShowHelp()
  end
end

function ucq_HandleOverrides(msg)
 print("Overrides:@" .. msg .. "@")
  local tbl = {}
  i = 0
  for v in string.gmatch(msg, "[^ ]+") do
    if i >= 2 then
      print("inserting " .. v)
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
    print("OVERRIDE " .. cls .. ":" .. value)
    OverridesDB[cls] = value
  end

end

function KTQQueue(msg)
  local queueString0,queueString1,queueString2,queueString3,queueString4,queueString5,queueString6  = strsplit(" ",msg)
  if queueString0 == "QUEUE" then
    if queueString1 ~= nil then
      stackSize = tonumber(queueString1)
      if queueString2 ~= nil then
        if queueString2 == "GLYPHS" then
          KTQQueueItem(stackSize, "Glyphs")
        elseif queueString2 == "EPICGEMS" then
          KTQQueueItem(stackSize, "EpicGems")
        elseif queueString2 == "RAREGEMS" then
          KTQQueueItem(stackSize, "RareGems")
        else
          if queueString6 ~= nil then
            KTQQueueItem(stackSize, strtrim(queueString2.." "..queueString3.." "..queueString4.." "..queueString5.." "..queueString6))
          elseif queueString5 ~= nil then
            KTQQueueItem(stackSize, strtrim(queueString2.." "..queueString3.." "..queueString4.." "..queueString5))
          elseif queueString4 ~= nil then
            KTQQueueItem(stackSize, strtrim(queueString2.." "..queueString3.." "..queueString4))
          elseif queueString3 ~= nil then
            KTQQueueItem(stackSize, strtrim(queueString2.." "..queueString3))
          else
            KTQQueueItem(stackSize, strtrim(queueString2))
          end
          
        end          
      end
      
    end
  end
end 
 
function KTQShowHelp()
  print("UltimateCraftQueueHelp [/ucq|/ultimatecraftqueue]")
  print("Features")
  print("  Bonus Queue lets you add extras when you sell out")
  print("  Skip Singles lets you not queue it if there is only one needed")
  print("  Threshold checks Auctioneer for listed value and lets you skip low selling items")
  print("  Fallback determins how to handle it when the AH is empty in regards to threshold")
  print("Command List")
  print("  QUEUE [number] [Keyword|Glyphs|EpicGems|RareGems]")
  print("          number is the amount you want to queue up")
  print("          keyword is search word that will queue matches")
  print("  ENABLE [BonusQueue|SkipSingles|Threshold|Fallback]")
  print("  DISABLE [BonusQueue|SkipSingles|Threshold|Fallback]")
  print("  SHOW [BonusQueue|SkipSingles|Threshold|Fallback]")
  print("  SET [BonusQueue|Threshold] [number]")
  print("          number is the value you want to set")
  print("Example")
  print("  /ucq set threshold 5g83s12c")
  print("  /ucq queue 5 Glyphs")
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
      cls = ucq_GetClassOfGlyphByLink(itemLink);
      if (cls ~= nil) then
        realStackSize = ucq_GetStackSize(cls, stackSize)
        local itemId = Skillet:GetItemIDFromLink(itemLink)
        queue, added = ucq_Process(i, realStackSize, group, itemLink, itemId)
        totalQueue = totalQueue + queue;
        totalAdded = totalAdded + added;
      end
    end -- if

  end -- for

  DEFAULT_CHAT_FRAME:AddMessage("Total Added: "..totalQueue)
  DEFAULT_CHAT_FRAME:AddMessage("Items Added: "..totalAdded )

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
    
    if KTQuseThreshold == true then
      local minBuyout = KTQGetLowestPrice(itemLink)      
      
      if minBuyout < KTQThreshold then
        
        DEFAULT_CHAT_FRAME:AddMessage("-"..toQueue.." "..itemLink.." under threshold "..KTQFormatCopperToText(minBuyout,true))
        toQueue = 0
      end
    end
    
    if (KTQskipSingles == false or toQueue > 1) and toQueue ~= 0 then
    -- This is where curse client crashes
      AddToQueue(skillId,i, toQueue)
      
      
--      DEFAULT_CHAT_FRAME:AddMessage("+"..toQueue.." "..itemLink)
      totalQueue = totalQueue + toQueue
      totalAdded = totalAdded  + 1
    else
      totalSkipped = totalSkipped  + 1
    end
    else
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

function AddToQueue(skillId,skillIndex, toQueue)
      if Skillet == nil then
        print("Skillet not loaded")
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

function KTQGetLowestPrice(itemLink)
  if itemLink then
    if KTQuseAucAdvanced == true and AucAdvanced and AucAdvanced.Version then
      local imgSeen, image, matchBid, matchBuy, lowBid, lowBuy, aveBuy, aSeen = AucAdvanced.Modules.Util.SimpleAuction.Private.GetItems(itemLink)
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
    end
  end  
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
    print("Invalid money format: #g#s#c")
    return nil
  end
  
  -- Convert it all into copper
  copper = (copper or 0) + ((gold or 0) * COPPER_PER_GOLD) + ((silver or 0) * COPPER_PER_SILVER) or 0
  
  return copper
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
--    print("Cls is not nil: " .. cls);
    result = strmatch(cls, "Classes: ([%w%s]+)");
  end

--  if (result ~= nil) then print("Returning class:@" .. result .. "@") end
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
          print("New stack size for " .. cls .. ":" .. stackSizes[cls])
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
  for k, v in ipairs(classes) do
    print("Adding " .. v .. " to flow simple group")
    container:AddChild(ucq_CreateClassStackSize(v))
  end
  print("adding simple group to parent")
  parent:AddChild(container)
end

function ucq_ShowUi()
  local frame = AceGUI:Create("Frame")
  frame:SetTitle("Ultimate Craft Queue")
  frame:SetStatusText("Nothing to report")
  frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
  frame:SetLayout("List")

  --
  -- Main stack size
  --
  local stackSize  
  local stackSizeEditBox = AceGUI:Create("EditBox")
  stackSizeEditBox:SetLabel("Stack size:")
  stackSizeEditBox:SetWidth(100)
  ss = UltimateCraftQueueDB.stackSize
  if ss ~= nil then
    stackSizeEditBox:SetText(ss)
  end
  stackSizeEditBox:SetCallback("OnEnterPressed",
    function(widget, event, text)
      UltimateCraftQueueDB.stackSize = tonumber(text)
    end)
  frame:AddChild(stackSizeEditBox)

  --
  -- Skip singles
  --
  KTQskipSingles = true
  if UltimateCraftQueueDB.skipSingles ~= nil then
    KTQskipSingles = true
  else
    KTQskipSingles = false
  end

  --
  -- Class stack size overrides
  --
  local classes = {
    { "Death Knight", "Druid", "Hunter" },
    { "Mage", "Paladin", "Priest"},
    { "Rogue", "Shaman", "Warlock"},
    { "Warrior" }
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
      print("stack size:" .. stackSize)
      KTQQueueItem(stackSize, "Glyphs");
    end)
  frame:AddChild(button)
end



-- /run print(GetClassOfGlyph(41104));
-- /run print(GetClassOfGlyph(43538))
;