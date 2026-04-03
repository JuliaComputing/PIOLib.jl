"""
    PIOInstruction

Abstract supertype for all PIO instruction descriptors and metadata markers.
Instruction objects are pure data — pass an array of them to [`build_program`](@ref)
to encode into a [`PIOProgram`](@ref).

All real instructions share `delay` and `sideset` keyword arguments:
- `delay::Integer=0`: idle cycles inserted after the instruction (0-31, reduced by sideset bits)
- `sideset=nothing`: value to assert on sideset pins concurrently with the instruction
"""
abstract type PIOInstruction end

"""
    Label(name::Symbol)

Metadata marker that defines a jump target at the current instruction index.
Does not produce a real instruction. Referenced by `Jmp` via the label symbol.

```julia
[Label(:loop), ..., Jmp{:always}(:loop)]
```
"""
struct Label <: PIOInstruction
    name::Symbol
end

"""
    WrapTarget()

Metadata marker indicating where execution resumes after program wrapping. Place before
the first instruction of the wrap region. Defaults to the start of the program if omitted.
"""
struct WrapTarget <: PIOInstruction end

"""
    Wrap()

Metadata marker indicating the last instruction of the wrap region. When PC reaches
this instruction (and no JMP is taken), it wraps to the `WrapTarget` on the next cycle
instead of incrementing — a free unconditional jump that saves an instruction slot.
Place after the last instruction of the loop body. Defaults to the end of the program if omitted.
"""
struct Wrap <: PIOInstruction end

"""
    Jmp{Cond}(target; delay=0, sideset=nothing)

Set program counter to `target` if `Cond` is true. `target` is a label `Symbol` or
an absolute instruction address. Delay cycles always take effect regardless of whether
the branch is taken.

Conditions:
- `:always` — unconditional
- `:not_x` — scratch X is zero
- `:x_dec` — always decrement X; branch if X was non-zero **before** decrement
- `:not_y` — scratch Y is zero
- `:y_dec` — always decrement Y; branch if Y was non-zero **before** decrement
- `:x_ne_y` — scratch X not equal to scratch Y
- `:pin` — branch if input pin (selected by JMP_PIN config) is high
- `:not_osre` — output shift register not empty (compares shift count to pull threshold)
"""
struct Jmp{Cond} <: PIOInstruction
    target::Union{Symbol, Integer}
    delay::UInt8
    sideset::Union{Nothing, UInt8}

    Jmp{Cond}(target; delay=0, sideset=nothing) where {Cond} =
        new{Cond}(target, UInt8(delay), sideset === nothing ? nothing : UInt8(sideset))
end

"""
    Wait{Src}(polarity, index; ...)

Stall until a condition is met. Delay cycles begin **after** the wait condition clears.

Sources:
- `Wait{:gpio}(pol, gpio_num)` — wait on absolute GPIO (ignores pin mapping)
- `Wait{:pin}(pol, pin_num)` — wait on mapped input pin (`pin_num` + `IN_BASE`, mod 32)
- `Wait{:irq}(pol, irq_num; relative=false)` — wait on PIO IRQ flag. If `relative`,
  the low 2 bits of the IRQ index are replaced with `(irq_num + sm_id) % 4`, allowing
  multiple SMs running the same program to synchronise on different flags.

Polarity: `true` = wait for 1, `false` = wait for 0.
For IRQ waits with polarity `true`, the flag is automatically cleared when the condition is met.
"""
struct Wait{Src} <: PIOInstruction
    polarity::Bool
    index::Integer
    relative::Bool
    delay::UInt8
    sideset::Union{Nothing, UInt8}

    Wait{:gpio}(polarity::Bool, gpio::Integer; delay=0, sideset=nothing) =
        new{:gpio}(polarity, gpio, false, UInt8(delay), sideset === nothing ? nothing : UInt8(sideset))
    Wait{:pin}(polarity::Bool, pin::Integer; delay=0, sideset=nothing) =
        new{:pin}(polarity, pin, false, UInt8(delay), sideset === nothing ? nothing : UInt8(sideset))
    Wait{:irq}(polarity::Bool, irq::Integer; relative=false, delay=0, sideset=nothing) =
        new{:irq}(polarity, irq, relative, UInt8(delay), sideset === nothing ? nothing : UInt8(sideset))
end

"""
    In(src::InSource, bit_count; delay=0, sideset=nothing)

Shift `bit_count` bits (1-32) from `src` into the Input Shift Register (ISR). Shift
direction is configured by `in_shift` in [`SMConfig`](@ref). The input shift count is
incremented by `bit_count`, saturating at 32.

If autopush is enabled and the shift count reaches the push threshold, the ISR contents
are automatically written to the RX FIFO and cleared. The SM will stall if the RX FIFO
is full during an autopush.

`Null` as a source shifts in zeroes, useful for right-aligning LSB-first data.
"""
struct In <: PIOInstruction
    src::PIORegister
    bit_count::UInt8
    delay::UInt8
    sideset::Union{Nothing, UInt8}

    In(src::InSource, bit_count::Integer; delay=0, sideset=nothing) =
        new(src, UInt8(bit_count), UInt8(delay), sideset === nothing ? nothing : UInt8(sideset))
end

"""
    Out(dest::OutDest, bit_count; delay=0, sideset=nothing)

Shift `bit_count` bits (1-32) out of the Output Shift Register (OSR) to `dest`. The OSR
fills with zeroes as data is shifted out. The output shift count is incremented by
`bit_count`, saturating at 32.

If autopull is enabled and the shift count reaches the pull threshold, the OSR is
automatically refilled from the TX FIFO. The SM will stall if the TX FIFO is empty
during an autopull.

Special destinations:
- `PC()` — behaves as an unconditional jump to the shifted-out address
- `ISR()` — also sets the ISR shift counter to `bit_count`
"""
struct Out <: PIOInstruction
    dest::PIORegister
    bit_count::UInt8
    delay::UInt8
    sideset::Union{Nothing, UInt8}

    Out(dest::OutDest, bit_count::Integer; delay=0, sideset=nothing) =
        new(dest, UInt8(bit_count), UInt8(delay), sideset === nothing ? nothing : UInt8(sideset))
end

"""
    Push(; if_full=false, block=true, delay=0, sideset=nothing)

Push ISR contents to the RX FIFO as a 32-bit word, then clear ISR to all zeroes.

- `if_full`: if `true`, only push when the input shift count has reached the configured
  threshold (same as autopush). Useful when autopush would stall at an inconvenient point.
- `block`: if `true` (default), stall when the RX FIFO is full. If `false`, the push
  is silently dropped and the FDEBUG RXSTALL flag is set.
"""
struct Push <: PIOInstruction
    if_full::Bool
    block::Bool
    delay::UInt8
    sideset::Union{Nothing, UInt8}

    Push(; if_full=false, block=true, delay=0, sideset=nothing) =
        new(if_full, block, UInt8(delay), sideset === nothing ? nothing : UInt8(sideset))
end

"""
    Pull(; if_empty=false, block=true, delay=0, sideset=nothing)

Load a 32-bit word from the TX FIFO into the OSR, clearing the output shift count to 0.

- `if_empty`: if `true`, only pull when the output shift count has reached the configured
  threshold (same as autopull). Allows controlled stalling at a specific program point.
- `block`: if `true` (default), stall when the TX FIFO is empty. If `false`, copy
  scratch register X into the OSR instead (useful for outputting a default value).

When autopull is enabled, PULL becomes a no-op if the OSR is full, acting as a
barrier/fence against the DMA system.
"""
struct Pull <: PIOInstruction
    if_empty::Bool
    block::Bool
    delay::UInt8
    sideset::Union{Nothing, UInt8}

    Pull(; if_empty=false, block=true, delay=0, sideset=nothing) =
        new(if_empty, block, UInt8(delay), sideset === nothing ? nothing : UInt8(sideset))
end

"""
    Mov{Op}(dest::MovDest, src::MovSrc; delay=0, sideset=nothing)

Copy data from `src` to `dest`, optionally transforming it.

Operations:
- `Mov{:none}` — direct copy
- `Mov{:invert}` — bitwise NOT (each bit inverted)
- `Mov{:reverse}` — bit-reverse (bit 0 swapped with bit 31, etc.)

Writing to `ISR` clears the input shift counter; writing to `OSR` clears the output
shift counter. Writing to `PC` causes an unconditional jump.

`Pins` as source reads via the IN pin mapping; as destination writes via the OUT pin
mapping, without masking (full 32-bit value written).
"""
struct Mov{Op} <: PIOInstruction
    dest::PIORegister
    src::PIORegister
    delay::UInt8
    sideset::Union{Nothing, UInt8}

    Mov{Op}(dest::MovDest, src::MovSrc; delay=0, sideset=nothing) where {Op} =
        new{Op}(dest, src, UInt8(delay), sideset === nothing ? nothing : UInt8(sideset))
end

"""
    Irq{Mode}(index; relative=false, delay=0, sideset=nothing)

Set, wait on, or clear a PIO IRQ flag (0-7).

Modes:
- `Irq{:set}` — raise the flag without waiting
- `Irq{:wait}` — raise the flag, then stall until it is cleared (e.g. by an interrupt handler)
- `Irq{:clear}` — clear the flag

If `relative=true`, the low 2 bits of `index` are replaced with `(index + sm_id) % 4`,
enabling multiple state machines running the same program to use different IRQ flags.

IRQ flags 0-3 can be routed to system-level interrupts; flags 4-7 are internal to the
PIO block and useful for inter-SM synchronisation.
"""
struct Irq{Mode} <: PIOInstruction
    index::Integer
    relative::Bool
    delay::UInt8
    sideset::Union{Nothing, UInt8}

    Irq{Mode}(index::Integer; relative=false, delay=0, sideset=nothing) where {Mode} =
        new{Mode}(index, relative, UInt8(delay), sideset === nothing ? nothing : UInt8(sideset))
end

"""
    Set(dest::SetDest, value; delay=0, sideset=nothing)

Write a 5-bit immediate value (0-31) to `dest`. Commonly used to initialise pin directions,
assert control signals, or load small loop counters into scratch registers.

For scratch registers, the 5 LSBs are written and all other bits are cleared to 0.
SET and OUT pin mappings are configured independently, allowing e.g. a UART to use SET
for start/stop bits and OUT for data on the same pins.
"""
struct Set <: PIOInstruction
    dest::PIORegister
    value::UInt8
    delay::UInt8
    sideset::Union{Nothing, UInt8}

    Set(dest::SetDest, value::Integer; delay=0, sideset=nothing) =
        new(dest, UInt8(value), UInt8(delay), sideset === nothing ? nothing : UInt8(sideset))
end

"""
    Nop(; delay=0, sideset=nothing)

No operation. Assembles to `MOV Y, Y`. Useful as a vehicle for a side-set operation
or an extra delay cycle.
"""
struct Nop <: PIOInstruction
    delay::UInt8
    sideset::Union{Nothing, UInt8}

    Nop(; delay=0, sideset=nothing) =
        new(UInt8(delay), sideset === nothing ? nothing : UInt8(sideset))
end
