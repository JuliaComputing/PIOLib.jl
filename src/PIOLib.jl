module PIOLib

module LibPIO
    using PIOLib_jll
    using CEnum: CEnum, @cenum

    const libpio = PIOLib_jll.libpio

    include(joinpath(@__DIR__, "..", "gen", "libpiolib_api.jl"))
end

using .LibPIO

include("types.jl")

# Program encoding
include("pio/registers.jl")
include("pio/instructions.jl")
include("pio/encode.jl")

# PIO operations
include("pio/lifecycle.jl")
include("pio/config.jl")
include("pio/control.jl")
include("pio/program.jl")
include("pio/stream.jl")

include("hw/gpio.jl")

function __init__()
    ret = LibPIO.pio_init()
    ret != 0 && error("PIOLib: pio_init() failed (code $ret)")
    LibPIO.pio_open_helper(UInt32(0))
end

# Types
export PIOBlock, StateMachine, SMConfig, PIOStream, PIOError, PIOProgram

# Registers
export PIORegister, Pins, RegX, RegY, Null, PinDirs, ISR, OSR, PC, Status

# Instructions
export PIOInstruction, Label, WrapTarget, Wrap
export Jmp, Wait, In, Out, Push, Pull, Mov, Irq, Set, Nop

# Program building
export build_program, encode_instr

# PIO lifecycle
export open_pio, claim_sm, unclaim!

# SM config & control
export init!, set_config!, enable!, disable!, restart!, restart_clkdiv!
export exec!, exec_blocking!
export clkdiv, set_clkdiv!, set_pins!, set_pindirs!, set_consecutive_pindirs!, set_dmactrl!

# Program management
export load_program!, remove_program!, can_load_program, clear_programs!

# Data transfer
export tryput!, trytake, tx_empty, tx_full, tx_level, rx_empty, rx_full, rx_level
export clear_fifos!, drain_tx!

# GPIO
export pio_pin_init!, gpio_init!, gpio_set_function!, gpio_set_pulls!
export gpio_pull_up!, gpio_pull_down!, gpio_disable_pulls!
export gpio_set_drive_strength!, gpio_set_input_enabled!

end # module PIOLib
