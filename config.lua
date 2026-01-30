Config = {}

Config.Debug = false

Config.Jobs = {
    ['police'] = {
        label = 'Polisen',
        logo = 'https://r2.fivemanage.com/pN3z1DHpADRyEEFI0VgPv/kronal.png',

        location = {
            coords = vector3(-576.5494, -938.4461, 28.6956),
            radius = 2.0,
        },

        marker = {
            type = 27,
            scale = vector3(1.0, 1.0, 0.5),
            color = { r = 66, g = 135, b = 245, a = 150 },
        },

        licenses = {
            enabled = true,
        },

        market = false,
    },

    ['ambulance'] = {
        label = 'Sjukvården',
        logo = 'https://r2.fivemanage.com/pN3z1DHpADRyEEFI0VgPv/ambulance.png',

        location = {
            coords = vector3(-661.4110, 310.0635, 92.7442),
            radius = 2.0,
        },

        marker = {
            type = 27,
            scale = vector3(1.0, 1.0, 0.5),
            color = { r = 239, g = 68, b = 68, a = 150 },
        },

        market = false,
    },

    ['trygghansa'] = {
        label = 'Trygghansa',
        logo = 'https://r2.fivemanage.com/pN3z1DHpADRyEEFI0VgPv/trygghansa.png',

        location = {
            coords = vector3(-1020.7328, -1376.8068, 5.5578),
            radius = 2.0,
        },

        marker = {
            type = 27,
            scale = vector3(1.0, 1.0, 0.5),
            color = { r = 239, g = 68, b = 68, a = 150 },
        },

        market = false,
    },

    ['bennys'] = {
        label = 'Bennys',
        logo = 'https://r2.fivemanage.com/pN3z1DHpADRyEEFI0VgPv/bennys.png',

        location = {
            coords = vector3(-197.5506, -1361.9559, 30.5901),
            radius = 2.0,
        },

        marker = {
            type = 27,
            scale = vector3(1.0, 1.0, 0.5),
            color = { r = 239, g = 68, b = 68, a = 150 },
        },

        market = false,
    },

    ['cardealer'] = {
        label = 'Premium Deluxe',
        logo = 'https://r2.fivemanage.com/pN3z1DHpADRyEEFI0VgPv/pdm.png',

        location = {
            coords = vector3(148.3198, -141.8414, 54.8001),
            radius = 2.0,
        },

        marker = {
            type = 27,
            scale = vector3(1.0, 1.0, 0.5),
            color = { r = 239, g = 68, b = 68, a = 150 },
        },

        market = false,
    },

    ['moore'] = {
        label = 'Moore Club',
        logo = 'https://r2.fivemanage.com/pN3z1DHpADRyEEFI0VgPv/moore.png',

        location = {
            coords = vector3(129.0687, -1283.3367, 29.2735),
            radius = 2.0,
        },

        marker = {
            type = 27,
            scale = vector3(1.0, 1.0, 0.5),
            color = { r = 239, g = 68, b = 68, a = 150 },
        },

        market = false,
    },

    ['qpark'] = {
        label = 'QPark',
        logo = 'https://r2.fivemanage.com/pN3z1DHpADRyEEFI0VgPv/qpark.png',

        location = {
            coords = vector3(227.2247, 378.5436, 106.1143),
            radius = 2.0,
        },

        marker = {
            type = 27,
            scale = vector3(1.0, 1.0, 0.5),
            color = { r = 239, g = 68, b = 68, a = 150 },
        },

        market = false,
    },

    ['scstyling'] = {
        label = 'SC Styling',
        logo = 'https://r2.fivemanage.com/pN3z1DHpADRyEEFI0VgPv/scstylingh.png',

        location = {
            coords = vector3(126.0558, -3007.9099, 7.0409),
            radius = 2.0,
        },

        marker = {
            type = 27,
            scale = vector3(1.0, 1.0, 0.5),
            color = { r = 239, g = 68, b = 68, a = 150 },
        },

        market = false,
    },

    ['mekonomen'] = {
        label = 'mekonomen',
        logo = 'https://r2.fivemanage.com/pN3z1DHpADRyEEFI0VgPv/images-removebg-preview.png',

        location = {
            coords = vector3(-929.0052, -2029.3982, 9.5045),
            radius = 2.0,
        },

        marker = {
            type = 27,
            scale = vector3(1.0, 1.0, 0.5),
            color = { r = 239, g = 68, b = 68, a = 150 },
        },

        market = false,
    },

    -- Template:
    -- ['jobname'] = {
    --     label = 'Namn',
    --     logo = 'logo url',
    --     location = {
    --         coords = vector3(0.0, 0.0, 0.0),
    --         radius = 2.0,
    --     },
    --     marker = {
    --         type = 27,
    --         scale = vector3(1.0, 1.0, 0.5),
    --         color = { r = 66, g = 135, b = 245, a = 150 },
    --     },
    --     licenses = {
    --         enabled = true,
    --     },
        -- market = {
        --     categories = {
        --         { id = 'weapons', label = 'Vapen' },
        --     },
        --     items = {
        --         { spawnName = 'WEAPON_PISTOL', label = 'Pistol', description = 'Standard tjänstevapen', price = 2500, category = 'weapons', image = 'https://docs.fivem.net/weapons/WEAPON_PISTOL.png' },
        --         { spawnName = 'WEAPON_STUNGUN', label = 'Elpistol', description = 'Icke dödligt alternativ', price = 1500, category = 'weapons', image = 'https://docs.fivem.net/weapons/WEAPON_STUNGUN.png' },
        --     },
        -- },
    -- },
}

Config.KeyToOpen = 38

Config.MinSalary = 1000
Config.MaxSalary = 5500

Config.BossGradeName = 'boss'

Config.AllPermissions = {
    'panel_access',
    'view_employees',
    'manage_grades',
    'manage_notes',
    'manage_tags',
    'manage_licenses',
    'manage_permissions',
    'hire_fire',
    'view_grades',
    'manage_salary',
    'view_finances',
    'manage_finances',
    'view_audit',
    'view_statistics',
    'order_equipment',
}

function Config.HasAccess(jobName)
    return jobName ~= nil and jobName ~= '' and jobName ~= 'unemployed'
end

function Config.IsBossGrade(gradeName)
    return gradeName and string.lower(gradeName) == string.lower(Config.BossGradeName)
end

function Config.GetJobConfig(jobName)
    local jobConfig = Config.Jobs[jobName]
    if jobConfig then
        return jobConfig
    end

    return {
        label = jobName:gsub("^%l", string.upper),
        logo = nil,
        location = nil,
        marker = nil,
        market = nil,
    }
end

function Config.GetJobLocation(jobName)
    local jobConfig = Config.Jobs[jobName]
    if jobConfig and jobConfig.location then
        return jobConfig.location, jobConfig.marker
    end
    return nil, nil
end

function Config.GetJobMarket(jobName)
    local jobConfig = Config.Jobs[jobName]
    if jobConfig and jobConfig.market then
        return jobConfig.market
    end
    return nil
end

function Config.HasLicensesEnabled(jobName)
    local jobConfig = Config.Jobs[jobName]
    return jobConfig and jobConfig.licenses and jobConfig.licenses.enabled == true
end
