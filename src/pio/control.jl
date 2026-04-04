"""
    init!(sm, program_offset, config)

Initialise a state machine: apply `config`, set the program counter to `program_offset`,
and clear the FIFOs and shift counters. The SM is left disabled — call [`enable!`](@ref)
to start execution.
"""
function init!(sm::StateMachine, program_offset::Integer, config::SMConfig)
    LibPIO.pio_sm_init(sm.pio.handle, sm.sm, UInt32(program_offset), Ref(config._config))
    check_error!(sm.pio)
end

"""
    set_config!(sm, config)

Apply a new configuration to a running or stopped state machine. Does not reset the
program counter or FIFOs — use [`init!`](@ref) for a full reset.
"""
function set_config!(sm::StateMachine, config::SMConfig)
    LibPIO.pio_sm_set_config(sm.pio.handle, sm.sm, Ref(config._config))
end

"Start executing the loaded program."
enable!(sm::StateMachine) = LibPIO.pio_sm_set_enabled(sm.pio.handle, sm.sm, true)

"Stop execution. The SM retains its current state (PC, registers, FIFOs)."
disable!(sm::StateMachine) = LibPIO.pio_sm_set_enabled(sm.pio.handle, sm.sm, false)

"Reset the SM to a consistent state (clears FIFOs, shift counters, and stall flags). Does not affect the loaded program."
restart!(sm::StateMachine) = LibPIO.pio_sm_restart(sm.pio.handle, sm.sm)

"Restart the clock divider phase. Useful for synchronising multiple SMs."
restart_clkdiv!(sm::StateMachine) = LibPIO.pio_sm_clkdiv_restart(sm.pio.handle, sm.sm)

"""
    clkdiv(target_hz; sys_clk=200_000_000.0) -> Float32

Compute the SM clock divider needed to achieve `target_hz` execution frequency.
Each SM instruction takes one tick at this frequency (plus any delay cycles).

```julia
config.clkdiv = clkdiv(800_000)    # 800kHz SM clock from 200MHz sys_clk
```
"""
clkdiv(target_hz::Real; sys_clk::Real=200_000_000.0) = Float32(sys_clk / target_hz)

"""
    set_clkdiv!(sm, div::Real)
    set_clkdiv!(sm, div_int::Integer, div_frac::Integer)

Set the clock divider for a running SM. The SM executes one instruction every `div`
system clock cycles. `div` is a 16.8 fixed-point value (16-bit integer, 8-bit fraction
in units of 1/256). A divider of 1 runs at full system clock speed.
"""
function set_clkdiv!(sm::StateMachine, div::Real)
    LibPIO.pio_sm_set_clkdiv(sm.pio.handle, sm.sm, Float32(div))
end

function set_clkdiv!(sm::StateMachine, div_int::Integer, div_frac::Integer)
    LibPIO.pio_sm_set_clkdiv_int_frac(sm.pio.handle, sm.sm, UInt16(div_int), UInt8(div_frac))
end

"Write `values` to all 32 GPIO output pins for this SM."
function set_pins!(sm::StateMachine, values::UInt32)
    LibPIO.pio_sm_set_pins(sm.pio.handle, sm.sm, values)
end

"Write `values` to GPIO pins selected by `mask` (1 = write, 0 = leave unchanged)."
function set_pins!(sm::StateMachine, values::UInt32, mask::UInt32)
    LibPIO.pio_sm_set_pins_with_mask(sm.pio.handle, sm.sm, values, mask)
end

"Set pin directions for GPIOs selected by `mask` (1 = output, 0 = input)."
function set_pindirs!(sm::StateMachine, dirs::UInt32, mask::UInt32)
    LibPIO.pio_sm_set_pindirs_with_mask(sm.pio.handle, sm.sm, dirs, mask)
end

"Set `count` consecutive pins starting at `base` to output (`is_out=true`) or input."
function set_consecutive_pindirs!(sm::StateMachine, base::Integer, count::Integer, is_out::Bool)
    LibPIO.pio_sm_set_consecutive_pindirs(sm.pio.handle, sm.sm, UInt32(base), UInt32(count), is_out)
end

"""
    exec!(sm, instr::Integer)
    exec!(sm, instr::PIOInstruction)

Immediately execute a single PIO instruction, momentarily interrupting the
current program. The SM resumes its program on the next cycle. Useful for forcing a
JMP to a new location, or initialising registers from the system side.

The `PIOInstruction` form encodes the instruction on the fly. Label references are
not supported — use absolute addresses or instructions that don't need them.

```julia
exec!(sm, Set(PinDirs(), 1))       # set pin direction to output
exec!(sm, Jmp{:always}(0))         # jump to address 0
```
"""
function exec!(sm::StateMachine, instr::Integer)
    LibPIO.pio_sm_exec(sm.pio.handle, sm.sm, UInt32(instr))
end

function exec!(sm::StateMachine, instr::PIOInstruction)
    LibPIO.pio_sm_exec(sm.pio.handle, sm.sm, UInt32(encode_instr(instr)))
end

"""
    exec_blocking!(sm, instr::Integer)
    exec_blocking!(sm, instr::PIOInstruction)

Like [`exec!`](@ref) but waits for any currently stalled instruction to complete first.
"""
function exec_blocking!(sm::StateMachine, instr::Integer)
    LibPIO.pio_sm_exec_wait_blocking(sm.pio.handle, sm.sm, UInt32(instr))
end

function exec_blocking!(sm::StateMachine, instr::PIOInstruction)
    LibPIO.pio_sm_exec_wait_blocking(sm.pio.handle, sm.sm, UInt32(encode_instr(instr)))
end

"Configure the DMA request control register for TX (`is_tx=true`) or RX FIFO."
function set_dmactrl!(sm::StateMachine, is_tx::Bool, ctrl::UInt32)
    LibPIO.pio_sm_set_dmactrl(sm.pio.handle, sm.sm, is_tx, ctrl)
end
