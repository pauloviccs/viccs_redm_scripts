-- ==========================================================
-- viccs_camera | Server-Side
-- Registro do item usável + comando /camera + sincronização
-- ==========================================================

local VorpCore <const> = exports.vorp_core:GetCore()

-- ============================================================
-- Registrar item usável no inventário (com Wait de segurança)
-- ============================================================
CreateThread(function()
    Wait(2000) -- Aguarda 2 segundos para o vorp_inventory iniciar completamente
    exports.vorp_inventory:registerUsableItem(Config.ItemName, function(data)
        local _source = data.source

        -- Notifica o jogador e fecha o inventário
        VorpCore.NotifyTip(_source, Config.Locale.NotifyUseItem, 4000)
        exports.vorp_inventory:closeInventory(_source)

        -- Dispara o evento no client para iniciar o placement
        TriggerClientEvent("viccs_camera:client:startPlacement", _source)
    end)
end)

-- ============================================================
-- Evento: Remover câmera do inventário (ao posicionar)
-- ============================================================
RegisterNetEvent("viccs_camera:server:removeCameraItem", function()
    local _source = source
    local hasItem = exports.vorp_inventory:getItemCount(_source, nil, Config.ItemName)

    if hasItem and hasItem > 0 then
        exports.vorp_inventory:subItem(_source, Config.ItemName, 1)
    end
end)

-- ============================================================
-- Evento: Adicionar câmera ao inventário (ao recolher)
-- ============================================================
RegisterNetEvent("viccs_camera:server:addCameraItem", function()
    local _source = source
    exports.vorp_inventory:addItem(_source, Config.ItemName, 1)
end)

-- ============================================================
-- Comando /camera
-- ============================================================
RegisterCommand(Config.CommandName, function(source, args, rawCommand)
    local _source = source

    if Config.CommandRequireItem then
        -- Verifica se o jogador tem o item no inventário
        local itemCount = exports.vorp_inventory:getItemCount(_source, nil, Config.ItemName)
        if not itemCount or itemCount <= 0 then
            VorpCore.NotifyTip(_source, Config.Locale.NotifyNoItem, 4000)
            return
        end
    end

    TriggerClientEvent("viccs_camera:client:startPlacement", _source)
end, false) -- false = todos podem usar
