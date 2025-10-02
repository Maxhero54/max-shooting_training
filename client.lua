local QBCore = exports['qb-core']:GetCoreObject()
local TrainingActive = false
local TargetNPC = nil
local TrainingPed = nil -- Eğitmen NPC
local CurrentScore = 0
local UIActive = false
local AutoHideTimer = nil
local TrainingTimer = nil
local TrainingDuration = 120
local NpcCoords = vector4(-1413.23, -3100.49, 13.94, 289.25) ---- Hedef
local TrainerCoords = vector4(-1363.31, -3109.63, 12.94, 159.32) -- Eğitmen NPC konumu başlatmak için 

-- WHITELIST SILAH LİSTESİ (Sadece bu silahlarla talim yapılabilir)
local WhitelistedWeapons = {
    `weapon_pistol`,           -- Walther P99
    `weapon_combatpistol`,     -- Combat Pistol
    `weapon_pistol50`,         -- Pistol .50
    `weapon_snspistol`,        -- SNS Pistol
  --  `weapon_heavypistol`,      -- Heavy Pistol
 --   `weapon_vintagepistol`,    -- Vintage Pistol
  --  `weapon_marksmanpistol`,   -- Marksman Pistol
   -- `weapon_revolver`,         -- Heavy Revolver
  --  `weapon_doubleaction`,     -- Double Action Revolver
  --  `weapon_appistol`,         -- AP Pistol
  --  `weapon_stungun`,          -- Stun Gun
  --  `weapon_flaregun`,         -- Flare Gun
  --  `weapon_navyrevolver`,     -- Navy Revolver
  --  `weapon_ceramicpistol`,    -- Ceramic Pistol
  --  `weapon_microsmg`,         -- Micro SMG
   -- `weapon_smg`,              -- SMG
 --   `weapon_assaultsmg`,       -- Assault SMG
  --  `weapon_combatpdw`,        -- Combat PDW
  --  `weapon_machinepistol`,    -- Machine Pistol
  --  `weapon_minismg`,          -- Mini SMG
  --  `weapon_raypistol`,        -- Up-n-Atomizer
}

print("^2[SHOOTING TRAINING]^7 Client script başlatıldı")

-- Silah kontrol fonksiyonu
function IsWeaponWhitelisted()
    local playerPed = PlayerPedId()
    local currentWeapon = GetSelectedPedWeapon(playerPed)
    
    for _, weaponHash in ipairs(WhitelistedWeapons) do
        if currentWeapon == weaponHash then
            return true
        end
    end
    
    return false
end

-- Whiltelist silah listesini gösteren fonksiyon
function GetWhitelistedWeaponNames()
    local weaponNames = {
        "Walther P99",
        "Combat Pistol", 
        "Pistol .50",
        "SNS Pistol"
    --    "Heavy Pistol",
    --    "Vintage Pistol",
     --   "Marksman Pistol",
     --   "Heavy Revolver",
     --   "Double Action Revolver",
     --   "AP Pistol",
      --  "Stun Gun",
      --  "Flare Gun",
      --  "Navy Revolver",
      --  "Ceramic Pistol",
     --   "Micro SMG",
    --    "SMG",
     --   "Assault SMG",
    --    "Combat PDW",
     --   "Machine Pistol",
     --   "Mini SMG",
     --   "Up-n-Atomizer"
    }
    return weaponNames
end

-- Eğitmen NPC oluşturma
function CreateTrainerNPC()
    local model = `s_m_y_ammucity_01` -- Silah dükkanı NPC modeli
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    TrainingPed = CreatePed(1, model, TrainerCoords.x, TrainerCoords.y, TrainerCoords.z, TrainerCoords.w, false, true)
    SetEntityInvincible(TrainingPed, true)
    SetBlockingOfNonTemporaryEvents(TrainingPed, true)
    FreezeEntityPosition(TrainingPed, true)
    SetEntityHealth(TrainingPed, 100)
    
    -- qb-target entegrasyonu
    exports['qb-target']:AddTargetEntity(TrainingPed, {
        options = {
            {
                type = "client",
                event = "shootingtraining:startTraining",
                icon = "fas fa-bullseye",
                label = "Atış Talimine Başla",
                canInteract = function()
                    return not TrainingActive
                end
            },
            {
                type = "client",
                event = "shootingtraining:showScores",
                icon = "fas fa-trophy",
                label = "Skorları Görüntüle",
                canInteract = function()
                    return not TrainingActive
                end
            },
            {
                type = "client", 
                event = "shootingtraining:showAllowedWeapons",
                icon = "fas fa-gun",
                label = "İzin Verilen Silahlar",
                canInteract = function()
                    return not TrainingActive
                end
            }
        },
        distance = 2.5
    })
    
    print("^2[SHOOTING TRAINING]^7 Eğitmen NPC oluşturuldu ve target eklendi")
    return TrainingPed
end

-- Eğitmen NPC temizleme
function CleanupTrainerNPC()
    if TrainingPed and DoesEntityExist(TrainingPed) then
        exports['qb-target']:RemoveTargetEntity(TrainingPed)
        DeleteEntity(TrainingPed)
        TrainingPed = nil
        print("^2[SHOOTING TRAINING]^7 Eğitmen NPC temizlendi")
    end
end

-- UI Fonksiyonları
function ShowTrainingUI()
    SendNUIMessage({
        action = "showScoreboard",
        score = CurrentScore
    })
    UIActive = true
    print("^2[SHOOTING TRAINING]^7 UI gösterildi")
    
    if AutoHideTimer then
        ClearTimeout(AutoHideTimer)
    end
    
    AutoHideTimer = SetTimeout(5000, function()
        if UIActive then
            print("^2[SHOOTING TRAINING]^7 UI otomatik kapatılıyor")
            CloseUI()
        end
    end)
end

function UpdateScoreboard(topScores)
    SendNUIMessage({
        action = "updateTopScores", 
        scores = topScores
    })
end

function CloseUI()
    SendNUIMessage({action = "hideScoreboard"})
    SetNuiFocus(false, false)
    UIActive = false
    
    if AutoHideTimer then
        ClearTimeout(AutoHideTimer)
        AutoHideTimer = nil
    end
    
    print("^2[SHOOTING TRAINING]^7 UI kapatıldı")
end

-- Hedef NPC oluşturma
function CreateTrainingNPC()
    local model = `s_m_m_autoshop_02`
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(1)
    end
    
    TargetNPC = CreatePed(1, model, NpcCoords.x, NpcCoords.y, NpcCoords.z, NpcCoords.w, false, true)
    SetEntityInvincible(TargetNPC, true)
    SetBlockingOfNonTemporaryEvents(TargetNPC, true)
    SetEntityHealth(TargetNPC, 100)
    SetEntityCollision(TargetNPC, true, true)
    
    print("^2[SHOOTING TRAINING]^7 Hareketli NPC oluşturuldu")
    return TargetNPC
end

-- Hedef NPC temizleme
function CleanupTrainingNPC()
    if DoesEntityExist(TargetNPC) then
        DeleteEntity(TargetNPC)
        TargetNPC = nil
        print("^2[SHOOTING TRAINING]^7 Hedef NPC temizlendi")
    end
end

-- NPC hareketleri
function StartNPCMovements()
    Citizen.CreateThread(function()
        while TrainingActive and TargetNPC do
            -- %60 ihtimalle hareket et
            if math.random(1, 100) <= 60 then
                local currentCoords = GetEntityCoords(TargetNPC)
                
                -- 5m çapında rastgele hareket
                local angle = math.random() * math.pi * 2
                local distance = math.random() * 5.0
                local newX = NpcCoords.x + math.cos(angle) * distance
                local newY = NpcCoords.y + math.sin(angle) * distance
                
                -- Daha hızlı hareket (2.5 speed)
                TaskGoStraightToCoord(TargetNPC, newX, newY, NpcCoords.z, 2.5, 2000, GetEntityHeading(TargetNPC), 0.1)
                
                -- Hafif yön değişimi
                local currentHeading = GetEntityHeading(TargetNPC)
                local newHeading = currentHeading + (math.random() - 0.5) * 60
                SetEntityHeading(TargetNPC, newHeading)
                
                -- Basit animasyon
                if math.random(1, 100) <= 40 then
                    local anims = {
                        {dict = "move_action", anim = "lean_left"},
                        {dict = "move_action", anim = "lean_right"},
                        {dict = "move_strafe", anim = "sidestep_left"}, 
                        {dict = "move_strafe", anim = "sidestep_right"},
                        
                        -- Çömelme / Çökme
                        {dict = "amb@medic@standing@kneel@idle_a", anim = "idle_a"},   -- diz çökme
                        {dict = "amb@world_human_picnic@male@idle_a", anim = "idle_a"}, -- yere otur/çömelme
                        {dict = "amb@world_human_hang_out_street@female_hold_arm@idle_a", anim = "idle_a"}, -- hafif eğilme
                    }
                    
                    local randomAnim = anims[math.random(1, #anims)]
                    
                    RequestAnimDict(randomAnim.dict)
                    local timeout = 0
                    while not HasAnimDictLoaded(randomAnim.dict) and timeout < 50 do
                        Wait(10)
                        timeout = timeout + 1
                    end
                    
                    if HasAnimDictLoaded(randomAnim.dict) then
                        -- NPC animasyonu biraz uzun oynasın
                        TaskPlayAnim(TargetNPC, randomAnim.dict, randomAnim.anim, 4.0, -4.0, 3000, 1, 0, false, false, false)
                        RemoveAnimDict(randomAnim.dict)
                    end
                end
                
                print("^2[SHOOTING TRAINING]^7 NPC hareket etti")
            end
            
            -- 0.5 - 2 saniye bekle (hızlandırma için azaltıldı)
            Wait(math.random(500, 2000))
        end
    end)
end

-- Raycast fonksiyonu
function PerformPreciseRaycast(targetNPC)
    local playerPed = PlayerPedId()
    local camCoords = GetGameplayCamCoord()
    local camRotation = GetGameplayCamRot(0)
    local direction = RotationToDirection(camRotation)
    
    local rayEnd = camCoords + (direction * 50.0)
    
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(
        camCoords.x, camCoords.y, camCoords.z,
        rayEnd.x, rayEnd.y, rayEnd.z,
        -1, playerPed, 0
    )
    
    local hit, hitCoords, _, _, entityHit = GetShapeTestResult(rayHandle)
    
    local entityValid = false
    if hit and entityHit ~= 0 then
        if GetEntityType(entityHit) == 1 then
            if entityHit == targetNPC then
                entityValid = true
            end
        end
    end
    
    return hit, hitCoords, entityValid and entityHit or nil
end

-- Bone tespit fonksiyonu
function GetHitBone(entity, hitCoords)
    if not DoesEntityExist(entity) then
        return "UNKNOWN"
    end

    local closestBone = "UNKNOWN"
    local closestDistance = 0.3   ---  yakonındaki gövde parçası 
    
    local boneList = {
        {name = "SKEL_HEAD", bone = 31086, label = "Kafa"},
        {name = "SKEL_NECK", bone = 39317, label = "Boyun"},
        {name = "SKEL_SPINE3", bone = 24818, label = "Üst Gövde"},
        {name = "SKEL_SPINE2", bone = 24817, label = "Orta Gövde"},
        {name = "SKEL_SPINE1", bone = 24816, label = "Alt Gövde"},
        {name = "SKEL_SPINE0", bone = 0, label = "Pelvis"},
        {name = "SKEL_L_UPPERARM", bone = 45509, label = "Sol Kol"},
        {name = "SKEL_R_UPPERARM", bone = 40269, label = "Sağ Kol"},
        {name = "SKEL_L_THIGH", bone = 58271, label = "Sol Bacak"},
        {name = "SKEL_R_THIGH", bone = 51826, label = "Sağ Bacak"},
    }
    
    for _, boneData in ipairs(boneList) do
        local boneIndex = boneData.bone
        local boneCoords
        
        if boneIndex == 0 then
            boneCoords = GetEntityCoords(entity)
        else
            boneCoords = GetWorldPositionOfEntityBone(entity, boneIndex)
        end
        
        if boneCoords and boneCoords.x ~= 0 and boneCoords.y ~= 0 and boneCoords.z ~= 0 then
            local distance = #(hitCoords - boneCoords)
            if distance < closestDistance then
                closestDistance = distance
                closestBone = boneData.name
            end
        end
    end
    
    return closestBone
end

-- Puanlama fonksiyonu
function CalculateBodyPoints(hitBone, distance)
    local basePoints = 0
    local bodyPart = ""
    local multiplier = 1.0
    
    if distance >= 40.0 then
        multiplier = 2.5
    elseif distance >= 30.0 then
        multiplier = 1.8
    elseif distance >= 20.0 then
        multiplier = 1.1
    else
        multiplier = 1.0
    end
    
    if hitBone == "SKEL_HEAD" then
        basePoints = 100
        bodyPart = "Kafa"
    elseif hitBone == "SKEL_NECK" then
        basePoints = 80
        bodyPart = "Boyun"
    elseif hitBone == "SKEL_SPINE3" then
        basePoints = 70
        bodyPart = "Üst Gövde"
    elseif hitBone == "SKEL_SPINE2" then
        basePoints = 60
        bodyPart = "Orta Gövde"
    elseif hitBone == "SKEL_SPINE1" then
        basePoints = 50
        bodyPart = "Alt Gövde"
    elseif hitBone == "SKEL_SPINE0" then
        basePoints = 40
        bodyPart = "Pelvis"
    elseif hitBone == "SKEL_L_UPPERARM" or hitBone == "SKEL_R_UPPERARM" then
        basePoints = 30
        bodyPart = "Kol"
    elseif hitBone == "SKEL_L_THIGH" or hitBone == "SKEL_R_THIGH" then
        basePoints = 20
        bodyPart = "Bacak"
    else
        basePoints = 10
        bodyPart = "Diğer"
    end
    
    local finalPoints = math.floor(basePoints * multiplier)
    return finalPoints, bodyPart
end

-- Skor kaydetme
function SaveScore()
    if CurrentScore > 0 then
        print("^2[SHOOTING TRAINING]^7 Skor kaydediliyor: " .. CurrentScore)
        TriggerServerEvent('shootingtraining:addScore', CurrentScore)
        QBCore.Functions.Notify("🏆 Skorunuz kaydedildi: " .. CurrentScore .. " puan!", "success", 4000)
        CurrentScore = 0
    else
        print("^2[SHOOTING TRAINING]^7 Kaydedilecek skor yok")
        QBCore.Functions.Notify("🎯 Talim bitti! Skorunuz yok.", "primary", 3000)
    end
end

-- Talim süresi sayacı
function StartTrainingTimer()
    local timeLeft = TrainingDuration
    
    if TrainingTimer then
        TerminateThread(TrainingTimer) -- önceki thread varsa kapat
    end

    TrainingTimer = Citizen.CreateThread(function()
        local lastSecond = GetGameTimer()

        while timeLeft > 0 and TrainingActive do
            if TargetNPC then
                local npcCoords = GetEntityCoords(TargetNPC)
                local playerCoords = GetEntityCoords(PlayerPedId())
                local dist = #(playerCoords - npcCoords)

                -- Yazının yüksekliğini mesafeye göre ayarla
                local textZ = npcCoords.z + 1.8 + (dist * 0.12)

                local minutes = math.floor(timeLeft / 60)
                local seconds = timeLeft % 60
                DrawText3D(npcCoords.x, npcCoords.y, textZ,
                    "~g~HEDEF~n~~w~Kalan Süre: ~y~" ..
                    minutes .. ":" .. string.format("%02d", seconds) ..
                    "")  --- ~n~~r~20m'den UZAKTA ol!~n~~c~Uzaklık = +Puan~n~~b~ESC ile kapat
            end

            -- saniye kontrolü (her 1000 ms'de bir düşür)
            if GetGameTimer() - lastSecond >= 1000 then
                timeLeft = timeLeft - 1
                lastSecond = GetGameTimer()

                -- Uyarılar
                if timeLeft == 10 then
                    QBCore.Functions.Notify("⏰ Son 10 saniye!", "error", 3000)
                elseif timeLeft <= 5 and timeLeft > 0 then
                    QBCore.Functions.Notify("⏰ " .. timeLeft .. " saniye!", "error", 1000)
                end
            end

            Citizen.Wait(0) -- her frame çizdir
        end

        if TrainingActive then
            print("^2[SHOOTING TRAINING]^7 Talim süresi doldu")
            TriggerEvent('shootingtraining:setTrainingState', false)
        end
    end)
end

-- Talim başlatma
function StartSimpleTraining()
    local npc = CreateTrainingNPC()
    if not npc then 
        QBCore.Functions.Notify("❌ NPC oluşturulamadı!", "error", 3000)
        return 
    end
    
    print("^2[SHOOTING TRAINING]^7 Talim başlatıldı, HAREKETLİ NPC hazır. Süre: " .. TrainingDuration .. " saniye")
    
    StartNPCMovements()
    StartTrainingTimer()
    
    QBCore.Functions.TriggerCallback('shootingtraining:getTopScores', function(scores)
        if scores then
            UpdateScoreboard(scores)
            print("^2[SHOOTING TRAINING]^7 Skorlar güncellendi: " .. #scores .. " kayıt")
        else
            print("^1[SHOOTING TRAINING]^7 Skorlar getirilemedi!")
        end
        ShowTrainingUI()
    end)
    
    Citizen.CreateThread(function()
        local lastShotTime = 0
        
        while TrainingActive and TargetNPC and DoesEntityExist(TargetNPC) do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local npcCoords = GetEntityCoords(TargetNPC)
            local distance = #(playerCoords - npcCoords)
            
            if not DoesEntityExist(TargetNPC) then
                print("^1[SHOOTING TRAINING]^7 NPC kayboldu!")
                break
            end
            
            -- Silah kontrolü - sadece whitelist silahlarla ateş edilebilir
            if not IsWeaponWhitelisted() then
                if IsPedShooting(playerPed) then
                    QBCore.Functions.Notify("❌ İzin verilmeyen silah! Sadece tabancalar kullanılabilir.", "error", 3000)
                    Wait(1000)
                end
                Wait(100)
                goto continue
            end
            
            if distance > 20.0 then ---- minimum mesafe
                if IsPedShooting(playerPed) then
                    local currentTime = GetGameTimer()
                    
                    if currentTime - lastShotTime < 500 then
                        Wait(100)
                        goto continue
                    end
                    
                    lastShotTime = currentTime
                    
                    local isAimingAtNPC = IsPlayerFreeAimingAtEntity(PlayerId(), TargetNPC)
                    
                    if isAimingAtNPC then
                        local hit, hitCoords, entityHit = PerformPreciseRaycast(TargetNPC)
                        
                        if hit and entityHit and entityHit == TargetNPC then
                            local hitBone = GetHitBone(TargetNPC, hitCoords)
                            local points, bodyPart = CalculateBodyPoints(hitBone, distance)
                            CurrentScore = CurrentScore + points
                            
                            ShowTrainingUI()
                            
                            PlaySoundFrontend(-1, "BASE_JUMP_PASSED", "HUD_AWARDS", true)
                            
                            local distanceMsg = math.floor(distance) .. "m"
                            QBCore.Functions.Notify("🎯 " .. points .. " puan! (" .. bodyPart .. " - " .. distanceMsg .. ") Toplam: " .. CurrentScore, "success", 3000)
                            print("^2[SHOOTING TRAINING]^7 Puan eklendi: " .. points .. " - Bölge: " .. bodyPart .. " - Bone: " .. hitBone .. " - Mesafe: " .. math.floor(distance) .. "m - Toplam: " .. CurrentScore)
                            
                        else
                            QBCore.Functions.Notify("❌ Iska! NPC'yi vuramadın!", "error", 1000)
                        end
                    else
                        QBCore.Functions.Notify("❌ Iska! NPC'ye nişan al!", "error", 1000)
                    end
                    
                    Wait(300)
                end
            else
                if IsPedShooting(playerPed) then
                    QBCore.Functions.Notify("📏 Çok yakınsın! Uzaklaş! (" .. math.floor(distance) .. "m)", "error", 1000)
                    Wait(500)
                end
            end
            
            ::continue::
            Wait(0)
        end
    end)
end

function RotationToDirection(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    
    return vector3(
        -math.sin(z) * num,
        math.cos(z) * num,
        math.sin(x)
    )
end

-- YENİ EVENT'LER: qb-target için
RegisterNetEvent('shootingtraining:startTraining', function()
    if TrainingActive then
        QBCore.Functions.Notify("❌ Zaten bir talim devam ediyor!", "error", 3000)
        return
    end
    
    -- Silah kontrolü - talim başlamadan önce
    if not IsWeaponWhitelisted() then
        local weaponNames = table.concat(GetWhitelistedWeaponNames(), ", ")
        QBCore.Functions.Notify("❌ İzin verilen silah elinde olmalı: " .. weaponNames, "error", 6000)
        return
    end
    
    -- Eğitmen NPC konuşma animasyonu
    if TrainingPed and DoesEntityExist(TrainingPed) then
        TaskStartScenarioInPlace(TrainingPed, "WORLD_HUMAN_COP_IDLES", 0, true)
        QBCore.Functions.Notify("🎯 Eğitmen: Talim başlıyor! 20 metreden uzakta dur ve hedefi vur!", "primary", 5000)
        Citizen.Wait(5000)
        ClearPedTasks(TrainingPed)
    end
    
    TriggerEvent('shootingtraining:setTrainingState', true)
end)

RegisterNetEvent('shootingtraining:showScores', function()
    QBCore.Functions.TriggerCallback('shootingtraining:getTopScores', function(scores)
        if scores then
            UpdateScoreboard(scores)
            ShowTrainingUI()
            QBCore.Functions.Notify("🏆 Liderlik tablosu açıldı", "success")
        else
            QBCore.Functions.Notify("❌ Skorlar yüklenemedi!", "error")
        end
    end)
end)

-- YENİ EVENT: İzin verilen silahları göster
RegisterNetEvent('shootingtraining:showAllowedWeapons', function()
    local weaponNames = GetWhitelistedWeaponNames()
    local message = "🎯 İzin Verilen Silahlar:\n"
    
    for i, weaponName in ipairs(weaponNames) do
        message = message .. "• " .. weaponName .. "\n"
    end
    
    QBCore.Functions.Notify(message, "primary", 8000)
end)

-- Ana Event Handler
RegisterNetEvent('shootingtraining:setTrainingState')
AddEventHandler('shootingtraining:setTrainingState', function(state)
    print("^2[SHOOTING TRAINING]^7 Talim durumu: " .. tostring(state))
    
    TrainingActive = state
    
    if TrainingActive then
        CurrentScore = 0
        StartSimpleTraining()
        QBCore.Functions.Notify("🎯 Talim başladı! HAREKETLİ HEDEF! " .. math.floor(TrainingDuration/60) .. " dakika süreniz var!", "success", 5000)
    else
        SaveScore()
        CleanupTrainingNPC()
        CloseUI()
        
        if TrainingTimer then
            Citizen.Wait(100)
            TrainingTimer = nil
        end
    end
end)

-- Script başlangıcında eğitmen NPC oluştur
Citizen.CreateThread(function()
    Wait(1000)
    CreateTrainerNPC()
    print("^2[SHOOTING TRAINING]^7 Eğitmen NPC başarıyla oluşturuldu")
end)

-- Resource stop时 temizlik
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupTrainingNPC()
        CleanupTrainerNPC()
        CloseUI()
        print("^2[SHOOTING TRAINING]^7 Resource stop - Temizlik yapıldı")
    end
end)

-- NUI callback
RegisterNUICallback('closeUI', function(data, cb)
    CloseUI()
    cb('ok')
end)

-- TUŞ KONTROLLERİ
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        
        if UIActive then
            if IsControlJustPressed(0, 322) then -- ESC
                CloseUI()
            end
            
            if IsControlJustPressed(0, 177) then -- BACKSPACE
                CloseUI()
            end
        end
    end
end)

-- Komutlar (mevcut)
RegisterCommand('stoptraining', function()
    TriggerEvent('shootingtraining:setTrainingState', false)
end, false)

RegisterCommand('testtraining', function()
    -- Komutla başlatırken de silah kontrolü
    if not IsWeaponWhitelisted() then
        QBCore.Functions.Notify("❌ İzin verilmeyen silah! Sadece tabanca ve SMG'ler kullanılabilir.", "error", 4000)
        return
    end
    TriggerEvent('shootingtraining:setTrainingState', true)
end, false)

RegisterCommand('closeui', function()
    CloseUI()
    QBCore.Functions.Notify("UI kapatıldı", "success")
end, false)

RegisterCommand('showscoreboard', function()
    QBCore.Functions.TriggerCallback('shootingtraining:getTopScores', function(scores)
        if scores then
            UpdateScoreboard(scores)
            ShowTrainingUI()
            QBCore.Functions.Notify("Liderlik tablosu açıldı", "success")
        else
            QBCore.Functions.Notify("Skorlar yüklenemedi!", "error")
        end
    end)
end, false)

RegisterCommand('allowedweapons', function()
    TriggerEvent('shootingtraining:showAllowedWeapons')
end, false)

RegisterCommand('settraintime', function(source, args)
    local time = tonumber(args[1])
    if time and time > 0 then
        TrainingDuration = time
        QBCore.Functions.Notify("Talim süresi " .. time .. " saniye olarak ayarlandı", "success")
    else
        QBCore.Functions.Notify("Kullanım: /settraintime [saniye]", "error")
    end
end, false)

-- 3D Text
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
    end
end