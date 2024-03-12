--[[
    GD50
    Super Mario Bros. Remake

    -- GameLevel Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

GameLevel = Class{}

function GameLevel:init(entities, objects, tilemap, playerStartX, playerStartY)

    self.entities = entities
    self.objects = objects
    self.tileMap = tilemap
    self.playerStartX = playerStartX
    self.playerStartY = playerStartY
end

--[[
    Remove all nil references from tables in case they've set themselves to nil.
]]
function GameLevel:clear()
    for i = #self.objects, 1, -1 do
        if not self.objects[i] then
            table.remove(self.objects, i)
        end
    end

    for i = #self.entities, 1, -1 do
        if not self.objects[i] then
            table.remove(self.objects, i)
        end
    end
end

function GameLevel:update(dt)
    self.tileMap:update(dt)

    for k, object in pairs(self.objects) do
        object:update(dt)
    end

    for k, entity in pairs(self.entities) do
        entity:update(dt)
    end
end

function GameLevel:render()
    self.tileMap:render()

    for k, object in pairs(self.objects) do
        if object.texture == 'keys_locks' then
            if object.frame >= 1 and object.frame <= 4 then
                -- Key frame, draw key
                love.graphics.draw(gTextures[object.texture], gFrames['keys_locks'][object.frame], object.x, object.y)
            elseif object.frame >= 5 and object.frame <= 8 then
                -- Lock frame, draw lock
                love.graphics.draw(gTextures[object.texture], gFrames['keys_locks'][object.frame], object.x, object.y)
            else
                -- Invalid frame, draw default
                object:render()
            end
        else
            object:render()
        end
    end

    for k, entity in pairs(self.entities) do
        entity:render()
    end
end
