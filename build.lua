local top_start = {-224.5, -137.5} -- Bottom left combinator
local bottom_start = {-224.5, 138.5} -- Top left combinator

local x_frame = {0,17,30,47,60,77}
local y_wire = {
1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,1,2,3,
4,5,4,5,4,5,4,5,4,5,4,5,4,5,4,5,4,5,4,5,
1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,
3,4,5,3,4,5,3,4,5,3,4,5,3,4,5,3,4,5,3,4,5,3,4,5,3,4,5,3,4,5}
local y_shift = {1,1,1,8,8,8,64,64,64,512,512,512,4096,4096,4096,32768,32768,32768,262144,262144,262144,2097152,2097152,2097152,16777216,16777216,16777216,134217728,134217728,134217728,
1,1,8,8,64,64,512,512,4096,4096,32768,32768,262144,262144,2097152,2097152,16777216,16777216,134217728,134217728,
1,1,8,8,64,64,512,512,4096,4096,32768,32768,262144,262144,2097152,2097152,16777216,16777216,134217728,134217728,
1,1,1,8,8,8,64,64,64,512,512,512,4096,4096,4096,32768,32768,32768,262144,262144,262144,2097152,2097152,2097152,16777216,16777216,16777216,134217728,134217728,134217728}
local unix = io.popen('uname'):read()

function scanDir(dir, ext)
	local files = {}
	local pfile
	if (unix) then
		pfile = io.popen('ls "'..dir..'/'..ext..'"')
		for filename in pfile:lines() do
			table.insert(files, filename)
		end
	else
		pfile = io.popen('dir "'..dir..'\\'..ext..'" /b')
		for filename in pfile:lines() do
			table.insert(files, dir.."\\"..filename)
		end
	end
	pfile:close()
	return files
end

function ReadWORD(str, offset)
	local loByte = str:byte(offset);
	local hiByte = str:byte(offset+1);
	return hiByte*256 + loByte;
end

function ReadDWORD(str, offset)
	local loWord = ReadWORD(str, offset);
	local hiWord = ReadWORD(str, offset+2);
	return hiWord*65536 + loWord;
end

function LoadBitmap(file)
	local f = assert(io.open(file, "rb"));
	local bytecode = f:read("*a");
	f:close();

	-- Parse BITMAPFILEHEADER
	local offset = 1;
	local bfType = ReadWORD(bytecode, offset);
	if(bfType ~= 0x4D42) then
		print("Not a bitmap file (Invalid BMP magic value)");
		return;
	end
	local bfOffBits = ReadWORD(bytecode, offset+10);

	-- Parse BITMAPINFOHEADER
	offset = 15; -- BITMAPFILEHEADER is 14 bytes long
	local biWidth = ReadDWORD(bytecode, offset+4);
	local biHeight = ReadDWORD(bytecode, offset+8);
	local biBitCount = ReadWORD(bytecode, offset+14);
	local biCompression = ReadDWORD(bytecode, offset+16);
	if(biBitCount ~= 24 and biBitCount ~= 32) then
		print("Only 24-bit or 32-bit bitmaps supported (Is " .. biBitCount .. "bpp)");
		return;
	end
	if(biCompression ~= 0) then
		print("Only uncompressed bitmaps supported (Compression type is " .. biCompression .. ")");
		return;
	end
	
	-- Parse bitmap image
	local pixels = {}
	for y = biHeight-1, 0, -1 do
		local rowLength = biWidth * biBitCount // 8
		rowLength = rowLength + (4 - (rowLength % 4)) % 4
		local offset = bfOffBits + rowLength*y + 1;
		
		for x = 1, biWidth do
			local b = bytecode:byte(offset);
			local g = bytecode:byte(offset+1);
			local r = bytecode:byte(offset+2);
			offset = offset + biBitCount // 8;

			if (not pixels[x]) then
				pixels[x] = {}
			end
			pixels[x][biHeight-y] = r .. "," .. g .. "," .. b
		end
	end
	return pixels
end

function writeScriptHeader(file)
	file:write("/c local signals = {{'wooden-chest','iron-chest','steel-chest','storage-tank','transport-belt','fast-transport-belt','express-transport-belt','underground-belt','fast-underground-belt','express-underground-belt','splitter','fast-splitter','express-splitter','burner-inserter','inserter'},{'long-handed-inserter','fast-inserter','filter-inserter','stack-inserter','stack-filter-inserter','small-electric-pole','medium-electric-pole','big-electric-pole','substation','pipe','pipe-to-ground','small-pump','car','tank','logistic-robot'},{'construction-robot','logistic-chest-active-provider','logistic-chest-passive-provider','logistic-chest-requester','logistic-chest-storage','roboport','red-wire','green-wire','arithmetic-combinator','decider-combinator','constant-combinator','power-switch','stone-brick','concrete','hazard-concrete'},{'repair-pack','boiler','small-lamp','solar-panel','accumulator','burner-mining-drill','electric-mining-drill','offshore-pump','pumpjack','stone-furnace','steel-furnace','electric-furnace','assembling-machine-1','assembling-machine-2','assembling-machine-3'},{'oil-refinery','chemical-plant','lab','beacon','speed-module','speed-module-2','speed-module-3','effectivity-module','effectivity-module-2','effectivity-module-3','productivity-module','productivity-module-2','productivity-module-3','solid-fuel','stone'},{'iron-ore','raw-fish','copper-ore','raw-wood','wood','coal','iron-plate','copper-plate','steel-plate','sulfur','plastic-bar','copper-cable','iron-stick','iron-gear-wheel','electronic-circuit'},{'advanced-circuit','processing-unit','engine-unit','electric-engine-unit','explosives','battery','flying-robot-frame','science-pack-1','science-pack-2','pistol','submachine-gun','shotgun','combat-shotgun','rocket-launcher','flame-thrower'},{'land-mine','firearm-magazine','piercing-rounds-magazine','shotgun-shell','piercing-shotgun-shell','cannon-shell','explosive-cannon-shell','rocket','explosive-rocket','flame-thrower-ammo','grenade','cluster-grenade','poison-capsule','slowdown-capsule','defender-capsule'},{'distractor-capsule','destroyer-capsule','light-armor','heavy-armor','modular-armor','power-armor','power-armor-mk2','solar-panel-equipment','energy-shield-equipment','energy-shield-mk2-equipment','battery-equipment','battery-mk2-equipment','personal-laser-defense-equipment','exoskeleton-equipment','personal-roboport-equipment'},{'night-vision-equipment','stone-wall','flamethrower-turret','gun-turret','laser-turret','radar','water','crude-oil','heavy-oil','light-oil','petroleum-gas','sulfuric-acid','lubricant','signal-0','signal-1'},{'signal-2','signal-3','signal-4','signal-5','signal-6','signal-7','signal-8','signal-9','signal-B','signal-C','signal-D','signal-E','signal-F','signal-G','signal-H'},{'signal-I','signal-J','signal-K','signal-L','signal-M','signal-N','signal-O','signal-P','signal-Q','signal-R','signal-S','signal-T','signal-U','signal-V','signal-W'}}; local get_type = function(n) local type = 'item'; if (n >= 157) then type = 'fluid' end; if (n >= 164) then type = 'virtual' end; return type end; local f = function(x, y, signal_set, ...) local combinator = game.player.surface.find_entities_filtered{name='constant-combinator',position={x,y}}[1]; local args = {...}; local parameters = {parameters={}}; for i = 1,15 do table.insert(parameters.parameters, {index=i, signal={type=get_type(signal_set*15+i), name=signals[signal_set][i]}, count=args[i]}) end; combinator.get_control_behavior().parameters = parameters end\n");
end

local c = 0
local top_signals = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local bottom_signals = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local top_script, bottom_script
function writeCombinator()
    local block = c // 36000
	if (c % 36000 == 0) then
		if (c > 0) then
			top_script:close()
			bottom_script:close()
		end
		os.remove("script/top"..string.format("%02d",block+1)..".txt")
		os.remove("script/bottom"..string.format("%02d",block+1)..".txt")
		top_script = io.open("script/top"..string.format("%02d",block+1)..".txt", "w+")
		bottom_script = io.open("script/bottom"..string.format("%02d",block+1)..".txt", "w+")
		writeScriptHeader(top_script)
		writeScriptHeader(bottom_script)
	end

	local frame = (c // 60) % 6 -- 6 frames per row
	local group = (c // 12) % 5 -- 5 groups of 12 combinators per frame
	local z = c % 12
	local x = z + x_frame[frame+1] + 90*group
	local y = c // 360 + block * 2
	top_script:write("f("..(top_start[1]+x)..","..(top_start[2]-y)..","..(z+1)..","..table.concat(top_signals, ",")..")\n")
	bottom_script:write("f("..(bottom_start[1]+x)..","..(bottom_start[2]+y)..","..(z+1)..","..table.concat(bottom_signals, ",")..")\n")
	top_signals = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	bottom_signals = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	c = c + 1
end

-- Load palette
local palette = {}
local pixels = LoadBitmap("palette.bmp")
for i = 1,7 do
	palette[pixels[i][1]] = i
end

-- Load image list
local files = scanDir("images", "*.bmp")

-- Process images
for index,file in pairs(files) do
	print("processing "..file)
	pixels = LoadBitmap(file)

	local count = 0
	for x = 1,178 do 
		for y = 1,100 do
			local color = palette[pixels[x][y]] or 0
			local position = y_wire[y] + ((x-1)%3)*5
			if (y <= 50) then
				top_signals[position] = top_signals[position] + color * y_shift[y]
			else
				bottom_signals[position] = bottom_signals[position] + color * y_shift[y]
			end
		end
		count = count + 1
		if (count == 3) then
			writeCombinator()
			count = 0
		end
	end
	writeCombinator()
end

