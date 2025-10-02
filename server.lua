local QBCore = exports['qb-core']:GetCoreObject()

print("^2[SHOOTING TRAINING]^7 Server script başlatıldı")

-- SQL tablosunu oluştur
CreateThread(function()
    Wait(10000) -- Uzun bekleme
    
    -- QBCore'un MySQL fonksiyonunu kullan
    if QBCore and QBCore.Functions then
        local result = exports.oxmysql:executeSync([[
            CREATE TABLE IF NOT EXISTS `shooting_training` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `citizenid` varchar(50) NOT NULL,
                `name` varchar(100) NOT NULL,
                `score` int(11) NOT NULL DEFAULT 0,
                `date` timestamp NOT NULL DEFAULT current_timestamp(),
                PRIMARY KEY (`id`)
            )
        ]], {})
        print("^2[SHOOTING TRAINING]^7 SQL tablosu hazır")
    else
        print("^1[SHOOTING TRAINING]^7 QBCore bulunamadı!")
    end
end)

-- Skor kaydetme (QBCore MySQL)
RegisterServerEvent('shootingtraining:addScore')
AddEventHandler('shootingtraining:addScore', function(score)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        print("^1[SHOOTING TRAINING]^7 Player bulunamadı!")
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    local name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    
    print("^2[SHOOTING TRAINING]^7 Skor kaydediliyor: " .. name .. " - " .. score .. " puan")
    
    -- QBCore MySQL ile ekle
    exports.oxmysql:insert('INSERT INTO shooting_training (citizenid, name, score) VALUES (?, ?, ?)', {
        citizenid, name, score
    }, function(insertId)
        if insertId then
            print("^2[SHOOTING TRAINING]^7 ✓ Skor kaydedildi! ID: " .. insertId)
            TriggerClientEvent('QBCore:Notify', src, "✓ Skorunuz kaydedildi: " .. score .. " puan!", "success")
        else
            print("^1[SHOOTING TRAINING]^7 ✗ Skor kaydedilemedi!")
            TriggerClientEvent('QBCore:Notify', src, "✗ Skor kaydedilemedi!", "error")
        end
    end)
end)

-- Top skorları getir (QBCore MySQL)
QBCore.Functions.CreateCallback('shootingtraining:getTopScores', function(source, cb)
    exports.oxmysql:fetch('SELECT name, score FROM shooting_training ORDER BY score DESC LIMIT 3', {}, function(result)
        if result then
            print("^2[SHOOTING TRAINING]^7 Top skorlar getirildi: " .. #result .. " kayıt")
            cb(result)
        else
            print("^1[SHOOTING TRAINING]^7 Skorlar getirilemedi!")
            cb({})
        end
    end)
end)

-- Admin komutları
QBCore.Commands.Add("starttraining", "Talimi başlat", {{name="durum", help="true/false"}}, true, function(source, args)
    local state = args[1]
    if state == "true" then
        TriggerClientEvent('shootingtraining:setTrainingState', -1, true)
        TriggerClientEvent('QBCore:Notify', -1, "🎯 Talim Başladı!", "success")
        print("^2[SHOOTING TRAINING]^7 Talim başlatıldı")
    else
        TriggerClientEvent('shootingtraining:setTrainingState', -1, false)
        TriggerClientEvent('QBCore:Notify', -1, "🎯 Talim Bitti!", "error")
        print("^2[SHOOTING TRAINING]^7 Talim durduruldu")
    end
end, "admin")

-- Test komutu (QBCore MySQL)
QBCore.Commands.Add("addtestscore", "Test skoru ekle", {{name="puan", help="Puan"}}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local score = tonumber(args[1]) or 100
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local name = Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
    
    exports.oxmysql:insert('INSERT INTO shooting_training (citizenid, name, score) VALUES (?, ?, ?)', {
        citizenid, name, score
    }, function(insertId)
        if insertId then
            TriggerClientEvent('QBCore:Notify', src, "✓ Test skoru eklendi: " .. score .. " puan", "success")
            print("^2[SHOOTING TRAINING]^7 Test skoru eklendi: " .. name .. " - " .. score)
        else
            TriggerClientEvent('QBCore:Notify', src, "✗ Test skoru eklenemedi!", "error")
        end
    end)
end, "admin")

-- Skorları göster
QBCore.Commands.Add("showscores", "Skorları göster", {}, false, function(source, args)
    local src = source
    
    exports.oxmysql:fetch('SELECT name, score FROM shooting_training ORDER BY score DESC LIMIT 5', {}, function(result)
        if result and #result > 0 then
            TriggerClientEvent('QBCore:Notify', src, "🏆 Top 5 Skor:", "primary", 5000)
            for i, v in ipairs(result) do
                TriggerClientEvent('QBCore:Notify', src, i .. ". " .. v.name .. " - " .. v.score .. " puan", "primary", 5000)
            end
        else
            TriggerClientEvent('QBCore:Notify', src, "Henüz skor kaydı yok!", "error")
        end
    end)
end, "admin")

-- Basit SQL test
QBCore.Commands.Add("testsql", "SQL test", {}, true, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    exports.oxmysql:insert('INSERT INTO shooting_training (citizenid, name, score) VALUES (?, ?, ?)', {
        Player.PlayerData.citizenid,
        Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname,
        999
    }, function(insertId)
        if insertId then
            TriggerClientEvent('QBCore:Notify', src, "✓ SQL Test Başarılı! ID: " .. insertId, "success")
        else
            TriggerClientEvent('QBCore:Notify', src, "✗ SQL Test Başarısız!", "error")
        end
    end)
end, "admin")

print("^2[SHOOTING TRAINING]^7 Server script yüklendi")


--------------------------------------------------
------------------ OK-------------------------v01--
------------------------------------------------------