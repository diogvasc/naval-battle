function battleship_gui_v07
    fig = figure('Name', 'Schiffe Versenken', 'NumberTitle', 'off', 'Resize', 'off', 'Position', [100, 100, 650, 500]);
    gridSize = 10;
    buttonSize = [30, 30];
    playerBoard = zeros(gridSize);
    computerBoard = zeros(gridSize);
    playerButtons = gobjects(gridSize, gridSize);
    computerButtons = gobjects(gridSize, gridSize);
    shipSizes = [5, 4, 3, 2, 2]; % Array of ship sizes for both player and computer
    currentShipSizeIndex = 1; % To track which ship size the player is currently placing
    shipOrientation = 'horizontal'; % Default orientation
    numPlayerShips = 0;
    statusText = uicontrol('Style', 'text', 'Position', [30, 430, 590, 40], 'Parent', fig);
    startScreen();
    startingPlayer = ''; % Will be set to either 'player' or 'computer';
    computerShotStatus = zeros(gridSize);

    function startScreen()
        clf(fig); % Bereinige das Figure-Objekt für den Startbildschirm

        % Es könnte nützlich sein, hier zusätzliche Resets durchzuführen,
        % insbesondere wenn `startScreen` auf andere Weise aufgerufen werden kann,
        % die oben nicht abgedeckt sind.

        % UI-Elemente für den Startbildschirm
        uicontrol('Style', 'text', 'String', 'Willkommen zu Schiffe Versenken!', 'Position', [100, 300, 450, 40], 'FontSize', 16, 'Parent', fig);
        uicontrol('Style', 'pushbutton', 'String', 'Spiel starten', 'Position', [275, 200, 100, 40], 'Callback', @initializeGame, 'Parent', fig);
        uicontrol('Style', 'pushbutton', 'String', 'Spiel beenden', 'Position', [275, 150, 100, 40], 'Callback', @(src, event)close(fig), 'Parent', fig);
    end

    function initializeGame(~, ~)
        clf(fig); % Bereinige das Figure-Objekt, um die UI zurückzusetzen

        % Setze die Spielbretter zurück
        playerBoard = zeros(gridSize);
        computerBoard = zeros(gridSize);

        % Setze die Schiffsplatzierungsvariablen zurück
        numPlayerShips = 0;
        currentShipSizeIndex = 1; % Zurück zum ersten Schiff
        shipOrientation = 'horizontal'; % Standardorientierung zurücksetzen

        setupGameUI(); % Initialisiere die Spiel-UI neu
        placeComputerShips(); % Platziere die Schiffe des Computers neu
        decideStartingPlayer(); % Entscheide neu, wer das Spiel beginnt
    end
    
    % New function to decide who starts without initiating an attack
    function decideStartingPlayer()
        if rand < 0.5
            startingPlayer = 'player';
            updateStatus('Du beginnst das Spiel. Platziere deine Schiffe.');
        else
            startingPlayer = 'computer';
            updateStatus('Der Computer beginnt. Bitte platziere deine Schiffe.');
            % Do not start computer attack immediately
        end
    end

    function setupGameUI()
        statusText = uicontrol('Style', 'text', 'String', 'Platziere deine Schiffe (5 benötigt).', 'Position', [30, 430, 590, 40], 'Parent', fig);
        for i = 1:gridSize
            for j = 1:gridSize
                playerButtons(i, j) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [30+(j-1)*buttonSize(1), 360-(i-1)*buttonSize(2), buttonSize(1), buttonSize(2)], 'Parent', fig, 'Callback', {@playerBoardCallback, i, j});
                computerButtons(i, j) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [350+(j-1)*buttonSize(1), 360-(i-1)*buttonSize(2), buttonSize(1), buttonSize(2)], 'Parent', fig, 'Callback', {@computerBoardCallback, i, j}, 'Enable', 'off');
            end
        end
        uicontrol('Style', 'pushbutton', 'String', 'Neustart', 'Position', [30, 470, 100, 20], 'Parent', fig, 'Callback', @(src,event)startScreen());
        uicontrol('Style', 'pushbutton', 'String', 'Spiel beenden', 'Position', [140, 470, 100, 20], 'Parent', fig, 'Callback', @(src, event)close(fig));
        uicontrol('Style', 'text', 'String', sprintf('Spielerfeld'), 'Position', [30, 400, 300, 20], 'Parent', fig);
        uicontrol('Style', 'pushbutton', 'String', 'Horizontal', 'Position', [340, 400, 100, 20], 'Parent', fig, 'Callback', @(src,event)setOrientation('horizontal'));
        uicontrol('Style', 'pushbutton', 'String', 'Vertikal', 'Position', [450, 400, 100, 20], 'Parent', fig, 'Callback', @(src,event)setOrientation('vertical'));
    end

    function setOrientation(orientation)
        shipOrientation = orientation;
        updateStatus(sprintf('Ausrichtung gesetzt zu %s. Platziere dein Schiff.', orientation));
    end

    function playerBoardCallback(src, ~, row, col)
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
            set(arrayfun(@(x) x, computerButtons), 'Enable', 'on');
            if strcmp(startingPlayer, 'computer')
                pause(1); % Kurze Verzögerung
                computerAttack(); % Der Computer startet seinen Angriff
            end
        else
            currentShipSizeIndex = currentShipSizeIndex + 1;
            updateStatus(sprintf('Platziere dein %d-Felder Schiff.', shipSizes(currentShipSizeIndex)));
        end
    end
    
    function computerBoardCallback(src, ~, row, col)
        set(src, 'Enable', 'off'); % Disable the button to prevent multiple clicks
        if computerBoard(row, col) == 0
            computerBoard(row, col) = 3; % Miss
            set(src, 'String', '~', 'BackgroundColor', [0.678, 0.847, 0.902]); % Light blue
            updateStatus('Fehlschuss!');
            computerAttack(); % Now it's computer's turn
        elseif computerBoard(row, col) == 1
            computerBoard(row, col) = 2; % Hit
            set(src, 'String', 'X', 'ForegroundColor', 'white', 'BackgroundColor', 'red');
            updateStatus('Treffer!');
            % Do not call computerAttack here to allow for another player turn
            if checkWin(computerBoard)
                updateStatus('Spieler gewinnt! Alle Schiffe versenkt.');
                disableBoard(computerButtons);
                showVictoryScreen('Spieler');
            end
        end
        % No else condition needed for calling computerAttack, as it's called only on miss
    end



    function placeComputerShips()
        shipSizes = [5, 4, 3, 2, 2]; % Array of ship sizes
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
            
                % Check if the space is free for the ship
                if isSpaceFree(computerBoard, row, col, shipSize, orientation)
                    % Place the ship
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


    function computerAttack()
    [row, col] = findBestMove();
    if playerBoard(row, col) <= 1
        if playerBoard(row, col) == 1
            playerBoard(row, col) = 2; % Mark as hit
            set(playerButtons(row, col), 'String', 'X', 'ForegroundColor', 'white', 'BackgroundColor', 'red');
            updateStatus('Computer hat getroffen!');
            pause(2); % Delay of 2 seconds
            if checkWin(playerBoard)
                updateStatus('Computer gewinnt! Alle Schiffe versenkt.');
                disableBoard(playerButtons);
                showVictoryScreen('Computer');
            else
                computerAttack();
            end
        else
            playerBoard(row, col) = 3; % Mark as miss
            set(playerButtons(row, col), 'String', '~', 'BackgroundColor', [0.678, 0.847, 0.902]); % Light blue
            updateStatus('Computer hat verfehlt.');
            pause(2); % Delay of 2 seconds
        end
    else
        computerAttack();
    end
    % Aktualisierung des Schussstatus der Computer
    if playerBoard(row, col) == 2
        computerShotStatus(row, col) = 1; % Anschossen aber noch nicht versenkt
    else
        computerShotStatus(row, col) = 9; % Verfehlt
    end
end

function [row, col] = findBestMove()
    persistent mode; % Persistente Variable, um den Modus zwischen den Aufrufen zu speichern

    % Überprüfe, ob der Modus bereits festgelegt ist
    if isempty(mode)
        % Wenn nicht, setze den Modus auf 'hunt'
        mode = 'hunt';
    end
    
    % Überprüfe, ob der Modus gewechselt werden soll
    if any(computerShotStatus(:) == 1) % Wenn irgendwo im computerShotStatus eine 1 zu finden ist
        mode = 'target'; % Wechsel zum Target-Modus
    else
        mode = 'hunt'; % Andernfalls bleibe im Hunt-Modus
    end

    if strcmp(mode, 'hunt')
        % Im Hunt-Modus wähle zufällige Positionen im Schachbrettmuster
        row = randi(gridSize); % Wähle eine zufällige Zeile
        if mod(row, 2) == 0 % Wenn die Zeile gerade ist
            col = round(randi([2, gridSize])/2)*2; % Wähle eine zufällige gerade Spalte zwischen 2 und gridSize
        else % Wenn die Zeile ungerade ist
            col = round((randi([1, gridSize-1])-1)/2)*2 + 1; % Wähle eine zufällige ungerade Spalte zwischen 1 und gridSize-1
        end
    else
        % Im Target-Modus suche nach angeschossenen Schiffen
        [row, col] = findTarget();
    end
end



function [row, col] = findTarget()
    % Waiting for Francesco to implement sinking ship logic
    row = randi(gridSize);
    col = randi(gridSize);
end


    function win = checkWin(board)
        win = all(board(:) ~= 1); % Win condition: no '1's left on the board
    end

    function disableBoard(buttons)
        for i = 1:numel(buttons)
            set(buttons(i), 'Enable', 'off');
        end
    end

    function updateStatus(message)
        set(statusText, 'String', message);
    end

    function showVictoryScreen(winner)
        clf(fig);
        message = sprintf('%s gewinnt!', winner);
        uicontrol('Style', 'text', 'String', message, 'Position', [100, 300, 450, 40], 'FontSize', 16, 'Parent', fig);
        uicontrol('Style', 'pushbutton', 'String', 'Neues Spiel', 'Position', [275, 200, 100, 40], 'Callback', @(src,event)startScreen(), 'Parent', fig);
        uicontrol('Style', 'pushbutton', 'String', 'Spiel beenden', 'Position', [275, 150, 100, 40], 'Callback', @(src, event)close(fig), 'Parent', fig);
        %Shiplacement muss zurückgesetzt werden/ reset global variables
    end
end


