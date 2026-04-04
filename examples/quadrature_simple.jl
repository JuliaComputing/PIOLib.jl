using PIOLib

"""
    quadrature_simple_program(; pin_a::Integer, pin_b::Integer)

Build a poll-and-push quadrature decoder for two independent (non-consecutive) GPIO pins.
Direction decoding is done on the host side via a lookup table.

# How it works
The SM polls both pins each iteration: pin A via `IN PINS, 1` and pin B via `JMP PIN`
branching, combining into a 2-bit state in ISR. On any state change, the new state is
pushed to the RX FIFO. The host decodes direction from successive transitions.

12 instructions. No-change poll loop: 9 cycles (~22MHz at 200MHz sys_clk).
Call [`setup_quadrature!`](@ref) after `init!` to seed the previous-state register.

# Pins
- `pin_a`: Encoder channel A (any GPIO)
- `pin_b`: Encoder channel B (any GPIO, need not be adjacent)

# Returns
`(program::PIOProgram, config::SMConfig)`

# See also
[`setup_quadrature!`](@ref), [`QuadratureDecoder`](@ref), [`quadrature_read!`](@ref)
"""
function quadrature_simple_program(; pin_a::Integer, pin_b::Integer)
    prog = build_program([
        WrapTarget(),
        Mov{:none}(ISR(), Null()),
        Set(RegX(), 0),
        Jmp{:pin}(:b_high),
        Jmp{:always}(:read_a),
        Label(:b_high),
        Set(RegX(), 1),
        Label(:read_a),
        In(RegX(), 1),
        In(Pins(), 1),
        Mov{:none}(RegX(), ISR()),
        Jmp{:x_ne_y}(:changed),
        Jmp{:always}(:poll),
        Label(:changed),
        Mov{:none}(RegY(), RegX()),
        Push(; block=false),
        Label(:poll),
        Wrap(),
    ])

    config = SMConfig(;
        in_pin_base=pin_a,
        jmp_pin=pin_b,
        in_shift=(false, false, 32),
        fifo_join=LibPIO.PIO_FIFO_JOIN_RX,
    )

    prog, config
end

"""
    setup_quadrature!(sm, pin_a, pin_b) -> UInt32

Seed scratch Y with the current encoder state by reading GPIO levels via `exec!`.
Call after `init!` but before `enable!`. Returns the initial 2-bit state (for
initialising a [`QuadratureDecoder`](@ref)).

Uses `MOV ISR, PINS` to sample all GPIOs in one instruction, then extracts both
pin values on the Julia side — no need for `JMP PIN` or temporary SM execution.
"""
function setup_quadrature!(sm::StateMachine, pin_a::Integer, pin_b::Integer)
    exec!(sm, Mov{:none}(ISR(), Pins()))
    exec!(sm, Push(; block=false))
    gpio_state = take!(sm)

    a_val = Int(gpio_state & UInt32(1))
    b_val = Int((gpio_state >> mod(pin_b - pin_a, 32)) & UInt32(1))

    initial = (b_val << 1) | a_val
    exec!(sm, Set(RegY(), initial))
    UInt32(initial)
end

"""
    QuadratureDecoder

Tracks encoder position by decoding 2-bit state transitions pushed by the PIO.

```julia
dec = QuadratureDecoder()
pos = quadrature_read!(dec, sm)
```
"""
mutable struct QuadratureDecoder
    position::Int
    prev::UInt32
    QuadratureDecoder(initial_state::UInt32=UInt32(0)) = new(0, initial_state)
end

#        new:  00  01  10  11
const _QUAD_LUT = Int8[  0,  -1,   1,   0,   # old = 00
                          1,   0,   0,  -1,   # old = 01
                         -1,   0,   0,   1,   # old = 10
                          0,   1,  -1,   0 ]  # old = 11

"""
    quadrature_read!(dec::QuadratureDecoder, sm::StateMachine) -> Int

Drain all pending state transitions from the RX FIFO and return the updated
position. Each encoder detent typically produces 4 edges (4x decoding).
"""
function quadrature_read!(dec::QuadratureDecoder, sm::StateMachine)
    while (raw = trytake(sm)) !== nothing
        new_state = raw & UInt32(0x3)
        dec.position += _QUAD_LUT[(dec.prev << 2 | new_state) + 1]
        dec.prev = new_state
    end
    dec.position
end

# Example usage:
#
#   PIN_A = 10
#   PIN_B = 14   # any GPIO — need not be adjacent
#
#   prog, config = quadrature_simple_program(pin_a=PIN_A, pin_b=PIN_B)
#
#   open_pio(0) do pio
#       pio_pin_init!(pio, PIN_A)
#       pio_pin_init!(pio, PIN_B)
#
#       offset = load_program!(pio, prog, config)
#
#       claim_sm(pio) do sm
#           gpio_set_pulls!(PIN_A; up=true)
#           gpio_set_pulls!(PIN_B; up=true)
#
#           init!(sm, offset, config)
#           initial = setup_quadrature!(sm, PIN_A, PIN_B)
#           enable!(sm)
#
#           dec = QuadratureDecoder(initial)
#           while true
#               pos = quadrature_read!(dec, sm)
#               println("Position: $pos  (detents: $(pos ÷ 4))")
#               sleep(0.01)
#           end
#       end
#   end
