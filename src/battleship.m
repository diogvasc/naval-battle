function battleship
    fig = figure('Name', 'Navios que se afundam', 'NumberTitle', 'off', 'Resize', 'off', 'Position', [100, 100, 680, 500],'CloseRequestFcn', @stopMusicAndClose); % Cria a janela da interface do jogo
    gridSize = 10;
    depthSize = 3;
    buttonSize = [30, 30]; 
    playerBoard = zeros(gridSize, gridSize, depthSize);
    computerBoard = zeros(gridSize, depthSize);
	playerButtons = gobjects(gridSize, gridSize); 
    computerButtons = gobjects(gridSize, gridSize);
    shipSizes = [5, 4, 3, 2, 2]; 
    currentShipSizeIndex = 1;
    shipOrientation = 'horizontal'; 
    numPlayerShips = 0;
    statusText = uicontrol('Style', 'text', 'Position', [30, 430, 590, 40], 'Parent', fig);
    startingPlayer = '';
	aiAttackMode = 'Caça'; 
    aiShotMatrix = zeros(gridSize, gridSize, depthSize);
    global audioData audioFs; 
    global waterSound bombSound; 
    startScreen();

    % Função para tocar música de fundo   
    function playBackgroundMusic()
        persistent isLoaded; 
        if isempty(isLoaded)
            audioFilePath = 'Menu.mp3';
            if ~isfile(audioFilePath)
                error('O ficheiro áudio não foi encontrado: %s', audioFilePath);
            end
            [audioData, audioFs] = audioread(audioFilePath);
            isLoaded = true; % Marca como carregado após a primeira vez
        end
        volumeFactor = 0.1;
        audioDataVolumeAdjusted = audioData * volumeFactor;
        player = audioplayer(audioDataVolumeAdjusted, audioFs);
        set(player, 'StopFcn', @(src, event)play(src));
        play(player);
        set(fig, 'UserData', player);
    end
    
    % Função para parar a música e fechar o jogo
    function stopMusicAndClose(src, event)
        player = get(fig, 'UserData');
        if ~isempty(player) && isvalid(player)
            stop(player);
        end
        delete(gcf);
    end

    % Função para criar a tela inicial
    function startScreen()
        clf(fig); % Limpa a janela para exibir a tela inicial
        playBackgroundMusic();
    
        % Carrega e redimensiona a imagem de fundo
        bg = imread('Battle_Menu_IMG.jpg');
        bgResized = imresize(bg, [500, 650]); % Ajusta para 500x650 pixels
    
        % Cria e posiciona o plano de fundo
        ax = axes('Parent', fig, 'Position', [0 0 1 1]);
        imagesc(ax, bgResized);
        axis(ax, 'off'); % Oculta os eixos
        uistack(ax, 'bottom'); % Envia o fundo para trás dos outros elementos
    
        % Elementos da interface da tela inicial
        uicontrol('Style', 'text', 'String', 'Welcome to Battleship!', 'Position', [190, 0, 300, 30], 'FontSize', 20, 'Parent', fig, 'BackgroundColor', [0.678, 0.847, 0.902], 'ForegroundColor', [0, 0, 0]);
        uicontrol('Style', 'pushbutton', 'String', 'Start Game', 'Position', [290, 220, 100, 40], 'Callback', @initializeGame, 'Parent', fig, 'BackgroundColor', [0.678, 0.847, 0.902], 'ForegroundColor', [0, 0, 0]);
        uicontrol('Style', 'pushbutton', 'String', 'Exit Game', 'Position', [290, 170, 100, 40], 'Callback', @(src, event)close(fig), 'Parent', fig, 'BackgroundColor', [0.678, 0.847, 0.902], 'ForegroundColor', [0, 0, 0]);
    end

    % Função para inicializar o jogo
    function initializeGame(~, ~)
    clf(fig); % Limpa a interface para reiniciar o jogo

    % Define número de camadas (níveis de profundidade) para o jogo 3D
    numLayers = 3; % você pode ajustar esse valor conforme quiser

    % Reinicia os tabuleiros como 3D (linha x coluna x camada)
    playerBoard = zeros(gridSize, gridSize, numLayers);
    computerBoard = zeros(gridSize, gridSize, numLayers);
    aiShotMatrix = zeros(gridSize, gridSize, numLayers);
    aiAttackMode = 'hunt';

    currentLayer = 1; % Define a camada atual visível

    numPlayerShips = 0;
    currentShipSizeIndex = 1; 
    shipOrientation = 'horizontal';

    % Carrega os sons e cria os objetos de áudio
    [y1, Fs1] = audioread('wasser.mp3');
    waterSound = audioplayer(y1, Fs1);

    [y2, Fs2] = audioread('bomb.mp3');
    bombSound = audioplayer(y2, Fs2);

    setupGameUI(); % Cria a interface de jogo
    placeComputerShips(); % Posiciona os navios do computador
    decideStartingPlayer(); % Decide quem começa
end

    
    % Função para decidir quem começa sem atacar
    function decideStartingPlayer()
        if rand < 0.5
            startingPlayer = 'player';
            updateStatus('Começa o jogo. Coloca a tua nave de 5 quadrados.');
        else
            startingPlayer = 'computer';
            updateStatus('O computador começa. Por favor, coloquem a vossa nave de 5 quadrados.');
        end
    end
    
    % Função para criar a interface do jogo
    function setupGameUI()
        % Texto de status na parte superior
        statusText = uicontrol('Style', 'text', 'String', 'Colocar os navios (5 necessários).', 'Position', [30, 450, 590, 40], 'FontSize', 12, 'Parent', fig);
    
        % Títulos dos tabuleiros
        uicontrol('Style', 'text', 'String', 'Campo de jogos', 'Position', [30, 430, 300, 20], 'Parent', fig);
        uicontrol('Style', 'text', 'String', 'Campo AI', 'Position', [350, 430, 300, 20], 'Parent', fig);
    
        % Criação dos botões dos dois tabuleiros
        for i = 1:gridSize
            for j = 1:gridSize
                playerButtons(i, j) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [30+(j-1)*buttonSize(1), 380-(i-1)*buttonSize(2), buttonSize(1), buttonSize(2)], 'Parent', fig, 'Callback', {@playerBoardCallback, i, j});
                computerButtons(i, j) = uicontrol('Style', 'pushbutton', 'String', '', 'Position', [350+(j-1)*buttonSize(1), 380-(i-1)*buttonSize(2), buttonSize(1), buttonSize(2)], 'Parent', fig, 'Callback', {@computerBoardCallback, i, j}, 'Enable', 'off');
            end
        end

        % Botões de reinício e saída
        uicontrol('Style', 'pushbutton', 'String', 'Reiniciar', 'Position', [30, 20, 100, 30], 'Parent', fig, 'Callback', @(src,event)startScreen());
        uicontrol('Style', 'pushbutton', 'String', 'Fim do jogo', 'Position', [140, 20, 100, 30], 'Parent', fig, 'Callback', @(src, event)close(fig));
    
        % Botões para definir a orientação dos navios
        uicontrol('Style', 'pushbutton', 'String', 'Horizontal', 'Position', [350, 20, 100, 30], 'Parent', fig, 'Callback', @(src,event)setOrientation('horizontal'));
        uicontrol('Style', 'pushbutton', 'String', 'Vertical', 'Position', [460, 20, 100, 30], 'Parent', fig, 'Callback', @(src,event)setOrientation('vertical'));
    end
    
    

    % Define a orientação do navio
    function setOrientation(orientation)
        shipOrientation = orientation;
        updateStatus(sprintf('Alinhamento definido para %s. Colocar a nave.', orientation));
    end
    
    % Função para posicionar navios do jogador
    function playerBoardCallback(~, ~, row, col)
        if numPlayerShips >= length(shipSizes)
            updateStatus('Todos os navios já foram colocados.');
            return;
        end
        shipSize = shipSizes(currentShipSizeIndex);
        if strcmp(shipOrientation, 'horizontal')
            if col + shipSize - 1 > gridSize || ~isSpaceFree(playerBoard, row, col, shipSize, 1)
                updateStatus('A embarcação não cabe nesta posição (horizontal) ou o espaço já está ocupado.');
                return;
            end
            for i = 0:(shipSize - 1)
                playerBoard(row, col + i) = 1;
                set(playerButtons(row, col + i), 'String', 'S', 'Enable', 'off', 'BackgroundColor', [0.5, 1, 0.5]);
            end
        else
            if row + shipSize - 1 > gridSize || ~isSpaceFree(playerBoard, row, col, shipSize, 2)
                updateStatus('A embarcação não cabe nesta posição (vertical) ou o espaço já está ocupado.');
                return;
            end
            for i = 0:(shipSize - 1)
                playerBoard(row + i, col) = 1;
                set(playerButtons(row + i, col), 'String', 'S', 'Enable', 'off', 'BackgroundColor', [0.5, 1, 0.5]);
            end
        end
        numPlayerShips = numPlayerShips + 1;
        if numPlayerShips == length(shipSizes)
            updateStatus('Todos os navios colocados. Esperar pelo adversário.');
            for i = 1:numel(playerButtons)
                if strcmp(get(playerButtons(i), 'String'), 'S')
                    set(findall(fig, 'String', 'Horizontal'), 'Visible', 'off');
                    set(findall(fig, 'String', 'Vertikal'), 'Visible', 'off');
                end
            end
            set(arrayfun(@(x) x, computerButtons), 'Enable', 'on');
            if strcmp(startingPlayer, 'computer')
                updateStatus('O adversário começa. Esperar pelo adversário.');
                pause(1);
                computerAttack(); 
            else 
                updateStatus('Todos os navios colocados. É a vossa vez de disparar.');
            end
        else
            currentShipSizeIndex = currentShipSizeIndex + 1;
            updateStatus(sprintf('Colocar os campos %d no navio.', shipSizes(currentShipSizeIndex)));
        end
    end

    % Função para tratar os ataques no campo do computador
    function computerBoardCallback(src, ~, row, col)
        set(src, 'Enable', 'off');
        if computerBoard(row, col) == 0
            computerBoard(row, col) = 3;
            set(src, 'String', '~', 'BackgroundColor', [0.678, 0.847, 0.902]);
            updateStatus('Falhaste!');
            play(waterSound);
            computerAttack();
        elseif computerBoard(row, col) == 1
            computerBoard(row, col) = 2;
            set(src, 'String', 'X', 'ForegroundColor', 'white', 'BackgroundColor', 'red');
            updateStatus('Acertaste!');
            play(bombSound);
            if checkWin(computerBoard)
                updateStatus('O jogador ganha! Todos os navios afundados.');
                disableBoard(computerButtons);
                showVictoryScreen('Jogador');
            end
        end
    end
    
    % Função para colocar navios do computador
    function placeComputerShips()
        shipSizes = [5, 4, 3, 2, 2];
        for shipSize = shipSizes
            placed = false;
            while ~placed
                orientation = randi([1, 2]);
                if orientation == 1
                    row = randi(gridSize);
                    col = randi([1, gridSize - shipSize + 1]);
                else
                    row = randi([1, gridSize - shipSize + 1]);
                    col = randi(gridSize);
                end
            
                if isSpaceFree(computerBoard, row, col, shipSize, orientation)
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

    % Função para verificar se o espaço está livre
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

    % Função para o ataque do computador
function computerAttack()
    try
        pause(1);
        [row, col, depth] = findBestMove();
        if playerBoard(row, col) <= 1
            if playerBoard(row, col, depth) == 1
                playerBoard(row, col, depth) = 2; % Marcar como acerto
                aiShotMatrix(row, col, depth) = 1; % IA: Acertou, mas ainda não afundou
                set(playerButtons(row, col, depth), 'String', 'X', 'ForegroundColor', 'white', 'BackgroundColor', 'red');
                updateStatus('O computador foi atingido!');
                play(bombSound); % Toca o som de acerto
                pause(2); % Pausa de 2 segundos
                if checkWin(playerBoard)
                    updateStatus('O computador ganha! Todos os navios foram afundados.');
                    disableBoard(playerButtons);
                    showVictoryScreen('Computer');
                else
                    aiAttackMode = 'target';
                    computerAttack();
                end
            else
                playerBoard(row, col, depth) = 3; % Marcar como erro
                aiShotMatrix(row, col, depth) = 9; % IA: Erro
                set(playerButtons(row, col, depth), 'String', '~', 'BackgroundColor', [0.678, 0.847, 0.902]); % Azul claro
                updateStatus('O computador falhou.');
                play(waterSound); % Toca o som de erro
                pause(1); % Pausa de 1 segundo
            end
        else
            computerAttack();
        end
    catch
        % Evita spam de erro caso o programa seja encerrado prematuramente
    end
end

% Função para o movimento de caça ou alvo
function [row, col, depth] = findBestMove()
    if strcmp(aiAttackMode, 'Caça')

        % No modo Caça, selecionar posições aleatórias no padrão de tabuleiro de xadrez
        foundValidMove = false;
        while ~foundValidMove
            depth = randi(depthSize);
            row = randi(gridSize); % Seleciona uma linha aleatória
            if mod(row, 2) == 0 % Se a linha for par
                col = round(randi([2, gridSize])/2)*2; % Seleciona uma coluna par entre 2 e gridSize
            else
                col = round((randi([1, gridSize-1])-1)/2)*2 + 1; % Seleciona uma coluna ímpar entre 1 e gridSize-1
            end
            % Verifica se a célula já foi atacada
            if aiShotMatrix(row, col, depth) == 0
                foundValidMove = true; % Movimento válido encontrado
            end
        end
    else
        % No modo Alvo, procurar por navios atingidos
        [row, col, depth] = findTarget();
    end
end

% Função para o modo Alvo
function [row, col] = findTarget()
    % Procurar todas as células com acerto (valor 1) na aiShotMatrix
    [hitRows, hitCols] = find(aiShotMatrix == 1);
    
    % Inicializa uma lista vazia para armazenar todas as células vizinhas válidas
    allLegalNeighboringCells = [];
    
    for i = 1:length(hitRows)
        hitRow = hitRows(i);
        hitCol = hitCols(i);
        
        % Determinar células vizinhas
        neighboringCells = [];
        % Verifica Norte
        if hitRow > 1 && aiShotMatrix(hitRow - 1, hitCol) == 0
            neighboringCells = [neighboringCells; hitRow - 1, hitCol];
        end
        % Verifica Sul
        if hitRow < gridSize && aiShotMatrix(hitRow + 1, hitCol) == 0
            neighboringCells = [neighboringCells; hitRow + 1, hitCol];
        end
        % Verifica Oeste
        if hitCol > 1 && aiShotMatrix(hitRow, hitCol - 1) == 0
            neighboringCells = [neighboringCells; hitRow, hitCol - 1];
        end
        % Verifica Leste
        if hitCol < gridSize && aiShotMatrix(hitRow, hitCol + 1) == 0
            neighboringCells = [neighboringCells; hitRow, hitCol + 1];
        end
        
        % Adiciona células vizinhas válidas à lista
        allLegalNeighboringCells = [allLegalNeighboringCells; neighboringCells];
    end
    
    % Se houver células vizinhas válidas, escolher uma aleatoriamente
    if ~isempty(allLegalNeighboringCells)
        randomIndex = randi(size(allLegalNeighboringCells, 1));
        row = allLegalNeighboringCells(randomIndex, 1);
        col = allLegalNeighboringCells(randomIndex, 2);
    else
        % Se não houver vizinhos válidos, volta para o modo Caça
        aiAttackMode = 'Caça';
        [row, col] = findBestMove(); % Disparo aleatório no modo Caça
    end
end

% Função para verificar quem venceu
function win = checkWin(board)
    win = all(board(:) ~= 1); % Condição de vitória: nenhum 1 restante no tabuleiro
end

% Função para desativar os botões do tabuleiro
function disableBoard(buttons)
    for i = 1:numel(buttons)
        set(buttons(i), 'Enable', 'off');
    end
end

% Função para atualizar a mensagem de status
function updateStatus(message)
    set(statusText, 'String', message);
end

% Função para mostrar a tela de vitória
function showVictoryScreen(winner)
    clf(fig); % Limpa a janela da figura
    
    % Carrega e ajusta a imagem de fundo para o tamanho da janela
    bg = imread('Endscreen.png');
    bgResized = imresize(bg, [500, 650]); % Redimensiona a imagem para 500x650 pixels

    % Cria um eixo que preenche a figura
    ax = axes('Parent', fig, 'Position', [0 0 1 1]);
    imagesc(ax, bgResized);
    axis(ax, 'off'); % Oculta eixos e rótulos
    uistack(ax, 'bottom'); % Envia o eixo para o fundo

    % Mensagem centralizada de vitória com fonte maior
    uicontrol('Style', 'text', 'String', sprintf('%s Ganha!', winner), ...
              'Position', [100, 250, 450, 60], 'FontSize', 20, ...
              'FontWeight', 'bold', 'Parent', fig, ...
              'HorizontalAlignment', 'center', 'BackgroundColor', 'none', ...
              'ForegroundColor', [1, 1, 1]);

    % Botão para iniciar novo jogo
    uicontrol('Style', 'pushbutton', 'String', 'Novo jogo', ...
              'Position', [265, 170, 150, 50], 'FontSize', 12, ...
              'Parent', fig, 'Callback', @(src,event)startScreen(), ...
              'BackgroundColor', [0, 0, 0, 0.5], 'ForegroundColor', [1, 1, 1]);

    % Botão para encerrar o jogo
    uicontrol('Style', 'pushbutton', 'String', 'Fim do jogo', ...
              'Position', [265, 110, 150, 50], 'FontSize', 12, ...
              'Parent', fig, 'Callback', @(src, event)close(fig), ...
              'BackgroundColor', [0, 0, 0, 0.5], 'ForegroundColor', [1, 1, 1]);
    end
end