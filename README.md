# Bludleigh

A 3D graphic novel in Godot 4.4. Two gentle poets visit a house that has been
killing things for four hundred years, and the house wins.

A loose adaptation of P. G. Wodehouse's *Unpleasantness at Bludleigh Court*
(*Mr Mulliner Speaking*, 1929): the premise and the people — Charlotte
Mulliner, Aubrey Bassinger, Sir Alexander and a family that talks of nothing
but what it has shot — told by Mr Mulliner in the bar-parlour of the Angler's
Rest. The dialogue is written fresh.

Spun out of [flipbook-field](https://github.com/nathandunn/flipbook-field): the
same toon shader and ink outlines, the same paper-doll figures, and the same
faces — Nathan's pen drawings. Charlotte wears the wavy hair with heavy bangs,
Aubrey the spiky hair and sunglasses.

## Read it

Visit the deployed book, or open `project/` in Godot 4.4 and press F5.

What is deployed is not the engine. Every page is a still, so `build.sh` renders
the book once, at 2560x1440 with 4x MSAA, to `web/pages/page_NN.webp` (~250 KB
a page, ~8 MB the lot), and `reader/index.html` turns them: no WebGL, no wasm,
nothing for a browser to lose. Godot 4's web export lost its WebGL context in
Safari a few pages in however small the scene was made; a folder of pictures
cannot.

Click, tap, Space, Enter or → to turn the page; ← (or tapping the left fifth of
the page) goes back; Home starts again. Twenty-eight pages.

## How a page is made

Every page is data in `scripts/story.gd`: which set, which light, where the
camera stands and what it looks at, who is in the shot — where, facing which
way, in what pose, wearing and holding what — and the lettering: narrator's
captions, speech balloons in reading order, sound effects. Pages are
self-contained, so paging backwards costs the same as forwards.

`scripts/main.gd` turns pages: place the cast, light, frame the shot, letter
it. Every page is a still, like a printed panel: nothing moves once it is up,
and the engine runs in low-processor mode so a still page isn't redrawn sixty
times a second. On a page with dialogue the camera rises (same angle) until the
speakers' heads sit below mid-panel, leaving headroom for the balloons — more
lines, more headroom.

## The transformation

Nothing about Charlotte and Aubrey's faces changes — they are the same four
drawings throughout. What changes is everything around them:

- **Shadows.** Every toon surface shares one shadow tint (`Ink.set_shadow_tint`).
  It starts a cool printer's purple at the Angler's Rest and on arrival, warms
  through the hall, goes claret at the moment Charlotte's poem turns, and is
  oxblood on the moor. At dusk it cools again.
- **Clothes.** The costumes are flipbook-field's pen-drawn office outfits, recast:
  the legal waistcoat and bow tie make a poet, the marketing turtleneck and
  scarf make a lady of letters, and the engineer's plaid, re-dyed, makes
  shooting tweeds. The lovers leave in their own clothes.
- **Hands.** Each page poses the paper doll: clasped hands on arrival, a gun carried in the gun-room, arms up
  on the moor, heads bowed on the steps.

## Lettering

`scripts/lettering.gd` draws everything printed on the page: the ink border and
paper margin (letterboxed on wide establishing shots), caption boxes, balloons
with tails to the speaker's head, jagged balloons for shouting, sound effects,
title plates and the folio. Each page is laid out once. Balloons go in comic
reading order — each one clearly below the one before it, or on the same row to
its right — and are placed by searching the whole panel for the clear spot
nearest the speaker: never on a face (the face cards' real on-screen extent),
a caption, another balloon or the folio. Early lines on a busy page are pulled
to the top so the replies have room. The `--shots` render prints a `LAYOUT`
line for any page that breaks those rules.

Type: Crimson Pro for the lettering, Gloock for titles and sound effects (both
SIL OFL, licences in `project/fonts/`).

## The sets

`scripts/sets.gd` builds all six from primitives — no editor-placed geometry:
the Angler's Rest, Bludleigh Court from the drive (with a 1920s tourer and a
stag for a door-knocker), the great hall (twenty-odd heads, two fish, a bear),
the dining room, the gun-room, and the moor (heather, a grouse butt, a copse, a
shot cloud). Each sits at its own spot along X; only the current one is shown.

## Running the engine in a browser

Not done any more (see above), but the project still runs in Godot and, if
exported, keeps a browser's GPU budget in mind: the 3D picture renders at no
more than ~2 megapixels (`RENDER_BUDGET` in `main.gd`), MSAA is 2x, only the
current set and the previous one are built at a time, and lettering sizes come
off a short ladder (`Lettering.SIZES`). `--memcheck` (under Xvfb, opengl3)
reads the book forward, back and forward again printing video memory after
every page. The Web export preset is non-threaded, which Safari needs.

## Checking the pages

```
xvfb-run -a godot4 --display-driver x11 --rendering-driver opengl3 \
  --path project -- --shots=/tmp/shots [--page=N] [--webp=90]
```

renders every page (or page N), prints a `LAYOUT` line for any balloon out of
reading order or over a face, caption or another balloon, and quits.
`--pagecheck` walks every page under plain `--headless` (no display needed)
and catches script errors.

## Build and deploy

`./build.sh` prints the book: it renders every page to `web/pages/` (needs
`xvfb-run` and Mesa — `apt install xvfb libgl1-mesa-dri`), fails if the render
reports a script error or a layout problem, and writes `reader/index.html` to
`web/index.html` with the page count filled in. The Dockerfile serves `web/`
from nginx. Deployed on the Precog hub as `hunting-lodge`, the same way as
flipbook-field.

Run `tools/install-hooks.sh` once after cloning. After that, every commit
touching `project/`, `reader/` or `build.sh` reprints the book (the render is
the gate), stages `web/`, and — on `main`, on a machine with
`/opt/scripts/deploy.sh` — pushes and redeploys in the background after the
commit lands. `SKIP_BUILD=1 git commit ...` skips the print; `SKIP_DEPLOY=1`
skips the push-and-deploy.
