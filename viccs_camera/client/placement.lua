-- ==========================================================
-- viccs_camera | Client — Placement System
-- Posicionar o prop p_camera01x no mundo
-- Q/E para rotacionar (hashes RDR2 corretos)
-- ==========================================================

PlacementSystem = {}
PlacementSystem.active = false
PlacementSystem.previewProp = nil
PlacementSystem.heading = 0.0
PlacementSystem.position = vector3(0, 0, 0)

-- ============================================================
-- Iniciar o modo placement
-- ============================================================
function PlacementSystem:Start()
    if self.active then return end
    self.active = true

    -- Heading inicial = direção que o jogador está olhando
    local ped = PlayerPedId()
    self.heading = GetEntityHeading(ped)

    -- Carrega o modelo do prop
    local modelHash = GetHashKey(Config.PropModel)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(100)
    end

    -- Posição inicial na frente do jogador
    local coords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local spawnPos = coords + (forward * Config.PlacementDistance)

    -- Cria o prop preview (fantasma transparente)
    self.previewProp = CreateObject(modelHash, spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, false, false)

    -- Sem colisão, transparente, congelado
    SetEntityCollision(self.previewProp, false, false)
    SetEntityAlpha(self.previewProp, Config.PlacementColor.a, false)
    FreezeEntityPosition(self.previewProp, true)
    SetEntityInvincible(self.previewProp, true)

    -- Loop principal de placement
    CreateThread(function()
        while self.active do
            Wait(0)
            self:Update()
        end
    end)
end

-- ============================================================
-- Atualizar posição do prop preview a cada frame
-- ============================================================
function PlacementSystem:Update()
    if not self.active or not self.previewProp then return end

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)
    local pedForward = GetEntityForwardVector(ped)

    -- Posicionar na frente do jogador
    local targetPos = pedCoords + (pedForward * Config.PlacementDistance)

    -- Raycast para alinhar ao chão
    local hit, hitCoords = self:RaycastGround(targetPos)

    if hit then
        self.position = hitCoords
    else
        self.position = vector3(targetPos.x, targetPos.y, pedCoords.z - 1.0)
    end

    -- Atualizar posição do prop
    SetEntityCoords(self.previewProp, self.position.x, self.position.y, self.position.z, false, false, false, false)
    SetEntityHeading(self.previewProp, self.heading)

    if Config.PropPlaceOnGround then
        PlaceObjectOnGroundProperly(self.previewProp, true)
    end

    -- ========================================================
    -- BLOQUEAR todas as ações da tecla Q e E para o jogo
    -- e reutilizar como rotação manual do prop
    -- ========================================================

    -- Q (INPUT_COVER) — bloqueia para não sentar/cobrir
    DisableControlAction(0, 0xDE794E3E, true)

    -- E — bloquear TODAS as ações vinculadas à tecla E no RDR2
    -- INPUT_ENTER (hash real da tecla E no RedM)
    DisableControlAction(0, 0xCEFD9220, true)
    -- INPUT_CONTEXT (contextual genérico, também mapeado no E)
    DisableControlAction(0, 0xB73BCA77, true)
    -- INPUT_LOOT (saquear/interagir com objetos)
    DisableControlAction(0, 0xFF12C566, true)
    -- INPUT_MELEE_ATTACK (ataque corpo a corpo, pode conflitar)
    DisableControlAction(0, 0x3C3DD371, true)

    -- Desabilita scroll do mouse (para não trocar de arma acidentalmente)
    DisableControlAction(0, Config.Keys.PhotoZoomIn, true)
    DisableControlAction(0, Config.Keys.PhotoZoomOut, true)

    -- Q = rotação esquerda
    if IsDisabledControlPressed(0, 0xDE794E3E) then
        self.heading = self.heading + Config.PlacementRotSpeed
        if self.heading > 360.0 then self.heading = self.heading - 360.0 end
    end

    -- E = rotação direita (escuta INPUT_ENTER que é o hash real da tecla E)
    if IsDisabledControlPressed(0, 0xCEFD9220) then
        self.heading = self.heading - Config.PlacementRotSpeed
        if self.heading < 0.0 then self.heading = self.heading + 360.0 end
    end

    -- ========================================
    -- ENTER = confirmar posição
    -- ========================================
    if IsControlJustReleased(0, Config.Keys.PlaceConfirm) then
        self:Confirm()
        return -- Sair do Update imediatamente após confirmar
    end

    -- ========================================
    -- BACKSPACE = cancelar
    -- ========================================
    if IsControlJustReleased(0, Config.Keys.PlaceCancel) then
        self:Cancel()
        return
    end

    -- ========================================
    -- Texto de instrução na tela
    -- ========================================
    self:DrawInstructionText()
end

-- ============================================================
-- Confirmar posicionamento
-- ============================================================
function PlacementSystem:Confirm()
    if not self.active then return end

    local finalPos = GetEntityCoords(self.previewProp)
    local finalHeading = self.heading

    self:DestroyPreview()
    self.active = false

    TriggerEvent("viccs_camera:client:placementConfirmed", finalPos, finalHeading)
end

-- ============================================================
-- Cancelar posicionamento
-- ============================================================
function PlacementSystem:Cancel()
    self:DestroyPreview()
    self.active = false
end

-- ============================================================
-- Destruir o prop de preview
-- ============================================================
function PlacementSystem:DestroyPreview()
    if self.previewProp and DoesEntityExist(self.previewProp) then
        DeleteEntity(self.previewProp)
        self.previewProp = nil
    end
end

-- ============================================================
-- Raycast para encontrar o chão
-- ============================================================
function PlacementSystem:RaycastGround(pos)
    local startPos = vector3(pos.x, pos.y, pos.z + 50.0)
    local endPos   = vector3(pos.x, pos.y, pos.z - 50.0)

    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(
        startPos.x, startPos.y, startPos.z,
        endPos.x, endPos.y, endPos.z,
        1 + 16,
        PlayerPedId(),
        0
    )

    local _, hit, hitCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
    return hit == 1, hitCoords
end

-- ============================================================
-- Texto de instrução na tela
-- ============================================================
function PlacementSystem:DrawInstructionText()
    -- Título
    SetTextScale(0.0, 0.4)
    SetTextColor(255, 255, 255, 255)
    SetTextCentre(true)
    SetTextDropshadow(1, 0, 0, 0, 255)
    SetTextFontForCurrentCommand(1)
    DisplayText(CreateVarString(10, "LITERAL_STRING", Config.Locale.PlacementTitle), 0.5, 0.88)

    -- Controles
    local controls = "ENTER: Confirmar | BACKSPACE: Cancelar | Q/E: Rotacionar"
    SetTextScale(0.0, 0.3)
    SetTextColor(200, 200, 200, 200)
    SetTextCentre(true)
    SetTextDropshadow(1, 0, 0, 0, 255)
    SetTextFontForCurrentCommand(1)
    DisplayText(CreateVarString(10, "LITERAL_STRING", controls), 0.5, 0.92)

    -- Indicador de rotação
    local rotText = string.format("Rotação: %.0f°", self.heading)
    SetTextScale(0.0, 0.25)
    SetTextColor(180, 180, 180, 180)
    SetTextCentre(true)
    SetTextDropshadow(1, 0, 0, 0, 255)
    SetTextFontForCurrentCommand(1)
    DisplayText(CreateVarString(10, "LITERAL_STRING", rotText), 0.5, 0.95)
end
