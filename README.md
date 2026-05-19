# apb-spi-controller
Synthesizable APB-based SPI Controller in Verilog supporting configurable SPI modes, programmable baud generation, interrupt handling, full-duplex communication, Modular and reusable RTL architecture, and self-checking verification environment.

# APB-Based SPI Controller
Motorola SPI Inspired AMBA-APB Compatible SPI Master Core

A synthesizable RTL implementation of a Motorola-style Serial Peripheral Interface (SPI) Controller integrated with an AMBA APB3 slave interface. The design supports configurable SPI modes, programmable baud-rate generation, interrupt handling, and full-duplex serial communication between a processor and external SPI peripherals.

This project is architecturally inspired by the classic Motorola SPI specification and implements major SPI concepts including CPOL/CPHA timing control, programmable baud-rate divisors, slave-select handling, interrupt flags, and configurable bit ordering.

# Features
AMBA APB3 Compatible Slave Interface
Motorola SPI Compatible Architecture
SPI Master Mode Support
Full-Duplex SPI Communication
Programmable Baud Rate Generator
CPOL/CPHA Configurable SPI Modes
LSB-First / MSB-First Transmission
SPI Interrupt Generation
Slave Select Control Logic
Synthesizable Verilog RTL
Modular Reusable Architecture
Self-Checking Verilog Testbench
Back-to-Back Transfer Support
SPI Status and Control Registers
Transfer Synchronization Logic
Wait/Run/Stop SPI Modes

# Project Architecture

The SPI controller is divided into four major RTL blocks:

APB Slave Interface
Baud Rate Generator
SPI Slave Select Generator
SPI Shifter

All modules are integrated through the top-level controller module.

# Top-Level Architecture
                    +----------------------+
                    |  spi_controller_top  |
                    +----------------------+
                       |      |      |
       -----------------------------------------------
       |              |              |               |
+-------------+ +-------------+ +-------------+ +-------------+
| apb_slave   | |baud_generator| |spi_shifter | |slave_select |
+-------------+ +-------------+ +-------------+ +-------------+
       |              |              |
       |              |              |
     APB BUS        SCLK        MOSI / MISO


     
