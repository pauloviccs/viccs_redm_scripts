Config = {}

-- ============================================================
-- ITEM & COMMAND
-- ============================================================
Config.ItemName       = "camera"              -- Nome do item no banco de dados (tabela items)
Config.CommandName    = "camera"              -- Comando /camera para usar sem item
Config.CommandRequireItem = true             -- Se true, o /camera só funciona se tiver o item no inventário

-- ============================================================
-- PROP
-- ============================================================
Config.PropModel      = "p_camera01x"         -- Modelo do prop da câmera no mundo
Config.PropPlaceOnGround = true               -- Ajustar automaticamente ao chão

-- ============================================================
-- PLACEMENT (Posicionamento)
-- ============================================================
Config.PlacementDistance    = 5.0             -- Distância máxima de placement na frente do jogador
Config.PlacementRotSpeed   = 2.0             -- Velocidade de rotação com Q/E
Config.PlacementColor      = { r = 100, g = 200, b = 100, a = 200 } -- Cor do prop fantasma (verde translúcido)

-- ============================================================
-- PROXIMIDADE & COMANDOS
-- ============================================================
Config.InteractDistance    = 2.5              -- Distância para aparecer o prompt "Ativar Câmera"
Config.PickupDistance      = 2.5              -- Distância para recolher a câmera
Config.FotoCommandName     = "foto"           -- Comando /foto para entrar no modo foto à distância

-- ============================================================
-- PHOTO MODE
-- ============================================================
Config.DefaultFOV         = 50.0              -- FOV padrão ao entrar no modo câmera
Config.MinFOV             = 10.0              -- FOV mínimo (zoom máximo)
Config.MaxFOV             = 90.0              -- FOV máximo (zoom mínimo)
Config.ZoomSpeed          = 2.0               -- Velocidade do zoom com scroll
Config.RotationSpeed      = 3.0               -- Sensibilidade de rotação da câmera (mouse)

-- ============================================================
-- FREE CAM (Câmera livre no modo foto)
-- ============================================================
Config.FreeCamEnabled     = true              -- Permite mover a câmera livremente com WASD
Config.FreeCamSpeed       = 0.08              -- Velocidade de movimento da free cam
Config.FreeCamRadius      = 25.0              -- Raio máximo de distância da posição do prop no chão
Config.FreeCamSprintMult  = 2.5               -- Multiplicador de velocidade ao segurar Shift

-- ============================================================
-- DOF (Profundidade de Campo)
-- ============================================================
Config.DOFEnabled         = true              -- DOF ativado por padrão
Config.DOFNear            = 0.5               -- Near DOF
Config.DOFFar             = 15.0              -- Far DOF
Config.DOFStrength        = 1.0               -- Intensidade do DOF

-- ============================================================
-- SCREENSHOT
-- ============================================================
Config.ScreenshotEncoding = "jpg"             -- Formato: "jpg", "png", "webp"
Config.ScreenshotQuality  = 0.95              -- Qualidade (0.0 a 1.0)
Config.Webhook            = "https://discord.com/api/webhooks/1470795488679821383/nFBRP6v1YzFV0ITK4q7e8J1pjkmgCsM9ZUKKCTqrYDgJLFTfKG-APR-j9gixv4Z8MCPm"

-- ============================================================
-- FILTROS DISPONÍVEIS (nomes válidos para RDR2/RedM)
-- Nota: Os efeitos AnimpostfxPlay usam nomes internos do
-- motor gráfico do RDR2. Nomes do GTA V NÃO funcionam aqui.
-- ============================================================
Config.Filters = {
    { name = "Nenhum",             fx = nil },
    { name = "Viewfinder",         fx = "CameraViewfinder" },
    { name = "Flash",              fx = "CameraTakePicture" },
    { name = "Studio",             fx = "CameraViewfinderStudio" },
    { name = "Transição",          fx = "CamTransitionBlink" },
    { name = "Óculos Escuros",     fx = "1p_glassesdark" },
    { name = "Chapéu Escuro",      fx = "1p_hatdark" },
    { name = "Máscara",            fx = "1p_maskdark" },
}

-- ============================================================
-- TECLAS — Hashes corretos para RDR2/RedM
-- ============================================================
Config.Keys = {
    -- Placement
    PlaceConfirm   = 0xC7B5340A,  -- ENTER
    PlaceCancel    = 0x156F7119,  -- BACKSPACE
    PlaceRotLeft   = 0xDE794E3E,  -- Q (INPUT_COVER)
    PlaceRotRight  = 0xCEFD9220,  -- E (INPUT_ENTER)

    -- Photo Mode
    PhotoExit      = 0x156F7119,  -- BACKSPACE
    PhotoCapture   = 0xC7B5340A,  -- ENTER
    PhotoFilter    = 0xB2F377E8,  -- F (INPUT_VEH_EXIT)
    PhotoDOF       = 0x760A9C6F,  -- G (INPUT_INTERACTION_MENU)
    PhotoHideUI    = 0x24978A28,  -- H (INPUT_WHISTLE)
    PhotoPickup    = 0x8CC9CD42,  -- X (INPUT_GAME_MENU_TAB_RIGHT_SECONDARY)
    PhotoZoomIn    = 0xCC1075A7,  -- Scroll Up (INPUT_PREV_WEAPON)
    PhotoZoomOut   = 0xFD0F0C2C,  -- Scroll Down (INPUT_NEXT_WEAPON)

    -- Free Cam movement (WASD) — usados com GetDisabledControlNormal
    FreeCamForward = 0x8FD7B45B,  -- W (INPUT_MOVE_UD — eixo vertical)
    FreeCamStrafe  = 0xD6D7A177,  -- A/D (INPUT_MOVE_LR — eixo horizontal)
    FreeCamSprint  = 0x8FFC75D6,  -- Shift (INPUT_SPRINT)
    FreeCamUp      = 0xD9D2CE13,  -- Space (INPUT_JUMP) — subir câmera
    FreeCamDown    = 0xDE794E3E,  -- Q (INPUT_COVER) — descer câmera
}

-- ============================================================
-- TEXTOS / LOCALIZAÇÃO
-- ============================================================
Config.Locale = {
    PromptActivate     = "Ativar Câmera",
    PromptPickup       = "Recolher Câmera",
    PlacementTitle     = "Posicionar Câmera",
    PhotoModeTitle     = "Modo Foto",
    NotifyUseItem      = "Você usou a câmera fotográfica.",
    NotifyNoItem       = "Você não tem uma câmera.",
    NotifyPickedUp     = "Câmera recolhida.",
    NotifyScreenshot   = "Foto capturada!",
    NotifyCameraPlaced = "Câmera posicionada. Use /foto ou aproxime-se para ativar.",
    NotifyNoCamera     = "Você não tem nenhuma câmera posicionada.",
    FilterLabel        = "Filtro",
    DOFLabel           = "Foco",
    ZoomLabel          = "Zoom",
    ControlsHelp       = "ENTER: Foto | BACKSPACE: Sair | F: Filtro | G: Foco | H: HUD | WASD: Mover | Scroll: Zoom | X: Recolher",
}
