"""
    PIORegister

Abstract supertype for PIO source/destination register singletons. Each concrete subtype
represents a register or pin group that PIO instructions can read from or write to.

Valid register types for each instruction are enforced at construction time via dispatch:
- [`In`](@ref): `Pins`, `RegX`, `RegY`, `Null`, `ISR`, `OSR`, `Status`
- [`Out`](@ref): `Pins`, `RegX`, `RegY`, `Null`, `PinDirs`, `PC`, `ISR`
- [`Set`](@ref): `Pins`, `RegX`, `RegY`, `PinDirs`
- [`Mov`](@ref): see `MovSrc` and `MovDest`
"""
abstract type PIORegister end

"GPIO pin values, mapped via the IN/OUT/SET/sideset pin mapping configuration."
struct Pins <: PIORegister end

"Scratch register X. 32-bit general-purpose register, also used as a loop counter by `Jmp{:x_dec}`."
struct RegX <: PIORegister end

"Scratch register Y. 32-bit general-purpose register, also used as a loop counter by `Jmp{:y_dec}`."
struct RegY <: PIORegister end

"Null register. Reads as all zeroes; writes are discarded. Useful for shifting zeroes into the ISR."
struct Null <: PIORegister end

"GPIO pin directions. Write-only in SET/OUT context (1 = output, 0 = input)."
struct PinDirs <: PIORegister end

"Input Shift Register. Data enters 1-32 bits at a time via IN; contents are pushed to the RX FIFO via PUSH or autopush."
struct ISR <: PIORegister end

"Output Shift Register. Loaded from the TX FIFO via PULL or autopull; data exits 1-32 bits at a time via OUT."
struct OSR <: PIORegister end

"Program counter. Writing causes an unconditional jump."
struct PC <: PIORegister end

"Status register (read-only source). Value is all-ones or all-zeroes depending on FIFO level vs. a configurable threshold."
struct Status <: PIORegister end

"Valid IN sources: `Pins`, `RegX`, `RegY`, `Null`, `ISR`, `OSR`, `Status`."
const InSource = Union{Pins, RegX, RegY, Null, ISR, OSR, Status}

"Valid OUT destinations: `Pins`, `RegX`, `RegY`, `Null`, `PinDirs`, `PC`, `ISR`."
const OutDest  = Union{Pins, RegX, RegY, Null, PinDirs, PC, ISR}

"Valid SET destinations: `Pins`, `RegX`, `RegY`, `PinDirs`."
const SetDest  = Union{Pins, RegX, RegY, PinDirs}

"Valid MOV sources: `Pins`, `RegX`, `RegY`, `Null`, `Status`, `ISR`, `OSR`."
const MovSrc   = Union{Pins, RegX, RegY, Null, Status, ISR, OSR}

"Valid MOV destinations: `Pins`, `RegX`, `RegY`, `PC`, `ISR`, `OSR`."
const MovDest  = Union{Pins, RegX, RegY, PC, ISR, OSR}

for T in (Pins, RegX, RegY, Null, PinDirs, ISR, OSR, PC, Status)
    name = string(T) * "()"
    @eval Base.show(io::IO, ::$T) = print(io, $name)
end

to_pio_src_dest(::Pins)    = LibPIO.pio_pins
to_pio_src_dest(::RegX)    = LibPIO.pio_x
to_pio_src_dest(::RegY)    = LibPIO.pio_y
to_pio_src_dest(::Null)    = LibPIO.pio_null
to_pio_src_dest(::PinDirs) = LibPIO.pio_pindirs
to_pio_src_dest(::ISR)     = LibPIO.pio_isr
to_pio_src_dest(::OSR)     = LibPIO.pio_osr
to_pio_src_dest(::PC)      = LibPIO.pio_pc
to_pio_src_dest(::Status)  = LibPIO.pio_status
