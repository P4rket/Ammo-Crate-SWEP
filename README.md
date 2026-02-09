# Ammo-Crate-SWEP
This addon adds a portable ammo crate that replenishes your ammunition based on the weapon you're holding. It works best with weapons using standard ammo types but will also resupply custom ammo from other addons.

# What, when and why?

lua/autorun/client/ammo_crate_menu.lua
- Default types of ammo, that can't be removed
- All configuration menu logic (buttons, titles, messages, UI sounds)
- Admin validation for saving changes

lua/autorun/server/server_validation.lua
- Creates ammocrate_limits.txt in data folder and filling by default values
- Admin validation for using "ammocrate_menu" command

lua/entities/entity_ammo_crate.lua
- Visual of crate entity
- Ground lifetime (60 second by default)
- Checks for amount of ammo player has

lua/weapons/weapon_ammo_kit.lua
- Visual of crate in hands (First and third person)
- Usage logic
- Recarge speed


Feel free to make additions or changes and reupload in workshop
