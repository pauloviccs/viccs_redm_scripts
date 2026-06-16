-- ==========================================================
-- viccs_camera | Client — Main Controller
-- Orquestra: placement → prop fixo → proximidade → foto
-- Suporta /foto para entrar no modo câmera à distância
-- ==========================================================

local cameraEntity = nil
local cameraCoords = nil
local cameraHeading = 0.0
local isPhotoModeActive = false
local promptGroup = nil
local promptActivate = nil
local promptPickup = nil

-- Referência global para photomode.lua poder esconder/mostrar o prop
CameraEntityRef = nil

-- ============================================================
-- Evento: Servidor pede para iniciar placement
-- ============================================================
RegisterNetEvent("viccs_camera:client:startPlacement", function()
    if cameraEntity and DoesEntityExist(cameraEntity) then
        TriggerEvent('chat:addMessage', {
            color = { 255, 200, 100 },
            args = { "Câmera", "Você já tem uma câmera posicionada. Recolha-a primeiro (ou use /foto)." }
        })
        return
    end

    PlacementSystem:Start()
end)

-- ============================================================
-- Evento: Placement confirmado — criar prop real
-- ============================================================
RegisterNetEvent("viccs_camera:client:placementConfirmed", function(pos, heading)
    local modelHash = GetHashKey(Config.PropModel)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(100)
    end

    -- Cria o prop real (sólido, sincronizado na rede)
    cameraEntity = CreateObject(modelHash, pos.x, pos.y, pos.z, true, true, false, false, false)
    SetEntityHeading(cameraEntity, heading)
    FreezeEntityPosition(cameraEntity, true)
    SetEntityInvincible(cameraEntity, true)
    SetModelAsNoLongerNeeded(modelHash)

    if Config.PropPlaceOnGround then
        PlaceObjectOnGroundProperly(cameraEntity, true)
    end

    cameraCoords = GetEntityCoords(cameraEntity)
    cameraHeading = heading

    -- Expor referência global para photomode.lua
    CameraEntityRef = cameraEntity

    -- Remove o item do inventário (câmera está no chão agora)
    TriggerServerEvent("viccs_camera:server:removeCameraItem")

    TriggerEvent('chat:addMessage', {
        color = { 255, 200, 100 },
        args = { "Câmera", Config.Locale.NotifyCameraPlaced }
    })

    -- O jogador NÃO é congelado — pode andar livremente
    -- Iniciar loop de proximidade
    CreateThread(function()
        ProximityLoop()
    end)
end)

-- ============================================================
-- Loop de proximidade
-- O jogador pode andar livre e voltar à câmera quando quiser
-- ============================================================
function ProximityLoop()
    SetupPrompts()

    while cameraEntity and DoesEntityExist(cameraEntity) do
        Wait(0)

        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped)
        local dist = #(pedCoords - cameraCoords)

        -- Mostrar prompts apenas quando perto E não no modo foto
        if dist < Config.InteractDistance and not isPhotoModeActive then
            PromptSetActiveGroupThisFrame(promptGroup, CreateVarString(10, "LITERAL_STRING", "Câmera"))

            -- ENTER = Ativar Câmera
            if PromptHasStandardModeCompleted(promptActivate, 0) then
                ActivatePhotoMode()
            end

            -- X = Recolher Câmera
            if PromptHasStandardModeCompleted(promptPickup, 0) then
                PickupCamera()
                return
            end
        end

        -- Resetar flag quando sai do modo foto
        if isPhotoModeActive and not PhotoMode.active then
            isPhotoModeActive = false
            -- Restaurar visibilidade do prop ao sair do modo foto
            if cameraEntity and DoesEntityExist(cameraEntity) then
                SetEntityVisible(cameraEntity, true)
                SetEntityCollision(cameraEntity, true, true)
            end
        end
    end

    CleanupPrompts()
end

-- ============================================================
-- Ativar modo foto (pode ser chamado por prompt ou /foto)
-- ============================================================
function ActivatePhotoMode()
    if isPhotoModeActive then return end
    if not cameraEntity or not DoesEntityExist(cameraEntity) then
        TriggerEvent('chat:addMessage', {
            color = { 255, 100, 100 },
            args = { "Câmera", Config.Locale.NotifyNoCamera }
        })
        return
    end

    isPhotoModeActive = true

    -- Esconder o prop da câmera durante o modo foto
    -- (o jogador não deve ver o tripé na cena)
    if cameraEntity and DoesEntityExist(cameraEntity) then
        SetEntityVisible(cameraEntity, false)
        SetEntityCollision(cameraEntity, false, false)
    end

    PhotoMode:Start(cameraCoords, cameraHeading)
end

-- ============================================================
-- Comando /foto — entrar no modo câmera à distância
-- (não precisa estar perto, basta ter uma câmera posicionada)
-- ============================================================
RegisterCommand(Config.FotoCommandName, function()
    if isPhotoModeActive then
        -- Se já está no modo foto, sai
        PhotoMode:Stop()
        isPhotoModeActive = false
        return
    end

    if not cameraEntity or not DoesEntityExist(cameraEntity) then
        TriggerEvent('chat:addMessage', {
            color = { 255, 100, 100 },
            args = { "Câmera", Config.Locale.NotifyNoCamera }
        })
        return
    end

    ActivatePhotoMode()
end, false)

-- ============================================================
-- Recolher a câmera
-- ============================================================
function PickupCamera()
    if PhotoMode.active then
        PhotoMode:Stop()
    end
    isPhotoModeActive = false

    if cameraEntity and DoesEntityExist(cameraEntity) then
        -- Garantir que o prop está visível antes de deletar
        SetEntityVisible(cameraEntity, true)
        DeleteEntity(cameraEntity)
    end
    cameraEntity = nil
    CameraEntityRef = nil
    cameraCoords = nil
    cameraHeading = 0.0

    CleanupPrompts()

    -- Devolve o item da câmera para o inventário
    TriggerServerEvent("viccs_camera:server:addCameraItem")

    TriggerEvent('chat:addMessage', {
        color = { 255, 200, 100 },
        args = { "Câmera", Config.Locale.NotifyPickedUp }
    })
end

-- ============================================================
-- Recolher câmera a partir do modo foto (tecla X)
-- ============================================================
RegisterNetEvent("viccs_camera:client:pickupFromPhotoMode", function()
    if PhotoMode.active then
        PhotoMode:Stop()
    end
    Wait(600)
    PickupCamera()
end)

-- ============================================================
-- Setup Prompts (nativos RDR2)
-- ============================================================
function SetupPrompts()
    promptGroup = GetRandomIntInRange(1000, 99999)

    -- Prompt "Ativar Câmera" (ENTER)
    promptActivate = PromptRegisterBegin()
    PromptSetControlAction(promptActivate, 0xC7B5340A) -- ENTER
    PromptSetText(promptActivate, CreateVarString(10, "LITERAL_STRING", Config.Locale.PromptActivate))
    PromptSetEnabled(promptActivate, true)
    PromptSetVisible(promptActivate, true)
    PromptSetStandardMode(promptActivate, true)
    PromptSetGroup(promptActivate, promptGroup, 0)
    PromptRegisterEnd(promptActivate)

    -- Prompt "Recolher Câmera" (X)
    promptPickup = PromptRegisterBegin()
    PromptSetControlAction(promptPickup, Config.Keys.PhotoPickup) -- X
    PromptSetText(promptPickup, CreateVarString(10, "LITERAL_STRING", Config.Locale.PromptPickup))
    PromptSetEnabled(promptPickup, true)
    PromptSetVisible(promptPickup, true)
    PromptSetStandardMode(promptPickup, true)
    PromptSetGroup(promptPickup, promptGroup, 0)
    PromptRegisterEnd(promptPickup)
end

-- ============================================================
-- Limpar Prompts
-- ============================================================
function CleanupPrompts()
    if promptActivate then
        PromptDelete(promptActivate)
        promptActivate = nil
    end
    if promptPickup then
        PromptDelete(promptPickup)
        promptPickup = nil
    end
end

-- ============================================================
-- Cleanup ao parar o recurso
-- ============================================================
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    if PhotoMode.active then
        PhotoMode:Stop()
    end

    if PlacementSystem.active then
        PlacementSystem:Cancel()
    end

    if cameraEntity and DoesEntityExist(cameraEntity) then
        DeleteEntity(cameraEntity)
    end

    CleanupPrompts()
    SendNUIMessage({ action = "hide" })
end)
