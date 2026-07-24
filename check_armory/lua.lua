local p = {}

local armory = require('armory.lua')

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
function p.grouped_armory()
    local max_charge_count = 4

    -- create grouped armory table
    local grouped_armory = {}
    for letter, l in pairs(armory) do
        for _, sub in ipairs(l) do
            local a_fields = a['field'] or {'NO'}
            for __, field in ipairs(a_fields) do
                grouped_armory[field] = grouped_armory[field] or {}
                for ___, num in ipairs(sub['primary_number'] or {}) do
                    local n = math.min(num, max_charge_count)
                    grouped_armory[field][n] = grouped_armory[field][n] or {}
                    for ____, charge in ipairs(sub['primary_charges'] or {}) do
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
                    grouped_armory[field][n][charge] = grouped_armory[field][n][charge] or {}
                    for j, a in ipairs(ca) do
                        table.insert(grouped_armory[field][n][charge], a)
                    end
                end
            end
        end
    end

    return grouped_armory
end

function p.potential_conflicts()
    local armory = {}
    local grouped_armory = p.grouped_armory()
    for field, fa in pairs(grouped_armory) do
        for n, na in pairs(fa) do
            for charge, ca in pairs(na) do
                if #ca > 1 then
                    armory[field] = armory[field] or {}
                    armory[field][n] = armory[field][n] or {}
                    armory[field][n][charge] = ca
                end
            end
        end
    end
    return armory
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
                table.insert(armory_text, field .. ', ' .. n .. ', ' .. charge .. ' (' .. #ca .. '):\n' .. table.concat(blazons, '\n'))
            end
        end
    end
    return table.concat(armory_text, '\n\n')
end

function p.print_grouped_armory()
    return p.print_grouped_table(p.grouped_armory())
end
function p.print_potential_conflicts()
    return p.print_grouped_table(p.potential_conflicts())
end

return p