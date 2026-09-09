# Kids Game UI Kit

A game-ready UI asset pack in the style of the screens you shared: chunky rounded
cards with a 3D bottom edge, white outlines, bright candy colours, soft shadows.

**These are original assets, drawn from scratch to match the palette and shape
language of your mockup.** They are yours to use and modify in your game.

---

## What's inside

```
tokens/       design-tokens.json + tokens.css  (colours, radii, shadows, sizes)
ui/           buttons, answer tiles, operator tiles, round icon buttons
cards/        category cards (Letters / Numbers / Shapes / Animals) + blank panels
map/          level nodes (locked / current / complete), banner ribbon, path, chest
hud/          coin pill, hearts pill, progress bars, avatar frame, star badge, toasts
icons/        16 flat icons (home, games, awards, profile, map, store, etc.)
nav/          bottom navigation bars
backgrounds/  full-screen 390×844 gradients (sky, sunny, map, app)
png/          every asset rasterised at @1x, @2x, @3x
preview.html  open in a browser to see the whole pack
```

- **SVG** = the source. Scale to any size, recolour by editing the fill.
- **PNG** = drop-in for Unity / Godot / React Native / Flutter.
  Use `@2x` for most phones, `@3x` for high-density screens.

## Colours

Eight brand colours, each with a base / shade / tint. The **shade** is what
creates the 3D bottom edge, the **tint** is the glossy highlight strip on top.

| | base | shade | tint |
|---|---|---|---|
| yellow | `#FBBD0C` | `#D9970A` | `#FFD75E` |
| green  | `#5FBE41` | `#489030` | `#8FDD6E` |
| purple | `#9C69D3` | `#7A47B0` | `#C39CEA` |
| blue   | `#3A8BE8` | `#2A6ABC` | `#7CB6F5` |
| pink   | `#FA7697` | `#D24F70` | `#FFA8BF` |
| orange | `#F59323` | `#C9740F` | `#FFB861` |
| teal   | `#2FC2C7` | `#219A9E` | `#79E0E3` |
| indigo | `#6561B9` | `#4941A5` | `#9A96D8` |

Text/ink: `#3B2E5A`. Muted text: `#8C86A8`.

## Font

No font file ships here (licensing). The pack is designed for a rounded
display face — **Fredoka**, **Baloo 2**, or **Nunito** (all free on Google
Fonts) all fit. Install one and the SVG text will render as intended.

## How to recolour a button

Open any `ui/button-*.svg`. There are three fills in the block:

1. the lower rect = **shade** (the 3D edge)
2. the upper rect = **base**
3. the small rounded strip = **tint** (the gloss)

Swap those three hex values for another row of the table above.

## Making the buttons feel right

- Minimum tap target is **64 px** — young children need big targets.
- On press, move the top rect down by the depth value (8 px for buttons,
  10 px for tiles) and shrink the shade rect. That's the whole "squash" effect.
- Correct answer → `hud/toast-correct.svg`, wrong → `hud/toast-wrong.svg`.

---

## What is NOT in this pack

The **character illustrations** — the boy, the elephant, the dog, the bear
cub, the 3D landscape islands. Those are painted 3D character art, and they're
the one thing that can't be rebuilt as vector UI. You have three options:

1. Commission an illustrator for a small character set (cheapest per-character
   if you brief them with this kit's palette).
2. Buy a matching 3D-cartoon character pack from an asset marketplace.
3. Generate them, then have an artist clean up and unify the style.

Also note: **don't ship the mockup image itself**. If it came from a
designer, a template site, or an AI generator, the characters in it may carry
usage terms you'd need to check. This kit avoids that problem entirely for the
UI layer.
