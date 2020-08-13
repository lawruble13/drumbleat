pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

bignum = {
	sign=1,
	thous={0}
}
function bignum:new(o)
	o = o or {}
	if type(o) == "number" then
		o={sign=sgn(o),thous={flr(o)}}
		if o.thous[1]>=1000 then
			o.thous[2]=o.thous[1]\1000
			o.thous[1]%=1000
		end
	end
	self.__index = self
	return setmetatable(o, self)
end

function bignum.__tostring(o)
	local str=""
	for v in all(o.thous) do
		str = tostr(v)..str
	end
	if (o.sign == -1) str="-"..str
	return str
end

function bignum.__len(o)
	local t = (#o.thous-1)*3+1
	local i = #o.thous
	if (o.thous[i] >= 10) t += 1
	if (o.thous[i] >= 100) t += 1
	return t
end

function bignum.__eq(o1,o2)
	if (o1.sign != o2.sign) return false
	if (#o1.thous != #o2.thous) return false
	for i=1,#o1.thous do
		if (o1.thous[i] != o2.thous[i]) return false
	end
	return true
end

function bignum.__lt(v1,v2)
	if (type(v1) == "number") v1=bignum:new(v1)
	if (type(v2) == "number") v2=bignum:new(v2)
	if (v1.sign < v2.sign) return true
	if v1.sign == -1 then
		if (#v1.thous < #v2.thous) return false
		if (#v1.thous > #v2.thous) return true
		for i=#v1.thous,1,-1 do
			if (v1.thous[i] < v2.thous[i]) return false
			if (v1.thous[i] > v2.thous[i]) return true
		end
		return false
	else
		if (#v1.thous < #v2.thous) return true
		if (#v1.thous > #v2.thous) return false
		for i=#v1.thous,1,-1 do
			if (v1.thous[i] < v2.thous[i]) return true
			if (v1.thous[i] > v2.thous[i]) return false
		end
		return false
	end
end

function bignum.__le(v1,v2)
	if (type(v1) == "number") v1=bignum:new(v1)
	if (type(v2) == "number") v2=bignum:new(v2)
	if (v1.sign < v2.sign) return true
	if v1.sign == -1 then
		if (#v1.thous < #v2.thous) return false
		if (#v1.thous > #v2.thous) return true
		for i=#v1.thous,1,-1 do
			if (v1.thous[i] < v2.thous[i]) return false
			if (v1.thous[i] > v2.thous[i]) return true
		end
		return true
	else
		if (#v1.thous < #v2.thous) return true
		if (#v1.thous > #v2.thous) return false
		for i=#v1.thous,1,-1 do
			if (v1.thous[i] < v2.thous[i]) return true
			if (v1.thous[i] > v2.thous[i]) return false
		end
		return true
	end
end

function bignum.__add(v1,v2)
	if (type(v1) == "number") v1=bignum:new(v1)
	if (type(v2) == "number") v2=bignum:new(v2)
	if v1.sign == 1 and v2.sign == 1 then
		local carry = 0
		local i = 1
		local t = 0
		while i <= #v1.thous or i <= #v2.thous or carry > 0 do
			if v1.thous[i] then
				t = v1.thous[i]
				t += carry
				if (v2.thous[i]) then
					t += v2.thous[i]
				end
			elseif v2.thous[i] then
				t = v2.thous[i] + carry
			else
				t = carry
			end				
			carry=t\1000
			v1.thous[i]=t%1000
			i += 1
		end
	elseif v1.sign == 1 and v2.sign == -1 then
		v2.sign = 1
		v1=v1-v2
	elseif v1.sign == -1 and v2.sign == 1 then
		v1.sign = 1
		v1=v2-v1
	else
		v1.sign = 1
		v2.sign = 1
		v1=v1+v2
		v1.sign = -1
	end
	return v1
end

function bignum.__sub(v1,v2)
	if (type(v1) == "number") v1=bignum:new(v1)
	if (type(v2) == "number") v2=bignum:new(v2)
	if v1.sign == 1 and v2.sign == 1 then
		if v1<v2 then
			v1=v2-v1
			v1.sign=-1
			return v1
		elseif v1 == v2 then
			return bignum:new()
		else
			local borrow = 0
			for i=1,#v1.thous do
				v1.thous[i] -= borrow
				borrow = 0
				if v2.thous[i] then
					if (v1.thous[i] < v2.thous[i]) then
						v1.thous[i] += 1000
						borrow = 1
					end
					v1.thous[i] -= v2.thous[i]
				end
			end
			return v1
		end
	elseif v1.sign != v2.sign then
		v2.sign *= -1
		return v1+v2
	else
		v1.sign=1
		v2.sign=1
		return v2-v1
	end
end

function bignum.__mul(v1,v2)
	if (type(v1) == "number") v1=bignum:new(v1)
	if (type(v2) == "number") v2=bignum:new(v2)
	if v1 == bignum:new() or v2 == bignum:new() then
		return bignum:new()
	end
	local s = v1
	local l = v2
	if #v2 < #v1 then
		s=v2
		l=v1
	end
	local res = bignum:new({sign=s.sign*l.sign})
	local pow_ten = 0
	
end

function _init()
	bn = bignum:new()
end

function _update()
	cls(0)
	bn = bn - 100
end

function _draw()
	color(7)
	print(bn)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
