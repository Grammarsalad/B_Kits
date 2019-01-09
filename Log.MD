# Log

TO DO 01: Unique spells will be implemented via the 'song mage' ability, which involves special 'song' books that can only be decipherable by bards. 

TO DO 02: Continue updating Bardsong descriptions

   - Change from "Bardsong" to "Performance".

TO DO 03: Update core and blade bardsongs as per the new instructions.  
   - Implement  cancel in move for blade.
   - Other? Compare
   
TO DO 04: Expand Bard Usability to match their 'use magic items' ability.  Allow them to cast in up to chain armor

TO DO 05: Revise counterspell in light of changes to Rally

TO DO 06: SKALD'S SONGS (make virtually permenant, but remove them on a delayed cast spell--doable?  If land a blow, give 6 second immunity to remove spell, but cast it on a 7 second delay. 

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
