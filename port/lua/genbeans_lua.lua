-- UTF-8 without BOM
local error = error
local print = print
local pairs = pairs
local ipairs = ipairs
local format = string.format
local concat = table.concat
local open = io.open
local type = type
local arg = arg

local template_bean = [=[
-- UTF-8 without BOM
-- This file is generated by genbeans tool. Do NOT edit it!

local num, str, bool, vec, map = 0, 1, 2, 3, 4
return require "util".initBeans {
#[#	#(bean.name) = { __type = #(bean.type), __vars = {
#{#		#(var.name)#(var.value),
#}##(#		[#(var.id2)] = { name = "#(var.name)", type = #(var.btype)#(var.keyval) },
#)#	}},
#]#}

---@module bean
#[#
---#(bean.comment)
-- @field [parent=#bean] ##(bean.name) #(bean.name)

---@callof ##(bean.name)
-- @return ##(bean.name)#(#

---#(var.comment)
-- @field [parent=##(bean.name)] ##(var.ltype) #(var.name)#)#
#]#]=]

local n, s, b, v, m = "num", "str", "bool", "vec", "map"
local typemap = { byte = n, char = n, short = n, int = n, long = n, float = n, double = n, integer = n,
	bool = b, boolean = b, string = s, octets = s, data = s, bytes = s, binary = s, bean = "\"#(var.name)\"",
	vector = v, list = v, deque = v, hashset = v, treeset = v, linkedhashset = v, array = v, arraydeque = v,
	arraylist = v, linkedlist = v, set = v, linkedset = v, hashmap = m, treemap = m, linkedhashmap = m, map = m, linkedmap = m, }
local ltypemap = { num = "number", str = "string", bool = "boolean", vec = "list", map = "map" }

local function trim(s)
	return s:gsub("[%c ]+", "")
end
local function code_conv(code, prefix, t)
	return code:gsub("#%(" .. prefix .. "%.([%w_]+)%)", function(name) return t[name] end)
end
local function to_ltype(btype)
	return ltypemap[btype] or btype:gsub('"', '')
end

local name_used = {}
local type_bean = {}
local name_bean = {}
local bean_order = {}
local handlers = {} -- selected handler name => true
local hdl_names = {} -- handler name => {bean names}
function handler(hdls)
	if not arg[1] then error("ERROR: arg[1] must be handler name(s)") end
	for hdlname in arg[1]:gmatch("([%w_%.]+)") do
		local hdl = hdls[hdlname]
		if not hdl then error("ERROR: not found or unknown handler name: " .. hdlname) end
		for hdlname in pairs(hdl) do
			handlers[hdlname] = true
		end
	end
end
function bean(bean)
	bean.name = trim(bean.name)
	if bean.name:find("[^%w_]") or typemap[bean.name] then error("ERROR: invalid bean.name: " .. bean.name) end
	if name_used[bean.name] then error("ERROR: duplicated bean.name: " .. bean.name) end
	if type_bean[bean.type] then error("ERROR: duplicated bean.type: " .. bean.type) end
	if type(bean.type) ~= "number" then bean.type = 0 end
	for name in (bean.handlers or ""):gmatch("([%w_%.]+)") do
		hdl_names[name] = hdl_names[name] or {}
		hdl_names[name][#hdl_names[name] + 1] = bean.name
	end
	type_bean[bean.type] = bean
	name_bean[bean.name] = bean

	for _, var in ipairs(bean) do
		if type(var.id) ~= "number" then var.id = -1 end
		if var.id < -1 or var.id > 62 then error("ERROR: normal id=" .. var.id .. " must be in [1, 62]") end
		if type(var.value) == "string" then var.value = "\"" .. var.value .. "\"" end
		var.value = var.value and " = " .. var.value or ""
		var.id2 = format("%2d", var.id)
		var.name = trim(var.name)
		var.type = trim(var.type)
		local basetype
		basetype, var.k, var.v = var.type:match "^%s*([%w_]+)%s*<?%s*([%w_]*)%s*,?%s*([%w_]*)%s*>?%s*%(?%s*([%w%._]*)%s*%)?%s*$"
		var.btype = typemap[basetype] or '"' .. basetype .. '"'
		var.key = var.k and (typemap[var.k] or '"' .. var.k .. '"')
		var.val = var.v and (typemap[var.v] or '"' .. var.v .. '"')
		if var.key == '""' then var.key = nil end
		if var.val == '""' then var.val = nil end
		if not var.val then var.val = var.key; var.key = nil end
		var.ltype = to_ltype(var.btype)
		if var.ltype == "list" then var.ltype = var.ltype .. "<#" .. to_ltype(var.val) .. ">" end
		if var.ltype == "map"  then var.ltype = var.ltype .. "<#" .. to_ltype(var.key) .. ",#" .. to_ltype(var.val) .. ">" end
		var.keyval = (var.key and ", key = #(var.key)" or "") .. (var.val and ", value = #(var.val)" or "")
		if not var.type then
			error("ERROR: unknown type: " .. var.type .. " => " .. basetype)
		end
	end

	name_used[bean.name] = true
	bean_order[#bean_order + 1] = bean.name
end

if not arg[2] then error("ERROR: arg[2] must be input allbeans.lua") end
dofile(arg[2])

local function checksave(fn, d, change_count, pattern, typename)
	local f = open(fn, "rb")
	if f then
		local s = f:read "*a"
		f:close()
		if change_count > 0 then
			d = s:gsub("\n\t/%*\\.-\n\t\\%*/", d:gmatch("\n\t/%*\\.-\n\t\\%*/"), change_count):gsub(pattern, typename, 1)
		end
		if s == d then d = nil else print(" * " .. fn) end
	else
		print("+  " .. fn)
	end
	if d then
		f = open(fn, "wb")
		if not f then error("ERROR: can not create file: " .. fn) end
		f:write(d)
		f:close()
	end
end

local outpath = (arg[3] or "."):gsub("\\", "/")
if outpath:sub(-1, -1) ~= "/" then outpath = outpath .. "/" end

local marked = {}
local function markbean(beanname)
	if marked[beanname] then return end
	marked[beanname] = true
	if not name_bean[beanname] then error("ERROR: unknown bean: " .. beanname) end
	for _, var in ipairs(name_bean[beanname]) do
		if name_bean[var.type] then markbean(var.type) end
		if name_bean[var.k] then markbean(var.k) end
		if name_bean[var.v] then markbean(var.v) end
	end
end
for hdlname in pairs(handlers) do
	for _, beanname in ipairs(hdl_names[hdlname]) do
		markbean(beanname)
	end
end

checksave(outpath .. "bean.lua", (template_bean:gsub("#%[#(.-)#%]#", function(body)
	local subcode = {}
	for _, name in ipairs(bean_order) do
		local bean = name_bean[name]
		if bean and marked[name] then
			subcode[#subcode + 1] = code_conv(body:gsub("#{#(.-)#}#", function(body)
				local subcode2 = {}
				for _, var in ipairs(bean) do
					if var.id == -1 then subcode2[#subcode2 + 1] = code_conv(body, "var", var) end
				end
				return concat(subcode2)
			end):gsub("#%(#(.-)#%)#", function(body)
				local subcode2 = {}
				for _, var in ipairs(bean) do
					if var.id > 0 then subcode2[#subcode2 + 1] = code_conv(code_conv(body, "var", var), "var", var) end
				end
				return concat(subcode2)
			end), "bean", bean)
		end
	end
	return concat(subcode)
end)):gsub("\r", ""), 0)

print "done!"
