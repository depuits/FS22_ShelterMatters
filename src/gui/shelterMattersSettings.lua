ShelterMattersSettings = {}
ShelterMattersSettings.modDirectory = g_currentModDirectory

ShelterMattersSettings.CONTROLS = {
    "baleTypes",
    "numBales",
    "fillTypes",
    "baleSizes"
}

local ShelterMattersSettings_mt = Class(ShelterMattersSettings, ScreenElement)

function ShelterMattersSettings.register()
    local screen = ShelterMattersSettings.new()
    if g_gui ~= nil then
        -- load the xml layout and assign it to the controller
        local filename = Utils.getFilename("src/gui/shelterMattersSettings.xml", ShelterMattersSettings.modDirectory)
        g_gui: loadGui(filename, "ShelterMattersSettings", screen)
    end
    ShelterMattersSettings.INSTANCE = screen
end

function ShelterMattersSettings.show(callbackFunc, callbackTarget)
    if ShelterMattersSettings.INSTANCE ~= nil then
        print("show!")
        local screen = ShelterMattersSettings.INSTANCE
        screen:setCallback(callbackFunc, callbackTarget)
        g_gui:changeScreen(nil, ShelterMattersSettings)
    end
end

function ShelterMattersSettings.new(custom_mt)
    local self = ScreenElement.new(nil, custom_mt or ShelterMattersSettings_mt)
    self:registerControls(ShelterMattersSettings.CONTROLS)
    self.callbackFunc = nil
    self.callbackTarget = nil
    self.numBalesTexts = {}
    for i=1, 5 do
        table.insert(self.numBalesTexts, tostring(i))
    end

    return self
end

function ShelterMattersSettings.createFromExistingGui(gui, guiName)
    ShelterMattersSettings.register()
    local callbackFunc = gui.callbackFunc
    local callbackTarget = gui.callbackTarget
    ShelterMattersSettings.show(callbackFunc, callbackTarget)
end

function ShelterMattersSettings:setCallback(callbackFunc, callbackTarget)
    self.callbackFunc = callbackFunc
    self.callbackTarget = callbackTarget
end

function ShelterMattersSettings:onOpen()
    ShelterMattersSettings:superClass().onOpen(self)
        print("Open!")

    --self.numBales:setTexts(self.numBalesTexts)
    --[[local fillTypeTexts = {}
    self.textIndexToFillTypeIndex = {}
    self.fillTypeToBales = {}
    for k, baleType in ipairs(g_baleManager.bales) do
        baleType.baleTypeIndex = k
        for _, fillTypeData in ipairs(baleType.fillTypes) do
            local fillTypeIndex = fillTypeData.fillTypeIndex
            local added = table.addElement(self.textIndexToFillTypeIndex, fillTypeIndex)
            if added then
                local fillTypeTitle = g_fillTypeManager:getFillTypeTitleByIndex(fillTypeIndex)
                table.insert(fillTypeTexts, fillTypeTitle)
            end

            if self.fillTypeToBales[fillTypeIndex] == nil then
                self.fillTypeToBales[fillTypeIndex] = {}
            end

            table.insert(self.fillTypeToBales[fillTypeIndex], baleType)
        end
    end

    self.fillTypes:setTexts(fillTypeTexts)
    self.baleTypes:setTexts({ g_i18n:getText("fillType_roundBale"), g_i18n:getText("fillType_squareBale") })
    self:updateBaleTypes()]]
end

function ShelterMattersSettings:updateBaleTypes()
    local hasRoundBale = false
    local hasSquareBale = false
    local index = self.fillTypes:getState()
    local fillTypeIndex = self.textIndexToFillTypeIndex[index]
    local bales = self.fillTypeToBales[fillTypeIndex]
    for _, bale in ipairs(bales) do
        if bale.isRoundbale then
            hasRoundBale = true
        else
            hasSquareBale = true
        end
    end

    self.baleTypes:setState(hasRoundBale and 1 or 2)
    self.baleTypes:setDisabled(not hasRoundBale or not hasSquareBale)
    self:updateBaleSizes()
end

function ShelterMattersSettings:updateBaleSizes()
    local index = self.fillTypes:getState()
    local fillTypeIndex = self.textIndexToFillTypeIndex[index]
    local bales = self.fillTypeToBales[fillTypeIndex]
    local useRoundBale = self.baleTypes:getState() == 1
    local baleSizeTexts = {}
    self.baleSizeIndexToBale = {}

    for _, bale in ipairs(bales) do
        if useRoundBale == bale.isRoundbale then
            local size
            if bale.isRoundbale then
                size = string.format("%dx%d cm",
                bale.diameter*100, bale.width*100)
            else
                size = string.format("%dx%dx%d cm",
                bale.length*100, bale.width*100,
                bale.height*100)
            end

            table.insert(baleSizeTexts, size)
            table.insert(self.baleSizeIndexToBale, bale)
        end
    end
    self.baleSizes:setTexts(baleSizeTexts)
    self.baleSizes:setDisabled(#baleSizeTexts < 2)
end


function ShelterMattersSettings:onClickOk()
    g_gui:changeScreen(nil)
    local numBales = tonumber(self.numBales:getState())
    local fillTypeIndex = self.textIndexToFillTypeIndex[self.fillTypes:getState()]
    local bale = self.baleSizeIndexToBale[self.baleSizes:getState()]
    local baleTypeIndex = bale.baleTypeIndex

    if self.callbackFunc ~= nil then
        if self.callbackTarget ~= nil then
            self.callbackFunc(self.callbackTarget, baleTypeIndex, fillTypeIndex, numBales)
        else
            self.callbackFunc(baleTypeIndex, fillTypeIndex, numBales)
        end
    end
end

function ShelterMattersSettings:onClickBack()
    g_gui:changeScreen(nil)
end

function ShelterMattersSettings:onClickBaleType()
    self:updateBaleSizes()
end

function ShelterMattersSettings:onClickFillType()
    self:updateBaleTypes()
end



--[[function ShelterMattersSettings:onOpen()
    self.isOpen = true

    --TODO Load current settings
    self.palletSpawnProtection = g_gameSettings:getValue("palletSpawnProtection") or 0
    self.palletSpawnProtectionInput:setText(tostring(self.palletSpawnProtection))
end
]]
function ShelterMattersSettings:onSave()
    --TODO Apply new settings
    local inputText = self.palletSpawnProtectionInput:getText()
    local hours = tonumber(inputText)
    
    if hours and hours >= 0 then
        self.palletSpawnProtection = hours
        --TODO save setting g_gameSettings:setValue("palletSpawnProtection", self.palletSpawnProtection)
        print("Pallet Spawn Protection set to: " .. hours .. " hours")
    else
        print("Invalid pallet spawn protection value!")
    end
end

function ShelterMattersSettings:onClose()
    self.isOpen = false
    g_gui:closeGui(self.menuName)
end

function ShelterMattersSettings:onClick(element)
    print("click: " .. element.name)
--[[    if element.name == "saveButton" then
        self:onSave()
    elseif element.name == "closeButton" then
        self:onClose()
    elseif element.name == "openDecayPropertiesMenu" then
        g_gui:showGui("DecayPropertiesMenu") -- Open submenu for decay settings
    end]]
end

ShelterMattersSettings.register()
