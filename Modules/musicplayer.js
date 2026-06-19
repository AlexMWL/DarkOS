(function() {
    // 1. Inject Styles
    const css = `
        @import url('https://fonts.googleapis.com/css2?family=Share+Tech+Mono&family=Outfit:wght@300;400;700&display=swap');
        
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            background-color: #000000;
            color: #ffffff;
            font-family: 'Share Tech Mono', monospace;
            overflow: hidden;
            margin: 0;
            padding: 10px;
            width: 100vw;
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        /* Scanline effect */
        body::before {
            content: " ";
            display: block;
            position: fixed;
            top: 0; left: 0; bottom: 0; right: 0;
            background: linear-gradient(rgba(18, 16, 16, 0) 50%, rgba(0, 0, 0, 0.25) 50%), 
                        linear-gradient(90deg, rgba(255, 0, 0, 0.05), rgba(0, 255, 0, 0.02), rgba(0, 0, 255, 0.05));
            background-size: 100% 4px, 3px 100%;
            z-index: 9999;
            pointer-events: none;
        }

        .darkos-player-container {
            width: 100%;
            height: 100%;
            max-width: 100%;
            background: rgba(12, 8, 8, 0.9);
            border: 1px solid #ff0055;
            box-shadow: 0 0 18px rgba(255, 0, 85, 0.4), inset 0 0 12px rgba(255, 0, 85, 0.15);
            border-radius: 8px;
            padding: 15px;
            position: relative;
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            display: flex;
            flex-direction: column;
            overflow: hidden;
        }

        .terminal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid rgba(255, 0, 85, 0.3);
            padding-bottom: 6px;
            margin-bottom: 10px;
            font-size: 10px;
            letter-spacing: 1px;
            color: #ff0055;
            text-shadow: 0 0 3px rgba(255, 0, 85, 0.5);
            flex-shrink: 0;
        }

        .terminal-header .dot {
            width: 6px;
            height: 6px;
            background-color: #ff0055;
            border-radius: 50%;
            display: inline-block;
            margin-right: 6px;
            box-shadow: 0 0 8px #ff0055;
            animation: pulse-dot 1.5s infinite alternate;
        }

        @keyframes pulse-dot {
            0% { opacity: 0.4; }
            100% { opacity: 1; }
        }

        /* Deck visualizer canvas */
        .deck-panel {
            background: rgba(0, 0, 0, 0.85);
            border: 1px solid rgba(255, 0, 85, 0.25);
            border-radius: 4px;
            padding: 10px;
            margin-bottom: 10px;
            text-align: center;
            position: relative;
            overflow: hidden;
            flex-shrink: 0;
        }

        .visualizer-canvas {
            width: 100%;
            height: 48px;
            display: block;
            background: rgba(255, 0, 85, 0.02);
            border-radius: 2px;
            margin-bottom: 8px;
        }

        .now-playing-title {
            font-family: 'Outfit', sans-serif;
            font-size: 14px;
            font-weight: 700;
            color: #ffffff;
            margin-bottom: 2px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            text-shadow: 0 0 5px rgba(255, 255, 255, 0.1);
        }

        .now-playing-status {
            font-size: 9px;
            color: rgba(255, 0, 85, 0.8);
            letter-spacing: 1.5px;
            text-transform: uppercase;
        }

        /* Time & progress bar */
        .progress-row {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 10px;
            font-size: 10px;
            color: rgba(255, 255, 255, 0.65);
            flex-shrink: 0;
        }

        .progress-container {
            flex: 1;
            height: 6px;
            background: rgba(255, 0, 85, 0.15);
            border: 1px solid rgba(255, 0, 85, 0.3);
            border-radius: 3px;
            position: relative;
            cursor: pointer;
        }

        .progress-bar {
            height: 100%;
            width: 0%;
            background: #ff0055;
            box-shadow: 0 0 8px #ff0055;
            border-radius: 2px;
            position: absolute;
            top: 0; left: 0;
        }

        /* Control deck buttons */
        .controls-row {
            display: flex;
            justify-content: center;
            align-items: center;
            gap: 12px;
            margin-bottom: 12px;
            flex-shrink: 0;
        }

        .ctrl-btn {
            background: rgba(255, 0, 85, 0.05);
            border: 1px solid rgba(255, 0, 85, 0.4);
            color: #ff0055;
            font-family: 'Share Tech Mono', monospace;
            width: 32px;
            height: 32px;
            display: flex;
            justify-content: center;
            align-items: center;
            cursor: pointer;
            border-radius: 50%;
            transition: all 0.25s;
            font-size: 11px;
            outline: none;
        }

        .ctrl-btn:hover {
            background: rgba(255, 0, 85, 0.15);
            border-color: #ff0055;
            box-shadow: 0 0 8px rgba(255, 0, 85, 0.3);
            transform: scale(1.05);
        }

        .ctrl-btn:active {
            transform: scale(0.95);
        }

        .ctrl-btn.play-pause {
            width: 40px;
            height: 40px;
            background: rgba(255, 0, 85, 0.15);
            border-color: #ff0055;
            font-size: 14px;
            box-shadow: 0 0 10px rgba(255, 0, 85, 0.3);
        }

        .ctrl-btn.play-pause:hover {
            background: #ff0055;
            color: #ffffff;
            box-shadow: 0 0 15px rgba(255, 0, 85, 0.6);
        }

        .ctrl-btn.active {
            background: #ff0055;
            color: #ffffff;
            border-color: #ff0055;
            box-shadow: 0 0 10px rgba(255, 0, 85, 0.5);
        }

        /* Volume & Options deck */
        .options-row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            border-bottom: 1px solid rgba(255, 0, 85, 0.25);
            padding-bottom: 8px;
            margin-bottom: 10px;
            font-size: 10px;
            flex-shrink: 0;
        }

        .volume-container {
            display: flex;
            align-items: center;
            gap: 6px;
        }

        .volume-slider {
            -webkit-appearance: none;
            appearance: none;
            width: 60px;
            height: 4px;
            background: rgba(255, 0, 85, 0.2);
            border-radius: 2px;
            outline: none;
        }

        .volume-slider::-webkit-slider-thumb {
            -webkit-appearance: none;
            appearance: none;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            background: #ff0055;
            cursor: pointer;
            box-shadow: 0 0 4px #ff0055;
        }

        .tab-btn-row {
            display: flex;
            gap: 6px;
        }

        .tab-btn {
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid rgba(255, 255, 255, 0.15);
            color: rgba(255, 255, 255, 0.7);
            font-family: 'Share Tech Mono', monospace;
            padding: 4px 8px;
            font-size: 9px;
            cursor: pointer;
            border-radius: 3px;
            transition: all 0.2s;
        }

        .tab-btn.active {
            background: rgba(255, 0, 85, 0.15);
            border-color: #ff0055;
            color: #ff0055;
        }

        /* List cluster view */
        .playlist-panel {
            flex: 1;
            overflow-y: auto;
            background: rgba(0, 0, 0, 0.6);
            border: 1px solid rgba(255, 0, 85, 0.2);
            border-radius: 4px;
            margin-bottom: 10px;
        }

        /* Customize scrollbar */
        .playlist-panel::-webkit-scrollbar {
            width: 4px;
        }
        .playlist-panel::-webkit-scrollbar-track {
            background: rgba(0,0,0,0.3);
        }
        .playlist-panel::-webkit-scrollbar-thumb {
            background: #ff0055;
            border-radius: 2px;
        }

        .playlist-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 8px 10px;
            border-bottom: 1px solid rgba(255, 0, 85, 0.1);
            font-size: 11px;
            cursor: pointer;
            transition: all 0.2s;
        }

        .playlist-item:last-child {
            border-bottom: none;
        }

        .playlist-item:hover {
            background: rgba(255, 0, 85, 0.05);
        }

        .playlist-item.playing {
            background: rgba(255, 0, 85, 0.12);
            border-left: 2px solid #ff0055;
            color: #ff0055;
            font-weight: bold;
        }

        .playlist-item-left {
            display: flex;
            align-items: center;
            gap: 6px;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
            flex: 1;
        }

        .playlist-item-index {
            color: rgba(255, 0, 85, 0.7);
            font-size: 9px;
            width: 15px;
        }

        .playlist-item-name {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .empty-state {
            text-align: center;
            padding: 20px 10px;
            font-size: 11px;
            color: rgba(255, 255, 255, 0.75);
            display: flex;
            flex-direction: column;
            gap: 10px;
            align-items: center;
        }

        .empty-state-btn {
            background: rgba(255, 0, 85, 0.15);
            border: 1px solid #ff0055;
            color: #ff0055;
            font-family: 'Share Tech Mono', monospace;
            padding: 5px 10px;
            font-size: 9px;
            font-weight: bold;
            cursor: pointer;
            border-radius: 4px;
            transition: all 0.25s;
        }

        .empty-state-btn:hover {
            background: #ff0055;
            color: #ffffff;
            box-shadow: 0 0 8px rgba(255, 0, 85, 0.4);
        }

        .status-footer {
            font-size: 8.5px;
            color: rgba(255, 255, 255, 0.4);
            text-align: center;
            letter-spacing: 1px;
            text-transform: uppercase;
            flex-shrink: 0;
        }

        /* Equalizer icon simulator */
        .eq-sim {
            display: flex;
            align-items: flex-end;
            gap: 2px;
            width: 12px;
            height: 10px;
        }
        .eq-bar {
            width: 2px;
            background-color: #ff0055;
            animation: bounce-eq 0.6s ease-in-out infinite alternate;
        }
        .eq-bar:nth-child(1) { height: 100%; animation-delay: 0.1s; }
        .eq-bar:nth-child(2) { height: 60%; animation-delay: 0.3s; }
        .eq-bar:nth-child(3) { height: 80%; animation-delay: 0.2s; }

        @keyframes bounce-eq {
            0% { transform: scaleY(0.2); }
            100% { transform: scaleY(1.1); }
        }
    `;

    // Inject Styles into Head
    const styleEl = document.createElement('style');
    styleEl.innerHTML = css;
    document.head.appendChild(styleEl);

    // Audio Elements: Split local files and streams to prevent CORS capturing on cross-origin resources
    const localAudio = new Audio();
    const streamAudio = new Audio();
    
    let audioCtx = null;
    let analyser = null;
    let sourceNode = null;
    let visualizerAnimFrame = null;

    // Synth elements
    let synthInterval = null;
    let synthPlaying = false;
    let synthStep = 0;
    const synthTempo = 120; // BPM

    // Playback state
    let playlist = [];
    let currentTrackIndex = -1;
    let activeTab = 'c_drive'; // 'c_drive', 'satellite', 'synth'
    let isShuffled = false;
    let repeatMode = 'none'; // 'none', 'one', 'all'
    let isVisualizerSetup = false;

    // High availability SomaFM HTTPS streams
    const satelliteStreams = [
        { name: "GROOVE SALAD [SOMA_FM]", url: "https://ice1.somafm.com/groovesalad-128-mp3" },
        { name: "DEF CON RADIO [SOMA_FM]", url: "https://ice1.somafm.com/defcon-128-mp3" },
        { name: "SYNTH ZONE [SOMA_FM]", url: "https://ice1.somafm.com/synthzone-128-mp3" }
    ];

    function getCurrentAudio() {
        return activeTab === 'satellite' ? streamAudio : localAudio;
    }

    // Build DOM layout
    const playerContainer = document.createElement('div');
    playerContainer.className = 'darkos-player-container';
    document.body.appendChild(playerContainer);

    function buildUI() {
        playerContainer.innerHTML = `
            <div class="terminal-header">
                <div><span class="dot"></span>DARKOS MUSIC PLAYER</div>
                <div id="drive-size">C_DRIVE MP3 DECK</div>
            </div>

            <div class="deck-panel">
                <canvas class="visualizer-canvas" id="canvas-visualizer"></canvas>
                <div class="now-playing-title" id="track-title">NO TRACK LOADED</div>
                <div class="now-playing-status" id="track-status">SYSTEM READY</div>
            </div>

            <div class="progress-row">
                <span id="time-current">00:00</span>
                <div class="progress-container" id="seek-container">
                    <div class="progress-bar" id="seek-bar"></div>
                </div>
                <span id="time-total">00:00</span>
            </div>

            <div class="controls-row">
                <button class="ctrl-btn" id="btn-shuffle" title="SHUFFLE">🔀</button>
                <button class="ctrl-btn" id="btn-prev" title="PREVIOUS">⏮</button>
                <button class="ctrl-btn play-pause" id="btn-play" title="PLAY/PAUSE">▶</button>
                <button class="ctrl-btn" id="btn-next" title="NEXT">⏭</button>
                <button class="ctrl-btn" id="btn-repeat" title="REPEAT">🔁</button>
            </div>

            <div class="options-row">
                <div class="volume-container">
                    <span>🔊</span>
                    <input type="range" class="volume-slider" id="volume-slider" min="0" max="100" value="70">
                </div>
                <div class="tab-btn-row">
                    <button class="tab-btn active" id="tab-c-drive">C_DRIVE</button>
                    <button class="tab-btn" id="tab-satellite">SATELLITE</button>
                    <button class="tab-btn" id="tab-synth">SYNTH</button>
                </div>
            </div>

            <div class="playlist-panel" id="playlist-container">
                <!-- Playlist items injected here -->
            </div>

            <div class="status-footer" id="status-footer">
                SCANNING LOCAL DIRECTORY SYSTEMS...
            </div>
        `;

        // Event Hooking
        document.getElementById('btn-play').addEventListener('click', togglePlayback);
        document.getElementById('btn-prev').addEventListener('click', playPrev);
        document.getElementById('btn-next').addEventListener('click', playNext);
        document.getElementById('btn-shuffle').addEventListener('click', toggleShuffle);
        document.getElementById('btn-repeat').addEventListener('click', toggleRepeat);
        
        document.getElementById('seek-container').addEventListener('click', handleSeek);
        
        const volSlider = document.getElementById('volume-slider');
        volSlider.addEventListener('input', (e) => {
            const val = e.target.value / 100;
            localAudio.volume = val;
            streamAudio.volume = val;
        });

        // Tabs
        document.getElementById('tab-c-drive').addEventListener('click', () => switchTab('c_drive'));
        document.getElementById('tab-satellite').addEventListener('click', () => switchTab('satellite'));
        document.getElementById('tab-synth').addEventListener('click', () => switchTab('synth'));

        // Local Audio events
        localAudio.addEventListener('timeupdate', updateProgress);
        localAudio.addEventListener('ended', handleTrackEnded);
        localAudio.addEventListener('loadedmetadata', () => {
            if (activeTab === 'c_drive') {
                document.getElementById('time-total').innerText = formatTime(localAudio.duration);
            }
        });

        // Stream Audio events
        streamAudio.addEventListener('timeupdate', updateProgress);
        streamAudio.addEventListener('ended', handleTrackEnded);
        streamAudio.addEventListener('loadedmetadata', () => {
            if (activeTab === 'satellite') {
                document.getElementById('time-total').innerText = formatTime(streamAudio.duration);
            }
        });

        // Register WebKit iOS Bridge Callback
        window.onMP3ListReceived = function(mp3Files) {
            if (activeTab !== 'c_drive') return;
            
            if (!mp3Files || mp3Files.length === 0) {
                renderNoFilesFound();
            } else {
                playlist = mp3Files;
                renderPlaylist();
                document.getElementById('status-footer').innerText = `FOUND ${playlist.length} AUDIO NODES ON DISK`;
            }
        };

        // Initial scan after a short delay to ensure bridge initialization
        setTimeout(scanLocalDrive, 150);
    }

    // Format seconds into MM:SS
    function formatTime(secs) {
        if (isNaN(secs) || !isFinite(secs)) return "00:00";
        const m = Math.floor(secs / 60);
        const s = Math.floor(secs % 60);
        return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
    }

    // Switch between storage segments
    function switchTab(tab) {
        if (activeTab === tab) return;
        
        // Stop current audio/synth
        stopAllPlayback();

        activeTab = tab;
        document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
        document.getElementById(`tab-${tab.replace('_', '-')}`).classList.add('active');

        if (tab === 'c_drive') {
            scanLocalDrive();
        } else if (tab === 'satellite') {
            loadSatellitePlaylist();
        } else if (tab === 'synth') {
            loadSynthPlaylist();
        }
    }

    // Stop both HTML Audio types and Web Synth
    function stopAllPlayback() {
        localAudio.pause();
        localAudio.src = '';
        streamAudio.pause();
        streamAudio.src = '';
        stopProceduralSynth();
        
        document.getElementById('btn-play').innerText = '▶';
        document.getElementById('track-title').innerText = 'NO TRACK LOADED';
        document.getElementById('track-status').innerText = 'STANDBY';
        document.getElementById('seek-bar').style.width = '0%';
        document.getElementById('time-current').innerText = '00:00';
        document.getElementById('time-total').innerText = '00:00';
    }

    // Directory listing in C_Drive via Swift Bridge
    function scanLocalDrive() {
        const container = document.getElementById('playlist-container');
        container.innerHTML = `<div class="empty-state">SCANNING DRIVE SEGMENTS...</div>`;
        document.getElementById('status-footer').innerText = "QUERYING SYSTEM DIRECTORY CLUSTERS...";

        playlist = [];
        currentTrackIndex = -1;

        if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.darkOSFileSystemBridge) {
            window.webkit.messageHandlers.darkOSFileSystemBridge.postMessage({ action: 'listMP3' });
        } else {
            // Fallback for browser tests
            setTimeout(() => {
                renderNoFilesFound();
            }, 800);
        }
    }

    // No files found message
    function renderNoFilesFound() {
        const container = document.getElementById('playlist-container');
        container.innerHTML = `
            <div class="empty-state">
                <p>NO LOCAL MP3 STORAGE IDENTIFIED INSIDE C_DRIVE.</p>
                <p style="font-size:9px; opacity:0.6;">IMPORT SONG FILES VIA NATIVE FILE EXPLORER SYSTEM.</p>
                <button class="empty-state-btn" id="btn-demo-mode">SWITCH TO SATELLITE STREAMS</button>
            </div>
        `;
        document.getElementById('status-footer').innerText = "DRIVE ACCESS STATUS: EMPTY OR RESTRICTED";
        
        const btnDemo = document.getElementById('btn-demo-mode');
        if (btnDemo) {
            btnDemo.addEventListener('click', () => switchTab('satellite'));
        }
    }

    // Load satellite stream playlist
    function loadSatellitePlaylist() {
        playlist = satelliteStreams;
        currentTrackIndex = -1;
        renderPlaylist();
        document.getElementById('status-footer').innerText = "STREAM CHANNELS DEPLOYED";
    }

    // Load synth playlist
    function loadSynthPlaylist() {
        playlist = [
            { name: "DARK_OS_PROCEDURAL_BEAT [SYNTH]", url: "procedural_synth" }
        ];
        currentTrackIndex = 0;
        renderPlaylist();
        document.getElementById('status-footer').innerText = "OFFLINE RETRO SYNTH VECTOR ACTIVE";
        
        // Select track
        selectTrack(0);
    }

    // Render tracks list
    function renderPlaylist() {
        const container = document.getElementById('playlist-container');
        container.innerHTML = '';

        playlist.forEach((track, index) => {
            const item = document.createElement('div');
            item.className = 'playlist-item';
            if (index === currentTrackIndex) item.classList.add('playing');
            
            const titleDisplay = track.name.toUpperCase().replace(/\.MP3$/, '');
            const isTrackActive = index === currentTrackIndex && (synthPlaying || !getCurrentAudio().paused);
            
            item.innerHTML = `
                <div class="playlist-item-left">
                    <span class="playlist-item-index">${String(index + 1).padStart(2, '0')}</span>
                    <span class="playlist-item-name">${titleDisplay}</span>
                </div>
                ${isTrackActive ? `
                    <div class="eq-sim">
                        <div class="eq-bar"></div>
                        <div class="eq-bar"></div>
                        <div class="eq-bar"></div>
                    </div>
                ` : `<span>${activeTab === 'c_drive' ? 'DISK' : 'NET'}</span>`}
            `;
            
            item.addEventListener('click', () => selectTrack(index));
            container.appendChild(item);
        });
    }

    // Select track to play
    function selectTrack(index) {
        if (index < 0 || index >= playlist.length) return;
        
        currentTrackIndex = index;
        const track = playlist[index];

        // Highlight playing track
        renderPlaylist();

        document.getElementById('track-title').innerText = track.name.toUpperCase().replace(/\.MP3$/, '');
        
        if (activeTab === 'synth') {
            localAudio.pause();
            localAudio.src = '';
            streamAudio.pause();
            streamAudio.src = '';
            document.getElementById('track-status').innerText = "SYNTH GENERATOR SYNCHRONIZED";
            document.getElementById('time-total').innerText = "INFINITY";
            playProceduralSynth();
        } else {
            stopProceduralSynth();
            
            const activeAudio = getCurrentAudio();
            const inactiveAudio = activeTab === 'satellite' ? localAudio : streamAudio;
            
            inactiveAudio.pause();
            inactiveAudio.removeAttribute('src');
            inactiveAudio.load();
            
            activeAudio.src = track.url;
            activeAudio.load();
            activeAudio.play()
                .then(() => {
                    document.getElementById('btn-play').innerText = '⏸';
                    document.getElementById('track-status').innerText = "PLAYING STREAM SIGNAL";
                    setupVisualizer();
                })
                .catch(err => {
                    console.error("Audio playback error:", err);
                    document.getElementById('track-status').innerText = "STREAM CORRUPT OR LOAD FAIL";
                });
        }
    }

    // Play/Pause button
    function togglePlayback() {
        if (playlist.length === 0) return;
        
        if (currentTrackIndex === -1) {
            selectTrack(0);
            return;
        }

        if (activeTab === 'synth') {
            if (synthPlaying) {
                stopProceduralSynth();
                document.getElementById('btn-play').innerText = '▶';
                document.getElementById('track-status').innerText = "SYNTH STANDBY";
            } else {
                playProceduralSynth();
                document.getElementById('btn-play').innerText = '⏸';
                document.getElementById('track-status').innerText = "SYNTH SEQUENCE LIVE";
            }
            renderPlaylist();
            return;
        }

        const audio = getCurrentAudio();
        if (audio.paused) {
            audio.play()
                .then(() => {
                    document.getElementById('btn-play').innerText = '⏸';
                    document.getElementById('track-status').innerText = "PLAYING STREAM SIGNAL";
                    setupVisualizer();
                })
                .catch(err => {
                    console.error("Play failed:", err);
                });
        } else {
            audio.pause();
            document.getElementById('btn-play').innerText = '▶';
            document.getElementById('track-status').innerText = "PAUSED";
        }
        renderPlaylist();
    }

    // Play next track
    function playNext() {
        if (playlist.length === 0) return;
        
        if (isShuffled) {
            const nextIndex = Math.floor(Math.random() * playlist.length);
            selectTrack(nextIndex);
        } else {
            let nextIndex = currentTrackIndex + 1;
            if (nextIndex >= playlist.length) {
                nextIndex = 0; // Wrap around
            }
            selectTrack(nextIndex);
        }
    }

    // Play previous track
    function playPrev() {
        if (playlist.length === 0) return;
        
        let prevIndex = currentTrackIndex - 1;
        if (prevIndex < 0) {
            prevIndex = playlist.length - 1; // Wrap around
        }
        selectTrack(prevIndex);
    }

    // Shuffle state toggle
    function toggleShuffle() {
        isShuffled = !isShuffled;
        const btn = document.getElementById('btn-shuffle');
        if (isShuffled) {
            btn.classList.add('active');
        } else {
            btn.classList.remove('active');
        }
    }

    // Repeat mode cycle
    function toggleRepeat() {
        const btn = document.getElementById('btn-repeat');
        btn.classList.remove('active');

        if (repeatMode === 'none') {
            repeatMode = 'all';
            btn.innerText = '🔁';
            btn.classList.add('active');
            btn.style.opacity = '1';
        } else if (repeatMode === 'all') {
            repeatMode = 'one';
            btn.innerText = '🔂';
            btn.classList.add('active');
            btn.style.opacity = '1';
        } else {
            repeatMode = 'none';
            btn.innerText = '🔁';
            btn.style.opacity = '0.5';
        }
    }

    // Auto-advance track end
    function handleTrackEnded() {
        if (repeatMode === 'one') {
            const audio = getCurrentAudio();
            audio.currentTime = 0;
            audio.play();
        } else if (repeatMode === 'all') {
            playNext();
        } else {
            if (currentTrackIndex < playlist.length - 1) {
                playNext();
            } else {
                stopAllPlayback();
            }
        }
    }

    // Update progress bar
    function updateProgress() {
        if (activeTab === 'synth') return;
        const audio = getCurrentAudio();
        const current = audio.currentTime;
        const total = audio.duration;
        if (isNaN(total) || !isFinite(total)) return;

        const pct = (current / total) * 100;
        document.getElementById('seek-bar').style.width = `${pct}%`;
        document.getElementById('time-current').innerText = formatTime(current);
    }

    // Seek track
    function handleSeek(e) {
        if (activeTab === 'synth' || playlist.length === 0 || currentTrackIndex === -1) return;
        const rect = e.target.getBoundingClientRect();
        const clickX = e.clientX - rect.left;
        const width = rect.width;
        const pct = clickX / width;
        
        const audio = getCurrentAudio();
        if (!isNaN(audio.duration) && isFinite(audio.duration)) {
            audio.currentTime = pct * audio.duration;
        }
    }

    // Setup visualizer canvas
    function setupVisualizer() {
        if (isVisualizerSetup) return;

        const canvas = document.getElementById('canvas-visualizer');
        const ctx = canvas.getContext('2d');
        
        function resize() {
            canvas.width = canvas.clientWidth;
            canvas.height = canvas.clientHeight;
        }
        resize();
        window.addEventListener('resize', resize);

        // Web Audio API setup: ONLY capture localAudio to prevent CORS blocks on streams!
        try {
            if (!audioCtx) {
                audioCtx = new (window.AudioContext || window.webkitAudioContext)();
                analyser = audioCtx.createAnalyser();
                analyser.fftSize = 64;
                
                sourceNode = audioCtx.createMediaElementSource(localAudio);
                sourceNode.connect(analyser);
                analyser.connect(audioCtx.destination);
            }
        } catch (e) {
            console.warn("Visualizer hook blocked:", e);
        }

        const bufferLength = analyser ? analyser.frequencyBinCount : 32;
        const dataArray = new Uint8Array(bufferLength);

        function draw() {
            visualizerAnimFrame = requestAnimationFrame(draw);
            
            ctx.clearRect(0, 0, canvas.width, canvas.height);

            const isPlaying = (activeTab === 'synth' && synthPlaying) || (activeTab === 'c_drive' && !localAudio.paused) || (activeTab === 'satellite' && !streamAudio.paused);

            if (analyser && isPlaying && activeTab === 'c_drive') {
                try {
                    analyser.getByteFrequencyData(dataArray);
                } catch(e) {
                    simulateWaveData();
                }
            } else if (isPlaying) {
                simulateWaveData();
            } else {
                for (let i = 0; i < bufferLength; i++) {
                    dataArray[i] = 10;
                }
            }

            function simulateWaveData() {
                const now = Date.now() * 0.003;
                for (let i = 0; i < bufferLength; i++) {
                    const factor = activeTab === 'synth' ? (synthStep % 8 === 0 ? 0.9 : 0.4) : 0.6;
                    dataArray[i] = Math.abs(Math.sin(i * 0.3 + now)) * 180 * factor + Math.random() * 20;
                }
            }

            // Draw glowing bars
            const barWidth = (canvas.width / bufferLength) * 1.5;
            let barHeight;
            let x = 0;

            for (let i = 0; i < bufferLength; i++) {
                barHeight = (dataArray[i] / 255) * canvas.height;

                // Cyber red neon gradient
                ctx.fillStyle = `rgba(255, 0, 85, ${0.35 + (barHeight / canvas.height) * 0.65})`;
                ctx.fillRect(x, canvas.height - barHeight, barWidth - 2, barHeight);

                // Peak line
                ctx.fillStyle = '#ff0055';
                ctx.fillRect(x, canvas.height - barHeight - 1, barWidth - 2, 1);

                x += barWidth;
            }
        }
        
        draw();
        isVisualizerSetup = true;
    }

    // --- PROCEDURAL RETRO-SYNTH ENGINE ---
    function playProceduralSynth() {
        if (synthPlaying) return;
        
        if (!audioCtx) {
            audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        }
        if (audioCtx.state === 'suspended') {
            audioCtx.resume();
        }

        synthPlaying = true;
        synthStep = 0;
        document.getElementById('btn-play').innerText = '⏸';
        document.getElementById('track-status').innerText = 'RETRO SEQUENCE LIVE';
        
        setupVisualizer();

        const intervalMs = (60 / synthTempo) / 4 * 1000;
        
        synthInterval = setInterval(() => {
            triggerSynthStep(synthStep);
            synthStep = (synthStep + 1) % 16;
            
            const secElapsed = Math.floor((synthStep * intervalMs) / 1000);
            document.getElementById('time-current').innerText = formatTime(secElapsed + (Math.floor(Date.now() / 1000) % 60));
        }, intervalMs);
    }

    function stopProceduralSynth() {
        synthPlaying = false;
        if (synthInterval) {
            clearInterval(synthInterval);
            synthInterval = null;
        }
    }

    function triggerSynthStep(step) {
        if (!audioCtx || audioCtx.state === 'suspended') return;
        const now = audioCtx.currentTime;
        const volumeVal = document.getElementById('volume-slider').value / 100;

        // 1. Synth Bass
        const bassScale = [65.41, 77.78, 98.00, 116.54];
        if (step % 2 === 0) {
            const osc = audioCtx.createOscillator();
            const gain = audioCtx.createGain();
            
            osc.type = 'sawtooth';
            const scaleIndex = Math.floor(step / 4) % bassScale.length;
            osc.frequency.setValueAtTime(bassScale[scaleIndex], now);
            
            gain.gain.setValueAtTime(volumeVal * 0.15, now);
            gain.gain.exponentialRampToValueAtTime(0.01, now + 0.15);
            
            osc.connect(gain);
            gain.connect(audioCtx.destination);
            
            osc.start(now);
            osc.stop(now + 0.15);
        }

        // 2. Kick Drum
        if (step % 4 === 0) {
            const kickOsc = audioCtx.createOscillator();
            const kickGain = audioCtx.createGain();
            
            kickOsc.frequency.setValueAtTime(150, now);
            kickOsc.frequency.exponentialRampToValueAtTime(0.01, now + 0.2);
            
            kickGain.gain.setValueAtTime(volumeVal * 0.5, now);
            kickGain.gain.exponentialRampToValueAtTime(0.01, now + 0.25);
            
            kickOsc.connect(kickGain);
            kickGain.connect(audioCtx.destination);
            
            kickOsc.start(now);
            kickOsc.stop(now + 0.25);
        }

        // 3. Melody Arpeggio
        const leadScale = [261.63, 311.13, 392.00, 466.16, 523.25];
        if (step % 8 === 2 || step % 8 === 5 || step % 16 === 11) {
            const leadOsc = audioCtx.createOscillator();
            const leadGain = audioCtx.createGain();
            
            leadOsc.type = 'triangle';
            const noteFreq = leadScale[Math.floor(Math.sin(step) * 5) % leadScale.length];
            leadOsc.frequency.setValueAtTime(noteFreq, now);
            
            leadGain.gain.setValueAtTime(volumeVal * 0.18, now);
            leadGain.gain.exponentialRampToValueAtTime(0.001, now + 0.35);
            
            leadOsc.connect(leadGain);
            leadGain.connect(audioCtx.destination);
            
            leadOsc.start(now);
            leadOsc.stop(now + 0.4);
        }

        // 4. Snare Drum
        if (step === 4 || step === 12) {
            const bufferSize = audioCtx.sampleRate * 0.12;
            const buffer = audioCtx.createBuffer(1, bufferSize, audioCtx.sampleRate);
            const data = buffer.getChannelData(0);
            
            for (let i = 0; i < bufferSize; i++) {
                data[i] = Math.random() * 2 - 1;
            }
            
            const noiseNode = audioCtx.createBufferSource();
            noiseNode.buffer = buffer;
            
            const filter = audioCtx.createBiquadFilter();
            filter.type = 'highpass';
            filter.frequency.value = 1000;
            
            const noiseGain = audioCtx.createGain();
            noiseGain.gain.setValueAtTime(volumeVal * 0.22, now);
            noiseGain.gain.exponentialRampToValueAtTime(0.01, now + 0.12);
            
            noiseNode.connect(filter);
            filter.connect(noiseGain);
            noiseGain.connect(audioCtx.destination);
            
            noiseNode.start(now);
            noiseNode.stop(now + 0.12);
        }
    }

    // Initialization
    buildUI();
    setupVisualizer();
})();
