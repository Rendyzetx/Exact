--[[
    recon3_attack.lua - Recon dengan OUTPUT DI LAYAR (tidak butuh console F9)
    by Tezydner (dibantu Notion AI)

    Perbaikan dari recon2:
      - Semua hasil tampil di panel GUI dalam game, bukan print ke console.
      - Tidak lagi scan ReplicatedStorage:GetDescendants() (bisa bikin freeze
        di Blox Fruits karena isinya puluhan ribu instance).
      - Setiap bagian dibungkus pcall sendiri, jadi satu error tidak
        mematikan seluruh script diam-diam.

    CARA PAKAI:
      1. Jalankan sendirian. Panel hitam muncul di kiri layar.
      2. Berdiri DEKAT mob (5-10 stud).
      3. Pencet tombol START di panel, lalu JANGAN sentuh apa pun 15 detik.
      4. Screenshot panelnya, atau pencet COPY kalau tombolnya aktif.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local localPlayer = Players.LocalPlayer

-- ============================================================
-- PANEL OUTPUT
-- ============================================================
local lines = {}
local label, scroll

local function refresh()
	if not label then return end
	label.Text = table.concat(lines, "\n")
	label.Size = UDim2.new(1, -10, 0, math.max(300, #lines * 15))
	if scroll then
		scroll.CanvasSize = UDim2.new(0, 0, 0, label.Size.Y.Offset + 20)
	end
end

local function log(text)
	table.insert(lines, tostring(text))
	print("[R3] " .. tostring(text))
	refresh()
end

local function section(title)
	log("")
	log("===== " .. title .. " =====")
end

local function step(name, fn)
	local ok, err = pcall(fn)
	if not ok then
		log("!! ERROR di " .. name .. ": " .. tostring(err))
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "Recon3"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local parented = pcall(function()
	gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
end)
if not parented then
	gui.Parent = localPlayer:WaitForChild("PlayerGui")
end

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 430, 0, 330)
frame.Position = UDim2.new(0, 10, 0, 40)
frame.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
frame.BackgroundTransparency = 0.08
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 26)
title.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
title.BorderSizePixel = 0
title.Text = "RECON 3 - jalur attack"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 15
title.Parent = frame

local function makeButton(text, xScale, xOffset, width, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, width, 0, 24)
	b.Position = UDim2.new(xScale, xOffset, 0, 30)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.SourceSansBold
	b.TextSize = 14
	b.Parent = frame
	return b
end

local startBtn = makeButton("START TES", 0, 6, 110, Color3.fromRGB(30, 130, 60))
local copyBtn = makeButton("COPY", 0, 122, 70, Color3.fromRGB(70, 70, 80))
local closeBtn = makeButton("TUTUP", 1, -76, 70, Color3.fromRGB(140, 40, 40))

scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -8, 1, -64)
scroll.Position = UDim2.new(0, 4, 0, 60)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.Parent = frame

label = Instance.new("TextLabel")
label.Size = UDim2.new(1, -10, 0, 300)
label.BackgroundTransparency = 1
label.Text = ""
label.TextColor3 = Color3.fromRGB(210, 235, 210)
label.Font = Enum.Font.Code
label.TextSize = 12
label.TextXAlignment = Enum.TextXAlignment.Left
label.TextYAlignment = Enum.TextYAlignment.Top
label.TextWrapped = true
label.Parent = scroll

closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
end)

copyBtn.MouseButton1Click:Connect(function()
	if setclipboard then
		pcall(setclipboard, table.concat(lines, "\n"))
		copyBtn.Text = "TERSALIN"
	else
		copyBtn.Text = "NO CLIP"
	end
end)

log("panel siap. kalau kamu lihat teks ini, script JALAN.")

-- ============================================================
-- A. CAPABILITY
-- ============================================================
step("A", function()
	section("A. CAPABILITY")
	local names = {
		"hookmetamethod", "getnamecallmethod", "firesignal", "getconnections",
		"setclipboard", "gethui", "getrawmetatable", "hookfunction",
	}
	local values = {
		hookmetamethod, getnamecallmethod, firesignal, getconnections,
		setclipboard, gethui, getrawmetatable, hookfunction,
	}
	for i, name in ipairs(names) do
		log(string.format("  %-18s %s", name, values[i] and "ADA" or "-"))
	end
	log("  VirtualInputManager " .. (pcall(function()
		return game:GetService("VirtualInputManager")
	end) and "ADA" or "-"))
end)

-- ============================================================
-- B. REMOTE (tanpa scan berat)
-- ============================================================
step("B", function()
	section("B. REMOTE")
	local modules = ReplicatedStorage:FindFirstChild("Modules")
	local net = modules and modules:FindFirstChild("Net")
	log("  Net folder: " .. (net and "ada" or "tidak ada"))
	if net then
		log("  RE/RegisterAttack: " .. tostring(net:FindFirstChild("RE/RegisterAttack") ~= nil))
		log("  RE/RegisterHit   : " .. tostring(net:FindFirstChild("RE/RegisterHit") ~= nil))
		for _, item in ipairs(net:GetChildren()) do
			if tonumber(item.Name) then
				log("  remote angka di Net: " .. item.Name)
			end
		end
	end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if remotes then
		for _, item in ipairs(remotes:GetChildren()) do
			if tonumber(item.Name) then
				log("  remote angka di Remotes: " .. item.Name)
			end
		end
	end
end)

-- ============================================================
-- C. TOMBOL ATTACK
-- ============================================================
local candidate = nil
local buttons = {}

step("C", function()
	section("C. TOMBOL")
	local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		log("  PlayerGui tidak ada")
		return
	end

	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1, 1)
	log("  viewport: " .. math.floor(viewport.X) .. "x" .. math.floor(viewport.Y))

	local words = { "attack", "fist", "combat", "melee", "punch", "m1", "hit" }

	for _, item in ipairs(playerGui:GetDescendants()) do
		if item:IsA("ImageButton") or item:IsA("TextButton") then
			pcall(function()
				if item.Visible and item.AbsoluteSize.X >= 25 and item.AbsoluteSize.Y >= 25 then
					local center = item.AbsolutePosition + item.AbsoluteSize / 2
					local path = item:GetFullName():lower()
					local score = 0
					for _, w in ipairs(words) do
						if path:find(w, 1, true) then score = score + 10 end
					end
					if center.Y > viewport.Y * 0.6 then score = score + 4 end
					if center.X > viewport.X * 0.2 and center.X < viewport.X * 0.8 then score = score + 2 end
					table.insert(buttons, { obj = item, score = score, center = center })
				end
			end)
		end
	end

	table.sort(buttons, function(a, b) return a.score > b.score end)
	log("  total tombol visible: " .. #buttons)

	for i = 1, math.min(#buttons, 15) do
		local b = buttons[i]
		log(string.format("  [%02d] s=%d (%d,%d) %dx%d %s",
			i, b.score, b.center.X, b.center.Y,
			b.obj.AbsoluteSize.X, b.obj.AbsoluteSize.Y, b.obj.Name))
		log("       " .. b.obj:GetFullName())
	end

	candidate = buttons[1] and buttons[1].obj or nil
	log("  KANDIDAT: " .. (candidate and candidate.Name or "tidak ada"))
end)

-- ============================================================
-- D. PEMANTAU
-- ============================================================
local fired = { attack = 0, hit = 0 }

step("D", function()
	section("D. PEMANTAU")
	if not (hookmetamethod and getnamecallmethod) then
		log("  hookmetamethod tidak ada -> hasil dinilai manual dari HP mob")
		return
	end
	local old
	old = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if method == "FireServer" then
			pcall(function()
				local n = self.Name
				if n == "RE/RegisterAttack" then
					fired.attack = fired.attack + 1
				elseif n == "RE/RegisterHit" or tonumber(n) then
					fired.hit = fired.hit + 1
				end
			end)
		end
		return old(self, ...)
	end)
	log("  pemantau aktif")
end)

-- ============================================================
-- E. TES KLIK
-- ============================================================
local function clickSignal(btn)
	if not (firesignal and getconnections) then return false end
	return pcall(function()
		for _, sig in ipairs({ btn.MouseButton1Down, btn.MouseButton1Click, btn.MouseButton1Up }) do
			for _, c in ipairs(getconnections(sig)) do
				if c.Fire then c:Fire() end
			end
		end
	end)
end

local function clickVirtualUser(btn)
	return pcall(function()
		local VirtualUser = game:GetService("VirtualUser")
		local inset = GuiService:GetGuiInset()
		local p = btn.AbsolutePosition + btn.AbsoluteSize / 2
		local x, y = p.X, p.Y + inset.Y
		log(string.format("    VU klik (%d,%d)", x, y))
		VirtualUser:CaptureController()
		VirtualUser:Button1Down(Vector2.new(x, y))
		task.wait(0.06)
		VirtualUser:Button1Up(Vector2.new(x, y))
	end)
end

local function clickVIM(btn)
	return pcall(function()
		local vim = game:GetService("VirtualInputManager")
		local inset = GuiService:GetGuiInset()
		local p = btn.AbsolutePosition + btn.AbsoluteSize / 2
		local x, y = p.X, p.Y + inset.Y
		log(string.format("    VIM klik (%d,%d)", x, y))
		vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
		task.wait(0.06)
		vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
	end)
end

local function clickTouch(btn)
	return pcall(function()
		local vim = game:GetService("VirtualInputManager")
		local inset = GuiService:GetGuiInset()
		local p = btn.AbsolutePosition + btn.AbsoluteSize / 2
		local x, y = p.X, p.Y + inset.Y
		log(string.format("    TOUCH (%d,%d)", x, y))
		vim:SendTouchEvent(1, 0, x, y) -- Begin
		task.wait(0.06)
		vim:SendTouchEvent(1, 2, x, y) -- End
	end)
end

local running = false

startBtn.MouseButton1Click:Connect(function()
	if running then return end
	running = true
	startBtn.Text = "BERJALAN..."

	task.spawn(function()
		section("E. TES KLIK")
		if not candidate then
			log("  batal: tombol kandidat tidak ada")
			startBtn.Text = "START TES"
			running = false
			return
		end

		for i = 3, 1, -1 do
			log("  mulai dalam " .. i .. " - jangan sentuh apa pun")
			task.wait(1)
		end

		local methods = {
			{ "firesignal", clickSignal },
			{ "VirtualUser", clickVirtualUser },
			{ "VIM mouse", clickVIM },
			{ "VIM touch", clickTouch },
		}

		for _, m in ipairs(methods) do
			local before = fired.attack
			log("  -- " .. m[1])
			for _ = 1, 3 do
				m[2](candidate)
				task.wait(0.35)
			end
			task.wait(0.5)
			local delta = fired.attack - before
			log(string.format("     hasil: RegisterAttack +%d", delta))
			if delta > 0 then
				log("     *** BERHASIL ***")
			end
		end

		section("RINGKASAN")
		log("  RegisterAttack total: " .. fired.attack)
		log("  hit terkirim total  : " .. fired.hit)
		if fired.attack == 0 then
			log("  Tidak ada yang tembus. Kirim daftar tombol bagian C.")
		end
		log("  SELESAI")
		startBtn.Text = "ULANGI"
		running = false
	end)
end)
