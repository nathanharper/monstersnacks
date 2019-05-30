local dogbutt, loaf, grit
local loaves = {}
local grittys = {}
local stage = {
    width = 0,
    height = 0
}
local box = {
    x = 20,
    y = 50,
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
    draw_loaves()
    draw_grittys()
    draw_butt()
end

function love.update(dt)
    move_butt(dt)
    move_grittys(dt)

    if check_boundary() then
        return
    end

    detect_gritty_collisions()
    detect_loaf_collisions()
end

-- HELPER METHODS

function load_assets()
    dogbutt = love.graphics.newImage("images/dogbutt2.png")
    loaf = love.graphics.newImage("images/loaf.png")
    grit = love.graphics.newImage("images/grit2.jpg")
end

function draw_butt()
    love.graphics.draw(dogbutt, box.x, box.y)
    -- love.graphics.rectangle("fill", box.x, box.y, box.width, box.width)
end

function draw_loaves()
    for i=1, #loaves do
        love.graphics.draw(loaf, loaves[i].x, loaves[i].y)
    end
end

function draw_grittys()
    for i=1, #grittys do
        local gritty = grittys[i]

        love.graphics.draw(grit, gritty.x, gritty.y)
    end
end

function move_butt(dt)
    if love.keyboard.isDown("up") then
        box.y = box.y - dt * box.speed
    end

    if love.keyboard.isDown("down") then
        box.y = box.y + dt * box.speed
    end

    if love.keyboard.isDown("left") then
        box.x = box.x - dt * box.speed
    end

    if love.keyboard.isDown("right") then
        box.x = box.x + dt * box.speed
    end
end

function check_boundary()
    local buffer = box.width / 2

    if box.y < -buffer then
        change_room("bottom")
        return true
    end

    if box.y + box.width > stage.height + buffer then
        change_room("top")
        return true
    end

    if box.x < -buffer then
        change_room("right")
        return true
    end

    if box.x + box.width > stage.width + buffer then
        change_room("left")
        return true
    end

    return false
end

function change_room(position)
    local buffer = 5

    clear_room()

    if position == "top" then
        box.y = buffer
    elseif position == "bottom" then
        box.y = stage.height - box.width - buffer
    elseif position == "left" then
        box.x = buffer
    elseif position == "right" then
        box.x = stage.width - box.width - buffer
    end

    build_room()

    stats.rooms = stats.rooms + 1
    print(stats.rooms .. " rooms visited")
end

function build_room()
    local loaf_count = math.random(50)
    local gritty_count = math.random(3)

    for i=1, loaf_count do
        add_random_loaf()
    end

    for i=1, gritty_count do
        add_random_gritty()
    end
end

function add_random_loaf()
    local loaf_width = 35
    local buffer = 5

    loaves[#loaves+1] = {
        x = math.random(stage.width - loaf_width - buffer),
        y = math.random(stage.height - loaf_width - buffer),
        width = loaf_width
    }
end

function add_random_gritty()
    local dx, dy
    local speed = 100
    local gritty_width = 55
    local buffer = 5

    dx = speed
    dy = speed

    if math.random(2) == 2 then
        dx = -1 * dx
    end

    if math.random(2) == 2 then
        dy = -1 * dy
    end

    grittys[#grittys+1] = {
        x = math.random(stage.width - gritty_width - buffer),
        y = math.random(stage.height - gritty_width - buffer),
        width = gritty_width,
        dx = dx,
        dy = dy
    }
end

function move_grittys(dt)
    for i=1, #grittys do
        grittys[i].x = grittys[i].x + grittys[i].dx * dt
        grittys[i].y = grittys[i].y + grittys[i].dy * dt

        if grittys[i].x <= 0 or grittys[i].x + grittys[i].width >= stage.width then
            grittys[i].dx = -1 * grittys[i].dx
        end

        if grittys[i].y <= 0 or grittys[i].y + grittys[i].width >= stage.height then
            grittys[i].dy = -1 * grittys[i].dy
        end
    end
end

function clear_room()
    loaves = {}
    grittys = {}
end

function detect_loaf_collisions()
    local hits = {}

    for i=1, #loaves do
        local lorf = loaves[i]

        if check_collision(box.x,box.y,box.width,box.width, lorf.x,lorf.y,lorf.width,lorf.width) then
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

        if check_collision(box.x,box.y,box.width,box.width, gritty.x,gritty.y,gritty.width,gritty.width) then
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

        if check_collision(gritty.x,gritty.y,gritty.width,gritty.width, lorf.x,lorf.y,lorf.width,lorf.width) then
            hits[#hits+1] = i
        end
    end

    for i=#hits, 1, -1 do
        table.remove(loaves, hits[i])
        gritty.dx = gritty.dx * speedup
        gritty.dy = gritty.dy * speedup
    end

    stats.gritty_loaves = stats.gritty_loaves + #hits
end

function check_collision(x1,y1,w1,h1, x2,y2,w2,h2)
    return x1 < x2+w2 and x2 < x1+w1 and y1 < y2+h2 and y2 < y1+h1
end
