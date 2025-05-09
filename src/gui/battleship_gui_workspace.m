function battleship_gui_workspace
    fig = figure('Name', 'Schiffe Versenken', 'NumberTitle', 'off', 'Resize', 'off', 'Position', [100, 100, 680, 500],'CloseRequestFcn', @stopMusicAndClose); % Erstellt GUI Fenster für das Spiel
    gridSize = 10; % Definiert die Spielfeldgrösse
    buttonSize = [30, 30]; % Definiert die Buttongrösse
    playerBoard = zeros(gridSize); % Definiert die grösse des Spielerfelds
    computerBoard = zeros(gridSize); % Definert die grösse des Computerfelds
	playerButtons = gobjects(gridSize, gridSize); % Definiert die Buttons für das Spielerfeld 
    computerButtons = gobjects(gridSize, gridSize);% Definiert die Buttons für das Computerfeld
    shipSizes = [5, 4, 3, 2, 2]; % Unterschiedliche Schiffsgrößen für Spieler und Computer
    currentShipSizeIndex = 1; % So verfolgen Sie, welche Schiffsgröße der Spieler gerade platziert
    shipOrientation = 'horizontal'; % Standardausrichtung
    numPlayerShips = 0;
    statusText = uicontrol('Style', 'text', 'Position', [30, 430, 590, 40], 'Parent', fig);
    startingPlayer = ''; % Wird entweder auf 'Spieler' oder 'Computer' gesetzt
	aiAttackMode = 'hunt'; % KI-Modus (Hunt/Target)
    aiShotMatrix = zeros(gridSize); % Matrix, um den Status der Felder zu verfolgen
    global audioData audioFs; % Globale Variablen für Audio-Daten und Sampling-Frequenz
    global waterSound bombSound; % Globale Variabeln für Treffer und Miss Sound
    startScreen();

    % Funktion für die Hintergrundmusik    
    function playBackgroundMusic()
        persistent isLoaded; % Persistente Variable, um den Ladezustand zu speichern
        if isempty(isLoaded)
            audioFilePath = 'Menu.mp3';
            if ~isfile(audioFilePath)
                error('Die Audiodatei wurde nicht gefunden: %s', audioFilePath);
            end
            [audioData, audioFs] = audioread(audioFilePath);
            isLoaded = true; % Setze isLoaded nach dem ersten Laden
        end
        volumeFactor = 0.1;
        audioDataVolumeAdjusted = audioData * volumeFactor;
        player = audioplayer(audioDataVolumeAdjusted, audioFs);
        set(player, 'StopFcn', @(src, event)play(src));
        play(player);
        set(fig, 'UserData', player);
    end
    
    % Funktion um die Musik zu Starten und zu stoppen 
    function stopMusicAndClose(src, event)
        player = get(fig, 'UserData');
        if ~isempty(player) && isvalid(player)
            stop(player);
        end
        delete(gcf);
    end

    % Funktion für das erstellen des Startmenüs
    function startScreen()
        clf(fig); % Löschen des Objekts Figure für den Startbildschirm
        playBackgroundMusic();
    
        % Laden und Anpassen des Hintergrundbildes an die Größe der Figur
        bg = imread('Titlescreen.jpg');
        bgResized = imresize(bg, [500, 650]); % Größe des Bildes auf 500x650 Pixel ändern
    
        % Achsen erstellen, die die Abbildung ausfüllen
        ax = axes('Parent', fig, 'Position', [0 0 1 1]);
        imagesc(ax, bgResized);
        axis(ax, 'off'); % Achsenlinien und Beschriftungen ausschalten
        uistack(ax, 'bottom'); % Senden der Achsen an die unterste Ebene
    
        % UI-Elemente für den Startbildschirm
        uicontrol('Style', 'text', 'String', 'Welcome to Battleship!', 'Position', [190, 0, 300, 30], 'FontSize', 20, 'Parent', fig, 'BackgroundColor', [0.678, 0.847, 0.902], 'ForegroundColor', [0, 0, 0]);
        % Zentral ausgerichtete "Spiel starten"-Taste
        uicontrol('Style', 'pushbutton', 'String', 'Start Game', 'Position', [290, 220, 100, 40], 'Callback', @initializeGame, 'Parent', fig, 'BackgroundColor', [0.678, 0.847, 0.902], 'ForegroundColor', [0, 0, 0]);
        % Zentral ausgerichtete Schaltfläche "Spiel beenden".
        uicontrol('Style', 'pushbutton', 'String', 'Exit Game', 'Position', [290, 170, 100, 40], 'Callback', @(src, event)close(fig), 'Parent', fig, 'BackgroundColor', [0.678, 0.847, 0.902], 'ForegroundColor', [0, 0, 0]);
    end

    % Funktion für die Spielinizialisierung
    function initializeGame(~, ~)
        clf(fig); % Bereinige das Figure-Objekt, um die UI zurückzusetzen

        % Setze die Spielbretter zurück
        playerBoard = zeros(gridSize);
        computerBoard = zeros(gridSize);
		aiShotMatrix = zeros(gridSize);
        aiAttackMode = 'hunt';

        numPlayerShips = 0; % Setze die Schiffsplatzierungsvariablen zurück
        currentShipSizeIndex = 1; % Zurück zum ersten Schiff
        shipOrientation = 'horizontal'; % Standardorientierung zurücksetzen

        % Laden der Soundeffekte und Initialisieren der audioplayer-Objekte
        [y1, Fs1] = audioread('wasser.mp3');
        waterSound = audioplayer(y1, Fs1);

        [y2, Fs2] = audioread('bomb.mp3');
        bombSound = audioplayer(y2, Fs2);

        setupGameUI(); % Initialisiere die Spiel-UI neu
        placeComputerShips(); % Platziere die Schiffe des Computers neu
        decideStartingPlayer(); % Entscheide neu, wer das Spiel beginnt
    end
    
    % Entscheiden, wer beginnt, ohne einen Angriff zu starten    
    function decideStartingPlayer()
        if rand < 0.5
            startingPlayer = 'player';
            updateStatus('Du beginnst das Spiel. Platziere dein 5-Felder Schiff.');
        else
            startingPlayer = 'computer';
            updateStatus('Der Computer beginnt. Bitte platziere dein 5-Felder Schiff.');
        end
    end
    
    % Funktion um das Interface des Spiels zu Starten
    function setupGameUI()
        % Statustext am oberen Rand für klare Sichtbarkeit
        statusText = uicontrol('Style', 'text', 'String', 'Platziere deine Schiffe (5 benötigt).', 'Position', [30, 450, 590, 40], 'FontSize', 12, 'Parent', fig);
    
        % Anpassen der Platzierung von Spieler- und Computergittern für eine bessere optische Trennung
        % Spielerraster
        uicontrol('Style', 'text', 'String', 'Spielfeld', 'Position', [30, 430, 300, 20], 'Parent', fig);
        % Computerraster
        uicontrol('Style', 'text', 'String', 'Computerfeld', 'Position', [350, 430, 300, 20], 'Parent', fig);
    
        % Buttons für Spieler und Computer erstellen
        for i = 1:gridSize
            for j = 1:gridSize
                playerButtons(i, j) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [30+(j-1)*buttonSize(1), 380-(i-1)*buttonSize(2), buttonSize(1), buttonSize(2)], 'Parent', fig, 'Callback', {@playerBoardCallback, i, j});
                computerButtons(i, j) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [350+(j-1)*buttonSize(1), 380-(i-1)*buttonSize(2), buttonSize(1), buttonSize(2)], 'Parent', fig, 'Callback', {@computerBoardCallback, i, j}, 'Enable', 'off');
            end
        end

        % Erzeugen von Schaltflächen für Spieler- und Computergitter
        uicontrol('Style', 'pushbutton', 'String', 'Neustart', 'Position', [30, 20, 100, 30], 'Parent', fig, 'Callback', @(src,event)startScreen());
        uicontrol('Style', 'pushbutton', 'String', 'Spiel beenden', 'Position', [140, 20, 100, 30], 'Parent', fig, 'Callback', @(src, event)close(fig));
    
        % Orientierungsschaltflächen für die Platzierung von Schiffen
        uicontrol('Style', 'pushbutton', 'String', 'Horizontal', 'Position', [350, 20, 100, 30], 'Parent', fig, 'Callback', @(src,event)setOrientation('horizontal'));
        uicontrol('Style', 'pushbutton', 'String', 'Vertikal', 'Position', [460, 20, 100, 30], 'Parent', fig, 'Callback', @(src,event)setOrientation('vertical'));
    end

    % Funktion für die Orientierung des Schiffs
    function setOrientation(orientation)
        shipOrientation = orientation;
        updateStatus(sprintf('Ausrichtung gesetzt zu %s. Platziere dein Schiff.', orientation));
    end
    
    % Funktion für  das Spielerfeld 
    function playerBoardCallback(~, ~, row, col)
        % Überprüfe, ob wir noch Schiffe zu platzieren haben
        if numPlayerShips >= length(shipSizes)
            updateStatus('Alle Schiffe sind bereits platziert.');
            return;
        end
        shipSize = shipSizes(currentShipSizeIndex); % Aktuelle Schiffgröße
        if strcmp(shipOrientation, 'horizontal')
            % Überprüfe, ob das Schiff horizontal platziert werden kann
            if col + shipSize - 1 > gridSize || ~isSpaceFree(playerBoard, row, col, shipSize, 1)
                updateStatus('Schiff passt nicht in diese Position (horizontal) oder Platz ist bereits belegt.');
                return;
            end
            % Platziere das Schiff
            for i = 0:(shipSize - 1)
                playerBoard(row, col + i) = 1;
                set(playerButtons(row, col + i), 'String', 'S', 'Enable', 'off', 'BackgroundColor', [0.5, 1, 0.5]);
            end
        else
            % Überprüfe, ob das Schiff vertikal platziert werden kann
            if row + shipSize - 1 > gridSize || ~isSpaceFree(playerBoard, row, col, shipSize, 2)
                updateStatus('Schiff passt nicht in diese Position (vertikal) oder Platz ist bereits belegt.');
                return;
            end
            % Platziere das Schiff
            for i = 0:(shipSize - 1)
                playerBoard(row + i, col) = 1;
                set(playerButtons(row + i, col), 'String', 'S', 'Enable', 'off', 'BackgroundColor', [0.5, 1, 0.5]);
            end
        end
        % Aktualisiere die Anzahl der platzierten Schiffe
        numPlayerShips = numPlayerShips + 1;
        if numPlayerShips == length(shipSizes)
            updateStatus('Alle Schiffe platziert. Warte auf den Gegner.');
            % Mache alle platzierten Schiffbuttons unsichtbar
            for i = 1:numel(playerButtons)
                if strcmp(get(playerButtons(i), 'String'), 'S')
                    set(findall(fig, 'String', 'Horizontal'), 'Visible', 'off');
                    set(findall(fig, 'String', 'Vertikal'), 'Visible', 'off');
                end
            end
            set(arrayfun(@(x) x, computerButtons), 'Enable', 'on');
            if strcmp(startingPlayer, 'computer')
                updateStatus('Der Gegner beginnt. Warte auf den Gegner.');
                pause(1); % Kurze Verzögerung
                computerAttack(); % Der Computer startet seinen Angriff
            else 
                updateStatus('Alle Schiffe platziert. Du bist dran mit Schiessen.');
            end
        else
            currentShipSizeIndex = currentShipSizeIndex + 1;
            updateStatus(sprintf('Platziere dein %d-Felder Schiff.', shipSizes(currentShipSizeIndex)));
        end
    end

    % Funktion für das Computerspielfeld
    function computerBoardCallback(src, ~, row, col)
        set(src, 'Enable', 'off'); % Deaktivieren Sie die Schaltfläche, um Mehrfachklicks zu verhindern.
        if computerBoard(row, col) == 0
            computerBoard(row, col) = 3; % Miss
            set(src, 'String', '~', 'BackgroundColor', [0.678, 0.847, 0.902]); % Light blue
            updateStatus('Fehlschuss!');
            play(waterSound); % Spielt den Fehlschusssound
            computerAttack(); % Jetzt ist der Computer an der Reihe
        elseif computerBoard(row, col) == 1
            computerBoard(row, col) = 2; % Hit
            set(src, 'String', 'X', 'ForegroundColor', 'white', 'BackgroundColor', 'red');
            updateStatus('Treffer!');
            play(bombSound); % Spielt den Treffersound
            if checkWin(computerBoard)
                updateStatus('Spieler gewinnt! Alle Schiffe versenkt.');
                disableBoard(computerButtons);
                showVictoryScreen('Spieler');
            end
        end
    end
    
    %Funktion um Computerschiffe zu platzieren
    function placeComputerShips()
        shipSizes = [5, 4, 3, 2, 2]; % Array von Schiffsgrößen
        for shipSize = shipSizes
            placed = false;
            while ~placed
                orientation = randi([1, 2]); % 1 for horizontal, 2 for vertical
                if orientation == 1 % Horizontal
                    row = randi(gridSize);
                    col = randi([1, gridSize - shipSize + 1]);
                else % Vertical
                    row = randi([1, gridSize - shipSize + 1]);
                    col = randi(gridSize);
                end
            
                % Prüfen, ob der Platz für das Schiff frei ist
                if isSpaceFree(computerBoard, row, col, shipSize, orientation)
                    % Platzieren Sie das Schiff
                    for i = 0:(shipSize - 1)
                        if orientation == 1
                            computerBoard(row, col + i) = 1;
                        else
                            computerBoard(row + i, col) = 1;
                        end
                    end
                    placed = true;
                end
            end
        end
    end

    function free = isSpaceFree(board, row, col, size, orientation)
        free = true;
        for i = 0:(size - 1)
            if orientation == 1
                if board(row, col + i) ~= 0
                    free = false;
                    break;
                end
            else
                if board(row + i, col) ~= 0
                    free = false;
                    break;
                end
            end
        end
    end

    % Funktion für den Computerangriff
    function computerAttack()
        try
            pause(1);
            [row, col] = findBestMove();
            if playerBoard(row, col) <= 1
                if playerBoard(row, col) == 1
                    playerBoard(row, col) = 2; % Mark as hit
                    aiShotMatrix(row, col) = 1; % KI: Angeschossen aber noch nicht versenkt
                    set(playerButtons(row, col), 'String', 'X', 'ForegroundColor', 'white', 'BackgroundColor', 'red');
                    updateStatus('Computer hat getroffen!');
                    play(bombSound); % Spielt den Treffersound
                    pause(2); % Delay of 2 seconds
                    if checkWin(playerBoard)
                        updateStatus('Computer gewinnt! Alle Schiffe versenkt.');
                        disableBoard(playerButtons);
                        showVictoryScreen('Computer');
                    else
                        aiAttackMode = 'target';
                        computerAttack();
                    end
                else
                    playerBoard(row, col) = 3; % Mark as miss
                    aiShotMatrix(row, col) = 9; % KI: Verfehlt
                    set(playerButtons(row, col), 'String', '~', 'BackgroundColor', [0.678, 0.847, 0.902]); % Light blue
                    updateStatus('Computer hat verfehlt.');
                    play(waterSound); % Spielt den Fehlschusssound
                    pause(1); % Delay of 2 seconds
                end
            else
                computerAttack();
            end
        catch
            % Verhindert einen Error-Spam im Falle einer frühzeitigen Programmschliessung
        end
    end


    % Funktion für den Hunt/Targetmove
    function [row, col] = findBestMove()
	    if strcmp(aiAttackMode, 'hunt')
		
		 % Im Hunt-Modus wähle zufällige Positionen im Schachbrettmuster
            foundValidMove = false;
            while ~foundValidMove
                row = randi(gridSize); % Wähle eine zufällige Zeile
                if mod(row, 2) == 0 % Wenn die Zeile gerade ist
                    col = round(randi([2, gridSize])/2)*2; % Wähle eine zufällige gerade Spalte zwischen 2 und gridSize
                else % Wenn die Zeile ungerade ist
                    col = round((randi([1, gridSize-1])-1)/2)*2 + 1; % Wähle eine zufällige ungerade Spalte zwischen 1 und gridSize-1
                end
                % Überprüfe, ob das Feld bereits angeschossen wurde
                if aiShotMatrix(row, col) == 0
                    foundValidMove = true; % Gültiger Zug gefunden
                end
            end
        else
            % Im Target-Modus suche nach angeschossenen Schiffen
            [row, col] = findTarget();
        end
    end
    
    
    % Funktion für den Targetmodus 
    function [row, col] = findTarget()
      % Suche nach allen Zellen mit einem Treffer (Wert 1) in der aiShotMatrix
        [hitRows, hitCols] = find(aiShotMatrix == 1);
        
        % Initialisierung einer leeren Liste zur Speicherung aller zulässigen Nachbarzellen
        allLegalNeighboringCells = [];
        
        %Initialisierung einer leeren Liste zur Speicherung aller zulässigen Nachbarzellen
        for i = 1:length(hitRows)
            hitRow = hitRows(i);
            hitCol = hitCols(i);
            
            % Bestimmen Sie benachbarte Zellen
            neighboringCells = [];
            % Check Norden
            if hitRow > 1 && aiShotMatrix(hitRow - 1, hitCol) == 0
                neighboringCells = [neighboringCells; hitRow - 1, hitCol];
            end
            % Check Süden
            if hitRow < gridSize && aiShotMatrix(hitRow + 1, hitCol) == 0
                neighboringCells = [neighboringCells; hitRow + 1, hitCol];
            end
            % Check Westen
            if hitCol > 1 && aiShotMatrix(hitRow, hitCol - 1) == 0
                neighboringCells = [neighboringCells; hitRow, hitCol - 1];
            end
            % Check Osten
            if hitCol < gridSize && aiShotMatrix(hitRow, hitCol + 1) == 0
                neighboringCells = [neighboringCells; hitRow, hitCol + 1];
            end
            
            % Hinzufügen legaler Nachbarzellen zur Liste
            allLegalNeighboringCells = [allLegalNeighboringCells; neighboringCells];
        end
        
        % Wenn es erlaubte benachbarte Zellen gibt, wähle eine zufällig aus
        if ~isempty(allLegalNeighboringCells)
            % Choose a random legal neighboring cell
            randomIndex = randi(size(allLegalNeighboringCells, 1));
            row = allLegalNeighboringCells(randomIndex, 1);
            col = allLegalNeighboringCells(randomIndex, 2);
        else
            % Wenn es keine zulässigen Nachbarzellen gibt, in den Jagdmodus wechseln
            aiAttackMode = 'hunt';
            [row, col] = findBestMove(); % Zufallsschuss im Hunt Modus abgeben
        end
    end

    %Funktion um festzustellen wer gewonnen hat
    function win = checkWin(board)
        win = all(board(:) ~= 1); % Siegbedingung: keine 1 mehr auf dem Brett
    end

    %Funktion um Buttons zu deaktivieren 
    function disableBoard(buttons)
        for i = 1:numel(buttons)
            set(buttons(i), 'Enable', 'off');
        end
    end

    % Funktion zum Update der Statusnachricht
    function updateStatus(message)
        set(statusText, 'String', message);
    end

    % Funktion zur erstellung des Victory Screens
    function showVictoryScreen(winner)
        clf(fig); % Löschen des Fensters Figure
        
        % Laden und Anpassen des Hintergrundbildes an die Größe der Figur
        bg = imread('Endscreen.png');
        bgResized = imresize(bg, [500, 650]); % Größe des Bildes auf 500x650 Pixel ändern
    
        % Create axes that fill the figure
        ax = axes('Parent', fig, 'Position', [0 0 1 1]);
        imagesc(ax, bgResized);
        axis(ax, 'off'); % Achsenlinien und Beschriftungen ausschalten
        uistack(ax, 'bottom'); % Senden der Achsen an die unterste Ebene
    
        % Centered victory message with larger font
        uicontrol('Style', 'text', 'String', sprintf('%s gewinnt!', winner), 'Position', [100, 250, 450, 60], 'FontSize', 20, 'FontWeight', 'bold', 'Parent', fig, 'HorizontalAlignment', 'center', 'BackgroundColor', 'none', 'ForegroundColor', [1, 1, 1]);
    
        % Zentrierte Siegesmeldung mit größerer Schrift
        uicontrol('Style', 'pushbutton', 'String', 'Neues Spiel', 'Position', [265, 170, 150, 50], 'FontSize', 12, 'Parent', fig, 'Callback', @(src,event)startScreen(), 'BackgroundColor', [0, 0, 0, 0.5], 'ForegroundColor', [1, 1, 1]);
    
        % Taste zum Beenden des Spiels
        uicontrol('Style', 'pushbutton', 'String', 'Spiel beenden', 'Position', [265, 110, 150, 50], 'FontSize', 12, 'Parent', fig, 'Callback', @(src, event)close(fig), 'BackgroundColor', [0, 0, 0, 0.5], 'ForegroundColor', [1, 1, 1]);
    end
end