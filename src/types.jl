"""
    PIOError <: Exception

Error thrown when a PIO operation fails. Wraps the error flag from the PIO hardware.
"""
struct PIOError <: Exception
    msg::String
end

"""
    PIOBlock

Handle to a PIO hardware block. Each block contains multiple state machines that share
a common instruction memory and can independently execute PIO programs to drive GPIOs
with cycle-accurate timing.

Obtain via [`open_pio`](@ref). Do not construct directly.
"""
struct PIOBlock
    handle::LibPIO.PIO
end

"""
    StateMachine

A state machine within a [`PIOBlock`](@ref), identified by its index. Each state machine
has its own clock divider, program counter, scratch registers (X and Y), shift registers
(ISR and OSR), and a pair of 8-deep FIFOs for data transfer with the system.

State machines execute one instruction per clock cycle (unless stalled) and can
independently manipulate up to 32 GPIOs.

Obtain via [`claim_sm`](@ref). Do not construct directly.
"""
struct StateMachine
    pio::PIOBlock
    sm::UInt32
end

"""
    SMConfig

Mutable configuration for a PIO state machine. Wraps the hardware configuration registers
that control pin mapping, clock division, shift behavior, and program wrapping.

Construct with keyword arguments, then apply with [`init!`](@ref) or [`set_config!`](@ref):

```julia
config = SMConfig(
    out_pins = (base, count),
    clkdiv = 125.0f0,
    wrap = (target, top),
    out_shift = (shift_right, autopull, threshold),
)
```

Individual fields can be modified after construction via property syntax:

```julia
config.clkdiv = 62.5f0
config.wrap = (0, 3)
```

See [`Base.setproperty!(::SMConfig, ::Symbol, value)`](@ref) for all settable properties.
"""
mutable struct SMConfig
    _config::LibPIO.pio_sm_config
end

"""
    PIOStream(sm; buf_size=256, buf_count=2) <: IO

An `IO`-compatible wrapper around a [`StateMachine`](@ref) for bulk data transfer via
`pio_sm_xfer_data`. Implements `Base.read`, `Base.write`, and related methods.

The constructor automatically configures transfer buffers for both TX and RX directions.
The stream is always open-ended (`eof` returns `false`).

```julia
stream = PIOStream(sm; buf_size=512, buf_count=4)
write(stream, data)
```
"""
struct PIOStream <: IO
    sm::StateMachine

    function PIOStream(sm::StateMachine; buf_size::Integer=256, buf_count::Integer=2)
        for dir in (UInt32(LibPIO.PIO_DIR_TO_SM), UInt32(LibPIO.PIO_DIR_FROM_SM))
            LibPIO.pio_sm_config_xfer(sm.pio.handle, sm.sm, dir, UInt32(buf_size), UInt32(buf_count))
        end
        check_error!(sm.pio)
        new(sm)
    end
end

function check_error!(pio::PIOBlock)
    if LibPIO.pio_get_error(pio.handle)
        LibPIO.pio_clear_error(pio.handle)
        throw(PIOError("PIO operation failed"))
    end
end
