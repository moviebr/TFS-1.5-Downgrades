function Player:onLook(thing, position, distance)
	local onLook = EventCallback.onLook
	local description = ""
	if onLook then
		description = onLook(self, thing, position, distance, description)
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInBattleList(creature, distance)
	local onLookInBattleList = EventCallback.onLookInBattleList
	local description = ""
	if onLookInBattleList then
		description = onLookInBattleList(self, creature, distance, description)
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInTrade(partner, item, distance)
	local onLookInTrade = EventCallback.onLookInTrade
	local description = "You see " .. item:getDescription(distance)
	if onLookInTrade then
		description = onLookInTrade(self, partner, item, distance, description)
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onLookInShop(itemType, count, description)
	local onLookInShop = EventCallback.onLookInShop
	local description = "You see " .. description
	if onLookInShop then
		description = onLookInShop(self, itemType, count, description)
	end
	self:sendTextMessage(MESSAGE_INFO_DESCR, description)
end

function Player:onMoveItem(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	local onMoveItem = EventCallback.onMoveItem
	if onMoveItem then
		return onMoveItem(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	end
	return true
end

function Player:onItemMoved(item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	local onItemMoved = EventCallback.onItemMoved
	if onItemMoved then
		onItemMoved(self, item, count, fromPosition, toPosition, fromCylinder, toCylinder)
	end
end

function Player:onMoveCreature(creature, fromPosition, toPosition)
	local onMoveCreature = EventCallback.onMoveCreature
	if onMoveCreature then
		return onMoveCreature(self, creature, fromPosition, toPosition)
	end
	return true
end

function Player:onReportRuleViolation(targetName, reportType, reportReason, comment, translation)
	local onReportRuleViolation = EventCallback.onReportRuleViolation
	if onReportRuleViolation then
		onReportRuleViolation(self, targetName, reportType, reportReason, comment, translation)
	end
end

function Player:onReportBug(message, position, category)
	local onReportBug = EventCallback.onReportBug
	if onReportBug then
		return onReportBug(self, message, position, category)
	end
	return true
end

function Player:onTurn(direction)
	if EventCallback.onTurn then
		return EventCallback.onTurn(self, direction)
	end
	return true
end

function Player:onTradeRequest(target, item)
	local onTradeRequest = EventCallback.onTradeRequest
	if onTradeRequest then
		return onTradeRequest(self, target, item)
	end
	return true
end

function Player:onTradeAccept(target, item, targetItem)
	local onTradeAccept = EventCallback.onTradeAccept
	if onTradeAccept then
		return onTradeAccept(self, target, item, targetItem)
	end
	return true
end

function Player:onTradeCompleted(target, item, targetItem, isSuccess)
	local onTradeCompleted = EventCallback.onTradeCompleted
	if onTradeCompleted then
		onTradeCompleted(self, target, item, targetItem, isSuccess)
	end
end

local soulCondition = Condition(CONDITION_SOUL, CONDITIONID_DEFAULT)
soulCondition:setTicks(4 * 60 * 1000)
soulCondition:setParameter(CONDITION_PARAM_SOULGAIN, 1)

local function useStamina(player)
	local staminaMinutes = player:getStamina()
	if staminaMinutes == 0 then
		return
	end

	local playerId = player:getId()
	if not nextUseStaminaTime[playerId] then
		nextUseStaminaTime[playerId] = 0
	end

	local currentTime = os.time()
	local timePassed = currentTime - nextUseStaminaTime[playerId]
	if timePassed <= 0 then
		return
	end

	if timePassed > 60 then
		if staminaMinutes > 2 then
			staminaMinutes = staminaMinutes - 2
		else
			staminaMinutes = 0
		end
		nextUseStaminaTime[playerId] = currentTime + 120
	else
		staminaMinutes = staminaMinutes - 1
		nextUseStaminaTime[playerId] = currentTime + 60
	end
	player:setStamina(staminaMinutes)
end

function Player:onGainExperience(source, exp, rawExp)
	local onGainExperience = EventCallback.onGainExperience
	if not source or source:isPlayer() then
		return exp
	end

	-- Soul regeneration
	local vocation = self:getVocation()
	if self:getSoul() < vocation:getMaxSoul() and exp >= self:getLevel() then
		soulCondition:setParameter(CONDITION_PARAM_SOULTICKS, vocation:getSoulGainTicks() * 1000)
		self:addCondition(soulCondition)
	end

	-- Apply experience stage multiplier
	exp = exp * Game.getExperienceStage(self:getLevel())

	-- Stamina modifier
	if configManager.getBoolean(configKeys.STAMINA_SYSTEM) then
		useStamina(self)

		local staminaMinutes = self:getStamina()
		if staminaMinutes > 2400 and self:isPremium() then
			exp = exp * 1.5
		elseif staminaMinutes <= 840 then
			exp = exp * 0.5
		end
	end

	return onGainExperience and onGainExperience(self, source, exp, rawExp) or exp
end

function Player:onLoseExperience(exp)
	local onLoseExperience = EventCallback.onLoseExperience
	return onLoseExperience and onLoseExperience(self, exp) or exp
end

function Player:onGainSkillTries(skill, tries)
	local onGainSkillTries = EventCallback.onGainSkillTries
	if not APPLY_SKILL_MULTIPLIER then
		return onGainSkillTries and onGainSkillTries(self, skill, tries) or tries
	end

	if skill == SKILL_MAGLEVEL then
		tries = tries * configManager.getNumber(configKeys.RATE_MAGIC)
		return onGainSkillTries and onGainSkillTries(self, skill, tries) or tries
	end
	tries = tries * configManager.getNumber(configKeys.RATE_SKILL)
	return onGainSkillTries and onGainSkillTries(self, skill, tries) or tries
end

function Player:onInventoryUpdate(item, slot, equip)
	local onInventoryUpdate = EventCallback.onInventoryUpdate
	if onInventoryUpdate then
		onInventoryUpdate(self, item, slot, equip)
	end
end

function Player:onStepTile(fromPosition, toPosition)
	local onStepTile = EventCallback.onStepTile
    if onStepTile then
        return onStepTile(self, fromPosition, toPosition)
    end
    return true
end