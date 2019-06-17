local vector = require "hump.vector"

local dogbutt, loaf, grit
local loaves = {}
local grittys = {}
local loaf_width = 35
local stage = {
    width = 0,
    height = 0
}
local butt = {
    pos = vector(20, 50),
    width = 60,
    speed = 200
}
local stats = {
    loaves = 0,
    gritty_loaves = 0,
    rooms = 1
}

-- LOVE METHODS

function love.load()
    math.randomseed(os.time())
    stage.width, stage.height = love.graphics.getDimensions()

    load_assets()
    build_room()
end

function love.draw()
    -- draw_background()
    draw_loaves()
    draw_grittys()
    draw_butt()
end

function love.keyreleased(key)
    if key == "space" then
        drop_snack()
    end
end

function love.update(dt)
    move_butt(dt)
    move_grittys(dt)

    if check_boundary() then
        return
    end

    detect_gritty_collisions()
    -- detect_loaf_collisions()
end

-- HELPER METHODS

function load_assets()
    dogbutt = love.graphics.newImage("images/dogbutt2.png")
    loaf = love.graphics.newImage("images/loaf.png")
    grit = love.graphics.newImage("images/grit2.jpg")
    background = love.graphics.newImage("images/pride.png")
end

function draw_background()
    for i=0, love.graphics.getWidth() / background:getWidth() do
        for j=0, love.graphics.getHeight() / background:getHeight() do
            love.graphics.draw(background, i * background:getWidth(), j * background:getHeight())
        end
    end
end

function draw_butt()
    love.graphics.draw(dogbutt, butt.pos.x, butt.pos.y)
    -- love.graphics.rectangle("fill", butt.pos.x, butt.pos.y, butt.width, butt.width)
end

function draw_loaves()
    for i=1, #loaves do
        love.graphics.draw(loaf, loaves[i].pos.x, loaves[i].pos.y)
    end
end

function draw_grittys()
    for i=1, #grittys do
        local gritty = grittys[i]

        love.graphics.draw(grit, gritty.pos.x, gritty.pos.y)
    end
end

function move_butt(dt)
    local delta = vector(0, 0)

    if love.keyboard.isDown("up") then
        delta.y = -1
    elseif love.keyboard.isDown("down") then
        delta.y = 1
    end

    if love.keyboard.isDown("left") then
        delta.x = -1
    elseif love.keyboard.isDown("right") then
        delta.x = 1
    end

    butt.pos = butt.pos + butt.speed * dt * delta
end

function check_boundary()
    local buffer = butt.width / 2

    if butt.pos.y < -buffer then
        change_room("bottom")
        return true
    end

    if butt.pos.y + butt.width > stage.height + buffer then
        change_room("top")
        return true
    end

    if butt.pos.x < -buffer then
        change_room("right")
        return true
    end

    if butt.pos.x + butt.width > stage.width + buffer then
        change_room("left")
        return true
    end

    return false
end

function change_room(position)
    local buffer = 5

    clear_room()

    if position == "top" then
        butt.pos.y = buffer
    elseif position == "bottom" then
        butt.pos.y = stage.height - butt.width - buffer
    elseif position == "left" then
        butt.pos.x = buffer
    elseif position == "right" then
        butt.pos.x = stage.width - butt.width - buffer
    end

    build_room()

    stats.rooms = stats.rooms + 1
    print(stats.rooms .. " rooms visited")
end

function build_room()
    local loaf_count = 0 -- math.random(50)
    local gritty_count = math.random(3)

    for i=1, loaf_count do
        add_random_loaf()
    end

    for i=1, gritty_count do
        add_random_gritty()
    end
end

function add_loaf(x, y)
    loaves[#loaves+1] = {
        pos = vector(x, y),
        width = loaf_width
    }
end

function add_random_loaf()
    local buffer = 5

    add_loaf(
        math.random(stage.width - loaf_width - buffer),
        math.random(stage.height - loaf_width - buffer)
    )
end

function add_random_gritty()
    local speed = 100
    local gritty_width = 55
    local buffer = 5

    grittys[#grittys+1] = {
        pos = vector(
            math.random(stage.width - gritty_width - buffer),
            math.random(stage.height - gritty_width - buffer)
        ),
        width = gritty_width,
        delta = vector.randomDirection(),
        speed = speed
    }
end

function move_grittys(dt)
    if #loaves == 0 then
        for i=1, #grittys do
            local gritty = grittys[i]

            gritty.pos = gritty.pos + gritty.delta * gritty.speed * dt

            if (gritty.pos.x <= 0 and gritty.delta.x < 0)
                or (gritty.pos.x + gritty.width >= stage.width and gritty.delta.x > 0)
            then
                gritty.delta.x = -1 * gritty.delta.x
            end

            if (gritty.pos.y <= 0 and gritty.delta.y < 0)
                or (gritty.pos.y + gritty.width >= stage.height and gritty.delta.y > 0)
            then
                gritty.delta.y = -1 * gritty.delta.y
            end
        end
    else
        for i=1, #grittys do
            local gritty = grittys[i]
            local snak = find_closest_snack(gritty)

            gritty.delta = (snak.pos - gritty.pos):normalized()
            gritty.pos = gritty.pos + gritty.delta * gritty.speed * dt
        end
    end
end

function find_closest_snack(gritty)
    local closest = nil
    local shortest_distance = nil

    for i=1, #loaves do
        local snak = loaves[i]
        local distance = gritty.pos:dist(snak.pos)

        if closest == nil or distance < shortest_distance then
            closest = snak
            shortest_distance = distance
        end
    end

    return closest
end

function clear_room()
    loaves = {}
    grittys = {}
end

function detect_loaf_collisions()
    local hits = {}

    for i=1, #loaves do
        local lorf = loaves[i]

        if check_collision(butt.pos,butt.width,butt.width, lorf.pos,lorf.width,lorf.width) then
            hits[#hits+1] = i
        end
    end

    for i=#hits, 1, -1 do
        table.remove(loaves, hits[i])
    end

    stats.loaves = stats.loaves + #hits

    if #hits > 0 then
        print("Loaves collected: " .. stats.loaves)
    end
end

function detect_gritty_collisions()
    for i=1, #grittys do
        local gritty = grittys[i]

        if check_collision(butt.pos,butt.width,butt.width, gritty.pos,gritty.width,gritty.width) then
            print "hitty gritty"
        end

        detect_gritty_loaf_collisions(gritty)
    end
end

function detect_gritty_loaf_collisions(gritty)
    local hits = {}
    local speedup = 1.2

    for i=1, #loaves do
        local lorf = loaves[i]

        if check_collision(gritty.pos,gritty.width,gritty.width, lorf.pos,lorf.width,lorf.width) then
            hits[#hits+1] = i
        end
    end

    for i=#hits, 1, -1 do
        table.remove(loaves, hits[i])
        gritty.speed = gritty.speed * speedup
    end

    stats.gritty_loaves = stats.gritty_loaves + #hits
end

function check_collision(pos1,w1,h1, pos2,w2,h2)
    return pos1.x < pos2.x+w2 and pos2.x < pos1.x+w1 and pos1.y < pos2.y+h2 and pos2.y < pos1.y+h1
end

function drop_snack()
    local offset = (butt.width / 2) - (loaf_width / 2)
    add_loaf(butt.pos.x + offset, butt.pos.y + offset)
end
