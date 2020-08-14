pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

bignum = {}
function bignum:new(o)
	if type(o) == "number" then
		o=flr(o)
		local tmp={}
		tmp.sign=sgn(o)
		o=abs(o)
		tmp.huns={
			o%100,
			(o\100)%100,
			o\10000
		}
		o=tmp
		if o.huns[3] == 0 then
			deli(o.huns,3)
			if (o.huns[2] == 0) deli(o.huns,2)
		end
	elseif type(o) == "table" then
		local tmp = {}
		tmp.sign=o.sign or 1
		tmp.huns={}
		for v in all(o.huns) do
			add(tmp.huns,v)
		end
		o=tmp
	elseif type(o) == "nil" then
		o={sign=1,huns={0}}
	end
	self.__index = self
	return setmetatable(o, self)
end

function bignum:clrz()
	local i=#self.huns
	while i > 1 do
		if self.huns[i] == 0 then
			deli(self.huns,i)
		else
			break
		end
		i -= 1
	end
end

function bignum.__tostring(o)
	local str=""
	for i,v in ipairs(o.huns) do
		local toadd=tostr(v)
		if (i != #o.huns and #toadd == 1) toadd="0"..toadd
		str = toadd..str
	end
	if (o.sign == -1) str="-"..str
	return str
end

function bignum.__len(o)
	local t = (#o.huns-1)*2+1
	local i = #o.huns
	if (o.huns[i] >= 10) t += 1
	return t
end

function bignum:rel_ind(other)
	if (type(other) == "number") other=bignum:new(other)
	assert(other.sign)
	assert(other.huns)
	if (#self.huns == 1 and self.huns[1] == 0 and #other.huns == 1 and other.huns[1] == 0) return 0
	if (self.sign < other.sign) return -1
	if (self.sign > other.sign) return 1
	if (#self.huns < #other.huns) return -self.sign
	if (#self.huns > #other.huns) return self.sign
	for i=#self.huns,1,-1 do
		if (self.huns[i] < other.huns[i]) return -self.sign
		if (self.huns[i] > other.huns[i]) return self.sign
	end
	return 0
end

function bignum.__eq(v1,v2)
	return v1:rel_ind(v2) == 0
end

function bignum.__lt(v1,v2)
	v1,v2=make_bn_pair(v1,v2)
	return v1:rel_ind(v2) < 0
end

function bignum.__le(v1,v2)
	v1,v2=make_bn_pair(v1,v2)
	return v1:rel_ind(v2) <= 0
end

function bignum.__unm(v)
	local o = bignum:new(v)
	o.sign *= -1
	return o
end

function bignum.__add(v1,v2)
	v1,v2=make_bn_pair(v1,v2)
	local res = bignum:new(v1)
	if v1.sign == 1 and v2.sign == 1 then
		local carry = 0
		local i = 1
		local t = 0
		while i <= #v1.huns or i <= #v2.huns or carry > 0 do
			t=0
			if v1.huns[i] then
				t += v1.huns[i]
			end
			if v2.huns[i] then
				t += v2.huns[i]
			end				
			t += carry
			carry=t\100
			res.huns[i]=t%100
			i += 1
		end
	elseif v1.sign == 1 and v2.sign == -1 then
		res=v1-(-v2)
	elseif v1.sign == -1 and v2.sign == 1 then
		res=v2-(-v1)
	else
		res=-((-v1)+(-v2))
	end
	return res
end

function bignum.__sub(v1,v2)
	v1,v2=make_bn_pair(v1,v2)
	local res=bignum:new()
	if v1.sign == 1 and v2.sign == 1 then
		if v1<v2 then
			return -(v2-v1)
		elseif v1 == v2 then
			return bignum:new()
		else
			local res = bignum:new(v1)
			local borrow = 0
			for i=1,#res.huns do
				if borrow > 0 then
					res.huns[i] -= borrow
					borrow = 0
					if res.huns[i] < 0 then
						res.huns[i] += 100
						borrow = 1
					end
				end
				if v2.huns[i] then
					if (res.huns[i] < v2.huns[i]) then
						res.huns[i] += 100
						borrow = 1
					end
					res.huns[i] -= v2.huns[i]
				end
			end
			res:clrz()
			return res
		end
	elseif v1.sign != v2.sign then
		return v1+(-v2)
	else
		return (-v2)-(-v1)
	end
end

function bignum.__mul(v1,v2)
	v1,v2=make_bn_pair(v1,v2)
	if (v1 > v2) then
		return v2*v1
	end
	local res = bignum:new()
	local i=0
	local j=0
	while i < #v1.huns do
		while j < #v2.huns do
			local tmp = v1.huns[i+1]*v2.huns[j+1]			
			local ind=i+j+1
			if (not res.huns[ind]) res.huns[ind] = 0			
			while tmp > 0 do
				if (res.huns[ind]) tmp += res.huns[ind]
				res.huns[ind] = tmp%100
				tmp \= 100
				ind += 1
			end
			j += 1
		end
		i += 1
		j=0
	end
	res.sign=v1.sign*v2.sign
	res:clrz()
	return res
end

function make_bn_pair(v1,v2)
	if (type(v1) != "table") v1=bignum:new(v1)
	if (type(v2) != "table") v2=bignum:new(v2)
	return v1,v2
end

function _init()
	bn1 = bignum:new(1000)
	bn2 = bignum:new(1000)
	op = 0
	bni = 1
	failed_test = nil
end

function _update()
	if not failed_test then
		for i=-128,128 do
			for j = -128, 128 do
				local a=bignum:new(i)
				local b=bignum:new(j)
 			if (i < j and not (a < b) and not failed_test) failed_test="lt "..i..","..j
				if (i > j and not (a > b) and not failed_test) failed_test="gt "..i..","..j
				if (i == j and not (a == b) and not failed_test) failed_test="eq "..i..","..j
				if (bignum:new(i+j) != a + b and not failed_test) failed_test="pl "..i.."+"..j.."!="..tostr(bignum:new(i+j))
				if (bignum:new(i-j) != a - b and not failed_test) failed_test="mn "..i.."-"..j.."!="..tostr(bignum:new(i-j))
				if (bignum:new(i*j) != a * b and not failed_test) failed_test="tm "..tostr(a).."*"..tostr(b).." == "..tostr(a*b).."!="..tostr(bignum:new(i*j))
			end
			if (failed_test) break
		end
	end
	if (not failed_test) failed_test="none"
	cls(0)
	if btnp(0) then
		if (bni == 1) bn1 -= 1
		if (bni == 2) bn2 -= 1
	elseif btnp(1) then
		if (bni == 1) bn1 += 1
		if (bni == 2) bn2 += 1
	elseif btnp(2) or btnp(3) then
		bni = 3-bni
	elseif btnp(4) or btnp(5) then
		op += 1
		op %= 5
	end
end

function _draw()
	print(failed_test)
	color(7+(2-bni))
	print(tostr(bn1))
	color(7)
	if op == 0 then
		print("+")
	elseif op == 1 then
		print("-")
	elseif op == 2 then
		print("*")
	elseif op == 3 then
		print(">")
	elseif op == 4 then
		print("<")
	end
	color(7+(bni-1))
	print(bn2)
	color(7)
	print("----------------")
	if (op == 0) print(bn1+bn2)
	if (op == 1) print(bn1-bn2)
	if (op == 2) print(bn1*bn2)
	if (op == 3) print(tostr(bn1>bn2))
	if (op == 4) print(tostr(bn1<bn2))
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
