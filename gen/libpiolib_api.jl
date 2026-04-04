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

function sleep_us(us)
    ccall((:sleep_us, libpio), Cvoid, (UInt64,), us)
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

const _PIO_INVALID_IN_SRC = Cuint(0x08)

const _PIO_INVALID_OUT_DEST = Cuint(0x10)

const _PIO_INVALID_SET_DEST = Cuint(0x20)

const _PIO_INVALID_MOV_SRC = Cuint(0x40)

const _PIO_INVALID_MOV_DEST = Cuint(0x80)

# Julia implementations of the static inline functions from piolib.h.
# These dispatch through the pio_chip vtable, matching the C header exactly.

const PIO_ORIGIN_ANY = typemax(UInt32)
const PIO_ORIGIN_INVALID = PIO_ORIGIN_ANY

# Vtable helpers

function _get_chip(pio::PIO)
    instance = unsafe_load(pio)
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


# exports
const PREFIXES = ["pio_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

