if EsoKR and EsoKR:isKorean() then -- 추가
	WritCreater = WritCreater or {}
	function WritCreater.initializeReticleChanges()
		if not WritCreater.langStationNames then return end
		local stations = WritCreater.langStationNames()
		local originalReticleFunction = ZO_ReticleContainerInteractContext.SetText
		local deliverText = WritCreater.writCompleteStrings()["Deliver"]

		local function isQuestComplete(questIndex, numConditions)
			local numConditions = GetJournalQuestNumConditions(questIndex)
			for i = 1, numConditions do

				local cur, max =  GetJournalQuestConditionValues(questIndex,1,i)

				local s = GetJournalQuestConditionInfo(questIndex,1,i)

				if string.find(s, deliverText) then  return true
				end
			end
			return false
		end

		local function setupReplacement(object, functionName)

			local original = object[functionName]
			object[functionName] = function(self, text)
			-- If the setting is off exit

			if not WritCreater:GetSettings().changeReticle then  original(self, text) return end
				text = EsoKR:removeIndex(text) -- 추가
			
				-- if not a station exit
				local craftingType = stations[text]
				if not craftingType then  original(self, text) return end

				-- Otherwise, do we have a writ on?
				local writs = WritCreater.writSearch()
				if writs[craftingType] then

					-- we have a writ. Do we need the reticle green or red
					if isQuestComplete(writs[craftingType]) or GetJournalQuestIsComplete(writs[craftingType]) then
						text = "|c66ff66"..text.."|r"
					else
						text = "|cff6666"..text.."|r"
					end

					original(self, text)
				else
					original(self, text)
				end
			end
		end

		setupReplacement(ZO_ReticleContainerInteractContext, "SetText")
	end
end --추가

local oldInteract = INTERACTIVE_WHEEL_MANAGER.StartInteraction


local function hook(...)
	if WritCreater:GetSettings().stealProtection then
		local _, hasWrits = WritCreater.writSearch()
		if not hasWrits then
			return oldInteract(...)
		end
		local action, _, isBlocked, isOwned, additional,_,_,isCriminal = GetGameCameraInteractableActionInfo()
		if isBlocked then
			return oldInteract(...)
		end
		if isCriminal then
			local isStealthed = GetUnitStealthState("player")
			if isStealthed == 3 or isStealthed == 5 then
				return oldInteract(...)
			else
				d("The Lazy Writ Crafter has saved you from stealing while doing writs!")
				return isCriminal
			end
		end
		return oldInteract(...)
	end
	return oldInteract(...)
end
INTERACTIVE_WHEEL_MANAGER.StartInteraction = hook


local jewelryName =zo_strformat("<<1>>",GetItemLinkName("|H1:item:138799:6:1:0:0:0:24:255:5:325:28:0:0:0:0:0:0:0:0:0:4320001|h|h"))
local function dialogHook(...)
	zo_callLater(function()
		if ZO_Dialog1 and ZO_Dialog1.textParams and ZO_Dialog1.textParams.mainTextParams then
			local itemName= ZO_Dialog1.textParams.mainTextParams[1]
			if  WritCreater:GetSettings().EZJewelryDestroy and string.find(itemName ,jewelryName )then
				for k, v in pairs(ZO_Dialog1.textParams.mainTextParams) do
					if v == string.upper(v) then
						ZO_Dialog1EditBox:SetText(v)
						ZO_Dialog1EditBox:LoseFocus()
					end
				end

			end
		end
	end, 10)
end

ZO_PreHook("ZO_Dialogs_ShowDialog", dialogHook)
