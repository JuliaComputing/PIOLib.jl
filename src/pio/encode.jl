"""
    PIOProgram

A compiled PIO program ready for loading into instruction memory. Contains the encoded
16-bit instruction words and metadata (origin, wrap points).

Construct via [`build_program`](@ref), then load with [`load_program!`](@ref).
"""
struct PIOProgram
    instructions::Vector{UInt16}
    origin::Int8
    wrap_target::UInt8
    wrap::UInt8
end

"""
    build_program(instrs; origin=-1, sideset_bits=0, sideset_opt=false) -> PIOProgram

Assemble an array of [`PIOInstruction`](@ref) descriptors into a [`PIOProgram`](@ref).

The builder runs two passes:
1. **Index pass** — assigns instruction addresses, collects labels and wrap points
2. **Encode pass** — resolves label references, validates delay/sideset, encodes via the C library

# Arguments
- `instrs`: array of instruction descriptors and metadata markers
- `origin`: fixed instruction memory offset (-1 for any)
- `sideset_bits`: number of GPIOs used for side-set (0-5). Reduces available delay bits.
- `sideset_opt`: if `true`, one additional bit is used as a side-set enable flag per
  instruction, and instructions without a `sideset` value will not perform a side-set.
  If `false` and `sideset_bits > 0`, every instruction must provide a sideset value.

# Delay/sideset bit allocation
The 5-bit delay/side-set field is shared: `delay_bits = 5 - sideset_bits - (sideset_opt ? 1 : 0)`.
Maximum delay is `2^delay_bits - 1`.

# Example
```julia
prog = build_program([
    Label(:loop),
    WrapTarget(),
    Set(Pins(), 1; delay=31),
    Set(Pins(), 0; delay=31),
    Jmp{:always}(:loop),
    Wrap(),
])
```
"""
function build_program(instrs::AbstractVector;
                       origin::Integer=-1, sideset_bits::Integer=0, sideset_opt::Bool=false)
    labels = Dict{Symbol, UInt8}()
    wt = -1
    wp = -1
    idx = 0
    for instr in instrs
        if instr isa Label
            haskey(labels, instr.name) && error("duplicate label :$(instr.name)")
            labels[instr.name] = UInt8(idx)
        elseif instr isa WrapTarget
            wt >= 0 && error("multiple wrap_target markers")
            wt = idx
        elseif instr isa Wrap
            wp >= 0 && error("multiple wrap markers")
            wp = idx - 1
        else
            idx += 1
        end
    end
    wt = wt < 0 ? 0 : wt
    wp = wp < 0 ? idx - 1 : wp

    encoded = UInt16[]
    for instr in instrs
        instr isa Label && continue
        instr isa WrapTarget && continue
        instr isa Wrap && continue
        push!(encoded, encode_instr(instr; labels, sideset_bits, sideset_opt))
    end

    PIOProgram(encoded, Int8(origin), UInt8(wt), UInt8(wp))
end

"""
    encode_instr(instr::PIOInstruction; labels=Dict{Symbol,UInt8}(), sideset_bits=0, sideset_opt=false) -> UInt16

Encode a single PIO instruction into its 16-bit binary representation, including delay
and sideset fields. Used internally by [`build_program`](@ref) and the
[`exec!`](@ref) `PIOInstruction` overload.

Validates delay/sideset against the given configuration. Pass `labels` to resolve
symbolic jump targets; defaults to an empty dict (labels will error).
"""
function encode_instr(instr::PIOInstruction;
                      labels::Dict{Symbol, UInt8}=Dict{Symbol, UInt8}(),
                      sideset_bits::Integer=0, sideset_opt::Bool=false)
    delay_bits = 5 - sideset_bits - (sideset_opt ? 1 : 0)
    max_delay = (1 << delay_bits) - 1
    max_sideset = sideset_bits > 0 ? (1 << sideset_bits) - 1 : 0

    d = instr.delay
    s = instr.sideset

    d > max_delay && error(
        "delay $d exceeds maximum $max_delay " *
        "(5 bits - $sideset_bits sideset - $(sideset_opt ? 1 : 0) opt = $delay_bits delay bits)")
    if s !== nothing
        sideset_bits == 0 && error("sideset value provided but sideset_bits=0")
        s > max_sideset && error("sideset value $s exceeds maximum $max_sideset ($sideset_bits bits)")
    end
    if s === nothing && sideset_bits > 0 && !sideset_opt
        error("non-optional sideset configured but instruction has no sideset value")
    end

    raw = _encode(instr, labels)
    raw |= LibPIO.pio_encode_delay(UInt32(d))
    if s !== nothing
        if sideset_opt
            raw |= LibPIO.pio_encode_sideset_opt(UInt32(sideset_bits), UInt32(s))
        else
            raw |= LibPIO.pio_encode_sideset(UInt32(sideset_bits), UInt32(s))
        end
    end
    UInt16(raw)
end

function _resolve(target::Symbol, labels::Dict{Symbol, UInt8})
    haskey(labels, target) || error("undefined label :$target")
    UInt32(labels[target])
end
_resolve(target::Integer, ::Dict{Symbol, UInt8}) = UInt32(target)

_encode(i::Jmp{:always},   l) = LibPIO.pio_encode_jmp(_resolve(i.target, l))
_encode(i::Jmp{:not_x},    l) = LibPIO.pio_encode_jmp_not_x(_resolve(i.target, l))
_encode(i::Jmp{:x_dec},    l) = LibPIO.pio_encode_jmp_x_dec(_resolve(i.target, l))
_encode(i::Jmp{:not_y},    l) = LibPIO.pio_encode_jmp_not_y(_resolve(i.target, l))
_encode(i::Jmp{:y_dec},    l) = LibPIO.pio_encode_jmp_y_dec(_resolve(i.target, l))
_encode(i::Jmp{:x_ne_y},   l) = LibPIO.pio_encode_jmp_x_ne_y(_resolve(i.target, l))
_encode(i::Jmp{:pin},      l) = LibPIO.pio_encode_jmp_pin(_resolve(i.target, l))
_encode(i::Jmp{:not_osre}, l) = LibPIO.pio_encode_jmp_not_osre(_resolve(i.target, l))

_encode(i::Wait{:gpio}, _) = LibPIO.pio_encode_wait_gpio(i.polarity, UInt32(i.index))
_encode(i::Wait{:pin},  _) = LibPIO.pio_encode_wait_pin(i.polarity, UInt32(i.index))
_encode(i::Wait{:irq},  _) = LibPIO.pio_encode_wait_irq(i.polarity, i.relative, UInt32(i.index))

_encode(i::In,  _) = LibPIO.pio_encode_in(to_pio_src_dest(i.src), UInt32(i.bit_count))
_encode(i::Out, _) = LibPIO.pio_encode_out(to_pio_src_dest(i.dest), UInt32(i.bit_count))

_encode(i::Push, _) = LibPIO.pio_encode_push(i.if_full, i.block)
_encode(i::Pull, _) = LibPIO.pio_encode_pull(i.if_empty, i.block)

_encode(i::Mov{:none},    _) = LibPIO.pio_encode_mov(to_pio_src_dest(i.dest), to_pio_src_dest(i.src))
_encode(i::Mov{:invert},  _) = LibPIO.pio_encode_mov_not(to_pio_src_dest(i.dest), to_pio_src_dest(i.src))
_encode(i::Mov{:reverse}, _) = LibPIO.pio_encode_mov_reverse(to_pio_src_dest(i.dest), to_pio_src_dest(i.src))

_encode(i::Irq{:set},   _) = LibPIO.pio_encode_irq_set(i.relative, UInt32(i.index))
_encode(i::Irq{:wait},  _) = LibPIO.pio_encode_irq_wait(i.relative, UInt32(i.index))
_encode(i::Irq{:clear}, _) = LibPIO.pio_encode_irq_clear(i.relative, UInt32(i.index))

_encode(i::Set, _) = LibPIO.pio_encode_set(to_pio_src_dest(i.dest), UInt32(i.value))
_encode(i::Nop, _) = LibPIO.pio_encode_nop()
