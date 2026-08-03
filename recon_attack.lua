--[[
    recon2_attack.lua - Recon ronde 2: cari pemicu attack yang benar
    by Tezydner (dibantu Notion AI)

    TEMUAN RONDE 1:
      - PlayerScripts.CombatFramework TIDAK ADA di versi ini -> semua jalur
        activeController percuma.
      - Hit asli dikirim lewat remote obfuscated "811" dengan token sesi,
        BUKAN sesuatu yang aman kita karang sendiri.
      - Jadi: kita tidak memalsukan hit. Kita picu tombol attack milik game,
        biar game sendiri yang menghitung hitbox dan mengirim hit-nya.

    CARA PAKAI:
      1. Jalankan SENDIRIAN (hub jangan jalan).
      2. Berdiri DEKAT mob (5-10 stud) supaya hitbox kena.
      3. Diam saja. Script akan mengklik tombol attack 3x sendiri setelah
         hitung mundur 5 detik, lalu melaporkan apakah RE/RegisterAttack
         benar-benar terkirim.
      4. Kirim seluruh output console (F9).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local localPlayer = Players.LocalPlayer

local report = {}
local function log(text)
	table.insert(report, tostring(text))
	print("[RECON2] " .. tostring(text))
end
local function section(title)
	log("")
	log("===== " .. title .. " =====")
end

-- ============================================================
-- A. CAPABILITY (dites ulang, ronde 1 salah deteksi)
-- ============================================================
section("A. CAPABILITY (ulang)")

local caps = {
	hookmetamethod = hookmetamethod,
	getnamecallmethod = getnamecallmethod,
	getrawmetatable = getrawmetatable,
	setreadonly = setreadonly,
	hookfunction = hookfunction,
	firesignal = firesignal,
	getconnections = getconnections,
	setclipboard = setclipboard,
	getgc = getgc,
	getsenv = getsenv,
}
for name, fn in pairs(caps) do
	log(string.format("  %-18s %s", name, fn and "ADA" or "tidak ada"))
end
log("  VirtualInputManager: " .. tostring(pcall(function()
	return game:GetService("VirtualInputManager")
end)))

-- ============================================================
-- B. REMOTE HIT YANG OBFUSCATED
-- ============================================================
section("B. REMOTE HIT")

local net = ReplicatedStorage:FindFirstChild("Modules")
net = net and net:FindFirstChild("Net")
log("RE/RegisterAttack: " .. tostring(net and net:FindFirstChild("RE/RegisterAttack") ~= nil))
log("RE/RegisterHit   : " .. tostring(net and net:FindFirstChild("RE/RegisterHit") ~= nil))

for _, item in ipairs(ReplicatedStorage:GetDescendants()) do
	if (item:IsA("RemoteEvent") or item:IsA("RemoteFunction")) and tonumber(item.Name) then
		log(string.format("  remote angka: %-6s di %s", item.Name, item.Parent:GetFullName()))
	end
end

-- ============================================================
-- C. TOMBOL DI PLAYERGUI
-- ============================================================
section("C. GUI BUTTON")

local playerGui = localPlayer:FindFirstChildOfClass("PlayerGui")
local buttons = {}

if playerGui then
	for _, item in ipairs(playerGui:GetDescendants()) do
		if item:IsA("ImageButton") or item:IsA("TextButton") then
			local ok = pcall(function()
				if item.Visible and item.AbsoluteSize.X > 20 and item.AbsoluteSize.Y > 20 then
					table.insert(buttons, item)
				end
			end)
		end
	end
end

log("tombol visible: " .. #buttons)

local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(0, 0)
log("viewport: " .. tostring(viewport))

local ATTACK_WORDS = { "attack", "fist", "combat", "melee", "hit", "punch", "m1" }

local function scoreButton(btn)
	local name = (btn.Name .. " " .. btn:GetFullName()):lower()
	local score = 0
	for _, word in ipairs(ATTACK_WORDS) do
		if name:find(word, 1, true) then score = score + 10 end
	end
	-- tombol attack mobile biasanya di bawah, agak ke tengah/kanan
	local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
	if viewport.Y > 0 and pos.Y > viewport.Y * 0.6 then score = score + 3 end
	if viewport.X > 0 and pos.X > viewport.X * 0.35 then score = score + 1 end
	return score, pos
end

table.sort(buttons, function(a, b)
	local sa = scoreButton(a)
	local sb = scoreButton(b)
	return sa > sb
end)

for i = 1, math.min(#buttons, 25) do
	local btn = buttons[i]
	local score, pos = scoreButton(btn)
	log(string.format("  [%02d] score=%-3d pos=(%d,%d) size=(%d,%d) %s",
		i, score, pos.X, pos.Y, btn.AbsoluteSize.X, btn.AbsoluteSize.Y, btn:GetFullName()))
end

local candidate = buttons[1]
if candidate then
	log("KANDIDAT: " .. candidate:GetFullName())
else
	log("tidak ada kandidat tombol")
end

-- ============================================================
-- D. HOOK PEMANTAU
-- ============================================================
section("D. TES KLIK OTOMATIS")

local fired = { attack = 0, hit = 0, other = 0 }
local hookOk = false

if hookmetamethod and getnamecallmethod then
	local old
	old = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if method == "FireServer" or method == "InvokeServer" then
			pcall(function()
				local n = self.Name
				if n == "RE/RegisterAttack" then
					fired.attack = fired.attack + 1
					log("    >> RE/RegisterAttack terkirim!")
				elseif n == "RE/RegisterHit" or tonumber(n) then
					fired.hit = fired.hit + 1
					log("    >> HIT terkirim lewat remote: " .. n)
				end
			end)
		end
		return old(self, ...)
	end)
	hookOk = true
	log("pemantau aktif")
else
	log("hookmetamethod tidak ada, hasil tes tidak bisa dipastikan otomatis")
end

-- ============================================================
-- E. EKSEKUSI TES
-- ============================================================
local function clickViaSignal(btn)
	if not (firesignal and getconnections) then return false end
	local ok = pcall(function()
		for _, signal in ipairs({ btn.MouseButton1Down, btn.MouseButton1Click, btn.MouseButton1Up }) do
			for _, conn in ipairs(getconnections(signal)) do
				if conn.Fire then conn:Fire() end
			end
		end
	end)
	return ok
end

local function clickViaVirtualUser(btn)
	local ok = pcall(function()
		local VirtualUser = game:GetService("VirtualUser")
		local inset = GuiService:GetGuiInset()
		local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
		local x, y = pos.X, pos.Y + inset.Y
		log(string.format("    klik VirtualUser di (%d, %d)", x, y))
		VirtualUser:CaptureController()
		VirtualUser:Button1Down(Vector2.new(x, y))
		task.wait(0.05)
		VirtualUser:Button1Up(Vector2.new(x, y))
	end)
	return ok
end

local function clickViaVIM(btn)
	local ok = pcall(function()
		local vim = game:GetService("VirtualInputManager")
		local inset = GuiService:GetGuiInset()
		local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
		local x, y = pos.X, pos.Y + inset.Y
		log(string.format("    klik VIM di (%d, %d)", x, y))
		vim:SendMouseButtonEvent(x, y, 0, true, game, 1)
		task.wait(0.05)
		vim:SendMouseButtonEvent(x, y, 0, false, game, 1)
	end)
	return ok
end

task.spawn(function()
	if not candidate then
		log("tes dibatalkan: tombol tidak ketemu")
		return
	end

	for i = 5, 1, -1 do
		log("tes mulai dalam " .. i .. " detik - berdiri dekat mob, jangan pencet apa pun")
		task.wait(1)
	end

	local methods = {
		{ name = "firesignal", fn = clickViaSignal },
		{ name = "VirtualUser", fn = clickViaVirtualUser },
		{ name = "VirtualInputManager", fn = clickViaVIM },
	}

	for _, method in ipairs(methods) do
		local before = fired.attack
		log("-- metode: " .. method.name)
		for _ = 1, 3 do
			method.fn(candidate)
			task.wait(0.4)
		end
		task.wait(0.6)
		local delta = fired.attack - before
		log(string.format("   hasil %s: RE/RegisterAttack +%d", method.name, delta))
		if delta > 0 then
			log("   *** METODE INI BERHASIL MEMICU ATTACK ***")
		end
	end

	section("RINGKASAN")
	log("total RegisterAttack: " .. fired.attack)
	log("total hit terkirim  : " .. fired.hit)
	if fired.attack == 0 then
		log("Tidak ada satu pun metode klik yang tembus.")
		log("Kirim daftar tombol di bagian C, mungkin kandidatnya salah pilih.")
	end
	log("SELESAI - salin seluruh output ini")
end)
