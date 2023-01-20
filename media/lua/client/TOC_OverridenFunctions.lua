require "TimedActions/ISBaseTimedAction"
require "TimedActions/ISEquipWeaponAction"
require "TimedActions/ISUnequipAction"
require "ISUI/ISInventoryPaneContextMenu"

local og_ISEquipTimedActionAdjustMaxTime = ISBaseTimedAction.adjustMaxTime


function ISBaseTimedAction:adjustMaxTime(maxTime)

    -- TODO Make the malus for time a little less awful and add some other malus, like fitness and stuff

    print("TOC: Input max time " .. tostring(maxTime))
    local original_max_time = og_ISEquipTimedActionAdjustMaxTime(self, maxTime)      
    
    print("TOC: Return original max time: " .. tostring(original_max_time))

    if original_max_time ~= -1 then
        

    local modified_max_time = original_max_time

    local part_data = getPlayer():getModData().TOC.Limbs
    local burn_factor = 1.3



    -- if it's -1, it should be instant.


    -- To make it faster, let's have everything already written in another func
    local all_body_parts = GetBodyParts()


    -- TODO this gets awfully slow really quick, doesn't even make much sense. 
    for _, part_name in ipairs(all_body_parts) do

        if part_data[part_name].is_cut then
            
            if part_data[part_name].is_prosthesis_equipped then
                modified_max_time = modified_max_time *  part_data[part_name].equipped_prosthesis.prosthesis_factor


            else
                modified_max_time = modified_max_time * 2           -- TODO make this lower
            end
            if part_data[part_name].is_cauterized then
                modified_max_time = modified_max_time * burn_factor
            end


            -- Perk scaling
            if part_name == "Right_Hand" or part_name == "Left_Hand" then
                modified_max_time = modified_max_time * (1 + (9 - self.character:getPerkLevel(Perks[part_name])) / 20 )
            end

        end
    end

    if modified_max_time > 10 * original_max_time then modified_max_time = 10 * original_max_time end


    print("TOC: Modified Max Time " .. modified_max_time)

    return modified_max_time
    else
        return original_max_time
    end


end




-------------------------------------------------
-- Block access to drag, picking, inspecting, etc to amputated limbs
local og_ISInventoryPaneOnMouseDoubleClick = ISInventoryPane.onMouseDoubleClick
function ISInventoryPane:onMouseDoubleClick(x, y)

    local item_to_check = self.items[self.mouseOverOption]
    local player_inventory = getPlayerInventory(self.player).inventory
    if instanceof(item_to_check, "InventoryItem") then
        og_ISInventoryPaneOnMouseDoubleClick(self, x,y)
    elseif CheckIfItemIsAmputatedLimb(item_to_check.items[1]) or CheckIfItemIsProsthesis(item_to_check.items[1])  then
        print("TOC: Can't double click this item")
    else
        og_ISInventoryPaneOnMouseDoubleClick(self, x,y)

    end



end


local og_ISInventoryPaneGetActualItems = ISInventoryPane.getActualItems
function ISInventoryPane.getActualItems(items)

    -- TODO add an exception for installed prosthesis, make them unequippable automatically from here and get the correct obj
    
    local ret = og_ISInventoryPaneGetActualItems(items)

    -- This is gonna be slower than just overriding the function but hey it's more compatible

    for i=1, #ret do
        local item_full_type = ret[i]:getFullType()
        if string.find(item_full_type, "Amputation_") or string.find(item_full_type, "Prost_") then
            table.remove(ret, i)
        end
    end
    return ret
end


local og_ISInventoryPaneContextMenuOnInspectClothing  = ISInventoryPaneContextMenu.onInspectClothing 
ISInventoryPaneContextMenu.onInspectClothing = function(playerObj, clothing)

    -- Inspect menu bypasses getActualItems, so we need to add that workaround here too
    local clothing_full_type = clothing:getFullType()
    if not string.find(clothing_full_type, "Amputation_") then
        
        og_ISInventoryPaneContextMenuOnInspectClothing(playerObj, clothing)
    end
    
end


local og_ISEquipWeaponActionPerform = ISEquipWeaponAction.perform
function ISEquipWeaponAction:perform()

    -- TODO in the inventory menu there is something broken, even though this works
    og_ISEquipWeaponActionPerform(self)
    local part_data = self.character:getModData().TOC.Limbs
    local can_be_held = {}

    for _, side in ipairs ({"Left", "Right"}) do
        can_be_held[side] = true

        if part_data[side .. "_Hand"].is_cut then
            if part_data[side .. "_LowerArm"].is_cut then
                if not part_data[side .. "_LowerArm"].is_prosthesis_equipped then
                    can_be_held[side] = false
                end
            elseif not part_data[side .. "_Hand"].is_prosthesis_equipped then
                can_be_held[side] = false
            end
        end
    end

    if not self.item:isRequiresEquippedBothHands() then
        if can_be_held["Right"] and not can_be_held["Left"] then
            self.character:setPrimaryHandItem(self.item)
            self.character:setSecondaryHandItem(nil)
        elseif not can_be_held["Right"] and can_be_held["Left"] then
            self.character:setPrimaryHandItem(nil)
            self.character:setSecondaryHandItem(self.item)
        elseif not can_be_held["Left"] and not can_be_held["Right"] then
            self.character:dropHandItems()
        end
    else
        if (can_be_held["Right"] and not can_be_held["Left"]) or
                (not can_be_held["Right"] and can_be_held["Left"]) or
                (not can_be_held["Left"] and not can_be_held["Right"]) then
            self.character:dropHandItems()

        end
    end



end


local og_ISInventoryPaneContextMenuUnequipItem = ISInventoryPaneContextMenu.unequipItem
function ISInventoryPaneContextMenu.unequipItem(item, player)

    if item == nil then
        return
    end
    if CheckIfItemIsAmputatedLimb(item) == false and CheckIfItemIsInstalledProsthesis(item) == false then
        og_ISInventoryPaneContextMenuUnequipItem(item, player)
    end
end

local og_ISInventoryPaneContextMenuDropItem = ISInventoryPaneContextMenu.dropItem
function ISInventoryPaneContextMenu.dropItem(item, player)

    if CheckIfItemIsAmputatedLimb(item) == false and CheckIfItemIsInstalledProsthesis(item) == false then
        og_ISInventoryPaneContextMenuDropItem(item, player)
    end

end

