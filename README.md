# Black Ops 2 Strat Tester

This mod for Black Ops 2 Zombies that will allow people to test strategies more efficiently in game.

## Download

[Download](https://github.com/5and5/BO2-Strat_Tester/releases/download/latest/BO2-Strat_Tester.zip)

## Created by: 5and5

[Discord](https://discord.gg/Z44Vnjd)

[YouTube](https://www.youtube.com/user/Zomb0s4life)

[Twitch](https://twitch.tv/5and5)

[Twitter](https://twitter.com/5and55)

## How to Install

### Redacted Installation

- Download and install BO2 Redacted [Redacted Download](https://redacted.se/)
- Download the latest version of [Strat Tester](https://github.com/5and5/BO2-Strat_Tester/releases/download/latest/BO2-Strat_Tester.zip)
- Open "BO2-Strat_Tester" and copy the "zm" folder into `Call of Duty Black Ops II Redacted\data\scripts`
- Launch the game and enjoy!

### Plutonium Installation

- Download and install BO2 Plutonium [Plutonium Download](https://plutonium.pw/)
- Download the latest version of [Strat Tester](https://github.com/5and5/BO2-Strat_Tester/releases/download/latest/BO2-Strat_Tester.zip)
- Open "BO2-Strat_Tester" and copy the "zm" folder into `%localappdata%\Plutonium\storage\t6\scripts`
- Launch the game and enjoy!

### How To Use Cheats

- Cheats can be used by typing their key word(s) into the console
- To open the console press the tilda key (key under ESC)
- Cheats can also be bound to a key using the key word "bind" (this will active the cheat when you press the bounded key)

#### List of Useful Cheats

- `god` godmode
- `noclip` flying
- `give ammo` refills ammo
- `give m1911_upgraded_zm` gives weapon (this gives upgraded m1911)
- `timescale 10` changes the speed of the game (10 is max)
- `ai_disableSpawn 1` stops zombies from spawning

#### List of Useful Binds

- `bind F1 noclip` binds noclip to F1
- `bind F2 "give ammo"` binds max ammo to F2
- `bind F3 noclip` binds flying to F3
- `bind F4 "toggle timescale 5 1"` binds 5x timescale to F4

## Patch Notes

### General

- Weapons for high round setup are given
- Perks are given on spawn
- Perks are given after being revived
- Power is turned on
- Buildable parts are given on spawn
- Boards are removed from windows

### HUD

- Timer
- Round timer
- Trap timer
- SPH - appears at the end of rounds
- Zombies remaining counter
- Current player zone

# Coding Related Stuff

## Bugs, Feature Reqeusts, etc.
If you encounter any bugs, have a feature request, something isn't clear, etc. you may [open a new issue](https://github.com/5and5/BO2-Strat_Tester/issues/new)

## Contributing

To contribute, all you have to do is clone the repo. To clone it, open a terminal with git installed and type 
```
git clone https://github.com/5and5/BO2-Strat_Tester
```
then, open the `BO2-Strat_Tester` folder with your favorite editor and get to work!

## Black Ops 2 Source Code
---

You will also want to get a hold of the decompiled source code for Black Ops 2. There is a repo containing the decompiled source and a lot of useful information [here](https://github.com/JezuzLizard/Recompilable-gscs-for-BO2-zombies-and-multiplayer).

## Replacing Functions
---
There are a couple of tricks we can use with Plutonium's toolset in order to change logic within the base game. The easiest way is through simple reassignment. Let's take a look at an example with the box weight function.

```
level.special_weapon_magicbox_check = ::nuked_special_weapon_check;
```

Within GSC, there are `level` variables that are attached the the level instance and work as a 'global' variable. Accessing and assigning variables like this are very easy and can be done from anywhere. In this case,
there is a global variable that stores the function to check if you are able to obtain a special weapon from the Mystery Box (think Ray Gun Mark 2, Time Bombs, etc.). Every map during bootup that has a custom
magicbox check function will store that function in `level.special_weapon_magicbox_check`. The `::` operator
during assignment is used to indicate that the function should be stored there. Later, the game can call that function by doing 
```
[[ level.speical_weapon_magicbox_check ]]();
```
This allows the game to dynamically call functions that may have custom logic between maps. The parenthesis outside of the `` [[ ]]`` would be the way to pass parameters into the function if it is required. We can take advantage of this by easily reassigning it to our custom function like so.

```
level.special_weapon_magicbox_check = ::our_custom_weight_func
```
Now we can define whatever custom logic we please in `our_custom_weight_func()`
It is highly recommended to do this in the `main()` of a custom script (It can be in a nested function within a `main()` if this tidies things up). 

Not all functions are this easy to replace however, but there is another method we can use.


### ReplaceFunc

Built into Plutonium by the Plutonium team is the ability to replace function pointers by using the `ReplaceFunc()` function. This function takes 2 parameters, the pointer to the old function, and a pointer to the new function. An example call would be like so:
```
replaceFunc( maps/mp/zombies/_zm_ai_leaper::leaper_round_tracker, ::leaper_round_tracker_override );
```
Here, we are replacing the round tracking function of the leapers (frogs, crawlers, jumping jacks, whatever you prefer to call them) with our own. Now, any call to `leaper_round_tracker()` will instead go to `leaper_round_tracker_override()`. It is important to make sure all parameters are the same in order to prevent argument/parameter mistatch errors. It is also important to make sure you add all the necessary `#includes` within your files.

#### Where ReplaceFunc() doesn't work

There are a handful of niche scenarios where `ReplaceFunc()` doesn't work. There is a brief overview of those scenarios [here](https://plutonium.pw/docs/modding/gsc/new-scripting-features/#replacefunc-specifics). If you encounter once while working on this project, we can try and assist you in finding a work around. Workarounds typically involve calling `replaceFunc()` on the function above it and copying most of the logic, but changing our desired call to our custom one. 

### Includes and Maintainability

In order to (try to) keep things organized, this project will likely split across multiple files. It will be important to make sure your includes are in order. All GSC files will typically have lots of includes. If you need to include from the base game because you have logic that depends on vanilla logic, you can simply do the following
```
#include maps/mp/zombies/script;
```
where `script` is the name (without the extension) of the script. An easy trick would be to include everything the the script you overrode a function in within the new gsc containing all our custom logic. If you need to include from a file within this project, you can do so like this
```
#include scripts/zm/.../.../script;
```
where `.../.../` denotes any directories you need to traverse in order to include the script. 

## Building 
Using VSCode is the easiest way to build. ALl you have to do is press `F1`, select "Run Build Tasks", select "build all testing", and everything automatically builds and install in `%localappdata%\Plutonium\storage\t6\scripts`
, press `F1` and run "Build all testing"

# Credits
5and5 - Coding