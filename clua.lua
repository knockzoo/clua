local clua = {}
local oldenv = _ENV and _ENV or getfenv()
function clua.raiseerror(...)
    return error(string.format(...))
end
function clua.serialize(data, var, indents)
    data = (type(data) == 'table' and data or table.pack(data))
    var = var or "local Serialized = "
    indents = indents or 1

    local function SerializeString(str)
        local r = ''
        local sq = str:match("'")
        local dq = str:match('"')
        local db = str:match("%[%[") or str:match("]]")

        if (not sq and not dq) or (sq and not dq) then
            r = r .. '"' .. str .. '"'
        elseif (dq and not sq) then
            r = r .. "'" .. str .. "'"
        else
            r = r .. '"' .. str:gsub('"', '\\"') .. '"'
        end

        return r
    end

    local r = var .. '{\n'
    local iteration = 0

    for i, v in pairs(data) do
        iteration = iteration + 1
        data = setmetatable(data, {
            __len = function()
                local len = 0
                for i, v in pairs(data) do
                    len = len + 1
                end

                return len
            end
        })

        local valuetype = type(v)
        local indextype = type(i)

        local index = string.rep('\t', indents) .. "["
        if indextype == 'string' then
            index = index .. SerializeString(i)
        elseif indextype == 'number' then
            index = index .. tostring(i)
        end

        index = index .. '] = '
        r = r .. index

        if valuetype == 'string' then
            r = r .. SerializeString(v)
        elseif valuetype == 'number' then
            r = r .. tostring(v)
        elseif valuetype == 'table' then
            r = r .. Serialize(v, '', indents + 1)
        end

        if iteration ~= #data then
            r = r .. ',\n'
        end
    end

    r = r .. '\n' .. string.rep('\t', indents - 1) .. '}'
    return r
end
function clua.build(...)
    local args = {...}
    args = args[1]

    local name = args.name
    local call = args.call
    local library = args.library

    local old
    if library then
        old = oldenv[library][name]
    else
        old = oldenv[name]
    end

    local build = { -- majorly idiotic approach
        __add = function(...)
            clua.raiseerror("attempt to perform arithmetic on a function value (global '%s')", name)
        end,
        __sub = function(...)
            clua.raiseerror("attempt to perform arithmetic on a function value (global '%s')", name)
        end,
        __mul = function(...)
            clua.raiseerror("attempt to perform arithmetic on a function value (global '%s')", name)
        end,
        __div = function(...)
            clua.raiseerror("attempt to perform arithmetic on a function value (global '%s')", name)
        end,
        __mod = function(...)
            clua.raiseerror("attempt to perform arithmetic on a function value (global '%s')", name)
        end,
        __pow = function(...)
            clua.raiseerror("attempt to perform arithmetic on a function value (global '%s')", name)
        end,
        __unm = function(...)
            clua.raiseerror("attempt to perform arithmetic on a function value (global '%s')", name)
        end,
        __idiv = function(...)
            clua.raiseerror("attempt to perform arithmetic on a function value (global '%s')", name)
        end,
        __band = function(...)
            clua.raiseerror("attempt to perform arithmetic on a function value (global '%s')", name)
        end,
        __bor = function(...)
            clua.raiseerror("attempt to perform arithmetic on a function value (global '%s')", name)
        end,
        __bxor = function(...)
            clua.raiseerror("attempt to perform arithmetic on a function value (global '%s')", name)
        end,
        __bnot = function(...)
            clua.raiseerror("attempt to perform arithmetic on a function value (global '%s')", name)
        end,
        __shl = function(...)
            clua.raiseerror("attempt to perform arithmetic on a function value (global '%s')", name)
        end,
        __shr = function(...)
            clua.raiseerror("attempt to perform arithmetic on a function value (global '%s')", name)
        end,
        __concat = function(...)
            clua.raiseerror("attempt to concanenate a function value (global '%s')", name)
        end,
        __len = function(...)
            clua.raiseerror("attempt to get length of a function value (global '%s')", name)
        end,
        __eq = function(...)
            return rawequal(old, select(1, ...))
        end,
        __lt = function(...)
            clua.raiseerror("attempt to compare %s with function", type(select(1, ...)))
        end,
        __le = function(...)
            clua.raiseerror("attempt to compare %s with function", type(select(1, ...)))
        end,
        __index = function(...)
            clua.raiseerror("attempt to index a function value (global '%s')", name)
        end,
        __newindex = function(...)
            clua.raiseerror("attempt to index a function value (global '%s')", name)
        end,
        __call = call,
        __metatable = {},
        __name = oldenv['tostring'](call)
    }

    setmetatable(build, build)

    if library then
        clua[library][name] = build
    else
        clua[name] = build
    end
end

clua.build({
    name = 'pairs',
    call = function(self, ...)
        local t = select(1, ...)
        assert(t, "bad argument #1 to 'pairs' (value expected)")

        local mt = getmetatable(t)
        if mt then
            if mt.__pairs then
                local result = mt.__pairs(t)
                return select(1, result), select(2, result), select(3, result)
            end
        end

        return next, t, nil
    end
})

clua.build({
    name = 'ipairs',
    call = function(self, ...)
        local t = select(1, ...)
        assert(t, "bad argument #1 to 'ipairs' (value expected)")

        return function(self, ...)
            local index = select(1, ...)
            local value = t[index + 1]
            if value then
                return index + 1, value
            end
        end, t, 0
    end
})

clua.build({
    name = 'tonumber',
    call = function(self, ...)
        local s = select(1, ...)
        assert(s, "bad argument #1 to 'tonumber' (value expected)")

        if s:sub(1, 1) == "-" then
            return (self(string.sub(s, 2, rawlen(s))) - (self(string.sub(s, 2, rawlen(s))) * 2))
        end

        local r = 0
        local decimal = false
        local decimalplace = 0
        local decimalpart = 0
        local min = string.byte("0")
        local max = string.byte("9")

        for i = 1, rawlen(s) do
            local c = s:sub(i, i)
            if c:match("%d") then
                local ascii = string.byte(c)
                if ascii >= min and ascii <= max then
                    local digit = ascii - min

                    if decimal then
                        decimalplace = decimalplace + 1
                        decimalpart = decimalpart + digit * 10 ^ (-decimalplace)
                    else
                        r = r * 10 + digit
                    end
                end
            elseif c == '.' then
                decimal = true
            else
                return nil
            end
        end

        return r + decimalpart
    end
})

local massivelylarge = 10 ^ 32
local approachingzero = 1 / massivelylarge
clua.build({
    name = 'tostring',
    call = function(self, ...)
        local v = select(1, ...)
        assert(v, "bad argument #1 to 'tostring' (value expected)")

        if type(v) == "number" then
            if v ~= math.floor(v) then
                local r = ""
                local function round(number, point)
                    local multiplier = 10 ^ point
                    return math.floor(number * multiplier) / multiplier
                end

                local function len(n, point)
                    point = point or 1

                    local c = point
                    local i = 0
                    while true do
                        if n >= c then
                            i = i + 1
                            c = c * 10
                        else
                            break
                        end
                    end

                    return i
                end

                local function singledigit(n)
                    local c = 1
                    while true do
                        if n >= c then
                            c = c * 10
                        else
                            break
                        end
                    end

                    return n / (c / 10)
                end

                local a = round
                local b = len
                local c = singledigit

                local function split(n)
                    local r = {}
                    for i = b(n), 0, -1 do
                        local v = a(n, i)
                        if v == n then
                            v = a(n, -i)
                            table.insert(r, math.floor(c(n - v)))
                        else
                            local d = c(n - v) / 10
                            table.insert(r, a(d, b(d, approachingzero) - 1)) -- this is probably the stupidest possible way of doing things
                        end
                    end

                    return r
                end

                local split = split(v)
                for i, v in pairs(split) do
                    if v > 0 and v <= 9 then
                        if v >= 1 then
                            r = r .. string.char(v + string.byte("0"))
                        else
                            r = r .. "." .. string.char(v + string.byte("0"))
                        end
                    elseif v == 0 then
                        r = r .. "0"
                    end
                end

                return r
            else
                return string.format("%s", v)
            end
        elseif type(v) == 'string' then
            return v
        else -- so sad
            return "return " .. clua.serialize(select(2, ...), '')
        end
    end
})

setmetatable(clua, {
    __index = function(self, ...)
        local index = oldenv['select'](1, ...)
        if not oldenv['rawget'](self, index) then
            return oldenv[index]
        end

        return oldenv['rawget'](self, index)
    end
})

_ENV = clua
getfenv = function()
    return clua
end