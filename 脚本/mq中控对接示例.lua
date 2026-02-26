mq = require("mq插件")
local code = "Y5RV23V9ZW"
local user_code ="X9BWCGQN27"

mq.init(code,user_code)

function onPluginEvent(e , arg)
	if e == 1 then
		中控传过来的数据 = arg
		print("中控传输过来的数据为 :" ..中控传过来的数据)
		--全局_code = arg
		
	elseif e == 2 then
		print("收到自定义命令了")
	elseif e == 66 then
		print("收到任务配置更新了")
		--获取任务配置
		获取任务配置()
		
	elseif e == 309 then
		print("收到更新脚本事件了")
		
		toast("脚本更新了,重启脚本" , 0 , 0 , 12)
		sleep(3000)
		restartScript()
		--sleep(3000)
		
	end
end
setPluginEventCallBack(onPluginEvent)

function getChangedFields(currentData , lastData)
	local changedFields = {}
	for key , value in pairs(currentData) do
		if lastData[key] ~= value then
			changedFields[key] = value
		end
	end
	return changedFields
end

function mq上传数据(数据)
	
	--对比数据并上传,只有数据发送变化才会上传
	
	local function deepCopy(orig)
		local copy = {}
		for k , v in pairs(orig) do
			
			if type(v) == "table" then
				copy[k] = deepCopy(v) -- 递归拷贝子表
			else
				copy[k] = v
			end
		end
		return copy
	end
	local changedFields = getChangedFields(数据 , 上次发送数据)
	if next(changedFields) == nil then
		print("没有变化的字段，不上传")
		
	else
		
		mq.sendMsgtoMq(云控配置.device , 1 , 5 , jsonLib.encode(数据) )
		上次发送数据 = deepCopy(数据) -- 更新记录为最新数据
		print("上传成功",mq.sendMsgtoMq(云控配置.device , 1 , 5 , jsonLib.encode(数据) ))
	end
	
end

function 对比ui文件(ui文件)
	--把中控配置文件加密写入到本地,并判断是否发生变化, 只要发生变化才重新连接, 解决之前每次连接都需要断开重连问题
	--读取文件,对比是否有变化
	local key = "kfaaccbbdd921288" -- 16字节 AES-128
	local iv = "aaccdd8899aa2255" -- 16字节 IV
	-- AES-CBC 解密示例
	
	local function 读取文件(路径)
		if fileExist(路径) == true then
			local file = io.open(路径 , "r")
			if file == nil then
				print("open file readtest.txt fail")
				return false
			else
				local readall = file:read("*a")
				file:close()
				return readall
			end
		else
			print("文件不存在")
			return false
		end
	end
	
	local function 写入文件(路径 , 内容)
		if 路径 ~= nil and 内容 ~= nil then
			local file = io.open(路径 , "w+")
			if file == nil then
				print("open file writetest.txt fail")
			else
				file:write(内容)
				file:close()
			end
		else
			print("写入文件路径错误或没有写入内容")
		end
	end
	
	local path = getSdPath().."/mqui.txt"
	local uitxt = 读取文件(path)
	
	if uitxt then
		
		local uitxt = cryptLib.aes_crypt(uitxt , key , "decrypt" , "cbc" , iv , true)
		print("读入完成, 解密完成"..uitxt )
		
		local changedFields = getChangedFields(jsonLib.decode(uitxt) , ui文件)
		if next(changedFields) == nil then
			print("没有变化的字段，不需要重新连接")
			
		else
			print("有变化的,重新写入, 并且重新发送连接")
			--断开之前的连接
			mq.sendCloseMq()
			sleep(1000)
			local encrypted = cryptLib.aes_crypt(jsonLib.encode(ui文件) , key , "encrypt" , "cbc" , iv , true)
			print("加密结果:" , encrypted)
			
			写入文件(path , encrypted )
			
			mq.SetMqConfig(ui文件.url , ui文件.user , ui文件.pas , ui文件.device , ui文件.upurl , ui文件.允许连接)
			sleep(2000)
		end
		
	else
		print("ui文件不存在")
		print("第一次连接,需要发送")
		local encrypted = cryptLib.aes_crypt(jsonLib.encode(ui文件) , key , "encrypt" , "cbc" , iv , true)
		
		print("加密完成,开始写入")
		写入文件(path , encrypted)
		print("写入完成")
		mq.SetMqConfig(ui文件.url , ui文件.user , ui文件.pas , ui文件.device , ui文件.upurl , ui文件.允许连接)
		sleep(2000)
	end
	
end

--获取任务配置
任务配置=""
function 获取任务配置()
	--把任务配置定义为全局变量,并在自定义事件中定义事件, 每次下发任务,自动获取最新配置
	任务配置 = mq.getStateConfig()
	
	if 任务配置~= "任务配置未下发,请下发之后再尝试获取" and 任务配置~= "" then
		任务配置 = jsonLib.decode(任务配置)
		--print("中控任务"..任务配置)
	else
		print("请在中控端下发任务")
		toast("请在中控端下发任务" , 0 , 0 , 12)
		
	end
	
end

上次发送数据 = {}

云控配置 = {
	url = "tcp://192.168.1.120:1883" ,
	user = "test002" ,
	pas = "test003" ,
	device = "" ,
	upurl = "" , --热更新链接
	允许连接 = true--是否允许插件连接mq
	
}
--用户名和设备名可以通过ui读取,我这里调试,直接定义

云控配置.user = "test002"
云控配置.device = "测试设备001"

对比ui文件(云控配置)

if mq.getMqStatus() == "" then
	
	local r = checkIsDebug()
	if r then
		print("插件未加载, 当前正在调试状态,请手动加载插件")
		toast("插件未加载,当前正在调试状态,请手动加载插件" , 0 , 0 , 12)
		
	else
		
		print("插件加载失败,当前非调试状态, 请在打包选项勾选默认加载插件")
		toast("插件加载失败,当前非调试状态, 请在打包选项勾选默认加载插件" , 0 , 0 , 12)
		
	end
	
	sleep(5000)
	
	exitScript()
end

--定义数据为全局变量,
--后续更新数据格式为--数据.运行状态="正在打怪",数据.等级="12"


数据 = {
	scriptStatus = "在线" ,
	level = 10 ,
	server = "" ,
	diamonds = 11 ,
	金币 = "" ,
	战力 = "" ,
	坐骑 = "" ,
	脚本到期时间 = ""
	
}

获取任务配置()
print(任务配置)

local 计次 = 0

while true do
	--发送数据
	
	计次 = 计次 + 1
	--模拟数据发送变化,5秒改变一次
	if 计次 == 5 then
		print("改变数值")
		数据.diamonds = 数据.diamonds+1
		计次 = 0
		数据.level = 数据.level +1
	end
	
	
	print("计次: "..计次)
	--只有上传的数据表内容发送变化才会上传
	print(任务配置)
	
	mq上传数据(数据)
	print("主循环中")
	sleep(1000)
end

