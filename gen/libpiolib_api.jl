using PIOLib_jll
export PIOLib_jll

using CEnum: CEnum, @cenum

const uint = Cuint

struct pio_chip
    name::Ptr{Cchar}
    compatible::Ptr{Cchar}
    instr_count::UInt16
    sm_count::UInt16
    fifo_depth::UInt16
    hw_state::Ptr{Cvoid}
    create_instance::Ptr{Cvoid}
    open_instance::Ptr{Cvoid}
    close_instance::Ptr{Cvoid}
    pio_sm_config_xfer::Ptr{Cvoid}
    pio_sm_xfer_data::Ptr{Cvoid}
    pio_can_add_program_at_offset::Ptr{Cvoid}
    pio_add_program_at_offset::Ptr{Cvoid}
    pio_remove_program::Ptr{Cvoid}
    pio_clear_instruction_memory::Ptr{Cvoid}
    pio_encode_delay::Ptr{Cvoid}
    pio_encode_sideset::Ptr{Cvoid}
    pio_encode_sideset_opt::Ptr{Cvoid}
    pio_encode_jmp::Ptr{Cvoid}
    pio_encode_jmp_not_x::Ptr{Cvoid}
    pio_encode_jmp_x_dec::Ptr{Cvoid}
    pio_encode_jmp_not_y::Ptr{Cvoid}
    pio_encode_jmp_y_dec::Ptr{Cvoid}
    pio_encode_jmp_x_ne_y::Ptr{Cvoid}
    pio_encode_jmp_pin::Ptr{Cvoid}
    pio_encode_jmp_not_osre::Ptr{Cvoid}
    pio_encode_wait_gpio::Ptr{Cvoid}
    pio_encode_wait_pin::Ptr{Cvoid}
    pio_encode_wait_irq::Ptr{Cvoid}
    pio_encode_in::Ptr{Cvoid}
    pio_encode_out::Ptr{Cvoid}
    pio_encode_push::Ptr{Cvoid}
    pio_encode_pull::Ptr{Cvoid}
    pio_encode_mov::Ptr{Cvoid}
    pio_encode_mov_not::Ptr{Cvoid}
    pio_encode_mov_reverse::Ptr{Cvoid}
    pio_encode_irq_set::Ptr{Cvoid}
    pio_encode_irq_wait::Ptr{Cvoid}
    pio_encode_irq_clear::Ptr{Cvoid}
    pio_encode_set::Ptr{Cvoid}
    pio_encode_nop::Ptr{Cvoid}
    pio_sm_claim::Ptr{Cvoid}
    pio_sm_claim_mask::Ptr{Cvoid}
    pio_sm_claim_unused::Ptr{Cvoid}
    pio_sm_unclaim::Ptr{Cvoid}
    pio_sm_is_claimed::Ptr{Cvoid}
    pio_sm_init::Ptr{Cvoid}
    pio_sm_set_config::Ptr{Cvoid}
    pio_sm_exec::Ptr{Cvoid}
    pio_sm_clear_fifos::Ptr{Cvoid}
    pio_sm_set_clkdiv_int_frac::Ptr{Cvoid}
    pio_sm_set_clkdiv::Ptr{Cvoid}
    pio_sm_set_pins::Ptr{Cvoid}
    pio_sm_set_pins_with_mask::Ptr{Cvoid}
    pio_sm_set_pindirs_with_mask::Ptr{Cvoid}
    pio_sm_set_consecutive_pindirs::Ptr{Cvoid}
    pio_sm_set_enabled::Ptr{Cvoid}
    pio_sm_set_enabled_mask::Ptr{Cvoid}
    pio_sm_restart::Ptr{Cvoid}
    pio_sm_restart_mask::Ptr{Cvoid}
    pio_sm_clkdiv_restart::Ptr{Cvoid}
    pio_sm_clkdiv_restart_mask::Ptr{Cvoid}
    pio_sm_enable_sync::Ptr{Cvoid}
    pio_sm_put::Ptr{Cvoid}
    pio_sm_get::Ptr{Cvoid}
    pio_sm_set_dmactrl::Ptr{Cvoid}
    pio_sm_is_rx_fifo_empty::Ptr{Cvoid}
    pio_sm_is_rx_fifo_full::Ptr{Cvoid}
    pio_sm_get_rx_fifo_level::Ptr{Cvoid}
    pio_sm_is_tx_fifo_empty::Ptr{Cvoid}
    pio_sm_is_tx_fifo_full::Ptr{Cvoid}
    pio_sm_get_tx_fifo_level::Ptr{Cvoid}
    pio_sm_drain_tx_fifo::Ptr{Cvoid}
    pio_get_default_sm_config::Ptr{Cvoid}
    smc_set_out_pins::Ptr{Cvoid}
    smc_set_set_pins::Ptr{Cvoid}
    smc_set_in_pins::Ptr{Cvoid}
    smc_set_sideset_pins::Ptr{Cvoid}
    smc_set_sideset::Ptr{Cvoid}
    smc_set_clkdiv_int_frac::Ptr{Cvoid}
    smc_set_clkdiv::Ptr{Cvoid}
    smc_set_wrap::Ptr{Cvoid}
    smc_set_jmp_pin::Ptr{Cvoid}
    smc_set_in_shift::Ptr{Cvoid}
    smc_set_out_shift::Ptr{Cvoid}
    smc_set_fifo_join::Ptr{Cvoid}
    smc_set_out_special::Ptr{Cvoid}
    smc_set_mov_status::Ptr{Cvoid}
    clock_get_hz::Ptr{Cvoid}
    pio_gpio_init::Ptr{Cvoid}
    gpio_init::Ptr{Cvoid}
    gpio_set_function::Ptr{Cvoid}
    gpio_set_pulls::Ptr{Cvoid}
    gpio_set_outover::Ptr{Cvoid}
    gpio_set_inover::Ptr{Cvoid}
    gpio_set_oeover::Ptr{Cvoid}
    gpio_set_input_enabled::Ptr{Cvoid}
    gpio_set_drive_strength::Ptr{Cvoid}
end

const PIO_CHIP_T = pio_chip

struct pio_instance
    chip::Ptr{PIO_CHIP_T}
    in_use::Cint
    errors_are_fatal::Bool
    error::Bool
end

const PIO = Ptr{pio_instance}

function pio_open_helper(idx)
    ccall((:pio_open_helper, libpio), PIO, (uint,), idx)
end

@cenum clock_index::UInt32 begin
    clk_gpout0 = 0
    clk_gpout1 = 1
    clk_gpout2 = 2
    clk_gpout3 = 3
    clk_ref = 4
    clk_sys = 5
    clk_peri = 6
    clk_usb = 7
    clk_adc = 8
    clk_rtc = 9
    CLK_COUNT = 10
end

@cenum gpio_function::UInt32 begin
    GPIO_FUNC_XIP = 0
    GPIO_FUNC_SPI = 1
    GPIO_FUNC_UART = 2
    GPIO_FUNC_I2C = 3
    GPIO_FUNC_PWM = 4
    GPIO_FUNC_SIO = 5
    GPIO_FUNC_PIO0 = 6
    GPIO_FUNC_PIO1 = 7
    GPIO_FUNC_GPCK = 8
    GPIO_FUNC_USB = 9
    GPIO_FUNC_NULL = 31
end

@cenum gpio_irq_level::UInt32 begin
    GPIO_IRQ_LEVEL_LOW = 1
    GPIO_IRQ_LEVEL_HIGH = 2
    GPIO_IRQ_EDGE_FALL = 4
    GPIO_IRQ_EDGE_RISE = 8
end

@cenum gpio_override::UInt32 begin
    GPIO_OVERRIDE_NORMAL = 0
    GPIO_OVERRIDE_INVERT = 1
    GPIO_OVERRIDE_LOW = 2
    GPIO_OVERRIDE_HIGH = 3
end

@cenum gpio_slew_rate::UInt32 begin
    GPIO_SLEW_RATE_SLOW = 0
    GPIO_SLEW_RATE_FAST = 1
end

@cenum gpio_drive_strength::UInt32 begin
    GPIO_DRIVE_STRENGTH_2MA = 0
    GPIO_DRIVE_STRENGTH_4MA = 1
    GPIO_DRIVE_STRENGTH_8MA = 2
    GPIO_DRIVE_STRENGTH_12MA = 3
end

function check_gpio_param(gpio)
    ccall((:check_gpio_param, libpio), Cvoid, (uint,), gpio)
end

@cenum pio_fifo_join::UInt32 begin
    PIO_FIFO_JOIN_NONE = 0
    PIO_FIFO_JOIN_TX = 1
    PIO_FIFO_JOIN_RX = 2
end

@cenum pio_mov_status_type::UInt32 begin
    STATUS_TX_LESSTHAN = 0
    STATUS_RX_LESSTHAN = 1
end

@cenum pio_xfer_dir::UInt32 begin
    PIO_DIR_TO_SM = 0
    PIO_DIR_FROM_SM = 1
    PIO_DIR_COUNT = 2
end

@cenum pio_instr_bits::UInt32 begin
    pio_instr_bits_jmp = 0
    pio_instr_bits_wait = 8192
    pio_instr_bits_in = 16384
    pio_instr_bits_out = 24576
    pio_instr_bits_push = 32768
    pio_instr_bits_pull = 32896
    pio_instr_bits_mov = 40960
    pio_instr_bits_irq = 49152
    pio_instr_bits_set = 57344
end

@cenum pio_src_dest::UInt32 begin
    pio_pins = 0
    pio_x = 1
    pio_y = 2
    pio_null = 163
    pio_pindirs = 204
    pio_exec_mov = 124
    pio_status = 189
    pio_pc = 109
    pio_isr = 38
    pio_osr = 55
    pio_exec_out = 239
end

struct pio_program
    instructions::Ptr{UInt16}
    length::UInt8
    origin::Int8
    pio_version::UInt8
end

const pio_program_t = pio_program

struct pio_sm_config
    content::NTuple{4, UInt32}
end

function pio_init()
    ccall((:pio_init, libpio), Cint, ())
end

function pio_open(idx)
    ccall((:pio_open, libpio), PIO, (uint,), idx)
end

function pio_open_by_name(name)
    ccall((:pio_open_by_name, libpio), PIO, (Ptr{Cchar},), name)
end

function pio_close(pio)
    ccall((:pio_close, libpio), Cvoid, (PIO,), pio)
end

function pio_panic(msg)
    ccall((:pio_panic, libpio), Cvoid, (Ptr{Cchar},), msg)
end

function pio_get_index(pio)
    ccall((:pio_get_index, libpio), Cint, (PIO,), pio)
end

function pio_select(pio)
    ccall((:pio_select, libpio), Cvoid, (PIO,), pio)
end

function pio_get_current()
    ccall((:pio_get_current, libpio), PIO, ())
end

function pio_error(pio, msg)
    ccall((:pio_error, libpio), Cvoid, (PIO, Ptr{Cchar}), pio, msg)
end

function pio_get_error(pio)
    ccall((:pio_get_error, libpio), Bool, (PIO,), pio)
end

function pio_clear_error(pio)
    ccall((:pio_clear_error, libpio), Cvoid, (PIO,), pio)
end

function pio_enable_fatal_errors(pio, enable)
    ccall((:pio_enable_fatal_errors, libpio), Cvoid, (PIO, Bool), pio, enable)
end

function pio_get_sm_count(pio)
    ccall((:pio_get_sm_count, libpio), uint, (PIO,), pio)
end

function pio_get_instruction_count(pio)
    ccall((:pio_get_instruction_count, libpio), uint, (PIO,), pio)
end

function pio_get_fifo_depth(pio)
    ccall((:pio_get_fifo_depth, libpio), uint, (PIO,), pio)
end

function check_pio_param(pio)
    ccall((:check_pio_param, libpio), Cvoid, (PIO,), pio)
end

function pio_sm_config_xfer(pio, sm, dir, buf_size, buf_count)
    ccall((:pio_sm_config_xfer, libpio), Cint, (PIO, uint, uint, uint, uint), pio, sm, dir, buf_size, buf_count)
end

function pio_sm_xfer_data(pio, sm, dir, data_bytes, data)
    ccall((:pio_sm_xfer_data, libpio), Cint, (PIO, uint, uint, uint, Ptr{Cvoid}), pio, sm, dir, data_bytes, data)
end

function pio_can_add_program(pio, program)
    ccall((:pio_can_add_program, libpio), Bool, (PIO, Ptr{pio_program_t}), pio, program)
end

function pio_can_add_program_at_offset(pio, program, offset)
    ccall((:pio_can_add_program_at_offset, libpio), Bool, (PIO, Ptr{pio_program_t}, uint), pio, program, offset)
end

function pio_add_program(pio, program)
    ccall((:pio_add_program, libpio), uint, (PIO, Ptr{pio_program_t}), pio, program)
end

function pio_add_program_at_offset(pio, program, offset)
    ccall((:pio_add_program_at_offset, libpio), Cvoid, (PIO, Ptr{pio_program_t}, uint), pio, program, offset)
end

function pio_remove_program(pio, program, loaded_offset)
    ccall((:pio_remove_program, libpio), Cvoid, (PIO, Ptr{pio_program_t}, uint), pio, program, loaded_offset)
end

function pio_clear_instruction_memory(pio)
    ccall((:pio_clear_instruction_memory, libpio), Cvoid, (PIO,), pio)
end

function pio_encode_delay(cycles)
    ccall((:pio_encode_delay, libpio), uint, (uint,), cycles)
end

function pio_encode_sideset(sideset_bit_count, value)
    ccall((:pio_encode_sideset, libpio), uint, (uint, uint), sideset_bit_count, value)
end

function pio_encode_sideset_opt(sideset_bit_count, value)
    ccall((:pio_encode_sideset_opt, libpio), uint, (uint, uint), sideset_bit_count, value)
end

function pio_encode_jmp(addr)
    ccall((:pio_encode_jmp, libpio), uint, (uint,), addr)
end

function pio_encode_jmp_not_x(addr)
    ccall((:pio_encode_jmp_not_x, libpio), uint, (uint,), addr)
end

function pio_encode_jmp_x_dec(addr)
    ccall((:pio_encode_jmp_x_dec, libpio), uint, (uint,), addr)
end

function pio_encode_jmp_not_y(addr)
    ccall((:pio_encode_jmp_not_y, libpio), uint, (uint,), addr)
end

function pio_encode_jmp_y_dec(addr)
    ccall((:pio_encode_jmp_y_dec, libpio), uint, (uint,), addr)
end

function pio_encode_jmp_x_ne_y(addr)
    ccall((:pio_encode_jmp_x_ne_y, libpio), uint, (uint,), addr)
end

function pio_encode_jmp_pin(addr)
    ccall((:pio_encode_jmp_pin, libpio), uint, (uint,), addr)
end

function pio_encode_jmp_not_osre(addr)
    ccall((:pio_encode_jmp_not_osre, libpio), uint, (uint,), addr)
end

function pio_encode_wait_gpio(polarity, gpio)
    ccall((:pio_encode_wait_gpio, libpio), uint, (Bool, uint), polarity, gpio)
end

function pio_encode_wait_pin(polarity, pin)
    ccall((:pio_encode_wait_pin, libpio), uint, (Bool, uint), polarity, pin)
end

function pio_encode_wait_irq(polarity, relative, irq)
    ccall((:pio_encode_wait_irq, libpio), uint, (Bool, Bool, uint), polarity, relative, irq)
end

function pio_encode_in(src, count)
    ccall((:pio_encode_in, libpio), uint, (pio_src_dest, uint), src, count)
end

function pio_encode_out(dest, count)
    ccall((:pio_encode_out, libpio), uint, (pio_src_dest, uint), dest, count)
end

function pio_encode_push(if_full, block)
    ccall((:pio_encode_push, libpio), uint, (Bool, Bool), if_full, block)
end

function pio_encode_pull(if_empty, block)
    ccall((:pio_encode_pull, libpio), uint, (Bool, Bool), if_empty, block)
end

function pio_encode_mov(dest, src)
    ccall((:pio_encode_mov, libpio), uint, (pio_src_dest, pio_src_dest), dest, src)
end

function pio_encode_mov_not(dest, src)
    ccall((:pio_encode_mov_not, libpio), uint, (pio_src_dest, pio_src_dest), dest, src)
end

function pio_encode_mov_reverse(dest, src)
    ccall((:pio_encode_mov_reverse, libpio), uint, (pio_src_dest, pio_src_dest), dest, src)
end

function pio_encode_irq_set(relative, irq)
    ccall((:pio_encode_irq_set, libpio), uint, (Bool, uint), relative, irq)
end

function pio_encode_irq_wait(relative, irq)
    ccall((:pio_encode_irq_wait, libpio), uint, (Bool, uint), relative, irq)
end

function pio_encode_irq_clear(relative, irq)
    ccall((:pio_encode_irq_clear, libpio), uint, (Bool, uint), relative, irq)
end

function pio_encode_set(dest, value)
    ccall((:pio_encode_set, libpio), uint, (pio_src_dest, uint), dest, value)
end

function pio_encode_nop()
    ccall((:pio_encode_nop, libpio), uint, ())
end

function pio_sm_claim(pio, sm)
    ccall((:pio_sm_claim, libpio), Cvoid, (PIO, uint), pio, sm)
end

function pio_claim_sm_mask(pio, mask)
    ccall((:pio_claim_sm_mask, libpio), Cvoid, (PIO, uint), pio, mask)
end

function pio_sm_unclaim(pio, sm)
    ccall((:pio_sm_unclaim, libpio), Cvoid, (PIO, uint), pio, sm)
end

function pio_claim_unused_sm(pio, required)
    ccall((:pio_claim_unused_sm, libpio), Cint, (PIO, Bool), pio, required)
end

function pio_sm_is_claimed(pio, sm)
    ccall((:pio_sm_is_claimed, libpio), Bool, (PIO, uint), pio, sm)
end

function pio_sm_init(pio, sm, initial_pc, config)
    ccall((:pio_sm_init, libpio), Cvoid, (PIO, uint, uint, Ptr{pio_sm_config}), pio, sm, initial_pc, config)
end

function pio_sm_set_config(pio, sm, config)
    ccall((:pio_sm_set_config, libpio), Cvoid, (PIO, uint, Ptr{pio_sm_config}), pio, sm, config)
end

function pio_sm_exec(pio, sm, instr)
    ccall((:pio_sm_exec, libpio), Cvoid, (PIO, uint, uint), pio, sm, instr)
end

function pio_sm_exec_wait_blocking(pio, sm, instr)
    ccall((:pio_sm_exec_wait_blocking, libpio), Cvoid, (PIO, uint, uint), pio, sm, instr)
end

function pio_sm_clear_fifos(pio, sm)
    ccall((:pio_sm_clear_fifos, libpio), Cvoid, (PIO, uint), pio, sm)
end

function pio_sm_set_clkdiv_int_frac(pio, sm, div_int, div_frac)
    ccall((:pio_sm_set_clkdiv_int_frac, libpio), Cvoid, (PIO, uint, UInt16, UInt8), pio, sm, div_int, div_frac)
end

function pio_sm_set_clkdiv(pio, sm, div)
    ccall((:pio_sm_set_clkdiv, libpio), Cvoid, (PIO, uint, Cfloat), pio, sm, div)
end

function pio_sm_set_pins(pio, sm, pin_values)
    ccall((:pio_sm_set_pins, libpio), Cvoid, (PIO, uint, UInt32), pio, sm, pin_values)
end

function pio_sm_set_pins_with_mask(pio, sm, pin_values, pin_mask)
    ccall((:pio_sm_set_pins_with_mask, libpio), Cvoid, (PIO, uint, UInt32, UInt32), pio, sm, pin_values, pin_mask)
end

function pio_sm_set_pindirs_with_mask(pio, sm, pin_dirs, pin_mask)
    ccall((:pio_sm_set_pindirs_with_mask, libpio), Cvoid, (PIO, uint, UInt32, UInt32), pio, sm, pin_dirs, pin_mask)
end

function pio_sm_set_consecutive_pindirs(pio, sm, pin_base, pin_count, is_out)
    ccall((:pio_sm_set_consecutive_pindirs, libpio), Cvoid, (PIO, uint, uint, uint, Bool), pio, sm, pin_base, pin_count, is_out)
end

function pio_sm_set_enabled(pio, sm, enabled)
    ccall((:pio_sm_set_enabled, libpio), Cvoid, (PIO, uint, Bool), pio, sm, enabled)
end

function pio_set_sm_mask_enabled(pio, mask, enabled)
    ccall((:pio_set_sm_mask_enabled, libpio), Cvoid, (PIO, UInt32, Bool), pio, mask, enabled)
end

function pio_sm_restart(pio, sm)
    ccall((:pio_sm_restart, libpio), Cvoid, (PIO, uint), pio, sm)
end

function pio_restart_sm_mask(pio, mask)
    ccall((:pio_restart_sm_mask, libpio), Cvoid, (PIO, UInt32), pio, mask)
end

function pio_sm_clkdiv_restart(pio, sm)
    ccall((:pio_sm_clkdiv_restart, libpio), Cvoid, (PIO, uint), pio, sm)
end

function pio_clkdiv_restart_sm_mask(pio, mask)
    ccall((:pio_clkdiv_restart_sm_mask, libpio), Cvoid, (PIO, UInt32), pio, mask)
end

function pio_enable_sm_in_sync_mask(pio, mask)
    ccall((:pio_enable_sm_in_sync_mask, libpio), Cvoid, (PIO, UInt32), pio, mask)
end

function pio_sm_set_dmactrl(pio, sm, is_tx, ctrl)
    ccall((:pio_sm_set_dmactrl, libpio), Cvoid, (PIO, uint, Bool, UInt32), pio, sm, is_tx, ctrl)
end

function pio_sm_is_rx_fifo_empty(pio, sm)
    ccall((:pio_sm_is_rx_fifo_empty, libpio), Bool, (PIO, uint), pio, sm)
end

function pio_sm_is_rx_fifo_full(pio, sm)
    ccall((:pio_sm_is_rx_fifo_full, libpio), Bool, (PIO, uint), pio, sm)
end

function pio_sm_get_rx_fifo_level(pio, sm)
    ccall((:pio_sm_get_rx_fifo_level, libpio), uint, (PIO, uint), pio, sm)
end

function pio_sm_is_tx_fifo_empty(pio, sm)
    ccall((:pio_sm_is_tx_fifo_empty, libpio), Bool, (PIO, uint), pio, sm)
end

function pio_sm_is_tx_fifo_full(pio, sm)
    ccall((:pio_sm_is_tx_fifo_full, libpio), Bool, (PIO, uint), pio, sm)
end

function pio_sm_get_tx_fifo_level(pio, sm)
    ccall((:pio_sm_get_tx_fifo_level, libpio), uint, (PIO, uint), pio, sm)
end

function pio_sm_drain_tx_fifo(pio, sm)
    ccall((:pio_sm_drain_tx_fifo, libpio), Cvoid, (PIO, uint), pio, sm)
end

function pio_sm_put(pio, sm, data)
    ccall((:pio_sm_put, libpio), Cvoid, (PIO, uint, UInt32), pio, sm, data)
end

function pio_sm_put_blocking(pio, sm, data)
    ccall((:pio_sm_put_blocking, libpio), Cvoid, (PIO, uint, UInt32), pio, sm, data)
end

function pio_sm_get(pio, sm)
    ccall((:pio_sm_get, libpio), UInt32, (PIO, uint), pio, sm)
end

function pio_sm_get_blocking(pio, sm)
    ccall((:pio_sm_get_blocking, libpio), UInt32, (PIO, uint), pio, sm)
end

function pio_get_default_sm_config_for_pio(pio)
    ccall((:pio_get_default_sm_config_for_pio, libpio), pio_sm_config, (PIO,), pio)
end

function pio_get_default_sm_config()
    ccall((:pio_get_default_sm_config, libpio), pio_sm_config, ())
end

function sm_config_set_out_pins(c, out_base, out_count)
    ccall((:sm_config_set_out_pins, libpio), Cvoid, (Ptr{pio_sm_config}, uint, uint), c, out_base, out_count)
end

function sm_config_set_set_pins(c, set_base, set_count)
    ccall((:sm_config_set_set_pins, libpio), Cvoid, (Ptr{pio_sm_config}, uint, uint), c, set_base, set_count)
end

function sm_config_set_in_pins(c, in_base)
    ccall((:sm_config_set_in_pins, libpio), Cvoid, (Ptr{pio_sm_config}, uint), c, in_base)
end

function sm_config_set_sideset_pins(c, sideset_base)
    ccall((:sm_config_set_sideset_pins, libpio), Cvoid, (Ptr{pio_sm_config}, uint), c, sideset_base)
end

function sm_config_set_sideset(c, bit_count, optional, pindirs)
    ccall((:sm_config_set_sideset, libpio), Cvoid, (Ptr{pio_sm_config}, uint, Bool, Bool), c, bit_count, optional, pindirs)
end

function sm_config_set_clkdiv_int_frac(c, div_int, div_frac)
    ccall((:sm_config_set_clkdiv_int_frac, libpio), Cvoid, (Ptr{pio_sm_config}, UInt16, UInt8), c, div_int, div_frac)
end

function sm_config_set_clkdiv(c, div)
    ccall((:sm_config_set_clkdiv, libpio), Cvoid, (Ptr{pio_sm_config}, Cfloat), c, div)
end

function sm_config_set_wrap(c, wrap_target, wrap)
    ccall((:sm_config_set_wrap, libpio), Cvoid, (Ptr{pio_sm_config}, uint, uint), c, wrap_target, wrap)
end

function sm_config_set_jmp_pin(c, pin)
    ccall((:sm_config_set_jmp_pin, libpio), Cvoid, (Ptr{pio_sm_config}, uint), c, pin)
end

function sm_config_set_in_shift(c, shift_right, autopush, push_threshold)
    ccall((:sm_config_set_in_shift, libpio), Cvoid, (Ptr{pio_sm_config}, Bool, Bool, uint), c, shift_right, autopush, push_threshold)
end

function sm_config_set_out_shift(c, shift_right, autopull, pull_threshold)
    ccall((:sm_config_set_out_shift, libpio), Cvoid, (Ptr{pio_sm_config}, Bool, Bool, uint), c, shift_right, autopull, pull_threshold)
end

function sm_config_set_fifo_join(c, join)
    ccall((:sm_config_set_fifo_join, libpio), Cvoid, (Ptr{pio_sm_config}, pio_fifo_join), c, join)
end

function sm_config_set_out_special(c, sticky, has_enable_pin, enable_pin_index)
    ccall((:sm_config_set_out_special, libpio), Cvoid, (Ptr{pio_sm_config}, Bool, Bool, uint), c, sticky, has_enable_pin, enable_pin_index)
end

function sm_config_set_mov_status(c, status_sel, status_n)
    ccall((:sm_config_set_mov_status, libpio), Cvoid, (Ptr{pio_sm_config}, pio_mov_status_type, uint), c, status_sel, status_n)
end

function pio_gpio_init(pio, pin)
    ccall((:pio_gpio_init, libpio), Cvoid, (PIO, uint), pio, pin)
end

function clock_get_hz(clk_index)
    ccall((:clock_get_hz, libpio), UInt32, (clock_index,), clk_index)
end

function gpio_init(gpio)
    ccall((:gpio_init, libpio), Cvoid, (uint,), gpio)
end

function gpio_set_function(gpio, fn)
    ccall((:gpio_set_function, libpio), Cvoid, (uint, gpio_function), gpio, fn)
end

function gpio_set_pulls(gpio, up, down)
    ccall((:gpio_set_pulls, libpio), Cvoid, (uint, Bool, Bool), gpio, up, down)
end

function gpio_set_outover(gpio, value)
    ccall((:gpio_set_outover, libpio), Cvoid, (uint, uint), gpio, value)
end

function gpio_set_inover(gpio, value)
    ccall((:gpio_set_inover, libpio), Cvoid, (uint, uint), gpio, value)
end

function gpio_set_oeover(gpio, value)
    ccall((:gpio_set_oeover, libpio), Cvoid, (uint, uint), gpio, value)
end

function gpio_set_input_enabled(gpio, enabled)
    ccall((:gpio_set_input_enabled, libpio), Cvoid, (uint, Bool), gpio, enabled)
end

function gpio_set_drive_strength(gpio, drive)
    ccall((:gpio_set_drive_strength, libpio), Cvoid, (uint, gpio_drive_strength), gpio, drive)
end

function gpio_pull_up(gpio)
    ccall((:gpio_pull_up, libpio), Cvoid, (uint,), gpio)
end

function gpio_pull_down(gpio)
    ccall((:gpio_pull_down, libpio), Cvoid, (uint,), gpio)
end

function gpio_disable_pulls(gpio)
    ccall((:gpio_disable_pulls, libpio), Cvoid, (uint,), gpio)
end

function stdio_init_all()
    ccall((:stdio_init_all, libpio), Cvoid, ())
end

function sleep_us(us)
    ccall((:sleep_us, libpio), Cvoid, (UInt64,), us)
end

function sleep_ms(ms)
    ccall((:sleep_ms, libpio), Cvoid, (UInt32,), ms)
end

# Skipping MacroDefinition: __unused __attribute__ ( ( unused ) )

const PICO_DEFAULT_LED_PIN = 4

const PARAM_ASSERTIONS_ENABLE_ALL = 0

const PARAM_ASSERTIONS_DISABLE_ALL = 0

const PARAM_ASSERTIONS_ENABLED_GPIO = 0

const NUM_BANK0_GPIOS = 32

const GPIO_OUT = 1

const GPIO_IN = 0

const PARAM_ASSERTIONS_ENABLED_PIO = 0

const PIO_ORIGIN_ANY = uint(~0)

const PIO_ORIGIN_INVALID = PIO_ORIGIN_ANY

const pio0 = pio_open_helper(0)

const _PIO_INVALID_IN_SRC = Cuint(0x08)

const _PIO_INVALID_OUT_DEST = Cuint(0x10)

const _PIO_INVALID_SET_DEST = Cuint(0x20)

const _PIO_INVALID_MOV_SRC = Cuint(0x40)

const _PIO_INVALID_MOV_DEST = Cuint(0x80)

# exports
const PREFIXES = ["pio_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

