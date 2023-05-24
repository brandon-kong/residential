local rs = game:GetService("ReplicatedStorage")
local container = rs.Container

local road = container.Road
local residential = container.Residential

return {
    Residential = {
        House = {
            ['Starter House'] = {
                name = 'Starter House',
                price = 1000,
                description = 'A small house for a small family.',
                maxOccupants = 2,
                model = residential.House['Starter House'],

                special = {
                    stacking = {
                        allowed = true,
                        max = 2,
                        allowedModels = {
                            ['Residential/House/Starter House'] = {
                                max = 1,
                            }
                        }
                    }
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
                        ['Road/Raised Road'] = {
                            max = 1,
                        },
                        ['Road/Streetlight'] = {
                            max = 2,
                        }
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
                        ['Road/Raised Road'] = {
                            max = 1,
                        },
                        ['Road/Streetlight'] = {
                            max = 2,
                        }
                    }
                }
            }
        },

        ['Curved Road'] = {
            name = 'Curved Road',
            price = 100,
            description = 'A dirt road.',
            model = road['Raised Road'],

            special = {
                stacking = {
                    allowed = true,
                    max = 2,
                    allowedModels = {
                        ['Road/Curved Raised Road'] = {
                            max = 1,
                        }
                    }
                }
            }
        },

        ['Curved Raised Road'] = {
            name = 'Curved Raised Road',
            price = 100,
            description = 'A dirt road.',
            model = road['Raised Road'],

            special = {
                stacking = {
                    allowed = true,
                    max = 2,
                    allowedModels = {
                        ['Road/Curved Road'] = {
                            max = 1,
                        }
                    }
                }
            }
        },

        ['Streetlight'] = {
            name = 'Streetlight',
            price = 100,
            description = 'A dirt road.',
            model = road['Streetlight'],

            special = {
                stacking = {
                    allowed = false
                }
            }
        }
    },
}