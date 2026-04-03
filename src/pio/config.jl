"""
    SMConfig(; kwargs...)
    SMConfig(pio::PIOBlock; kwargs...)

Construct an SM configuration with optional keyword arguments. The first form uses a
global default; the second uses defaults appropriate for the specific PIO block.

See [`Base.setproperty!(::SMConfig, ::Symbol, value)`](@ref) for all settable properties.

# Example
```julia
config = SMConfig(pio;
    out_pins = (0, 1),
    clkdiv = 125.0f0,
    wrap = (prog.wrap_target, prog.wrap),
    out_shift = (true, true, 32),
)
```
"""
function SMConfig(; kwargs...)
    c = SMConfig(LibPIO.pio_get_default_sm_config())
    for (k, v) in pairs(kwargs)
        setproperty!(c, k, v)
    end
    c
end

function SMConfig(pio::PIOBlock; kwargs...)
    c = SMConfig(LibPIO.pio_get_default_sm_config_for_pio(pio.handle))
    for (k, v) in pairs(kwargs)
        setproperty!(c, k, v)
    end
    c
end

"""
    Base.setproperty!(config::SMConfig, name::Symbol, value)

Set a configuration field. Each property maps to a hardware configuration register:

| Property | Value | Description |
|:---|:---|:---|
| `out_pins` | `(base, count)` | OUT pin mapping: base GPIO and number of pins |
| `set_pins` | `(base, count)` | SET pin mapping |
| `in_pin_base` | `base` | IN pin mapping base GPIO |
| `sideset_pin_base` | `base` | Side-set pin mapping base GPIO |
| `sideset` | `(bits, optional, pindirs)` | Side-set config: bit count, optional enable, write to pindirs |
| `clkdiv` | `Float32` or `(int, frac)` | Clock divider — 16-bit integer + 8-bit fractional (1/256 increments) |
| `wrap` | `(target, top)` | Program wrap points (bottom, top instruction addresses) |
| `jmp_pin` | `pin` | GPIO number for `JMP PIN` condition |
| `in_shift` | `(right, autopush, threshold)` | ISR shift direction, autopush enable, push threshold (1-32) |
| `out_shift` | `(right, autopull, threshold)` | OSR shift direction, autopull enable, pull threshold (1-32) |
| `fifo_join` | `pio_fifo_join` enum | FIFO joining: `PIO_FIFO_JOIN_NONE`, `_TX`, or `_RX` (merges both 8-deep FIFOs into one 16-deep FIFO) |
| `out_special` | `(sticky, has_enable, pin_idx)` | OUT sticky mode and enable pin |
| `mov_status` | `(sel, n)` | MOV STATUS source: TX or RX level vs. threshold `n` |
"""
const _SMCONFIG_PROPERTIES = (
    :out_pins, :set_pins, :in_pin_base, :sideset_pin_base, :sideset,
    :clkdiv, :wrap, :jmp_pin, :in_shift, :out_shift,
    :fifo_join, :out_special, :mov_status,
)

Base.propertynames(::SMConfig) = _SMCONFIG_PROPERTIES

function Base.setproperty!(c::SMConfig, name::Symbol, value)
    if name === :_config
        setfield!(c, :_config, value)
        return value
    end
    ref = Ref(c._config)
    if name === :out_pins
        base, count = value
        LibPIO.sm_config_set_out_pins(ref, UInt32(base), UInt32(count))
    elseif name === :set_pins
        base, count = value
        LibPIO.sm_config_set_set_pins(ref, UInt32(base), UInt32(count))
    elseif name === :in_pin_base
        LibPIO.sm_config_set_in_pins(ref, UInt32(value))
    elseif name === :sideset_pin_base
        LibPIO.sm_config_set_sideset_pins(ref, UInt32(value))
    elseif name === :sideset
        bit_count, optional, pindirs = value
        LibPIO.sm_config_set_sideset(ref, UInt32(bit_count), optional, pindirs)
    elseif name === :clkdiv
        if value isa Tuple
            div_int, div_frac = value
            LibPIO.sm_config_set_clkdiv_int_frac(ref, UInt16(div_int), UInt8(div_frac))
        else
            LibPIO.sm_config_set_clkdiv(ref, Float32(value))
        end
    elseif name === :wrap
        target, top = value
        LibPIO.sm_config_set_wrap(ref, UInt32(target), UInt32(top))
    elseif name === :jmp_pin
        LibPIO.sm_config_set_jmp_pin(ref, UInt32(value))
    elseif name === :in_shift
        shift_right, autopush, threshold = value
        LibPIO.sm_config_set_in_shift(ref, shift_right, autopush, UInt32(threshold))
    elseif name === :out_shift
        shift_right, autopull, threshold = value
        LibPIO.sm_config_set_out_shift(ref, shift_right, autopull, UInt32(threshold))
    elseif name === :fifo_join
        LibPIO.sm_config_set_fifo_join(ref, value)
    elseif name === :out_special
        sticky, has_enable_pin, enable_pin_index = value
        LibPIO.sm_config_set_out_special(ref, sticky, has_enable_pin, UInt32(enable_pin_index))
    elseif name === :mov_status
        status_sel, status_n = value
        LibPIO.sm_config_set_mov_status(ref, status_sel, UInt32(status_n))
    else
        error("SMConfig has no settable property :$name")
    end
    setfield!(c, :_config, ref[])
    value
end
