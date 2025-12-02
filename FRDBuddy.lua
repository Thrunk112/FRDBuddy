local isLocked = true
local isEnabled = false 
local isFRDEquipped = false
local hasRepairedThisVisit = false
local FRD_ID = 18168 
local updateTick = 0

FRD = FRD or { position = { x = 0, y = 0 } }

local FRDframe = CreateFrame('FRAME', nil, UIParent)
FRDframe:SetWidth(24)
FRDframe:SetHeight(24)
FRDframe:ClearAllPoints()
FRDframe:SetPoint("CENTER", UIParent, "CENTER", FRD.position.x or 0, FRD.position.y or 0)
FRDframe:Hide()

FRDframe.texture = FRDframe:CreateTexture(nil, "ARTWORK")
FRDframe.texture:SetTexture("Interface\\Icons\\Spell_Arcane_PortalDarnassus")
FRDframe.texture:SetAllPoints()

FRDframe.title = FRDframe:CreateFontString(nil, "OVERLAY")
FRDframe.title:SetFont("Fonts\\ARIALN.TTF", 14, "OUTLINE")
FRDframe.title:SetTextColor(1,1,1,1)
FRDframe.title:SetPoint("CENTER", FRDframe.texture, "CENTER", 0, 0)
FRDframe.title:SetText("0")

local function EnableDrag()
    FRDframe:SetMovable(true)
    FRDframe:EnableMouse(true)
    FRDframe:RegisterForDrag("LeftButton")
    FRDframe:SetScript("OnDragStart", function(self) this:StartMoving() end)
    FRDframe:SetScript("OnDragStop", function(self)
        this:StopMovingOrSizing()
        local x, y = this:GetCenter()
        local ux, uy = UIParent:GetCenter()
        FRD.position.x = math.floor(x - ux)
        FRD.position.y = math.floor(y - uy)
    end)
end

local function DisableDrag()
    FRDframe:SetMovable(false)
    FRDframe:EnableMouse(false)
    FRDframe:SetScript("OnDragStart", nil)
    FRDframe:SetScript("OnDragStop", nil)
end

local function ToggleLock()
    if isLocked then
        EnableDrag()
        FRDframe:Show()
        isLocked = false
        DEFAULT_CHAT_FRAME:AddMessage("FRD Unlocked. Drag to reposition.")
    else
        DisableDrag()
        isLocked = true
        DEFAULT_CHAT_FRAME:AddMessage("FRD Locked.")
        if not isEnabled then FRDframe:Hide() end
    end
end


local scanTooltip = CreateFrame("GameTooltip", "FRDScanTooltip", nil, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

local function GetShieldDurability()
    scanTooltip:ClearLines()
    scanTooltip:SetInventoryItem("player", 17) 
    for i = 2, scanTooltip:NumLines() do
        local text = getglobal("FRDScanTooltipTextLeft"..i):GetText()
        if text then
            local _, _, cur, max = string.find(text, "(%d+)%s*/%s*(%d+)")
            if cur and max then
                return tonumber(cur), tonumber(max)
            end
        end
    end
    return nil, nil
end


local function CheckFRDEquipped()
    local link = GetInventoryItemLink("player", 17) 
    if link then
        local _, _, id = string.find(link, "item:(%d+)")
        isFRDEquipped = id and tonumber(id) == FRD_ID or false
    else
        isFRDEquipped = false
    end
end


local function Update()
    if not isEnabled then return end

    updateTick = updateTick + arg1
    if updateTick < 1 then return end
    updateTick = 0
	
	if not isFRDEquipped then
        FRDframe.title:SetText("NA")
        FRDframe.texture:SetVertexColor(1,0,0)
        FRDframe:Show()
        return
    end

    local cur, max = GetShieldDurability()
    if not cur or not max then
        FRDframe.title:SetText("NA")
        FRDframe.texture:SetVertexColor(1,0,0)
        if not isLocked then FRDframe:Show() end
        return
    end

    local pct = math.floor((cur / max) * 100)
    FRDframe.title:SetText(pct)

    if pct > 60 then
        FRDframe.texture:SetVertexColor(1,1,1)
    elseif pct > 30 then
        FRDframe.texture:SetVertexColor(1,1,0)
    else
        FRDframe.texture:SetVertexColor(1,0,0)
    end
	
	if CanMerchantRepair() then
        local rcost = GetRepairAllCost()
        if rcost and rcost > 0 then
            if not hasRepairedThisVisit or pct < 25 then
                RepairAllItems()
                DEFAULT_CHAT_FRAME:AddMessage("FRD: Items repaired")
                hasRepairedThisVisit = true
            end
        end
    end

    FRDframe:ClearAllPoints()
    FRDframe:SetPoint("CENTER", UIParent, "CENTER", FRD.position.x or 0, FRD.position.y or 0)
    FRDframe:Show()
end


local FR = CreateFrame("Frame")
FR:RegisterEvent("PLAYER_ENTERING_WORLD")
FR:RegisterEvent("UNIT_INVENTORY_CHANGED")
FR:RegisterEvent("MERCHANT_SHOW")
FR:RegisterEvent("MERCHANT_CLOSED")
FR:SetScript("OnEvent", function()
	if event == "PLAYER_ENTERING_WORLD" then
    FRDframe:Hide()
	CheckFRDEquipped()
	elseif event == "MERCHANT_SHOW" then
		hasRepairedThisVisit = false
	elseif event == "MERCHANT_CLOSED" then
		hasRepairedThisVisit = false
	elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
		CheckFRDEquipped()
		
	end
end)

-- Slash command
SLASH_FRD1 = "/frd"
SlashCmdList["FRD"] = function(msg)
    msg = string.lower(msg or "")
    if msg == "lock" then
        ToggleLock()
    else
        if not isEnabled then
            isEnabled = true
            FRDframe:ClearAllPoints()
            FRDframe:SetPoint("CENTER", UIParent, "CENTER", FRD.position.x or 0, FRD.position.y or 0)
            FRDframe:Show()
            FR:SetScript("OnUpdate", Update)
            DEFAULT_CHAT_FRAME:AddMessage("FRD Enabled.")
		else
            isEnabled = false
            FRDframe:Hide()
            FR:SetScript("OnUpdate", nil)
            DEFAULT_CHAT_FRAME:AddMessage("FRD Disabled.")
        end
    end
end
