# The Hunting Lodge: A Wodehouse Tale

3D graphic novel adaptation of P.G. Wodehouse's pacifist couple corrupted by a hunting lodge's spirit.

## Features

- **Procedural 3D Environments**: Six scenes built from CSG geometry (arrival, great room, dining, gun room, moorland, dusk)
- **Hand-drawn FaceCard Characters**: Ink-rendered characters using the flipbook project's face extraction and generation pipeline
- **Character Corruption Arc**: Face rotation and posture animation showing moral decay across scenes
- **Dynamic Lighting**: Scene-specific presets with smooth transitions (golden hour, fireplace glow, candlelight, clinical white, dramatic moorland, dusk)
- **Dialogue System**: Wodehouse-voiced captions with precise timing
- **Keyboard Navigation**: Arrow keys to advance/retreat through scenes

## How It Works

**Scene Manager** (`hunting_lodge_scene_manager.gd`) orchestrates:
- Scene building via `HuntingLodge` (CSG models)
- Lighting via `HuntingLodgeLighting` (environment + directional + point lights)
- Character placement and corruption via `HuntingLodgeCharacter` (face rotation + posture)
- Camera positioning and dialogue playback

**Character Corruption**:
- Face angle rotates from neutral (0°) → curious tilt (18°) → profile (40°) → extreme profile (75°) → bowed shame (0°)
- Posture shifts from upright → stiffening → leaning → assertive → wild → collapsed
- Same drawn faces, different angles = visual corruption without new art

**Lighting Progression**:
- Scene 1 (Arrival): Golden hour, soft (0.6 ambient energy)
- Scene 2 (Great Room): Fireplace amber, intimate point lights (0.4 energy)
- Scene 3 (Dining): Candlelight, deep shadows (0.3 energy)
- Scene 4 (Gun Room): Overhead clinical white, sharp shadows (0.8 energy)
- Scene 5 (Moorland): Low golden sun, fog, dramatic (1.8 dir energy)
- Scene 6 (Dusk): Purple-blue sky, cool tones, desaturated (0.4 energy)

## Controls

- **RIGHT / D**: Next scene
- **LEFT / A**: Previous scene
- **R**: Reload current scene
- **ESC**: Quit

## Building

Requires Godot 4.4+

```bash
godot4 --path project --export-release web web/index.html
```

## Deployment

Deploy `web/index.html` and assets to a web server, or to Precog hub:

```bash
./build.sh
```

## Credits

- **Story & Dialogue**: P.G. Wodehouse (Mulliner Tales)
- **Character Faces**: Nathan's pen drawings (flipbook-field project)
- **Technical Direction**: Nathan Dunn
- **Implementation**: Claude Haiku 4.5
