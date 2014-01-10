-- UTF-8 without BOM
local type = type
local string = string
local error = error
local pairs = pairs
local table = table
local concat = table.concat
local ipairs = ipairs
local print = print
local open = io.open

local namespace = "jane" -- for bean namespace

local template_hint = "// This file is generated by genbeans tool. Do NOT edit it!\n"
local template_bean = template_hint .. [=[
using System;
using System.Text;
using System.Collections.Generic;

namespace ]=] .. namespace .. [=[.bean
{#(bean.comment)
	public sealed class #(bean.name) : Bean, IComparable<#(bean.name)>
	{
		public const int BEAN_TYPE = #(bean.type);
#{#		public const #(var.type) #(var.name)#(var.value);#(var.comment)
#}#
#(#		#(var.public) /*#(var.id2)*/ #(var.final)#(var.type) #(var.name);#(var.comment)
#)##<#
		public #(bean.name)()
		{
#(##(var.new)#)#		}

		public #(bean.name)(#(##(var.type_i) #(var.name), #)#)
		{
#(#			#(var.init);
#)#		}

#>#		public override void reset()
		{
#(#			#(var.reset);
#)#		}

		#(bean.param_warning)public void assign(#(bean.name) b)
		{#<#
			if(b == null) { reset(); return; }#>#
#(#			#(var.assign);
#)#		}
#(#
		public #(var.type) get#(var.name_u)()
		{
			return #(var.name);
		}
#(var.set)#)#
		public override int type()
		{
			return #(bean.type);
		}

		public override int initSize()
		{
			return #(bean.initsize);
		}

		public override int maxSize()
		{
			return #(bean.maxsize);
		}

		public override Bean create()
		{
			return new #(bean.name)();
		}

		public override OctetsStream marshal(OctetsStream s)
		{
#(#			#(var.marshal)
#)#			return s.marshal1((byte)0);
		}

		public override OctetsStream unmarshal(OctetsStream s)
		{
			for(;;) { int i = s.unmarshalByte() & 0xff, t = i & 3; switch(i >> 2)
			{
				case 0: return s;
#(#				#(var.unmarshal) break;
#)#				default: s.unmarshalSkipVar(t); break;
			}}
		}

		public override object Clone()
		{
			return new #(bean.name)(#(##(var.name), #)#);
		}

		public override int GetHashCode()
		{
			int h = unchecked(#(bean.type) * (int)0x9e3779b1);
#(#			h = h * 31 + 1 + #(var.hashcode);
#)#			return h;
		}

		public override bool Equals(object o)
		{
			if(o == this) return true;
			if(!(o is #(bean.name))) return false;#<#
			#(bean.name) b = (#(bean.name))o;#>#
#(#			if(#(var.equals)) return false;
#)#			return true;
		}

		public int CompareTo(#(bean.name) b)
		{
			if(b == this) return 0;
			if(b == null) return 1;#<#
			int c;#>#
#(#			c = #(var.compareto); if(c != 0) return c;
#)#			return 0;
		}

		public override string ToString()
		{
			StringBuilder s = new StringBuilder(16 + #(bean.initsize) * 2).Append('{');#<#
#(#			#(var.tostring);
#)#			s[s.Length - 1] = '}';#>#
			return s.ToString();
		}

		public override StringBuilder toJson(StringBuilder s)
		{
			if(s == null) s = new StringBuilder(1024);
			s.Append('{');#<#
#(#			#(var.tojson);
#)#			s[s.Length - 1] = '}';#>#
			return s;
		}

		public override StringBuilder toLua(StringBuilder s)
		{
			if(s == null) s = new StringBuilder(1024);
			s.Append('{');#<#
#(#			#(var.tolua);
#)#			s[s.Length - 1] = '}';#>#
			return s;
		}
	}
}
]=]

local template_allbeans = template_hint .. [=[
using System.Collections.Generic;

namespace ]=] .. namespace .. [=[.bean
{
	/** 全部beans的注册(自动生成的静态类) */
	public sealed class AllBeans
	{
		private AllBeans() {}

		/** 注册全部的beans到网络管理器. 必须在网络连接之前调用 */
		public static ICollection<Bean> getAllBeans()
		{
			ICollection<Bean> r = new List<Bean>(#(bean.count));
#(#			r.Add(new #(bean.name)());
#)#			return r;
		}
#[#
		public static Dictionary<int, BeanHandler> get#(hdl.name)Handlers()
		{
			Dictionary<int, BeanHandler> r = new Dictionary<int, BeanHandler>(#(hdl.count) * 4);
#(#			r.Add(#(bean.type), new #(hdl.path).#(bean.name)Handler());
#)#			return r;
		}
#]#	}
}
]=]

local template_bean_handler = [=[
using ]=] .. namespace .. [=[.bean;

namespace #(hdl.path)
{
	public class #(bean.name)Handler : BeanHandler<#(bean.name)>
	{
		/*\
#(#		|*| #(var.type) #(var.name)#(var.value);#(var.comment)
#)#		\*/

		public override void onProcess(object manager, object session, #(bean.name) arg)
		{
			// Log.log.debug("{}.onProcess: arg={}", getClass().getName(), arg);
		}
	}
}
]=]

local typedef = {}
local function merge(ta, tb)
	local r = {}
	for k, v in pairs(ta) do r[k] = v end
	for k, v in pairs(tb) do r[k] = v end
	return r
end
local function typename(var, t)
	local def = typedef[t]
	if not def then return t end
	if type(def) == "function" then
		local t = { id = 0 } def(t, 0) def = t
	end
	if type(def) == "table" then return type(def.type) == "string" and def.type or def.type(var) end
	error("ERROR: unknown typename(" .. var .. ", " .. t .. ")")
end
local function subtypename(var, t)
	local def = typedef[t]
	if not def then return t end
	if type(def) == "function" then
		local t = { id = 0 } def(t, 0) def = t
	end
	if type(def) == "table" then return type(def.type_o) == "string" and def.type_o or def.type_o(var) end
	error("ERROR: unknown subtypename(" .. var .. ", " .. t .. ")")
end
local function subtypename_new(var, t)
	if not var then return ", " end
	return subtypename(var, t)
end
local function subtypeid(t)
	local def = typedef[t]
	if not def then def = typedef.bean end
	if type(def) == "function" then local t = { id = 0 } def(t, 0) return t.subtypeid end
	if type(def) == "table" then return def.subtypeid end
	error("ERROR: unknown subtypeid(" .. t .. ")")
end
local function get_unmarshal_kv(var, kv, t)
	local s = (typedef[var[kv]] or typedef.bean).unmarshal_kv
	return type(s) == "string" and s or s(var, kv, t)
end
typedef.byte =
{
	name_u = function(var) return var.name:sub(1, 1):upper() .. var.name:sub(2) end,
	type = "byte", type_i = "byte", type_o = "byte",
	subtypeid = 0,
	public = "public ",
	final = "",
	new = "",
	init = "this.#(var.name) = #(var.name)",
	reset = "#(var.name) = 0",
	assign = "this.#(var.name) = b.#(var.name)",
	set = [[

		public void set#(var.name_u)(#(var.type) #(var.name))
		{
			this.#(var.name) = #(var.name);
		}
]],
	marshal = function(var) return string.format("if(this.#(var.name) != 0) s.marshal1((byte)0x%02x).marshal(this.#(var.name));", var.id * 4) end,
	unmarshal = "case #(var.id): this.#(var.name) = (#(var.type))s.unmarshalInt(t);",
	unmarshal_kv = function(var, kv, t) if kv then return "(" .. typename(var, var[kv]) .. ")s.unmarshalIntKV(" .. t .. ")" end end,
	hashcode = "this.#(var.name)",
	equals = "this.#(var.name) != b.#(var.name)",
	compareto = "this.#(var.name) - b.#(var.name)",
	tostring = "s.Append(this.#(var.name)).Append(',')",
	tojson = "s.Append(\"\\\"#(var.name)\\\":\").Append(this.#(var.name)).Append(',')",
	tolua = "s.Append(\"#(var.name)=\").Append(this.#(var.name)).Append(',')",
}
typedef.char  = merge(typedef.byte, { type = "char",  type_i = "char",  type_o = "char"  })
typedef.short = merge(typedef.byte, { type = "short", type_i = "short", type_o = "short" })
typedef.int = merge(typedef.byte,
{
	type = "int",
	type_i = "int",
	type_o = "int",
	unmarshal = "case #(var.id): this.#(var.name) = s.unmarshalInt(t);",
	unmarshal_kv = function(var, kv, t) if kv then return "s.unmarshalIntKV(" .. t .. ")" end end,
})
typedef.long = merge(typedef.byte,
{
	type = "long",
	type_i = "long",
	type_o = "long",
	unmarshal = "case #(var.id): this.#(var.name) = s.unmarshalLong(t);",
	unmarshal_kv = function(var, kv, t) if kv then return "s.unmarshalLongKV(" .. t .. ")" end end,
	hashcode = "(int)this.#(var.name)",
	compareto = "Math.Sign(this.#(var.name) - b.#(var.name))",
})
typedef.bool = merge(typedef.byte,
{
	type = "bool", type_i = "bool", type_o = "bool",
	reset = "#(var.name) = false",
	marshal = function(var) return string.format("if(this.#(var.name)) s.marshal1((byte)0x%02x).marshal1((byte)1);", var.id * 4) end,
	unmarshal = "case #(var.id): this.#(var.name) = (s.unmarshalInt(t) != 0);",
	unmarshal_kv = function(var, kv, t) if kv then return "(s.unmarshalIntKV(" .. t .. ") != 0)" end end,
	hashcode = "(int)(this.#(var.name) ? 0xcafebabe : 0xdeadbeef)",
	compareto = "(this.#(var.name) == b.#(var.name) ? 0 : (this.#(var.name) ? 1 : -1))",
})
typedef.float = merge(typedef.byte,
{
	type = "float", type_i = "float", type_o = "float",
	subtypeid = 4,
	marshal = function(var) return string.format("if(this.#(var.name) != 0) s.marshal2(0x%04x).marshal(this.#(var.name));", var.id * 0x400 + 0x308) end,
	unmarshal = "case #(var.id): this.#(var.name) = s.unmarshalFloat(t);",
	unmarshal_kv = function(var, kv, t) if kv then return "s.unmarshalFloatKV(" .. t .. ")" end end,
	hashcode = "(int)((BitConverter.DoubleToInt64Bits(this.#(var.name)) * 0x100000001L) >> 32)",
	compareto = "Math.Sign(this.#(var.name) - b.#(var.name))",
})
typedef.double = merge(typedef.float,
{
	type = "double", type_i = "double", type_o = "double",
	subtypeid = 5,
	marshal = function(var) return string.format("if(this.#(var.name) != 0) s.marshal2(0x%04x).marshal(this.#(var.name));", var.id * 0x400 + 0x309) end,
	unmarshal = "case #(var.id): this.#(var.name) = s.unmarshalDouble(t);",
	unmarshal_kv = function(var, kv, t) if kv then return "s.unmarshalDoubleKV(" .. t .. ")" end end,
	compareto = "Math.Sign(this.#(var.name) - b.#(var.name))",
})
typedef.string = merge(typedef.byte,
{
	type = "string", type_i = "string", type_o = "string",
	subtypeid = 1,
	public = "private",
	new = "\t\t\t#(var.name) = \"\";\n",
	init = "this.#(var.name) = (#(var.name) != null ? #(var.name) : \"\")",
	reset = "#(var.name) = \"\"",
	assign = "this.#(var.name) = (b.#(var.name) != null ? b.#(var.name) : \"\")",
	set = [[

		public void set#(var.name_u)(#(var.type) #(var.name))
		{
			this.#(var.name) = (#(var.name) != null ? #(var.name) : "");
		}
]],
	marshal = function(var) return string.format("if(this.#(var.name).Length > 0) s.marshal1((byte)0x%02x).marshal(this.#(var.name));", var.id * 4 + 1) end,
	unmarshal = "case #(var.id): this.#(var.name) = s.unmarshalString(t);",
	unmarshal_kv = function(var, kv, t) if kv then return "s.unmarshalStringKV(" .. t .. ")" end end,
	hashcode = "this.#(var.name).GetHashCode()",
	equals = "!this.#(var.name).Equals(b.#(var.name))",
	compareto = "this.#(var.name).CompareTo(b.#(var.name))",
	tojson = "Util.toJStr(s.Append(\"\\\"#(var.name)\\\":\"), this.#(var.name)).Append(',')",
	tolua = "Util.toJStr(s.Append(\"#(var.name)=\"), this.#(var.name)).Append(',')",
})
typedef.octets = merge(typedef.string,
{
	type = "Octets", type_i = "Octets", type_o = "Octets",
	public = "public ",
	final = "readonly ",
	new = "\t\t\t#(var.name) = new Octets(#(var.cap));\n",
	init = "this.#(var.name) = new Octets(#(var.cap)); if(#(var.name) != null) this.#(var.name).replace(#(var.name))",
	reset = "#(var.name).clear()",
	assign = "if(b.#(var.name) != null) this.#(var.name).replace(b.#(var.name)); else this.#(var.name).clear()",
	set = "",
	marshal = function(var) return string.format("if(!this.#(var.name).empty()) s.marshal1((byte)0x%02x).marshal(this.#(var.name));", var.id * 4 + 1) end,
	unmarshal = "case #(var.id): s.unmarshal(this.#(var.name), t);",
	unmarshal_kv = function(var, kv, t) if kv then return "s.unmarshalOctetsKV(" .. t .. ")" end end,
	tojson = "this.#(var.name).dumpJStr(s.Append(\"\\\"#(var.name)\\\":\")).Append(',')",
	tolua = "this.#(var.name).dumpJStr(s.Append(\"#(var.name)=\")).Append(',')",
})
typedef.vector = merge(typedef.octets,
{
	type = function(var) return "List<" .. subtypename(var, var.k) .. ">" end,
	type_i = function(var) return "ICollection<" .. subtypename(var, var.k) .. ">" end,
	new = function(var) return "\t\t\t#(var.name) = new List<" .. subtypename_new(var, var.k) .. ">(#(var.cap));\n" end,
	init = function(var) return "this.#(var.name) = new List<" .. subtypename_new(var, var.k) .. ">(#(var.cap)); if(#(var.name) != null) this.#(var.name).AddRange(#(var.name))" end,
	reset = "#(var.name).Clear()",
	assign = "this.#(var.name).Clear(); if(b.#(var.name) != null) this.#(var.name).AddRange(b.#(var.name))",
	marshal = function(var) return string.format([[if(this.#(var.name).Count > 0)
			{
				s.marshal2(0x%04x).marshalUInt(this.#(var.name).Count);
				foreach(%s v in this.#(var.name))
					s.marshal(v);
			}]], var.id * 0x400 + 0x300 + subtypeid(var.k), subtypename(var, var.k)) end,
	unmarshal = function(var) return string.format([[case #(var.id):
				{
					this.#(var.name).Clear();
					if(t != 3) { s.unmarshalSkipVar(t); break; }
					t = s.unmarshalByte();
					if((t >> 3) != 0) { s.unmarshalSkipVarSub(t); break; }
					t &= 7;
					int n = s.unmarshalUInt();
					this.#(var.name).Capacity = (n < 0x10000 ? n : 0x10000);
					for(; n > 0; --n)
						this.#(var.name).Add(%s);
				}]], get_unmarshal_kv(var, "k", "t")) end,
	compareto = "Util.compareTo(this.#(var.name), b.#(var.name))",
	tostring = "Util.append(s, this.#(var.name))",
	tojson = "Util.appendJson(s.Append(\"\\\"#(var.name)\\\":\"), this.#(var.name))",
	tolua = "Util.appendLua(s.Append(\"#(var.name)=\"), this.#(var.name))",
})
typedef.list = merge(typedef.vector,
{
	type = function(var) return "LinkedList<" .. subtypename(var, var.k) .. ">" end,
	new = function(var) return "\t\t\t#(var.name) = new LinkedList<" .. subtypename_new(var, var.k) .. ">();\n" end,
	init = function(var) return "this.#(var.name) = new LinkedList<" .. subtypename_new(var, var.k) .. ">(); if(#(var.name) != null) Util.addAll(this.#(var.name), #(var.name))" end,
	assign = "this.#(var.name).Clear(); if(b.#(var.name) != null) Util.addAll(this.#(var.name), b.#(var.name))",
	unmarshal = function(var) return string.format([[case #(var.id):
				{
					this.#(var.name).Clear();
					if(t != 3) { s.unmarshalSkipVar(t); break; }
					t = s.unmarshalByte();
					if((t >> 3) != 0) { s.unmarshalSkipVarSub(t); break; }
					t &= 7;
					for(int n = s.unmarshalUInt(); n > 0; --n)
						this.#(var.name).AddLast(%s);
				}]], get_unmarshal_kv(var, "k", "t")) end,
})
typedef.deque = merge(typedef.list,
{
})
typedef.hashset = merge(typedef.vector,
{
	type = function(var) return "HashSet<" .. subtypename(var, var.k) .. ">" end,
	new = function(var) return "\t\t\t#(var.name) = new HashSet<" .. subtypename_new(var, var.k) .. ">(#(var.cap));\n" end,
	init = function(var) return "this.#(var.name) = new HashSet<" .. subtypename_new(var, var.k) .. ">(#(var.cap)); if(#(var.name) != null) this.#(var.name).UnionWith(#(var.name))" end,
	assign = "this.#(var.name).Clear(); if(b.#(var.name) != null) this.#(var.name).UnionWith(#(var.name))",
	unmarshal = function(var) return string.format([[case #(var.id):
				{
					this.#(var.name).Clear();
					if(t != 3) { s.unmarshalSkipVar(t); break; }
					t = s.unmarshalByte();
					if((t >> 3) != 0) { s.unmarshalSkipVarSub(t); break; }
					t &= 7;
					int n = s.unmarshalUInt();
					for(; n > 0; --n)
						this.#(var.name).Add(%s);
				}]], get_unmarshal_kv(var, "k", "t")) end,
})
typedef.treeset = merge(typedef.hashset,
{
	type = function(var) return "SortedSet<" .. subtypename(var, var.k) .. ">" end,
	new = function(var) return "\t\t\t#(var.name) = new SortedSet<" .. subtypename_new(var, var.k) .. ">();\n" end,
	init = function(var) return "this.#(var.name) = new SortedSet<" .. subtypename_new(var, var.k) .. ">(); if(#(var.name) != null) this.#(var.name).UnionWith(#(var.name))" end,
})
typedef.linkedhashset = merge(typedef.hashset,
{
})
typedef.hashmap = merge(typedef.hashset,
{
	type = function(var) return "Dictionary<" .. subtypename(var, var.k) .. ", " .. subtypename(var, var.v) .. ">" end,
	type_i = function(var) return "IDictionary<" .. subtypename(var, var.k) .. ", " .. subtypename(var, var.v) .. ">" end,
	new = function(var) return "\t\t\t#(var.name) = new Dictionary<" .. subtypename_new(var, var.k) .. subtypename_new() .. subtypename_new(var, var.v) .. ">(#(var.cap));\n" end,
	init = function(var) return "this.#(var.name) = new Dictionary<" .. subtypename_new(var, var.k) .. subtypename_new() .. subtypename_new(var, var.v) .. ">(#(var.cap)); if(#(var.name) != null) Util.addAll(this.#(var.name), #(var.name))" end,
	marshal = function(var) return string.format([[if(this.#(var.name).Count > 0)
			{
				s.marshal2(0x%04x).marshalUInt(this.#(var.name).Count);
				foreach(KeyValuePair<%s, %s> p in this.#(var.name))
					s.marshal(p.Key).marshal(p.Value);
			}]], var.id * 0x400 + 0x340 + subtypeid(var.k) * 8 + subtypeid(var.v), subtypename(var, var.k), subtypename(var, var.v)) end,
	unmarshal = function(var) return string.format([[case #(var.id):
				{
					this.#(var.name).Clear();
					if(t != 3) { s.unmarshalSkipVar(t); break; }
					t = s.unmarshalByte();
					if((t >> 6) != 1) { s.unmarshalSkipVarSub(t); break; }
					int k = (t >> 3) & 7; t &= 7;
					for(int n = s.unmarshalUInt(); n > 0; --n)
						this.#(var.name).Add(%s, %s);
				}]], get_unmarshal_kv(var, "k", "k"), get_unmarshal_kv(var, "v", "t")) end,
	assign = "this.#(var.name).Clear(); if(b.#(var.name) != null) Util.addAll(this.#(var.name), b.#(var.name))",
})
typedef.treemap = merge(typedef.hashmap,
{
	type = function(var) return "SortedDictionary<" .. subtypename(var, var.k) .. ", " .. subtypename(var, var.v) .. ">" end,
	type_i = function(var) return "IDictionary<" .. subtypename(var, var.k) .. ", " .. subtypename(var, var.v) .. ">" end,
	new = function(var) return "\t\t\t#(var.name) = new SortedDictionary<" .. subtypename_new(var, var.k) .. subtypename_new() .. subtypename_new(var, var.v) .. ">();\n" end,
	init = function(var) return "this.#(var.name) = new SortedDictionary<" .. subtypename_new(var, var.k) .. subtypename_new() .. subtypename_new(var, var.v) .. ">(); if(#(var.name) != null) Util.addAll(this.#(var.name), #(var.name))" end,
	assign = "this.#(var.name).Clear(); if(b.#(var.name) != null) Util.addAll(this.#(var.name), b.#(var.name))",
})
typedef.linkedhashmap = merge(typedef.hashmap,
{
	type = function(var) return "Dictionary<" .. subtypename(var, var.k) .. ", " .. subtypename(var, var.v) .. ">" end,
	type_i = function(var) return "IDictionary<" .. subtypename(var, var.k) .. ", " .. subtypename(var, var.v) .. ">" end,
	new = function(var) return "\t\t\t#(var.name) = new Dictionary<" .. subtypename_new(var, var.k) .. subtypename_new() .. subtypename_new(var, var.v) .. ">(#(var.cap));\n" end,
	init = function(var) return "this.#(var.name) = new Dictionary<" .. subtypename_new(var, var.k) .. subtypename_new() .. subtypename_new(var, var.v) .. ">(#(var.cap)); if(#(var.name) != null) Util.addAll(this.#(var.name), #(var.name))" end,
	assign = "this.#(var.name).Clear(); if(b.#(var.name) != null) Util.addAll(this.#(var.name), b.#(var.name))",
})
typedef.bean = merge(typedef.octets,
{
	type = function(var) return var.type end,
	type_i = function(var) return var.type end,
	type_o = function(var) return var.type end,
	subtypeid = 2,
	new = function(var) return "\t\t\t#(var.name) = new " .. var.type .. "();\n" end,
	init = function(var) return "this.#(var.name) = (#(var.name) != null ? (" .. var.type .. ")#(var.name).Clone() : new " .. var.type .. "())" end,
	reset = "#(var.name).reset()",
	assign = "this.#(var.name).assign(b.#(var.name))",
	marshal = function(var) return string.format([[{
				int n = s.size();
				this.#(var.name).marshal(s.marshal1((byte)0x%02x));
				if(s.size() - n < 3) s.resize(n);
			}]], var.id * 4 + 2) end,
	unmarshal = "case #(var.id): s.unmarshalBean(this.#(var.name), t);",
	unmarshal_kv = function(var, kv, t) if kv then return "(" .. typename(var, var[kv]) .. ")s.unmarshalBeanKV(new " .. typename(var, var[kv]) .. "(), " .. t .. ")" end end,
	compareto = "this.#(var.name).CompareTo(b.#(var.name))",
	tojson = "this.#(var.name).toJson(s.Append(\"\\\"#(var.name)\\\":\")).Append(',')",
	tolua = "this.#(var.name).toLua(s.Append(\"#(var.name)=\")).Append(',')",
})
typedef.boolean = typedef.bool
typedef.integer = typedef.int
typedef.binary = typedef.octets
typedef.bytes = typedef.octets
typedef.data = typedef.octets
typedef.array = typedef.vector
typedef.arraydeque = typedef.deque
typedef.arraylist = typedef.vector
typedef.linkedlist = typedef.list
typedef.set = typedef.hashset
typedef.linkedset = typedef.linkedhashset
typedef.map = typedef.hashmap
typedef.linkedmap = typedef.linkedhashmap

local function trim(s)
	return s:gsub("[%c ]+", "")
end
local function do_var(var)
	if var.id and (var.id < 1 or var.id > 62) then error("ERROR: id=" .. var.id .. " must be in [1, 62]") end
	if not var.id then var.id = 0 end
	var.id2 = string.format("%2d", var.id)
	var.name = trim(var.name)
	var.type = trim(var.type)
	if var.comment and #var.comment > 0 then var.comment = " // " .. var.comment:gsub("%c", " ") else var.comment = ""  end
	if type(var.value) == "string" then var.value = "\"" .. var.value .. "\"" end
	var.value = var.value and " = " .. var.value or ""
	local basetype
	basetype, var.k, var.v, var.cap = var.type:match "^%s*([%w_]+)%s*<?%s*([%w_]*)%s*,?%s*([%w_]*)%s*>?%s*%(?%s*([%w%._]*)%s*%)?%s*$"
	if not var.cap then var.cap = "" end
	local def = typedef[basetype]
	if not def and basetype == var.type then def = typedef.bean end
	if type(def) == "table" then
		for k, v in pairs(def) do
			if type(v) == "function" then v = v(var) end
			var[k] = v
		end
	else
		error("ERROR: unknown type: " .. var.type .. " => " .. basetype)
	end
end
local function code_conv(code, prefix, t)
	return code:gsub("#%(" .. prefix .. "%.([%w_]+)%)", function(name) return t[name] end)
end
local function gen_uid(s)
	local h = 0
	for i = 1, #s do
		h = h % 0x10000000000 * 4093 + 1 + s:byte(i)
	end
	return string.format("0xbeac%04x%08xL", math.floor(h / 0x100000000) % 0x10000, h % 0x100000000)
end

local name_code = {}
local type_bean = {}
local name_bean = {}
local handlers = {}
local hdl_types = {}
local bean_order = {}
local tables = {}
function handler(hdls)
	handlers = hdls
	for _, v in ipairs(hdls) do
		handlers[v.name] = v
	end
end
local function bean_common(bean)
	bean.name = trim(bean.name)
	if bean.name:find("[^%w_]") or typedef[bean.name] or bean.name == "AllBeans" or bean.name == "AllTables" then error("ERROR: invalid bean.name: " .. bean.name) end
	if name_code[bean.name] then error("ERROR: duplicated bean.name: " .. bean.name) end
	if type_bean[bean.type] then error("ERROR: duplicated bean.type: " .. bean.type) end
	if bean.type < 1 or bean.type > 0x7fffffff then error("ERROR: invalid bean.type: " .. bean.type) end
	for name in (bean.handlers or ""):gmatch("([%w_]+)") do
		if not handlers[name] then error("ERROR: not defined handle: " .. name) end
		hdl_types[name] = hdl_types[name] or {}
		hdl_types[name][#hdl_types[name] + 1] = bean.type
	end
	type_bean[bean.type] = bean
	name_bean[bean.name] = bean
	bean.comment = bean.comment and #bean.comment > 0 and "\n\t/**\n\t * " .. bean.comment:gsub("\n", "<br>\n\t * ") .. "\n\t */" or ""
end
local function bean_const(code)
	return code:gsub("public  /%*", "private /*"):
		gsub("\t\tpublic void assign%(.-\n\t\t}\n\n", ""):
		gsub("\t\tpublic void set.-\n\t\t}\n\n", ""):
		gsub("\t\tpublic override void reset%(.-\n\t\t}", [[
		public override void reset()
		{
			throw new NotSupportedException();
		}]]):
			gsub("\t\tpublic override OctetsStream unmarshal%(.-\n\t\t}", [[
		public override OctetsStream unmarshal(OctetsStream s)
		{
			throw new NotSupportedException();
		}]])
end
function bean(bean)
	bean_common(bean)

	local vartypes = { bean.name }
	for _, var in ipairs(bean) do
		do_var(var)
		if var.id > 0 then
			vartypes[#vartypes + 1] = var.type
		end
	end
	bean.uid = gen_uid(concat(vartypes))

	local code = template_bean:gsub("#{#(.-)#}#", function(body)
		local subcode = {}
		for _, var in ipairs(bean) do
			if var.id == 0 then subcode[#subcode + 1] = code_conv(body, "var", var) end
		end
		return concat(subcode)
	end):gsub("#%(#(.-)#%)#", function(body)
		local subcode = {}
		for _, var in ipairs(bean) do
			if var.id > 0 then subcode[#subcode + 1] = code_conv(code_conv(body, "var", var), "var", var) end
		end
		local code = concat(subcode)
		return code:sub(-2, -1) ~= ", " and code or code:sub(1, -3)
	end)

	bean.param_warning = (#bean > 0 and "" or "/** @param b unused */\n\t\t")
	name_code[bean.name] = code_conv(code, "bean", bean):gsub(#bean > 0 and "#[<>]#" or "#<#(.-)#>#", ""):gsub("\r", "")
	bean_order[#bean_order + 1] = bean.name
	if bean.const then name_code[bean.name] = bean_const(name_code[bean.name]) end
end

dofile "../../allbeans.lua"

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

local outpath = (arg[1] or "."):gsub("\\", "/")
if outpath:sub(-1, -1) ~= "/" then outpath = outpath .. "/" end
for name, code in pairs(name_code) do
	checksave(outpath .. namespace .. "/bean/" .. name .. ".cs", code, 0)
end

checksave(outpath .. namespace .. "/bean/AllBeans.cs", (template_allbeans:gsub("#%[#(.-)#%]#", function(body)
	local subcode = {}
	for _, hdl in ipairs(handlers) do
		local types = hdl_types[hdl.name] or {}
		hdl.count = #types
		subcode[#subcode + 1] = code_conv(body:gsub("#%(#(.-)#%)#", function(body)
			local subcode2 = {}
			for _, type in ipairs(types) do
				local bean = type_bean[type]
				subcode2[#subcode2 + 1] = code_conv(body, "bean", bean)
				if not bean.arg then
					checksave(outpath .. hdl.path:gsub("%.", "/") .. "/" .. bean.name .. "Handler.cs", code_conv(code_conv(template_bean_handler:gsub("#%(#(.-)#%)#", function(body)
						local subcode3 = {}
						for _, var in ipairs(bean) do
							subcode3[#subcode3 + 1] = code_conv(body, "var", var)
						end
						return concat(subcode3)
					end), "hdl", hdl), "bean", bean):gsub("\r", ""), 1, "(%s+class%s+" .. bean.name .. "Handler%s+extends%s+BeanHandler%s*<)[%w_%s]+>", "%1" .. bean.name .. ">")
				end
			end
			return concat(subcode2)
		end), "hdl", hdl)
	end
	return concat(subcode)
end):gsub("#%(#(.-)#%)#", function(body)
	local subcode = {}
	for _, beanname in ipairs(bean_order) do
		local bean = name_bean[beanname]
		subcode[#subcode + 1] = code_conv(body, "bean", bean)
	end
	return concat(subcode)
end)):gsub(#handlers > 0 and "#[<>]#" or "#%<#(.-)#%>#", ""):gsub("#%(bean.count%)", #bean_order):gsub("\r", ""), 0)

print "completed!"
