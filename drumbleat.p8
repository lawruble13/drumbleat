pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- drumbleat
-- starring totes the goat

-- lowrez 2020 basic functions

function _init()	
	-- set me to step thru frames
	fstep=false
	debug_info=false
	record_state=false
	record_tiles=false
	general_debug=false
	reset_high_score=false
	platform_below=false
	queue_stop=false
	
	cartdata("lawruble13_drumbleat_2")
	if (reset_high_score) then
		store_score(bignum:new())
	end
	
	init_bg()
	init_br()
	init_gw()
	init_pl()
	if platform_below then
		add(gw.platforms,platform_cls:new({y=gw.cy-1,l=48}),1)
	end
	gw.stored_hs = get_stored_score()
	gw.shown_instructions = false
	
	if not debug_info then
		-- when debugging, game tl,
		-- info other space
		poke(0x5f2c,3) -- 64 x 64	
	end

	if (record_state) csv_print_file("state.csv","state",{gw=gw,pl=pl,but=peek(0x5f4c)},true)
	setpal()
	music(0)
end

function _update60()
	if (queue_stop) stop()
	local dy = pl.y
	if record_state then
		csv_print_file("state.csv","state",{gw=gw,pl=pl,but=peek(0x5f4c)})
		-- btn(4) is 'z' by default
		if (btn(4)) record_state=false
	end
	if not fstep or btnp(4) then
		if gw.mode == "game" then
			if 0x34 & @0x5f4c > 0 then
				pl.js=(not pl.jh) or (fstep and 0x24 & @0x5f4c > 0)
				pl.jh=true
			else
				pl.js=false
				pl.jh=false
			end
			update_player_speed()
			move_player()
			if platform_below then
				gw.platforms[1].y=gw.cy-1
			end
			check_platforms()
			check_powerups()
		elseif gw.mode == "menu" or gw.mode == "over" or gw.mode == "credits" or gw.mode == "inst1" or gw.mode == "inst2" then
			update_buttons()
		end
	end
	check_music()
	dy = pl.y-dy
	if abs(dy) > 10 then
		printh(dump_str({pl,gw}))
		printh(dump_str({pl,gw}),"out.log",true)
		stop("an error has been encountered. please inform the developer.",0,0)
	end
end

function _draw()
 background()
 set_camera()
	if gw.mode == "game" then
	 for pt in all(gw.platforms) do
 		platform(pt)
	 end
	 for pu in all(gw.powerups) do
	 	powerup(pu)
	 end
	 player()
	 draw_score()
	elseif gw.mode == "menu" then
		draw_logo()
		draw_buttons()
	elseif gw.mode == "over" then
		draw_final_dist()
		if gw.nhs then
			draw_high_score()
		else
			draw_best_distance()
		end
		draw_buttons()
	elseif gw.mode == "credits" then
		draw_credits()
		draw_buttons()
	end
	camera(0,0)
 border()
 draw_alert()
 notebar()
 draw_instructions()
 if debug_info then
	 show_debug()
 end
end
-->8
--lowrez drawing functions
function setpal()
	pal(1,140,1)
	pal(2,141,1)
	pal(5,1,1)
	pal(11,132,1)
	pal(14,134,1)
	pal(15,137,1)
end

function player()
	if pl.pu then
		pl.w=16
		if pl.pu.dur > stat(8) or pl.pu.dur%2 == 1 then
			pal(3,pl.pu.col)
			palt(3,false)
		else
			pal(3,0)
			palt(3,true)
		end
		pl.pu.dur -= 1			
		if (pl.pu.dur == 0) pl.pu=nil
	else
		pal(3,0)
		palt(3,true)
		pl.w=15
	end
	if pl.stn then
		pl.sn=17
		if (gw.offset+pl.y)*10 > pl.score then
			pl.score = (gw.offset+pl.y)*7
		end
	else
		pl.sn=1
	end
	spr(pl.sn,pleft(),ptop(),pl.w/8,pl.h/8,pl.fl)
	if pl.y < gw.cy-pl.h then
		min_t = stat(8)*1.5
		local nhs = gw.nhs
		if nhs then
			store_score(pl.score)
		end
		init_gw()
		gw.mode = "over"
		gw.stored_hs = get_stored_score()
		gw.nhs=nhs
		gw.last_score = pl.score
		init_pl()
		reset_tiles()
	end
end

function platform(pt)
	local lx=flr(sqrt(pt.l^2/(pt.m^2+1)))
	for dx=0,lx do
		local x=pt.x+dx
		local y=flr(pt.y+dx*pt.m)
		local ax=x+gw.lx
		if pt.h_dark[dx+1] then
			local i=1
			while i <= pt.h_dark[dx+1] do
				pset(ax,gw.by-y+i,1)
				i += 1
			end
			i=1
			while i <= pt.h_light[dx+1] do
				pset(ax,gw.by-y+i,12)
				i += 1
			end
		else
			pset(ax,gw.by-y+1,12)
		end
		pset(ax,gw.by-y,7)
	end
end

function draw_specs(specs)
	for s in all(specs) do
		local w=s[3]*8
		local h=s[4]*8
		local f=s[8]
		for x=s[1],s[1]+s[6]*w,w do
			for y=s[2],s[2]+s[7]*h,h do
				spr(s[5],x,y,w/8,h/8,f&1>0,f&2>0)
			end
		end
	end
end

do
	local snowflakes = {}
	local d_sf_count = 0
	function draw_snowfall()
		if rnd(30) < 1 then
			if gw.mode == "game" then
				add(snowflakes, {x=gw.lx+flr(rnd(gw:w())),y=0})
			else
				add(snowflakes, {x=flr(rnd(64)),y=0})
			end
		end
		d_sf_count += 1
		d_sf_count %= 8
		for sf in all(snowflakes) do
			if d_sf_count == 0 then
				sf.y += 1
			end
			if (gw.mode != "game") or sf.x >= gw.lx then
				pset(sf.x,sf.y,7)
			end
			if sf.y > 64 then
				del(snowflakes,sf)
			end
		end
	end
end

do
	local cam_pos = -1
	local last_mul = 0
	function background()
		if gw.mode == "game" or gw.mode == "inst2" then
			cls(6)
			clip(gw.lx,gw.ty,gw.rx-gw.lx,gw.by-gw.ty)
			if bg.tiles then
				if last_mul < gw.cy\16 then
					tile_bg(4)
					last_mul = gw.cy\16
				end
				local y_off = flr(gw.cy)%16
				for i, c in ipairs(bg.tiles) do
					if c>0 then
						local n=5+2*(c%2)+32*(c\2)
						local t=i-1
						spr(n,16*(t%4),16*(t\4)-16+y_off,2,2)
					end
				end
			end
			clip()
		elseif gw.mode == "menu" or gw.mode == "over" or gw.mode == "credits" or gw.mode == "inst1" then
			cls(10)
		elseif gw.mode == "intro" then
			if stat(24) > 0 then
				gw.mode = "menu"
			end
			cls(10)
			cam_pos = max(cam_pos,stat(26)/511-1)
			
			camera(0,64*cam_pos)
		end
		draw_specs(bg.spr[gw.mode])
		if (gw.mode != "intro") draw_snowfall()
	end
	
	function reset_tiles()
		last_mul = 0
	end
end

function border()
	draw_specs(br.spr[gw.mode])
end

function set_camera()
	local h=gw.by-gw.ty
	if pl.stn and pl.y > 0.4 * h+gw.cy then
		gw.cyt = pl.y-0.4*h
	end
	if pl.y > 0.8*h+gw.cy then
		gw.cy = pl.y-0.8*h
	elseif gw.cy < gw.cyt then
		gw.cy += min(0.3,gw.cyt-gw.cy)
	end
	if gw.cy > 10000 then
		gw.cy -= 10000
		gw.cyt -= 10000
		pl.y -= 10000
		for pt in all(gw.platforms) do
			pt.y -= 10000
		end
		for pu in all(gw.powerups) do
			pu.y -= 10000
		end
		gw.npu -= 10000
		gw.offset += 10000
		reset_tiles()
	end
	camera(0,-gw.cy)	
end

do
	function draw_logo()
		spr(64,11,20+(stat(26)%128)\64,6,4)
	end
	
	function draw_buttons()
		if not min_t or min_t <= 0 then
			local os = (stat(26)%128)\64
			if gw.selected == 0 then		
				pal(3,15)
				palt(3,false)
			else
				pal(3,0)
				palt(3,true)
			end
			spr(33,20+os,49,2,2)
			spr(52,22+os,51)
			if gw.selected == 1 then		
				pal(3,15)
				palt(3,false)
			else
				pal(3,0)
				palt(3,true)
			end
			spr(33,35+os,49,2,2)
			spr(0,37+os,51)
		end
	end
end

function text_box(str,y,snowy)
	local boxspec = {
		{4 ,y,1  ,1,86,0 ,0,0},
		{12,y,1/4,1,87,19,0,0},
		{52,y,1  ,1,87,0 ,0,0}
	}
	local x=32-str_disp_width(str)/2
	if not snowy then
		for item in all(boxspec) do
			item[5] -= 16
			item[4] = 7/8
		end
		cursor(x,y+1)
	else
		cursor(x,y+2)
	end
	draw_specs(boxspec)
	color(5)
	print(str)
end

function tall_text_box(str1,str2,y)
	local boxspec = {
		{4,y,1,1,61,0,0,0},
		{12,y,1/4,1,62,19,0,0},
		{52,y,1,1,62,0,0,0},
		{4,y+7,1,1,77,0,0,0},
		{12,y+7,1/4,1,78,19,0,0},
		{52,y+7,1,1,78,0,0,0}
	}
	draw_specs(boxspec)
	cursor(32-str_disp_width(str1)/2,y+2)
	color(5)
	print(str1)
	cursor(32-str_disp_width(str2)/2,y+8)
	print(str2)
end

function draw_final_dist()
	tall_text_box("distance",tostr(gw.last_score),14)
end

function draw_high_score()
	text_box("high score!",31,true)
end

function draw_best_distance()
	text_box("prev best:",31,true)
	text_box(tostr(gw.stored_hs),40,false)
end

function powerup(pu)
	pu.timer += 1
	pu.timer %= 2*pu.period
	pal(3,3)
	palt(3,false)
	if stat(26)%64<32 then
		spr(pu.sn1,gw.lx+pu.x,gw.by-pu.y-pu.h1,pu.w1/8,pu.h1/8)
	else
		spr(pu.sn2,gw.lx+pu.x,gw.by-pu.y-pu.h2,pu.w2/8,pu.h2/8)
	end
end

function notebar()
	if gw.mode == "game" or gw.mode == "inst2" then
		local eob = (stat(26)+128)%256-192
		local nby = 35+24*max(eob,-128-eob)/64
		spr(30,1,nby,1.25,3/8)
	end
end

do
	local alert_str = ""
	local alert_dur = 0
	function alert(str,dur)
		alert_str = str or ""
		alert_dur = dur or stat(8)
	end
	
	function draw_alert()
		if alert_dur > 0 then
			text_box(alert_str,2,false)
			alert_dur -= 1
		end
	end
end

function draw_score()
	if gw.drawn_score < pl.score then
		if gw.drawn_score+5 > pl.score then
			gw.drawn_score=pl.score
		else
			gw.drawn_score += 5
		end
	end
	if pl.score > gw.stored_hs and gw.mode == "game" and not gw.nhs then
		alert("high score!")
		gw.nhs=true
	end
	color(5)
 camera(0,0)
 cursor(gw.lx+1, gw.ty+1)
 print(gw.drawn_score,5)
end

function draw_credits()
	tall_text_box("art: hannah","zaitlin",4)
	tall_text_box("music: jon","malley",19)
	tall_text_box("code: liam","wrubleski",34)
end

function draw_instructions()
	if gw.mode == "inst1" then
		text_box("left/right",4,true)
		pal(3,0)
		palt(3,true)
		spr(33,19,12,1.5,1.5)
		spr(51,21,14,1,1)
		spr(33,33,12,1.5,1.5)
		spr(52,35,14,1,1)
		text_box("jump/select",24,true)
		spr(33,13,32,1.5,1.5)
		spr(130,15,34,1,1)
		spr(33,26,32,1.5,1.5)
		spr(129,28,34,1,1)
		spr(33,39,32,1.5,1.5)
		spr(132,41,34,1,1)
		pal(3,15)
		palt(3,false)
		spr(33,26+(stat(26)%128)\64,46,1.5,1.5)
		spr(52,28+(stat(26)%128)\64,48,1,1)
	elseif gw.mode == "inst2" then
		spr(144,gw.lx+1,16,6,5)
		local str="jump on"
		cursor(ceil((gw.lx+gw.rx+1)/2)-#str*2,20)
		color(5)
		print(str)
		local cur_x = ceil((gw.lx+gw.rx+1)/2)-(11)*2+1
		cursor(cur_x,28)
		print("the")
		cur_x += 15
		cursor(cur_x,28)
		local eob=(stat(26)+64)%128
		if min(eob,128-eob) < 10 then
			color(15)
		end
		print("beat")
		cursor(cur_x+19,28)
		color(5)
		print("to")
		str="go higher"
		cursor(ceil((gw.lx+gw.rx+1)/2)-#str*2,36)
		print(str)
		pal(3,15)
		palt(3,false)
		spr(33,ceil((gw.lx+gw.rx+1)/2)-6+(stat(26)%128)\64,46,1.5,1.5)
		spr(52,ceil((gw.lx+gw.rx+1)/2)-4+(stat(26)%128)\64,48,1,1)
	end
end
-->8
--lowrez physics functions
function move_player()
	local n_steps=8
	for i=1,n_steps do
		local wall = true
		local _pt = nil
		local bc = wall_collide()
		local active_x = 0
		for pt in all(gw.platforms) do
			local coll = false
			for offset in all(pl.offsets) do
				local os_x = pl.x-pl.w/2
				if pl.fl then
					os_x += pl.w-1-offset
				else
					os_x += offset
				end
				local bcp=pt_collide(pt,os_x)
				if bcp < bc then
					bc=bcp
					wall=false
					_pt=pt
				end
			end
		end
		for pu in all(gw.powerups) do
			local w=pu.w1
			local h=pu.h1
			if pu.timer >= pu.period then
				w=pu.w2
				h=pu.h2
			end
			if pleft() - gw.lx < pu.x+w and pright() - gw.lx >= pu.x
				and gw.by-pbottom()+1 < pu.y+h and gw.by-ptop()+1 >= pu.y then
				del(gw.powerups, pu)
				pl.pu=pu
				if pu.type == 0 then
					alert("double jump")
				elseif pu.type == 1 then
					alert("high jump")
				elseif pu.type == 2 then
					alert("sticky")
				end
			end
		end
		if bc <= 1/n_steps then
			pl.x += bc*pl.vx
			pl.y += bc*pl.vy
			if wall then
				if pl.stn then
					pl.vx = 0
					pl.vy = 0
				else
					pl.vx *= -0.5
				end
			else
				local m = _pt.m
				local k = dot(pl.vx,pl.vy,1,m)/dot(1,m,1,m)
				pl.vx = k
				pl.vy = k*m
				printh("in col, b4 clip")
				pl.y=_pt.y+m*(pl.x-_pt.x)
				pl.spt=_pt
			end
		else
			pl.x += pl.vx/n_steps
			pl.y += pl.vy/n_steps
		end
	end
	local pt=pl.spt
	if pt then
		for offset in all(pl.offsets) do
			local os_x = pl.x-pl.w/2
			if pl.fl then
				os_x += pl.w-1-offset
			else
				os_x += offset
			end
			local os_y = pl.y+pt.m*(os_x-pl.x)
			if on_floor(pt,os_x,os_y) then
				pl.stn=true
				printh("in c2flr b4 clip")
				pl.y=pt.y+pt.m*(pl.x-pt.x)
				return
			end
		end
		pl.stn=false
		pl.spt=nil
	end
end

function on_floor(pt,x,y)
	x=x or pl.x
	y=y or pl.y
	return (
		(x >= pt.x) and 
		(abs(y-(pt.y+pt.m*(x-pt.x))) <= 0.5) and
	 (len(x-pt.x,y-pt.y) <= pt.l)
	)
end

function wall_collide()
 --check left wall collision
 d=gw.lx-pleft() -- < 0
 if d > pl.vx then
 	return d/pl.vx
 end
 --check right wall collision
 d=gw.rx-pright()+1
 if pl.vx > d then
 	return d/pl.vx
 end
 return 1
end

function dot(x1,y1,x2,y2)
	return x1*x2+y1*y2
end

function len(x,y)
	return sqrt(x^2+y^2)
end

function pt_collide(pt, x, y, vx, vy)
	x=x or pl.x
	y=y or pl.y
	vx=vx or pl.vx
	vy=vy or pl.vy
	local d = dot(vx,vy,-pt.m,1)
	local v = len(vx,vy)
	local t = 1
	if (d > 0) return 1
	-- speed one of down towards
	-- pt, along pt, or 0
	if (d == 0) then
		-- speed either along pt or 0
		if on_floor(pt,x,y) then
			return 1
			-- means we can move when
			-- standing on a platform
		elseif on_floor(pt,x+vx,y+vy) then
-- b/c on_floor(pt) false, 
-- speed is not 0. ergo,  speed
-- is along pt. pt  slope 
-- limited between -1, 1 means
-- vx != 0, regardless of vy

-- also know on line of pt,
-- so this approx valid
			local l=(pt.x-x)*len(1,pt.m)
			if vx > 0 then
			-- on pt after moving right,
			-- so l>0
				t = l/v
			elseif vx < 0 then
			-- on pt after moving left,
			-- so l<0, and l+pt.l<0
				t = -(pt.l+l)/v
			end
			if (t < 0) printh("very bad error!","error.log",true)
			if t < 1 then
				return t
			end
		end
		return 1
		-- catch speed = 0, etc
	end
	local k=dot(pt.x,pt.y,-pt.m,1)
	t=(k-dot(x,y,-pt.m,1))/d
	if t > 0 and t < 1 then
		--possible collision
		x += vx*t
		y += vy*t
		if on_floor(pt,x,y) then
			-- collision!
			return t
		end
	end
	return 1
end

function update_player_speed()
	local eob=(stat(26)+64)%128
	local jh=2-min(eob,128-eob)/64
	print_debug("jump h: "..jh)
	if (pl.stn) then
		local pt = pl.spt
		local k=1/pt:hyp()
		local v=len(pl.vx,pl.vy)
		local dv = pt.m
		if pl.pu and pl.pu.type == 2 then
			dv = 0
		else
			dv *= -0.09
		end
		pl.doublejump = false
		
		if (btn(0)) then
			dv -= 0.1
			pl.fl = true
		elseif (btn(1)) then
			dv += 0.1
			pl.fl = false
		elseif pt.m==0 or (pl.pu and pl.pu.type == 2) then
			dv = -pl.vx/k
		end
		
		dv=mid(-0.1,dv,0.1)
		
		pl.vx += dv*k
		pl.vy += dv*pt.m*k
		v=len(pl.vx,pl.vy)
		if v > 0.5 then
			pl.vx /= 2*v
			pl.vy /= 2*v
		end
		
		if pl.js then
			pl.stn = false
			pl.spt = nil
			if pl.pu and pl.pu.type == 1 then
				pl.vy += jh+1
			else
				pl.vy += jh
			end
			sfx(8)
		end
	else
		if (btn(0) and pl.vx > -2) then
			pl.vx -= 0.1
			pl.fl = true
		elseif (btn(1) and pl.vx < 2) then
			pl.vx += 0.1
			pl.fl = false
		elseif (pl.vx > 0) then
			pl.vx -= min(0.025,pl.vx)
		elseif (pl.vx < 0) then
			pl.vx -= max(-0.025,pl.vx)
		end
		if (pl.pu and pl.pu.type == 0) then
			if (not pl.doublejump) and pl.js then
				if pl.vy < 0 then
					pl.vy = jh
				else
					pl.vy += jh+0.0625
				end
				sfx(8)
				pl.doublejump = true
			end
		end
		if (pl.vy > -2.5) pl.vy -= 0.0625		
	end
end
-->8
--lowrez player util functions
function pleft()
 return gw.lx + pl.x - pl.w/2
end

function pright()
 return gw.lx + pl.x + pl.w/2 - 1
end

function ptop()
	return gw.by+1-pl.y-pl.h
end

function pbottom()
 return gw.by-pl.y
end
-->8
-- lowrez init functions
function init_bg()
	bg={}
	bg.spr={}
	bg.spr.game={
 	{3,20,1,5,27,0,0,0},
 	--{3,57,1,1,46,0,0,0},
 	{13,54,1,1,45,0,0,0},
 	{18,54,1,1,46,4,0,0},
 	{54,54,1,1,47,0,0,0},
	}
	bg.spr.menu={
		{0,5,1,3,16,7,0,0},
		{0,0,8,8,136,0,0,0}
	}
	bg.spr.intro=bg.spr.menu
	bg.spr.over=bg.spr.menu
	bg.spr.credits=bg.spr.menu
	bg.spr.inst1=bg.spr.credits
	bg.spr.inst2=bg.spr.game
	bg.tiles={}
	tile_bg(20,20)
	bg.offset=0
end

function init_br()
	br={}
	br.spr={}
	br.spr.game={
 	{0,0,2,3,9,0,0,0},
 	{16,0,1,1,11,4,0,0},
 	{56,0,1,1,12,0,0,0},
 	{56,8,1,1,14,0,5,0},
 	{0,24,2,1,57,0,3,0},
 	{0,56,2,1,73,0,0,0},
 	{16,56,1,1,13,4,0,0},
 	{56,56,1,1,15,0,0,0}
 }
	br.spr.menu={
 	{0, 0, 1,1,12,0,0,1},
 	{8, 0, 1,1,11,5,0,0},
 	{56,0, 1,1,12,0,0,0},
 	{0, 8, 1,1,14,0,5,1},
 	{56,8, 1,1,14,0,5,0},
 	{0, 56,1,1,15,0,0,1},
 	{8, 56,1,1,13,5,0,0},
 	{56,56,1,1,15,0,0,0}
 }	
 br.spr.intro=br.spr.menu
 br.spr.over=br.spr.menu
 br.spr.credits=br.spr.menu
 br.spr.inst1=br.spr.menu
 br.spr.inst2=br.spr.game
end

function init_gw()
	gw = {
		lx=13,
		rx=61,
		ty=3,
		by=61,
		cy=0,
		cyt=0,
		drawn_score=bignum:new(),
		offset=bignum:new(),
		w=function(self)
			return self.rx-self.lx+1
		end,
		shown_instructions=true
	}
	gw.platforms={}
	gw.platforms[1]=platform_cls:new({l=48})
	
	gw.powerups={}
	gw.npu = 70
	
	gw.mode="intro"
	gw.selected=0
	
	gw.stored_hs=bignum:new()
end

function init_pl()
	pl = {
		x=31,
		y=0.5,
		w=16,
		h=8,
		stn=false,
		spt=nil,
		vx=0,
		vy=0,
		fl=false,
		sn=66,
		score=bignum:new(30000)*2,
		doublejump = false,
		offsets = {1,10},
		nhs = false
	}
end
-->8
-- lowrez misc functions
function tile_bg(n,ml)
	if (not bg) init_bg()
	if (not bg.tiles) bg.tiles={}
	n = n or 8
	ml = ml or #bg.tiles 
	for i=1,n do
		local r = flr(rnd(8))
		if (r >= 4) r=-1
		add(bg.tiles,r,1)
	end
	
	while #bg.tiles < ml do
		deli(bg.tiles,#bg.tiles)
	end
	
	if record_tiles then
		local l = #(bg.tiles)
		for i = 1,l/8 do
			csv_print_file("bg_tiles.csv","",{unpack(bg.tiles,l-8*i+1,l-8*i+8)},i==1)
		end
	end
end

function update_buttons()
	print_debug("min_t: "..tostr(min_t))
	if not min_t or min_t <= 0 then
		if btnp(0) or btnp(1) then
			gw.selected = 1-gw.selected
		elseif (btnp(2) or btnp(4) or btnp(5)) then	
			if gw.mode == "inst1" then
				gw.mode = "inst2"
				min_t = stat(8)
			elseif gw.mode == "inst2" then
				gw.mode = "game"
			elseif gw.selected == 0 then
				pl.score = 0
				gw.nhs = false
				if gw.shown_instructions then
					gw.mode = "game"
				else
					gw.mode = "inst1"
					min_t = stat(8)
				end
			else
				if gw.mode == "credits" then
					gw.mode = "menu"
				else
					gw.mode = "credits"
				end
			end
		end
	end
	if (min_t and min_t > 0) min_t -= 1
end

function check_platforms()
	for pt in all(gw.platforms) do
		if pt:top() < gw.cy-5 then
			del(gw.platforms, pt)
		end
	end
	local num_pt = #gw.platforms
	local highest = gw.platforms[num_pt]
	local gww=gw.rx-gw.lx+1
	if not highest then
		highest = platform_cls:new()
	end
	while highest:top() < gw.cy + gw.by - gw.ty+5 do
		local np = platform_cls:new()
		local m = rnd(1.8)-0.9
		if m >= 0 then
			m += 0.1
		else
			m -= 0.1
		end
		np:setslope(m)
		if m < 0 then
			local rx = rnd(gww-pl.w*2)+pl.w
			local lx = rnd(rx-pl.w)
			np:setleft(lx)
			np:setwidth(rx-lx)
		else
			local lx = rnd(gww-pl.w*2)+pl.w
			local rx = rnd(gww-pl.w-lx)+pl.w+lx
			np:setleft(lx)
			np:setwidth(rx-lx)
		end
		hmin = 0--min(10,np:height()-1)
		if sgn(m) != sgn(highest.m) then
			hmin = -1
		end
		np:setbottom(highest:top()+rnd(10+hmin)-hmin)
		np:gen_h()
		highest=np
		add(gw.platforms,np)
	end
end

function check_powerups()
	for pu in all(gw.powerups) do
		if pu.y < gw.cy then
			del(gw.powerups, pu)
		end
	end
	local cty = gw.cy+gw.by-gw.ty+1
	if gw.npu < cty+10 then
		local rvd = 128
		local cy = bignum:new(gw.offset)+gw.cy
		while (cy > 0) do
			cy -= 2000
			if (rvd*2 < 10000) then
				rvd *= 1.1
			else
				cy = 0
			end
		end
		if pl.pu then
			gw.npu += flr(rnd(rvd))+rvd
			return
		end
		local t = flr(rnd(3))
		local npu = {
			y=gw.npu,
			timer=0,
			period=stat(8)/4,
			dur=15*stat(8),
			type=t,
			sn1=16*t+3,
			sn2=16*t+4,
			w1=5,
			w2=5,
			h1=6,
			h2=7,
			col=10
		}
		
		if t == 1 then
			npu.col=137
		elseif t == 2 then
			npu.w1=5
			npu.w2=6
			npu.h1=5
			npu.h2=6
			npu.col=3
		end
		npu.x=flr(rnd(gw.rx-gw.lx-max(npu.w1,npu.w2)-2)+1)
		add(gw.powerups,npu)
		gw.npu += flr(rnd(128))+128
	end
end

do
	local melody_options={7,11,15,19,23,27,31,39}
	local choice_nodes={
		{
			{pat=7,nxt=1,taken=0},
			{pat=11,nxt=1,taken=0},
			{pat=15,nxt=2,taken=0},
			{pat=27,nxt=1,taken=0},
			{pat=31,nxt=2,taken=0},
			last=0
		},
		{
			{pat=20,nxt=1,taken=0},
			{pat=32,nxt=3,taken=0},
			{pat=36,nxt=3,taken=0},
			last=0
		},
		{
			{pat=35,nxt=4,taken=0},
			{pat=39,nxt=1,taken=0},
			last=0
		},
		{
			{pat=20,nxt=1,taken=0},
			{pat=36,nxt=3,taken=0},
			last=0
		}
	}
	local ncn=choice_nodes[1]
	function check_music()
		if stat(24) < 0 then
			local ind = flr(rnd(#ncn))+1
			if ind == ncn.last then
				ind = flr(rnd(#ncn))+1
			end
			music(ncn[ind].pat)
			ncn[ind].taken += 1
			ncn.last=ind
			ncn=choice_nodes[ncn[ind].nxt]
		end
		for n in all(ncn) do
			if(type(n) == "table") print_debug("{"..n.pat..","..n.nxt..","..n.taken.."}")
		end
	end
end

function get_stored_score()
	local res = bignum:new()
	if dget(0) > 100 then
		res.sign = -1
		res.huns[1] = 200-dget(0)
	else
		res.huns[1] = 100-dget(0)
	end
	for i=1,63 do
		if (dget(i) == 0) break
		res.huns[i+1] = 100-dget(i)
	end
	return res
end

function store_score(s)
	if s.sign < 0 then
		dset(0,200-s.huns[1])
	else
		dset(0,100-s.huns[1])
	end
	for i=1,63 do
		if s.huns[i+1] then
			dset(i,100-s.huns[i+1])
		else
			dset(i,0)
		end
	end
end

function str_disp_width(s)
	local r=0
	for i=1,#s do
		if ord(s,i) < 32 or ord(s,i) == 127 then
			r += 0
		elseif ord(s,i) < 65 then
			r += 4
		elseif ord(s,i) < 91 then
			r += 8
		elseif ord(s,i) < 128 then
			r += 4
		else
			r += 8
		end
	end
	return r
end
-->8
--lowrez debug functions
function csv_print_file(file, name, item, header, sep)
 printh(csv_print(name, item, header, sep), file, header)
end

function csv_print (name, item, header, sep)
	sep = sep or ","
	str = ""
	header = header and name != ""
	if header then
		if type(item) == "table" then
			for k, v in pairs(item) do
				str ..= csv_print(name.."."..k, v, header, sep)
			end
		else
			str = name..sep
		end
	else
		if type(item) == "table" then
			for k, v in pairs(item) do
				str ..= csv_print(name.."."..k, v, header, sep)
			end
		else
			str = tostring(item)..sep
		end
	end
	return str
end

do
	local debug_queue = {}
	local can_queue = true
	
	function clear_debug()
		debug_queue={}
	end
	
	function print_debug(s)
		if (debug_info and can_queue) then
			local start=1
			for i=1,#s do
				if sub(s,i,i) == "\n" then
					add(debug_queue,sub(s,start,i-1))
					start=i+1
				end
			end
			add(debug_queue,sub(s,start))
		end
	end
	
	function lock_debug()
		can_queue = false
	end
	
	function unlock_debug()
		can_queue = true
	end
	
	function show_debug()
		local ln=0
		cursor(0,65)
		local i=1
		while #debug_queue > 0 and i <= #debug_queue do
			local s = debug_queue[i]
			if (not fstep) then
				deli(debug_queue,1)
			else
				i += 1
			end
			if #s > 16 then
				add(debug_queue, sub(s,16),i)
				s=sub(s,1,15).."\\"
			end
			color(0)
			print(s)
			ln += 1
			if ln == 9 then
				cursor(64,1)
			elseif ln == 28 then
				if not fstep then
					debug_queue={}
				else
					i=#debug_queue+1
				end
			end
		end
	end
end

do
	local last_time=0
	function dump_str(t,pa)
		pa=pa or ""
		local str = ""
		local this_time = 1-last_time
		if (not t.dump_visited) or t.dump_visited != this_time then
			for k,v in pairs(t) do
				str ..= pa..k..": "
				local s = tostr(v)
				if s == "[table]" or sub(s,1,5) == "table" then
					str ..="\n"..dump_str(v,"	"..pa)
				else
					str ..= s.."\n"
				end
			end
			t.dump_visited = this_time
		end
		last_time = this_time
		return str
	end
end
-->8
-- platform class
platform_cls = {
	x=0,
	y=0,
	m=0,
	l=0,
	h_light={},
	h_dark={}
}

function platform_cls:new(o)
	o = o or {}
	self.__index = self
	setmetatable(o, self)
	return o
end

function platform_cls:hyp()
	return sqrt(1+self.m^2)
end

function platform_cls:left()
	return self.x
end

function platform_cls:width()
	return self.l/self:hyp()
end

function platform_cls:height()
	return self:width()*abs(self.m)
end

function platform_cls:right()
	return self.x + self:width()
end

function platform_cls:bottom()
	if self.m >= 0 then
		return self.y
	else
		return self.y-self:height()
	end
end

function platform_cls:top()
	if self.m <= 0 then
		return self.y
	else
		return self.y + self:height()
	end
end

function platform_cls:setslope(nm)
	self.m = nm
end

function platform_cls:setleft(nl)
	self.x = nl
end

function platform_cls:setright(nr)
	self.x = nr - self:width()
end

function platform_cls:setwidth(nw,keep_side)
	keep_side=keep_side or "left"
	local o_r = self:right()
	self.l = nw*self:hyp()
	if (keep_side == "right") self:setright(o_r)		
end

function platform_cls:setbottom(nb)
	if self.m >= 0 then
		self.y = nb
	else
		self.y = nb+self:height()
	end
end

function platform_cls:settop(nt)
	if self.m <= 0 then
		self.y = nt
	else
		self.y = nb-self:height()
	end
end

function platform_cls:gen_h()
	self.h_light={}
	self.h_dark={}
	local icicle_pos=1
	local tmp=0
	for i = 0,ceil(self:width()) do
		if i == icicle_pos-1 then
			tmp = flr(rnd(2))+1
			add(self.h_light,tmp)
			tmp = flr(rnd(3))+1
			add(self.h_dark,tmp)
		elseif i == icicle_pos then
			tmp = flr(rnd(3))+3
			add(self.h_dark,tmp)
			tmp = flr(rnd(tmp-1)+1)
			add(self.h_light,tmp)
		elseif i == icicle_pos + 1 then
			tmp = flr(rnd(2))+1
			add(self.h_light,tmp)
			tmp = flr(rnd(3))+1
			add(self.h_dark,tmp)
			icicle_pos += flr(rnd(5))+3
		else
			add(self.h_light,1)
			add(self.h_dark,0)
		end
	end
end
-->8
-- bignum class
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

function bignum:tonum()
	local rmax = bignum:new(16384)*bignum:new(2)-1
	local rmin = bignum:new(-16384)*bignum:new(2)
	if (self > rmax) return rmax
	if (self < rmin) return rmxn
	local tmp = 0
	for i in 1,#self.huns do
		tmp += self.sign*self.huns[i]*(100^(i-1))
	end
end

function make_bn_pair(v1,v2)
	if (type(v1) != "table") v1=bignum:new(v1)
	if (type(v2) != "table") v2=bignum:new(v2)
	return v1,v2
end
__gfx__
00055000000344444303ee3000a0000000a0000066666666666666666666666676666666ccccccccccccc7777777777777777ccc000000000000001c0000001c
0055550003444444444033e00a7a00000a7a000066676666667666666666666666667666cccccccccccc771111111111111117cc000000000000001c0000001c
00555500344444444444ee30a777a000a777a00066666666666666666667666666676666ccccccccccc77100000000000000017c000000000000001c0000001c
000550004b44bb4444b44300aa7aa000aa7aa00066666666666666666667767666676666ccccccccccc71000000000000000001c000000000000001c0000001c
00000000034bbbbb4b34b3000a7a00000a7a000066666666766666666667766666776666ccccccccccc71000000000000000001c000000000000001c0000001c
00555500344b33334b3030000aaa00000a7a000066666666766666666666776666776666ccccccccccc71000000000000000001c000000000000001c000001cc
0555555034b3000034b30000000000000aaa000066666666766666666666677667766766ccccccccccc71000000000000000001c111111110000001c11111ccc
055555500e30000003e00000000000000000000066666666666666766676677777766666cccccccccccc1000000000000000001ccccccccc0000001ccccccccc
aaaaaaaa000344444303ee3000f0000000f0000066666667666666766666667777766666ccccccccccc71000a0000a0000000000000000001111111111000000
aaaa9aaa03444444444033e00f7f00000f7f000066766666666667766666666777666666cccc77777ccc1000aaaaaa0000000000000000001cccccccc1000000
aaaaaaaa044444444444ee300f7f00000f7f000066766666666667666666666677666666ccc7117777cc1000aaaaaa0000000000000000001111111111000000
aa9aaa9a34444bb444b44300f777f000f777f00066666666666667666766666677666666cc710007177c1000aaaaaa0000000000000000000000000000000000
9aaa9aaa4bb4bbbb4b34b300ff7ff000f777f00066676666666666666766666667766676cc100007017c1000aaaaaa0000000000000000000000000000000000
a9a9a9a93344b3334b0330000fff0000ff7ff00066666666666766666666666666776666cc100000017c1000aaaaaa0000000000000000000000000000000000
9a9a9a9a034b300034300000000000000fff000066666666666766666666666666677766cc100000017c10009999990000000000000000000000000000000000
a999a99900e300003e000000000000000000000066666666666666666666666666666676cc100000017c10009999990000000000000000000000000000000000
99a999a90003333330000000033300000033000066666666666666666666666666666666cc10000001cc10009999990000000000d0000000000000000000000d
999999990031111113000000337330000377300066666666666667666766666667666666cc100000017c100099999900000000000000d0000000000d000d0000
999f9999031cccccc1300000373730003733730066667666666666666766666667666666cc10000001cc10009999990000000000d0d000000000000000000d0d
9999999931cccccccc130000337330003733730066667666666666666666666667666666cc10000001cc10009999990000000000dd0000d00d000d000d0000dd
9f999f9931cccccccc130000033300000377300066666676666766666666666677666766cc10000001cc1000f9999f0000000000d0d0d000000d000d000d0d0d
999f999f31cccccccc130000000000000033000066666676666666666666667677766766cc10000001cc1000ffffff0000000000dd0d0d0dd0d0d0d0d0d0d0dd
f9f9f9f931cccccccc130000000000000000000066766666666666666666666677766776cc10000001cc1000ffffff0000000000ddddd0dd0ddd0ddd0ddd0ddd
9f9f9f9f31cccccccc130000000000000000000066666666666666666666666677766776cc10000001cc1000ffffff00000000000dddddddddddddddddddddd0
f9fff9ff31cccccccc130000000000000000000066666666666666666666666667766776cc10000001cc1000ffffff0000000000007777777777770000000000
fff9fff9031cccccc1300000000055000055000066666666666666666676666667776776cc10000001cc1000ffffff0000000000077117711111117000000000
ffffffff0031111113000000000555000055500066666666666676666666666666776766cc10000001cc1000ffffff000000000077ccc7ccccccc71700000000
ffffffff0003333330000000005555000055550066766666666776666666666676776666cc10000001cc1000f9999f000000000071ccccccccccccc100000000
ffffffff0000000000000000005555000055550066766666666776666667666676776666cc10000001cc1000999999000000000071ccccccccccc7c100000000
ffffffff0000000000000000000555000055500066676666666766666667666676676666cc10000001cc1000999999000000000071ccccccccccccc100000000
ffffffff0000000000000000000055000055000066676666666666666666666666676666cc10000001cc1000999999000000000071ccccccccccccc100000000
ffffffff0000000000000000000000000000000066666666666666666666666666666666cc10000001cc1000999999000000000071ccccccccccccc100000000
00aaaaaa00000000aaaa0aaaa00000000000000000000000001111111111110000000000cc10000001cc1000999999000000000001ccccccccccccc100000000
0aaffffaaaaaaaaaaffaaaffaaa00aaaa00000000000000001cccccccccccc1000000000cc10000001cc1000999999000000000071ccccccccccccc100000000
aaf7777ffaafffaaf77faf77ffaaaaffaa000000000000001cccccccccccccc100000000cc10000001cc1000aaaaaa000000000001ccccccccccccc100000000
af7111177ff777fff51faf5177faaf77fa000000000000001cccccccccccccc100000000cc10000001cc1000aaaaaa000000000001ccccccccccccc100000000
af75555117f11177f51faf51117faf51fa000000000000001cccccccccccccc100000000cc10000001cc1000aaaaaa000000000001ccccccccccccc100000000
aaf5555551755511751ff7515517f751fa0000000000000001cccccccccccc1000000000ccc100001cccc100aaaaaa0000000000001ccccccccccc1000000000
af751f5551755555151ff15155517551faa0000000000000001111111111110000000000cccc1111cccccc11aaaaaa0000000000000111111111110000000000
aaf51fff55151f751551f551555555517fa0000000000000000000000000000000000000cccccccccccccccca0000a0000000000000000000000000000000000
0af551faf51517551551f55151f55f551faaaaaa0000000000777777777770000000000000000000000000000000000000000000000000000000000000000000
0af551fff5155155f551755151ffff551faafffaa000000007111111111117000000000000000000000000000000000000000000000000000000000000000000
0aaf51f77515555faf55155151faaaf51fff777faa00000071ccccccccccc1700000000000000000000000000000000000000000000000000000000000000000
00af517115151551ff55551f51fafff51f771117fa0000001ccccccccccccc170000000000000000000000000000000000000000000000000000000000000000
00af551555551f51fff555ff51ff777517115517fa0000001ccccccccccccc170000000000000000000000000000000000000000000000000000000000000000
00af555557751f5177ff777751f711171155551faa0000001ccccccccccccc170000000000000000000000000000000000000000000000000000000000000000
00af555f711177f551f711117f75555155551ff7fa00000001ccccccccccc1000000000000000000000000000000000000000000000000000000000000000000
00aafff7555551ff51f555551f551f5155f51fafaa00000000111111111110070000000000000000000000000000000000000000000000000000000000000000
000aaaf751ff51ff51f51f751f551f51fff51faaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000aaf517551ff51f5175577517751faf51fa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000af75515551751f551571f551151ff551fa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000aaf5555f55151f5517151555551ff551fa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000aaf51ff751517755155151ff51ff51faa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000af517755155115555ff51ff51ff51fa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000af551155f5555ffffaf51faffaf51fa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000af55555faffffaaaaaaffaaaaaf5faa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000a0afffffaaaaaaa000aaaa000aafaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000aaaaaaa00000000000000000aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05500550055555500000000000555500005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555500050055000005500005500550050550500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055000000550000055550005055050055005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00055000005500000555555005055050055005500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555500055000500555555005500550050550500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05500550055555500000000000555500005555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05000050000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777777777777777777777777777777777777777777700000000000000000000000000000000000000000000000000000000000000000000000000000000000
07711771111111111111717711111111111111111111170000000000000000000000000000000000000000000000000000000000007700000000000000000000
77ccc7ccccccccccccccccc7cccccccccccccccccccc71700000000000000000000000000000000000000000000000000000000007dd70000000000000000000
71cccccccccccccccccccccccccccccccccccccccccccc100000000000000000000000000000000000000000000000766000000077dddd000000000000000000
71ccccccccccccccccccccc7cccccccccccccccccccc7c1000000000000000000000000000000000000000000000077766000007777dddd00000000000000000
71cccccccccccccccccccccccccccccccccccccccccccc10000000000000000000000000000000000000000000007777dd6007777777dddd0000000000000000
71cccccccccccccccccccccccccccccccccccccccccccc10000000000000000000000000000000000000000000077777ddd67777777777dd7000000000000000
71cccccccccccccccccccccccccccccccccccccccccccc1000000000000000000000000000000000000000000077777777dd6777777677dddd00000000000000
01cccccccccccccccccccccccccccccccccccccccccccc1000000000000000000000000000000000000000000777777777ddd6777777677dddd0000000000000
01cccccccccccccccccccccccccccccccccccccccccccc100000000000000000000000000000000000000000777777777777d6777777d777dddd000000000000
01cccccccccccccccccccccccccccccccccccccccccccc1000000000000000000000000000000000000000077777777777777d6777777d777dddd00000000000
01cccccccccccccccccccccccccccccccccccccccccccc10000000000000000000000000000000000000077777767777777777d777777dd777dddd0000000000
01cccccccccccccccccccccccccccccccccccccccccccc1000000000000000000000000000000000000777777767777777777776777777dd777ddd7000000000
01cccccccccccccccccccccccccccccccccccccccccccc1000000000000000000000000000077700777777777d677777777777777777777ddd77ddd770000000
01cccccccccccccccccccccccccccccccccccccccccccc1000000000000000000000000000777777777777777777777777777777d7777776ddd77ddd77000000
01cccccccccccccccccccccccccccccccccccccccccccc10000000000000000000000000076ddd7777777777d6777777677777777d7777766ddd77ddd7700000
01cccccccccccccccccccccccccccccccccccccccccccc1000000000000000000000000076666dd7d77777dd666777777d7777777dd777776dddd77ddddd0000
01cccccccccccccccccccccccccccccccccccccccccccc10000000000000000000000007d66666dd7d777dd6666677777dd7777777dd776766ddddd7dddd7000
01cccccccccccccccccccccccccccccccccccccccccccc1000000000000000000000007d6666666ddd77ddd66666677777d77777777dd777766ddddd7dddd000
01cccccccccccccccccccccccccccccccccccccccccccc100000000000000000000007dd666666666dddddd6666666777766677767777d77766dddddd7ddd700
01cccccccccccccccccccccccccccccccccccccccccccc10000000000000000000077dd666d6666666dddd6666666667777d6677667777777766dddddddddd00
71cccccccccccccccccccccccccccccccccccccccccccc1000000000000000000077ddd76dd66676666ddd6666666666777666677667777777666ddddd7ddd00
01cccccccccccccccccccccccccccccccccccccccccccc1000000000000000000077ddd76dd666667666ddd66666666667776666766677777776667ddddddd00
01cccccccccccccccccccccccccccccccccccccccccccc100000000000000000007ddd77dd66666666666dd666666666667766666766777d7776666ddddddd00
01cccccccccccccccccccccccccccccccccccccccccccc10000000000000000000ddd7dddd666666666766d766666666666776666666677d66776666dddddd00
001cccccccccccccccccccccccccccccccccccccccccc100000000000000000000dddddddd6666666666766d7666666666677666666666776667666667dddd00
000111111111111111111111111111111111111111111000000000000000000000dddddd6666666766667766666666666666d76666666667d6667666667ddd00
000000000000000000000000000000000000000000000000000000000000000000dd76dd66666666d66667766666766666666d66666666667666666666667d00
000000000000000000000000000000000000000000000000000000000000000000dd666d66666666dd7667776666d76666666dd6666666666666667666666700
000000000000000000000000000000000000000000000000000000000000000000dd6666666666666d77667776666d66666666dd666666666666666666666600
000000000000000000000000000000000000000000000000000000000000000000dd66666d6666666dd7777777666dd66666666d766666666d66666666666600
0000000000000000000000000000000000000000000000000000000000000000006dd6666666666666dd7777777666dd66666666d76666666666666667666600
0000000000000000000000000000000000000000000000000000000000000000006dd66666766666666dd7777677667ddd6666666666666666dd666667776600
00000000000000000000000000000000000000000000000000000000000000000066dd66666666666666dd7766676667ddd666666666d666666dd66666777600
000000000000000000000000000000000000000000000000000000000000000000766d666666666666666ddd766676677ddd666666666666667ddd6666677700
00000000000000000000000000000000000000000000000000000000000000000076666666666666666666ddd66666667dddd76666666dd66667ddd666667700
00000000000000000000000000000000000000000000000000000000000000000067666666666666666666dddd77666677dddd66666666dd66677ddd66667700
000000000000000000000000000000000000000000000000000000000000000000666666666666666666666dddd77666777ddd766666666dd6667dddd6666700
0000000000000000000000000000000000000000000000000000000000000000006666676666666667666666ddddd7666777ddd76666666ddd6677dddd666700
000000000000000000000000000000000000000000000000000000000000000000666666d6666666667666666ddddd6667777ddd77666666dd66777dddd66600
00000000000000000000000000000000000000000000000000000000000000000066666666666666666dd6666dddddd666777ddd77766666ddd66777ddddd600
0000000000000000000000000000000000000000000000000000000000000000006666666d6666666666dd6666dddddd666777ddd77766666ddd67777ddddd00
0000000000000000000000000000000000000000000000000000000000000000006666667dd6666666666dd6666dddddd667777ddd77776666ddd67777dddd00
00000000000000000000000000000000000000000000000000000000000000000066666677d66666666666dd6666dddddd667777dd77777666ddd77777dddd00
00000000000000000000000000000000000000000000000000000000000000000076666777dd66666666666ddd666dddddd667777d777777776d7777777ddd00
00000000000000000000000000000000000000000000000000000000000000000077667777dd666666666666dddd6ddddddd667777d77777777777677777dd00
00000000000000000000000000000000000000000000000000000000000000000077dd77777dd76666666666ddddddddddddd6777776777777777d6677777d00
000000000000000000000000000000000000000000000000000000000000000000777d77777dd776666666676ddddddddddddd77777777777777777d77777700
0000000000000000000000000000000000000000000000000000000000000000007777d7777ddd7766666666766dddddddddddd77777777777777777d7777700
00000000000000000000000000000000000000000000000000000000000000000077777777777dd7766666666667dddddddddddd777777777777777777777700
0000000000000000000000000000000000000000000000000000000000000000007777d77777777d7666666666667dddddddddddd77777777777777777777700
00000000000000000000000000000000000000000000000000000000000000000077777d77777777776666666666677ddddddddddd7777776777777777777700
00000000000000000000000000000000000000000000000000000000000000000077777dd7777777d77766666666677777ddddddddd777777677777777777700
00000000000000000000000000000000000000000000000000000000000000000077777ddd7777777777766666667777777ddddddddd77777d67777777777700
000000000000000000000000000000000000000000000000000000000000000000077777ddd7777777777766677777777777ddddddddd77777d6777777777000
__label__
cccccc77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777cccccc
cccccc77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777cccccc
cccc77ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss77cccc
cccc77ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss77cccc
cc77ssaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaass77cc
cc77ssaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaass77cc
ccssaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaasscc
ccssaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaasscc
ccssaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaasscc
ccssaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaasscc
ccssaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaasscc
ccssaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaasscc
ccssaaaa99aaaaaaaaaaaaaa99aaaaaaaaaaaaaa99aaaaaaaaaaaaaa99aaaaaaaaaaaaaa99aaaaaaaaaaaaaa99aaaaaaaaaaaaaa99aaaaaaaaaaaaaa99aasscc
ccssaaaa99aaaaaaaaaaaaaa99aaaaaaaaaaaaaa99aaaaaaaaaaaaaa99aaaaaaaaaaaaaa99aaaaaaaaaaaaaa99aaaaaaaaaaaaaa99aaaaaaaaaaaaaa99aasscc
ccssaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaasscc
ccssaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaasscc
ccss99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaasscc
ccss99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaasscc
ccssaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aa777799aaaaaa99aaaaaa99aaaaaa99aaaaaa99aasscc
ccssaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aaaaaa99aa777799aaaaaa99aaaaaa99aaaaaa99aaaaaa99aasscc
ccssaa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa77dddd7799aa99aa99aa99aa99aa99aa99aa99aa99sscc
ccssaa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa77dddd7799aa99aa99aa99aa99aa99aa99aa99aa99sscc
ccss99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa776666aa99aa99aa99aa7777dddddddd99aa99aa99aa99aa99aa99aa99aa99aasscc
ccss99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa99aa776666aa99aa99aa99aa7777dddddddd99aa99aa99aa99aa99aa99aa99aa99aasscc
ccss9999aa999999aa999999aa999999aa999999aa999999aa999999aa77777766669999aa999977777777dddddddd99aa999999aa999999aa999999aa99sscc
ccss9999aa999999aa999999aa999999aa999999aa999999aa999999aa77777766669999aa999977777777dddddddd99aa999999aa999999aa999999aa99sscc
ccssaa999999aa999999aa999999aa999999aa999999aa999999aa9977777777dddd66999977777777777777dddddddd9999aa999999aa999999aa999999sscc
ccssaa999999aa999999aa999999aa999999aa999999aa999999aa9977777777dddd66999977777777777777dddddddd9999aa999999aa999999aa999999sscc
ccss999999999999999999999999999999999999999999999999997777777777dddddd6677777777777777777777dddd7799999999999999999999999999sscc
ccss999999999999999999999999999999999999999999999999997777777777dddddd6677777777777777777777dddd7799999999999999999999999999sscc
ccss99pp99999999999999pp99999999999999pp9999999999997777777777777777dddd66777777777777667777dddddddd99pp99999999999999pp9999sscc
ccss99pp99999999999999pp99999999999999pp9999999999997777777777777777dddd66777777777777667777dddddddd99pp99999999999999pp9999sscc
ccss9999999999999999999999999999999999999999999999777777777777777777dddddd66777777777777667777dddddddd9999999999999999999999sscc
ccss9999999999999999999999999999999999999999999999777777777777777777dddddd66777777777777667777dddddddd9999999999999999999999sscc
ccss999999pp999999pp999999pp999999pp999999pp9999777777777777777777777777dd66777777777777dd777777dddddddd99pp999999pp999999ppsscc
ccss999999pp999999pp999999pp999999pp999999pp9999777777777777777777777777dd66777777777777dd777777dddddddd99pp999999pp999999ppsscc
ccss99pp999999pp999999pp999999pp999999pp9999997777777777777777777777777777dd66777777777777dd777777dddddddd9999pp999999pp9999sscc
ccss99pp999999pp999999pp999999pp999999pp9999997777777777777777777777777777dd66777777777777dd777777dddddddd9999pp999999pp9999sscc
ccsspp99pp99pp99pp99pp99pp99pp99pp99pp99pp7777777777776677777777777777777777dd777777777777dddd777777ddddddddpp99pp99pp99pp99sscc
ccsspp99pp99pp99pp99pp99pp99pp99pp99pp99pp7777777777776677777777777777777777dd777777777777dddd777777ddddddddpp99pp99pp99pp99sscc
ccss99pp99pp99pp99pp99pp99pp99pp99pp99777777777777776677777777777777777777777766777777777777dddd777777dddddd77pp99pp99pp99ppsscc
ccss99pp99pp99pp99pp99pp99pp99pp99pp99777777777777776677777777777777777777777766777777777777dddd777777dddddd77pp99pp99pp99ppsscc
ccsspppppp99pppppp99pp7777aaaaaaaaaaaa777777777777dd66aaaaaaaa77aaaaaaaa7777777777777777777777dddddd7777dddddd777799pppppp99sscc
ccsspppppp99pppppp99pp7777aaaaaaaaaaaa777777777777dd66aaaaaaaa77aaaaaaaa7777777777777777777777dddddd7777dddddd777799pppppp99sscc
ccsspp99pppppp99pppp7777aaaappppppppaaaaaaaaaaaaaaaaaaaappppaaaaaappppaaaaaa7777aaaaaaaa77777766dddddd7777dddddd7777pp99ppppsscc
ccsspp99pppppp99pppp7777aaaappppppppaaaaaaaaaaaaaaaaaaaappppaaaaaappppaaaaaa7777aaaaaaaa77777766dddddd7777dddddd7777pp99ppppsscc
ccsspppppppppppppp7766aaaapp77777777ppppaaaappppppaaaapp7777ppaapp7777ppppaaaaaaaappppaaaa77776666dddddd7777dddddd7777ppppppsscc
ccsspppppppppppppp7766aaaapp77777777ppppaaaappppppaaaapp7777ppaapp7777ppppaaaaaaaappppaaaa77776666dddddd7777dddddd7777ppppppsscc
ccsspppppppppppp776666aapp77ssssssss7777pppp777777pppppp11ssppaapp11ss7777ppaaaapp7777ppaa77777766dddddddd7777ddddddddddppppsscc
ccsspppppppppppp776666aapp77ssssssss7777pppp777777pppppp11ssppaapp11ss7777ppaaaapp7777ppaa77777766dddddddd7777ddddddddddppppsscc
ccsspppppppppp77dd6666aapp7711111111ssss77ppssssss7777pp11ssppaapp11ssssss77ppaapp11ssppaa7766776666dddddddddd77dddddddd77ppsscc
ccsspppppppppp77dd6666aapp7711111111ssss77ppssssss7777pp11ssppaapp11ssssss77ppaapp11ssppaa7766776666dddddddddd77dddddddd77ppsscc
ccsspppppppp77dd666666aaaapp111111111111ss77111111ssss7711sspppp7711ss1111ss77pp7711ssppaa777777776666dddddddddd77ddddddddppsscc
ccsspppppppp77dd666666aaaapp111111111111ss77111111ssss7711sspppp7711ss1111ss77pp7711ssppaa777777776666dddddddddd77ddddddddppsscc
ccsspppppp77dddd666666aapp7711sspp111111ss771111111111ss11ssppppss11ss111111ss771111ssppaaaa7777776666dddddddddddd77dddddd77sscc
ccsspppppp77dddd666666aapp7711sspp111111ss771111111111ss11ssppppss11ss111111ss771111ssppaaaa7777776666dddddddddddd77dddddd77sscc
ccsspp7777dddd666666ddaaaapp11sspppppp1111ss11sspp7711ss1111sspp1111ss11111111111111ss77ppaa777777776666ddddddddddddddddddddsscc
ccsspp7777dddd666666ddaaaapp11sspppppp1111ss11sspp7711ss1111sspp1111ss11111111111111ss77ppaa777777776666ddddddddddddddddddddsscc
ccss7777dddddd7766dddd66aapp1111ssppaapp11ss11ss771111ss1111sspp1111ss11sspp1111pp1111ssppaaaaaaaaaaaa6666dddddddddd77ddddddsscc
ccss7777dddddd7766dddd66aapp1111ssppaapp11ss11ss771111ss1111sspp1111ss11sspp1111pp1111ssppaaaaaaaaaaaa6666dddddddddd77ddddddsscc
ccss7777dddddd7766dddd66aapp1111sspppppp11ss1111ss1111pp1111ss771111ss11sspppppppp1111ssppaaaappppppaaaa666677ddddddddddddddsscc
ccss7777dddddd7766dddd66aapp1111sspppppp11ss1111ss1111pp1111ss771111ss11sspppppppp1111ssppaaaappppppaaaa666677ddddddddddddddsscc
ccss77dddddd7777dddd6666aaaapp11sspp777711ss11111111ppaapp1111ss1111ss11ssppaaaaaapp11sspppppp777777ppaaaa6666ddddddddddddddsscc
ccss77dddddd7777dddd6666aaaapp11sspp777711ss11111111ppaapp1111ss1111ss11ssppaaaaaapp11sspppppp777777ppaaaa6666ddddddddddddddsscc
ccssdddddd77dddddddd666666aapp11ss77ssss11ss11ss1111sspppp11111111sspp11ssppaapppppp11sspp7777ssssss77ppaa666666ddddddddddddsscc
ccssdddddd77dddddddd666666aapp11ss77ssss11ss11ss1111sspppp11111111sspp11ssppaapppppp11sspp7777ssssss77ppaa666666ddddddddddddsscc
ccssdddddddddddddddd666666aapp1111ss1111111111sspp11sspppppp111111pppp11sspppp77777711ss77ssss1111ss77ppaa6666666677ddddddddsscc
ccssdddddddddddddddd666666aapp1111ss1111111111sspp11sspppppp111111pppp11sspppp77777711ss77ssss1111ss77ppaa6666666677ddddddddsscc
ccssdddddddddddd6666666666aapp1111111111777711sspp11ss7777pppp7777777711sspp77ssssss77ssss11111111ssppaaaa666666666677ddddddsscc
ccssdddddddddddd6666666666aapp1111111111777711sspp11ss7777pppp7777777711sspp77ssssss77ssss11111111ssppaaaa666666666677ddddddsscc
ccssdddd7766dddd6666666666aapp111111pp77ssssss7777pp1111sspp77ssssssss77pp7711111111ss11111111sspppp77ppaa6666666666666677ddsscc
ccssdddd7766dddd6666666666aapp111111pp77ssssss7777pp1111sspp77ssssssss77pp7711111111ss11111111sspppp77ppaa6666666666666677ddsscc
ccssdddd666666dd6666666666aaaapppppp771111111111sspppp11sspp1111111111sspp1111sspp11ss1111pp11ssppaappaaaa667766666666666677sscc
ccssdddd666666dd6666666666aaaapppppp771111111111sspppp11sspp1111111111sspp1111sspp11ss1111pp11ssppaappaaaa667766666666666677sscc
ccssdddd66666666666666666666aaaaaapp7711sspppp11sspppp11sspp11sspp7711sspp1111sspp11sspppppp11ssppaaaaaa66666666666666666666sscc
ccssdddd66666666666666666666aaaaaapp7711sspppp11sspppp11sspp11sspp7711sspp1111sspp11sspppppp11ssppaaaaaa66666666666666666666sscc
ccssdddd6666666666dd666666666666aaaapp11ss771111sspppp11sspp11ss771111777711ss777711ssppaapp11ssppaa666666666666666666666666sscc
ccssdddd6666666666dd666666666666aaaapp11ss771111sspppp11sspp11ss771111777711ss777711ssppaapp11ssppaa666666666666666666666666sscc
ccss66dddd6666666666666666666666aapp771111ss111111ss7711sspp1111ss1177sspp1111ssss11sspppp1111ssppaa666666666666667766666666sscc
ccss66dddd6666666666666666666666aapp771111ss111111ss7711sspp1111ss1177sspp1111ssss11sspppp1111ssppaa666666666666667766666666sscc
ccss66dddd6666666666776666666666aaaapp11111111pp1111ss11sspp1111ss77ss11ss1111111111sspppp1111ssppaadddd66666666667777776666sscc
ccss66dddd6666666666776666666666aaaapp11111111pp1111ss11sspp1111ss77ss11ss1111111111sspppp1111ssppaadddd66666666667777776666sscc
ccss6666dddd6666666666666666666666aaaapp11sspppp7711ss11ss77771111ss1111ss11sspppp11sspppp11ssppaaaa66dddd666666666677777766sscc
ccss6666dddd6666666666666666666666aaaapp11sspppp7711ss11ss77771111ss1111ss11sspppp11sspppp11ssppaaaa66dddd666666666677777766sscc
ccss776666dd666666666666666666666666aapp11ss77771111ss1111ssss11111111pppp11sspppp11sspppp11ssppaa6677dddddd6666666666777777sscc
ccss776666dd666666666666666666666666aapp11ss77771111ss1111ssss11111111pppp11sspppp11sspppp11ssppaa6677dddddd6666666666777777sscc
ccss77666666666666666666666666666666aapp1111ssss1111pp11111111ppppppppaapp11ssppaappppaapp11ssppaa666677dddddd66666666667777sscc
ccss77666666666666666666666666666666aapp1111ssss1111pp11111111ppppppppaapp11ssppaappppaapp11ssppaa666677dddddd66666666667777sscc
ccss66776666666666666666666666666666aapp1111111111ppaappppppppaaaaaaaaaaaappppaaaaaaaaaapp11ppaaaa66667777dddddd666666667777sscc
ccss66776666666666666666666666666666aapp1111111111ppaappppppppaaaaaaaaaaaappppaaaaaaaaaapp11ppaaaa66667777dddddd666666667777sscc
ccss66666666666666666666666666666666aaaappppppppppaaaaaaaaaaaaaa777777ddaaaaaaaa666666aaaappaaaadd66666677dddddddd6666666677sscc
ccss66666666666666666666666666666666aaaappppppppppaaaaaaaaaaaaaa777777ddaaaaaaaa666666aaaappaaaadd66666677dddddddd6666666677sscc
ccss6666666666776666666666666666667766aaaaaaaaaaaaaadddddd77666666777777dddddd7766666666aaaaaadddddd66667777dddddddd66666677sscc
ccss6666666666776666666666666666667766aaaaaaaaaaaaaadddddd77666666777777dddddd7766666666aaaaaadddddd66667777dddddddd66666677sscc
ccss666666666666dd66666666666666666677666666666666dddddddddd66666677777777dddddd7777666666666666dddd6666777777dddddddd666666sscc
ccss666666666666dd66666666666666666677666666666666dddddddddd66666677777777dddddd7777666666666666dddd6666777777dddddddd666666sscc
ccss6666666666666666666666666666666666dddd66666666dddddddddddd666666777777dddddd7777776666666666dddddd6666777777dddddddddd66sscc
ccss6666666666666666666666666666666666dddd66666666dddddddddddd666666777777dddddd7777776666666666dddddd6666777777dddddddddd66sscc
ccss66666666666666dd66666666666666666666dddd6666ppppppppppppdddd666666777777dddddd7777776666666666dddddd6677777777ddddddddddsscc
ccss66666666666666dd66666666666666666666dddd6666ppppppppppppdddd666666777777dddddd7777776666666666dddddd6677777777ddddddddddsscc
ccss66666666666677dddd66666666666666666666ddddppssssssssssssppdddd666677777777ssssssssssss7766666666dddddd6677777777ddddddddsscc
ccss66666666666677dddd66666666666666666666ddddppssssssssssssppdddd666677777777ssssssssssss7766666666dddddd6677777777ddddddddsscc
ccss6666666666667777dd6666666666666666666666ppssccccccccccccssppdddd66667777sscccc1111ccccss77666666dddddd7777777777ddddddddsscc
ccss6666666666667777dd6666666666666666666666ppssccccccccccccssppdddd66667777sscccc1111ccccss77666666dddddd7777777777ddddddddsscc
ccss7766666666777777dddd666666666666666666ppsscccc1111ccccccccssppdddd6666sscccc11111111ccccss77777766dd77777777777777ddddddsscc
ccss7766666666777777dddd666666666666666666ppsscccc1111ccccccccssppdddd6666sscccc11111111ccccss77777766dd77777777777777ddddddsscc
ccss7777666677777777dddd666666666666666666ppsscccc111111ccccccssppdddddd66sscccc11111111ccccss77777777777777667777777777ddddsscc
ccss7777666677777777dddd666666666666666666ppsscccc111111ccccccssppdddddd66sscccc11111111ccccss77777777777777667777777777ddddsscc
ccss7777dddd7777777777dddd7766666666666666ppsscccc11111111ccccssppddddddddsscccccc1111ccccccss777777777777dd66667777777777ddsscc
ccss7777dddd7777777777dddd7766666666666666ppsscccc11111111ccccssppddddddddsscccccc1111ccccccss777777777777dd66667777777777ddsscc
ccss777777dd7777777777dddd7777666666666666ppsscccc11111111ccccssppddddddddssccccccccccccccccss7777777777777777dd777777777777sscc
ccss777777dd7777777777dddd7777666666666666ppsscccc11111111ccccssppddddddddssccccccccccccccccss7777777777777777dd777777777777sscc
ccss77777777dd77777777dddddd77776666666666ppsscccc111111ccccccssppddddddddsscccc11111111ccccss777777777777777777dd7777777777sscc
ccss77777777dd77777777dddddd77776666666666ppsscccc111111ccccccssppddddddddsscccc11111111ccccss777777777777777777dd7777777777sscc
ccss7777777777777777777777dddd777766666666ppsscccc1111ccccccccssppddddddddsscc111111111111ccss777777777777777777777777777777sscc
ccss7777777777777777777777dddd777766666666ppsscccc1111ccccccccssppddddddddsscc111111111111ccss777777777777777777777777777777sscc
ccss77777777dd7777777777777777dd776666666666ppssccccccccccccssppddddddddddddss111111111111ss77777777777777777777777777777777sscc
ccss77777777dd7777777777777777dd776666666666ppssccccccccccccssppddddddddddddss111111111111ss77777777777777777777777777777777sscc
ccss7777777777dd777777777777777777776666666666ppssssssssssssppddddddddddddddddssssssssssss7777776677777777777777777777777777sscc
ccss7777777777dd777777777777777777776666666666ppssssssssssssppddddddddddddddddssssssssssss7777776677777777777777777777777777sscc
ccss7777777777dddd77777777777777dd77777766666666pppppppppppp77777777dddddddddddddddddd77777777777766777777777777777777777777sscc
ccss7777777777dddd77777777777777dd77777766666666pppppppppppp77777777dddddddddddddddddd77777777777766777777777777777777777777sscc
ccccss77777777dddddd77777777777777777777776666666666666677777777777777dddddddddddddddddd7777777777dd6677777777777777777777sscccc
ccccss77777777dddddd77777777777777777777776666666666666677777777777777dddddddddddddddddd7777777777dd6677777777777777777777sscccc
ccccccsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssscccccc
ccccccsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssscccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__sfx__
000100003033030330303603036030370300103033030110303303001030320303203000030000300003000030310303100000000000000000000000000000000000000000000000000000000000000000000000
000100000064000640007700067000770007200072000730007300073000730007200072000710007100071000710007200072000720007200071000710007100071000710007100071000710007100071000710
000100003f6433f2433a6433a24334633342232e6102d6102b6102861026610236101e6101b6101761015610136100f6100d61009610056100261000610000000000000000000000000000000000000000000000
0101060718313183231833318343183531836318371000001465011150101500f150101501215015150191501e15023150281502c1502e1502e15000000000000000000000000000000000000000000000000000
000300002b5602b5602b5602a5502a5502a55029540285402854026540255402454022540205401e5301c5301a53019530175301653015520135201252011520105200f5200e5200e5200d520000000000000000
002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100001465011150101500f150101501215015150191501e15023150281502c1502e1502e150000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000202b7202b72032720327202e7202e72032720327202d7202d72030720307202e7202e7202d7202d7202b7202b72032720327202e7202e72032720327202d7202d72030720307202e7202e7202d7202d720
011000202b8432b8402b8432b8402b8432b8402b8432b8402b8432b8402b8432b8402b8432b8402b8432b8402b8432b8402b8432b8402b8432b8402b8432b8402b8432b8402b8432b8402b8432b8402b8432b840
01100020119731197023a5023a50119731197023a5023a50119731197023a5023a50119731197023a5023a50119731197023a5023a50119731197023a5023a50119731197023a5023a501197323a503fa503ea50
012000001332213322133221332213322133221332213322133221332213322133221332213322133221332211322113221132211322113221132211322113221132211322113221132211322113221132211322
012000001fb201fb201fb201fb201fb201fb201fb201fb201fb201fb201fb201fb201fb201ab231ab231fb201db201db201db201db201db201db201db201db201db201db201db201db201db2018b2318b231db20
012000001bb301bb301bb301bb301bb301bb301bb301bb301bb301bb301bb301bb301bb3018b3318b331bb3018b3018b3018b3018b3018b3018b3018b3018b301ab301ab301ab301ab301eb301eb301eb301eb30
012000000f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220c3220c3220c3220c3220c3220c3220c3220c3220e3220e3220e3220e32212322123221232212322
011000001f2501f3201f2501f3201f2501d2501f250212501f2501f2501f2501f2501f2501f2501a2501a2501f2501f3201f2501f3201f2501d2501f250212501f2501f2301f2501a2301f2501e2501e2501e250
011000001d2501d3201d2501d3201d2501d3201b2501d3201d2501d2501d2501d2501d2501d2501b2501b2501d2501d3201d2501d3201d2501b2501b2501b2501d2501e2501e2501f2501f250202502125021250
011000001b2501b3201b2501b3201b2501a2501a2501a250182501b3201b2501b3201b2501b3201b2501b3201b2501b3201b2501b3201b2501d2501d2501d2501f2501f2501b250183201b2501a2501a2501a250
0110000018250183201825018320182501625016250162501825018250183201825018320182501b250183201a2501a3201a2501a3201a2501b2501b2501b2501e2501e2501e2501e2501b2501e2501e2501e250
0110000013322133221332213322133221332213322133221332213322133221332213322133221332213322133221332213322133221332213322133221332213322133220e3220e3220e3220e3221332213022
0110000011322113221132211322113221132211322113221132211322113221132211322113221132211322113221132211322113221132211322113221132211322113220c3220c3220c3220c3221132211322
011000000f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220f3220c3220c3220c3220c3220f3220f322
011000000c3220c3220c3220c3220c3220c3220c3220c3220c3220c3220c3220c3220c3220c3220c3220c3220e3220e3220e3220e3220e3220e3220e3220e3221232212322123221232212322123221232212322
011000001f2501f3201f2501f3201f2501d2501f250212501f2501f2501f2501f2501f2501f2501a2501a2501f2501f3201f2501f3201f2501e2501f25021250222501f320222501a320212501f2501f2501f250
011000001d2501d3201d2501d3201d2501f2501f2501f2501a2501a250162501d320162501d320162501d3201a2501d3201a2501d3201a2501825018250182501a2501a2501a2501a2501a2501a2501a2501a250
011000001b2501b3201b2501b3201b2501a2501a2501a2501b2501b3201b2501b3201b2501a2501a2501a2501b2501b3201b2501b3201b2501d2501d2501d2501f2501f2501f2501f2501f2501f2501b2501b250
00100000182501832018250183201825016250162501625018250183201825218252182501b2501b2501b2501a2501a3201a2501a3201a2501b2501b2501b2501e2501e2501e2501e2501a2501e2501e2501e250
011000001f2501f2501f2501f2501f2501f2501a2501a2501f2501f2501f2501f2501f2501f2501a2501a2501f2501f3201f2501f3201f2502125021250212502225022250222502225021250202501f2501e250
011000001d2501d2501d2501d2501d2501d25018250182501d2501d2501d2501d2501d2501d25018250182501d2501d3201d2501d3201d2501f2501f2501f250212502125021250212501f2501e2501d2501c250
011000001b2501b3201b2501b3201b2501825018250182501b2501b3201b2501b3201b2501825018250182501b2501b3201b2501b3201b2501c2501d2501e2501f2501f2501f2501f2501e2501d2501c2501b250
0110000018250183201825018320182501a2501a2501a2501b250183201b250183201b2501d2501d2501d2501e2501a3201e2501a3201e2501f2501f2501f25021250212502125021250212501a3202125021250
00100000222501f320222501f320222502425024250242502625026250262502625026250222502225022250262501f320262501f3202625022250222502225026250262502625026250262501a3202625026250
01100000272501d320272501d32027250262502625026250242501d320242501d32024250222502225022250242501d320242501d320252502625027250282502925029250292502925029250183202925029250
01100000272501b320272501b32027250262502625026250242501b320242501b32024250262502625026250272501b320272501b320272502925029250292502b2502b2502b2502b2502b250262502b2502b250
011000002b250183202b250183202b2502a2502a2502a2502925018320292501832029250272502725027250262501a320262501a320262502525025250252502425024250242502425021250212502125021250
011000001f2501f3201f2501f3201f2501d2501f250212501f2501f2501f2501f2501f2501e2501e2501e2501d2501f3201d2501f3201d2501b2501d2501e2501f2501f2501f2501f2501f2501e2501e2501e250
011000001d2501d3201d2501d3201d2501c2501d2501e2501d2501d2501d2501d2501d2501825018250182501d2501d3201d2501d3201d2501c2501d2501e2501d2501d2501d2501d2501d2501c2501c2501c250
011000001b2501b3201b2501b3201b2501a2501b2501d2501b2501b2501b2501b2501b2501a2501a2501a250182501b320182501b320182501a2501a2501a2501b2501b2501b2501b2501b2501a2501a2501a250
01100000182501832018250183201825017250182501a25018250182501825018250183201825018250182501a2501a3201a2501a3201a250192501a2501c2501e2501e2501e2501e2501a2501e2501e2501e250
011000001f2501f3201f2501f3201f2502225022250222501f2501f3201f2501f3201f2501a2501a2501a2501f2501f3201f2501f3201f250222502225022250262502625026250262501a320262502625026250
01100000272501d320272501d32027250262502625026250242501d320242501d32024250222502225022250242501d320242501d320242502625026250262502425024250242501832024250222502225022250
011000001f2501b3201f2501b3201f250212501f2501d2501f2501f2501f2501f2501f2501b2501b2501b2501f2501b3201f2501b3201f2501a2501f25021250222502225022250222501b250222502225022250
01100000262501a320262501a320262502225022250222502625026250262502625026250222502225022250262501a320262501a320262502825028250282502a2502a2502a2502a250262502a2502a2502a250
011000002b2501f3202b2501f3202b2502a2502a2502a2502925029250292502925029250262502625026250292501f320292501f320292502825028250282502725027250272502725027250242502425024250
00100000272501d320272501d320272502625026250262502425024250242502425024250222502225022250242501d320242501d320242502625026250262502925029250292502925018320292502925029250
011000002b2501b3202b2501b3202b2502e2502e2502e2502d2502d2502925029250292501b32029250292502b2501b3202b2501b320292502725027250272502625026250262502625018320262502625026250
0110000024250183202425018320242502725027250272502625026250242502425024250272502725027250262501a320262501a320262502725028250292502a2502a2502a2502a250262502a2502a2502a250
011000002b2501f3202b2501f3202b2502a2502b2502d2502b2502b2501f3202b2502a250292502825027250262501f320262501f320262502525026250282502625026250262502625026250282502825028250
00100000292501d320292501d3202925028250292502b2502925029250242501d320242502b2502b2502b2502d2501d3202d2501d3202d2502c2502b2502a25029250292502925029250292502b2502b2502b250
011000002e2501b3202e2501b3202e2502d2502d2502d2502b2502b2502b2502b2502b250292502925029250272501b320272501b320272502625024250222502125021250212502125021250222502225022250
0110000024250183202425018320242502325024250252502425024250242502425024250222502225022250212501a320212501a320212501f2501e2501c2501e2501e2501e2501e2501a2501e2501e2501e250
__music__
00 094a5044
00 094a0c54
00 094a0f4d
00 094a0c0d
00 094a0f0e
00 090b0c0d
00 090b0f0e
01 090b1014
00 090b1115
00 090b1216
04 090b1317
00 090b1814
00 090b1915
00 090b1a16
04 090b1b17
00 090b1c14
00 090b1d15
00 090b1e16
00 090b1f17
04 090b2014
00 090b2115
00 090b2216
04 090b2317
00 090b1014
00 090b1115
00 090b1216
04 090b1317
00 090b2414
00 090b2515
00 090b2616
04 090b2717
04 090b2814
00 090b2915
00 090b2a16
04 090b2b17
04 090b2c14
00 090b2d15
00 090b2e16
04 090b2f17
00 090b3014
00 090b3115
00 090b3216
04 090b3317
00 090b2014
00 090b2d15
00 090b2e16
02 090b2f17

