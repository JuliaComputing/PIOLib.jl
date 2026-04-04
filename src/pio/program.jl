"""
    load_program!(pio, prog) -> offset
    load_program!(pio, prog, config::SMConfig) -> offset
    load_program!(pio, prog, offset::Integer)

Load a PIO program into instruction memory. The first form auto-selects a free location
and returns the offset; the second also adjusts `config.wrap` to the loaded address;
the third places it at a specific offset.

All state machines on the same PIO block share instruction memory, so multiple programs
can coexist if they fit.
"""
function load_program!(pio::PIOBlock, prog::PIOProgram)
    GC.@preserve prog begin
        c_prog = LibPIO.pio_program_t(
            pointer(prog.instructions),
            UInt8(length(prog.instructions)),
            prog.origin,
            UInt8(0),
        )
        offset = LibPIO.pio_add_program(pio.handle, Ref(c_prog))
    end
    check_error!(pio)
    offset
end

function load_program!(pio::PIOBlock, prog::PIOProgram, config::SMConfig)
    offset = load_program!(pio, prog)
    config.wrap = (offset + prog.wrap_target, offset + prog.wrap)
    offset
end

function load_program!(pio::PIOBlock, prog::LibPIO.pio_program_t)
    offset = LibPIO.pio_add_program(pio.handle, Ref(prog))
    check_error!(pio)
    offset
end

function load_program!(pio::PIOBlock, prog::PIOProgram, offset::Integer)
    GC.@preserve prog begin
        c_prog = LibPIO.pio_program_t(
            pointer(prog.instructions),
            UInt8(length(prog.instructions)),
            prog.origin,
            UInt8(0),
        )
        LibPIO.pio_add_program_at_offset(pio.handle, Ref(c_prog), UInt32(offset))
    end
    check_error!(pio)
end

function load_program!(pio::PIOBlock, prog::LibPIO.pio_program_t, offset::Integer)
    LibPIO.pio_add_program_at_offset(pio.handle, Ref(prog), UInt32(offset))
    check_error!(pio)
end

"Check whether `prog` can be loaded (i.e. there is room in instruction memory)."
function can_load_program(pio::PIOBlock, prog::LibPIO.pio_program_t)
    LibPIO.pio_can_add_program(pio.handle, Ref(prog))
end

function can_load_program(pio::PIOBlock, prog::LibPIO.pio_program_t, offset::Integer)
    LibPIO.pio_can_add_program_at_offset(pio.handle, Ref(prog), UInt32(offset))
end

"Remove a previously loaded program, freeing its instruction memory slots."
function remove_program!(pio::PIOBlock, prog::LibPIO.pio_program_t, offset::Integer)
    LibPIO.pio_remove_program(pio.handle, Ref(prog), UInt32(offset))
end

"Clear all instruction memory. Affects all state machines on this PIO block."
clear_programs!(pio::PIOBlock) = LibPIO.pio_clear_instruction_memory(pio.handle)
