# Soma - Turing Machine-Style Scale Sequencer

A stochastic sequencer for the disting NT that does the Turing Machine thing with exotic scales.

Named after the mysterious drink from "Brave New World" - creates patterns that feel both random and intentional, somewhere between chaos and order.

## What It Does

Soma generates patterns that mutate based on probability controls - like a Turing Machine. The twist is it weights "spicy" notes higher - the ones that make each scale sound different from major.

## How It Works

### Pattern Evolution 
- **Note Pattern**: Sequence that mutates or locks
- **Gate Pattern**: Gates that evolve independently  
- **Probability**: Controls mutation rate
  - **100%** = Constant change
  - **50%** = Gradual evolution
  - **0%** = Locked

### The Spicy Notes Thing
Compares each scale to major and gives 3x weight to notes NOT in the major scale. These characteristic notes define each scale's flavor:

- **Phrygian**: ♭2, ♭6, ♭7 get emphasized
- **Lydian**: That #4 shows up more
- **Hungarian Minor**: ♭2, #4, ♭6 come through

Patterns naturally emphasize what makes each scale unique.

## Controls

### Pots
- **1**: Note mutation % (0=locked, 100=chaos)
- **2**: Gate mutation % (0=locked, 100=chaos)
- **3**: Octave spread % (0=none, 100=3 octaves)

### Encoders
- **1**: Scale selection (21 scales)
- **2**: Root note (C-B)

### Parameters
- **Length**: 1-64 steps

## I/O
- **In 1**: Clock
- **In 2**: Reset
- **Out 1**: Gate
- **Out 2**: Pitch CV (1V/oct)

## Usage Tips

### Finding Sweet Spots
Start with high probability (70-90%) to generate interesting patterns, then gradually reduce to lock in patterns you like.

### Scale Morphing
- Lock a pattern at 0%
- Switch to a different scale  
- Slowly increase probability to hear it morph
- Lock it again when it sounds good

### Rhythmic Combos
- Low note %, high gate % = stable melody, evolving rhythm
- High note %, low gate % = evolving melody, stable rhythm

### Octave Dynamics
Small amounts (10-30%) add variation without losing the melodic line.

## Experiments to Try

### The Conversation
Run two Somas at different clock divisions (one at 1/4, one at 1/3). Set them to complementary scales (like Dorian and Lydian). Use low probability (~15%) so they slowly diverge from similar starting points.

### Ghost in the Machine  
Set note probability to 1-2% - just enough that you occasionally hear a "mistake" that becomes part of the pattern. Like a musician occasionally hitting a wrong note that sounds right.

### The Degrading Loop
Start with a locked pattern you like. Add just 3-5% probability and let it run for 10 minutes. It's like a tape loop slowly deteriorating, occasionally glitching into something new.

### Call and Response
Use Reset input rhythmically (not just at pattern start). Feed it a euclidean rhythm. The pattern keeps getting pulled back to step 1, creating phrases that mutate but keep returning home.

### Probability Surfing
Instead of tweaking knobs, CV control the probability inputs with slow LFOs. The pattern locks and unlocks cyclically, breathing between order and chaos.

### Scale Automation
Keep probability at ~40% but sequence through scales via encoder. Each scale change is like a harmonic filter being swept - the pattern reshapes itself to the new harmonic space.

### The Octave Scatter
Gate probability at 0%, note probability at 0%, but octave at 100%. Same notes, same rhythm, but huge registral leaps. Run through a resonant filter that tracks pitch for wild timbral changes.

### Binary Beats
Set gate probability high (80%) but note probability at 0%. You get evolving rhythms with a repeating melodic motif - techno generators.

## Technical Bits

The weighted probability thing ensures each scale sounds like itself. The Turing Machine behavior creates organic evolution. It's that balance between random and intentional that makes it musical.