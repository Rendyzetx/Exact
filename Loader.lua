-- Loader.lua
-- Simple loader untuk BloxFruits.lua

-- Cek apakah file lokal ada (untuk testing)
local success, result = pcall(function()
    return readfile("BloxFruits.lua")
end)

if success then
    print("[Loader] Loading from local file...")
    loadstring(result)()
else
    print("[Loader] Local file not found")
    print("[Loader] Please paste the full script directly into your executor")
    
    -- Alternatif: Load dari URL (ganti dengan URL script Anda)
    -- loadstring(game:HttpGet("https://raw.githubusercontent.com/USERNAME/REPO/main/BloxFruits.lua"))()
end
