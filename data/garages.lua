-- these are just the starter garages taht get loaded into the server on resource start, editing them after first start does nothing
-- use the creator in game thru /garagecreator cmnd
return {
    {
        id = 'legion_square',
        label = 'Legion Square',
        type = 'car',
        interact = {
            mode = 'ped',
            coords = { x = 215.95, y = -809.70, z = 29.73, w = 337.0 },
            ped = 's_m_y_valet_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },
        spawns = {
            { x = 222.02, y = -804.19, z = 30.26, w = 248.5 },
            { x = 223.93, y = -799.67, z = 30.26, w = 248.5 },
            { x = 225.70, y = -795.12, z = 30.26, w = 248.5 },
        },
        zone = {
            kind = 'poly',
            points = {
                { x = 230.56, y = -725.12, z = 29.82 },
                { x = 274.00, y = -740.05, z = 33.64 },
                { x = 240.23, y = -821.78, z = 29.06 },
                { x = 198.30, y = -807.24, z = 30.09 },
            },
            minZ = 20.0,
            maxZ = 40.0,
        },
    },
    {
        id = 'pink_cage',
        label = 'Pink Cage Motel',
        type = 'car',
        interact = {
            mode = 'ped',
            coords = { x = 273.43, y = -343.99, z = 43.91, w = 160.0 },
            ped = 's_m_y_valet_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },
        spawns = {
            { x = 270.94, y = -342.96, z = 43.97, w = 161.5 },
            { x = 267.62, y = -341.82, z = 43.97, w = 161.5 },
        },
    },
    {
        id = 'sandy_shores',
        label = 'Sandy Shores',
        type = 'car',
        interact = {
            mode = 'ped',
            coords = { x = 1737.03, y = 3710.86, z = 33.14, w = 20.0 },
            ped = 's_m_y_valet_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },
        spawns = {
            { x = 1737.84, y = 3719.28, z = 33.70, w = 21.2 },
        },
    },
    {
        id = 'paleto_bay',
        label = 'Paleto Bay',
        type = 'car',
        interact = {
            mode = 'ped',
            coords = { x = 80.65, y = 6377.98, z = 30.23, w = 315.0 },
            ped = 's_m_y_valet_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },
        spawns = {
            { x = 76.38, y = 6397.70, z = 30.83, w = 327.0 },
        },
    },
    {
        id = 'mission_row_pd',
        label = 'Mission Row PD',
        type = 'job',
        owners = 'fleet',
        interact = {
            mode = 'ped',
            coords = { x = 448.16, y = -1017.41, z = 27.58, w = 90.65 },
            ped = 's_m_y_cop_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },
        spawns = {
            { x = 438.40, y = -1018.30, z = 27.70, w = 90.0 },
            { x = 438.40, y = -1022.60, z = 27.70, w = 90.0 },
        },
        access = { mode = 'locked', jobs = { { name = 'police', grade = 0, onDuty = true } }, gangs = {}, citizens = {} },
        fleet = {
            { model = 'police', label = 'Police Cruiser' },
            { model = 'police2', label = 'Police Buffalo' },
            { model = 'police3', label = 'Police Interceptor' },
        },
    },
    {
        id = 'lsymc_boathouse',
        label = 'LSYMC boathouse',
        type = 'boat',
        interact = {
            mode = 'ped',
            coords = { x = -794.66, y = -1510.83, z = 1.60, w = 200.0 },
            ped = 's_m_y_valet_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },
        spawns = {
            { x = -793.58, y = -1501.40, z = 0.12, w = 111.5 },
        },
    },
    {
        id = 'lsia_hangar',
        label = 'LSIA hangar',
        type = 'air',
        interact = {
            mode = 'ped',
            coords = { x = -1025.34, y = -3017.00, z = 12.95, w = 60.0 },
            ped = 's_m_y_airworker',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },
        spawns = {
            { x = -979.20, y = -2995.51, z = 13.95, w = 52.2 },
        },
    },
    {
        id = 'davis_impound',
        label = 'Davis Impound',
        type = 'impound',
        interact = {
            mode = 'ped',
            coords = { x = 408.95, y = -1622.79, z = 28.29, w = 226.97 },
            ped = 's_m_y_cop_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
        },
        spawns = {
            { x = 408.13, y = -1644.61, z = 28.29, w = 226.75 },
            { x = 404.60, y = -1648.40, z = 28.29, w = 226.75 },
        },
        rules = { fees = { release = 250 } },
    },
}
