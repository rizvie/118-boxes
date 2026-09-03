# Elementary

A periodic table quiz for a six-year-old. Show a symbol, tap the right name.
Every element has a picture of what the stuff actually looks like, and the
names get read out loud, because he can read but he's never heard "magnesium".

## The three rounds

- **What's this symbol?** The symbol is the question ("Mg"), four names to
  choose from. A picture of the sample sits underneath as a clue, which can be
  turned off in Settings to make it harder.
- **What is this stuff?** The picture is the question. Wrong answers are picked
  so they look different from the right one, otherwise it's a coin toss.
- **Find the symbol** The name is the question, four symbols to choose from.

Ten questions a round, then a score out of ten and up to three stars. Anything
he gets wrong is listed at the end with its picture.

## The pictures

Nothing is downloaded and nothing is bundled. Every sample is drawn in SwiftUI
from three things about the element: its colour, its state at room temperature,
and the shape a real sample comes in.

| Form | Looks like | Who gets it |
|---|---|---|
| chunk | irregular lump | iron, sodium, most rare earths |
| ingot | cast bar with a bevelled top | gold, silver, aluminium, tin |
| pellets | little beads | calcium, nickel, zinc |
| powder | a settled heap with specks | sulfur, carbon, selenium |
| crystal | faceted cluster | iodine, silicon, bismuth |
| wire | a coil with a loose end | copper, magnesium |
| pool | droplets and a puddle | mercury, bromine |
| cloud | drifting glow | hydrogen, oxygen, chlorine |
| tube | glowing discharge tube | the noble gases |
| shard | glowing, with a pulsing ring | anything radioactive |

Metals get a hard sheen, everything else stays matte. The lump shapes come from
a seeded random number generator keyed to the atomic number, so an element
always draws itself the same way.

Well-known elements have their form pinned by hand in `ChemElement.knownForms`
(copper as wire, gold as a bar, sulfur as yellow powder). Everything else is
derived from its family and atomic number.

## Which elements come up

All 118, from the first round. Nothing is locked. The picker just weights
things: anything he hasn't met yet comes up more often, anything he's already
learned comes up less, and the first 36 get a nudge because that's where the
familiar ones live. That weighting is `QuizEngine.buildRound`, if you want to
change it.

An element counts as **learned** after three correct answers. Progress is
stored on the device with SwiftData.

## Explore

The Explore screen has the real table, colour-coded by family and scrollable
sideways, plus a searchable list. Tapping any element opens its picture, its
fact, and a "Say it" button. Learned elements show brighter on the table.

## Settings

- Sound effects on/off
- Read names out loud on/off (Australian voice)
- Show the picture as a clue on/off
- Reset progress

## Build & run

Requires Xcode and [XcodeGen](https://github.com/yonyz/XcodeGen)
(`brew install xcodegen`).

```sh
cd Elementary
xcodegen generate      # regenerates Elementary.xcodeproj from project.yml
open Elementary.xcodeproj
```

Then pick a simulator or a connected iPhone and hit run.

The app icon is generated: `python3 scripts/make_icon.py`.

## Adding to the facts

All the element data is one array in `Sources/Models/ElementData.swift`. Each
row is atomic number, symbol, name, family, state, colour and the one-sentence
fact. Facts are written for an early reader: one short sentence, ideally
something he could point at in the real world.
