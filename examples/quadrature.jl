using PIOLib

# Translated from https://github.com/adamgreen/QuadratureDecoder
# (Apache 2.0 License, Adam Green)
#
# A single-SM 4x quadrature decoder using a 16-entry jump table at origin 0.
# The 4-bit index (old_AB:new_AB) selects +1, -1, or no-change. Position is
# tracked in scratch X and pushed to the RX FIFO on each transition.

"""
    quadrature_program(; pin_a::Integer)

Build a PIO program and SM config for a 4x quadrature decoder. Pin B must be `pin_a + 1`.

# How it works
A 16-entry jump table at address 0 is indexed by `{previous_AB, current_AB}` to
decode direction in a single cycle. The position counter lives in scratch X and is
pushed to the RX FIFO (noblock) on every transition. When idle the polling loop is
6 cycles.

Uses 28 of 32 instruction slots. Must be loaded at origin 0.

# Pins
- `pin_a`: Encoder channel A (IN base). Channel B must be `pin_a + 1`.

# Reading position
Drain the RX FIFO — the last value is the most recent absolute position (signed,
as `Int32`). If the FIFO fills, intermediate values are silently dropped but X
remains correct; the next transition pushes the up-to-date count.

# Returns
`(program::PIOProgram, config::SMConfig, entry::Int)` — pass `offset + entry` as
the initial PC to `init!` to skip the jump table.

# See also
[`quadrature_position`](@ref)
"""
function quadrature_program(; pin_a::Integer)
    prog = build_program([
        # Jump table (addresses 0-15), indexed by old_AB:new_AB
        Jmp{:always}(:delta0),   #  0: 00→00 no change
        Jmp{:always}(:minus1),   #  1: 00→01
        Jmp{:always}(:plus1),    #  2: 00→10
        Jmp{:always}(:delta0),   #  3: 00→11 invalid
        Jmp{:always}(:plus1),    #  4: 01→00
        Jmp{:always}(:delta0),   #  5: 01→01 no change
        Jmp{:always}(:delta0),   #  6: 01→10 invalid
        Jmp{:always}(:minus1),   #  7: 01→11
        Jmp{:always}(:minus1),   #  8: 10→00
        Jmp{:always}(:delta0),   #  9: 10→01 invalid
        Jmp{:always}(:delta0),   # 10: 10→10 no change
        Jmp{:always}(:plus1),    # 11: 10→11
        Jmp{:always}(:delta0),   # 12: 11→00 invalid
        Jmp{:always}(:plus1),    # 13: 11→01
        Jmp{:always}(:minus1),   # 14: 11→10
        Jmp{:always}(:delta0),   # 15: 11→11 no change

        WrapTarget(),
        Label(:delta0),
        Mov{:none}(ISR(), Null()),
        In(RegY(), 2),
        Mov{:none}(RegY(), Pins()),
        In(RegY(), 2),
        Mov{:none}(PC(), ISR()),

        Label(:minus1),
        Jmp{:x_dec}(:output),
        Jmp{:always}(:output),

        Label(:plus1),
        Mov{:invert}(RegX(), RegX()),
        Jmp{:x_dec}(:next2),
        Label(:next2),
        Mov{:invert}(RegX(), RegX()),

        Label(:output),
        Mov{:none}(ISR(), RegX()),
        Push(; block=false),
        Wrap(),
    ]; origin=0)

    config = SMConfig(;
        in_pin_base=pin_a,
        in_shift=(false, false, 32),
    )

    prog, config, 16
end

"""
    quadrature_position(sm) -> Int32

Read the latest position from the decoder. Drains the RX FIFO and returns the
most recent value, or reads X directly if the FIFO is empty.
"""
function quadrature_position(sm::StateMachine)
    val = nothing
    while (v = trytake(sm)) !== nothing
        val = v
    end
    if val === nothing
        exec!(sm, In(RegX(), 32))
        val = take!(sm)
    end
    reinterpret(Int32, val)
end

# Example usage:
#
#   PIN_A = 10   # channel B must be pin 11
#
#   prog, config, entry = quadrature_program(pin_a=PIN_A)
#
#   open_pio(0) do pio
#       pio_pin_init!(pio, PIN_A)
#       pio_pin_init!(pio, PIN_A + 1)
#
#       offset = load_program!(pio, prog, config)
#
#       claim_sm(pio) do sm
#           gpio_set_pulls!(PIN_A; up=true)
#           gpio_set_pulls!(PIN_A + 1; up=true)
#
#           init!(sm, offset + entry, config)
#           enable!(sm)
#
#           while true
#               pos = quadrature_position(sm)
#               println("Position: $pos  (detents: $(pos ÷ 4))")
#               sleep(0.01)
#           end
#       end
#   end
