--[[
脚本目录兼容加载器
目的：避免复制第二份实现，统一复用项目根目录 mq插件.lua
]]

-- 优先复用已经加载过的模块（避免重复加载）
local loaded = package.loaded["mq插件"]
if loaded then
    return loaded
end

-- 根据常见执行目录尝试候选路径
local candidates = {
    "mq插件.lua",
    "../mq插件.lua",
}

for _, path in ipairs(candidates) do
    local f = io.open(path, "r")
    if f then
        f:close()
        local mod = dofile(path)
        package.loaded["mq插件"] = mod
        return mod
    end
end

error("未找到项目根目录的 mq插件.lua，请检查文件位置")
local mq = {}

local state = {
    initialized = false,
    status = "插件已加载",
    config = {
        url = "",
        user = "",
        password = "",
        device = "",
        updateUrl = "",
        enabled = false,
    },
    deviceTable = {},
    dataTable = {},
    taskConfig = {},
    code = "",
    userCode = "",
}

local function encodeJson(value)
    if jsonLib and jsonLib.encode then
        return jsonLib.encode(value)
    end
    if type(value) ~= "table" then
        return tostring(value)
    end

    local parts = {}
    for k, v in pairs(value) do
        local key = string.format('"%s"', tostring(k))
        local val
        if type(v) == "string" then
            val = string.format('"%s"', v)
        elseif type(v) == "number" or type(v) == "boolean" then
            val = tostring(v)
        else
            val = '"' .. tostring(v) .. '"'
        end
        parts[#parts + 1] = key .. ":" .. val
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function emitEvent(eventId, arg)
    if type(_G.onPluginEvent) == "function" then
        _G.onPluginEvent(eventId, arg)
    end
end

function mq.init(code, userCode)
    state.code = code or ""
    state.userCode = userCode or ""
    state.initialized = true
    state.status = "插件已初始化"
    return true
end

function mq.SetMqConfig(url, user, password, device, updateUrl, enabled)
    state.config.url = url or ""
    state.config.user = user or ""
    state.config.password = password or ""
    state.config.device = device or ""
    state.config.updateUrl = updateUrl or ""
    state.config.enabled = enabled == true

    if not state.initialized then
        state.status = "插件未初始化"
        return false, state.status
    end

    if state.config.enabled and state.config.url ~= "" and state.config.device ~= "" then
        state.status = "已连接"
    elseif state.config.enabled then
        state.status = "参数不完整"
    else
        state.status = "连接已禁用"
    end

    return true, state.status
end

function mq.getMqStatus()
    return state.status
end

function mq.sendMsgtoMq(device, tableType, column, content)
    local targetDevice = device or state.config.device
    if targetDevice == "" then
        return false, "设备名不能为空"
    end

    local targetTable = (tonumber(tableType) == 0) and state.deviceTable or state.dataTable
    targetTable[targetDevice] = targetTable[targetDevice] or {}
    targetTable[targetDevice][tostring(column)] = content

    return true
end

function mq.getMqmsg(device, sourceDevice, tableType, column)
    local targetDevice = sourceDevice or device or state.config.device
    local targetTable = (tonumber(tableType) == 0) and state.deviceTable or state.dataTable

    if not targetTable[targetDevice] then
        return ""
    end

    local value = targetTable[targetDevice][tostring(column)] or ""
    emitEvent(1, value)
    return value
end

function mq.getStateConfig()
    if next(state.taskConfig) == nil then
        return "任务配置未下发,请下发之后再尝试获取"
    end
    return encodeJson(state.taskConfig)
end

function mq.sendCloseMq()
    state.status = "已断开"
    return true
end

-- 下面是便于本地调试的辅助方法，不影响原接口
function mq.mockSetTaskConfig(configTable)
    state.taskConfig = configTable or {}
    emitEvent(66, mq.getStateConfig())
end

function mq.mockPushUpdateEvent()
    emitEvent(309, "")
end

return mq
