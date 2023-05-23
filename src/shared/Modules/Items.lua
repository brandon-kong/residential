local rs = game:GetService("ReplicatedStorage")
local container = rs.Container

local road = container.Road
local residential = container.Residential

return {
    Residential = {
        House = {
            ['StarterHouse'] = {
                name = 'Starter House',
                price = 1000,
                description = 'A small house for a small family.',
                maxOccupants = 2,
                model = residential.House.StarterHouse,

                special = {

                }
            }
        }
    },

    Road = {
        ['Basic Road'] = {
            name = 'Basic Road',
            price = 100,
            description = 'A dirt road.',
            model = road['Basic Road'],

            special = {
                stacking = {
                    allowed = true,
                    max = 2,
                    allowedModels = {
                        'Road/Raised Road'
                    }
                }
            }
        },

        ['Raised Road'] = {
            name = 'Raised Road',
            price = 100,
            description = 'A dirt road.',
            model = road['Raised Road'],

            special = {
                stacking = {
                    allowed = true,
                    max = 2,
                    allowedModels = {
                        'Road/Basic Road'
                    }
                }
            }
        }
    },
}