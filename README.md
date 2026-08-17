# SCA Pre-O&A Conflict Checks

This code will systematically check for conflicts between SCA armory submissions which aren't in the [O&A](https://oanda.sca.org/) yet. The UI isn't great, and it requires a lot of manual data entry, but it does work.

## How to use this code
1. Make sure you have [Lua](https://www.lua.org/) installed.
2. Download this code.
3. If needed, add armory data to [armory/lua.lua](armory/lua.lua).
4. In the command line, start Lua and evaluate `require("global_def.lua")`.
5. To check armory, evaluate `check_armory.print_potential_conflicts(...)`.

### print_potential_conflicts
Optional arguments: `min_date`, `max_date`

To check with no date limits:
```
require("global_def.lua")
check_armory.print_potential_conflicts()
```

To check a particular month:
```
require("global_def.lua")
check_armory.print_potential_conflicts({letter_date = {2026, 8}})
```

To check with date limits:
* `check_armory.print_potential_conflicts({min_date = {2026, 5}})`
* `check_armory.print_potential_conflicts({max_date = {2026, 5}})`
* `check_armory.print_potential_conflicts({min_date = {2026, 5}, max_date = {2026, 8}})`

## Filling out the armory data

Go to the appropriate tracking month, like [https://oscar.sca.org/index.php?action=213&id=251](https://oscar.sca.org/index.php?action=213&id=251)

Copy all the emblazons and blazons into a text file, like [armory_replacements.md](armory_replacements.md)

Use regex to format: `([^\n]+)\n([^\n]+)\n` to
```
			{
				['name'] = "$1",
				['blazon'] = "$2",
				['field'] = {},
				['primary_number'] = {},
				['primary_charge'] = {}
			},

```
Check if any of the blazons have quotation marks which need to be escaped.

Add to [armory/lua.lua](armory/lua.lua) with the year and month as keys, like so:
```
{
	[2026] = {
		...
		[05] = {
			{
				['name'] = "...",
				['blazon'] = "...",
				['field'] = {},
				['primary_number'] = {},
				['primary_charge'] = {}
			},
			...
		}
	}
}

Fields are `solid`, `NO`, and directions of division which are features of `FIELD` in the OA& (e.g. `bendwise`). Number of primary charges are integers; the code will group submissions into 0, 1, 2, 3, and 4+. Primary charges are based on codes in the O&A, but with more grouping by SCs (e.g. a tyger will just be coded as a `CAT`, a demi-sun or a caltrop as `STAR`, a tree as `TREE`).

All the data should be manually checked, but these replacements will speed things up a bit:
1. `(\['blazon'\] = "\(Fieldless\)[^\n]+",\n\t\t\t\['field'\] = )\{\}` to `$1{'NO'}`
2. `(\['blazon'\] = "(Gules|Or|Vert|Azure|Purpure|Sable|Argent|Ermine|Vair),[^\n]+",\n\t\t\t\['field'\] = )\{\}` to `$1{'solid'}`
3. `(\['blazon'\] = "Per bend sinister[^\n]+",\n\t\t\t\['field'\] = )\{\}` to `$1{'bendwise sinister'}`
4. `(\['blazon'\] = "Per chevron inverted[^\n]+",\n\t\t\t\['field'\] = )\{\}` to `$1{'chevronwise inverted'}`
5. `(\['blazon'\] = "Per (bend|pale|fess|saltire|chevron)[^\n]+",\n\t\t\t\['field'\] = )\{\}` to `$1{'$2wise'}`
6. `(\['blazon'\] = "Quarterly[^\n]+",\n\t\t\t\['field'\] = )\{\}` to `$1{'quarterly'}`
8. `(\['blazon'\] = "Checky[^\n]+",\n\t\t\t\['field'\] = )\{\}` to `$1{'checky'}`