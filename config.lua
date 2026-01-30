Config = {}

-- ============================================
-- GENERAL SETTINGS
-- ============================================
Config.DevName = 'Elias Developments'
Config.DevLogo = 'https://i.imgur.com/your-logo.png' -- Din utvecklar-logo

Config.RefreshInterval = 5000 -- Live update interval (ms)
Config.Debug = false

-- ============================================
-- ACCESS METHODS
-- ============================================
Config.TabletItem = 'boss_tablet' -- Item name, or false to disable
Config.Command = 'boss' -- Command, or false to disable
Config.UseTarget = true -- ox_target/qb-target support
Config.UseProximity = true -- Open when near location

-- ============================================
-- ANIMATION
-- ============================================
Config.Animation = {
    enabled = true,
    dict = 'amb@code_human_in_bus_passenger_idles@female@tablet@base',
    anim = 'base',
    prop = 'prop_cs_tablet',
    bone = 60309,
    offset = { x = 0.03, y = 0.002, z = -0.0 },
    rotation = { x = 10.0, y = 160.0, z = 0.0 }
}

-- ============================================
-- PERMISSION SYSTEM
-- ============================================
-- Alla tillgängliga behörigheter som kan tilldelas per rank
Config.AllPermissions = {
    { id = 'panel_access', label = 'Tillgång till Panel', icon = 'door-open', category = 'basic' },
    { id = 'view_employees', label = 'Se Anställda', icon = 'users', category = 'basic' },
    { id = 'view_finances', label = 'Se Ekonomi', icon = 'eye', category = 'finance' },
    { id = 'view_grades', label = 'Se Ranks', icon = 'layer-group', category = 'basic' },
    { id = 'view_audit', label = 'Se Revisionslogg', icon = 'clipboard-list', category = 'admin' },
    { id = 'view_statistics', label = 'Se Statistik', icon = 'chart-line', category = 'admin' },
    
    { id = 'hire_fire', label = 'Anställa/Avskeda', icon = 'user-plus', category = 'hr' },
    { id = 'manage_grades', label = 'Ändra Ranks', icon = 'user-cog', category = 'hr' },
    { id = 'manage_notes', label = 'Hantera Anteckningar', icon = 'sticky-note', category = 'hr' },
    { id = 'manage_individual_salary', label = 'Individuell Lön', icon = 'user-tag', category = 'finance' },
    
    { id = 'manage_salary', label = 'Betala Löner', icon = 'money-bill-wave', category = 'finance' },
    { id = 'manage_finances', label = 'Ta ut Pengar', icon = 'hand-holding-usd', category = 'finance' },
    { id = 'manage_grade_salary', label = 'Ändra Löneskalor', icon = 'sliders-h', category = 'admin' },
    
    { id = 'manage_permissions', label = 'Hantera Behörigheter', icon = 'shield-alt', category = 'admin' },
    { id = 'manage_vehicles', label = 'Fordonshantering', icon = 'car', category = 'resources' },
    { id = 'order_equipment', label = 'Beställa Utrustning', icon = 'box', category = 'resources' },
}

-- ============================================
-- JOB CONFIGURATION
-- ============================================
Config.Jobs = {
    ['police'] = {
        label = 'Los Santos Police Department',
        shortLabel = 'LSPD',
        logo = 'https://i.imgur.com/8FzsdCV.png',
        banner = 'https://i.imgur.com/banner.png', -- Optional banner image
        color = '#2563eb', -- Primary color
        colorSecondary = '#1d4ed8', -- Secondary color
        
        -- Access location
        location = {
            enabled = true,
            coords = vector3(441.8465, -982.0898, 30.6896),
            radius = 2.5,
            label = 'Boss Panel'
        },
        
        -- Marker settings
        marker = {
            enabled = true,
            type = 27,
            scale = vector3(1.0, 1.0, 0.5),
            color = { r = 37, g = 99, b = 235, a = 180 },
            bobUpAndDown = true
        },
        
        -- Blip settings
        blip = {
            enabled = true,
            sprite = 60,
            color = 3,
            scale = 0.8,
            label = 'LSPD Station'
        },
        
        -- Society account
        society = 'society_police',
        
        -- Grade configuration with individual permissions
        grades = {
            [0] = { 
                name = 'Kadet', 
                defaultSalary = 2500,
                canReceiveSalary = true,
                permissions = { 
                    'panel_access', 
                    'view_employees' 
                }
            },
            [1] = { 
                name = 'Officer', 
                defaultSalary = 3200,
                canReceiveSalary = true,
                permissions = { 
                    'panel_access', 
                    'view_employees', 
                    'view_grades',
                    'view_finances'
                }
            },
            [2] = { 
                name = 'Sergeant', 
                defaultSalary = 4000,
                canReceiveSalary = true,
                permissions = { 
                    'panel_access', 
                    'view_employees', 
                    'view_grades',
                    'view_finances',
                    'manage_notes',
                    'hire_fire'
                }
            },
            [3] = { 
                name = 'Lieutenant', 
                defaultSalary = 4800,
                canReceiveSalary = true,
                permissions = { 
                    'panel_access', 
                    'view_employees', 
                    'view_grades',
                    'view_finances',
                    'view_audit',
                    'manage_notes',
                    'hire_fire',
                    'manage_grades',
                    'manage_salary'
                }
            },
            [4] = { 
                name = 'Captain', 
                defaultSalary = 5500,
                canReceiveSalary = true,
                permissions = { 
                    'panel_access', 
                    'view_employees', 
                    'view_grades',
                    'view_finances',
                    'view_audit',
                    'view_statistics',
                    'manage_notes',
                    'hire_fire',
                    'manage_grades',
                    'manage_salary',
                    'manage_finances',
                    'manage_individual_salary',
                    'manage_grade_salary'
                }
            },
            [5] = { 
                name = 'Chief of Police', 
                defaultSalary = 7500,
                canReceiveSalary = true,
                permissions = { 
                    'panel_access', 
                    'view_employees', 
                    'view_grades',
                    'view_finances',
                    'view_audit',
                    'view_statistics',
                    'manage_notes',
                    'hire_fire',
                    'manage_grades',
                    'manage_salary',
                    'manage_finances',
                    'manage_individual_salary',
                    'manage_grade_salary',
                    'manage_permissions',
                    'manage_vehicles',
                    'order_equipment'
                }
            }
        },
        
        -- Salary settings
        salarySettings = {
            minSalary = 1000,
            maxSalary = 15000,
            minBonus = 0,
            maxBonus = 10000,
            allowIndividualSalary = true
        }
    },
    
    ['ambulance'] = {
        label = 'Los Santos Medical Department',
        shortLabel = 'LSMD',
        logo = 'https://i.imgur.com/JxN9z0W.png',
        color = '#dc2626',
        colorSecondary = '#b91c1c',
        
        location = {
            enabled = true,
            coords = vector3(311.4851, -592.5918, 43.2840),
            radius = 2.5,
            label = 'Boss Panel'
        },
        
        marker = {
            enabled = true,
            type = 27,
            scale = vector3(1.0, 1.0, 0.5),
            color = { r = 220, g = 38, b = 38, a = 180 },
            bobUpAndDown = true
        },
        
        blip = {
            enabled = true,
            sprite = 61,
            color = 1,
            scale = 0.8,
            label = 'Pillbox Hospital'
        },
        
        society = 'society_ambulance',
        
        grades = {
            [0] = { 
                name = 'Trainee', 
                defaultSalary = 2000,
                canReceiveSalary = true,
                permissions = { 'panel_access', 'view_employees' }
            },
            [1] = { 
                name = 'EMT', 
                defaultSalary = 2800,
                canReceiveSalary = true,
                permissions = { 'panel_access', 'view_employees', 'view_grades', 'view_finances' }
            },
            [2] = { 
                name = 'Paramedic', 
                defaultSalary = 3500,
                canReceiveSalary = true,
                permissions = { 'panel_access', 'view_employees', 'view_grades', 'view_finances', 'manage_notes' }
            },
            [3] = { 
                name = 'Doctor', 
                defaultSalary = 4500,
                canReceiveSalary = true,
                permissions = { 'panel_access', 'view_employees', 'view_grades', 'view_finances', 'view_audit', 'manage_notes', 'hire_fire', 'manage_grades', 'manage_salary' }
            },
            [4] = { 
                name = 'Chief of Medicine', 
                defaultSalary = 6500,
                canReceiveSalary = true,
                permissions = { 'panel_access', 'view_employees', 'view_grades', 'view_finances', 'view_audit', 'view_statistics', 'manage_notes', 'hire_fire', 'manage_grades', 'manage_salary', 'manage_finances', 'manage_individual_salary', 'manage_grade_salary', 'manage_permissions' }
            }
        },
        
        salarySettings = {
            minSalary = 1000,
            maxSalary = 12000,
            minBonus = 0,
            maxBonus = 8000,
            allowIndividualSalary = true
        }
    }
}

-- ============================================
-- WEBHOOKS (Discord Logging)
-- ============================================
Config.Webhooks = {
    enabled = true,
    salary = '', -- Webhook for salary payments
    hiring = '', -- Webhook for hire/fire
    finances = '', -- Webhook for deposits/withdrawals
    audit = '' -- General audit log
}