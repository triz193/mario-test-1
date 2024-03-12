--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- Match the colors for locks and keys
    local keyFrame = math.random(1, 4)
    local lockFrame = keyFrame + 4
    --setting the start mode key and lock
    local hasKey = false
    local hasLock = false

    local requiresKey = false

    -- Define the pillars table
    local pillars = {}

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        local isChasm = math.random(7) == 1
        
        if isChasm then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            if math.random(8) == 1 then
                blockHeight = 2
                -- Add pillar location to the list
                table.insert(pillars, { x = x, y = 5, height = blockHeight })
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false,
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
                
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false,
                    }
                )
            end

            -- chance to spawn a block
            if math.random(10) == 1 then
                table.insert(objects,

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,
                        requiresKey = false,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then

                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles

    -- Generate a random position for the key and the lock
    local keyX, keyY = 0, 0
    local lockX, lockY = 0, 0
    local keyPlaced = false
    local lockPlaced = false
    
    -- Define lists to keep track of valid locations for the key and lock
    local keyLocations = {}
    local lockLocations = {}

    -- Function to check if a given location is a pillar location
    function isPillarLocation(x, y, pillars)
        for _, pillar in pairs(pillars) do
            if x == pillar.x and y == pillar.y + pillar.height then
                return true
            end
        end
        return false
    end

    -- When deciding where to spawn a key or lock
    for x = 1, width do
        -- Check if the current tile is a ground tile and not a pillar location
        if tiles[height][x].id == TILE_ID_GROUND and not isPillarLocation(x, height, pillars) then
            table.insert(keyLocations, { x = x, y = height - 4 })
            table.insert(lockLocations, { x = x, y = height - 4 })
        end
    end
    

    --  select a location for the key (not a pillar)
    if #keyLocations > 0 then
        while true do
            local keyIndex = math.random(#keyLocations)
            keyX, keyY = keyLocations[keyIndex].x, keyLocations[keyIndex].y
            if not isPillarLocation(keyX, keyY, pillars) then
                keyPlaced = true
                break
            else
                table.remove(keyLocations, keyIndex)
                if #keyLocations == 0 then break end
            end
        end
    end

    --  select a location for the key (not a pillar)
    if #lockLocations > 0 then
        while true do
            local lockIndex = math.random(#lockLocations)
            lockX, lockY = lockLocations[lockIndex].x, lockLocations[lockIndex].y
            if not isPillarLocation(lockX, lockY, pillars) then
                lockPlaced = true
                break
            else
                table.remove(lockLocations, lockIndex)
                if #lockLocations == 0 then break end
            end
        end
    end

   
    -- Define lockObject with an empty onConsume function
    local lockObject = GameObject {
        texture = 'keys_locks',
        x = (lockX - 1) * TILE_SIZE,
        y = (lockY - 1) * TILE_SIZE,
        width = 16,
        height = 16,
        frame = lockFrame,
        collidable = true,
        consumable = true,
        solid = false,
        requiresKey = true,
        onConsume = function(player, object)
        end
    }

    -- Add the lock object to the objects table
    table.insert(objects, lockObject)

    -- Add the key to the objects table
    table.insert(objects,
        GameObject {
            texture = 'keys_locks',
            x = (keyX - 1) * TILE_SIZE,
            y = (keyY - 1) * TILE_SIZE,
            width = 16,
            height = 16,
            frame = keyFrame,
            collidable = true,
            consumable = true,
            solid = false,
            requiresKey = false,
            onConsume = function(player, object)
                gSounds['pickup']:play()  
                hasKey = true              
            end
        }
    )    
     
 
    
    -- Setting the new player starting coordinates
    local playerStartX, playerStartY = 0, 0
    --[[ Finding a suitable starting position for the player on solid ground
         by iterating over the width of the level and checking if the
         current tile and the tile to the right are both ground tiles]]
    for x = 1, width - 1 do
        if tiles[height][x].id == TILE_ID_GROUND and tiles[height][x + 1].id == TILE_ID_GROUND then
            playerStartX = x
            playerStartY = 0
            break
        end
    end

    return GameLevel(entities, objects, map, playerStartX, playerStartY)
end

