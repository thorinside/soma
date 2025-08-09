# disting NT Lua Scripting Quick Reference

## Core Concepts
The disting NT runs Lua 5.4.6 scripts for custom algorithms and UI control. Scripts interact with audio/CV buses (28 total) at 1ms intervals.

## Lua Script Algorithm Structure

```lua
-- Script Name
-- Description of what the script does

local myVariable = 0  -- script-local variables

return {
    name = 'Algorithm Name',
    author = 'Your Name',
    
    init = function(self)
        -- Called once on load
        return {
            inputs = 2,  -- 0-28
            outputs = 2,  -- 0-28
            -- OR for specific types:
            inputs = {kCV, kTrigger, kGate},
            outputs = {kStepped, kLinear},
            
            -- Optional custom names
            inputNames = {[1]="Pitch", [2]="Gate"},
            outputNames = {"Audio Out", "Envelope"},
            
            -- Optional parameters
            parameters = {
                {"Param Name", min, max, default, kVolts},
                {"Scale Param", -100, 100, 0, kVolts, kBy10},
                {"Choice", {"Option1", "Option2"}, 1}
            }
        }
    end,
    
    step = function(self, dt, inputs)
        -- Called every 1ms
        -- dt = time delta in seconds
        -- inputs = array of input voltages
        local output1 = inputs[1] * 2
        local output2 = math.sin(myVariable)
        return {output1, output2}  -- return output voltages
    end,
    
    -- Optional: handle triggers/gates efficiently
    trigger = function(self, input)
        -- input = which input triggered (1-based)
        return {5.0}  -- return outputs to update
    end,
    
    gate = function(self, input, rising)
        -- rising = true for gate open, false for close
        return {rising and 5.0 or 0.0}
    end,
    
    -- Optional: custom display
    draw = function(self)
        drawText(100, 40, "Custom Display")
        -- Return true to hide parameter line
    end,
    
    -- Optional: custom UI controls
    ui = function(self) return true end,
    pot1Turn = function(self, value) end,  -- value 0.0-1.0
    encoder1Turn = function(self, delta) end,  -- delta ±1
    
    -- Optional: save/load state
    serialise = function(self)
        return {myData = 42}  -- JSON-compatible data
    end,
    
    -- Optional: MIDI
    midi = {
        channelParameter = 1,  -- which param selects MIDI channel
        messages = {"note", "cc", "bend"}
    },
    midiMessage = function(self, message)
        -- message is array of MIDI bytes
    end
}
```

## Input/Output Types
- `kCV` - Continuous voltage
- `kGate` - Gate detection (calls gate function)
- `kTrigger` - Trigger detection (calls trigger function)
- `kStepped` - Stepped output (default)
- `kLinear` - Linearly interpolated output

## Parameter Units
`kNone`, `kDb`, `kPercent`, `kHz`, `kSemitones`, `kCents`, `kMs`, `kSeconds`, `kVolts`, `kBPM`

## Parameter Scales
`kBy10`, `kBy100`, `kBy1000` - Divides min/max/default for float handling

## Key Global Functions

### Algorithm/Parameter Control
```lua
findAlgorithm("Name") -- returns algorithm index
findParameter(alg, "Param Name") -- returns parameter index
getParameter(alg, param) -- get value
setParameter(alg, param, value, focus) -- set value
setParameterNormalized(alg, param, 0.0-1.0, focus)
getCurrentAlgorithm()
getCurrentParameter(alg)
focusParameter(alg, param)
```

### Drawing (256x64 pixels, 0-15 brightness)
```lua
drawText(x, y, "text", color)
drawTinyText(x, y, "text")
drawLine(x1, y1, x2, y2, color)
drawRectangle(x1, y1, x2, y2, color) -- filled
drawBox(x1, y1, x2, y2, color) -- outline
drawCircle(cx, cy, radius, color)
drawSmoothLine(x1, y1, x2, y2, color) -- antialiased
drawStandardParameterLine() -- standard param display
drawParameterLine(alg, param, yOffset)
drawAlgorithmUI(alg)
```

### System Functions
```lua
getBusVoltage(alg, bus) -- read bus voltage
sendMIDI(dest, byte1, byte2, byte3) -- dest: 0x1=breakout, 0x2=select, 0x4=USB, 0x8=internal
exit() -- exit UI script
getCpuCycleCount() -- performance timing
```

### UI Script Functions
```lua
standardPot1Turn(value) -- call standard pot behavior
standardPot2Turn(value)
standardPot3Turn(value)
```

## self Table
- `self.parameters[]` - array of current parameter values (read-only)
- `self.parameterOffset` - offset between system and script parameters
- `self.state` - loaded serialised data (available in init)
- Custom members can be added for state storage

## Best Practices
1. Use local variables for script-scoped data
2. Use self table for instance data
3. Prefer trigger/gate functions over polling in step
4. Return sparse output tables when possible
5. Handle MIDI efficiently with filtering
6. Keep draw functions fast (30fps)
7. Use kLinear for smooth CV, kStepped for gates/triggers

## File Locations
- Scripts: `/disting/algorithms/`
- Libraries: `/programs/lua/lib/`
- UI Scripts: `/disting/ui_scripts/`

## Common Patterns

### LFO Example
```lua
local phase = 0
return {
    name = 'LFO',
    init = function(self)
        return {inputs = 1, outputs = {kStepped, kLinear}}
    end,
    step = function(self, dt, inputs)
        local freq = 1 + inputs[1]
        phase = (phase + dt * freq) % 1.0
        local square = phase > 0.5 and 5.0 or -5.0
        local triangle = 10 * math.min(phase, 1-phase) - 5
        return {square, triangle}
    end
}
```

### Parameter Control
```lua
init = function(self)
    return {
        parameters = {
            {"Speed", 0.1, 10, 1, kHz},
            {"Depth", 0, 100, 50, kPercent}
        }
    }
end,
step = function(self, dt, inputs)
    local speed = self.parameters[1]
    local depth = self.parameters[2] / 100
    -- use parameters...
end
```

## Notes
- Lua instance is shared across all scripts
- 1ms step timing (1000Hz update rate)
- Voltages typically ±5V or ±10V range
- Display updates at 30fps
- CPU cycle counter overflows every ~7 seconds
