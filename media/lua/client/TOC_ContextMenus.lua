
-- TODO rewrite this mess

function TocCutLocal(_, patient, surgeon, part_name)
    if GetSawInInventory(surgeon) ~= nil then
        ISTimedActionQueue.add(ISCutLimb:new(patient, surgeon, part_name));
    else
        surgeon:Say("I don't have a saw on me")
    end
end

function TocOperateLocal(_, patient, surgeon, part_name, use_oven)
    --local player = getPlayer();
    -- todo add a check if the player has already been amputated or somethin
    if use_oven then
        ISTimedActionQueue.add(ISOperateLimb:new(patient, surgeon, _, part_name, use_oven));
    else
        local kit = GetKitInInventory(surgeon)
        if kit ~= nil then
            ISTimedActionQueue.add(ISOperateLimb:new(patient, surgeon, kit, part_name, false))
        else
            surgeon:Say("I don't have a kit on me")
        end
    end
end


function TryToToResetEverythingOtherPlayer(_, patient, surgeon)
    sendClientCommand(surgeon, "TOC", "AskToResetEverything", {patient:getOnlineID()})
end


-- TODO Rename this

function TryTocAction(_, part_name, action, surgeon, patient)
    -- TODO add checks so that we don't show these menus if a player has already beeen operated or amputated
    -- TODO at this point surgeon doesnt do anything. We'll fix this later
    local ui = GetConfirmUIMP()
    if not ui then
        CreateTocConfirmUIMP()
        ui = GetConfirmUIMP()
    end

    if action == "Cut" then
        AskCanCutLimb(patient, part_name)
    elseif action == "Operate" then
        AskCanOperateLimb(patient, part_name)
    end
    ui.actionAct = action
    ui.partNameAct = part_name
    ui.patient = patient
    SendCommandToConfirmUIMP("Wait server")
end



-- function TryTocActionOnAnotherPlayer(_, part_name, action, surgeon, patient)


--     if action == "Cut" then
--         AskCanCutLimb(patient, part_name)

--     elseif action == "Operate" then
--         AskCanOperateLimb(patient, part_name)

--     end

-- end

local function CheckIfCanBeOperated(modData)
    if modData.TOC.RightHand.is_cut and not modData.TOC.RightHand.is_operated
    or modData.TOC.RightForearm.is_cut and not modData.TOC.RightForearm.is_operated
    or modData.TOC.RightArm.is_cut and not modData.TOC.RightArm.is_operated
    or modData.TOC.LeftHand.is_cut and not modData.TOC.LeftHand.is_operated
    or modData.TOC.LeftForearm.is_cut and not modData.TOC.LeftForearm.is_operated
    or modData.TOC.LeftArm.is_cut and not modData.TOC.LeftArm.is_operated then
        return true
    else
        return false
    end

end

local function CloseAllMenus(player_index)
    local contextMenu = getPlayerContextMenu(player_index)
    if contextMenu:isVisible() then

        contextMenu:closeAll()

    end
end

----------------------------------------------------------------------------------------------------------

TocContextMenus = {}


TocContextMenus.CreateMenus = function(player, context, worldObjects, test)
    local clicked_players_table = {}
    local clicked_player = nil

    local local_player = getSpecificPlayer(player)
    --local players = getOnlinePlayers()     

    for k,v in ipairs(worldObjects) do
        -- help detecting a player by checking nearby squares
        for x=v:getSquare():getX()-1,v:getSquare():getX()+1 do
            for y=v:getSquare():getY()-1,v:getSquare():getY()+1 do
                local sq = getCell():getGridSquare(x,y,v:getSquare():getZ())
                if sq then
                    for i=0,sq:getMovingObjects():size()-1 do
                        local o = sq:getMovingObjects():get(i)
                        if instanceof(o, "IsoPlayer") then
                            clicked_player = o

                            if clicked_players_table[clicked_player:getUsername()] == nil then

                                -- FIXME this is to prevent context menu spamming. Find a better way
                                clicked_players_table[clicked_player:getUsername()] = true
                                
                                local root_option = context:addOption("The Only Cure on " .. clicked_player:getUsername())
                                local root_menu = context:getNew(context)

                                local cut_menu = TocContextMenus.CreateNewMenu("Cut", context, root_menu)
                                local operate_menu = TocContextMenus.CreateNewMenu("Operate", context, root_menu)
                                local cheat_menu = TocContextMenus.CreateCheatMenu(context, root_menu, local_player, clicked_player)
                                context:addSubMenu(root_option, root_menu)

                                TocContextMenus.FillCutAndOperateMenus(local_player, clicked_player, worldObjects, cut_menu, operate_menu)
                                --TocContextMenus.FillCheatMenu(context, cheat_menu)

                                break
                            end

                        end
                    end
                end
            end
        end
    end
end


TocContextMenus.CreateOperateWithOvenMenu = function(player, context, worldObjects, test)
    local player_obj = getSpecificPlayer(player)
    --local clickedPlayer


    -- TODO Add a way to move the player towards the oven

    
    local toc_data = player_obj:getModData().TOC

    local is_main_menu_already_created = false


    --local props = v:getSprite() and v:getSprite():getProperties() or nil

    for k_stove, v_stove in pairs(worldObjects) do
        if instanceof(v_stove, "IsoStove") and (player_obj:HasTrait("Brave") or player_obj:getPerkLevel(Perks.Strength) >= 6) then

            -- Check temperature
            if v_stove:getCurrentTemperature() > 250 then
                
                for k_bodypart, v_bodypart in ipairs(GetBodyParts()) do
                    if toc_data[v_bodypart].is_cut and toc_data[v_bodypart].is_amputation_shown and not toc_data[v_bodypart].is_operated  then
                        local subMenu = context:getNew(context);

                        if is_main_menu_already_created == false then
                            local rootMenu = context:addOption(getText('UI_ContextMenu_OperateOven'), worldObjects, nil);
                            context:addSubMenu(rootMenu, subMenu)
                            is_main_menu_already_created = true
                        end
                        subMenu:addOption(getText('UI_ContextMenu_' .. v_bodypart), worldObjects, TocOperateLocal, getSpecificPlayer(player), getSpecificPlayer(player), v_bodypart, true)
                    end
                end
            end

            break   -- stop searching for stoves

        end

    end
end


TocContextMenus.DoCut = function(_, patient, surgeon, part_name)

    if GetSawInInventory(surgeon) then
        ISTimedActionQueue.add(ISCutLimb:new(patient, surgeon, part_name));
    else
        surgeon:Say("I don't have a saw on me")
    end
end



TocContextMenus.CreateNewMenu = function(name, context, root_menu)

    local new_option = root_menu:addOption(name)
    local new_menu = context:getNew(context)
    context:addSubMenu(new_option, new_menu)

    return new_menu
end



TocContextMenus.FillCutAndOperateMenus = function(local_player, clicked_player, world_objects, cut_menu, operate_menu)

    local local_toc_data = local_player:getModData().TOC

    for _, v in ipairs(GetBodyParts()) do


        if local_player == clicked_player then        -- Local player
            if TheOnlyCure.CheckIfCanBeCut(local_toc_data, v) then
                cut_menu:addOption(getText('UI_ContextMenu_' .. v), _, TryTocAction, v, "Cut", local_player, local_player)

                --cut_menu:addOption(getText('UI_ContextMenu_' .. v), _, TocCutLocal, local_player, local_player, v)
            elseif TheOnlyCure.CheckIfCanBeOperated(local_toc_data, v) then
                operate_menu:addOption(getText('UI_ContextMenu_' .. v), _, TryTocAction, v, "Operate", local_player, local_player)
            end
            
        else    -- Another player
            -- TODO add way to prevent cutting already cut parts
            cut_menu:addOption(getText('UI_ContextMenu_' .. v), world_objects, TryTocAction, v, "Cut", local_player, clicked_player)
            operate_menu:addOption(getText('UI_ContextMenu_' .. v), world_objects, TryTocAction, v, "Operate", local_player, clicked_player)

        end

    end

end




TocContextMenus.CreateCheatMenu = function(context, root_menu, local_player, clicked_player)
    if local_player:getAccessLevel() == "Admin" then

        local cheat_menu = TocContextMenus.CreateNewMenu("Cheat", context, root_menu)

        if clicked_player == local_player then
            cheat_menu:addOption("Reset TOC for me", _, ResetEverything)

        else
            cheat_menu:addOption("Reset TOC for " .. clicked_player:getUsername(), _, TryToToResetEverythingOtherPlayer, clicked_player, local_player)

        end

        return cheat_menu
    end
end


TocContextMenus.FillCheatMenus = function(context, cheat_menu)

    if cheat_menu then
        local cheat_cut_and_fix_menu = TocContextMenus.CreateNewMenu("Cut and Fix", context, cheat_menu)

    end
end


Events.OnFillWorldObjectContextMenu.Add(TocContextMenus.CreateOperateWithOvenMenu)       -- this is probably too much 
Events.OnFillWorldObjectContextMenu.Add(TocContextMenus.CreateMenus)