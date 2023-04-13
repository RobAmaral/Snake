-- Importa a biblioteca LÖVE
love = require("love")


local size = 225 -- Tamanho da tela (em px)
local divider = 1 -- >=1 ou <=.9 (pra multiplicar)

game = {}
game.width = math.floor(size/divider) -- Largura da janela do jogo
game.height = game.width -- Altura da janela do jogo
game.title = "Snake, uma cobra muito maluka" -- Título da janela do jogo
game.score = 0 -- Pontuação atual do jogador
game.highscore = 0 -- Pontuação máxima
game.cellSize = 15

function love.load()
    -- Configura a janela do jogo
    love.window.setTitle(game.title)
    love.window.setMode(game.width, game.height)
    gridXCount = math.floor(game.width/game.cellSize)
    gridYCount = gridXCount
    
    function music()
        -- Obter a lista de arquivos na pasta "music"
        local musicFiles = love.filesystem.getDirectoryItems("music")
        
        -- Selecionar um arquivo aleatoriamente
        local randomIndex = love.math.random(1, #musicFiles)
        local randomMusic = musicFiles[randomIndex]
        player = love.audio.newSource("music/" .. randomMusic, "stream")
        player:play()
    end

    volume = .5
    music()
    

    -- Função que cria a comida
    function moveFood()
        local possibleFoodPositions = {}

        for foodX = 1, gridXCount do
            for foodY = 1, gridYCount do
                local possible = true

                for segmentIndex, segment in ipairs(snakeSegments) do
                    if foodX == segment.x and foodY == segment.y then
                        possible = false
                    end
                end

                if possible then
                    table.insert(possibleFoodPositions, {x = foodX, y = foodY})
                end
            end
        end

        foodPosition = possibleFoodPositions[
            love.math.random(#possibleFoodPositions)
        ]
    end

    -- Função que reinicia o jogo
    function reset()
        intX = math.ceil(gridXCount/2)
        intY = math.ceil(gridYCount/2)
        snakeSegments = {
            {x = intX, y = intY},
            {x = intX, y = intY},
            {x = intX, y = intY},
        }
        directionQueue = {'right'}
        snakeAlive = true
        timer = 0
        moveFood()
    end

    reset()
end

function love.update(dt)
    timer = timer + dt

    -- Muda a música 
    if not player:isPlaying() then
        music()
    end
    player:setVolume(volume)
    
    -- Movimentação do jogador
    if snakeAlive then
        if timer >= 0.13 then
            timer = 0

            if #directionQueue > 1 then
                table.remove(directionQueue, 1)
            end

            local nextXPosition = snakeSegments[1].x
            local nextYPosition = snakeSegments[1].y

            if directionQueue[1] == 'right' then
                nextXPosition = nextXPosition + 1
                if nextXPosition > gridXCount then
                    nextXPosition = 1
                end
            elseif directionQueue[1] == 'left' then
                nextXPosition = nextXPosition - 1
                if nextXPosition < 1 then
                    nextXPosition = gridXCount
                end
            elseif directionQueue[1] == 'down' then
                nextYPosition = nextYPosition + 1
                if nextYPosition > gridYCount then
                    nextYPosition = 1
                end
            elseif directionQueue[1] == 'up' then
                nextYPosition = nextYPosition - 1
                if nextYPosition < 1 then
                    nextYPosition = gridYCount
                end
            end

            local canMove = true

            for segmentIndex, segment in ipairs(snakeSegments) do
                if segmentIndex ~= #snakeSegments and nextXPosition == segment.x and nextYPosition == segment.y then
                    canMove = false
                end
            end

            -- Lógica de aumentar o tamanho do jogador
            if canMove then
                table.insert(snakeSegments, 1, {
                    x = nextXPosition, y = nextYPosition
                })

                if snakeSegments[1].x == foodPosition.x and snakeSegments[1].y == foodPosition.y then
                    moveFood()
                    local eat = love.audio.newSource("FX/eating.mp3", "stream")
                    eat:setVolume(volume)
                    eat:play()
                    game.score = game.score + 1
                else
                    table.remove(snakeSegments)
                end
            else
                snakeAlive = false
            end
        end
    elseif timer >= 2 then
        reset()
    end
end

function love.keypressed(key)
    if key == 'right'
    and directionQueue[#directionQueue] ~= 'right' and directionQueue[#directionQueue] ~= 'left' then
        table.insert(directionQueue, 'right')

    elseif key == 'left'
    and directionQueue[#directionQueue] ~= 'left' and directionQueue[#directionQueue] ~= 'right' then
        table.insert(directionQueue, 'left')

    elseif key == 'up'
    and directionQueue[#directionQueue] ~= 'up' and directionQueue[#directionQueue] ~= 'down' then
        table.insert(directionQueue, 'up')

    elseif key == 'down'
    and directionQueue[#directionQueue] ~= 'down' and directionQueue[#directionQueue] ~= 'up' then
        table.insert(directionQueue, 'down')

    elseif key == 'pageup' then
        if volume < 0.9 then
            volume = volume + .1
        end
    elseif key == 'pagedown' then
        if volume > 0.2 then
            volume = volume - .1
        end
    elseif key == 'm' then
        if volume ~= 0 then
            volRam = volume
            volume = 0
        else
            volume = volRam
        end
    end
end

function love.draw()
    
    love.graphics.setNewFont((game.width/gridXCount)*0.7)
    local cellSize = game.cellSize

    -- Desenha o fundo
    love.graphics.setColor(.28, .28, .28)
    love.graphics.rectangle('fill', 0, 0, gridXCount * (cellSize+1), gridYCount * (cellSize+1))


    local function drawCell(x, y)
        love.graphics.rectangle('fill', (x - 1) * cellSize, (y - 1) * cellSize, cellSize - 1, cellSize - 1)
    end

    -- Desenha a comida
    local function drawCellFood(x, y)
        love.graphics.circle('fill', (x-.5) * cellSize, (y-.5) * cellSize, math.ceil(cellSize/2), math.ceil(cellSize/2))
        love.graphics.setColor(.7, .3, .3)
        love.graphics.circle('fill', (x-.5) * cellSize, (y-.5) * cellSize, math.ceil(cellSize/4), math.ceil(cellSize/4))
    end

    -- Desenha a cobra
    for segmentIndex, segment in ipairs(snakeSegments) do
        if snakeAlive and segmentIndex == 1 then
            love.graphics.setColor(.6, .7, .32)
        elseif snakeAlive then
            love.graphics.setColor(.7, 1, .32)
        else
            love.graphics.setColor(.5, .5, .5)
        end
        drawCell(segment.x, segment.y)
    end

    love.graphics.setColor(1, .3, .3)
    drawCellFood(foodPosition.x, foodPosition.y)

    -- Desenhar pontuação
    if snakeAlive then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Score: " .. game.score, 1, 1)
        if game.score >= game.highscore then
            game.highscore = game.score
            if game.highscore ~= 0 then
                love.graphics.print("Highscore: " .. game.highscore .. " !", math.floor(game.width-(game.cellSize*5)), 1)
            end
        end
    else
        game.score = 0
    end
    love.graphics.print("Volume: " .. volume*100 .. "%", 1, math.ceil(game.height-(game.cellSize*1.2)))
    love.graphics.setNewFont((game.width/gridXCount)*0.5)
    love.graphics.print("Pg Up   =   Vol + \nPg Down = Vol -\nM = Mute", math.ceil(game.width-(game.cellSize*4)), math.ceil(game.height-(game.cellSize*1.7)))
end