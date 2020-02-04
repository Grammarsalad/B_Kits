# Log

TO DO 01: Unique spells will be implemented via the 'song mage' ability, which involves special 'song' books that can only be decipherable by bards. 

TO DO 02: Continue updating Bardsong descriptions and bard class and kit descriptions

TO DO 03: Update core and blade bardsongs as per the new instructions.  
   - Implement  cancel in move for blade.
   - Other? Compare
   
TO DO 04: Allow them to cast in up to chain armor for bards

TO DO 05: Add race access to bard class

TO DO 06: SKALD'S SONGS (make virtually permenant, but remove them on a delayed cast spell--doable?  If land a blow, give 6 second immunity to remove spell, but cast it on a 7 second delay. 

TO DO 07:

TO DO 08: Add unique portrait icons for Bard Performances (rally, countersong, countersong spell protection, weapon display,

TO DO 09: Disable bardsong (and cancel existing bardsongs?) if character becomes fatigued

TO DO 10: Finish Unique Spell Selection

TO DO 11: Song Magic!  Innates that cast instead of arcane spells that the bard can use to change bardsong and create additional effects (Radical!)

TO DO 12: Blade: see if slash damage can be changed based on weilded weapons.  It can.  Created splplot entries.  Need to actually have weapons apply the splstate and then modify the Defensive Spin/Weapon Display to apply by entry

TO DO 13: Create 'add on' components (Performance fatigue for bard/shaman--seperate from reg songs; spontaneous casting for cleric/druid; ... )

TO DO 14: Figure out the ini stuff so users can dynamically choose which extra class feature they want to install

TO DO 15: All classes can search (GIVE BUTTON TO ALL CLASSES THAT DON'T HAVE IT!!)

TO DO 16: Add an option to replace domain spells with spontaneous casting. 

TO DO 17: Add 'extra' component to limit clerics to chain mail

TO DO 18: Add 'extra' component to 'expand' cleric weapon training to all 'simple' weapons

TO DO 19: COMPATIBILITY: IFF Performance skill installed, reduce fatigue cost for performance for bards/shamans in both fatigue code and performance code

TO DO 20: Maybe give performance skill to shamans, too...

TO DO 21: Complete Barter Skill

TO DO 22: do Variant attribute boni for thief skills component

TO DO 23: Finish Use Scroll skill

TO DO 24: Spon Casting for Druids/Cleric: Detect if EEEx is installed and use their method instead if so

TO DO 25: Check war_tools.tph for compatibility with wiz identify alternate (also finish tools of war--add check armor version for lev 5--I mean with 326).

TO DO 26: Maybe change tools of war so it only works if you have prof with weapon.

Version 0.02.00

2020-01-25

- A lot of work on revised fighter (text)

- Tools of War first draft

2020-01-18

- Started Kensai Ki Focus spl

2019-12-04

- Continued work on component skeleton

2019-12-03

- Updated kit.tp2 with additional skill based components

Version 0.01.16

2019-12-01

- Checking readme

2019-09-06

- Updated mage scroll use using qd_multi

2019-09-03

- Use Scroll: changed stat 2002 to use base as original use no longer needed, and added to mage (though, check base mage, wildmage and sorcerer)

- Use Scroll: 1st part of usability 

- Added splprot_scrolls.tpa 

Version 0.01.15

2019-08-31

- Updated Use Scroll to actually check level (seems to work)

2019-08-28

- Added Use poison and Use scrolls skills (using updated code for adding new skills)

- Changed around a few components (i.e. sep everybody can search and var skill bonuses from new skills)

Version 0.01.14

2019-07-28

- Added beginning of barter skill

- Created bare bones variant attribute bonuses to skills component

- Externalized backup folder

- Changed extendskill.tpa to make it compatible with multiple added skills (hopefully!)

2019-07-27

- Moved Bardic Knowledge/Perform to Class Skills

- Started bard skill component

- Started thief skill component (and started use scroll skill)

2019-07-25

- Added ExtendedSkills.tpa

- Added (first draft) set natural snares (EEex version) to rangers 

- Reverted EEex set natural snares text display for rangers (not plausible as it must ALSO increment set traps which will also be available as a skill)

- Added Bardic Knowledge (Full credit to OlvynChuru) --EEEx seems bugged.  Wait for official release to report (may get fixed)

Version 0.01.13

2019-04-11

- Started Fighter Stance Selection

- First draft: Reckless Onslaught

Version 0.01.12

2019-03-26

- Added extra fatigue options (everybody gets fatigued and barb/berserk get fatigued)

- Organized Tra refs

- Added a more direct check for spon cast

Version 0.01.11

2019-03-13

- Added All can search component

- Gave all classes/kits a base 5% Search

2019-03-09

- Added Rage and Enrage Fatigue

Version 0.01.10

2019-03-02

- Started unique spells (damn, what a pita!) 

- More effecient groupings (class revisions and 'extras') 

- Incorporated Charisma Turn Bonus

- Incorporated Pecca's Spontaneous Casting (hopefully)

- Added (the beginnings of) a Readme

- Added SR compatibility (esp for Spon casting)

Version 0.01.09

2019-01-26

- Seperated Fatigue from bard modification into bard extra

2019-01-23

- Set up skeleton for rest of classes and 'extras'

Version 0.01.08

2019-01-21

- Created skeleton for Cleric Kits (may have a conservative, and radical version)

- Slight reorganizing

2019-01-20

- Created splprot entries for TO DO 12.  Need to actually have weapons apply the splstate and then modify the Defensive Spin/Weapon Display to apply by entry

- Created skeleton for Thief (conservative version).  

- THief: HP to d8

2019-01-19

- Started Ranger Revision (Conservative)

- Cleaned up the Bard Revision 

2019-01-17 to 18

- Update action bar and bard thieving button for new EEEx

2019-01-15

- First draft of Offensive Spin

Version 0.01.07

2019-01-13

- Started Blade.  Basic Weapon Display completed.

- First draft of Defensive Spin

Version 0.01.06

2019-01-12

- Remove prot from opcodes in countersong, and replace with removal (so in line with description)

- Finished Countersong(?) 

- Removed Fascinate

- Implemented cancelled Rally for movement

- Implement 50% move for bard singing countersong

- Finished conservative bard song (+/-)

- Reimplemented Fascinate aaaaannnd...done with the base bard +/-

2019-01-11

- Tested Install and quick play bard in BG2EE.  Song doesn't seem to work as it's supposed to.  Rally and countersong seemed to have no effect on movement.  

- Added missing bams (i.e. missing in non-IWDEE games)

- Added Fatigue cost for Bard songs

- Probably fixed an issue with countersong that was removing saves from allies

- Changed bard song to performance notifications for all engines

Version 0.01.05

2019-01-08

- More code for Bards iff EEEx is installed

2019-01-07

- Setup basic skeleton for tp2

- Started all_bard.tpa (in lib folder)
  --to change 'bard song' to 'performance' notification
  --if EEEx installed, add button functionality, and skill progression for pick lock (yes, even for conservative)


Version 0.01.04

2018-10-08

- Added gitignore

2018-07-26

-Upgraded Weidu to v246

2018-07-17

- 1st level countersong ability

- Modified countersong, and changed #BARD4 accordingly

2018-07-16

- Started Countersong

Version 0.01.03

2018-07-14

- Further refined Rally.

- Revised descriptions to mirror rally.

- Added effect batches because of countersong, but need to actually modify effect batches (do in B_SPELLS).

2018-07-12

- Barred necromancy, conjuration, alteration, and evocation from Bardkit flags

- Updated description of core bard

- Replaced Blade with Bard (again).  Need to create most of the song spls and unique spells

- Finished Rally

Version 0.01.02

2018-07-10

- Tidied up the tra and desc of base bard and blade.

- Added OHVRPO.pro for standard bard song

- Added pro to SPCL120.spl (if not already there)

- Updated 1st lev delay spl (2 hrs instead of 8)

- Added move penalty to bardsong

- Modified bard spell progression and copied table over (lazy, I know)

- Modified blade's proficiencies so I can implement specialization as described (i.e. 2 weapons max)

Version 0.01.01

2018-07-08

- Rad Bard: Created first level rally

Version 0.01.00

2018-07-07

- Started creating the mod using fnp as a base.

- Tested and fixed a few bugs so installs

- Bard: Radical version: eliminated base kit from selection

- Bard: radical Version: Created replacement base bard class and blade skeletons

- Created descriptions for bard and blade.  Need to spellcheck and actually implement.
