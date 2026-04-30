-- data/card/dice.lua
-- Dice card type definitions

local dice = {

    --- Demo Dice ---
    
        {
            id = "D001",
            type = "BasicDmg",
            value = 3,
            targ = "Atk",
        },

        {
            id = "D002",
            type = "Blank",
            facename = "Blank",
            facedesc = "Does nothing.",
        },

        {
            id = "D003",
            type = "BasicDmg",
            value = 72,
        },

        {
            id = "D004",
            type = "RedButton",
            value = 1,
            targ = "Obj",
        },

        {
            id = "D005",
            type = "RedButton",
            value = 2,
            targ = "Obj",
        },

        {
            id = "D006",
            type = "Detonator",
            value = 6,
            targ = "Sab",
        },

        {
            id = "D007",
            type = "Warrant",
            value = 1,
            targ = "IntCD",
        },

        {
            id = "D008",
            type = "Warrant",
            value = 2,
            targ = "IntCD",
        },

        {
            id = "D009",
            type = "Warrant",
            value = 6,
            targ = "IntCD",
        },

        {
            id = "D010",
            type = "Threat",
            value = 2,
            targ = "WZOpp",
        },

        {
            id = "D011",
            type = "BlackTap",
            value = 8,
            targ = "WZPlayer",
        },

--- Blank Die ---

{
    id = "NUL",
    type = "Nul",
    image = "Nul",
    facename = "Blank",
    facedesc = "Does nothing.",
},

{
    id = "MNGL",
    type = "BlMang",
    facename = "Mangled",
    facedesc = "Does nothing.",
},

 --- Basic Damage ---

 {
    id = "BDMG4",
    type = "BasicDmg",
    value = 4,
    targ = "Atk",
    facename = "Basic Attack",
    facedesc = "Deal damage to a target troop or Champion.",
},
 
        {
            id = "BDMG3",
            type = "BasicDmg",
            value = 3,
            targ = "Atk",
            facename = "Basic Attack",
            facedesc = "Deal damage to a target troop or Champion.",
        },

        {
            id = "BDMG2",
            type = "BasicDmg",
            value = 2,
            targ = "Atk",
            facename = "Basic Attack",
            facedesc = "Deal damage to a target troop or Champion.",
        },

        {
            id = "BDMG1",
            type = "BasicDmg",
            value = 1,
            targ = "Atk",
            facename = "Basic Attack",
            facedesc = "Deal damage to a target troop or Champion.",
        },

        --- Advanced Damage ---

        {
            id = "TACDMG1",
            type = "TacAndDmg",
            value = 1,
            action = "attack",
            target = "enemy_card",
            gainSyntac = true,
            facename = "Basic Attack and SynTac",
            facedesc = "Deal damage to a target troop or Champion. Gain SynTac.",
        },

        {
            id = "TACDMG2",
            type = "TacAndDmg",
            value = 2,
            action = "attack",
            target = "enemy_card",
            gainSyntac = true,
            facename = "Basic Attack and SynTac",
            facedesc = "Deal damage to a target troop or Champion. Gain SynTac.",
        },

        {
            id = "EXODMG5",
            type = "ExWeap",
            value = 5,
            action = "attack",
            target = "enemy_card",
            autoReload = true,
            facename = "Exotic Weapon Attack",
            facedesc = "Deal damage to a target troop or Champion. This card gains Reloading.",
        },

        {
            id = "EXORNGDMG5",
            type = "ExRngWeap",
            value = 5,
            action = "attack",
            target = "enemy_card",
            autoReload = true,
            lrange = true,
            facename = "Exotic Long Range Weapon Attack",
            facedesc = "Deal damage to a target troop or Champion. This card gains Reloading. May attack Flying targets.",
        },

        {
            id = "EXODMG10",
            type = "ExWeap",
            value = 10,
            action = "attack",
            target = "enemy_card",
            autoReload = true,
            facename = "Exotic Weapon Attack",
            facedesc = "Deal damage to a target troop or Champion. This card gains Reloading.",
        },

        {
            id = "EXOARDMG10",
            type = "ExoBeam",
            value = 10,
            action = "attack",
            target = "enemy_card",
            autoReload = true,
            area = true,
            facename = "Exotic Area Weapon Attack",
            facedesc = "Deal damage to a target troop and adjacent troops or Champion. This card gains Reloading.",
        },

        {
            id = "CQDMG2",
            type = "MeleeWeap",
            value = 2,
            action = "attack",
            target = "enemy_card",
            selfBlock = true,
            facename = "Close Quarters Attack",
            facedesc = "Deal damage to a target troop or Champion. This card gains block.",
        },

        {
            id = "CQDMG3",
            type = "MeleeWeap",
            value = 3,
            action = "attack",
            target = "enemy_card",
            selfBlock = true,
            facename = "Close Quarters Attack",
            facedesc = "Deal damage to a target troop or Champion. This card gains block.",
        },

        {
            id = "CQDMG1",
            type = "MeleeWeap",
            value = 1,
            action = "attack",
            target = "enemy_card",
            selfBlock = true,
            facename = "Close Quarters Attack",
            facedesc = "Deal damage to a target troop or Champion. This card gains block.",
        },

        {
            id = "HCQDMG4",
            type = "HvyMeleeWeap",
            value = 4,
            action = "attack",
            target = "enemy_card",
            selfBlock = true,
            heavy = true,
            facename = "Heavy Close Quarters Attack",
            facedesc = "Deal damage to a target troop with the highest health or Champion. This card gains block.",
        },

        {
            id = "MLDMG3",
            type = "Maul",
            value = 3,
            action = "attack",
            target = "enemy_card",
            selfHeal = true,
            facename = "Mauling Attack",
            facedesc = "Deal damage to a target troop or Champion. This card heals.",
        },

        {
            id = "ARDMG1",
            type = "AreaDmg",
            value = 1,
            targ = "Atk",
            facename = "High Explosive Attack",
            facedesc = "Deal damage to a target troop or Champion. Damages adjacent troops.",
            area = true,
        },

        {
            id = "RNGDMG1",
            type = "LRngDmg",
            value = 1,
            targ = "Atk",
            facename = "Long Range Attack",
            facedesc = "Deal damage to a target troop or Champion. May attack Flying targets.",
            lrange = true,
        },

        {
            id = "IMMACRNGDMG3",
            type = "ImmacLRngDmg",
            value = 3,
            targ = "Atk",
            facename = "Immaculate Long Range Attack",
            facedesc = "Deal damage to a target troop or Champion. Double damage if at full health. May attack Flying targets.",
            lrange = true,
            immac = true,
        },

        {
            id = "WDMG1",
            type = "WoundDmg",
            value = 1,
            targ = "Atk",
            facename = "Wound Attack",
            facedesc = "Deal damage to a target troop or Champion. Inflict the Wound condition.",
            wound = true,
        },

        {
            id = "WDMG2",
            type = "WoundDmg",
            value = 2,
            targ = "Atk",
            facename = "Wound Attack",
            facedesc = "Deal damage to a target troop or Champion. Inflict the Wound condition.",
            wound = true,
        },

        {
            id = "AWDMG1",
            type = "AreaWoundDmg",
            value = 1,
            targ = "Atk",
            facename = "Area Wound Attack",
            facedesc = "Deal damage to a target troop and adjacent troops or Champion. Inflict the Wound condition.",
            wound = true,
            area = true,
        },

        {
            id = "AWDMG2",
            type = "AreaWoundDmg",
            value = 2,
            targ = "Atk",
            facename = "Area Wound Attack",
            facedesc = "Deal damage to a target troop and adjacent troops or Champion. Inflict the Wound condition.",
            wound = true,
            area = true,
        },

        {
            id = "MNGDMG1",
            type = "MngDmg",
            value = 1,
            targ = "Atk",
            mangle = true,
            facename = "Mangling Attack",
            facedesc = "Deal damage to a target troop or Champion. Mangle their dice.",
        },

        {
            id = "MNGDMG2",
            type = "MngDmg",
            value = 2,
            targ = "Atk",
            mangle = true,
            facename = "Mangling Attack",
            facedesc = "Deal damage to a target troop or Champion. Mangle their dice.",
        },


    -- Pain Damage ---


    {
        id = "PDMG8",
        type = "PainDmg",
        value = 8,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",
    },

    {
        id = "PDMG7",
        type = "PainDmg",
        value = 7,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",
    },

    {
        id = "PDMG6",
        type = "PainDmg",
        value = 6,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",
    },

    {
        id = "PDMG5",
        type = "PainDmg",
        value = 5,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",
    },

    {
        id = "PDMG4",
        type = "PainDmg",
        value = 4,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",
    },

    {
        id = "PDMG3",
        type = "PainDmg",
        value = 1,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",
    },

    {
        id = "PDMG2",
        type = "PainDmg",
        value = 2,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",

    },

    {
        id = "PDMG1",
        type = "PainDmg",
        value = 1,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",

    },

    {
        id = "ARPDMG1",
        type = "AreaPainDmg",
        value = 1,
        targ = "Atk",
        pain = true,
        area = true,
        facename = "Area Suicide Attack",
        facedesc = "Deal damage to a target troop and adjacent troops or Champion. Deal damage to this card.",

    },

    {
        id = "ARPDMG2",
        type = "AreaPainDmg",
        value = 2,
        targ = "Atk",
        pain = true,
        area = true,
        facename = "Area Suicide Attack",
        facedesc = "Deal damage to a target troop and adjacent troops or Champion. Deal damage to this card.",

    },

    {
        id = "ARPDMG3",
        type = "AreaPainDmg",
        value = 3,
        targ = "Atk",
        pain = true,
        area = true,
        facename = "Area Suicide Attack",
        facedesc = "Deal damage to a target troop and adjacent troops or Champion. Deal damage to this card.",

    },

    {
        id = "EXOARPDMG1",
        type = "ExoAreaPainDmg",
        value = 1,
        targ = "Atk",
        pain = true,
        area = true,
        autoReload = true,
        facename = "Exotic Weapon Area Suicide Attack",
        facedesc = "Deal damage to a target troop and adjacent troops or Champion. Deal damage to this card. This card gains Reloading.",

    },

    {
        id = "EXOARPDMG2",
        type = "ExoAreaPainDmg",
        value = 2,
        targ = "Atk",
        pain = true,
        area = true,
        autoReload = true,
        facename = "Exotic Weapon Area Suicide Attack",
        facedesc = "Deal damage to a target troop and adjacent troops or Champion. Deal damage to this card. This card gains Reloading.",

    },

    {
        id = "EXOARPDMG3",
        type = "ExoAreaPainDmg",
        value = 3,
        targ = "Atk",
        pain = true,
        area = true,
        autoReload = true,
        facename = "Exotic Weapon Area Suicide Attack",
        facedesc = "Deal damage to a target troop and adjacent troops or Champion. Deal damage to this card. This card gains Reloading.",

    },

    --- Basic Block ---

    {
        id = "BBLK1",
        type = "BasicBlk",
        value = 1,
        targ = "Blk",
    },

    {
        id = "BBLK2",
        type = "BasicBlk",
        value = 2,
        targ = "Blk",
    },

    {
        id = "BBLK3",
        type = "BasicBlk",
        value = 3,
        targ = "Blk",
    },

    {
        id = "BBLK4",
        type = "BasicBlk",
        value = 4,
        targ = "Blk",
    },

    --- Advanced Block ---

    {
        id = "DIV1",
        type = "Divert",
        value = 1,
        targ = "Div",
        facename = "Divert Attack",
        facedesc = "Divert all attacks targeting an allied card to this card. This card gains block.",
    },

    {
        id = "DIV2",
        type = "Divert",
        value = 2,
        targ = "Div",
        facename = "Divert Attack",
        facedesc = "Divert all attacks targeting an allied card to this card. This card gains block.",
    },
  
    {
        id = "DIV3",
        type = "Divert",
        value = 3,
        targ = "Div",
        facename = "Divert Attack",
        facedesc = "Divert all attacks targeting an allied card to this card. This card gains block.",
    },

    --- Basic SynTac

    {
        id = "TAC1",
        type = "SynTac",
        value = 1,
        targ = "Tac",
    },

    {
        id = "TAC2",
        type = "SynTac",
        value = 2,
        targ = "Tac",
        facename = "Basic SynTac",
        facedesc = "Gain SynTac.",
    },

    {
        id = "TAC3",
        type = "SynTac",
        value = 3,
        targ = "Tac",
        facename = "Basic SynTac",
        facedesc = "Gain SynTac.",
    },

    {
        id = "TAC4",
        type = "SynTac",
        value = 4,
        targ = "Tac",
        facename = "Basic SynTac",
        facedesc = "Gain SynTac.",
    },


    --- Basic Sabotage ---

    {
        id = "SAB4",
        type = "Detonator",
        value = 4,
        targ = "Sab",
        facename = "Basic Sabotage",
        facedesc = "Removes progress from an Objective or Intelligence asset.",
    },

    {
        id = "SAB3",
        type = "Detonator",
        value = 3,
        targ = "Sab",
        facename = "Basic Sabotage",
        facedesc = "Removes progress from an Objective or Intelligence asset.",
    },

    {
        id = "SAB2",
        type = "Detonator",
        value = 2,
        targ = "Sab",
        facename = "Basic Sabotage",
        facedesc = "Removes progress from an Objective or Intelligence asset.",
    },

    {
        id = "SAB1",
        type = "Detonator",
        value = 1,
        targ = "Sab",
        facename = "Basic Sabotage",
        facedesc = "Removes progress from an Objective or Intelligence asset.",
    },

        --- Advanced Sabotage ---

        {
            id = "TACSAB1",
            type = "SabAndTac",
            value = 1,
            action = "sabotage",
            target = "objective_or_intel",
            gainSyntac = true,
            facename = "Sabotage and SynTac",
            facedesc = "Removes progress from an Objective or Intelligence asset. Gain SynTac.",
        },

        {
            id = "TACSAB2",
            type = "SabAndTac",
            value = 2,
            action = "sabotage",
            target = "objective_or_intel",
            gainSyntac = true,
            facename = "Sabotage and SynTac",
            facedesc = "Removes progress from an Objective or Intelligence asset. Gain SynTac.",
        },

        {
            id = "CASHSAB1",
            type = "CashDetonator",
            value = 1,
            targ = "Sab",
            genres = "The Scratch",
            facename = "Extractive Sabotage",
            facedesc = "Removes progress from an Objective or Intelligence asset. Gain scratch.",
        },

        {
            id = "CASHSAB2",
            type = "CashDetonator",
            value = 2,
            targ = "Sab",
            genres = "The Scratch",
            facename = "Extractive Sabotage",
            facedesc = "Removes progress from an Objective or Intelligence asset. Gain Scratch.",
        },

        {
            id = "DRAWSAB1",
            type = "DrawDetonator",
            value = 1,
            targ = "Sab",
            drawcard = true,
            facename = "Critical Sabotage",
            facedesc = "Removes progress from an Objective or Intelligence asset. Draw cards.",
        },

        {
            id = "DRAWSAB2",
            type = "DrawDetonator",
            value = 2,
            targ = "Sab",
            drawcard = true,
            facename = "Critical Sabotage",
            facedesc = "Removes progress from an Objective or Intelligence asset. Draw cards.",
        },

        --- Pain Sabotage ---

        {
            id = "PSAB1",
            type = "PainDetonator",
            value = 1,
            targ = "Sab",
            facename = "Suicide Sabotage",
            facedesc = "Removes progress from an Objective or Intelligence asset. Deal damage to this card.",
            pain = true,
        },

        --- Attack / Sabotage Hybrid ---

        {
            id = "ATKORSAB1",
            type = "AttackOrSabotage",
            value = 1,
            targ = { "Atk", "Sab" },
            facename = "Basic Attack or Sabotage",
            facedesc = "Choose one: Deal damage to a target troop or Champion or remove progress from an Objective or Intelligence asset.",
        },
    
        {
            id = "ATKANDSAB1",
            type = "AttackAndSabotage",
            value = 1,
            action = "attack",
            target = "enemy_card",
            sabotageObjective = true,
            facename = "Attack and Sabotage",
            facedesc = "Deal damage to a target troop or Champion. Remove progress from an Objective asset.",
        },

        {
            id = "ATKANDSAB2",
            type = "AttackAndSabotage",
            value = 2,
            action = "attack",
            target = "enemy_card",
            sabotageObjective = true,
            facename = "Attack and Sabotage",
            facedesc = "Deal damage to a target troop or Champion. Remove progress from an Objective asset.",
        },

        {
            id = "PATKANDSAB1",
            type = "PainAttackAndSabotage",
            value = 1,
            action = "attack",
            target = "enemy_card",
            sabotageObjective = true,
            facename = "Suicide Attack and Sabotage",
            facedesc = "Deal damage to a target troop or Champion. Remove progress from an Objective asset. Deal damage to this card.",
            pain = true,
        },

    --- Basic Influence ---

    {
        id = "BINF1",
        type = "BlackTap",
        value = 1,
        targ = "WZPlayer",
        facename = "Basic Influence",
        facedesc = "Add influence to a Warzone environment or Person of Interest asset.",
    },

    {
        id = "BINF2",
        type = "BlackTap",
        value = 2,
        targ = "WZPlayer",
        facename = "Basic Influence",
        facedesc = "Add influence to a Warzone environment or Person of Interest asset.",
    },

    --- Advanced Influence ---

    {
        id = "INFTAC1",
        type = "TacAndInf",
        value = 1,
        action = "influence",
        target = "player_warzone",
        gainSyntac = true,
        facename = "Influence and SynTac",
        facedesc = "Add influence to a Warzone environment or Person of Interest asset. Gain SynTac.",
    },

    {
        id = "INFTAC2",
        type = "TacAndInf",
        value = 2,
        action = "influence",
        target = "player_warzone",
        gainSyntac = true,
        facename = "Influence and SynTac",
        facedesc = "Add influence to a Warzone environment or Person of Interest asset. Gain SynTac.",
    },

    --- Infiltration ---

    {
        id = "INF1",
        type = "BasicInf",
        value = 1,
        targ = "Inf",
        cardgen = "HNTINFFM",
        facename = "Infiltrate",
        facedesc = "Add a hunter card to the player's deck.",
        preview = {
            label = "CREATE",
            cardId = "HNTINFFM",
        },
    },

    {
        id = "INF2",
        type = "BasicInf",
        value = 2,
        targ = "Inf",
        cardgen = "HNTINFFM",
        facename = "Infiltrate",
        facedesc = "Add a hunter card to the player's deck.",
        preview = {
            label = "CREATE",
            cardId = "HNTINFFM",
        },
    },

    --- Warrant ---

    {
        id = "WARR1",
        type = "Warrant",
        value = 1,
        targ = "IntCD",
        facename = "Warrant",
        facedesc = "Remove progress from No Signal.",
    },

    {
        id = "WARR2",
        type = "Warrant",
        value = 2,
        targ = "IntCD",
        facename = "Warrant",
        facedesc = "Remove progress from No Signal.",
    },

    {
        id = "WARR3",
        type = "Warrant",
        value = 3,
        targ = "IntCD",
        facename = "Warrant",
        facedesc = "Remove progress from No Signal.",
    },

    --- Threat ---

    {
        id = "THR1",
        type = "Threat",
        value = 1,
        targ = "WZOpp",
        facename = "Threaten",
        facedesc = "Decrease the player's influence over a warzone.",
    },

    {
        id = "THR2",
        type = "Threat",
        value = 2,
        targ = "WZOpp",
        facename = "Threaten",
        facedesc = "Decrease the player's influence over a warzone.",
    },

    {
        id = "THR3",
        type = "Threat",
        value = 3,
        targ = "WZOpp",
        facename = "Threaten",
        facedesc = "Decrease the player's influence over a warzone.",
    },

    --- Objective ---

    {
        id = "OBJ1",
        type = "RedButton",
        value = 1,
        targ = "Obj",
        facename = "Red Switch",
        facedesc = "Increase the progress on an objective.",
    },

    {
        id = "OBJ2",
        type = "RedButton",
        value = 2,
        targ = "Obj",
        facename = "Red Switch",
        facedesc = "Increase the progress on an objective.",
    },

    {
        id = "OBJ3",
        type = "RedButton",
        value = 3,
        targ = "Obj",
        facename = "Red Switch",
        facedesc = "Increase the progress on an objective.",
    },

    --- Summoning

    {
        id = "FREYSMN",
        type = "PainSummon",
        value = 2,
        targ = "smn",
        facename = "Suicide Summon",
        facedesc = "Summon the shown token. Deal damage to this card.",
        target = { "TK0001" },
        func = "Spawn",
        pain = true,
        preview = {
            label = "SUMMON",
            cardId = "TK0001",
        },
    },

    {
        id = "FZSMN",
        type = "Summon",
        value = 1,
        targ = "smn",
        facename = "Summon",
        facedesc = "Summon the shown token.",
        target = { "AEGFZTOK" },
        func = "Spawn",
        preview = {
            label = "SUMMON",
            cardId = "AEGFZTOK",
        },
    },

    {
        id = "TMINGOSMN",
        type = "Summon",
        value = 1,
        targ = "rsmn",
        facename = "Random Summon",
        facedesc = "Summon a randomly chosen token from the shown set.",
        target = { "AEGPRIVEDTOK", "AEGMYRARTOK", "AEGNYFETOK" },
        func = "Spawn",
        preview = {
            label = "SUMMON",
            cardIds = { "AEGPRIVEDTOK", "AEGMYRARTOK", "AEGNYFETOK" },
        },
    },

    {
        id = "ANGELSMN",
        type = "Summon",
        value = 1,
        targ = "smn",
        facename = "Summon",
        facedesc = "Summon the shown enemy.",
        target = { "ENNUN" },
        func = "Spawn",
        preview = {
            label = "SUMMON",
            cardId = "ENNUN",
        },
    },

    {
        id = "ORBSMN",
        type = "PainSummon",
        value = 1,
        targ = "smn",
        facename = "Suicide Summon",
        facedesc = "Summon the shown enemy. Deal damage to this card.",
        target = { "ENORB" },
        func = "Spawn",
        pain = true,
        preview = {
            label = "SUMMON",
            cardId = "ENORB",
        },
    },
    
    
    }
    
    return dice
