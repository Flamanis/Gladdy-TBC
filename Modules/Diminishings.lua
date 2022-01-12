local select = select
local pairs,ipairs,tbl_sort,tinsert,format,rand = pairs,ipairs,table.sort,tinsert,format,math.random

local GetSpellInfo = GetSpellInfo
local CreateFrame = CreateFrame
local GetTime = GetTime

local Gladdy = LibStub("Gladdy")
local DRData = LibStub("DRData-1.0-BCC")
local L = Gladdy.L
local function defaultCategories()
    local categories = {}
    local indexList = {}
    for k,v in pairs(DRData:GetSpells()) do
        tinsert(indexList, {spellID = k, category = v})
    end
    tbl_sort(indexList, function(a, b) return a.spellID < b.spellID end)
    for _,v in ipairs(indexList) do
        if not categories[v.category] then
            categories[v.category] = {
                enabled = true,
                forceIcon = false,
                icon = select(3, GetSpellInfo(v.spellID))
            }
        end
    end
    return categories
end
local Diminishings = Gladdy:NewModule("Diminishings", nil, {
    drFont = "DorisPP",
    drFontColor = { r = 1, g = 1, b = 0, a = 1 },
    drFontScale = 1,
    drGrowDirection = "RIGHT",
    drXOffset = 0,
    drYOffset = 0,
    drIconSize = 36,
    drEnabled = true,
    drBorderStyle = "Interface\\AddOns\\Gladdy\\Images\\Border_Gloss",
    drBorderColor = { r = 1, g = 1, b = 1, a = 1 },
    drDisableCircle = false,
    drCooldownAlpha = 1,
    drBorderColorsEnabled = true,
    drIconPadding = 1,
    drHalfColor = {r = 1, g = 1, b = 0, a = 1 },
    drQuarterColor = {r = 1, g = 0.7, b = 0, a = 1 },
    drNullColor = {r = 1, g = 0, b = 0, a = 1 },
    drLevelTextEnabled = true,
    drLevelTextFont = "DorisPP",
    drLevelTextFontScale = 0.8,
    drWidthFactor = 1,
    drCategories = defaultCategories(),
    drDuration = 18,
    drFrameStrata = "MEDIUM",
    drFrameLevel = 3,
})

local function getDiminishColor(dr)
    if dr == 0.5 then
        return Gladdy:SetColor(Gladdy.db.drHalfColor)
    elseif dr == 0.25 then
        return Gladdy:SetColor(Gladdy.db.drQuarterColor)
    else
        return Gladdy:SetColor(Gladdy.db.drNullColor)
    end
end

local function getDiminishText(dr)
    if dr == 0.5 then
        return "½"
    elseif dr == 0.25 then
        return "¼"
    else
        return "ø"
    end
end

function Diminishings:Initialize()
    self.frames = {}
    self:RegisterMessage("UNIT_DEATH", "ResetUnit", "AURA_FADE", "UNIT_DESTROYED")
end

function Diminishings:CreateFrame(unit)
    local drFrame = CreateFrame("Frame", nil, Gladdy.buttons[unit])
    drFrame:EnableMouse(false)
    drFrame:SetMovable(true)
    drFrame:SetFrameStrata(Gladdy.db.drFrameStrata)
    drFrame:SetFrameLevel(Gladdy.db.drFrameLevel)

    for i = 1, 16 do
        local icon = CreateFrame("Frame", "GladdyDr" .. unit .. "Icon" .. i, drFrame)
        icon:Hide()
        icon:EnableMouse(false)
        icon:SetFrameStrata(Gladdy.db.drFrameStrata)
        icon:SetFrameLevel(Gladdy.db.drFrameLevel)
        icon.texture = icon:CreateTexture(nil, "BACKGROUND")
        icon.texture:SetMask("Interface\\AddOns\\Gladdy\\Images\\mask")
        icon.texture:SetAllPoints(icon)
        icon:SetScript("OnUpdate", function(self, elapsed)
            if (self.active) then
                if (self.timeLeft <= 0) then
                    if (self.factor == drFrame.tracked[self.dr]) then
                        drFrame.tracked[self.dr] = 0
                    end

                    self.active = false
                    self.dr = nil
                    self.diminishing = 1.0
                    self.texture:SetTexture("")
                    self.text:SetText("")
                    self:Hide()
                    Diminishings:Positionate(unit)
                else
                    self.timeLeft = self.timeLeft - elapsed
                    Gladdy:FormatTimer(self.text, self.timeLeft, self.timeLeft < 5)
                end
            end
        end)

        icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
        icon.cooldown.noCooldownCount = true --Gladdy.db.trinketDisableOmniCC
        icon.cooldown:SetHideCountdownNumbers(true)
        icon.cooldown:SetFrameStrata(Gladdy.db.drFrameStrata)
        icon.cooldown:SetFrameLevel(Gladdy.db.drFrameLevel + 1)

        icon.cooldownFrame = CreateFrame("Frame", nil, icon)
        icon.cooldownFrame:ClearAllPoints()
        icon.cooldownFrame:SetPoint("TOPLEFT", icon, "TOPLEFT")
        icon.cooldownFrame:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT")
        icon.cooldownFrame:SetFrameStrata(Gladdy.db.drFrameStrata)
        icon.cooldownFrame:SetFrameLevel(Gladdy.db.drFrameLevel + 2)

        --icon.overlay = CreateFrame("Frame", nil, icon)
        --icon.overlay:SetAllPoints(icon)
        icon.border = icon.cooldownFrame:CreateTexture(nil, "OVERLAY")
        icon.border:SetTexture("Interface\\AddOns\\Gladdy\\Images\\Border_rounded_blp")
        icon.border:SetAllPoints(icon)

        icon.text = icon.cooldownFrame:CreateFontString(nil, "OVERLAY")
        icon.text:SetDrawLayer("OVERLAY")
        icon.text:SetFont(Gladdy:SMFetch("font", "drFont"), 10, "OUTLINE")
        icon.text:SetTextColor(Gladdy:SetColor(Gladdy.db.drFontColor))
        icon.text:SetShadowOffset(1, -1)
        icon.text:SetShadowColor(0, 0, 0, 1)
        icon.text:SetJustifyH("CENTER")
        icon.text:SetPoint("CENTER")

        icon.timeText = icon.cooldownFrame:CreateFontString(nil, "OVERLAY")
        icon.timeText:SetDrawLayer("OVERLAY")
        icon.timeText:SetFont(Gladdy:SMFetch("font", "drFont"), 10, "OUTLINE")
        icon.timeText:SetTextColor(Gladdy:SetColor(Gladdy.db.drFontColor))
        icon.timeText:SetShadowOffset(1, -1)
        icon.timeText:SetShadowColor(0, 0, 0, 1)
        icon.timeText:SetJustifyH("CENTER")
        icon.timeText:SetPoint("CENTER", icon, "CENTER", 0, 1)

        icon.drLevelText = icon.cooldownFrame:CreateFontString(nil, "OVERLAY")
        icon.drLevelText:SetDrawLayer("OVERLAY")
        icon.drLevelText:SetFont(Gladdy:SMFetch("font", "drLevelTextFont"), 10, "OUTLINE")
        icon.drLevelText:SetTextColor(getDiminishColor(1))
        icon.drLevelText:SetShadowOffset(1, -1)
        icon.drLevelText:SetShadowColor(0, 0, 0, 1)
        icon.drLevelText:SetJustifyH("CENTER")
        icon.drLevelText:SetPoint("BOTTOM", icon, "BOTTOM", 0, 0)

        icon.diminishing = 1

        drFrame["icon" .. i] = icon
    end

    drFrame.tracked = {}
    Gladdy.buttons[unit].drFrame = drFrame
    self.frames[unit] = drFrame
    self:ResetUnit(unit)
end

function Diminishings:UpdateFrame(unit)
    local drFrame = self.frames[unit]
    if (not drFrame) then
        return
    end

    if (Gladdy.db.drEnabled == false) then
        drFrame:Hide()
        return
    else
        drFrame:Show()
    end

    drFrame:SetWidth(Gladdy.db.drIconSize)
    drFrame:SetHeight(Gladdy.db.drIconSize)
    drFrame:SetFrameStrata(Gladdy.db.drFrameStrata)
    drFrame:SetFrameLevel(Gladdy.db.drFrameLevel)

    Gladdy:SetPosition(drFrame, unit, "drXOffset", "drYOffset", Diminishings:LegacySetPosition(drFrame, unit), Diminishings)

    if (unit == "arena1") then
        Gladdy:CreateMover(drFrame,"drXOffset", "drYOffset", L["Diminishings"],
                Gladdy.db.drGrowDirection == "RIGHT" and {"TOPLEFT", "TOPLEFT"} or {"TOPRIGHT", "TOPRIGHT"},
                Gladdy.db.drIconSize * Gladdy.db.drWidthFactor,
                Gladdy.db.drIconSize,
                0,
                0)
    end

    for i = 1, 16 do
        local icon = drFrame["icon" .. i]

        icon:SetWidth(Gladdy.db.drIconSize * Gladdy.db.drWidthFactor)
        icon:SetHeight(Gladdy.db.drIconSize)

        icon:SetFrameStrata(Gladdy.db.drFrameStrata)
        icon:SetFrameLevel(Gladdy.db.drFrameLevel)
        icon.cooldown:SetFrameStrata(Gladdy.db.drFrameStrata)
        icon.cooldown:SetFrameLevel(Gladdy.db.drFrameLevel + 1)
        icon.cooldownFrame:SetFrameStrata(Gladdy.db.drFrameStrata)
        icon.cooldownFrame:SetFrameLevel(Gladdy.db.drFrameLevel + 2)

        icon.text:SetFont(Gladdy:SMFetch("font", "drFont"), (Gladdy.db.drIconSize/2 - 1) * Gladdy.db.drFontScale, "OUTLINE")
        icon.text:SetTextColor(Gladdy:SetColor(Gladdy.db.drFontColor))
        icon.timeText:SetFont(Gladdy:SMFetch("font", "drFont"), (Gladdy.db.drIconSize/2 - 1) * Gladdy.db.drFontScale, "OUTLINE")
        icon.timeText:SetTextColor(Gladdy:SetColor(Gladdy.db.drFontColor))

        icon.drLevelText:SetFont(Gladdy:SMFetch("font", "drLevelTextFont"), (Gladdy.db.drIconSize/2 - 1) * Gladdy.db.drLevelTextFontScale, "OUTLINE")

        icon.cooldown:SetWidth(icon:GetWidth() - icon:GetWidth()/16)
        icon.cooldown:SetHeight(icon:GetHeight() - icon:GetHeight()/16)
        icon.cooldown:ClearAllPoints()
        icon.cooldown:SetPoint("CENTER", icon, "CENTER")
        if Gladdy.db.drDisableCircle then
            icon.cooldown:SetAlpha(0)
        else
            icon.cooldown:SetAlpha(Gladdy.db.drCooldownAlpha)
        end

        if Gladdy.db.drBorderColorsEnabled then
            icon.border:SetVertexColor(getDiminishColor(icon.diminishing))
        else
            icon.border:SetVertexColor(Gladdy:SetColor(Gladdy.db.drBorderColor))
        end

        if Gladdy.db.drLevelTextEnabled then
            icon.drLevelText:Show()
        else
            icon.drLevelText:Hide()
        end

        icon:ClearAllPoints()
        if (Gladdy.db.drGrowDirection == "LEFT") then
            if (i == 1) then
                icon:SetPoint("TOPRIGHT", drFrame, "TOPRIGHT")
            else
                icon:SetPoint("RIGHT", drFrame["icon" .. (i - 1)], "LEFT", -Gladdy.db.drIconPadding, 0)
            end
        else
            if (i == 1) then
                icon:SetPoint("TOPLEFT", drFrame, "TOPLEFT")
            else
                icon:SetPoint("LEFT", drFrame["icon" .. (i - 1)], "RIGHT", Gladdy.db.drIconPadding, 0)
            end
        end

        if Gladdy.db.drBorderStyle == "Interface\\AddOns\\Gladdy\\Images\\Border_Gloss" then
            icon.border:SetTexture("Interface\\AddOns\\Gladdy\\Images\\Border_rounded_blp")
        else
            icon.border:SetTexture(Gladdy.db.drBorderStyle)
        end

        --icon.texture:SetTexCoord(.1, .9, .1, .9)
        --icon.texture:SetPoint("TOPLEFT", icon, "TOPLEFT", 2, -2)
        --icon.texture:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", -2, 2)
    end
end

function Diminishings:ResetUnit(unit)
    local drFrame = self.frames[unit]
    if (not drFrame) then
        return
    end

    drFrame.tracked = {}

    for i = 1, 16 do
        local icon = drFrame["icon" .. i]
        icon.active = false
        icon.timeLeft = 0
        icon.texture:SetTexture("")
        icon.text:SetText("")
        icon.timeText:SetText("")
        icon:Hide()
    end
end

function Diminishings:UNIT_DESTROYED(unit)
    Diminishings:ResetUnit(unit)
end

function Diminishings:Test(unit)
    if Gladdy.db.drEnabled then
        local enabledCategories = {}
        for cat,val in pairs(Gladdy.db.drCategories) do
            if (val.enabled) then
                tinsert(enabledCategories, {cat = cat , spellIDs = {}})
                enabledCategories[cat] = #enabledCategories
            end
        end
        for spellId,cat in pairs(DRData:GetSpells()) do
            if enabledCategories[cat] then
                tinsert(enabledCategories[enabledCategories[cat]].spellIDs, spellId)
            end
        end

        --shuffle
        for i = #enabledCategories, 2, -1 do
            local j = rand(i)
            enabledCategories[i], enabledCategories[j] = enabledCategories[j], enabledCategories[i]
        end

        --execute test
        local index, amount = 0,0
        for i=1, (#enabledCategories < 4 and #enabledCategories) or 4 do
            amount = rand(1,3)
            index = rand(1, #enabledCategories[i].spellIDs)
            for _=1, amount do
                self:AuraFade(unit, enabledCategories[i].spellIDs[index])
            end
        end
    end
end

function Diminishings:AuraFade(unit, spellID)
    local drFrame = self.frames[unit]
    local drCat = DRData:GetSpellCategory(spellID)
    if (not drFrame or not drCat) then
        return
    end
    if not Gladdy.db.drCategories[drCat].enabled then
        return
    end

    local lastIcon
    for i = 1, 16 do
        local icon = drFrame["icon" .. i]
        if (icon.active and icon.dr and icon.dr == drCat) then
            lastIcon = icon
            break
        elseif not icon.active and not lastIcon then
            lastIcon = icon
            lastIcon.diminishing = 1.0
        end
    end
    if not lastIcon then return end
    lastIcon.dr = drCat
    lastIcon.timeLeft = Gladdy.db.drDuration
    lastIcon.diminishing = DRData:NextDR(lastIcon.diminishing)
    if Gladdy.db.drBorderColorsEnabled then
        lastIcon.border:SetVertexColor(getDiminishColor(lastIcon.diminishing))
    else
        lastIcon.border:SetVertexColor(Gladdy:SetColor(Gladdy.db.drBorderColor))
    end
    lastIcon.cooldown:SetCooldown(GetTime(), Gladdy.db.drDuration)
    if Gladdy.db.drCategories[drCat].forceIcon then
        lastIcon.texture:SetTexture(Gladdy.db.drCategories[drCat].icon)
    else
        lastIcon.texture:SetTexture(select(3, GetSpellInfo(spellID)))
    end
    lastIcon.active = true
    self:Positionate(unit)
    lastIcon:Show()
    lastIcon.drLevelText:SetText(getDiminishText(lastIcon.diminishing))
    lastIcon.drLevelText:SetTextColor(getDiminishColor(lastIcon.diminishing))
end

function Diminishings:Positionate(unit)
    local drFrame = self.frames[unit]
    if (not drFrame) then
        return
    end

    local lastIcon

    for i = 1, 16 do
        local icon = drFrame["icon" .. i]

        if (icon.active) then
            icon:ClearAllPoints()
            if (Gladdy.db.newLayout and Gladdy.db.drGrowDirection == "LEFT"
                    or not Gladdy.db.newLayout and Gladdy.db.drCooldownPos == "LEFT") then
                if (not lastIcon) then
                    icon:SetPoint("TOPRIGHT")
                else
                    icon:SetPoint("RIGHT", lastIcon, "LEFT", -Gladdy.db.drIconPadding, 0)
                end
            elseif (Gladdy.db.newLayout and Gladdy.db.drGrowDirection == "RIGHT"
                    or not Gladdy.db.newLayout and Gladdy.db.drCooldownPos == "RIGHT") then
                if (not lastIcon) then
                    icon:SetPoint("TOPLEFT")
                else
                    icon:SetPoint("LEFT", lastIcon, "RIGHT", Gladdy.db.drIconPadding, 0)
                end
            end

            lastIcon = icon
        end
    end
end

function Diminishings:GetOptions()
    return {
        headerDiminishings = {
            type = "header",
            name = L["Diminishings"],
            order = 2,
        },
        drEnabled = Gladdy:option({
            type = "toggle",
            name = L["Enabled"],
            desc = L["Enabled DR module"],
            order = 3,
        }),
        drDuration = Gladdy:option({
            type = "range",
            name = L["DR Duration"],
            desc = L["Change the DR Duration in seconds (DR is dynamic between 15-20s)"],
            order = 4,
            min = 15,
            max = 20,
            step = .1,
        }),
        group = {
            type = "group",
            childGroups = "tree",
            name = L["Frame"],
            order = 5,
            args = {
                icon = {
                    type = "group",
                    name = L["Icon"],
                    order = 1,
                    args = {
                        headerDiminishingsFrame = {
                            type = "header",
                            name = L["Icon"],
                            order = 4,
                        },
                        drIconSize = Gladdy:option({
                            type = "range",
                            name = L["Icon Size"],
                            desc = L["Size of the DR Icons"],
                            order = 5,
                            min = 5,
                            max = 80,
                            step = 1,
                            width = "full",
                        }),
                        drWidthFactor = Gladdy:option({
                            type = "range",
                            name = L["Icon Width Factor"],
                            desc = L["Stretches the icon"],
                            order = 6,
                            min = 0.5,
                            max = 2,
                            step = 0.05,
                            width = "full",
                        }),
                        drIconPadding = Gladdy:option({
                            type = "range",
                            name = L["Icon Padding"],
                            desc = L["Space between Icons"],
                            order = 7,
                            min = 0,
                            max = 10,
                            step = 0.1,
                            width = "full",
                        }),
                    },
                },
                cooldown = {
                    type = "group",
                    name = L["Cooldown"],
                    order = 2,
                    args = {
                        headerDiminishingsFrame = {
                            type = "header",
                            name = L["Cooldown"],
                            order = 4,
                        },
                        drDisableCircle = Gladdy:option({
                            type = "toggle",
                            name = L["No Cooldown Circle"],
                            order = 8,
                            width = "full",
                        }),
                        drCooldownAlpha = Gladdy:option({
                            type = "range",
                            name = L["Cooldown circle alpha"],
                            min = 0,
                            max = 1,
                            step = 0.1,
                            order = 9,
                            width = "full",
                        }),
                        drCooldownNumberAlpha = {
                            type = "range",
                            name = L["Cooldown number alpha"],
                            min = 0,
                            max = 1,
                            step = 0.1,
                            order = 10,
                            width = "full",
                            set = function(info, value)
                                Gladdy.db.drFontColor.a = value
                                Gladdy:UpdateFrame()
                            end,
                            get = function(info)
                                return Gladdy.db.drFontColor.a
                            end,
                        },
                    },
                },
                font = {
                    type = "group",
                    name = L["Font"],
                    order = 3,
                    args = {
                        headerFont = {
                            type = "header",
                            name = L["Font"],
                            order = 10,
                        },
                        drFont = Gladdy:option({
                            type = "select",
                            name = L["Font"],
                            desc = L["Font of the cooldown"],
                            order = 11,
                            dialogControl = "LSM30_Font",
                            values = AceGUIWidgetLSMlists.font,
                        }),
                        drFontColor = Gladdy:colorOption({
                            type = "color",
                            name = L["Font color"],
                            desc = L["Color of the text"],
                            order = 13,
                            hasAlpha = true,
                        }),
                        drFontScale = Gladdy:option({
                            type = "range",
                            name = L["Font scale"],
                            desc = L["Scale of the text"],
                            order = 12,
                            min = 0.1,
                            max = 2,
                            step = 0.1,
                            width = "full",
                        }),
                    }
                },
                position = {
                    type = "group",
                    name = L["Position"],
                    order = 6,
                    args = {
                        headerPosition = {
                            type = "header",
                            name = L["Position"],
                            order = 20,
                        },
                        drGrowDirection = Gladdy:option({
                            type = "select",
                            name = L["DR Grow Direction"],
                            desc = L["Grow Direction of the dr icons"],
                            order = 21,
                            values = {
                                ["LEFT"] = L["Left"],
                                ["RIGHT"] = L["Right"],
                            },
                        }),
                        drXOffset = Gladdy:option({
                            type = "range",
                            name = L["Horizontal offset"],
                            order = 23,
                            min = -400,
                            max = 400,
                            step = 0.1,
                            width = "full",
                        }),
                        drYOffset = Gladdy:option({
                            type = "range",
                            name = L["Vertical offset"],
                            order = 24,
                            min = -400,
                            max = 400,
                            step = 0.1,
                            width = "full",
                        }),
                    },
                },
                level = {
                    type = "group",
                    name = L["Level Text"],
                    order = 5,
                    args = {
                        headerBorder = {
                            type = "header",
                            name = L["DR Level"],
                            order = 1,
                        },
                        drLevelTextEnabled = Gladdy:option({
                            type = "toggle",
                            name = L["DR Level Text Enabled"],
                            desc = L["Shows the current DR Level on the DR icon."],
                            order = 2,
                            width = "full",
                        }),
                        drLevelTextFont = Gladdy:option({
                            type = "select",
                            name = L["Font"],
                            desc = L["Font of the cooldown"],
                            order = 3,
                            dialogControl = "LSM30_Font",
                            values = AceGUIWidgetLSMlists.font,
                        }),
                        drLevelTextFontScale = Gladdy:option({
                            type = "range",
                            name = L["Font scale"],
                            desc = L["Scale of the text"],
                            order = 4,
                            min = 0.1,
                            max = 2,
                            step = 0.1,
                            width = "full",
                        }),
                    },
                },
                border = {
                    type = "group",
                    name = L["Border"],
                    order = 4,
                    args = {
                        headerBorder = {
                            type = "header",
                            name = L["Border"],
                            order = 30,
                        },
                        drBorderStyle = Gladdy:option({
                            type = "select",
                            name = L["Border style"],
                            order = 31,
                            values = Gladdy:GetIconStyles()
                        }),
                        drBorderColor = Gladdy:colorOption({
                            type = "color",
                            name = L["Border color"],
                            desc = L["Color of the border"],
                            order = 32,
                            hasAlpha = true,
                        }),
                        headerBorderColors = {
                            type = "header",
                            name = L["DR Border Colors"],
                            order = 40,
                        },
                        drBorderColorsEnabled = Gladdy:option({
                            type = "toggle",
                            name = L["Dr Border Colors Enabled"],
                            desc = L["Colors borders of DRs in respective DR-color below"],
                            order = 41,
                            width = "full",
                        }),
                        drHalfColor = Gladdy:colorOption({
                            type = "color",
                            name = L["Half"],
                            desc = L["Color of the border"],
                            order = 42,
                            hasAlpha = true,
                        }),
                        drQuarterColor = Gladdy:colorOption({
                            type = "color",
                            name = L["Quarter"],
                            desc = L["Color of the border"],
                            order = 43,
                            hasAlpha = true,
                        }),
                        drNullColor = Gladdy:colorOption({
                            type = "color",
                            name = L["Immune"],
                            desc = L["Color of the border"],
                            order = 44,
                            hasAlpha = true,
                        }),
                    }
                },
                frameStrata = {
                    type = "group",
                    name = L["Frame Strata and Level"],
                    order = 7,
                    args = {
                        headerAuraLevel = {
                            type = "header",
                            name = L["Frame Strata and Level"],
                            order = 1,
                        },
                        drFrameStrata = Gladdy:option({
                            type = "select",
                            name = L["Frame Strata"],
                            order = 2,
                            values = Gladdy.frameStrata,
                            sorting = Gladdy.frameStrataSorting,
                            width = "full",
                        }),
                        drFrameLevel = Gladdy:option({
                            type = "range",
                            name = L["Frame Level"],
                            min = 0,
                            max = 500,
                            step = 1,
                            order = 3,
                            width = "full",
                        }),
                    },
                },
            },
        },
        categories = {
            type = "group",
            name = L["Categories"],
            order = 6,
            args = Diminishings:CategoryOptions(),
        },
    }
end

function Diminishings:CategoryOptions()
    local categories = {
        checkAll = {
            order = 1,
            width = "0.7",
            name = L["Check All"],
            type = "execute",
            func = function()
                for k,_ in pairs(defaultCategories()) do
                    Gladdy.db.drCategories[k].enabled = true
                end
            end,
        },
        uncheckAll = {
            order = 2,
            width = "0.7",
            name = L["Uncheck All"],
            type = "execute",
            func = function()
                for k,_ in pairs(defaultCategories()) do
                    Gladdy.db.drCategories[k].enabled = false
                end
            end,
        },
    }
    local indexList = {}
    for k,_ in pairs(DRData:GetCategories()) do
        tinsert(indexList, k)
    end
    tbl_sort(indexList)
    for i,k in ipairs(indexList) do
        categories[k] = {
            type = "group",
            name = L[DRData:GetCategoryName(k)],
            order = i,
            icon = Gladdy.db.drCategories[k].icon,
            args = {
                enabled = {
                    type = "toggle",
                    name = L["Enabled"],
                    order = 1,
                    get = function()
                        return Gladdy.db.drCategories[k].enabled
                    end,
                    set = function(_, value)
                        Gladdy.db.drCategories[k].enabled = value
                    end,
                },
                forceIcon = {
                    type = "toggle",
                    name = L["Force Icon"],
                    order = 2,
                    get = function()
                        return Gladdy.db.drCategories[k].forceIcon
                    end,
                    set = function(_, value)
                        Gladdy.db.drCategories[k].forceIcon = value
                    end,
                },
                icon = {
                    type = "select",
                    name = L["Icon"],
                    desc = L["Icon of the DR"],
                    order = 4,
                    values = Diminishings:GetDRIcons(k),
                    get = function()
                        return Gladdy.db.drCategories[k].icon
                    end,
                    set = function(_, value)
                        Gladdy.db.drCategories[k].icon = value
                        Gladdy.options.args.Diminishings.args.categories.args[k].icon = value
                    end,
                }
            }
        }
    end
    return categories
end

function Diminishings:GetDRIcons(category)
    local icons = {}
    for k,v in pairs(DRData:GetSpells()) do
        if v == category then
            icons[select(3, GetSpellInfo(k))] = format("|T%s:20|t %s", select(3, GetSpellInfo(k)), select(1, GetSpellInfo(k)))
        end
    end
    return icons
end

---------------------------

-- LAGACY HANDLER

---------------------------

function Diminishings:LegacySetPosition(drFrame, unit)
    if Gladdy.db.newLayout then
        return Gladdy.db.newLayout
    end
    drFrame:ClearAllPoints()
    local horizontalMargin = (Gladdy.db.highlightInset and 0 or Gladdy.db.highlightBorderSize) + Gladdy.db.padding
    if (Gladdy.db.drCooldownPos == "LEFT") then
        Gladdy.db.drGrowDirection = "LEFT"
        local anchor = Gladdy:GetAnchor(unit, "LEFT")
        if anchor == Gladdy.buttons[unit].healthBar then
            drFrame:SetPoint("RIGHT", anchor, "LEFT", -horizontalMargin + Gladdy.db.drXOffset, Gladdy.db.drYOffset)
        else
            drFrame:SetPoint("RIGHT", anchor, "LEFT", -Gladdy.db.padding + Gladdy.db.drXOffset, Gladdy.db.drYOffset)
        end
    end
    if (Gladdy.db.drCooldownPos == "RIGHT") then
        Gladdy.db.drGrowDirection = "RIGHT"
        local anchor = Gladdy:GetAnchor(unit, "RIGHT")
        if anchor == Gladdy.buttons[unit].healthBar then
            drFrame:SetPoint("LEFT", anchor, "RIGHT", horizontalMargin + Gladdy.db.drXOffset, Gladdy.db.drYOffset)
        else
            drFrame:SetPoint("LEFT", anchor, "RIGHT", Gladdy.db.padding + Gladdy.db.drXOffset, Gladdy.db.drYOffset)
        end
    end
    return Gladdy.db.newLayout
end