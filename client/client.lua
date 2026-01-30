local ESX = exports['es_extended']:getSharedObject()
local isOpen = false
local PlayerData = {}
local tabletObject = nil
local currentLocation = nil
local refreshThread = nil

-- Init
CreateThread(function()
    while ESX.GetPlayerData().job == nil do Wait(100) end
    PlayerData = ESX.GetPlayerData()
    SetupJobLocations()
end)

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    SetupJobLocations()
end)

RegisterNetEvent('esx:setJob', function(job)
    PlayerData.job = job
    SetupJobLocations()
    if isOpen then
        SendNUIMessage({ action = 'updateJob', job = GetJobData() })
        TriggerServerEvent('jobpanel:requestRefresh')
    end
end)

-- Setup job locations, markers & blips
function SetupJobLocations()
    -- Remove existing blips
    -- Create new ones based on player job
    for jobName, jobConfig in pairs(Config.Jobs) do
        if jobConfig.blip and jobConfig.blip.enabled and jobConfig.location and jobConfig.location.enabled then
            local blip = AddBlipForCoord(jobConfig.location.coords)
            SetBlipSprite(blip, jobConfig.blip.sprite)
            SetBlipColour(blip, jobConfig.blip.color)
            SetBlipScale(blip, jobConfig.blip.scale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(jobConfig.blip.label)
            EndTextCommandSetBlipName(blip)
        end
    end
end

-- Location check thread
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        for jobName, jobConfig in pairs(Config.Jobs) do
            if jobConfig.location and jobConfig.location.enabled then
                local distance = #(playerCoords - jobConfig.location.coords)
                
                if distance < 20.0 then
                    sleep = 0
                    
                    -- Draw marker
                    if jobConfig.marker and jobConfig.marker.enabled then
                        DrawMarker(
                            jobConfig.marker.type,
                            jobConfig.location.coords.x,
                            jobConfig.location.coords.y,
                            jobConfig.location.coords.z - 0.95,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            jobConfig.marker.scale.x,
                            jobConfig.marker.scale.y,
                            jobConfig.marker.scale.z,
                            jobConfig.marker.color.r,
                            jobConfig.marker.color.g,
                            jobConfig.marker.color.b,
                            jobConfig.marker.color.a,
                            jobConfig.marker.bobUpAndDown or false,
                            false, 2, nil, nil, false
                        )
                    end
                    
                    -- Check if player is in range and has job
                    if distance < jobConfig.location.radius then
                        if PlayerData.job and PlayerData.job.name == jobName then
                            -- Show help text
                            BeginTextCommandDisplayHelp("STRING")
                            AddTextComponentSubstringPlayerName(jobConfig.location.label or '[E] Boss Panel')
                            EndTextCommandDisplayHelp(0, false, true, -1)
                            
                            -- Open on E press
                            if IsControlJustPressed(0, 38) then
                                currentLocation = jobName
                                OpenPanel()
                            end
                        end
                    end
                end
            end
        end
        
        Wait(sleep)
    end
end)

-- Item usage
if Config.TabletItem then
    RegisterNetEvent('jobpanel:useTablet', function()
        if PlayerData.job and Config.Jobs[PlayerData.job.name] then
            currentLocation = nil
            OpenPanel()
        else
            Notify('Du har inte tillgång till denna enhet', 'error')
        end
    end)
end

-- Command
if Config.Command then
    RegisterCommand(Config.Command, function()
        if PlayerData.job and Config.Jobs[PlayerData.job.name] then
            currentLocation = nil
            OpenPanel()
        else
            Notify('Du har inte tillgång till denna panel', 'error')
        end
    end, false)
end

-- Open Panel
function OpenPanel()
    local job = PlayerData.job
    
    if not job or not Config.Jobs[job.name] then
        Notify('Du har inte tillgång', 'error')
        return
    end
    
    local jobConfig = Config.Jobs[job.name]
    local gradeConfig = jobConfig.grades[job.grade]
    
    if not gradeConfig then
        Notify('Ogiltig rank', 'error')
        return
    end
    
    -- Check panel_access permission
    if not HasPermission('panel_access', gradeConfig.permissions) then
        Notify('Du har inte behörighet', 'error')
        return
    end
    
    if Config.Animation.enabled then
        StartTabletAnimation()
    end
    
    isOpen = true
    Wait(500)
    
    SetNuiFocus(true, true)
    
    -- Request all data
    ESX.TriggerServerCallback('jobpanel:getAllData', function(data)
        if not data then
            Notify('Kunde inte hämta data', 'error')
            ClosePanel()
            return
        end
        
        SendNUIMessage({
            action = 'open',
            job = GetJobData(),
            permissions = gradeConfig.permissions,
            employees = data.employees,
            grades = data.grades,
            societyMoney = data.societyMoney,
            playerMoney = data.playerMoney,
            salaryHistory = data.salaryHistory,
            transactions = data.transactions,
            statistics = data.statistics,
            auditLog = data.auditLog,
            settings = Config.SalarySettings,
            jobConfig = {
                logo = jobConfig.logo,
                color = jobConfig.color,
                licenses = jobConfig.licenses,
                equipment = jobConfig.equipment
            }
        })
        
        -- Start refresh thread
        StartRefreshThread()
    end, job.name)
end

function GetJobData()
    local job = PlayerData.job
    local jobConfig = Config.Jobs[job.name]
    return {
        name = job.name,
        label = jobConfig.label,
        grade = job.grade,
        grade_label = job.grade_label,
        logo = jobConfig.logo,
        color = jobConfig.color
    }
end

function HasPermission(perm, permissions)
    for _, p in ipairs(permissions or {}) do
        if p == perm then return true end
    end
    return false
end

-- Refresh thread for live updates
function StartRefreshThread()
    if refreshThread then return end
    
    refreshThread = CreateThread(function()
        while isOpen do
            Wait(Config.RefreshInterval)
            if isOpen then
                TriggerServerEvent('jobpanel:requestRefresh')
            end
        end
        refreshThread = nil
    end)
end

-- Server refresh event
RegisterNetEvent('jobpanel:refreshData', function(data)
    if isOpen and data then
        SendNUIMessage({
            action = 'refresh',
            employees = data.employees,
            grades = data.grades,
            societyMoney = data.societyMoney,
            playerMoney = data.playerMoney,
            salaryHistory = data.salaryHistory,
            transactions = data.transactions,
            statistics = data.statistics,
            auditLog = data.auditLog
        })
    end
end)

function ClosePanel()
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    
    if Config.Animation.enabled then
        StopTabletAnimation()
    end
end

-- Animation functions
function StartTabletAnimation()
    local ped = PlayerPedId()
    local dict = Config.Animation.dict
    
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do Wait(10) end
    
    local propModel = GetHashKey(Config.Animation.prop)
    RequestModel(propModel)
    while not HasModelLoaded(propModel) do Wait(10) end
    
    TaskPlayAnim(ped, dict, Config.Animation.anim, 8.0, 8.0, -1, 49, 0, false, false, false)
    
    local coords = GetEntityCoords(ped)
    tabletObject = CreateObject(propModel, coords.x, coords.y, coords.z, true, true, true)
    
    local boneIndex = GetPedBoneIndex(ped, Config.Animation.bone)
    AttachEntityToEntity(
        tabletObject, ped, boneIndex,
        Config.Animation.offset.x, Config.Animation.offset.y, Config.Animation.offset.z,
        Config.Animation.rotation.x, Config.Animation.rotation.y, Config.Animation.rotation.z,
        true, true, false, true, 1, true
    )
    
    SetModelAsNoLongerNeeded(propModel)
end

function StopTabletAnimation()
    local ped = PlayerPedId()
    StopAnimTask(ped, Config.Animation.dict, Config.Animation.anim, 1.0)
    ClearPedTasks(ped)
    
    if tabletObject and DoesEntityExist(tabletObject) then
        DeleteEntity(tabletObject)
        tabletObject = nil
    end
end

-- NUI Callbacks
RegisterNUICallback('close', function(_, cb)
    ClosePanel()
    cb('ok')
end)

RegisterNUICallback('paySalary', function(data, cb)
    TriggerServerEvent('jobpanel:paySalary', data.identifier, tonumber(data.amount), data.note or '')
    cb('ok')
end)

RegisterNUICallback('payBonus', function(data, cb)
    TriggerServerEvent('jobpanel:payBonus', data.identifier, tonumber(data.amount), data.note or '')
    cb('ok')
end)

RegisterNUICallback('payAllSalaries', function(data, cb)
    TriggerServerEvent('jobpanel:payAllSalaries', data.note or '')
    cb('ok')
end)

RegisterNUICallback('hireEmployee', function(data, cb)
    TriggerServerEvent('jobpanel:hireEmployee', tonumber(data.playerId), tonumber(data.grade))
    cb('ok')
end)

RegisterNUICallback('fireEmployee', function(data, cb)
    TriggerServerEvent('jobpanel:fireEmployee', data.identifier)
    cb('ok')
end)

RegisterNUICallback('setGrade', function(data, cb)
    TriggerServerEvent('jobpanel:setGrade', data.identifier, tonumber(data.grade))
    cb('ok')
end)

RegisterNUICallback('updateSalary', function(data, cb)
    TriggerServerEvent('jobpanel:updateSalary', tonumber(data.grade), tonumber(data.salary), tonumber(data.bonus))
    cb('ok')
end)

RegisterNUICallback('depositMoney', function(data, cb)
    TriggerServerEvent('jobpanel:depositMoney', tonumber(data.amount), data.moneyType, data.note or '')
    cb('ok')
end)

RegisterNUICallback('withdrawMoney', function(data, cb)
    TriggerServerEvent('jobpanel:withdrawMoney', tonumber(data.amount), data.moneyType, data.note or '')
    cb('ok')
end)

RegisterNUICallback('addNote', function(data, cb)
    TriggerServerEvent('jobpanel:addNote', data.identifier, data.note)
    cb('ok')
end)

RegisterNUICallback('removeNote', function(data, cb)
    TriggerServerEvent('jobpanel:removeNote', data.noteId)
    cb('ok')
end)

RegisterNUICallback('orderEquipment', function(data, cb)
    TriggerServerEvent('jobpanel:orderEquipment', data.item, tonumber(data.quantity))
    cb('ok')
end)

RegisterNUICallback('getNearbyPlayers', function(_, cb)
    ESX.TriggerServerCallback('jobpanel:getNearbyPlayers', function(players)
        cb(players)
    end)
end)

RegisterNUICallback('requestRefresh', function(_, cb)
    TriggerServerEvent('jobpanel:requestRefresh')
    cb('ok')
end)

-- Notify
RegisterNetEvent('jobpanel:notify', function(msg, type)
    Notify(msg, type)
end)

function Notify(msg, type)
    if GetResourceState('ox_lib') == 'started' then
        exports['ox_lib']:notify({ title = 'Boss Panel', description = msg, type = type or 'info' })
    else
        ESX.ShowNotification(msg)
    end
end

-- Controls
CreateThread(function()
    while true do
        Wait(0)
        if isOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 106, true)
            
            if IsControlJustPressed(0, 322) or IsControlJustPressed(0, 177) then
                ClosePanel()
            end
        end
    end
end)

print('[^2BossPanel^7] Client loaded!')