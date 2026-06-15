-- ==========================================================
-- viccs_camera | Client — Photo Mode (Free Cam)
-- Controles: mouse = rotação, WASD = mover, Scroll = zoom,
-- F = filtro, G = DOF, H = HUD, Enter = foto, X = recolher
-- ==========================================================

PhotoMode = {}
PhotoMode.active = false
PhotoMode.cam = nil
PhotoMode.fov = 50.0
PhotoMode.filterIndex = 1
PhotoMode.dofEnabled = true
PhotoMode.hudHidden = false
PhotoMode.rotX = 0.0        -- Pitch
PhotoMode.rotZ = 0.0        -- Yaw
PhotoMode.camPos = nil       -- Posição atual da câmera (free cam)
PhotoMode.anchorPos = nil    -- Posição do prop no chão (ponto de ancoragem)

-- ============================================================
-- Hashes nativos para DOF (RDR3/RedM)
-- ============================================================
local NATIVE_SET_CAM_NEAR_DOF    = 0x3FA4BF0A7AB7DE2C
local NATIVE_SET_CAM_FAR_DOF     = 0xEDD91296CD01AEE0
local NATIVE_SET_CAM_DOF_STRENGTH = 0x5EE29B4D7D5DF897

-- ============================================================
-- Ativar modo foto
-- ============================================================
function PhotoMode:Start(propCoords, propHeading)
    if self.active then return end
    self.active = true
    self.fov = Config.DefaultFOV
    self.filterIndex = 1
    self.dofEnabled = Config.DOFEnabled
    self.hudHidden = false

    -- Salvar ponto de ancoragem (posição do prop no chão)
    self.anchorPos = vector3(propCoords.x, propCoords.y, propCoords.z)

    -- Posição inicial da câmera = prop + offset vertical
    self.camPos = vector3(propCoords.x, propCoords.y, propCoords.z + 1.2)
    self.rotX = 0.0
    self.rotZ = propHeading + 0.0

    -- Criar câmera de renderização
    self.cam = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        self.camPos.x, self.camPos.y, self.camPos.z,
        0.0, 0.0, self.rotZ,
        self.fov,
        false, 2
    )

    SetCamActive(self.cam, true)
    RenderScriptCams(true, true, 500, true, true)

    -- NÃO congelar o jogador — ele pode andar livre
    -- (a câmera se move de forma independente)

    -- Mostrar NUI overlay
    SendNUIMessage({ action = "show", controls = Config.Locale.ControlsHelp })
    SetNuiFocus(false, false)

    -- Loop principal do modo foto
    CreateThread(function()
        while self.active do
            self:Update()
            Wait(0)
        end
    end)
end

-- ============================================================
-- Atualizar controles a cada frame
-- ============================================================
function PhotoMode:Update()
    if not self.active or not self.cam then return end

    -- ========================================================
    -- DESABILITAR CONTROLES SELETIVAMENTE
    -- ========================================================
    DisableControlAction(0, 0xD6D7A177, true) -- INPUT_MOVE_LR (A/D)
    DisableControlAction(0, 0x8FD7B45B, true) -- INPUT_MOVE_UD (W/S)
    DisableControlAction(0, 0x8FFC75D6, true) -- INPUT_SPRINT (Shift)
    DisableControlAction(0, 0xD9D2CE13, true) -- INPUT_JUMP (Space)
    DisableControlAction(0, 0xDE794E3E, true) -- INPUT_COVER (Q)
    DisableControlAction(0, 0xCEFD9220, true) -- INPUT_ENTER (E)

    -- Combate
    DisableControlAction(0, 0x8CC5E295, true) -- INPUT_ATTACK
    DisableControlAction(0, 0x24AEA3F0, true) -- INPUT_ATTACK2
    DisableControlAction(0, 0x5B915C8F, true) -- INPUT_MELEE_ATTACK
    DisableControlAction(0, 0xC1989F4C, true) -- INPUT_SELECT_WEAPON
    DisableControlAction(0, 0x74E9FA0E, true) -- INPUT_SELECT_WEAPON_RADIAL

    -- Menus nativos
    DisableControlAction(0, 0xE30CD707, true) -- INPUT_OPEN_JOURNAL
    DisableControlAction(0, 0xCF9A4E28, true) -- INPUT_OPEN_SATCHEL

    -- Look (mouse)
    DisableControlAction(0, 0xA987235F, true) -- INPUT_LOOK_LR
    DisableControlAction(0, 0xD2047988, true) -- INPUT_LOOK_UD

    -- Teclas do modo foto
    DisableControlAction(0, Config.Keys.PhotoExit, true)
    DisableControlAction(0, Config.Keys.PhotoCapture, true)
    DisableControlAction(0, Config.Keys.PhotoFilter, true)
    DisableControlAction(0, Config.Keys.PhotoDOF, true)
    DisableControlAction(0, Config.Keys.PhotoHideUI, true)
    DisableControlAction(0, Config.Keys.PhotoPickup, true)
    DisableControlAction(0, Config.Keys.PhotoZoomIn, true)
    DisableControlAction(0, Config.Keys.PhotoZoomOut, true)

    -- Também desabilitar interação contextual (prevenir ações do E)
    DisableControlAction(0, 0xB73BCA77, true) -- INPUT_CONTEXT
    DisableControlAction(0, 0xFF12C566, true) -- INPUT_LOOT

    -- ========================================
    -- ROTAÇÃO DA CÂMERA (Mouse)
    -- ========================================
    local mouseX = GetDisabledControlNormal(0, 0xA987235F)
    local mouseY = GetDisabledControlNormal(0, 0xD2047988)

    self.rotZ = self.rotZ - (mouseX * Config.RotationSpeed)
    self.rotX = self.rotX - (mouseY * Config.RotationSpeed)

    if self.rotX > 89.0 then self.rotX = 89.0 end
    if self.rotX < -89.0 then self.rotX = -89.0 end

    -- ========================================
    -- FREE CAM — Mover câmera com WASD + Space/Q
    -- ========================================
    if Config.FreeCamEnabled then
        self:UpdateFreeCam()
    end

    -- Aplicar posição e rotação na câmera
    SetCamCoord(self.cam, self.camPos.x, self.camPos.y, self.camPos.z)
    SetCamRot(self.cam, self.rotX, 0.0, self.rotZ, 2)

    -- ========================================
    -- DOF (aplicar a cada frame se ativado)
    -- ========================================
    if self.dofEnabled then
        self:ApplyDOFPerFrame()
    end

    -- ========================================
    -- ZOOM (Scroll)
    -- ========================================
    if IsDisabledControlJustPressed(0, Config.Keys.PhotoZoomIn) then
        self.fov = self.fov - Config.ZoomSpeed
        if self.fov < Config.MinFOV then self.fov = Config.MinFOV end
        SetCamFov(self.cam, self.fov)
        self:UpdateNUIStatus()
    end

    if IsDisabledControlJustPressed(0, Config.Keys.PhotoZoomOut) then
        self.fov = self.fov + Config.ZoomSpeed
        if self.fov > Config.MaxFOV then self.fov = Config.MaxFOV end
        SetCamFov(self.cam, self.fov)
        self:UpdateNUIStatus()
    end

    -- ========================================
    -- FILTROS (F)
    -- ========================================
    if IsDisabledControlJustReleased(0, Config.Keys.PhotoFilter) then
        self:CycleFilter()
    end

    -- ========================================
    -- DOF Toggle (G)
    -- ========================================
    if IsDisabledControlJustReleased(0, Config.Keys.PhotoDOF) then
        self.dofEnabled = not self.dofEnabled
        if not self.dofEnabled then
            self:RemoveDOF()
        end
        self:UpdateNUIStatus()
    end

    -- ========================================
    -- Hide HUD (H)
    -- ========================================
    if IsDisabledControlJustReleased(0, Config.Keys.PhotoHideUI) then
        self.hudHidden = not self.hudHidden
        if self.hudHidden then
            SendNUIMessage({ action = "hide" })
        else
            SendNUIMessage({ action = "show", controls = Config.Locale.ControlsHelp })
        end
    end

    -- ========================================
    -- SCREENSHOT (ENTER)
    -- ========================================
    if IsDisabledControlJustReleased(0, Config.Keys.PhotoCapture) then
        self:TakeScreenshot()
    end

    -- ========================================
    -- RECOLHER CÂMERA (X)
    -- ========================================
    if IsDisabledControlJustReleased(0, Config.Keys.PhotoPickup) then
        TriggerEvent("viccs_camera:client:pickupFromPhotoMode")
    end

    -- ========================================
    -- SAIR DO MODO FOTO (BACKSPACE)
    -- ========================================
    if IsDisabledControlJustReleased(0, Config.Keys.PhotoExit) then
        self:Stop()
        return
    end
end

-- ============================================================
-- Free Cam — Mover a câmera com WASD dentro do raio permitido
-- ============================================================
function PhotoMode:UpdateFreeCam()
    -- Eixo frente/trás (W/S)
    local moveUD = GetDisabledControlNormal(0, Config.Keys.FreeCamForward)
    -- Eixo esquerda/direita (A/D)
    local moveLR = GetDisabledControlNormal(0, Config.Keys.FreeCamStrafe)

    -- Velocidade base
    local speed = Config.FreeCamSpeed

    -- Sprint (Shift)
    if IsDisabledControlPressed(0, Config.Keys.FreeCamSprint) then
        speed = speed * Config.FreeCamSprintMult
    end

    -- Calcular vetor de direção baseado na rotação da câmera
    local radZ = math.rad(self.rotZ)
    local radX = math.rad(self.rotX)

    -- Frente/trás (baseado em heading e pitch)
    local forwardX = -math.sin(radZ) * math.cos(radX) * moveUD * speed
    local forwardY =  math.cos(radZ) * math.cos(radX) * moveUD * speed
    local forwardZ = -math.sin(radX) * moveUD * speed

    -- Strafe esquerda/direita
    local strafeX = -math.cos(radZ) * moveLR * speed
    local strafeY = -math.sin(radZ) * moveLR * speed

    -- Subir/descer
    local verticalMove = 0.0
    -- Space = subir
    if IsDisabledControlPressed(0, Config.Keys.FreeCamUp) then
        verticalMove = speed
    end
    -- Q = descer
    if IsDisabledControlPressed(0, Config.Keys.FreeCamDown) then
        verticalMove = verticalMove - speed
    end

    -- Calcular nova posição
    local newX = self.camPos.x + forwardX + strafeX
    local newY = self.camPos.y + forwardY + strafeY
    local newZ = self.camPos.z + forwardZ + verticalMove

    local newPos = vector3(newX, newY, newZ)

    -- Verificar se está dentro do raio permitido
    if self.anchorPos then
        local dist = #(vector3(newPos.x, newPos.y, self.anchorPos.z) - self.anchorPos)
        if dist <= Config.FreeCamRadius then
            self.camPos = newPos
        else
            -- Permitir mover na vertical mesmo no limite do raio
            local clampedPos = self.camPos
            self.camPos = vector3(clampedPos.x, clampedPos.y, newZ)
        end
    else
        self.camPos = newPos
    end
end

-- ============================================================
-- Atualizar informações dinâmicas na NUI
-- ============================================================
function PhotoMode:UpdateNUIStatus()
    local filter = Config.Filters[self.filterIndex]
    local fovRange = Config.MaxFOV - Config.MinFOV
    local zoomPercent = 0
    if fovRange > 0 then
        zoomPercent = math.floor(((Config.MaxFOV - self.fov) / fovRange) * 100)
    end

    SendNUIMessage({
        action = "updateStatus",
        filterName = filter and filter.name or "Nenhum",
        dofEnabled = self.dofEnabled,
        zoomPercent = zoomPercent,
    })
end

-- ============================================================
-- Capturar screenshot usando screenshot-basic
-- ============================================================
function PhotoMode:TakeScreenshot()
    -- Esconde a NUI para o screenshot capturar a imagem limpa
    SendNUIMessage({ action = "hide" })
    Wait(300) -- Esperar a NUI desaparecer completamente

    if Config.Webhook and Config.Webhook ~= "" then
        -- Nota: Discord espera o campo "files[]" no multipart upload
        exports['screenshot-basic']:requestScreenshotUpload(
            Config.Webhook,
            "files[]",
            function(data)
                -- Dispara o efeito de flash e som
                SendNUIMessage({ action = "triggerFlash" })

                Wait(500)
                if not PhotoMode.hudHidden then
                    SendNUIMessage({ action = "show", controls = Config.Locale.ControlsHelp })
                end

                -- Tenta decodificar a resposta do Discord
                local success, resp = pcall(json.decode, data)
                if success and resp and resp.attachments and resp.attachments[1] then
                    local photoUrl = resp.attachments[1].proxy_url or resp.attachments[1].url
                    TriggerEvent('chat:addMessage', {
                        color = { 255, 200, 100 },
                        args = { "Câmera", "Foto enviada com sucesso!" }
                    })
                    print("[viccs_camera] Foto enviada: " .. tostring(photoUrl))
                else
                    print("[viccs_camera] Discord response: " .. tostring(data))
                    TriggerEvent('chat:addMessage', {
                        color = { 255, 200, 100 },
                        args = { "Câmera", "Foto capturada! Verifique o canal do Discord." }
                    })
                end
            end
        )
    else
        SendNUIMessage({ action = "triggerFlash" })
        Wait(500)
        if not PhotoMode.hudHidden then
            SendNUIMessage({ action = "show", controls = Config.Locale.ControlsHelp })
        end

        TriggerEvent('chat:addMessage', {
            color = { 255, 100, 100 },
            args = { "Câmera", "Configure o Webhook do Discord no config.lua para salvar fotos." }
        })
    end
end

-- ============================================================
-- Ciclar filtros
-- ============================================================
function PhotoMode:CycleFilter()
    -- Remove filtro atual
    local currentFilter = Config.Filters[self.filterIndex]
    if currentFilter and currentFilter.fx then
        AnimpostfxStop(currentFilter.fx)
    end

    -- Avança
    self.filterIndex = self.filterIndex + 1
    if self.filterIndex > #Config.Filters then
        self.filterIndex = 1
    end

    -- Aplica novo
    local newFilter = Config.Filters[self.filterIndex]
    if newFilter and newFilter.fx then
        AnimpostfxPlay(newFilter.fx)
    end

    -- Atualiza NUI
    SendNUIMessage({
        action = "updateFilter",
        filterName = newFilter and newFilter.name or "Nenhum",
    })
    self:UpdateNUIStatus()
end

-- ============================================================
-- DOF — Aplicar via Citizen.InvokeNative (nomes globais não
-- existem no RedM, precisa chamar pelo hash)
-- ============================================================
function PhotoMode:ApplyDOFPerFrame()
    if not self.cam then return end
    pcall(function()
        Citizen.InvokeNative(NATIVE_SET_CAM_NEAR_DOF, self.cam, Config.DOFNear)
        Citizen.InvokeNative(NATIVE_SET_CAM_FAR_DOF, self.cam, Config.DOFFar)
        Citizen.InvokeNative(NATIVE_SET_CAM_DOF_STRENGTH, self.cam, Config.DOFStrength)
    end)
end

-- ============================================================
-- Remover DOF
-- ============================================================
function PhotoMode:RemoveDOF()
    if not self.cam then return end
    pcall(function()
        Citizen.InvokeNative(NATIVE_SET_CAM_DOF_STRENGTH, self.cam, 0.0)
    end)
end

-- ============================================================
-- Parar modo foto
-- ============================================================
function PhotoMode:Stop()
    if not self.active then return end
    self.active = false

    -- Remove filtros ativos
    local currentFilter = Config.Filters[self.filterIndex]
    if currentFilter and currentFilter.fx then
        AnimpostfxStop(currentFilter.fx)
    end

    -- Remove DOF
    self:RemoveDOF()

    -- Destruir câmera
    if self.cam then
        RenderScriptCams(false, true, 500, true, true)
        SetCamActive(self.cam, false)
        DestroyCam(self.cam, false)
        self.cam = nil
    end

    -- Descongelar o jogador (caso esteja congelado por outro script)
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)

    -- Esconder NUI
    SendNUIMessage({ action = "hide" })

    -- Resetar estado
    self.filterIndex = 1
    self.fov = Config.DefaultFOV
    self.camPos = nil
    self.anchorPos = nil
end
