--[[
    recon4_attack.lua - MODE REKAM: tangkap tombol attack dari input asli
    by Tezydner (dibantu Notion AI)

    KENAPA RONDE 3 GAGAL:
      Filter tombol cuma cek .Visible, padahal tombol di dalam frame yang
      TERTUTUP tetap punya Visible = true. Jadi 211 "tombol visible" itu
      isinya menu-menu yang lagi ketutup, dan kandidat teratas malah
      Stats.Melee.Add (tombol tambah poin stat). Koordinatnya pun di luar
      layar (Y=637 padahal viewport 540).

    PENDEKATAN BARU:
      Tidak menebak sama sekali. Script merekam SETIAP sentuhan/klik-mu,
      lalu saat RE/RegisterAttack benar-benar terkirim, dia melaporkan
      objek GUI apa yang barusan kamu sentuh. Itulah tombol attack asli.

    CARA PAKAI:
      1. Jalankan sendirian, dekat mob.
      2. Pencet REKAM di panel.
      3. PUKUL MANUAL 5 kali pakai tombol kepalan seperti biasa.
      4. Baca bagian HASIL. Screenshot / pencet COPY.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- PANEL
-- ============================================================
local lines, label, scroll = {}, nil, nil

local function refresh()
	if not label then return end
	label.Text = table.concat(lines, "\n")
	label.Size = UDim2.new(1, -10, 0, math.max(300, #lines * 15))
	scroll.CanvasSize = UDim2.new(0, 0, 0, label.Size.Y.Offset + 20)
	scroll.CanvasPosition = Vector2.new(0, math.max(0, label.Size.Y.Offset - scroll.AbsoluteSize.Y))
end

local function log(text)
	table.insert(lines, tostring(text))
	print("[R4] " .. tostring(text))
	refresh()
end

local function section(t)
	log("")
	log("===== " .. t .. " =====")
end

local gui = Instance.new("ScreenGui")
gui.Name = "Recon4"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
local ok = pcall(function()
	gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not ok then gui.Parent = playerGui end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 420, 0, 300)
frame.Position = UDim2.new(0, 8, 0, 30)
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 24)
title.BackgroundColor3 = Color3.fromRGB(150, 90, 0)
title.BorderSizePixel = 0
title.Text = "RECON 4 - mode rekam"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 14
title.Parent = frame

local function mkBtn(text, x, w, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, w, 0, 22)
	b.Position = UDim2.new(0, x, 0, 27)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.SourceSansBold
	b.TextSize = 13
	b.Parent = frame
	return b
end

local recBtn = mkBtn("REKAM", 6, 90, Color3.fromRGB(160, 40, 40))
local listBtn = mkBtn("LIST TOMBOL", 100, 100, Color3.fromRGB(50, 90, 150))
local copyBtn = mkBtn("COPY", 204, 60, Color3.fromRGB(70, 70, 80))
local closeBtn = mkBtn("TUTUP", 268, 60, Color3.fromRGB(90, 90, 90))

scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 1, -58)
scroll.Position = UDim2.new(0, 4, 0, 54)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.Parent = frame

label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -10, 0, 300)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(215, 235, 215)
label.Font = Enum.Font.Code
label.TextSize = 12
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.TextWrapped = true
label.Text = ""
label.Parent = scroll

closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)
copyBtn.MouseButton1Click:Connect(function()
	if setclipboard then
		pcall(setclipboard, table.concat(lines, "\n"))
		copyBtn.Text = "OK"
	end
end)

log("panel siap.")
log("PERINGATAN: ronde 3 sempat menembak tombol")
log("Stats.Melee.Add 3x lewat firesignal.")
log("Cek poin stat Melee-mu, mungkin nambah 3.")

-- ============================================================
-- UTIL
-- ============================================================
local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(960, 540)

-- FIX ronde 3: cek visibilitas SELURUH rantai induk, bukan cuma objeknya.
local function trulyOnScreen(obj)
	local good = false
	pcall(function()
		if not obj.Visible then return end
		local parent = obj.Parent
		while parent and parent:IsA("GuiObject") do
			if not parent.Visible then return end
			parent = parent.Parent
		end
		local layer = obj:FindFirstAncestorWhichIsA("LayerCollector")
		if layer and not layer.Enabled then return end
		local c = obj.AbsolutePosition + obj.AbsoluteSize / 2
		if c.X < 0 or c.Y < 0 or c.X > viewport.X or c.Y > viewport.Y then return end
		good = true
	end)
	return good
end

local function guiAt(x, y)
	local names = {}
	pcall(function()
		for _, obj in ipairs(playerGui:GetGuiObjectsAtPosition(x, y)) do
			if #names < 4 then
				table.insert(names, obj.ClassName .. " " .. obj:GetFullName())
			end
		end
	end)
	return names
end

-- ============================================================
-- LIST TOMBOL YANG BENAR-BENAR DI LAYAR
-- ============================================================
listBtn.MouseButton1Click:Connect(function()
	section("TOMBOL BENAR-BENAR DI LAYAR")
	local found = {}
	for _, item in ipairs(playerGui:GetDescendants()) do
		if (item:IsA("ImageButton") or item:IsA("TextButton") or item:IsA("ImageLabel") or item:IsA("Frame"))
			and trulyOnScreen(item) then
			local c = item.AbsolutePosition + item.AbsoluteSize / 2
			-- tombol attack mobile ada di bawah layar
			if c.Y > viewport.Y * 0.55 and item.AbsoluteSize.X >= 30 and item.AbsoluteSize.Y >= 30 then
				table.insert(found, { obj = item, c = c })
			end
		end
	end
	table.sort(found, function(a, b) return a.c.Y > b.c.Y end)
	log("  ketemu " .. #found .. " elemen di paruh bawah layar")
	for i = 1, math.min(#found, 18) do
		local f = found[i]
		log(string.format("  [%02d] (%d,%d) %dx%d %s", i, f.c.X, f.c.Y,
			f.obj.AbsoluteSize.X, f.obj.AbsoluteSize.Y, f.obj.ClassName))
		log("       " .. f.obj:GetFullName())
	end
end)

-- ============================================================
-- REKAM
-- ============================================================
local lastInput = nil
local attackCount = 0
local recording = false
local reported = 0

UserInputService.InputBegan:Connect(function(input, processed)
	if not recording then return end
	if input.UserInputType == Enum.UserInputType.Touch
		or input.UserInputType == Enum.UserInputType.MouseButton1 then
		lastInput = {
			x = input.Position.X,
			y = input.Position.Y,
			processed = processed,
			type = input.UserInputType.Name,
			clock = os.clock(),
		}
	elseif input.UserInputType == Enum.UserInputType.Keyboard then
		lastInput = {
			key = input.KeyCode.Name,
			processed = processed,
			type = "Keyboard",
			clock = os.clock(),
		}
	end
end)

local hooked = false
local function installHook()
	if hooked then return end
	if not (hookmetamethod and getnamecallmethod) then
		log("  hookmetamethod tidak ada")
		return
	end
	local old
	old = hookmetamethod(game, "__namecall", function(self, ...)
		if recording and getnamecallmethod() == "FireServer" then
			pcall(function()
				if self.Name ~= "RE/RegisterAttack" then return end
				attackCount = attackCount + 1
				if reported >= 6 then return end
				reported = reported + 1
				log("")
				log("** ATTACK #" .. attackCount .. " terdeteksi")
				if not lastInput then
					log("   tidak ada input tercatat sebelumnya (?)")
					return
				end
				local age = os.clock() - lastInput.clock
				log(string.format("   input: %s, %.2fs lalu, gameProcessed=%s",
					lastInput.type, age, tostring(lastInput.processed)))
				if lastInput.key then
					log("   tombol keyboard: " .. lastInput.key)
					return
				end
				log(string.format("   posisi: (%d, %d)", lastInput.x, lastInput.y))
				local inset = GuiService:GetGuiInset()
				local hits = guiAt(lastInput.x, lastInput.y)
				if #hits == 0 then
					hits = guiAt(lastInput.x, lastInput.y - inset.Y)
					if #hits > 0 then log("   (perlu koreksi inset Y=" .. inset.Y .. ")") end
				end
				if #hits == 0 then
					log("   TIDAK ADA GUI di titik itu -> attack bukan dari tombol GUI")
				else
					for i, name in ipairs(hits) do
						log("   GUI" .. i .. ": " .. name)
					end
				end
			end)
		end
		return old(self, ...)
	end)
	hooked = true
end

recBtn.MouseButton1Click:Connect(function()
	if recording then
		recording = false
		recBtn.Text = "REKAM"
		recBtn.BackgroundColor3 = Color3.fromRGB(160, 40, 40)
		section("HASIL")
		log("  total attack terekam: " .. attackCount)
		if attackCount == 0 then
			log("  Kamu belum memukul, atau attack-nya")
			log("  tidak lewat RE/RegisterAttack.")
		else
			log("  Kirim baris GUI1 di atas - itu tombolnya.")
		end
		return
	end

	installHook()
	recording = true
	attackCount = 0
	reported = 0
	recBtn.Text = "STOP"
	recBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 60)
	section("REKAM AKTIF")
	log("  >> PUKUL MANUAL 5x SEKARANG <<")
	log("  lalu pencet STOP")
end)
