<h1 align="center">Portal</h1>

<p align="center">
  <a href="https://www.youtube.com/watch?v=sb2x-6PJXL4"><img src="https://img.youtube.com/vi/sb2x-6PJXL4/maxresdefault.jpg" alt="Watch on YouTube" width="600"></a>
</p>

## 📝 Description
This plugin adds a fully dynamic Portal system to Counter-Strike 1.6.
Portals can be placed, managed and configured during gameplay with runtime control over visibility, team access, activation states and teleport destinations.
- Create and remove portals during gameplay via an in-game menu
- Two-part portal system with a base entry point and a configurable destination
- Configurable per portal: team access, animation speed and spawn chance
- Delayed and timed activation with random ranges for round-based gameplay
- Optional cooldown before a portal becomes active again
- Optional DLight and teleport sound effects on activation
- Optional reverse activation for inverted portal behavior
- Optional "Players Only" restriction to limit teleportation to players
- Dynamic portal rotation and natural ghost preview placement
- Custom portal setups are saved per map and automatically loaded on every map start

## 💬 Commands
- `say /portal` - Opens the Portal menu.
- `say_team /portal` - Opens the Portal menu.
- `portal_reload` - Reloads the configuration file.

## ⚙️ Configuration
```ini
# Per-portal settings (defined under each [Portal Name] section):
# PORTAL_FLAGS               = a - Active Delay     b - Active Duration     c - DLight              d - Sound              e - Cooldown            f - Random            g - Players Only
# PORTAL_TEAM                = 0 - None             1 - Terrorist           2 - Counter-Terrorist   3 - Both
# PORTAL_FRAMERATE           = Portal's animation speed
# PORTAL_SPAWN_CHANCE        = Portal's respawn probability (0.0 - 1.0)
# PORTAL_ACTIVE_DELAY        = Minimum and maximum activation delay after round start
# PORTAL_ACTIVE_DURATION     = Minimum and maximum active state duration
# PORTAL_ACTIVE_COOLDOWN     = Minimum and maximum cooldown before reactivation
# PORTAL_SPRITE_FRAMERATE    = Sprite animation speed
# PORTAL_SPRITE_SCALE        = Sprite scale (1.0 = normal size)
# PORTAL_SPRITE_ALPHA        = Sprite transparency (0 - 255)
# PORTAL_SPRITE_COLOR        = Sprite color (RGB values 0 - 255)
# PORTAL_DLIGHT_RADIUS       = DLight radius
# PORTAL_DLIGHT_COLOR        = DLight color (RGB values 0 - 255)
# PORTAL_COOLDOWN            = Cooldown in seconds before the portal can be used again
# PORTAL_SOUND_AMBIENT       = Ambient sound to play when the portal is active
# PORTAL_SOUND_TELEPORT      = Sound to play when a player uses the portal
```

## 🔄 Changelog
```text
* v1.0: Initial release.
```
