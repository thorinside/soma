-- Soma — Stochastic Exotic Scale Sequencer
-- Custom UI: one page with live-editable params

local major = { 0, 2, 4, 5, 7, 9, 11 }

local noteNames = { "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B" }

local scales = {
    { name = "Ionian (Major)", notes = { 0, 2, 4, 5, 7, 9, 11 } },
    { name = "Dorian", notes = { 0, 2, 3, 5, 7, 9, 10 } },
    { name = "Phrygian", notes = { 0, 1, 3, 5, 7, 8, 10 } },
    { name = "Lydian", notes = { 0, 2, 4, 6, 7, 9, 11 } },
    { name = "Mixolydian", notes = { 0, 2, 4, 5, 7, 9, 10 } },
    { name = "Aeolian (Minor)", notes = { 0, 2, 3, 5, 7, 8, 10 } },
    { name = "Locrian", notes = { 0, 1, 3, 5, 6, 8, 10 } },
    { name = "Major Flat-6", notes = { 0, 2, 4, 5, 7, 8, 11 } },
    { name = "Minor Flat-6", notes = { 0, 2, 3, 5, 7, 8, 10 } },
    { name = "Lydian Sharp-4", notes = { 0, 2, 4, 6, 7, 9, 10 } },
    { name = "Hungarian Minor", notes = { 0, 2, 3, 6, 7, 8, 11 } },
    { name = "Persian", notes = { 0, 1, 4, 5, 6, 8, 11 } },
    { name = "Byzantine", notes = { 0, 1, 4, 5, 7, 8, 11 } },
    { name = "Enigmatic", notes = { 0, 1, 4, 6, 8, 10, 11 } },
    { name = "Neapolitan Minor", notes = { 0, 1, 3, 5, 7, 8, 11 } },
    { name = "Hirajoshi", notes = { 0, 2, 3, 7, 8 } },
    { name = "Iwato", notes = { 0, 1, 5, 6, 10 } },
    { name = "Pelog (approx)", notes = { 0, 1, 3, 7, 10 } },
    { name = "Ryo (Japan)", notes = { 0, 2, 4, 7, 9 } },
    { name = "Ritsu (Japan)", notes = { 0, 2, 5, 7, 9 } },
    { name = "Yo (Japan)", notes = { 0, 2, 5, 7, 10 } },
}

-- Create scale names array for parameter definition
local scaleNames = {}
for i, scale in ipairs(scales) do
    scaleNames[i] = scale.name
end

local current_step = 0
local note_pattern = {}  -- Stores note indices for each step
local gate_pattern = {}  -- Stores gate states (true/false) for each step
local probabilities = {}  -- Probability weights for scale notes
local output_table = { 0.0, 0.0 }  -- Reusable output table to avoid allocations
local weights_cache = {}  -- Reusable weights table to avoid allocations

local OCTAVE_PARAM = 1
local SCALE_PARAM = 2
local ROOT_PARAM = 3
local NOTE_PROB_PARAM = 4
local GATE_PROB_PARAM = 5
local LENGTH_PARAM = 6

local function compute_probabilities(scale)
    -- Clear and reuse existing weights table
    for i = 1, #weights_cache do
        weights_cache[i] = nil
    end

    local total = 0
    for i, n in ipairs(scale) do
        local is_char = true
        for _, m in ipairs(major) do
            if m == n then
                is_char = false
                break
            end
        end
        local w = is_char and 3 or 1
        weights_cache[i] = w
        total = total + w
    end

    -- Clear and reuse existing probabilities table
    for i = 1, #probabilities do
        probabilities[i] = nil
    end

    for i, w in ipairs(weights_cache) do
        probabilities[i] = w / total
    end
    return probabilities
end

local function weighted_pick(scale, probabilities)
    local r = math.random()
    local accum = 0
    for i, p in ipairs(probabilities) do
        accum = accum + p
        if r <= accum then
            return scale[i]
        end
    end
    return scale[#scale]
end

local function initialize_patterns(scale, probabilities, length)
    -- Clear existing note pattern and resize
    for i = length + 1, #note_pattern do
        note_pattern[i] = nil
    end
    for i = 1, length do
        note_pattern[i] = weighted_pick(scale, probabilities)
    end

    -- Clear existing gate pattern and resize
    for i = length + 1, #gate_pattern do
        gate_pattern[i] = nil
    end
    for i = 1, length do
        gate_pattern[i] = math.random() > 0.5
    end
end

return {
    name = "Soma",
    author = "Neal + ChatGPT",

    init = function(self)
        -- math.randomseed(getCpuCycleCount())  -- Not available in emulator

        -- Initialize patterns and probabilities with default values
        local initial_scale = scales[1].notes
        local initial_length = 8
        probabilities = compute_probabilities(initial_scale)
        initialize_patterns(initial_scale, probabilities, initial_length)

        return {
            inputs = { kGate, kTrigger },
            inputNames = { [1] = "Clock In", [2] = "Reset" },
            outputs = { kStepped, kLinear },
            outputNames = { [1] = "Gate Out", [2] = "Pitch CV" },
            parameters = {
                { "Octave Spread", 0, 100, 50, kPercent },
                { "Scale", scaleNames, 1 },
                { "Root", 0, 11, 0, kMIDINote },
                { "Note Prob %", 0, 100, 70, kPercent },
                { "Gate Prob %", 0, 100, 80, kPercent },
                { "Length", 1, 64, 8 },
            }
        }
    end,

    gate = function(self, input, rising)
        if input == 1 and rising then
            local scale_idx = self.parameters[SCALE_PARAM]
            local scale = scales[scale_idx].notes
            local root = self.parameters[ROOT_PARAM]
            local note_prob = self.parameters[NOTE_PROB_PARAM] / 100
            local gate_prob = self.parameters[GATE_PROB_PARAM] / 100
            local length = math.floor(self.parameters[LENGTH_PARAM])

            -- Initialize or resize patterns if needed
            if #note_pattern ~= length then
                probabilities = compute_probabilities(scale)
                initialize_patterns(scale, probabilities, length)
            elseif not probabilities or #probabilities == 0 then
                -- Safety check: ensure probabilities is initialized
                probabilities = compute_probabilities(scale)
            end

            -- Advance to next step
            current_step = (current_step % length) + 1

            -- Mutate note at current step based on probability
            -- 100% = always change, 0% = never change
            if math.random() < note_prob then
                note_pattern[current_step] = weighted_pick(scale, probabilities)
            end

            -- Mutate gate at current step based on probability
            -- 100% = always flip, 0% = never flip
            if math.random() < gate_prob then
                gate_pattern[current_step] = not gate_pattern[current_step]
            end

            -- Get current note and gate
            local current_note = note_pattern[current_step]
            local gate_out = gate_pattern[current_step] and 5.0 or 0.0

            -- Apply octave variation
            local octave_prob = self.parameters[OCTAVE_PARAM] / 100
            local octave_offset = 0
            if octave_prob > 0 then
                local oct_range = math.floor(octave_prob * 3)
                octave_offset = math.random(0, oct_range) * 12
            end

            local cv = (current_note + root + octave_offset) / 12

            output_table[1] = gate_out
            output_table[2] = cv
            return output_table
        end
    end,

    trigger = function(self, input)
        if input == 2 then
            current_step = 0
        end
    end,

    pot1Turn = function(self, x)
        local alg = getCurrentAlgorithm()
        setParameter(alg, self.parameterOffset + NOTE_PROB_PARAM, math.floor(x * 100 + 0.5))
    end,

    pot2Turn = function(self, x)
        local alg = getCurrentAlgorithm()
        setParameter(alg, self.parameterOffset + GATE_PROB_PARAM, math.floor(x * 100 + 0.5))
    end,

    pot3Turn = function(self, x)
        local alg = getCurrentAlgorithm()
        setParameter(alg, self.parameterOffset + OCTAVE_PARAM, math.floor(x * 100 + 0.5))
    end,

    encoder1Turn = function(self, d)
        local alg = getCurrentAlgorithm()
        local scale_index = self.parameters[SCALE_PARAM]
        scale_index = scale_index + d
        if scale_index < 1 then
            scale_index = #scales
        elseif scale_index > #scales then
            scale_index = 1
        end
        setParameter(alg, self.parameterOffset + SCALE_PARAM, scale_index)
        probabilities = compute_probabilities(scales[scale_index].notes)
    end,

    encoder2Turn = function(self, d)
        local alg = getCurrentAlgorithm()
        local r = self.parameters[ROOT_PARAM] + d
        if r < 0 then
            r = 11
        elseif r > 11 then
            r = 0
        end
        setParameter(alg, self.parameterOffset + ROOT_PARAM, r)
    end,

    draw = function(self)
        -- Title centered at top
        drawText(128 - 18, 10, "Soma", 15)

        -- Left column
        drawText(10, 26, "Note:")
        drawText(50, 26, math.floor(self.parameters[NOTE_PROB_PARAM]) .. "%")

        drawText(10, 38, "Gate:")
        drawText(50, 38, math.floor(self.parameters[GATE_PROB_PARAM]) .. "%")

        drawText(10, 50, "Oct:")
        drawText(50, 50, math.floor(self.parameters[OCTAVE_PARAM]) .. "%")

        -- Right column
        drawText(128, 26, "Scale:")
        local scale_idx = math.floor(self.parameters[SCALE_PARAM])
        if scale_idx >= 1 and scale_idx <= #scales then
            drawTinyText(128, 38, scales[scale_idx].name)
        else
            drawTinyText(128, 38, "Invalid")
        end

        drawText(128, 50, "Root:")
        local root_idx = math.floor(self.parameters[ROOT_PARAM])
        drawText(168, 50, noteNames[root_idx + 1])

        return true
    end,

    ui = function(self)
        return true
    end
}
