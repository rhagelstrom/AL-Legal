# AL-Legal
Fantasy Grounds 5E extension to check if characters are Adventurers League legal. This extension should be used as a tool to possible issues with a character's AL legality. If a character is in question, the character sheet should be reviewed.

## Usage
Enter the command **/alcheck** and each character sheet in the campaign will be analyzed.

## Not Supported
1. Eberron: Rising from the Last War
2. Elemental Evil Player’s Companion
3. Locathah Rising
4. The Tortle Package

## Notes
**Race/Class/Feats:** Race, Class, Subclass, and Feats are exact pattern match. If a player edits these, then they won't match. Correct ASI calcuation depends on correct matching all of these.

**Hit Point Calculation:** Accurate. A lot of players will adjust their HP from spells and forget about doing that.

**Reverse Point Buy:** A point buy value that is 27 or slightly less is likely accurate. A point buy value larger than 27 should be a big red flag.

**Magic Items:** Anything with a rarity, potions and scrolls excluded, will match as a magic item. Standard Adventuring Gear doesn't have a rarity

## Installation

Download [AL-Legal.ext](https://github.com/rhagelstrom/AL-Legal/raw/main/AL-Legal.ext)  and place in the extensions subfolder of the Fantasy Grounds data folder. 

