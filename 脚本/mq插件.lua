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
