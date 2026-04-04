"""
    open_pio(idx::Integer) -> PIOBlock
    open_pio(name::AbstractString) -> PIOBlock
    open_pio(f, idx::Integer)
    open_pio(f, name::AbstractString)

Open a PIO block by index or name. Each PIO block has its own instruction memory,
state machines, and IRQ flags.

The do-block form closes the PIO automatically; the direct form returns the handle
for the caller to `close` when done.

```julia
# Do-block (auto-close)
open_pio(0) do pio
    claim_sm(pio) do sm
        # ...
    end
end

# Imperative (caller manages lifetime)
pio = open_pio(0)
try
    # long-running work...
finally
    close(pio)
end
```
"""
function _check_pio_handle(handle::LibPIO.PIO, desc)
    if handle == C_NULL || LibPIO._pio_is_err(handle)
        code = LibPIO.PIO_ERR_VAL(handle)
        throw(PIOError("failed to open PIO $desc (error $code)"))
    end
end

function open_pio(idx::Integer)
    handle = LibPIO.pio_open(UInt32(idx))
    _check_pio_handle(handle, idx)
    PIOBlock(handle)
end

function open_pio(name::AbstractString)
    handle = LibPIO.pio_open_by_name(name)
    _check_pio_handle(handle, "\"$name\"")
    PIOBlock(handle)
end

function open_pio(f::Function, idx::Integer)
    pio = open_pio(idx)
    try
        f(pio)
    finally
        Base.close(pio)
    end
end

function open_pio(f::Function, name::AbstractString)
    pio = open_pio(name)
    try
        f(pio)
    finally
        Base.close(pio)
    end
end

Base.close(pio::PIOBlock) = LibPIO.pio_close(pio.handle)

"""
    claim_sm(pio::PIOBlock) -> StateMachine
    claim_sm(pio::PIOBlock, idx::Integer) -> StateMachine
    claim_sm(f, pio::PIOBlock)
    claim_sm(f, pio::PIOBlock, idx::Integer)

Claim a state machine from `pio`. The first two forms return the SM directly for the
caller to `unclaim!` when done; the do-block forms handle cleanup automatically.

```julia
# Imperative
sm = claim_sm(pio)
try
    init!(sm, offset, config)
    enable!(sm)
    # long-running work...
finally
    unclaim!(sm)
end

# Do-block (auto-unclaim)
claim_sm(pio) do sm
    init!(sm, offset, config)
    enable!(sm)
end
```
"""
function claim_sm(pio::PIOBlock)
    idx = LibPIO.pio_claim_unused_sm(pio.handle, true)
    idx < 0 && throw(PIOError("no unused state machine available"))
    StateMachine(pio, UInt32(idx))
end

function claim_sm(pio::PIOBlock, idx::Integer)
    LibPIO.pio_sm_claim(pio.handle, UInt32(idx))
    check_error!(pio)
    StateMachine(pio, UInt32(idx))
end

function claim_sm(f::Function, pio::PIOBlock)
    sm = claim_sm(pio)
    try
        f(sm)
    finally
        unclaim!(sm)
    end
end

function claim_sm(f::Function, pio::PIOBlock, idx::Integer)
    sm = claim_sm(pio, idx)
    try
        f(sm)
    finally
        unclaim!(sm)
    end
end

"Release a previously claimed state machine. Required cleanup when using the imperative `claim_sm` form."
unclaim!(sm::StateMachine) = LibPIO.pio_sm_unclaim(sm.pio.handle, sm.sm)

"Check whether state machine `sm` (by index) is currently claimed on `pio`."
is_claimed(pio::PIOBlock, sm::Integer) = LibPIO.pio_sm_is_claimed(pio.handle, UInt32(sm))

"Number of state machines on this PIO block."
sm_count(pio::PIOBlock) = LibPIO.pio_get_sm_count(pio.handle)

"Number of instruction slots in the shared instruction memory."
instruction_count(pio::PIOBlock) = LibPIO.pio_get_instruction_count(pio.handle)

"Depth of each FIFO (per direction) in 32-bit words. 8 on RP1."
fifo_depth(pio::PIOBlock) = LibPIO.pio_get_fifo_depth(pio.handle)
