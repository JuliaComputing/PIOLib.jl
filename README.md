PIOLib.jl
==========

On Raspberry Pi 5 hardware (either the normal Pi 5 or a CM5) the PIOs in the RP1 are exposed to the host CPU via PCIe memory-mapping and are supported by a kernel driver. This is a wrapper for Raspberry Pi's piolib that lets you program the PIOs from Julia.

The Pi 5/RP1 PIOs are more-or-less the same as the ones in the RP2040 (sadly, we don't get the nice new RP2350 features). Refer to the RP2040 datasheet for more information on the programming model.

Take a look in the `examples` directory for a couple of common PIO use cases.