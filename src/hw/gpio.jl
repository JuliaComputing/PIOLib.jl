"Configure `pin` for PIO use on the given PIO block. Must be called before the SM drives the pin."
pio_pin_init!(pio::PIOBlock, pin::Integer) = LibPIO.pio_gpio_init(pio.handle, UInt32(pin))

"Initialise a GPIO pin to SIO (default software control)."
gpio_init!(pin::Integer) = LibPIO.gpio_init(UInt32(pin))

"Set the function select for a GPIO (e.g. `GPIO_FUNC_PIO0`, `GPIO_FUNC_SPI`)."
gpio_set_function!(pin::Integer, func::LibPIO.gpio_function) = LibPIO.gpio_set_function(UInt32(pin), func)

"Set pull-up and pull-down resistors on a GPIO."
function gpio_set_pulls!(pin::Integer; up::Bool=false, down::Bool=false)
    LibPIO.gpio_set_pulls(UInt32(pin), up, down)
end

"Enable the pull-up resistor on a GPIO."
gpio_pull_up!(pin::Integer) = LibPIO.gpio_pull_up(UInt32(pin))

"Enable the pull-down resistor on a GPIO."
gpio_pull_down!(pin::Integer) = LibPIO.gpio_pull_down(UInt32(pin))

"Disable both pull-up and pull-down resistors on a GPIO."
gpio_disable_pulls!(pin::Integer) = LibPIO.gpio_disable_pulls(UInt32(pin))

"Set the drive strength for a GPIO output (e.g. `GPIO_DRIVE_STRENGTH_2MA`, `_4MA`, `_8MA`, `_12MA`)."
gpio_set_drive_strength!(pin::Integer, s::LibPIO.gpio_drive_strength) = LibPIO.gpio_set_drive_strength(UInt32(pin), s)

"Enable or disable the input buffer on a GPIO. Must be enabled for the PIO to read the pin."
gpio_set_input_enabled!(pin::Integer, enabled::Bool) = LibPIO.gpio_set_input_enabled(UInt32(pin), enabled)
