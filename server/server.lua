local ESX = exports['es_extended']:getSharedObject()
local salaryCache = {}

-- Init
CreateThread(function()
    Wait(2000)
    LoadSalaries()
end)

function LoadSalaries()
    for jobName, jobConfig in pairs(Config.Jobs) do
        salaryCache[jobName] = {}
        
        local result = MySQL.query.await('SELECT grade, salary, bonus FROM job_grades_custom WHERE job_name = ?', { jobName })
        
        if result then
            for _, row in ipairs(result) do
                salaryCache[jobName][row.grade] = { salary = row.salary, bonus = row.bonus or 0 }
            end
        end
        
        for grade, gradeConfig in pairs(jobConfig.grades) do
            if not salaryCache[jobName][grade] then
                salaryCache[jobName][grade] = { salary = gradeConfig.defaultSalary, bonus = 0 }
                MySQL.insert('INSERT INTO job_grades_custom (job_name, grade, salary, bonus) VALUES (?, ?, ?, ?) ON DUPLICATE KEY UPDATE salary = VALUES(salary)', {
                    jobName, grade, gradeConfig.defaultSalary, 0
                })
            end
        end
    end
    print('[^2BossPanel^7] Salaries loaded!')
end

function GetSalary(jobName, grade)
    if salaryCache[jobName] and salaryCache[jobName][grade] then
        return salaryCache[jobName][grade].salary, salaryCache[jobName][grade].bonus
    end
    if Config.Jobs[jobName] and Config.Jobs[jobName].grades[grade] then
        return Config.Jobs[jobName].grades[grade].defaultSalary, 0
    end
    return 0, 0
end

function HasPermission(xPlayer, permission)
    local jobConfig = Config.Jobs[xPlayer.job.name]
    if not jobConfig then return false end
    
    local gradeConfig = jobConfig.grades[xPlayer.job.grade]
    if not gradeConfig then return false end
    
    for _, perm in ipairs(gradeConfig.permissions or {}) do
        if perm == permission then return true end
    end
    return false
end

-- Item
if Config.TabletItem then
    ESX.RegisterUsableItem(Config.TabletItem, function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer and Config.Jobs[xPlayer.job.name] then
            TriggerClientEvent('jobpanel:useTablet', source)
        else
            TriggerClientEvent('jobpanel:notify', source, 'Du har inte tillgång', 'error')
        end
    end)
end

-- ============================================
-- CALLBACKS
-- ============================================

-- Hämta spelarens pengar
ESX.RegisterServerCallback('jobpanel:getPlayerMoney', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb({ cash = 0, bank = 0 })
        return
    end
    
    cb({
        cash = xPlayer.getMoney(),
        bank = xPlayer.getAccount('bank').money
    })
end)

-- Hämta all data
ESX.RegisterServerCallback('jobpanel:getAllData', function(source, cb, jobName)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then
        cb(nil)
        return
    end
    
    if xPlayer.job.name ~= jobName then
        cb(nil)
        return
    end
    
    if not Config.Jobs[jobName] then
        cb(nil)
        return
    end
    
    local data = {
        employees = GetEmployees(jobName),
        grades = GetGrades(jobName),
        societyMoney = GetSocietyMoney(jobName),
        playerMoney = { cash = xPlayer.getMoney(), bank = xPlayer.getAccount('bank').money },
        salaryHistory = GetSalaryHistory(jobName),
        transactions = GetTransactions(jobName),
        statistics = GetStatistics(jobName),
        auditLog = GetAuditLog(jobName)
    }
    
    cb(data)
end)

-- Hämta närliggande spelare
ESX.RegisterServerCallback('jobpanel:getNearbyPlayers', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local players = {}
    
    if not xPlayer then
        cb(players)
        return
    end
    
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, player in pairs(ESX.GetExtendedPlayers()) do
        if player.source ~= source then
            local targetPed = GetPlayerPed(player.source)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if distance < 10.0 then
                table.insert(players, {
                    id = player.source,
                    name = player.getName(),
                    job = player.job.label,
                    identifier = player.identifier
                })
            end
        end
    end
    
    cb(players)
end)

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

function GetEmployees(jobName)
    local employees = {}
    local result = MySQL.query.await('SELECT identifier, firstname, lastname, job_grade FROM users WHERE job = ? ORDER BY job_grade DESC', { jobName })
    
    local onlinePlayers = ESX.GetExtendedPlayers('job', jobName)
    local onlineIds = {}
    for _, p in pairs(onlinePlayers) do
        onlineIds[p.identifier] = p.source
    end
    
    if result then
        for _, row in ipairs(result) do
            local salary, bonus = GetSalary(jobName, row.job_grade)
            local gradeInfo = Config.Jobs[jobName].grades[row.job_grade]
            
            -- Get notes
            local notes = MySQL.query.await('SELECT * FROM job_employee_notes WHERE identifier = ? AND job_name = ? ORDER BY created_at DESC LIMIT 5', { row.identifier, jobName }) or {}
            
            table.insert(employees, {
                identifier = row.identifier,
                name = row.firstname .. ' ' .. row.lastname,
                grade = row.job_grade,
                gradeLabel = gradeInfo and gradeInfo.name or 'Okänd',
                salary = salary,
                bonus = bonus,
                isOnline = onlineIds[row.identifier] ~= nil,
                source = onlineIds[row.identifier],
                notes = notes
            })
        end
    end
    
    return employees
end

function GetGrades(jobName)
    local grades = {}
    for grade, gradeConfig in pairs(Config.Jobs[jobName].grades) do
        local salary, bonus = GetSalary(jobName, grade)
        grades[tostring(grade)] = {
            name = gradeConfig.name,
            salary = salary,
            bonus = bonus,
            permissions = gradeConfig.permissions
        }
    end
    return grades
end

function GetSocietyMoney(jobName)
    local result = MySQL.query.await('SELECT money FROM addon_account_data WHERE account_name = ?', { Config.Jobs[jobName].society })
    return result and result[1] and result[1].money or 0
end

function GetSalaryHistory(jobName)
    return MySQL.query.await('SELECT * FROM job_salary_history WHERE job_name = ? ORDER BY created_at DESC LIMIT 100', { jobName }) or {}
end

function GetTransactions(jobName)
    return MySQL.query.await('SELECT * FROM job_transactions WHERE job_name = ? ORDER BY created_at DESC LIMIT 100', { jobName }) or {}
end

function GetStatistics(jobName)
    local stats = {
        totalPaid = 0,
        totalDeposited = 0,
        totalWithdrawn = 0,
        paymentsThisWeek = 0
    }
    
    local paid = MySQL.query.await('SELECT COALESCE(SUM(amount), 0) as total FROM job_salary_history WHERE job_name = ?', { jobName })
    stats.totalPaid = paid and paid[1] and paid[1].total or 0
    
    local weekly = MySQL.query.await('SELECT COUNT(*) as count FROM job_salary_history WHERE job_name = ? AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)', { jobName })
    stats.paymentsThisWeek = weekly and weekly[1] and weekly[1].count or 0
    
    local deposits = MySQL.query.await("SELECT COALESCE(SUM(amount), 0) as total FROM job_transactions WHERE job_name = ? AND type = 'deposit'", { jobName })
    stats.totalDeposited = deposits and deposits[1] and deposits[1].total or 0
    
    local withdrawals = MySQL.query.await("SELECT COALESCE(SUM(amount), 0) as total FROM job_transactions WHERE job_name = ? AND type = 'withdraw'", { jobName })
    stats.totalWithdrawn = withdrawals and withdrawals[1] and withdrawals[1].total or 0
    
    return stats
end

function GetAuditLog(jobName)
    return MySQL.query.await('SELECT * FROM job_audit_log WHERE job_name = ? ORDER BY created_at DESC LIMIT 100', { jobName }) or {}
end

function LogAudit(jobName, action, performedBy, targetId, details)
    MySQL.insert('INSERT INTO job_audit_log (job_name, action, performed_by, target_identifier, details) VALUES (?, ?, ?, ?, ?)', {
        jobName, action, performedBy, targetId or '', json.encode(details or {})
    })
end

function BroadcastRefresh(jobName)
    for _, player in pairs(ESX.GetExtendedPlayers('job', jobName)) do
        local data = {
            employees = GetEmployees(jobName),
            grades = GetGrades(jobName),
            societyMoney = GetSocietyMoney(jobName),
            playerMoney = { cash = player.getMoney(), bank = player.getAccount('bank').money },
            salaryHistory = GetSalaryHistory(jobName),
            transactions = GetTransactions(jobName),
            statistics = GetStatistics(jobName),
            auditLog = GetAuditLog(jobName)
        }
        TriggerClientEvent('jobpanel:refreshData', player.source, data)
    end
end

-- ============================================
-- EVENTS
-- ============================================

-- Refresh request
RegisterNetEvent('jobpanel:requestRefresh')
AddEventHandler('jobpanel:requestRefresh', function()
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    if not Config.Jobs[xPlayer.job.name] then return end
    
    local jobName = xPlayer.job.name
    
    local data = {
        employees = GetEmployees(jobName),
        grades = GetGrades(jobName),
        societyMoney = GetSocietyMoney(jobName),
        playerMoney = { cash = xPlayer.getMoney(), bank = xPlayer.getAccount('bank').money },
        salaryHistory = GetSalaryHistory(jobName),
        transactions = GetTransactions(jobName),
        statistics = GetStatistics(jobName),
        auditLog = GetAuditLog(jobName)
    }
    
    TriggerClientEvent('jobpanel:refreshData', source, data)
end)

-- Update Salary
RegisterNetEvent('jobpanel:updateSalary')
AddEventHandler('jobpanel:updateSalary', function(grade, newSalary, newBonus)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    if not HasPermission(xPlayer, 'manage_salary') then
        TriggerClientEvent('jobpanel:notify', source, 'Ingen behörighet', 'error')
        return
    end
    
    local jobName = xPlayer.job.name
    local jobConfig = Config.Jobs[jobName]
    
    if not jobConfig or not jobConfig.grades[grade] then
        TriggerClientEvent('jobpanel:notify', source, 'Ogiltig rank', 'error')
        return
    end
    
    MySQL.update('INSERT INTO job_grades_custom (job_name, grade, salary, bonus, updated_by) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE salary = VALUES(salary), bonus = VALUES(bonus), updated_by = VALUES(updated_by)', {
        jobName, grade, newSalary, newBonus, xPlayer.identifier
    })
    
    if not salaryCache[jobName] then salaryCache[jobName] = {} end
    salaryCache[jobName][grade] = { salary = newSalary, bonus = newBonus }
    
    LogAudit(jobName, 'UPDATE_SALARY', xPlayer.identifier, nil, { grade = grade, salary = newSalary, bonus = newBonus })
    TriggerClientEvent('jobpanel:notify', source, 'Lön uppdaterad', 'success')
    BroadcastRefresh(jobName)
end)

-- Pay Salary
RegisterNetEvent('jobpanel:paySalary')
AddEventHandler('jobpanel:paySalary', function(targetId, amount, note)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    if not HasPermission(xPlayer, 'manage_salary') then
        TriggerClientEvent('jobpanel:notify', source, 'Ingen behörighet', 'error')
        return
    end
    
    local jobName = xPlayer.job.name
    local jobConfig = Config.Jobs[jobName]
    
    if not jobConfig then return end
    
    local targetPlayer = ESX.GetPlayerFromIdentifier(targetId)
    
    if not targetPlayer then
        TriggerClientEvent('jobpanel:notify', source, 'Spelaren måste vara online', 'error')
        return
    end
    
    if targetPlayer.job.name ~= jobName then
        TriggerClientEvent('jobpanel:notify', source, 'Spelaren är inte anställd här', 'error')
        return
    end
    
    local societyMoney = GetSocietyMoney(jobName)
    if societyMoney < amount then
        TriggerClientEvent('jobpanel:notify', source, 'Inte tillräckligt i kassan ($' .. societyMoney .. ')', 'error')
        return
    end
    
    -- Ta från society
    MySQL.update('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', { amount, jobConfig.society })
    
    -- Ge till spelare
    targetPlayer.addAccountMoney('bank', amount)
    
    -- Spara historik
    MySQL.insert('INSERT INTO job_salary_history (job_name, employee_identifier, employee_name, amount, paid_by_identifier, paid_by_name, payment_type, note) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        jobName, targetId, targetPlayer.getName(), amount, xPlayer.identifier, xPlayer.getName(), 'salary', note or ''
    })
    
    -- Spara transaktion
    local newBalance = societyMoney - amount
    MySQL.insert('INSERT INTO job_transactions (job_name, type, amount, balance_after, identifier, name, note) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        jobName, 'salary_payment', amount, newBalance, xPlayer.identifier, xPlayer.getName(), 'Lön: ' .. targetPlayer.getName()
    })
    
    LogAudit(jobName, 'PAY_SALARY', xPlayer.identifier, targetId, { amount = amount })
    
    TriggerClientEvent('jobpanel:notify', source, 'Betalade $' .. amount .. ' till ' .. targetPlayer.getName(), 'success')
    TriggerClientEvent('jobpanel:notify', targetPlayer.source, 'Du fick $' .. amount .. ' i lön', 'success')
    BroadcastRefresh(jobName)
end)

-- Pay Bonus
RegisterNetEvent('jobpanel:payBonus')
AddEventHandler('jobpanel:payBonus', function(targetId, amount, note)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    if not HasPermission(xPlayer, 'manage_salary') then
        TriggerClientEvent('jobpanel:notify', source, 'Ingen behörighet', 'error')
        return
    end
    
    local jobName = xPlayer.job.name
    local jobConfig = Config.Jobs[jobName]
    
    if not jobConfig then return end
    
    local targetPlayer = ESX.GetPlayerFromIdentifier(targetId)
    
    if not targetPlayer then
        TriggerClientEvent('jobpanel:notify', source, 'Spelaren måste vara online', 'error')
        return
    end
    
    if targetPlayer.job.name ~= jobName then
        TriggerClientEvent('jobpanel:notify', source, 'Spelaren är inte anställd här', 'error')
        return
    end
    
    local societyMoney = GetSocietyMoney(jobName)
    if societyMoney < amount then
        TriggerClientEvent('jobpanel:notify', source, 'Inte tillräckligt i kassan', 'error')
        return
    end
    
    MySQL.update('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', { amount, jobConfig.society })
    targetPlayer.addAccountMoney('bank', amount)
    
    MySQL.insert('INSERT INTO job_salary_history (job_name, employee_identifier, employee_name, amount, paid_by_identifier, paid_by_name, payment_type, note) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        jobName, targetId, targetPlayer.getName(), amount, xPlayer.identifier, xPlayer.getName(), 'bonus', note or ''
    })
    
    LogAudit(jobName, 'PAY_BONUS', xPlayer.identifier, targetId, { amount = amount, note = note })
    
    TriggerClientEvent('jobpanel:notify', source, 'Betalade $' .. amount .. ' bonus', 'success')
    TriggerClientEvent('jobpanel:notify', targetPlayer.source, 'Du fick $' .. amount .. ' i bonus!', 'success')
    BroadcastRefresh(jobName)
end)

-- Pay All
RegisterNetEvent('jobpanel:payAllSalaries')
AddEventHandler('jobpanel:payAllSalaries', function(note)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    if not HasPermission(xPlayer, 'manage_salary') then
        TriggerClientEvent('jobpanel:notify', source, 'Ingen behörighet', 'error')
        return
    end
    
    local jobName = xPlayer.job.name
    local jobConfig = Config.Jobs[jobName]
    
    if not jobConfig then return end
    
    local onlineEmployees = ESX.GetExtendedPlayers('job', jobName)
    
    if #onlineEmployees == 0 then
        TriggerClientEvent('jobpanel:notify', source, 'Inga anställda online', 'error')
        return
    end
    
    local totalSalary = 0
    local payments = {}
    
    for _, emp in pairs(onlineEmployees) do
        local salary = GetSalary(jobName, emp.job.grade)
        totalSalary = totalSalary + salary
        table.insert(payments, { player = emp, salary = salary })
    end
    
    local societyMoney = GetSocietyMoney(jobName)
    if societyMoney < totalSalary then
        TriggerClientEvent('jobpanel:notify', source, 'Inte tillräckligt! Behöver: $' .. totalSalary .. ', Har: $' .. societyMoney, 'error')
        return
    end
    
    MySQL.update('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', { totalSalary, jobConfig.society })
    
    for _, payment in ipairs(payments) do
        payment.player.addAccountMoney('bank', payment.salary)
        
        MySQL.insert('INSERT INTO job_salary_history (job_name, employee_identifier, employee_name, amount, paid_by_identifier, paid_by_name, payment_type, note) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
            jobName, payment.player.identifier, payment.player.getName(), payment.salary, xPlayer.identifier, xPlayer.getName(), 'salary', note or ''
        })
        
        TriggerClientEvent('jobpanel:notify', payment.player.source, 'Du fick $' .. payment.salary .. ' i lön', 'success')
    end
    
    LogAudit(jobName, 'PAY_ALL', xPlayer.identifier, nil, { total = totalSalary, count = #payments })
    TriggerClientEvent('jobpanel:notify', source, 'Betalade $' .. totalSalary .. ' till ' .. #payments .. ' anställda', 'success')
    BroadcastRefresh(jobName)
end)

-- Hire
RegisterNetEvent('jobpanel:hireEmployee')
AddEventHandler('jobpanel:hireEmployee', function(targetId, grade)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    local targetPlayer = ESX.GetPlayerFromId(targetId)
    
    if not xPlayer then return end
    if not HasPermission(xPlayer, 'hire_fire') then
        TriggerClientEvent('jobpanel:notify', source, 'Ingen behörighet', 'error')
        return
    end
    
    if not targetPlayer then
        TriggerClientEvent('jobpanel:notify', source, 'Spelaren hittades inte', 'error')
        return
    end
    
    if grade >= xPlayer.job.grade then
        TriggerClientEvent('jobpanel:notify', source, 'Kan ej ge högre/samma rank', 'error')
        return
    end
    
    local jobName = xPlayer.job.name
    local jobConfig = Config.Jobs[jobName]
    
    if not jobConfig or not jobConfig.grades[grade] then
        TriggerClientEvent('jobpanel:notify', source, 'Ogiltig rank', 'error')
        return
    end
    
    local gradeName = jobConfig.grades[grade].name
    
    targetPlayer.setJob(jobName, grade)
    
    LogAudit(jobName, 'HIRE', xPlayer.identifier, targetPlayer.identifier, { grade = grade, gradeName = gradeName })
    
    TriggerClientEvent('jobpanel:notify', source, 'Anställde ' .. targetPlayer.getName() .. ' som ' .. gradeName, 'success')
    TriggerClientEvent('jobpanel:notify', targetId, 'Du anställdes som ' .. gradeName .. ' hos ' .. jobConfig.label, 'success')
    BroadcastRefresh(jobName)
end)

-- Fire
RegisterNetEvent('jobpanel:fireEmployee')
AddEventHandler('jobpanel:fireEmployee', function(targetId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    if not HasPermission(xPlayer, 'hire_fire') then
        TriggerClientEvent('jobpanel:notify', source, 'Ingen behörighet', 'error')
        return
    end
    
    if xPlayer.identifier == targetId then
        TriggerClientEvent('jobpanel:notify', source, 'Kan ej avskeda dig själv', 'error')
        return
    end
    
    local jobName = xPlayer.job.name
    local targetPlayer = ESX.GetPlayerFromIdentifier(targetId)
    local targetName = 'Okänd'
    
    if targetPlayer then
        if targetPlayer.job.grade >= xPlayer.job.grade then
            TriggerClientEvent('jobpanel:notify', source, 'Kan ej avskeda högre/samma rank', 'error')
            return
        end
        targetName = targetPlayer.getName()
        targetPlayer.setJob('unemployed', 0)
        TriggerClientEvent('jobpanel:notify', targetPlayer.source, 'Du har blivit avskedad', 'error')
    else
        -- Offline player
        local userData = MySQL.query.await('SELECT firstname, lastname, job_grade FROM users WHERE identifier = ?', { targetId })
        if userData and userData[1] then
            if userData[1].job_grade >= xPlayer.job.grade then
                TriggerClientEvent('jobpanel:notify', source, 'Kan ej avskeda högre/samma rank', 'error')
                return
            end
            targetName = userData[1].firstname .. ' ' .. userData[1].lastname
        end
        MySQL.update('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', { 'unemployed', 0, targetId })
    end
    
    LogAudit(jobName, 'FIRE', xPlayer.identifier, targetId, { name = targetName })
    TriggerClientEvent('jobpanel:notify', source, targetName .. ' har blivit avskedad', 'success')
    BroadcastRefresh(jobName)
end)

-- Set Grade
RegisterNetEvent('jobpanel:setGrade')
AddEventHandler('jobpanel:setGrade', function(targetId, newGrade)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    if not HasPermission(xPlayer, 'manage_grades') then
        TriggerClientEvent('jobpanel:notify', source, 'Ingen behörighet', 'error')
        return
    end
    
    if newGrade >= xPlayer.job.grade then
        TriggerClientEvent('jobpanel:notify', source, 'Kan ej ge högre/samma rank', 'error')
        return
    end
    
    if xPlayer.identifier == targetId then
        TriggerClientEvent('jobpanel:notify', source, 'Kan ej ändra egen rank', 'error')
        return
    end
    
    local jobName = xPlayer.job.name
    local jobConfig = Config.Jobs[jobName]
    
    if not jobConfig or not jobConfig.grades[newGrade] then
        TriggerClientEvent('jobpanel:notify', source, 'Ogiltig rank', 'error')
        return
    end
    
    local gradeName = jobConfig.grades[newGrade].name
    local targetPlayer = ESX.GetPlayerFromIdentifier(targetId)
    
    if targetPlayer then
        if targetPlayer.job.grade >= xPlayer.job.grade then
            TriggerClientEvent('jobpanel:notify', source, 'Kan ej ändra högre/samma rank', 'error')
            return
        end
        targetPlayer.setJob(jobName, newGrade)
        TriggerClientEvent('jobpanel:notify', targetPlayer.source, 'Din rank ändrades till ' .. gradeName, 'info')
    else
        -- Offline player
        local userData = MySQL.query.await('SELECT job_grade FROM users WHERE identifier = ?', { targetId })
        if userData and userData[1] and userData[1].job_grade >= xPlayer.job.grade then
            TriggerClientEvent('jobpanel:notify', source, 'Kan ej ändra högre/samma rank', 'error')
            return
        end
        MySQL.update('UPDATE users SET job_grade = ? WHERE identifier = ?', { newGrade, targetId })
    end
    
    LogAudit(jobName, 'SET_GRADE', xPlayer.identifier, targetId, { newGrade = newGrade, gradeName = gradeName })
    TriggerClientEvent('jobpanel:notify', source, 'Rank ändrad till ' .. gradeName, 'success')
    BroadcastRefresh(jobName)
end)

-- Deposit
RegisterNetEvent('jobpanel:depositMoney')
AddEventHandler('jobpanel:depositMoney', function(amount, moneyType, note)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    if not HasPermission(xPlayer, 'view_finances') then
        TriggerClientEvent('jobpanel:notify', source, 'Ingen behörighet', 'error')
        return
    end
    
    if amount <= 0 then
        TriggerClientEvent('jobpanel:notify', source, 'Ogiltigt belopp', 'error')
        return
    end
    
    local playerMoney = 0
    if moneyType == 'cash' then
        playerMoney = xPlayer.getMoney()
    else
        playerMoney = xPlayer.getAccount('bank').money
    end
    
    if playerMoney < amount then
        TriggerClientEvent('jobpanel:notify', source, 'Du har inte tillräckligt med pengar', 'error')
        return
    end
    
    local jobName = xPlayer.job.name
    local jobConfig = Config.Jobs[jobName]
    
    if not jobConfig then return end
    
    -- Ta pengar från spelaren
    if moneyType == 'cash' then
        xPlayer.removeMoney(amount)
    else
        xPlayer.removeAccountMoney('bank', amount)
    end
    
    -- Lägg till i society
    MySQL.update('UPDATE addon_account_data SET money = money + ? WHERE account_name = ?', { amount, jobConfig.society })
    
    local newBalance = GetSocietyMoney(jobName)
    local typeLabel = moneyType == 'cash' and 'kontanter' or 'bank'
    
    MySQL.insert('INSERT INTO job_transactions (job_name, type, amount, balance_after, identifier, name, note) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        jobName, 'deposit', amount, newBalance, xPlayer.identifier, xPlayer.getName(), 'Insättning via ' .. typeLabel .. (note ~= '' and ': ' .. note or '')
    })
    
    LogAudit(jobName, 'DEPOSIT', xPlayer.identifier, nil, { amount = amount, type = moneyType })
    TriggerClientEvent('jobpanel:notify', source, 'Satte in $' .. amount .. ' (' .. typeLabel .. ')', 'success')
    BroadcastRefresh(jobName)
end)

-- Withdraw
RegisterNetEvent('jobpanel:withdrawMoney')
AddEventHandler('jobpanel:withdrawMoney', function(amount, moneyType, note)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    if not HasPermission(xPlayer, 'manage_finances') then
        TriggerClientEvent('jobpanel:notify', source, 'Ingen behörighet', 'error')
        return
    end
    
    if amount <= 0 then
        TriggerClientEvent('jobpanel:notify', source, 'Ogiltigt belopp', 'error')
        return
    end
    
    local jobName = xPlayer.job.name
    local jobConfig = Config.Jobs[jobName]
    
    if not jobConfig then return end
    
    local societyMoney = GetSocietyMoney(jobName)
    if societyMoney < amount then
        TriggerClientEvent('jobpanel:notify', source, 'Inte tillräckligt i kassan', 'error')
        return
    end
    
    -- Ta från society
    MySQL.update('UPDATE addon_account_data SET money = money - ? WHERE account_name = ?', { amount, jobConfig.society })
    
    -- Ge till spelare
    if moneyType == 'cash' then
        xPlayer.addMoney(amount)
    else
        xPlayer.addAccountMoney('bank', amount)
    end
    
    local newBalance = GetSocietyMoney(jobName)
    local typeLabel = moneyType == 'cash' and 'kontanter' or 'bank'
    
    MySQL.insert('INSERT INTO job_transactions (job_name, type, amount, balance_after, identifier, name, note) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        jobName, 'withdraw', amount, newBalance, xPlayer.identifier, xPlayer.getName(), 'Uttag till ' .. typeLabel .. (note ~= '' and ': ' .. note or '')
    })
    
    LogAudit(jobName, 'WITHDRAW', xPlayer.identifier, nil, { amount = amount, type = moneyType })
    TriggerClientEvent('jobpanel:notify', source, 'Tog ut $' .. amount .. ' (' .. typeLabel .. ')', 'success')
    BroadcastRefresh(jobName)
end)

-- Add Note
RegisterNetEvent('jobpanel:addNote')
AddEventHandler('jobpanel:addNote', function(targetId, noteText)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    if not HasPermission(xPlayer, 'manage_notes') then
        TriggerClientEvent('jobpanel:notify', source, 'Ingen behörighet', 'error')
        return
    end
    
    if not noteText or noteText == '' then
        TriggerClientEvent('jobpanel:notify', source, 'Anteckningen kan inte vara tom', 'error')
        return
    end
    
    local jobName = xPlayer.job.name
    
    MySQL.insert('INSERT INTO job_employee_notes (job_name, identifier, note, created_by, created_by_name) VALUES (?, ?, ?, ?, ?)', {
        jobName, targetId, noteText, xPlayer.identifier, xPlayer.getName()
    })
    
    TriggerClientEvent('jobpanel:notify', source, 'Anteckning tillagd', 'success')
    BroadcastRefresh(jobName)
end)

-- Remove Note
RegisterNetEvent('jobpanel:removeNote')
AddEventHandler('jobpanel:removeNote', function(noteId)
    local source = source
    local xPlayer = ESX.GetPlayerFromId(source)
    
    if not xPlayer then return end
    if not HasPermission(xPlayer, 'manage_notes') then
        TriggerClientEvent('jobpanel:notify', source, 'Ingen behörighet', 'error')
        return
    end
    
    MySQL.update('DELETE FROM job_employee_notes WHERE id = ?', { noteId })
    
    TriggerClientEvent('jobpanel:notify', source, 'Anteckning borttagen', 'success')
    BroadcastRefresh(xPlayer.job.name)
end)

print('[^2BossPanel^7] Server loaded successfully!')