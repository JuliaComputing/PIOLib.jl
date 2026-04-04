# Julia implementations of the static inline functions from piolib.h.
# These dispatch through the pio_chip vtable, matching the C header exactly.

const PIO_ORIGIN_ANY = typemax(UInt32)
const PIO_ORIGIN_INVALID = PIO_ORIGIN_ANY

# Vtable helpers

function _pio_is_err(pio::PIO)
    reinterpret(UInt, pio) >= reinterpret(UInt, Ptr{pio_instance}(-200))
end

function _get_chip(pio::PIO)
    (pio == C_NULL || _pio_is_err(pio)) &&
        error("PIO handle is invalid ($(reinterpret(UInt, pio))) — has pio_init() / pio_open() succeeded?")
    instance = unsafe_load(pio)
    instance.chip == C_NULL && error("PIO chip pointer is null")
    unsafe_load(instance.chip)
end

function _set_error!(pio::PIO, value::Bool)
    unsafe_store!(Ptr{Bool}(Ptr{UInt8}(pio) + fieldoffset(pio_instance, 4)), value)
end

# Instance field access

function pio_error(pio, msg)
    _set_error!(pio, true)
    instance = unsafe_load(pio)
    if instance.errors_are_fatal
        pio_panic(msg)
    end
end

pio_get_error(pio) = unsafe_load(pio).error
pio_clear_error(pio) = _set_error!(pio, false)

function pio_enable_fatal_errors(pio, enable)
    unsafe_store!(Ptr{Bool}(Ptr{UInt8}(pio) + fieldoffset(pio_instance, 3)), enable)
end

function pio_get_sm_count(pio)
    chip = _get_chip(pio)
    uint(chip.sm_count)
end

function pio_get_instruction_count(pio)
    chip = _get_chip(pio)
    uint(chip.instr_count)
end

function pio_get_fifo_depth(pio)
    chip = _get_chip(pio)
    uint(chip.fifo_depth)
end

function check_pio_param(pio)
    nothing
end

function check_gpio_param(gpio)
    nothing
end

# Program management

function pio_sm_config_xfer(pio, sm, dir, buf_size, buf_count)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_config_xfer, Cint, (PIO, uint, uint, uint, uint), pio, sm, dir, buf_size, buf_count)
end

function pio_sm_xfer_data(pio, sm, dir, data_bytes, data)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_xfer_data, Cint, (PIO, uint, uint, uint, Ptr{Cvoid}), pio, sm, dir, data_bytes, data)
end

function pio_can_add_program(pio, program)
    chip = _get_chip(pio)
    ccall(chip.pio_can_add_program_at_offset, Bool, (PIO, Ptr{pio_program_t}, uint), pio, program, PIO_ORIGIN_ANY)
end

function pio_can_add_program_at_offset(pio, program, offset)
    chip = _get_chip(pio)
    ccall(chip.pio_can_add_program_at_offset, Bool, (PIO, Ptr{pio_program_t}, uint), pio, program, offset)
end

function pio_add_program(pio, program)
    chip = _get_chip(pio)
    offset = ccall(chip.pio_add_program_at_offset, uint, (PIO, Ptr{pio_program_t}, uint), pio, program, PIO_ORIGIN_ANY)
    if offset == PIO_ORIGIN_INVALID
        pio_error(pio, "No program space")
    end
    offset
end

function pio_add_program_at_offset(pio, program, offset)
    chip = _get_chip(pio)
    if ccall(chip.pio_add_program_at_offset, uint, (PIO, Ptr{pio_program_t}, uint), pio, program, offset) == PIO_ORIGIN_INVALID
        pio_error(pio, "No program space")
    end
end

function pio_remove_program(pio, program, loaded_offset)
    chip = _get_chip(pio)
    if !ccall(chip.pio_remove_program, Bool, (PIO, Ptr{pio_program_t}, uint), pio, program, loaded_offset)
        pio_error(pio, "Failed to remove program")
    end
end

function pio_clear_instruction_memory(pio)
    chip = _get_chip(pio)
    if !ccall(chip.pio_clear_instruction_memory, Bool, (PIO,), pio)
        pio_error(pio, "Failed to clear instruction memory")
    end
end

# Instruction encoding (uses pio_get_current())

function pio_encode_delay(cycles)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.pio_encode_delay, uint, (PIO, uint), pio, cycles)
end

function pio_encode_sideset(sideset_bit_count, value)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.pio_encode_sideset, uint, (PIO, uint, uint), pio, sideset_bit_count, value)
end

function pio_encode_sideset_opt(sideset_bit_count, value)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.pio_encode_sideset_opt, uint, (PIO, uint, uint), pio, sideset_bit_count, value)
end

for name in (:jmp, :jmp_not_x, :jmp_x_dec, :jmp_not_y, :jmp_y_dec, :jmp_x_ne_y, :jmp_pin, :jmp_not_osre)
    func = Symbol(:pio_encode_, name)
    field = Symbol(:pio_encode_, name)
    @eval function $func(addr)
        pio = pio_get_current()
        chip = _get_chip(pio)
        ccall(chip.$field, uint, (PIO, uint), pio, addr)
    end
end

function pio_encode_wait_gpio(polarity, gpio)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.pio_encode_wait_gpio, uint, (PIO, Bool, uint), pio, polarity, gpio)
end

function pio_encode_wait_pin(polarity, pin)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.pio_encode_wait_pin, uint, (PIO, Bool, uint), pio, polarity, pin)
end

function pio_encode_wait_irq(polarity, relative, irq)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.pio_encode_wait_irq, uint, (PIO, Bool, Bool, uint), pio, polarity, relative, irq)
end

function pio_encode_in(src, count)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.pio_encode_in, uint, (PIO, pio_src_dest, uint), pio, src, count)
end

function pio_encode_out(dest, count)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.pio_encode_out, uint, (PIO, pio_src_dest, uint), pio, dest, count)
end

function pio_encode_push(if_full, block)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.pio_encode_push, uint, (PIO, Bool, Bool), pio, if_full, block)
end

function pio_encode_pull(if_empty, block)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.pio_encode_pull, uint, (PIO, Bool, Bool), pio, if_empty, block)
end

for name in (:mov, :mov_not, :mov_reverse)
    func = Symbol(:pio_encode_, name)
    field = Symbol(:pio_encode_, name)
    @eval function $func(dest, src)
        pio = pio_get_current()
        chip = _get_chip(pio)
        ccall(chip.$field, uint, (PIO, pio_src_dest, pio_src_dest), pio, dest, src)
    end
end

for name in (:irq_set, :irq_wait, :irq_clear)
    func = Symbol(:pio_encode_, name)
    field = Symbol(:pio_encode_, name)
    @eval function $func(relative, irq)
        pio = pio_get_current()
        chip = _get_chip(pio)
        ccall(chip.$field, uint, (PIO, Bool, uint), pio, relative, irq)
    end
end

function pio_encode_set(dest, value)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.pio_encode_set, uint, (PIO, pio_src_dest, uint), pio, dest, value)
end

function pio_encode_nop()
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.pio_encode_nop, uint, (PIO,), pio)
end

# State machine claiming

function pio_sm_claim(pio, sm)
    chip = _get_chip(pio)
    if !ccall(chip.pio_sm_claim, Bool, (PIO, uint), pio, sm)
        pio_error(pio, "Failed to claim SM")
    end
end

function pio_claim_sm_mask(pio, mask)
    chip = _get_chip(pio)
    if !ccall(chip.pio_sm_claim_mask, Bool, (PIO, uint), pio, mask)
        pio_error(pio, "Failed to claim masked SMs")
    end
end

function pio_sm_unclaim(pio, sm)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_unclaim, Bool, (PIO, uint), pio, sm)
    nothing
end

function pio_claim_unused_sm(pio, required)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_claim_unused, Cint, (PIO, Bool), pio, required)
end

function pio_sm_is_claimed(pio, sm)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_is_claimed, Bool, (PIO, uint), pio, sm)
end

# State machine control

function pio_sm_init(pio, sm, initial_pc, config)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_init, Cvoid, (PIO, uint, uint, Ptr{pio_sm_config}), pio, sm, initial_pc, config)
end

function pio_sm_set_config(pio, sm, config)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_set_config, Cvoid, (PIO, uint, Ptr{pio_sm_config}), pio, sm, config)
end

function pio_sm_exec(pio, sm, instr)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_exec, Cvoid, (PIO, uint, uint, Bool), pio, sm, instr, false)
end

function pio_sm_exec_wait_blocking(pio, sm, instr)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_exec, Cvoid, (PIO, uint, uint, Bool), pio, sm, instr, true)
end

function pio_sm_clear_fifos(pio, sm)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_clear_fifos, Cvoid, (PIO, uint), pio, sm)
end

function pio_sm_set_clkdiv_int_frac(pio, sm, div_int, div_frac)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_set_clkdiv_int_frac, Cvoid, (PIO, uint, UInt16, UInt8), pio, sm, div_int, div_frac)
end

function pio_sm_set_clkdiv(pio, sm, div)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_set_clkdiv, Cvoid, (PIO, uint, Cfloat), pio, sm, div)
end

function pio_sm_set_pins(pio, sm, pin_values)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_set_pins, Cvoid, (PIO, uint, UInt32), pio, sm, pin_values)
end

function pio_sm_set_pins_with_mask(pio, sm, pin_values, pin_mask)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_set_pins_with_mask, Cvoid, (PIO, uint, UInt32, UInt32), pio, sm, pin_values, pin_mask)
end

function pio_sm_set_pindirs_with_mask(pio, sm, pin_dirs, pin_mask)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_set_pindirs_with_mask, Cvoid, (PIO, uint, UInt32, UInt32), pio, sm, pin_dirs, pin_mask)
end

function pio_sm_set_consecutive_pindirs(pio, sm, pin_base, pin_count, is_out)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_set_consecutive_pindirs, Cvoid, (PIO, uint, uint, uint, Bool), pio, sm, pin_base, pin_count, is_out)
end

function pio_sm_set_enabled(pio, sm, enabled)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_set_enabled, Cvoid, (PIO, uint, Bool), pio, sm, enabled)
end

function pio_set_sm_mask_enabled(pio, mask, enabled)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_set_enabled_mask, Cvoid, (PIO, UInt32, Bool), pio, mask, enabled)
end

function pio_sm_restart(pio, sm)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_restart, Cvoid, (PIO, uint), pio, sm)
end

function pio_restart_sm_mask(pio, mask)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_restart_mask, Cvoid, (PIO, UInt32), pio, mask)
end

function pio_sm_clkdiv_restart(pio, sm)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_clkdiv_restart, Cvoid, (PIO, uint), pio, sm)
end

function pio_clkdiv_restart_sm_mask(pio, mask)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_clkdiv_restart_mask, Cvoid, (PIO, UInt32), pio, mask)
end

function pio_enable_sm_in_sync_mask(pio, mask)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_enable_sync, Cvoid, (PIO, UInt32), pio, mask)
end

function pio_sm_set_dmactrl(pio, sm, is_tx, ctrl)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_set_dmactrl, Cvoid, (PIO, uint, Bool, UInt32), pio, sm, is_tx, ctrl)
end

# FIFO data transfer

function pio_sm_is_rx_fifo_empty(pio, sm)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_is_rx_fifo_empty, Bool, (PIO, uint), pio, sm)
end

function pio_sm_is_rx_fifo_full(pio, sm)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_is_rx_fifo_full, Bool, (PIO, uint), pio, sm)
end

function pio_sm_get_rx_fifo_level(pio, sm)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_get_rx_fifo_level, uint, (PIO, uint), pio, sm)
end

function pio_sm_is_tx_fifo_empty(pio, sm)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_is_tx_fifo_empty, Bool, (PIO, uint), pio, sm)
end

function pio_sm_is_tx_fifo_full(pio, sm)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_is_tx_fifo_full, Bool, (PIO, uint), pio, sm)
end

function pio_sm_get_tx_fifo_level(pio, sm)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_get_tx_fifo_level, uint, (PIO, uint), pio, sm)
end

function pio_sm_drain_tx_fifo(pio, sm)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_drain_tx_fifo, Cvoid, (PIO, uint), pio, sm)
end

function pio_sm_put(pio, sm, data)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_put, Cvoid, (PIO, uint, UInt32, Bool), pio, sm, data, false)
end

function pio_sm_put_blocking(pio, sm, data)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_put, Cvoid, (PIO, uint, UInt32, Bool), pio, sm, data, true)
end

function pio_sm_get(pio, sm)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_get, UInt32, (PIO, uint, Bool), pio, sm, false)
end

function pio_sm_get_blocking(pio, sm)
    chip = _get_chip(pio)
    ccall(chip.pio_sm_get, UInt32, (PIO, uint, Bool), pio, sm, true)
end

# SM config

function pio_get_default_sm_config_for_pio(pio)
    chip = _get_chip(pio)
    ccall(chip.pio_get_default_sm_config, pio_sm_config, (PIO,), pio)
end

function pio_get_default_sm_config()
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.pio_get_default_sm_config, pio_sm_config, (PIO,), pio)
end

function sm_config_set_out_pins(c, out_base, out_count)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.smc_set_out_pins, Cvoid, (PIO, Ptr{pio_sm_config}, uint, uint), pio, c, out_base, out_count)
end

function sm_config_set_set_pins(c, set_base, set_count)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.smc_set_set_pins, Cvoid, (PIO, Ptr{pio_sm_config}, uint, uint), pio, c, set_base, set_count)
end

function sm_config_set_in_pins(c, in_base)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.smc_set_in_pins, Cvoid, (PIO, Ptr{pio_sm_config}, uint), pio, c, in_base)
end

function sm_config_set_sideset_pins(c, sideset_base)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.smc_set_sideset_pins, Cvoid, (PIO, Ptr{pio_sm_config}, uint), pio, c, sideset_base)
end

function sm_config_set_sideset(c, bit_count, optional, pindirs)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.smc_set_sideset, Cvoid, (PIO, Ptr{pio_sm_config}, uint, Bool, Bool), pio, c, bit_count, optional, pindirs)
end

function sm_config_set_clkdiv_int_frac(c, div_int, div_frac)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.smc_set_clkdiv_int_frac, Cvoid, (PIO, Ptr{pio_sm_config}, UInt16, UInt8), pio, c, div_int, div_frac)
end

function sm_config_set_clkdiv(c, div)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.smc_set_clkdiv, Cvoid, (PIO, Ptr{pio_sm_config}, Cfloat), pio, c, div)
end

function sm_config_set_wrap(c, wrap_target, wrap)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.smc_set_wrap, Cvoid, (PIO, Ptr{pio_sm_config}, uint, uint), pio, c, wrap_target, wrap)
end

function sm_config_set_jmp_pin(c, pin)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.smc_set_jmp_pin, Cvoid, (PIO, Ptr{pio_sm_config}, uint), pio, c, pin)
end

function sm_config_set_in_shift(c, shift_right, autopush, push_threshold)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.smc_set_in_shift, Cvoid, (PIO, Ptr{pio_sm_config}, Bool, Bool, uint), pio, c, shift_right, autopush, push_threshold)
end

function sm_config_set_out_shift(c, shift_right, autopull, pull_threshold)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.smc_set_out_shift, Cvoid, (PIO, Ptr{pio_sm_config}, Bool, Bool, uint), pio, c, shift_right, autopull, pull_threshold)
end

function sm_config_set_fifo_join(c, join)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.smc_set_fifo_join, Cvoid, (PIO, Ptr{pio_sm_config}, pio_fifo_join), pio, c, join)
end

function sm_config_set_out_special(c, sticky, has_enable_pin, enable_pin_index)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.smc_set_out_special, Cvoid, (PIO, Ptr{pio_sm_config}, Bool, Bool, uint), pio, c, sticky, has_enable_pin, enable_pin_index)
end

function sm_config_set_mov_status(c, status_sel, status_n)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.smc_set_mov_status, Cvoid, (PIO, Ptr{pio_sm_config}, pio_mov_status_type, uint), pio, c, status_sel, status_n)
end

# GPIO

function pio_gpio_init(pio, pin)
    chip = _get_chip(pio)
    ccall(chip.pio_gpio_init, Cvoid, (PIO, uint), pio, pin)
end

function clock_get_hz(clk_index)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.clock_get_hz, UInt32, (PIO, clock_index), pio, clk_index)
end

function gpio_init(gpio)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.gpio_init, Cvoid, (PIO, uint), pio, gpio)
end

function gpio_set_function(gpio, fn)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.gpio_set_function, Cvoid, (PIO, uint, gpio_function), pio, gpio, fn)
end

function gpio_set_pulls(gpio, up, down)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.gpio_set_pulls, Cvoid, (PIO, uint, Bool, Bool), pio, gpio, up, down)
end

function gpio_set_outover(gpio, value)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.gpio_set_outover, Cvoid, (PIO, uint, uint), pio, gpio, value)
end

function gpio_set_inover(gpio, value)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.gpio_set_inover, Cvoid, (PIO, uint, uint), pio, gpio, value)
end

function gpio_set_oeover(gpio, value)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.gpio_set_oeover, Cvoid, (PIO, uint, uint), pio, gpio, value)
end

function gpio_set_input_enabled(gpio, enabled)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.gpio_set_input_enabled, Cvoid, (PIO, uint, Bool), pio, gpio, enabled)
end

function gpio_set_drive_strength(gpio, drive)
    pio = pio_get_current()
    chip = _get_chip(pio)
    ccall(chip.gpio_set_drive_strength, Cvoid, (PIO, uint, gpio_drive_strength), pio, gpio, drive)
end

gpio_pull_up(gpio) = gpio_set_pulls(gpio, true, false)
gpio_pull_down(gpio) = gpio_set_pulls(gpio, false, true)
gpio_disable_pulls(gpio) = gpio_set_pulls(gpio, false, false)

stdio_init_all() = nothing

function sleep_ms(ms)
    sleep_us(UInt64(ms) * UInt64(1000))
end
