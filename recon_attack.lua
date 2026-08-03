--[[
    recon_attack.lua - Diagnosa jalur ATTACK Blox Fruits
    by Tezydner (dibantu Notion AI)

    CARA PAKAI:
      1. Tutup / jangan jalankan hub dulu. Jalankan file ini SENDIRIAN.
      2. Tunggu bagian A-E selesai (instan).
      3. Saat muncul "SNIFFER AKTIF", ATTACK MANUAL ke mob 3-5 kali
         (pencet tombol attack seperti biasa). Jangan pakai auto farm.
      4. Setelah 30 detik hasil lengkap otomatis disalin ke clipboard.
         Paste ke chat.

    Script ini READ-ONLY: cuma membaca & mencatat, tidak menyerang,
    tidak mengubah apa pun di game.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local localPlayer = Players.LocalPlayer

local SNIFF_SECONDS = 30
local MAX_SNIFF_LINES = 60

local report = {}

local function log(text)
	table.insert(report, tostring(text))
	print("[RECON] " .. tostring(text))
end

local function section(title)
	log("")
	log("===== " .. title .. " =====")
end

local function safe(label, fn)
	local ok, result = pcall(fn)
	if ok then
		return result
	end
	log("  ! gagal " .. label .. ": " .. tostring(result))
	return nil
end

local function describe(value)
	local t = typeof(value)
	if t == "Instance" then
		return string.format("%s(%s)", value.ClassName, value.Name)
	elseif t == "table" then
		return "table"
	elseif t == "function" then
		return "function"
	elseif t == "string" then
		return string.format("%q", #value > 60 and (value:sub(1, 60) .. "...") or value)
	elseif t == "Vector3" or t == "CFrame" then
		return t .. "(" .. tostring(value) .. ")"
	end
	return t .. "(" .. tostring(value) .. ")"
end

-- ============================================================
-- A. ENVIRONMENT / EXECUTOR
-- ============================================================
section("A. EXECUTOR")

log("executor: " .. tostring(safe("identifyexecutor", function()
	return (identifyexecutor or getexecutorname)()
end)))
log("PlaceId: " .. tostring(game.PlaceId) .. "  JobId: " .. tostring(game.JobId))

local caps = {
	"hookmetamethod", "getnamecallmethod", "getrawmetatable", "setreadonly",
	"hookfunction", "getgc", "getsenv", "getupvalue", "setclipboard",
	"firesignal", "getconnections",
}
for _, name in ipairs(caps) do
	local fn = rawget(getfenv(), name) or (debug and rawget(debug, name:gsub("^get", "get")))
	if name == "getupvalue" then
		fn = debug and debug.getupvalue
	end
	log(string.format("  %-18s %s", name, fn and "ADA" or "tidak ada"))
end

-- ============================================================
-- B. TOOL / SENJATA
-- ============================================================
section("B. TOOL")

local character = localPlayer.Character
log("character: " .. tostring(character and character.Name or "nil"))

local equipped = character and character:FindFirstChildOfClass("Tool")
if equipped then
	log(string.format("equipped: %s | ToolTip=%q | RequiresHandle=%s",
		equipped.Name, tostring(equipped.ToolTip), tostring(equipped.RequiresHandle)))
else
	log("equipped: TIDAK ADA tool di tangan")
end

local backpack = localPlayer:FindFirstChild("Backpack")
if backpack then
	for _, tool in ipairs(backpack:GetChildren()) do
		if tool:IsA("Tool") then
			log(string.format("  backpack: %-28s ToolTip=%q", tool.Name, tostring(tool.ToolTip)))
		end
	end
else
	log("  Backpack tidak ketemu")
end

-- ============================================================
-- C. PLAYERSCRIPTS
-- ============================================================
section("C. PLAYERSCRIPTS")

local playerScripts = localPlayer:FindFirstChild("PlayerScripts")
if playerScripts then
	for _, child in ipairs(playerScripts:GetChildren()) do
		log(string.format("  %-14s %s", child.ClassName, child.Name))
	end
else
	log("  PlayerScripts tidak ketemu")
end

-- ============================================================
-- D. COMBATFRAMEWORK
-- ============================================================
section("D. COMBATFRAMEWORK")

local cfModule = playerScripts and playerScripts:FindFirstChild("CombatFramework")
log("module: " .. (cfModule and (cfModule.ClassName .. " ditemukan") or "TIDAK DITEMUKAN"))

local cf = cfModule and safe("require CombatFramework", function()
	return require(cfModule)
end)

if type(cf) == "table" then
	log("isi module:")
	for key, value in pairs(cf) do
		log(string.format("  .%-24s = %s", tostring(key), describe(value)))
	end

	local controller = rawget(cf, "activeController")
	log("activeController: " .. (controller and "ADA" or "nil <- ini penyebab utama kalau nil"))

	if type(controller) == "table" then
		log("isi activeController:")
		for key, value in pairs(controller) do
			log(string.format("  :%-24s = %s", tostring(key), describe(value)))
		end
		local blades = rawget(controller, "blades")
		if type(blades) == "table" then
			log("  blades count: " .. tostring(#blades))
		end
	end
elseif cf ~= nil then
	log("hasil require bertipe: " .. typeof(cf))
end

-- ============================================================
-- E. REMOTE YANG TERSEDIA
-- ============================================================
section("E. REMOTE KANDIDAT")

local function dumpRemotes(container, label)
	if not container then
		log(label .. ": tidak ada")
		return
	end
	local count = 0
	for _, item in ipairs(container:GetChildren()) do
		if item:IsA("RemoteEvent") or item:IsA("RemoteFunction") then
			count = count + 1
			local n = item.Name:lower()
			local mark = (n:find("attack") or n:find("hit") or n:find("combat") or n:find("damage")) and "  <== KANDIDAT" or ""
			log(string.format("  %-14s %s%s", item.ClassName, item.Name, mark))
		end
	end
	log(label .. ": " .. count .. " remote")
end

local modules = ReplicatedStorage:FindFirstChild("Modules")
dumpRemotes(modules and modules:FindFirstChild("Net"), "ReplicatedStorage.Modules.Net")
dumpRemotes(ReplicatedStorage:FindFirstChild("Remotes"), "ReplicatedStorage.Remotes")

-- ============================================================
-- F. SNIFFER NAMECALL
-- ============================================================
section("F. SNIFFER (attack manual sekarang!)")

local sniffLines = 0
local hookOk = false

if hookmetamethod and getnamecallmethod then
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
		local method = getnamecallmethod()
		if (method == "FireServer" or method == "InvokeServer") and sniffLines < MAX_SNIFF_LINES then
			local args = { ... }
			local ok = pcall(function()
				local parts = {}
				for i = 1, math.min(#args, 6) do
					parts[i] = describe(args[i])
				end
				sniffLines = sniffLines + 1
				log(string.format("  [%02d] %s:%s(%s)", sniffLines, self.Name, method, table.concat(parts, ", ")))
			end)
			if not ok then sniffLines = sniffLines + 1 end
		end
		return oldNamecall(self, ...)
	end)
	hookOk = true
	log("SNIFFER AKTIF selama " .. SNIFF_SECONDS .. " detik.")
	log(">>> SEKARANG ATTACK MANUAL KE MOB 3-5 KALI <<<")
else
	log("executor tidak punya hookmetamethod/getnamecallmethod.")
	log("Sniffer dilewati - kirim saja hasil bagian A-E.")
end

task.spawn(function()
	if hookOk then
		task.wait(SNIFF_SECONDS)
		log("")
		log("sniffer selesai, " .. sniffLines .. " panggilan tercatat.")
	end

	section("SELESAI")
	local text = table.concat(report, "\n")
	if setclipboard then
		pcall(setclipboard, text)
		log("Hasil sudah disalin ke clipboard. Paste ke chat.")
		print("[RECON] Hasil sudah disalin ke clipboard.")
	else
		print("[RECON] setclipboard tidak ada. Salin manual dari console (F9).")
	end
	print(text)
end)
