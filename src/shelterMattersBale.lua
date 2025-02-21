
ShelterMattersBale = {
}

function ShelterMattersBale.registerFunctions()
    Bale.showInfo = Utils.appendedFunction(Bale.showInfo, ShelterMattersBale.showInfo)
    Bale.delete = Utils.appendedFunction(Bale.delete, ShelterMattersBale.delete)
end

function ShelterMattersBale.updateBaleDamage(bale, elapsedInGameHours, rate)
    if bale.wrappingState == 1 then
        return -- no damage is applied when the bale is wrapped
    end

    local inShed = ShelterMatters.isNodeInShed(bale.nodeId)
    if not inShed then
        -- save fillLevel when applying first damage
        if bale.fillLevelFull == nil then
            bale.fillLevelFull = bale.fillLevel
        end

        local outsideDamage = (rate * elapsedInGameHours)
        bale.fillLevel = bale.fillLevel - outsideDamage

        if bale.fillLevel > 0 then
            -- send new fill level to all clients
            g_server:broadcastEvent(shelterMattersBaleDamageEvent.new(bale))
        else
            bale:delete()
        end
    end
end

function ShelterMattersBale:showInfo(box)
    local decayPercentage = 0
    if self.fillLevelFull ~= nil then
        decayPercentage = 1 - (self.fillLevel / self.fillLevelFull)
    end

    box:addLine(g_i18n:getText("SM_InfoBaleDecay"), string.format("%d%%", decayPercentage * 100))
end

function ShelterMattersBale:delete()
    g_currentMission:addIngameNotification(FSBaseMission.INGAME_NOTIFICATION_CRITICAL, g_i18n:getText("SM_AlertBaleDeleted"))
end
