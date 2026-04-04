using PIOLib

"""
    ws2812_program(pio::PIOBlock; pin, sys_clk=200_000_000.0)

Build a PIO program and SM config for driving a WS2812 (NeoPixel) LED strip on a
single GPIO pin.

# Protocol
WS2812 uses a single-wire protocol at 800kHz where each bit is a fixed-length pulse:
- **1-bit**: long high (~875ns), short low (~375ns)
- **0-bit**: short high (~250ns), long low (~1000ns)
- **Reset**: >280μs low (happens automatically when the FIFO is empty)

Data is 24 bits per LED in GRB order (MSB first). LEDs daisy-chain: the first LED
consumes the first 24 bits, the second consumes the next 24, etc.

# Implementation
The data pin is driven by side-set. Each bit, the pin goes high, the program branches
on the data bit to decide how long to stay high, then goes low. 4 instructions, 10
SM cycles per bit.

```
        out x, 1       side 0 [T3-1]  ; shift bit to X, pin low
        jmp !x do_zero side 1 [T1-1]  ; pin high, branch if 0-bit
        jmp bitloop    side 1 [T2-1]  ; 1-bit: stay high longer
do_zero:
        nop            side 0 [T2-1]  ; 0-bit: go low sooner
```

The TX FIFO is joined (16-deep on RP1) for maximum throughput. Autopull at 24 bits
reloads the OSR automatically.

# Returns
`(program::PIOProgram, config::SMConfig)`

# See also
[`ws2812_put!`](@ref), [`ws2812_rgb!`](@ref)
"""
function ws2812_program(pio::PIOBlock; pin::Integer, sys_clk::Real=200_000_000.0)
    T1 = 2
    T2 = 5
    T3 = 3
    cycles_per_bit = T1 + T2 + T3
    div = clkdiv(800_000.0 * cycles_per_bit; sys_clk)

    prog = build_program([
        WrapTarget(),
        Label(:bitloop),
        Out(RegX(), 1; sideset=0, delay=T3-1),
        Jmp{:not_x}(:do_zero; sideset=1, delay=T1-1),
        Jmp{:always}(:bitloop; sideset=1, delay=T2-1),
        Label(:do_zero),
        Nop(; sideset=0, delay=T2-1),
        Wrap(),
    ]; sideset_bits=1)

    config = SMConfig(pio;
        sideset_pin_base=pin,
        sideset=(1, false, false),
        out_shift=(false, true, 24),
        clkdiv=div,
        wrap=(prog.wrap_target, prog.wrap),
        fifo_join=LibPIO.PIO_FIFO_JOIN_TX,
    )

    prog, config
end

"""
    ws2812_put!(sm, grb::UInt32)

Send a raw 24-bit GRB colour value to the next LED in the chain. The value is packed
as `0x00GGRRBB` — green in bits 23:16, red in 15:8, blue in 7:0.
"""
ws2812_put!(sm::StateMachine, grb::UInt32) = put!(sm, grb << 8)

"""
    ws2812_rgb!(sm, r, g, b)

Send an RGB colour to the next LED, converting to GRB order.
"""
function ws2812_rgb!(sm::StateMachine, r::Integer, g::Integer, b::Integer)
    grb = (UInt32(g) << 16) | (UInt32(r) << 8) | UInt32(b)
    ws2812_put!(sm, grb)
end

# Example usage:
#
#   LED_PIN = 2
#   NUM_LEDS = 8
#
#   open_pio(0) do pio
#       prog, config = ws2812_program(pio; pin=LED_PIN)
#
#       pio_pin_init!(pio, LED_PIN)
#
#       offset = load_program!(pio, prog, config)
#
#       claim_sm(pio) do sm
#           set_consecutive_pindirs!(sm, LED_PIN, 1, true)
#           init!(sm, offset, config)
#           enable!(sm)
#
#           for _ in 1:NUM_LEDS
#               ws2812_rgb!(sm, 255, 0, 0)
#           end
#
#           sleep(0.001)
#
#           for i in 0:NUM_LEDS-1
#               hue = (i * 256 ÷ NUM_LEDS) % 256
#               ws2812_rgb!(sm, hue, 255 - hue, 0)
#           end
#       end
#   end
