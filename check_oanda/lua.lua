local p = {}

local oanda = require('oanda.lua')
local processed_oanda = require('processed_oanda.lua')

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

local function remove_duplicates(array)
    if not array or type(array) ~= "table" then
        return array
    end
    local deduped_array = {}
    local exists = {}
    for i, v in ipairs(array) do
        if type(v) == 'number' and v ~= v then
            table.insert(deduped_array, v)
        elseif not exists[v] then
            table.insert(deduped_array, v)
            exists[v] = true
        end
    end
    return deduped_array
end

local max_charge_count = 4
local default_primary_numbers = {0, 1, 2, 3, 4}

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

local field_lookup = {
    ["AR"] = true,
    ["AZ"] = true,
    ["BC"] = true,
    ["BR"] = true,
    ["CEN"] = true,
    ["CE"] = true,
    ["ER"] = true,
    ["ES"] = true,
    ["GU"] = true,
    ["KH"] = true,
    ["OR"] = true,
    ["PE"] = true,
    ["PU"] = true,
    ["SA"] = true,
    ["TE"] = true,
    ["VT"] = true
}

local arrangement_lookup = {
    ["ARRANGEMENT9BEAST&MONSTER,ADDORSED"] = true,
    ["COMBAT"] = true,
    ["ARRANGEMENT9BEAST&MONSTER,RESPECTANT"] = true,
    ["ARRANGEMENT9HEAD,ADDORSED"] = true,
    ["ARRANGEMENT9HEAD,RESPECTANT"] = true,
    ["ARRANGEMENT-IN ANNULO"] = true,
    ["ARRANGEMENT-IN ARCH"] = true,
    ["ARRANGEMENT-IN BEND"] = true,
    ["ARRANGEMENT-IN BEND*3"] = true,
    ["ARRANGEMENT-IN CHEVRON"] = true,
    ["ARRANGEMENT-IN CHEVRON*7"] = true,
    ["ARRANGEMENT-IN CROSS"] = true,
    ["ARRANGEMENT-IN ESTOILE"] = true,
    ["ARRANGEMENT-IN FESS"] = true,
    ["ARRANGEMENT-IN MASCLE"] = true,
    ["ARRANGEMENT-IN ORLE"] = true,
    ["INPALE"] = true,
    ["ARRANGEMENT-IN PALL"] = true,
    ["ARRANGEMENT-IN PALL*7"] = true,
    ["ARRANGEMENT-IN PILE"] = true,
    ["INSA"] = true,
    ["ARRANGEMENT-IN TRIQUETRA"] = true
}

local charge_lookup = {

}

function p.process_oanda(args)
    args = args or {}

    local armory_of_interest = {}
    for i, record in ipairs(oanda) do
        if record["armory"] and #(record["armory"]) > 0 then
            local record_fields = {}
            local record_primary_charges = {}
            local record_primary_numbers = {}
            
            for j, heading in ipairs(record["armory"]) do
                if heading == "NO" then
                    table.insert(record_fields, "NO")
                elseif string.match(heading, "^FIELD:") then
                    local division = string.match(heading, ":(divided[^:]*):") or string.match(heading, ":(divided[^:]*)$") or string.match(heading, ":(solid):") or string.match(heading, ":(solid)$")
                    table.insert(record_fields, division)
                elseif heading == "FO" or heading == "PO" then
                    table.insert(record_primary_numbers, "FP")
                    table.insert(record_primary_numbers, 0)
                else
                    local primary_info = string.match(heading, ":(spn?a):") or string.match(heading, ":(spn?a)$") or string.match(heading, ":(g%d*pn?a):") or string.match(heading, ":(g%d*pn?a)$") or string.match(heading, ":(primary):") or string.match(heading, ":(primary)$") or string.match(heading, ":(%w+ primary):") or string.match(heading, ":(%w+ primary)$")
                    if primary_info then
                        local charge = string.match(heading, "^([^:]+):")
                        if not field_lookup[charge] and not arrangement_lookup[charge] then
                            if charge_lookup[charge] then
                                for k, c in ipairs(charge_lookup[charge]) do
                                    table.insert(record_primary_charges, c)
                                end
                            else
                                table.insert(record_primary_charges, charge)
                            end
                        end

                        local group_n = string.match(primary_info, "g(%d+)pn?a")
                        group_n = tonumber(group_n)
                        local charge_n = string.match(heading, ":%d+:") or string.match(heading, ":%d+$")
                        charge_n = tonumber(charge_n)

                        if primary_info == "spa" or primary_info == "spna" or primary_info == "sole primary" then
                            table.insert(record_primary_numbers, 1)
                        elseif group_n then
                            table.insert(record_primary_numbers, math.min(group_n, max_charge_count))
                        elseif primary_info == "gpa" or primary_info == "gpna" or primary_info == "group primary" then
                            if charge_n and charge_n >= max_charge_count then
                                table.insert(record_primary_numbers, max_charge_count)
                            elseif charge_n then
                                for k = math.max(2, charge_n), max_charge_count, 1 do
                                    table.insert(record_primary_numbers, k)
                                end
                            end
                        elseif primary_info then
                            if charge_n and charge_n >= max_charge_count then
                                table.insert(record_primary_numbers, max_charge_count)
                            elseif charge_n then
                                for k = math.max(1, charge_n), max_charge_count, 1 do
                                    table.insert(record_primary_numbers, k)
                                end
                            end
                        end
                    end
                end
            end

            local new_record = {
                ["name"] = record["name"],
                ["date"] = record["date"],
                ["kingdom"] = record["kingdom"] and kindgom_lookup[record["kingdom"]],
                ["type"] = record["type"] and type_lookup[record["type"]],
                ["blazon"] = record["blazon"],
                ["notes"] = record["notes"],
                ["armory"] = {
                    ["fields"] = remove_duplicates(record_fields),
                    ["primary_charges"] = remove_duplicates(record_primary_charges),
                    ["primary_numbers"] = remove_duplicates(record_primary_numbers)
                }
            }
            table.insert(armory_of_interest, new_record)
        end
    end

    return armory_of_interest
end

local function write_table(record, tabs)
    tabs = tabs or 0
    io.write(string.rep("\t", tabs), "{\n")
    for k, v in pairs(record) do
        io.write(string.rep("\t", tabs + 1))
        if type(k) == "string" then
            io.write("[\"", k, "\"] = ")
        end
        if type(v) == "table" then
            write_table(v, tabs + 1)
        elseif type(v) == "string" then
            io.write("\"", v, "\"")
        else
            io.write(v)
        end
        io.write(",", string.rep("\t", tabs + 1), "\n")
    end
    io.write(string.rep("\t", tabs), "},\n")
end

function p.write_processed_oanda(args)
    local processed = p.process_oanda(args)
    io.write("{\n")
    for i, record in ipairs(processed) do
        write_table(record, 1)
    end
    io.write("\n}")
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

    -- create grouped armory table
    local grouped_armory = {}
    for i, record in ipairs(processed_oanda) do
        local record_fields = record["fields"] and #(record["fields"]) > 0 and record["fields"] or {"NO"}
        for j, field in ipairs(record_fields) do
            grouped_armory[field] = grouped_armory[field] or {}
            local primary_numbers = record["primary_numbers"] and #(record["primary_numbers"]) > 0 and record["primary_numbers"] or default_primary_numbers
            for k, num in ipairs(primary_numbers) do
                local n = math.min(num, max_charge_count)
                grouped_armory[field][n] = grouped_armory[field][n] or {}
                local primary_charges = record["primary_charges"] and #(record["primary_charges"]) > 0 and record["primary_charges"] or {"UNKNOWN"}
                for l, charge in ipairs(primary_charges) do
                    grouped_armory[field][n][charge] = grouped_armory[field][n][charge] or {}
                    table.insert(
                        grouped_armory[field][n][charge],
                        record
                    )
                end
            end
        end
    end

    -- put grouped_armory['NO'] in every other grouped_armory[*][n][charge]
    if grouped_armory["NO"] then
        local fields = {}
        for field, _ in pairs(grouped_armory) do
            if field ~= "NO" then
                table.insert(fields, field)
            end
        end
        local fieldless_charges = {}
        for n = 0, max_charge_count do
            fieldless_charges[n] = {}
            for charge, ca in pairs(grouped_armory["NO"][n] or {}) do
                fieldless_charges[n][charge] = ca
            end
        end
        for i, field in ipairs(fields) do
            for n = 0, max_charge_count do
                if grouped_armory[field][n] then
                    for charge, ca in pairs(fieldless_charges[n]) do
                        if grouped_armory[field][n][charge] then
                            for j, record in ipairs(ca) do
                                table.insert(grouped_armory[field][n][charge], record)
                            end
                        end
                    end
                end
            end
        end
    end

    return grouped_armory
end

function p.potential_conflicts(args)
    args = args or {}
    local letter_date = args["letter_date"] and args["letter_date"]["year"] and args["letter_date"]["month"] and args["letter_date"]

    local conflicts = {}
    local grouped_armory = p.grouped_armory()
    for field, fa in pairs(grouped_armory) do
        for n, na in pairs(fa) do
            for charge, ca in pairs(na) do
                if #ca > 1 then
                    local has_letter = true
                    if letter_date then
                        has_letter = false
                        for i, record in ipairs(ca) do
                            if record["date"] and record["date"]["year"] == letter_date["year"] and record["date"]["month"] == letter_date["month"] then
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