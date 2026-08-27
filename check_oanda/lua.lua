local p = {}

local armory = require('oanda.lua')

local function date_leq(date1, date2)
    if not date1 or not date2 or not date1["year"] or not date2["year"] then
        return nil
    end
    if date1["year"] ~= date2["year"] then
        return date1["year"] < date2["year"]
    end
    if not date1["month"] or not date2["month"] then
        return true
    end
    return date1["month"] <= date2["month"]
end

local kindgom_lookup = {
    ["A"] = "Atenveldt",
	["C"] = "Caid",
	["D"] = "Drachenwald",
	["E"] = "East",
	["G"] = "Gleann Abhann",
	["H"] = "AEthelmearc",
	["K"] = "Calontir",
	["L"] = "Laurel",
	["M"] = "Middle",
	["m"] = "Ealdormere",
	["N"] = "An Tir",
	["n"] = "Northshield",
	["O"] = "Outlands",
	["Q"] = "Atlantia",
	["R"] = "Artemisia",
	["S"] = "Meridies",
	["T"] = "Trimaris",
	["V"] = "Avacal",
	["W"] = "West",
	["w"] = "Lochac",
	["X"] = "Ansteorra"
}

local type_lookup = {
    ["a"] = "augmentation of arms",
	["ABN"] = "ancient branch name",
	["AN"] = "alternate name",
	["ANC"] = "alternate name change",
	["b"] = "badge",
	["B"] = "personal name and badge",
	["BN"] = "branch name",
	["BD"] = "branch name and device",
	["BNC"] = "branch name change",
	["BNc"] = "branch name correction",
	["Bv"] = "branch name variant without correction",
	["Bvc"] = "branch name variant with correction",
	["C"] = "comment",
	["d"] = "device",
	["D"] = "personal name and device",
	["D?"] = "uncertain type of armory",
	["g"] = "regalia",
	["HN"] = "household name",
	["HNC"] = "household name change",
	["j"] = "joint badge cross-reference",
	["N"] = "primary personal name",
	["NC"] = "personal name change",
	["Nc"] = "personal name correction",
	["O"] = "award name or order name",
	["OC"] = "award name change or order name change",
	["r"] = "reserved/generic word/phrase",
	["R"] = "cross-reference",
	["s"] = "seal",
	["t"] = "heraldic title",
	["u"] = "branch designator update",
	["v"] = "personal name variant without correction",
	["vc"] = "personal name variant with correction",
	["W"] = "heraldic will"
}

local function ungrouped_armory(args)
    args = args or {}
    local min_date = args["min_date"] and #(args["min_date"]) == 2 and {["year"] = args["min_date"][1], ["month"] = args["min_date"][2]}
    local max_date = args["max_date"] and #(args["max_date"]) == 2 and {["year"] = args["max_date"][1], ["month"] = args["max_date"][2]}

    local armory_of_interest = {}
    for i, record in ipairs(armory) do
        if date_leq(min_date, record["date"]) ~= false and date_leq(record["date"], max_date) ~= false then
            local new_record = {
                ["name"] = record["name"],
                ["date"] = record["date"] and table.concat(record["date"], "-"),
                ["kingdom"] = record["kingdom"] and kindgom_lookup[record["kingdom"]],
                ["type"] = record["type"] and type_lookup[record["type"]],
                ["blazon"] = record["blazon"],
                ["notes"] = record["notes"]
            }
            table.insert(armory_of_interest, record)
        end
    end
end

--[=[
Format:
{
    field = {
        primary_number = {
            primary_charge = {
                {['letter'] = letter, ['name'] = name, ['blazon'] = blazon},
                ...
            },
            ...
        },
        ...
    },
    ...
}
]=]
function p.grouped_armory(args)
    args = args or {}
    local min_date = args["min_date"] and #(args["min_date"]) == 2 and args["min_date"]
    local max_date = args["max_date"] and #(args["max_date"]) == 2 and args["max_date"]

    local armory_of_interest = {}
    for year, ya in pairs(armory) do
        if (not min_date or year >= min_date[1]) and (not max_date or year <= max_date[1]) then
            for month, ma in pairs(ya) do
                if (not min_date or year > min_date[1] or month >= min_date[2]) and (not max_date or year < max_date[1] or month <= max_date[2]) then
                    armory_of_interest[month .. '/' .. year] = ma
                end
            end
        end
    end

    local max_charge_count = 4
    local default_primary_numbers = {0, 1, 2, 3, 4}

    -- create grouped armory table
    local grouped_armory = {}
    for letter, l in pairs(armory_of_interest) do
        for _, sub in ipairs(l) do
            local sub_fields = (sub['field'] and #sub['field'] > 0 and sub['field']) or {'NO'}

            for __, field in ipairs(sub_fields) do
                grouped_armory[field] = grouped_armory[field] or {}
                local primary_numbers = (sub['primary_number'] and #sub['primary_number'] > 0 and sub['primary_number']) or default_primary_numbers

                for ___, num in ipairs(primary_numbers) do
                    local n = math.min(num, max_charge_count)
                    grouped_armory[field][n] = grouped_armory[field][n] or {}
                    local primary_charges = (sub['primary_charge'] and #sub['primary_charge'] > 0 and sub['primary_charge']) or {'UNKNOWN'}
                    
                    for ____, charge in ipairs(primary_charges) do
                        grouped_armory[field][n][charge] = grouped_armory[field][n][charge] or {}

                        table.insert(
                            grouped_armory[field][n][charge],
                            {['letter'] = letter, ['name'] = sub['name'], ['blazon'] = sub['blazon']}
                        )
                    end
                end
            end
        end
    end

    -- put grouped_armory['NO'] in every other grouped_armory[*][n][charge]
    if grouped_armory['NO'] then
        local fields = {}
        for field, _ in pairs(grouped_armory) do
            if field ~= 'NO' then
                table.insert(fields, field)
            end
        end
        local fieldless_charges = {}
        for n = 0, max_charge_count do
            fieldless_charges[n] = {}
            for charge, ca in pairs(grouped_armory['NO'][n] or {}) do
                fieldless_charges[n][charge] = ca
            end
        end
        for i, field in ipairs(fields) do
            for n = 0, max_charge_count do
                if grouped_armory[field][n] then
                    for charge, ca in pairs(fieldless_charges[n]) do
                        if grouped_armory[field][n][charge] then
                            for j, sub in ipairs(ca) do
                                table.insert(grouped_armory[field][n][charge], sub)
                            end
                        end
                    end
                end
            end
        end
    end

    -- put armory with unknown primary charges in every other grouped_armory[field][n][*]
    local unknown_charges = {}
    local known_charges = {}
    for field, fa in pairs(grouped_armory) do
        unknown_charges[field] = {}
        known_charges[field] = {}
        for n, na in pairs(fa) do
            if na['UNKNOWN'] then
                unknown_charges[field][n] = na['UNKNOWN']
                known_charges[field][n] = {}
                for charge, _ in pairs(na) do
                    if charge ~= 'UNKNOWN' then
                        table.insert(known_charges[field][n], charge)
                    end
                end
            end
        end
    end
    for field, fa in pairs(unknown_charges) do
        for n, na in pairs(fa) do
            for i, sub in ipairs(na) do
                for j, charge in ipairs(known_charges[field][n]) do
                    table.insert(grouped_armory[field][n][charge], sub)
                end
            end
        end
    end

    return grouped_armory
end

function p.potential_conflicts(args)
    args = args or {}
    local letter_date = args['letter_date'] and #(args['letter_date']) == 2 and args['letter_date']
    args["max_date"] = args['letter_date']
    local letter = letter_date and letter_date[2] .. '/' .. letter_date[1]

    local conflicts = {}
    local grouped_armory = p.grouped_armory()
    for field, fa in pairs(grouped_armory) do
        for n, na in pairs(fa) do
            for charge, ca in pairs(na) do
                if #ca > 1 then
                    local has_letter = true
                    if letter then
                        has_letter = false
                        for i, sub in ipairs(ca) do
                            if sub['letter'] == letter then
                                has_letter = true
                            end
                        end
                    end
                    if has_letter then
                        conflicts[field] = conflicts[field] or {}
                        conflicts[field][n] = conflicts[field][n] or {}
                        conflicts[field][n][charge] = ca
                    end
                end
            end
        end
    end
    return conflicts
end

function p.print_grouped_table(grouped_armory)
    local armory_text = {}
    for field, fa in pairs(grouped_armory) do
        for n, na in pairs(fa) do
            for charge, ca in pairs(na) do
                local blazons = {}
                for i, a in ipairs(ca) do
                    table.insert(blazons, a.letter .. ', ' .. a.name .. ', ' .. a.blazon)
                end
                table.insert(armory_text, field .. ', ' .. n .. ', ' .. charge .. ':\n' .. table.concat(blazons, '\n'))
            end
        end
    end
    return table.concat(armory_text, '\n\n')
end

function p.print_grouped_armory(args)
    return p.print_grouped_table(p.grouped_armory(args))
end
function p.print_potential_conflicts(args)
    return p.print_grouped_table(p.potential_conflicts(args))
end

return p