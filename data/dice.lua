-- data/card/dice.lua
-- Dice card type definitions

local dice = {

    --- Demo Dice ---
    
        {
            id = "D001",
            type = "Black",
            value = 3,
            targ = "Atk",
        },

        {
            id = "D002",
            type = "Black",
            facename = "Blank",
            facedesc = "Does nothing.",
        },

        {
            id = "D003",
            type = "Black",
            value = 72,
        },

        {
            id = "D004",
            type = "Black",
            value = 1,
            targ = "Obj",
        },

        {
            id = "D005",
            type = "Black",
            value = 2,
            targ = "Obj",
        },

        {
            id = "D006",
            type = "Black",
            value = 6,
            targ = "Sab",
        },

        {
            id = "D007",
            type = "Black",
            value = 1,
            targ = "IntCD",
        },

        {
            id = "D008",
            type = "Black",
            value = 2,
            targ = "IntCD",
        },

        {
            id = "D009",
            type = "Black",
            value = 6,
            targ = "IntCD",
        },

        {
            id = "D010",
            type = "Black",
            value = 2,
            targ = "WZOpp",
        },

        {
            id = "D011",
            type = "Black",
            value = 8,
            targ = "WZPlayer",
        },

--- Blank Die ---

{
    id = "NUL",
    type = "Black",
    image = "Nul",
    facename = "Blank",
    facedesc = "Does nothing.",
},

{
    id = "MNGL",
    type = "Black",
    facename = "Mangled",
    facedesc = "Does nothing.",
},

 --- Basic Damage ---

 {
    id = "BDMG4",
    type = "Black",
    over = "BscAtk",
    value = 4,
    targ = "Atk",
    facename = "Basic Attack",
    facedesc = "Deal damage to a target troop or Champion.",
},
 
        {
            id = "BDMG3",
            type = "Black",
            over = "BscAtk",
            value = 3,
            targ = "Atk",
            facename = "Basic Attack",
            facedesc = "Deal damage to a target troop or Champion.",
        },

        {
            id = "BDMG2",
            type = "Black",
            over = "BscAtk",
            value = 2,
            targ = "Atk",
            facename = "Basic Attack",
            facedesc = "Deal damage to a target troop or Champion.",
        },

        {
            id = "BDMG1",
            type = "Black",
            over = "BscAtk",
            value = 1,
            targ = "Atk",
            facename = "Basic Attack",
            facedesc = "Deal damage to a target troop or Champion.",
        },

        --- Advanced Damage ---

        {
            id = "TACDMG1",
            type = "SynTac",
            over = "BscAtk", 
            value = 1,
            action = "attack",
            target = "enemy_card",
            gainSyntac = true,
            facename = "Basic Attack and SynTac",
            facedesc = "Deal damage to a target troop or Champion. Gain SynTac.",
        },

        {
            id = "TACDMG2",
            type = "SynTac",
            over = "BscAtk", 
            value = 2,
            action = "attack",
            target = "enemy_card",
            gainSyntac = true,
            facename = "Basic Attack and SynTac",
            facedesc = "Deal damage to a target troop or Champion. Gain SynTac.",
        },

        {
            id = "EXODMG5",
            type = "Black",
            over = "ExoAtk",
            value = 5,
            action = "attack",
            target = "enemy_card",
            autoReload = true,
            facename = "Exotic Weapon Attack",
            facedesc = "Deal damage to a target troop or Champion. This card gains Reloading.",
        },

        {
            id = "EXODMG10",
            type = "Black",
            over = "ExoAtk",
            value = 10,
            action = "attack",
            target = "enemy_card",
            autoReload = true,
            facename = "Exotic Weapon Attack",
            facedesc = "Deal damage to a target troop or Champion. This card gains Reloading.",
        },

        {
            id = "EXORNGDMG5",
            type = "Rng",
            over = "ExoAtk",
            value = 5,
            action = "attack",
            target = "enemy_card",
            autoReload = true,
            lrange = true,
            facename = "Exotic Long Range Weapon Attack",
            facedesc = "Deal damage to a target troop or Champion. This card gains Reloading. May attack Flying targets.",
        },

        {
            id = "EXOARDMG10",
            type = "Black",
            over = "ExoAreaAtk",
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
            type = "Black",
            over = "CQAtk",
            value = 2,
            action = "attack",
            target = "enemy_card",
            selfBlock = true,
            facename = "Close Quarters Attack",
            facedesc = "Deal damage to a target troop or Champion. This card gains block.",
        },

        {
            id = "CQDMG3",
            type = "Black",
            over = "CQAtk",
            value = 3,
            action = "attack",
            target = "enemy_card",
            selfBlock = true,
            facename = "Close Quarters Attack",
            facedesc = "Deal damage to a target troop or Champion. This card gains block.",
        },

        {
            id = "CQDMG1",
            type = "Black",
            over = "CQAtk",
            value = 1,
            action = "attack",
            target = "enemy_card",
            selfBlock = true,
            facename = "Close Quarters Attack",
            facedesc = "Deal damage to a target troop or Champion. This card gains block.",
        },

        {
            id = "HCQDMG4",
            type = "Black",
            over = "CQHvAtk",
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
            type = "Black",
            over = "MlAtk",
            value = 3,
            action = "attack",
            target = "enemy_card",
            selfHeal = true,
            facename = "Mauling Attack",
            facedesc = "Deal damage to a target troop or Champion. This card heals.",
        },

        {
            id = "ARDMG1",
            type = "Black",
            over = "AreaAtk",
            value = 1,
            targ = "Atk",
            facename = "High Explosive Attack",
            facedesc = "Deal damage to a target troop or Champion. Damages adjacent troops.",
            area = true,
        },

        {
            id = "RNGDMG1",
            type = "Black",
            over = "BscRngAtk",
            value = 1,
            targ = "Atk",
            facename = "Long Range Attack",
            facedesc = "Deal damage to a target troop or Champion. May attack Flying targets.",
            lrange = true,
        },

        {
            id = "IMMACRNGDMG3",
            type = "Rng",
            over = "ImmRngAtk",
            value = 3,
            targ = "Atk",
            facename = "Immaculate Long Range Attack",
            facedesc = "Deal damage to a target troop or Champion. Double damage if at full health. May attack Flying targets.",
            lrange = true,
            immac = true,
        },

        {
            id = "WDMG1",
            type = "Wnd",
            over = "BscAtk",
            value = 1,
            targ = "Atk",
            facename = "Wound Attack",
            facedesc = "Deal damage to a target troop or Champion. Inflict the Wound condition.",
            wound = true,
        },

        {
            id = "WDMG2",
            type = "Wnd",
            over = "BscAtk",
            value = 2,
            targ = "Atk",
            facename = "Wound Attack",
            facedesc = "Deal damage to a target troop or Champion. Inflict the Wound condition.",
            wound = true,
        },

        {
            id = "AWDMG1",
            type = "Wnd",
            over = "AreaAtk",
            value = 1,
            targ = "Atk",
            facename = "Area Wound Attack",
            facedesc = "Deal damage to a target troop and adjacent troops or Champion. Inflict the Wound condition.",
            wound = true,
            area = true,
        },

        {
            id = "AWDMG2",
            type = "Wnd",
            over = "AreaAtk",
            value = 2,
            targ = "Atk",
            facename = "Area Wound Attack",
            facedesc = "Deal damage to a target troop and adjacent troops or Champion. Inflict the Wound condition.",
            wound = true,
            area = true,
        },

        {
            id = "MNGDMG1",
            type = "Mng",
            over = "BscAtk",
            value = 1,
            targ = "Atk",
            mangle = true,
            facename = "Mangling Attack",
            facedesc = "Deal damage to a target troop or Champion. Mangle their dice.",
        },

        {
            id = "MNGDMG2",
            type = "Mng",
            over = "BscAtk",
            value = 2,
            targ = "Atk",
            mangle = true,
            facename = "Mangling Attack",
            facedesc = "Deal damage to a target troop or Champion. Mangle their dice.",
        },


    -- Pain Damage ---


    {
        id = "PDMG8",
        type = "Sui",
        over = "BscAtk",
        value = 8,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",
    },

    {
        id = "PDMG7",
        type = "Sui",
        over = "BscAtk",
        value = 7,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",
    },

    {
        id = "PDMG6",
        type = "Sui",
        over = "BscAtk",
        value = 6,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",
    },

    {
        id = "PDMG5",
        type = "Sui",
        over = "BscAtk",
        value = 5,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",
    },

    {
        id = "PDMG4",
        type = "Sui",
        over = "BscAtk",
        value = 4,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",
    },

    {
        id = "PDMG3",
        type = "Sui",
        over = "BscAtk",
        value = 1,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",
    },

    {
        id = "PDMG2",
        type = "Sui",
        over = "BscAtk",
        value = 2,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",

    },

    {
        id = "PDMG1",
        type = "Sui",
        over = "BscAtk",
        value = 1,
        targ = "Atk",
        pain = true,
        facename = "Suicide Attack",
        facedesc = "Deal damage to a target troop or Champion. Deal damage to this card.",

    },

    {
        id = "ARPDMG1",
        type = "Sui",
        over = "AreaAtk",
        value = 1,
        targ = "Atk",
        pain = true,
        area = true,
        facename = "Area Suicide Attack",
        facedesc = "Deal damage to a target troop and adjacent troops or Champion. Deal damage to this card.",

    },

    {
        id = "ARPDMG2",
        type = "Sui",
        over = "AreaAtk",
        value = 2,
        targ = "Atk",
        pain = true,
        area = true,
        facename = "Area Suicide Attack",
        facedesc = "Deal damage to a target troop and adjacent troops or Champion. Deal damage to this card.",

    },

    {
        id = "ARPDMG3",
        type = "Sui",
        over = "AreaAtk",
        value = 3,
        targ = "Atk",
        pain = true,
        area = true,
        facename = "Area Suicide Attack",
        facedesc = "Deal damage to a target troop and adjacent troops or Champion. Deal damage to this card.",

    },

    {
        id = "EXOARPDMG1",
        type = "Black",
        over = "ExoAreaPAtk",
        value = 1,
        targ = "Atk",
        pain = true,
        area = true,
        autoReload = true,
        facename = "Exotic Area Suicide Attack",
        facedesc = "Deal damage to a target troop and adjacent troops or Champion. Deal damage to this card. This card gains Reloading.",

    },

    {
        id = "EXOARPDMG2",
        type = "Black",
        over = "ExoAreaPAtk",
        value = 2,
        targ = "Atk",
        pain = true,
        area = true,
        autoReload = true,
        facename = "Exotic Area Suicide Attack",
        facedesc = "Deal damage to a target troop and adjacent troops or Champion. Deal damage to this card. This card gains Reloading.",

    },

    {
        id = "EXOARPDMG3",
        type = "Black",
        over = "ExoAreaPAtk",
        value = 3,
        targ = "Atk",
        pain = true,
        area = true,
        autoReload = true,
        facename = "Exotic Area Suicide Attack",
        facedesc = "Deal damage to a target troop and adjacent troops or Champion. Deal damage to this card. This card gains Reloading.",

    },

    --- Basic Block ---

    {
        id = "BBLK1",
        type = "Black",
        over = "BscBlk",
        value = 1,
        targ = "Blk",
        facename = "Basic Block",
        facedesc = "Add block to an allied troop or Agent.",
    },

    {
        id = "BBLK2",
        type = "Black",
        over = "BscBlk",
        value = 2,
        targ = "Blk",
        facename = "Basic Block",
        facedesc = "Add block to an allied troop or Agent.",
    },

    {
        id = "BBLK3",
        type = "Black",
        over = "BscBlk",
        value = 3,
        targ = "Blk",
        facename = "Basic Block",
        facedesc = "Add block to an allied troop or Agent.",
    },

    {
        id = "BBLK4",
        type = "Black",
        over = "BscBlk",
        value = 4,
        targ = "Blk",
        facename = "Basic Block",
        facedesc = "Add block to an allied troop or Agent.",
    },

    --- Advanced Block ---

    {
        id = "DIV1",
        type = "Black",
        over = "Div",
        value = 1,
        targ = "Div",
        facename = "Divert Attack",
        facedesc = "Divert all attacks targeting an allied card to this card. This card gains block.",
    },

    {
        id = "DIV2",
        type = "Black",
        over = "Div",
        value = 2,
        targ = "Div",
        facename = "Divert Attack",
        facedesc = "Divert all attacks targeting an allied card to this card. This card gains block.",
    },
  
    {
        id = "DIV3",
        type = "Black",
        over = "Div",
        value = 3,
        targ = "Div",
        facename = "Divert Attack",
        facedesc = "Divert all attacks targeting an allied card to this card. This card gains block.",
    },

    --- Basic SynTac

    {
        id = "TAC1",
        type = "SynTac",
        over = "BscTac",
        value = 1,
        targ = "Tac",
        facename = "Basic SynTac",
        facedesc = "Gain SynTac.",
    },

    {
        id = "TAC2",
        type = "SynTac",
        over = "BscTac",
        value = 2,
        targ = "Tac",
        facename = "Basic SynTac",
        facedesc = "Gain SynTac.",
    },

    {
        id = "TAC3",
        type = "SynTac",
        over = "BscTac",
        value = 3,
        targ = "Tac",
        facename = "Basic SynTac",
        facedesc = "Gain SynTac.",
    },

    {
        id = "TAC4",
        type = "SynTac",
        over = "BscTac",
        value = 4,
        targ = "Tac",
        facename = "Basic SynTac",
        facedesc = "Gain SynTac.",
    },


    --- Basic Sabotage ---

    {
        id = "SAB4",
        type = "Sab",
        over = "BscSab",
        value = 4,
        targ = "Sab",
        facename = "Basic Sabotage",
        facedesc = "Removes progress from an Objective or Intelligence asset.",
    },

    {
        id = "SAB3",
        type = "Sab",
        over = "BscSab",
        value = 3,
        targ = "Sab",
        facename = "Basic Sabotage",
        facedesc = "Removes progress from an Objective or Intelligence asset.",
    },

    {
        id = "SAB2",
        type = "Sab",
        over = "BscSab",
        value = 2,
        targ = "Sab",
        facename = "Basic Sabotage",
        facedesc = "Removes progress from an Objective or Intelligence asset.",
    },

    {
        id = "SAB1",
        type = "Sab",
        over = "BscSab",
        value = 1,
        targ = "Sab",
        facename = "Basic Sabotage",
        facedesc = "Removes progress from an Objective or Intelligence asset.",
    },

        --- Advanced Sabotage ---

        {
            id = "TACSAB1",
            type = "Sab",
            over = "BscTac",
            value = 1,
            action = "sabotage",
            target = "objective_or_intel",
            gainSyntac = true,
            facename = "Sabotage and SynTac",
            facedesc = "Removes progress from an Objective or Intelligence asset. Gain SynTac.",
        },

        {
            id = "TACSAB2",
            type = "Sab",
            over = "BscTac",
            value = 2,
            action = "sabotage",
            target = "objective_or_intel",
            gainSyntac = true,
            facename = "Sabotage and SynTac",
            facedesc = "Removes progress from an Objective or Intelligence asset. Gain SynTac.",
        },

        {
            id = "CASHSAB1",
            type = "Sab",
            over = "BscCsh",
            value = 1,
            targ = "Sab",
            genres = "The Scratch",
            facename = "Extractive Sabotage",
            facedesc = "Removes progress from an Objective or Intelligence asset. Gain scratch.",
        },

        {
            id = "CASHSAB2",
            type = "Sab",
            over = "BscCsh",
            value = 2,
            targ = "Sab",
            genres = "The Scratch",
            facename = "Extractive Sabotage",
            facedesc = "Removes progress from an Objective or Intelligence asset. Gain Scratch.",
        },

        {
            id = "DRAWSAB1",
            type = "Draw",
            over = "BscSab",
            value = 1,
            targ = "Sab",
            drawcard = true,
            facename = "Critical Sabotage",
            facedesc = "Removes progress from an Objective or Intelligence asset. Draw cards.",
        },

        {
            id = "DRAWSAB2",
            type = "Draw",
            over = "BscSab",
            value = 2,
            targ = "Sab",
            drawcard = true,
            facename = "Critical Sabotage",
            facedesc = "Removes progress from an Objective or Intelligence asset. Draw cards.",
        },

        --- Pain Sabotage ---

        {
            id = "PSAB1",
            type = "Sui",
            over = "BscSab",
            value = 1,
            targ = "Sab",
            facename = "Suicide Sabotage",
            facedesc = "Removes progress from an Objective or Intelligence asset. Deal damage to this card.",
            pain = true,
        },

        --- Attack / Sabotage Hybrid ---

        {
            id = "ATKORSAB1",
            type = "Black",
            over = "SabAtk",
            value = 1,
            targ = { "Atk", "Sab" },
            facename = "Basic Attack or Sabotage",
            facedesc = "Choose one: Deal damage to a target troop or Champion or remove progress from an Objective or Intelligence asset.",
        },
    
        {
            id = "ATKANDSAB1",
            type = "Black",
            over = "SabAtk",
            value = 1,
            action = "attack",
            target = "enemy_card",
            sabotageObjective = true,
            facename = "Attack and Sabotage",
            facedesc = "Deal damage to a target troop or Champion. Remove progress from an Objective asset.",
        },

        {
            id = "ATKANDSAB2",
            type = "Black",
            over = "SabAtk",
            value = 2,
            action = "attack",
            target = "enemy_card",
            sabotageObjective = true,
            facename = "Attack and Sabotage",
            facedesc = "Deal damage to a target troop or Champion. Remove progress from an Objective asset.",
        },

        {
            id = "PATKANDSAB1",
            type = "Sui",
            over = "SabAtk",
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
        type = "Ifl",
        over = "BscIfl",
        value = 1,
        targ = "WZPlayer",
        facename = "Basic Influence",
        facedesc = "Add influence to a Warzone environment or Person of Interest asset.",
    },

    {
        id = "BINF2",
        type = "Ifl",
        over = "BscIfl",
        value = 2,
        targ = "WZPlayer",
        facename = "Basic Influence",
        facedesc = "Add influence to a Warzone environment or Person of Interest asset.",
    },

    --- Advanced Influence ---

    {
        id = "INFTAC1",
        type = "Ifl",
        over = "BscTac",
        value = 1,
        action = "influence",
        target = "player_warzone",
        gainSyntac = true,
        facename = "Influence and SynTac",
        facedesc = "Add influence to a Warzone environment or Person of Interest asset. Gain SynTac.",
    },

    {
        id = "INFTAC2",
        type = "Ifl",
        over = "BscTac",
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
        type = "Inf",
        over = "BscInf",
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
        type = "Inf",
        over = "BscInf",
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
        type = "Black",
        over = "BscWarr",
        value = 1,
        targ = "IntCD",
        facename = "Warrant",
        facedesc = "Remove progress from No Signal.",
    },

    {
        id = "WARR2",
        type = "Black",
        over = "BscWarr",
        value = 2,
        targ = "IntCD",
        facename = "Warrant",
        facedesc = "Remove progress from No Signal.",
    },

    {
        id = "WARR3",
        type = "Black",
        over = "BscWarr",
        value = 3,
        targ = "IntCD",
        facename = "Warrant",
        facedesc = "Remove progress from No Signal.",
    },

    --- Threat ---

    {
        id = "THR1",
        type = "Ifl",
        over = "BscThr",
        value = 1,
        targ = "WZOpp",
        facename = "Threaten",
        facedesc = "Decrease the player's influence over a warzone.",
    },

    {
        id = "THR2",
        type = "Ifl",
        over = "BscThr",
        value = 2,
        targ = "WZOpp",
        facename = "Threaten",
        facedesc = "Decrease the player's influence over a warzone.",
    },

    {
        id = "THR3",
        type = "Ifl",
        over = "BscThr",
        value = 3,
        targ = "WZOpp",
        facename = "Threaten",
        facedesc = "Decrease the player's influence over a warzone.",
    },

    --- Objective ---

    {
        id = "OBJ1",
        type = "Cvt",
        over = "BscBtn",
        value = 1,
        targ = "Obj",
        facename = "Red Switch",
        facedesc = "Increase the progress on an objective.",
    },

    {
        id = "OBJ2",
        type = "Cvt",
        over = "BscBtn",
        value = 2,
        targ = "Obj",
        facename = "Red Switch",
        facedesc = "Increase the progress on an objective.",
    },

    {
        id = "OBJ3",
        type = "Cvt",
        over = "BscBtn",
        value = 3,
        targ = "Obj",
        facename = "Red Switch",
        facedesc = "Increase the progress on an objective.",
    },

    --- Summoning

    {
        id = "FREYSMN",
        type = "Black",
        over = "SuiSmn",
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
        type = "Black",
        over = "BscSmn",
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
        type = "Black",
        over = "BscSmn",
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
        type = "Black",
        over = "BscSmn",
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
        type = "Black",
        over = "SuiSmn",
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
