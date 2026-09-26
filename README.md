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

Open `project/` in Godot 4.4 and press F5, or visit the deployed build.

Click, tap, Space, Enter or → to turn the page; ← (or tapping the left fifth of
the page) goes back; Home starts again. Twenty-eight pages.

## How a page is made

Every page is data in `scripts/story.gd`: which set, which light, where the
camera stands and what it looks at, who is in the shot — where, facing which
way, in what pose, wearing and holding what — and the lettering: narrator's
captions, speech balloons in reading order, sound effects. Pages are
self-contained, so paging backwards costs the same as forwards.

`scripts/main.gd` turns pages: wipe to paper, place the cast, ease the light,
frame the shot, letter it, wipe back. While a page is open the camera creeps a
few per cent toward its subject, so a still panel is never quite still.

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
- **Hands.** Poses are targets the paper doll eases toward in six drawn
  in-betweens: clasped hands on arrival, a gun carried in the gun-room, arms up
  on the moor, heads bowed on the steps.

## Lettering

`scripts/lettering.gd` draws everything printed on the page: the ink border and
paper margin (letterboxed on wide establishing shots), caption boxes, balloons
whose tails find the speaker's head every frame, jagged balloons for shouting,
sound effects, title plates and the folio. Balloons try above the speaker, then
beside, and will not sit on anybody's face or break reading order.

Type: Crimson Pro for the lettering, Gloock for titles and sound effects (both
SIL OFL, licences in `project/fonts/`).

## The sets

`scripts/sets.gd` builds all six from primitives — no editor-placed geometry:
the Angler's Rest, Bludleigh Court from the drive (with a 1920s tourer and a
stag for a door-knocker), the great hall (twenty-odd heads, two fish, a bear),
the dining room, the gun-room, and the moor (heather, a grouse butt, a copse, a
shot cloud). Each sits at its own spot along X; only the current one is shown.

## Checking the pages

```
xvfb-run -a godot4 --display-driver x11 --rendering-driver opengl3 \
  --path project -- --shots=/tmp/shots [--page=N]
```

renders every page (or page N) to PNG under the Compatibility renderer, which
is the one the browser uses, and quits.

## Build and deploy

`./build.sh` re-exports `web/` (Godot 4.4.1 plus web export templates) and
gzips the wasm and js for nginx's `gzip_static`. The Dockerfile serves `web/`
from nginx. Deployed on the Precog hub as `hunting-lodge`, the same way as
flipbook-field.

The export is built **without thread support** (`variant/thread_support=false`
in `export_presets.cfg`): Godot 4's threaded web export needs SharedArrayBuffer,
which is a documented upstream problem on macOS/iOS browsers (Chrome on macOS
routes WebGL through ANGLE's Metal backend) — the `WebGL context lost, please
reload` a reader ran into a few pages in was this, not our scene. `headers.caddy`
still sends COOP/COEP; they're harmless with a non-threaded build and cost
nothing to leave in.

Run `tools/install-hooks.sh` once after cloning. After that, every commit
touching `project/` or `build.sh` rebuilds `web/` and walks all 28 pages under
plain `--headless` (`--pagecheck`, no Xvfb needed — it catches a script error
or a bad page dictionary the same way the screenshot gate does, just without
needing a GPU), stages the rebuilt `web/`, and — on `main`, on a machine with
`/opt/scripts/deploy.sh` — pushes and redeploys in the background after the
commit lands. `SKIP_BUILD=1 git commit ...` skips the build; `SKIP_DEPLOY=1`
skips the push-and-deploy.
