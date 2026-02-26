--[[
明文 mq 插件实现（本地模拟版）
用途：替代加密 .luaej 插件，保持相同 API，便于开发/调试。
说明：
1) 该实现仅在内存中保存数据，不会真正连接 MQTT 服务端。
2) 接口命名与原插件保持一致，减少示例脚本改动。
]]

local mq = {}

-- 插件运行期状态（仅内存）
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
    -- tableType=0 时存设备表，tableType=1 时存数据表
    deviceTable = {},
    dataTable = {},
    -- 中控任务配置（模拟下发）
    deviceTable = {},
    dataTable = {},
    taskConfig = {},
    code = "",
    userCode = "",
}

-- JSON 编码：优先复用宿主 jsonLib，缺失时提供简易兜底
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

-- 触发插件回调事件（与 setPluginEventCallBack/onPluginEvent 约定兼容）
local function emitEvent(eventId, arg)
    if type(_G.onPluginEvent) == "function" then
        _G.onPluginEvent(eventId, arg)
    end
end

--- 初始化插件
--- @param code string 卡密/授权码（透传保存）
--- @param userCode string 用户码（透传保存）
function mq.init(code, userCode)
    state.code = code or ""
    state.userCode = userCode or ""
    state.initialized = true
    state.status = "插件已初始化"
    return true
end

--- 设置连接参数（模拟）
--- @return boolean ok
--- @return string status
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

--- 获取当前连接状态文本
function mq.getMqStatus()
    return state.status
end

--- 发送数据到“中控”（模拟写入本地内存表）
--- @param device string 目标设备
--- @param tableType number 0=设备表, 1=数据表
--- @param column string|number 列名/列序号
--- @param content any 内容
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

--- 读取“中控数据”（模拟从内存表读取）
--- 读取成功时会触发事件 e=1
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

--- 获取任务配置（模拟下发）
function mq.getStateConfig()
    if next(state.taskConfig) == nil then
        return "任务配置未下发,请下发之后再尝试获取"
    end
    return encodeJson(state.taskConfig)
end

--- 主动断开连接（模拟）
function mq.sendCloseMq()
    state.status = "已断开"
    return true
end

-- 调试辅助：模拟“任务配置下发”并触发 e=66
-- 下面是便于本地调试的辅助方法，不影响原接口
function mq.mockSetTaskConfig(configTable)
    state.taskConfig = configTable or {}
    emitEvent(66, mq.getStateConfig())
end

-- 调试辅助：模拟“脚本更新事件” e=309
function mq.mockPushUpdateEvent()
    emitEvent(309, "")
end

return mq
