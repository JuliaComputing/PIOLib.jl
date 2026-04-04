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
    raw |= _encode_delay_sideset(UInt32(d), s, sideset_bits, sideset_opt)
    UInt16(raw)
end

function _resolve(target::Symbol, labels::Dict{Symbol, UInt8})
    haskey(labels, target) || error("undefined label :$target")
    UInt32(labels[target])
end
_resolve(target::Integer, ::Dict{Symbol, UInt8}) = UInt32(target)

# Pure Julia instruction encoding — no hardware access needed.
# Bit layout from RP2040 datasheet §3.4:
#   [15:13] opcode  [12:8] delay/sideset  [7:0] instruction-specific

_src_dest_bits(r::PIORegister) = UInt32(to_pio_src_dest(r)) & UInt32(0x07)

function _encode_delay_sideset(delay::UInt32, sideset, sideset_bits::Integer, sideset_opt::Bool)
    if sideset === nothing
        delay << 8
    elseif sideset_opt
        ss = UInt32(sideset)
        (UInt32(0x1000) | (ss << (12 - sideset_bits)) | (delay << 8))
    else
        ss = UInt32(sideset)
        ((ss << (13 - sideset_bits)) | (delay << 8))
    end
end

# JMP: 000 | delay/ss | cond[7:5] | addr[4:0]
const _JMP_CONDS = Dict{Symbol, UInt32}(
    :always   => 0b000,
    :not_x    => 0b001,
    :x_dec    => 0b010,
    :not_y    => 0b011,
    :y_dec    => 0b100,
    :x_ne_y   => 0b101,
    :pin      => 0b110,
    :not_osre => 0b111,
)

function _encode(i::Jmp{Cond}, l) where {Cond}
    addr = _resolve(i.target, l) & UInt32(0x1f)
    cond = _JMP_CONDS[Cond]
    UInt32(0x0000) | (cond << 5) | addr
end

# WAIT: 001 | delay/ss | pol[7] | src[6:5] | idx[4:0]
const _WAIT_SRCS = Dict{Symbol, UInt32}(:gpio => 0b00, :pin => 0b01, :irq => 0b10)

function _encode(i::Wait{Src}, _) where {Src}
    pol = UInt32(i.polarity) << 7
    src = _WAIT_SRCS[Src] << 5
    idx = UInt32(i.index) & UInt32(0x1f)
    if Src === :irq && i.relative
        idx |= UInt32(0x10)
    end
    UInt32(0x2000) | pol | src | idx
end

# IN: 010 | delay/ss | src[7:5] | count[4:0]
function _encode(i::In, _)
    src = _src_dest_bits(i.src) << 5
    count = UInt32(i.bit_count == 32 ? 0 : i.bit_count) & UInt32(0x1f)
    UInt32(0x4000) | src | count
end

# OUT: 011 | delay/ss | dest[7:5] | count[4:0]
function _encode(i::Out, _)
    dest = _src_dest_bits(i.dest) << 5
    count = UInt32(i.bit_count == 32 ? 0 : i.bit_count) & UInt32(0x1f)
    UInt32(0x6000) | dest | count
end

# PUSH: 100 | delay/ss | 0[7] | iff[6] | blk[5] | 00000
function _encode(i::Push, _)
    UInt32(0x8000) | (UInt32(i.if_full) << 6) | (UInt32(i.block) << 5)
end

# PULL: 100 | delay/ss | 1[7] | ife[6] | blk[5] | 00000
function _encode(i::Pull, _)
    UInt32(0x8080) | (UInt32(i.if_empty) << 6) | (UInt32(i.block) << 5)
end

# MOV: 101 | delay/ss | dest[7:5] | op[4:3] | src[2:0]
const _MOV_OPS = Dict{Symbol, UInt32}(:none => 0b00, :invert => 0b01, :reverse => 0b10)

function _encode(i::Mov{Op}, _) where {Op}
    dest = _src_dest_bits(i.dest) << 5
    op = _MOV_OPS[Op] << 3
    src = _src_dest_bits(i.src)
    UInt32(0xa000) | dest | op | src
end

# IRQ: 110 | delay/ss | 0[7] | clr[6] | wait[5] | idx[4:0]
function _encode(i::Irq{:set}, _)
    idx = UInt32(i.index) & UInt32(0x1f)
    if i.relative; idx |= UInt32(0x10); end
    UInt32(0xc000) | idx
end

function _encode(i::Irq{:wait}, _)
    idx = UInt32(i.index) & UInt32(0x1f)
    if i.relative; idx |= UInt32(0x10); end
    UInt32(0xc000) | UInt32(0x20) | idx
end

function _encode(i::Irq{:clear}, _)
    idx = UInt32(i.index) & UInt32(0x1f)
    if i.relative; idx |= UInt32(0x10); end
    UInt32(0xc000) | UInt32(0x40) | idx
end

# SET: 111 | delay/ss | dest[7:5] | data[4:0]
function _encode(i::Set, _)
    dest = _src_dest_bits(i.dest) << 5
    data = UInt32(i.value) & UInt32(0x1f)
    UInt32(0xe000) | dest | data
end

# NOP: mov y, y
function _encode(::Nop, _)
    UInt32(0xa000) | (_src_dest_bits(RegY()) << 5) | _src_dest_bits(RegY())
end
