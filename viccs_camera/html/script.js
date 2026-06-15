/* ==========================================================
   viccs_camera | NUI Script — UI Control & Flash
   ========================================================== */

(function () {
    "use strict";

    const overlay      = document.getElementById("camera-overlay");
    const flash        = document.getElementById("flash-overlay");
    const filterName   = document.getElementById("filter-name");
    const statusFilter = document.getElementById("status-filter");
    const statusDof    = document.getElementById("status-dof");
    const statusZoom   = document.getElementById("status-zoom");

    // ============================================================
    // Listener para mensagens do Lua (SendNUIMessage)
    // ============================================================
    window.addEventListener("message", function (event) {
        var data = event.data;
        if (!data || !data.action) return;

        switch (data.action) {
            case "show":
                showOverlay();
                break;

            case "hide":
                hideOverlay();
                break;

            case "triggerFlash":
                triggerFlash();
                playShutterSound();
                break;

            case "updateFilter":
                updateFilterIndicator(data.filterName);
                break;

            case "updateStatus":
                updateStatusBar(data.filterName, data.dofEnabled, data.zoomPercent);
                break;
        }
    });

    // ============================================================
    // Mostrar/Esconder overlay
    // ============================================================
    function showOverlay() {
        overlay.classList.remove("hidden");
    }

    function hideOverlay() {
        overlay.classList.add("hidden");
    }

    // ============================================================
    // Atualizar indicador de filtro (temporário ao trocar)
    // ============================================================
    function updateFilterIndicator(name) {
        if (filterName) {
            filterName.textContent = name || "Nenhum";
        }
        if (statusFilter) {
            statusFilter.textContent = "Filtro: " + (name || "Nenhum");
        }
    }

    // ============================================================
    // Atualizar barra de status
    // ============================================================
    function updateStatusBar(filterNameVal, dofEnabled, zoomPercent) {
        if (statusFilter && filterNameVal !== undefined) {
            statusFilter.textContent = "Filtro: " + (filterNameVal || "Nenhum");
        }
        if (statusDof && dofEnabled !== undefined) {
            statusDof.textContent = "Foco: " + (dofEnabled ? "ON" : "OFF");
        }
        if (statusZoom && zoomPercent !== undefined) {
            statusZoom.textContent = "Zoom: " + Math.max(0, Math.min(100, zoomPercent)) + "%";
        }
    }

    // ============================================================
    // Flash branco (efeito de câmera)
    // ============================================================
    function triggerFlash() {
        flash.classList.remove("hidden");
        flash.classList.remove("active");
        void flash.offsetHeight; // Force reflow
        flash.classList.add("active");

        setTimeout(function () {
            flash.classList.remove("active");
            flash.classList.add("hidden");
        }, 500);
    }

    // ============================================================
    // Som de obturador mecânico (Web Audio API)
    // ============================================================
    function playShutterSound() {
        try {
            var AudioCtx = window.AudioContext || window.webkitAudioContext;
            if (!AudioCtx) return;
            var ctx = new AudioCtx();

            // Ruído metálico rápido
            var bufferSize = Math.floor(ctx.sampleRate * 0.12);
            var buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
            var channelData = buffer.getChannelData(0);
            for (var i = 0; i < bufferSize; i++) {
                channelData[i] = Math.random() * 2 - 1;
            }

            var noise = ctx.createBufferSource();
            noise.buffer = buffer;

            var filter = ctx.createBiquadFilter();
            filter.type = "bandpass";
            filter.frequency.setValueAtTime(800, ctx.currentTime);
            filter.Q.setValueAtTime(3, ctx.currentTime);

            var gainNode = ctx.createGain();
            gainNode.gain.setValueAtTime(0.4, ctx.currentTime);
            gainNode.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.1);

            noise.connect(filter);
            filter.connect(gainNode);
            gainNode.connect(ctx.destination);
            noise.start();

            // Clique mecânico
            var osc = ctx.createOscillator();
            var oscGain = ctx.createGain();
            osc.type = "sine";
            osc.frequency.setValueAtTime(120, ctx.currentTime);
            osc.frequency.exponentialRampToValueAtTime(60, ctx.currentTime + 0.05);
            oscGain.gain.setValueAtTime(0.3, ctx.currentTime);
            oscGain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 0.05);
            osc.connect(oscGain);
            oscGain.connect(ctx.destination);
            osc.start();
            osc.stop(ctx.currentTime + 0.06);
        } catch (e) {
            // Silenciar erros de áudio
        }
    }

})();
