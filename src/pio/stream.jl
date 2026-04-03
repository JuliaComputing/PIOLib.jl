"""
    Base.put!(sm::StateMachine, data::UInt32) -> UInt32

Write a 32-bit word to the TX FIFO (system → state machine). Blocks if the FIFO is full.
The SM's PIO program consumes these words via `PULL` or autopull into the OSR.
"""
function Base.put!(sm::StateMachine, data::UInt32)
    LibPIO.pio_sm_put_blocking(sm.pio.handle, sm.sm, data)
    data
end

"""
    Base.take!(sm::StateMachine) -> UInt32

Read a 32-bit word from the RX FIFO (state machine → system). Blocks if the FIFO is empty.
The SM's PIO program produces these words via `PUSH` or autopush from the ISR.
"""
function Base.take!(sm::StateMachine)
    LibPIO.pio_sm_get_blocking(sm.pio.handle, sm.sm)
end

"""
    tryput!(sm, data::UInt32) -> Bool

Non-blocking write to the TX FIFO. Returns `true` if the word was enqueued,
`false` if the FIFO was full.
"""
function tryput!(sm::StateMachine, data::UInt32)
    if LibPIO.pio_sm_is_tx_fifo_full(sm.pio.handle, sm.sm)
        return false
    end
    LibPIO.pio_sm_put(sm.pio.handle, sm.sm, data)
    true
end

"""
    trytake(sm) -> Union{UInt32, Nothing}

Non-blocking read from the RX FIFO. Returns the word, or `nothing` if the FIFO was empty.
"""
function trytake(sm::StateMachine)
    if LibPIO.pio_sm_is_rx_fifo_empty(sm.pio.handle, sm.sm)
        return nothing
    end
    LibPIO.pio_sm_get(sm.pio.handle, sm.sm)
end

"Is the TX FIFO empty? The SM will stall on `PULL block` when this is true."
tx_empty(sm::StateMachine) = LibPIO.pio_sm_is_tx_fifo_empty(sm.pio.handle, sm.sm)

"Is the TX FIFO full? System writes will block until the SM drains a word."
tx_full(sm::StateMachine) = LibPIO.pio_sm_is_tx_fifo_full(sm.pio.handle, sm.sm)

"Number of 32-bit words currently in the TX FIFO (0 to 8, or 0 to 16 if joined)."
tx_level(sm::StateMachine) = LibPIO.pio_sm_get_tx_fifo_level(sm.pio.handle, sm.sm)

"Is the RX FIFO empty? System reads will block until the SM pushes a word."
rx_empty(sm::StateMachine) = LibPIO.pio_sm_is_rx_fifo_empty(sm.pio.handle, sm.sm)

"Is the RX FIFO full? The SM will stall on `PUSH block` when this is true."
rx_full(sm::StateMachine) = LibPIO.pio_sm_is_rx_fifo_full(sm.pio.handle, sm.sm)

"Number of 32-bit words currently in the RX FIFO (0 to 8, or 0 to 16 if joined)."
rx_level(sm::StateMachine) = LibPIO.pio_sm_get_rx_fifo_level(sm.pio.handle, sm.sm)

"Clear both TX and RX FIFOs for this state machine."
clear_fifos!(sm::StateMachine) = LibPIO.pio_sm_clear_fifos(sm.pio.handle, sm.sm)

"Drain the TX FIFO by executing `OUT NULL, 32` until empty. Useful before reconfiguring."
drain_tx!(sm::StateMachine) = LibPIO.pio_sm_drain_tx_fifo(sm.pio.handle, sm.sm)

function Base.unsafe_write(s::PIOStream, p::Ptr{UInt8}, n::UInt)
    LibPIO.pio_sm_xfer_data(
        s.sm.pio.handle, s.sm.sm,
        UInt32(LibPIO.PIO_DIR_TO_SM),
        UInt32(n), Ptr{Cvoid}(p)
    )
    check_error!(s.sm.pio)
    Int(n)
end

function Base.unsafe_read(s::PIOStream, p::Ptr{UInt8}, n::UInt)
    LibPIO.pio_sm_xfer_data(
        s.sm.pio.handle, s.sm.sm,
        UInt32(LibPIO.PIO_DIR_FROM_SM),
        UInt32(n), Ptr{Cvoid}(p)
    )
    check_error!(s.sm.pio)
    nothing
end

Base.isreadable(::PIOStream) = true
Base.iswritable(::PIOStream) = true
Base.isopen(::PIOStream) = true
Base.eof(::PIOStream) = false
Base.bytesavailable(s::PIOStream) = Int(rx_level(s.sm)) * 4
