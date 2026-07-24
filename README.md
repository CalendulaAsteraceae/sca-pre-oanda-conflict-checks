# SCA Pre-O&A Conflict Checks

This code will systematically check for conflicts between SCA armory submissions which aren't in the [O&A](https://oanda.sca.org/) yet. The UI isn't great, and it requires a lot of manual data entry, but it does work.

## How to use this code
1. Make sure you have [Lua](https://www.lua.org/) installed.
2. Download this code.
3. If needed, add armory data to [armory/lua.lua](armory/lua.lua).
4. In the command line, start Lua, evaluate `require("global_def.lua")`, and evaluate `check_armory.print_potential_conflicts()`.

## Filling out the armory data

Go to the appropriate tracking month, like [https://oscar.sca.org/index.php?action=213&id=251](https://oscar.sca.org/index.php?action=213&id=251)

Copy all the emblazons and blazons into a text file, like [armory_replacements.md](armory_replacements.md)

Use regex to format: `([^\n]+)\n([^\n]+)\n` to
```
		{
			['name'] = "$1",
			['blazon'] = "$2",
			['field'] = {},
			['primary_charges'] = {},
			['primary_number'] = {}
		},

```
Check if any of the blazons have quotation marks which need to be escaped.

Add to [armory/lua.lua](armory/lua.lua) with the month as the key, like
```
{
	...
	['2026-05] = {
		{
			['name'] = "...",
			['blazon'] = "...",
			['field'] = {},
			['primary_charges'] = {},
			['primary_number'] = {}
		},
		...
	}
}

Fields are `solid`, `NO`, and directions of division which are features of `FIELD` in the OA& (e.g. `bendwise`). Number of primary charges are integers; the code will group submissions into 0, 1, 2, 3, and 4+. Primary charges are codes in the O&A, but with more grouping by SCs (e.g. a tyger will just be coded as a `CAT`).