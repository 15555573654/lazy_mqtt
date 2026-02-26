mq= {}
---
---
--- 功能:设置中控连接参数
--- 参数1:中控url
--- 参数2:中控用户名
--- 参数3:中控密码
--- 参数4:设备名
--- 参数5:热更新链接
--- 参数6:是否运行连接
---
--- [查看文档](command:extension.lua.doc?[mq.SetMqConfig])
---
--- @param ... any
function mq.SetMqConfig()
    -- TODO: Implement this function
end

---
--- 功能:获取插件连接状态
---
--- [查看文档](command:extension.lua.doc?[mq.getMqStatus])
---
--- @param ... any
function mq.getMqStatus()
    -- TODO: Implement this function
end

---
--- 功能:获取中控数据
--- 参数1:设备名
--- 参数3:欲获取的设备名
--- 参数2:数据表
--- 参数3:欲获取的数据列
--- 返回:该命令返回值由设置插件回调函数返回
---
--- [查看文档](command:extension.lua.doc?[mq.getMqmsg])
---
--- @param ... any
function mq.getMqmsg()
    -- TODO: Implement this function
end

---
--- 功能:获取中控发送的任务配置
--- 返回:Json格式的任务数据
---
--- [查看文档](command:extension.lua.doc?[mq.getStateConfig])
---
--- @param ... any
function mq.getStateConfig()
    -- TODO: Implement this function
end

---
--- 初始化插件,插件开始运行前必须调用
---
--- [查看文档](command:extension.lua.doc?[mq.init])
---
--- @param ... any
function mq.init()
    -- TODO: Implement this function
end

---
--- 功能:断开与中控的连接
--- 说明:该命令用于主动断开与中控的连接,如果用户卡密到期了,可调用该命令主动断开与中控的连接 避免占用服务器资源
---
--- [查看文档](command:extension.lua.doc?[mq.sendCloseMq])
---
--- @param ... any
function mq.sendCloseMq()
    -- TODO: Implement this function
end

---
--- 功能:发送数据到中控
--- 参数1:设备名
--- 参数2:设备表(0为设备列表,1为数据列表)
--- 参数3:数据列
--- 参数4:数据内容
---
--- [查看文档](command:extension.lua.doc?[mq.sendMsgtoMq])
---
--- @param ... any
function mq.sendMsgtoMq()
    -- TODO: Implement this function
end

