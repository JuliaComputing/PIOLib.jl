using PIOLib

"""
    shift_register_program(pio::PIOBlock; ser_pin, clk_pin, rclk_pin, nbits, clkdiv=1.0f0)

Build a PIO program and SM config for driving a shift register (e.g. 74HC595).

# Pins
- `ser_pin`: Serial data (SER/DS)
- `clk_pin`: Shift clock (SRCLK/SHCP) — data sampled on rising edge
- `rclk_pin`: Register/latch clock (RCLK/STCP) — outputs updated on rising edge

# Arguments
- `nbits`: Number of bits per transfer (1-31, e.g. 8 for one 74HC595, 16 for two chained)
- `clkdiv`: Clock divider (1.0 = full speed). Each bit takes 2 SM cycles.

# Protocol
Write one data word to the TX FIFO per transfer via [`shift_out!`](@ref). The bit
count is fixed at init time — stored in scratch Y and used as autopull threshold.
Data is shifted out LSB first by default.

The OSR is automatically refilled from the TX FIFO (autopull) when the shift count
reaches `nbits`. If the FIFO is empty, the SM stalls on the first OUT until data
is available.

# Timing
Each bit takes 2 SM cycles (set SER + clock pulse), 50% duty cycle on CLK.
Per-transfer overhead is 3 cycles (reload counter + latch pulse).
Total: `2N + 3` cycles per transfer.

# Returns
`(program::PIOProgram, config::SMConfig)` — after `init!`, call
`setup_shift_register!(sm, nbits)` to load the bit count before enabling.
"""
function shift_register_program(pio::PIOBlock; ser_pin::Integer, clk_pin::Integer, rclk_pin::Integer,
                                  nbits::Integer, clkdiv::Real=1.0f0)
    1 <= nbits <= 31 || error("nbits must be 1-31 (SET immediate is 5 bits, and 32 encodes as 0 in autopull threshold)")

    prog = build_program([
        WrapTarget(),
        Mov{:none}(RegX(), RegY(); sideset=0),
        Label(:bitloop),
        Out(Pins(), 1; sideset=0),
        Jmp{:x_dec}(:bitloop; sideset=1),
        Set(Pins(), 1; sideset=0),
        Set(Pins(), 0; sideset=0),
        Wrap(),
    ]; sideset_bits=1)

    config = SMConfig(pio;
        out_pins=(ser_pin, 1),
        set_pins=(rclk_pin, 1),
        sideset_pin_base=clk_pin,
        sideset=(1, false, false),
        out_shift=(true, true, nbits),
        clkdiv=Float32(clkdiv),
        wrap=(prog.wrap_target, prog.wrap),
    )

    prog, config
end

"""
    setup_shift_register!(sm, nbits)

Load the bit count into scratch Y via `exec!`. Call after `init!` but before `enable!`.
"""
function setup_shift_register!(sm::StateMachine, nbits::Integer)
    exec!(sm, Set(RegY(), nbits - 1))
end

"""
    shift_out!(sm, data)

Clock one word through the shift register and latch. Blocks until the TX FIFO has room.
"""
shift_out!(sm::StateMachine, data::UInt32) = put!(sm, data)

# Example usage:
#
#   SER_PIN  = 2
#   CLK_PIN  = 3
#   RCLK_PIN = 4
#   NBITS    = 8
#
#   open_pio(0) do pio
#       prog, config = shift_register_program(pio;
#           ser_pin=SER_PIN, clk_pin=CLK_PIN, rclk_pin=RCLK_PIN,
#           nbits=NBITS, clkdiv=62.5f0,
#       )
#
#       for pin in (SER_PIN, CLK_PIN, RCLK_PIN)
#           pio_pin_init!(pio, pin)
#       end
#
#       offset = load_program!(pio, prog, config)
#
#       claim_sm(pio) do sm
#           set_consecutive_pindirs!(sm, SER_PIN, 3, true)
#           init!(sm, offset, config)
#           setup_shift_register!(sm, NBITS)
#           enable!(sm)
#
#           shift_out!(sm, 0x000000ff)
#           shift_out!(sm, 0x0000005a)
#       end
#   end
