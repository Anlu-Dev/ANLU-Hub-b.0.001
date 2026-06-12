-- =============================================================================
-- ANLU Hub(Rivals) - VOLT STABLE (ORIGINAL 100%)
-- FIXED: Task.spawn typo and execution timeout
-- =============================================================================

task.spawn(function()
    -- [ 🌟 ORIGINAL SCRIPT LOAD ]
    -- Volt에서 game:HttpGet이 너무 빨리 실행되어 실패하는 경우를 대비해 약간의 대기 시간을 줍니다.
    if not game:IsLoaded() then game.Loaded:Wait() end
    task.wait(0.5)

    local success, content = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/Anlu-Dev/My-Lua-Script/refs/heads/main/ANLU%20Hub.lua")
    end)

    if success and content then
        -- 원본 코드 실행
        local func, err = loadstring(content)
        if func then
            func()
            print("[ANLU] Original Script Loaded Successfully!")
        else
            warn("[ANLU] Loadstring Error: " .. tostring(err))
        end
    else
        warn("[ANLU] Failed to fetch original script from GitHub.")
    end
end)
