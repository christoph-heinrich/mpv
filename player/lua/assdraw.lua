local ass_mt = {}
ass_mt.__index = ass_mt
local text_mt = {}
text_mt.__index = text_mt
local c = 0.551915024494 -- circle approximation

local function ass_new()
    return setmetatable({ scale = 4, text = setmetatable({}, text_mt) }, ass_mt)
end

function text_mt.__concat(t1, t2)
    if type(t2) == "table" then
        if type(t1) == "table" then
            local n = #t1
            for i, e in ipairs(t2) do
                t1[n + i] = e
            end
        else
            t2[#t2 + 1] = t1
            return t2
        end
    else
        t1[#t1 + 1] = t2
    end
    return t1
end

function ass_mt.new_event(ass)
    -- osd_libass.c adds an event per line
    if #ass.text > 0 then
        ass.text = ass.text .. "\n"
    end
end

function ass_mt.draw_start(ass)
    ass:append(string.format("{\\p%d}", ass.scale))
end

function ass_mt.draw_stop(ass)
    ass.text = ass.text .. "{\\p0}"
end

function ass_mt.coord(ass, x, y)
    local scale = 2 ^ (ass.scale - 1)
    local ix = math.ceil(x * scale)
    local iy = math.ceil(y * scale)
    ass:append(string.format(" %d %d", ix, iy))
end

function ass_mt.append(ass, s)
    ass.text = ass.text .. s
end

function ass_mt.merge(ass1, ass2)
    ass1.text = ass1.text .. ass2.text
end

function ass_mt.pos(ass, x, y)
    ass:append(string.format("{\\pos(%f,%f)}", x, y))
end

function ass_mt.an(ass, an)
    ass:append(string.format("{\\an%d}", an))
end

function ass_mt.move_to(ass, x, y)
    ass:append(" m")
    ass:coord(x, y)
end

function ass_mt.line_to(ass, x, y)
    ass:append(" l")
    ass:coord(x, y)
end

function ass_mt.bezier_curve(ass, x1, y1, x2, y2, x3, y3)
    ass:append(" b")
    ass:coord(x1, y1)
    ass:coord(x2, y2)
    ass:coord(x3, y3)
end


function ass_mt.rect_ccw(ass, x0, y0, x1, y1)
    ass:move_to(x0, y0)
    ass:line_to(x0, y1)
    ass:line_to(x1, y1)
    ass:line_to(x1, y0)
end

function ass_mt.rect_cw(ass, x0, y0, x1, y1)
    ass:move_to(x0, y0)
    ass:line_to(x1, y0)
    ass:line_to(x1, y1)
    ass:line_to(x0, y1)
end

function ass_mt.hexagon_cw(ass, x0, y0, x1, y1, r1, r2)
    if r2 == nil then
        r2 = r1
    end
    ass:move_to(x0 + r1, y0)
    if x0 ~= x1 then
        ass:line_to(x1 - r2, y0)
    end
    ass:line_to(x1, y0 + r2)
    if x0 ~= x1 then
        ass:line_to(x1 - r2, y1)
    end
    ass:line_to(x0 + r1, y1)
    ass:line_to(x0, y0 + r1)
end

function ass_mt.hexagon_ccw(ass, x0, y0, x1, y1, r1, r2)
    if r2 == nil then
        r2 = r1
    end
    ass:move_to(x0 + r1, y0)
    ass:line_to(x0, y0 + r1)
    ass:line_to(x0 + r1, y1)
    if x0 ~= x1 then
        ass:line_to(x1 - r2, y1)
    end
    ass:line_to(x1, y0 + r2)
    if x0 ~= x1 then
        ass:line_to(x1 - r2, y0)
    end
end

function ass_mt.round_rect_cw(ass, x0, y0, x1, y1, r1, r2)
    if r2 == nil then
        r2 = r1
    end
    local c1 = c * r1 -- circle approximation
    local c2 = c * r2 -- circle approximation
    ass:move_to(x0 + r1, y0)
    ass:line_to(x1 - r2, y0) -- top line
    if r2 > 0 then
        ass:bezier_curve(x1 - r2 + c2, y0, x1, y0 + r2 - c2, x1, y0 + r2) -- top right corner
    end
    ass:line_to(x1, y1 - r2) -- right line
    if r2 > 0 then
        ass:bezier_curve(x1, y1 - r2 + c2, x1 - r2 + c2, y1, x1 - r2, y1) -- bottom right corner
    end
    ass:line_to(x0 + r1, y1) -- bottom line
    if r1 > 0 then
        ass:bezier_curve(x0 + r1 - c1, y1, x0, y1 - r1 + c1, x0, y1 - r1) -- bottom left corner
    end
    ass:line_to(x0, y0 + r1) -- left line
    if r1 > 0 then
        ass:bezier_curve(x0, y0 + r1 - c1, x0 + r1 - c1, y0, x0 + r1, y0) -- top left corner
    end
end

function ass_mt.round_rect_ccw(ass, x0, y0, x1, y1, r1, r2)
    if r2 == nil then
        r2 = r1
    end
    local c1 = c * r1 -- circle approximation
    local c2 = c * r2 -- circle approximation
    ass:move_to(x0 + r1, y0)
    if r1 > 0 then
        ass:bezier_curve(x0 + r1 - c1, y0, x0, y0 + r1 - c1, x0, y0 + r1) -- top left corner
    end
    ass:line_to(x0, y1 - r1) -- left line
    if r1 > 0 then
        ass:bezier_curve(x0, y1 - r1 + c1, x0 + r1 - c1, y1, x0 + r1, y1) -- bottom left corner
    end
    ass:line_to(x1 - r2, y1) -- bottom line
    if r2 > 0 then
        ass:bezier_curve(x1 - r2 + c2, y1, x1, y1 - r2 + c2, x1, y1 - r2) -- bottom right corner
    end
    ass:line_to(x1, y0 + r2) -- right line
    if r2 > 0 then
        ass:bezier_curve(x1, y0 + r2 - c2, x1 - r2 + c2, y0, x1 - r2, y0) -- top right corner
    end
end

return {ass_new = ass_new}
