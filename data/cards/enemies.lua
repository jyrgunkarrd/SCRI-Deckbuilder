-- data/enemies.lua
-- enemy definitions

local enemies = {

    --- Enemies ---
    
    --- Subordinate ---

    {
        id = "EN0001",
        name = "Forgiven",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "Those who break Sermon City's laws are forgiven; they repay this act of grace with a life of service, garbed permanently in the image pf Our Lord Father as a display of profound faith and gratitude.",
        health = 3,
        max = 3,
        rfc = 1,
        D1 = "BDMG3",
        D2 = "BDMG2",
        D3 = "BDMG2",
        D4 = "BDMG1",
        D5 = "NUL",
        D6 = "NUL",
    },

    {
        id = "ENMISS",
        name = "Missionary",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "\"The Exterminator brings fire. The Lawman brings steel. The Missionary brings forgiveness.\"",
        health = 5,
        max = 5,
        rfc = 2,
        D1 = "BDMG4",
        D2 = "BDMG4",
        D3 = "ARDMG1",
        D4 = "ARDMG1",
        D5 = "OBJ1",
        D6 = "OBJ1",
    },

    {
        id = "ENFALC",
        name = "Falconer",
        classname = "Enemy",
        subclass = "Troop",
        keyword = { "KWEVA"},
        flavor = "\"They are whole cloth mercenaries. The act of employing them condemns and refutes more than we ever could.\"",
        health = 3,
        max = 3,
        rfc = 2,
        D1 = "BDMG3",
        D2 = "BDMG3",
        D3 = "BDMG2",
        D4 = "BDMG2",
        D5 = "BDMG2",
        D6 = "BDMG2",
    },

    {
        id = "ENOWL",
        name = "Spectral Raptor",
        classname = "Enemy",
        subclass = "Troop",
        keyword = { "KWFLY"},
        flavor = "\"Of course I can talk. I can sing too. No, I don't want a 'treat'.\n\n...Actually, well, maybe just a little nibble...\"",
        health = 2,
        max = 2,
        rfc = 1,
        D1 = "PDMG2",
        D2 = "PDMG2",
        D3 = "PDMG2",
        D4 = "PDMG2",
        D5 = "PDMG1",
        D6 = "PDMG1",
    },

    {
        id = "ENFEN",
        name = "Fenrir",
        classname = "Enemy",
        subclass = "Troop",
        keyword = { "KWRAGE"},
        flavor = "\"I used to say there were no bad dogs. I don't say that anymore.\"",
        health = 16,
        max = 16,
        rfc = 5,
        D1 = "CQDMG3",
        D2 = "CQDMG3",
        D3 = "CQDMG3",
        D4 = "ARPDMG2",
        D5 = "ARPDMG2",
        D6 = "AWDMG1",
    },

    {
        id = "ENNUN",
        name = "Messenger",
        classname = "Enemy",
        subclass = "Troop",
        keyword = { "KWFLY"},
        flavor = "\"Our Lord Father's messengers always have much to say, but they only speak in one particular language.\"",
        health = 2,
        max = 2,
        rfc = 2,
        D1 = "ANGELSMN",
        D2 = "BDMG2",
        D3 = "BDMG2",
        D4 = "BDMG3",
        D5 = "BDMG3",
        D6 = "BDMG3",
    },

    {
        id = "ENDRON",
        name = "Menace Hunter",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "\"Proof of concept model, really. Didn't do much damage to the ants, but was an invaluable foundation for later grey warfare designs.\"",
        health = 2,
        max = 2,
        rfc = 1,
        D1 = "ARDMG1",
        D2 = "BDMG1",
        D3 = "BDMG1",
        D4 = "BDMG1",
        D5 = "PDMG4",
        D6 = "PDMG4",
    },

    {
        id = "ENDEC",
        name = "Decriminalizer",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "\"It does what the name suggests. And does it very well.\"",
        health = 2,
        max = 2,
        keyword = { "KWCNTR" },
        kwval = {
            KWCNTR = 1,
        },
        rfc = 1,
        D1 = "MNGDMG2",
        D2 = "MNGDMG2",
        D3 = "MNGDMG2",
        D4 = "MNGDMG2",
        D5 = "MNGDMG2",
        D6 = "MNGDMG2",
    },

    {
        id = "ENPORC",
        name = "Crowned",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "\"Not all accept forgiveness. Blinded by guilt, some become Crowned: martyrs sealed inside machines of absolution.\"",
        health = 13,
        max = 13,
        keyword = { "KWCNTR" },
        kwval = {
            KWCNTR = 1,
        },
        rfc = 3,
        D1 = "PDMG8",
        D2 = "PDMG8",
        D3 = "PDMG7",
        D4 = "PDMG7",
        D5 = "PDMG4",
        D6 = "PDMG4",
    },

    {
        id = "ENORB",
        name = "Hunter Orb",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "\"The primary innovations were about simplification rather than performance enhancement.\"",
        health = 4,
        max = 4,
        keyword = { "KWCNTR" },
        kwval = {
            KWCNTR = 1,
        },
        rfc = 2,
        D1 = "PDMG5",
        D2 = "BDMG4",
        D3 = "BDMG4",
        D4 = "BDMG4",
        D5 = "WDMG1",
        D6 = "WDMG1",
    },



    --- Captain ---

    {
        id = "EN0002",
        name = "Confessor",
        classname = "Enemy",
        subclass = "Troop",
        keyword = { "KWTOUGH"},
        flavor = "Confessors attend to the final rites of the Forgiven, accepting any last words of apology or prayer on behalf of Our Lord Father.",
        health = 7,
        max = 7,
        encounter = {
            spawns = {
                { enemyId = "EN0001", count = 2 },
            },
        },
        preview = {
            label = "SQUAD",
            cards = {
                { "EN0001", quantity = 2 },
            },
        },
        rfc = 3,
        D1 = "ARDMG1",
        D2 = "BDMG3",
        D3 = "BDMG2",
        D4 = "BDMG2",
        D5 = "BDMG2",
        D6 = "BDMG1",
    },

    {
        id = "ENSEEN",
        name = "Seen",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "The Seen are the backbone of Sermon City's volunteer security forces - those who take up arms after witnessing an act of the divine.",
        health = 6,
        max = 6,
        encounter = {
            spawns = {
                { enemyId = "EN0001", count = 2 },
            },
        },
        preview = {
            label = "SQUAD",
            cards = {
                { "EN0001", quantity = 2 },
            },
        },
        rfc = 3,
        D1 = "BDMG4",
        D2 = "BDMG4",
        D3 = "BDMG3",
        D4 = "BDMG3",
        D5 = "ARDMG1",
        D6 = "ARDMG1",
    },

    {
        id = "ENBISH",
        name = "Bishop",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "\"Two hundred years of justice, honesty, security. Two hundred years! And it should all end now? Over twelve seconds of doubt? Absurd.\"",
        health = 3,
        max = 3,
        keyword = { "KWBULLETPROOF", "KWFAIR"},
        encounter = {
            spawns = {
                { enemyId = "ENFALC", count = 1 },
                { enemyId = "ENMISS", count = 1 },
                { enemyId = "ENOWL", count = 1 },
            },
        },
        preview = {
            label = "SQUAD",
            cardIds = { "ENFALC", "ENMISS", "ENOWL" },
        },
        rfc = 3,
        D1 = "OBJ3",
        D2 = "OBJ3",
        D3 = "THR3",
        D4 = "THR3",
        D5 = "OBJ1",
        D6 = "THR1",
    },

    {
        id = "ENNUNC",
        artId = "ENNUN",
        name = "Messenger",
        classname = "Enemy",
        subclass = "Troop",
        keyword = { "KWFLY"},
        flavor = "\"Our Lord Father's messengers always have much to say, but they only speak in one particular language.\"",
        health = 2,
        rfc = 2,
        encounter = {
            spawns = {
                { enemyId = "ENNUN", count = 1 },
                { enemyId = "ENDRON", count = 4 },
            },
        },
        preview = {
            label = "SQUAD",
            cards = {
                { "ENNUN", quantity = 1 },
                { "ENDRON", quantity = 4 },
            },
        },
        D1 = "ANGELSMN",
        D2 = "BDMG2",
        D3 = "BDMG2",
        D4 = "BDMG3",
        D5 = "BDMG3",
        D6 = "BDMG3",
    },

    {
        id = "ENSEENDRON",
        artId = "ENSEEN",
        name = "Seen",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "The Seen are the backbone of Sermon City's volunteer security forces - those who take up arms after witnessing an act of the divine.",
        health = 6,
        max = 6,
        encounter = {
            spawns = {
                { enemyId = "ENDRON", count = 2 },
            },
        },
        preview = {
            label = "SQUAD",
            cards = {
                { "ENDRON", quantity = 2 },
            },
        },
        rfc = 3,
        D1 = "BDMG4",
        D2 = "BDMG4",
        D3 = "BDMG3",
        D4 = "BDMG3",
        D5 = "ARDMG1",
        D6 = "ARDMG1",
    },

    {
        id = "ENBISHDEC",
        name = "Bishop",
        artId = "ENBISH",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "\"Two hundred years of justice, honesty, security. Two hundred years! And it should all end now? Over twelve seconds of doubt? Absurd.\"",
        health = 3,
        max = 3,
        keyword = { "KWBULLETPROOF", "KWFAIR"},
        encounter = {
            spawns = {
                { enemyId = "ENDEC", count = 2 },
            },
        },
        preview = {
            label = "SQUAD",
            cards = {
                { "ENDEC", quantity = 2 },
            },
        },
        rfc = 3,
        D1 = "OBJ3",
        D2 = "OBJ3",
        D3 = "THR3",
        D4 = "THR3",
        D5 = "OBJ1",
        D6 = "THR1",
    },

    {
        id = "ENSTRD",
        name = "Death Strider",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "\"A mad renegade. A zealot. We care not who they were, only that they are now useful.\"",
        health = 21,
        max = 21,
        encounter = {
            spawns = {
                { enemyId = "ENPORC", count = 2 },
            },
        },
        preview = {
            label = "SQUAD",
            cards = {
                { "ENPORC", quantity = 2 },
            },
        },
        rfc = 14,
        D1 = "EXOARPDMG3",
        D2 = "EXOARPDMG3",
        D3 = "EXOARPDMG2",
        D4 = "EXOARPDMG2",
        D5 = "ORBSMN",
        D6 = "ORBSMN",
    },

    ---=== MODULAR PACKAGES ===---

    --- Ezekiel ---

        -- Captain --
    {
        id = "ENZEK",
        name = "The Ezekiel",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "\"None have ventured further from Sermon City. And whatever they've seen out there, it only seems to have redoubled their loyalties.\"",
        health = 10,
        max = 10,
        keyword = { "KWTOUGH", "KWFLY" },
        encounter = {
            spawns = {
                { enemyId = "ENADV", count = 2 },
            },
        },
        preview = {
            label = "SQUAD",
            cards = {
                { "ENADV", quantity = 2 },
            },
        },
        rfc = 8,
        D1 = "PDMG4",
        D2 = "PDMG4",
        D3 = "ADVSMN",
        D4 = "ADVSMN",
        D5 = "ADVSMN",
        D6 = "ADVSMN",
    },

    {
        id = "ENFOG",
        name = "Fogbank",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "\"Only a fool would refuse loyalty to those who have the weather's obedience.\"",
        health = 3,
        max = 3,
        textbox = "This card gains Growth equal to its Block.",
        func = "ENFOGFUNC",
        keyword = { "KWEVA" },
        encounter = {
            spawns = {
                { enemyId = "ENSTRM", count = 2 },
            },
        },
        preview = {
            label = "SQUAD",
            cards = {
                { "ENSTRM", quantity = 2 },
            },
        },
        rfc = 3,
        D1 = "OBJBLK2",
        D2 = "OBJBLK2",
        D3 = "THRBLK2",
        D4 = "THRBLK2",
        D5 = "CQDMG2",
        D6 = "CQDMG2",
    },

    {
        id = "ENADVACE",
        artId = "ENADV",
        name = "Advent Squadron",
        classname = "Enemy",
        subclass = "Troop",
        flavor = "\"Good pilots. Great bootlickers.\"",
        health = 2,
        max = 2,
        keyword = { "KWFLY" },
        encounter = {
            spawns = {
                { enemyId = "ENSKY", count = 2 },
            },
        },
        preview = {
            label = "SQUAD",
            cards = {
                { "ENSKY", quantity = 2 },
            },
        },
        rfc = 2,
        D1 = "BDMG2",
        D2 = "BDMG2",
        D3 = "BDMG1",
        D4 = "NUL",
        D5 = "NUL",
        D6 = "NUL",
    },

        -- Subordinate --

        {
            id = "ENADV",
            name = "Advent Squadron",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"Good pilots. Great bootlickers.\"",
            health = 2,
            max = 2,
            keyword = { "KWFLY" },
            rfc = 2,
            D1 = "BDMG2",
            D2 = "BDMG2",
            D3 = "BDMG1",
            D4 = "NUL",
            D5 = "NUL",
            D6 = "NUL",
        },

        {
            id = "ENSTRM",
            name = "Storm Rider",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"It's amazing what people will sign-up for just to play with some cool toys.\"",
            health = 4,
            max = 4,
            keyword = { "KWEVA" },
            rfc = 3,
            D1 = "EXORNGDMG5",
            D2 = "EXORNGDMG5",
            D3 = "BDMG3",
            D4 = "BDMG3",
            D5 = "CQDMG2",
            D6 = "CQDMG1",
        },

        {
            id = "ENSKY",
            name = "Sky Wolf",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"Slaughter and payment are one and the same to them.\"",
            health = 1,
            max = 1,
            keyword = { "KWFLY" },
            rfc = 2,
            D1 = "ARDMG1",
            D2 = "ARDMG1",
            D3 = "BDMG2",
            D4 = "BDMG2",
            D5 = "NUL",
            D6 = "NUL",
        },

    --- Red Dot's Gang ---

        -- Captain --
        
        {
            id = "ENDOT",
            artId = "ENDOT",
            name = "Red Dot",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"It is necessity, not loyalty. Their mayhem would lose its glow without the contrast of the police state.\"",
            health = 4,
            max = 4,
            keyword = { "KWBULLETPROOF" },
            encounter = {
                spawns = {
                    { enemyId = "ENTKO", count = 2 },
                },
            },
            preview = {
                label = "SQUAD",
                cards = {
                    { "ENTKO", quantity = 2 },
                },
            },
            rfc = 6,
            D1 = "RNGDMG6",
            D2 = "RNGDMG6",
            D3 = "RNGDMG4",
            D4 = "RNGDMG4",
            D5 = "CQDMG2",
            D6 = "CQDMG2",
        },

                
        {
            id = "ENFID",
            artId = "ENFID",
            name = "The Fiddler",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"She's hoping to one day make someone scream until they sound like a string instrument.\"",
            health = 8,
            max = 8,
            keyword = { "KWCNTR", "KWTOUGH" },
            kwval = {
                KWCNTR = 1,
            },
            encounter = {
                spawns = {
                    { enemyId = "ENTKO", count = 2 },
                },
            },
            preview = {
                label = "SQUAD",
                cards = {
                    { "ENTKO", quantity = 2 },
                },
            },
            rfc = 10,
            D1 = "PDMG6",
            D2 = "PDMG6",
            D3 = "PDMG4",
            D4 = "PDMG4",
            D5 = "CQDMG3",
            D6 = "CQDMG3",
        },

        {
            id = "ENFDOH",
            artId = "ENFDOH",
            name = "Fey Doh",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"It is whatever it wants to be. And usually that's not great for everything else around it.\"",
            health = 3,
            max = 3,
            keyword = { "KWBULLETPROOF", "KWRAGE" },
            encounter = {
                spawns = {
                    { enemyId = "ENTKO", count = 2 },
                },
            },
            preview = {
                label = "SQUAD",
                cards = {
                    { "ENTKO", quantity = 2 },
                },
            },
            rfc = 5,
            D1 = "CQDMG2",
            D2 = "CQDMG2",
            D3 = "CQDMG1",
            D4 = "CQDMG1",
            D5 = "NUL",
            D6 = "NUL",
        },

        {
            id = "ENOCTO",
            artId = "ENOCTO",
            name = "Octopuss",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"...It's true. They put a cat's brain in there.\"",
            health = 14,
            max = 14,
            keyword = { "KWRAGE" },
            encounter = {
                spawns = {
                    { enemyId = "ENTKO", count = 2 },
                },
            },
            preview = {
                label = "SQUAD",
                cards = {
                    { "ENTKO", quantity = 2 },
                },
            },
            rfc = 16,
            D1 = "WDMG2",
            D2 = "WDMG2",
            D3 = "CQDMG2",
            D4 = "CQDMG2",
            D5 = "NUL",
            D6 = "NUL",
        },

        {
            id = "ENWAGN",
            artId = "ENWAGN",
            name = "Wagon",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"It'd make a Hell of a bang.\"",
            health = 10,
            max = 10,
            keyword = { "KWBOOM" },
            kwval = {
                KWBOOM = 5,
            },
            encounter = {
                spawns = {
                    { enemyId = "ENTKO", count = 2 },
                },
            },
            preview = {
                label = "SQUAD",
                cards = {
                    { "ENTKO", quantity = 2 },
                },
            },
            rfc = 12,
            D1 = "AWDMG1",
            D2 = "AWDMG1",
            D3 = "CQDMG2",
            D4 = "CQDMG2",
            D5 = "ADMG1",
            D6 = "ADMG1",
        },

        -- Subordinate --

        {
            id = "ENTKO",
            artId = "ENTKO",
            name = "TKO",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"Some just need to hit something as hard as possible. Something that will feel it.\"",
            health = 6,
            max = 6,
            keyword = { "KWTOUGH" },
            rfc = 8,
            D1 = "HCQDMG6",
            D2 = "CQDMG3",
            D3 = "CQDMG3",
            D4 = "CQDMG2",
            D5 = "CQDMG2",
            D6 = "NUL",
        },


    ---=== CHAMPION DECKS ===---

    --- PAM Deck ---

        -- Captains --

        {
            id = "ENEXTDRVWSP",
            name = "Exterminator",
            artId = "ENEXT",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"None were ever lost to war's appetite. Rats, rain and rust proved to be that much hungrier.\"",
            health = 3,
            max = 3,
            keyword = { "KWBULLETPROOF", "KWTIME" },
            kwval = {
                KWTIME = 2,
            },
            encounter = {
                spawns = {
                    { enemyId = "ENPLDRV", count = 2 },
                    { enemyId = "ENLWSP", count = 2 },
                },
            },
            preview = {
                label = "SQUAD",
                cards = {
                    { "ENPLDRV", quantity = 2 },
                    { "ENLWSP", quantity = 2 },
                },
            },
            rfc = 3,
            D1 = "BDMG4",
            D2 = "BDMG4",
            D3 = "BDMG4",
            D4 = "BDMG3",
            D5 = "BDMG3",
            D6 = "NUL",
        },

        {
            id = "ENJNGLWSP",
            name = "Mercenary Jungler",
            artId = "ENJNGMRC",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"They figured out how to control us well before we figured out how to control them.\"",
            health = 5,
            max = 5,
            encounter = {
                spawns = {
                    { enemyId = "ENPLDRV", count = 1 },
                    { enemyId = "ENLWSP", count = 2 },
                },
            },
            preview = {
                label = "SQUAD",
                cards = {
                    { "ENPLDRV", quantity = 1 },
                    { "ENLWSP", quantity = 2 },
                },
            },
            rfc = 3,
            D1 = "IMMACRNGDMG3",
            D2 = "IMMACRNGDMG3",
            D3 = "CQDMG2",
            D4 = "CQDMG2",
            D5 = "NUL",
            D6 = "NUL",
        },

        {
            id = "ENCLKMKR",
            name = "Clocker",
            artId = "ENCLKMKR",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"If he can't buy you, he'll clock you.\"",
            health = 12,
            max = 12,
            encounter = {
                spawns = {
                    { enemyId = "ENJNGMRC", count = 2 },
                },
            },
            preview = {
                label = "SQUAD",
                cards = {
                    { "ENJNGMRC", quantity = 2 },
                },
            },
            rfc = 15,
            D1 = "CLKATKSMN2",
            D2 = "CLKATKSMN",
            D3 = "CLKATKSMN",
            D4 = "CLKATKSMN",
            D5 = "NUL",
            D6 = "NUL",
        },

        -- Subordinates --

        {
            id = "ENJNGMRC",
            name = "Mercenary Jungler",
            artId = "ENJNGMRC",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"They figured out how to control us well before we figured out how to control them.\"",
            health = 5,
            max = 5,
            rfc = 3,
            D1 = "IMMACRNGDMG3",
            D2 = "IMMACRNGDMG3",
            D3 = "CQDMG2",
            D4 = "CQDMG2",
            D5 = "NUL",
            D6 = "NUL",
        },

        {
            id = "ENPLDRV",
            name = "Pile Driver",
            artId = "ENPLDRV",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"They probably suspected something after we had them bulldoze the bones of their ancestors.\"",
            health = 2,
            max = 2,
            keyword = { "KWBULLETPROOF" },
            rfc = 2,
            D1 = "CQDMG3",
            D2 = "CQDMG3",
            D3 = "BBLK4",
            D4 = "BBLK4",
            D5 = "BBLK2",
            D6 = "BBLK2",
        },

        {
            id = "ENLWSP",
            name = "Lance Wasp",
            artId = "ENLWSP",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"You can probably imagine why these things caused a recruitment drought.\"",
            textbox = "Whenever this card defeats an enemy or is defeated, it summons a Panzervore.",
            preview = {
                label = "SUMMON",
                cards = {
                    { "ENTNKVOR", quantity = 1 },
                },
            },
            health = 1,
            max = 1,
            func = "ENLWSPFUNC",
            keyword = { "KWFLY" },
            rfc = 2,
            D1 = "PDMG5",
            D2 = "PDMG5",
            D3 = "ARDMG2",
            D4 = "ARDMG2",
            D5 = "ARDMG1",
            D6 = "ARDMG1",
        },

        {
            id = "ENTNKVOR",
            name = "Panzervore",
            artId = "ENTNKVOR",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"In the early days, whole companies succumbed to the life cycle of Lance Wasps.\"",
            health = 1,
            max = 1,
            rfc = 1,
            D1 = "LWSPATKSMN",
            D2 = "LWSPATKSMN",
            D3 = "LWSPATKSMN",
            D4 = "NUL",
            D5 = "NUL",
            D6 = "NUL",
        },

        {
            id = "ENCLK",
            name = "Clocked",
            artId = "ENCLK",
            classname = "Enemy",
            subclass = "Troop",
            flavor = "\"They're clocked. Forget 'em.\"",
            keyword = { "KWRAGE" },
            health = 2,
            max = 2,
            rfc = 1,
            D1 = "PDMG3",
            D2 = "PDMG3",
            D3 = "CQDMG2",
            D4 = "CQDMG2",
            D5 = "NUL",
            D6 = "NUL",
        },

}

return enemies
