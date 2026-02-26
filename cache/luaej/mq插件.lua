--[[
cache 下的 mq 入口兼容层
目的：原 .luaej 对应的缓存入口也能转到明文 mq插件.lua
]]

mq = {}

local function loadRootModule()
    -- 1) 已加载则直接返回
    local loaded = package.loaded["mq插件"]
    if loaded then
        return loaded
    end

    -- 2) 尝试常规 require
    local ok, mod = pcall(require, "mq插件")
    if ok and type(mod) == "table" then
        package.loaded["mq插件"] = mod
        return mod
    end

    -- 3) 失败后按路径回退
    local candidates = {
        "mq插件.lua",
        "../mq插件.lua",
        "../../mq插件.lua",
    }

    for _, path in ipairs(candidates) do
        local f = io.open(path, "r")
        if f then
            f:close()
            local module = dofile(path)
            package.loaded["mq插件"] = module
            return module
        end
    end

    error("未找到可用的 mq插件.lua，请确认项目根目录存在该文件")
end

return loadRootModule()
