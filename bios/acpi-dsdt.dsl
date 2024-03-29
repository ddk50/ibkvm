/*
 * Bochs/QEMU ACPI DSDT ASL definition
 *
 * Copyright (c) 2006 Fabrice Bellard
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License version 2 as published by the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
DefinitionBlock (
    "acpi-dsdt.aml",    // Output Filename
    "DSDT",             // Signature
    0x01,               // DSDT Compliance Revision
    "BXPC",             // OEMID
    "BXDSDT",           // TABLE ID
    0x1                 // OEM Revision
    )
{
   Scope (\_PR)
   {
	OperationRegion(PRST, SystemIO, 0xaf00, 32)
	Field (PRST, ByteAcc, NoLock, Preserve)
	{
		PRS, 256
	}

	Name(PRSS, Buffer(32){}) /* shadow CPU status bitmask */
	Name(SSVL, 0)

	Method(CRST, 1) {
		If (LEqual(SSVL, 0)) {
			Store(PRS, PRSS) /* read CPUs status bitmaks from HW */
			Store(1, SSVL)
                }
		ShiftRight(Arg0, 3, Local1)
		Store(DerefOf(Index(PRSS, Local1)), Local2)
	        Return(And(Local2, ShiftLeft(1, And(Arg0, 0x7))))
	}

#define gen_processor(nr, name) 				            \
	Processor (CPU##name, nr, 0x0000b010, 0x06) {                       \
            Name (PREN, Buffer(0x8) {0x0, 0x8, nr, nr, 0x1, 0x0, 0x0, 0x0}) \
            Name (PRDS, Buffer(0x8) {0x0, 0x8, nr, nr, 0x0, 0x0, 0x0, 0x0}) \
            Method(_MAT, 0) {                                               \
                If (CRST(nr)) { Return(PREN) }                              \
                Else { Return(PRDS) }                                       \
            }                                                               \
            Method (_STA) {                                                 \
                If (CRST(nr)) { Return(0xF) }                               \
                Else { Return(0x9) }                                        \
            }                                                               \
        }                                                                   \


	gen_processor(0, 0)
	gen_processor(1, 1)
	gen_processor(2, 2)
	gen_processor(3, 3)
	gen_processor(4, 4)
	gen_processor(5, 5)
	gen_processor(6, 6)
	gen_processor(7, 7)
	gen_processor(8, 8)
	gen_processor(9, 9)
	gen_processor(10, A)
	gen_processor(11, B)
	gen_processor(12, C)
	gen_processor(13, D)
	gen_processor(14, E)

	Method (NTFY, 2) {
#define gen_ntfy(nr)                              \
	If (LEqual(Arg0, 0x##nr)) {               \
		Notify(CPU##nr, Arg1)             \
	}
		gen_ntfy(0)
		gen_ntfy(1)
		gen_ntfy(2)
		gen_ntfy(3)
		gen_ntfy(4)
		gen_ntfy(5)
		gen_ntfy(6)
		gen_ntfy(7)
		gen_ntfy(8)
		gen_ntfy(9)
		gen_ntfy(A)
		gen_ntfy(B)
		gen_ntfy(C)
		gen_ntfy(D)
		gen_ntfy(E)
		Return(One)
	}

	/* Works on 8 bit quentity.
         * Arg1 - Shadow status bits
         * Arg2 - Current status bits
	 */
        Method(PR1, 3) {
	    Xor(Arg1, Arg2, Local0) /* figure out what chaged */
	    ShiftLeft(Arg0, 3, Local1)
            While (LNotEqual(Local0, Zero)) {
		If (And(Local0, 1)) {      /* if staus have changed */
                    if(And(Arg2, 1)) {     /* check previous status */
	                Store(3, Local3)
		    } Else {
	                Store(1, Local3)
	            }
		    NTFY(Local1, Local3)
                }
		ShiftRight(Local0, 1, Local0)
		ShiftRight(Arg2, 1, Arg2)
		Increment(Local1)
	    }
	    Return(One)
	}

	Method(PRSC, 0) {
		Store(Buffer(32){}, Local0)
		Store(PRS, Local0) /* read CPUs status bitmask into Local0 */
		Store(Zero, Local1)
		/* loop over bitmask byte by byte to see what have chaged */
		While(LLess(Local1, 32)) {
			Store(DerefOf(Index(Local0, Local1)), Local2)
			Store(DerefOf(Index(PRSS, Local1)), Local3)
			PR1(Local1, Local2, Local3)
			Increment(Local1)
                }
		Store(Local0, PRSS) /* store curr satust bitmask into shadow */
		Return(One)
	}
    }

    Scope (\)
    {
        /* Debug Output */
        OperationRegion (DBG, SystemIO, 0xb044, 0x04)
        Field (DBG, DWordAcc, NoLock, Preserve)
        {
            DBGL,   32,
        }
    }


    /* PCI Bus definition */
    Scope(\_SB) {
        Device(PCI0) {
            Name (_HID, EisaId ("PNP0A03"))
            Name (_ADR, 0x00)
            Name (_UID, 1)
            Name(_PRT, Package() {
                /* PCI IRQ routing table, example from ACPI 2.0a specification,
                   section 6.2.8.1 */
                /* Note: we provide the same info as the PCI routing
                   table of the Bochs BIOS */

#define prt_slot(nr, lnk0, lnk1, lnk2, lnk3) \
	Package() { nr##ffff, 0, lnk0, 0 }, \
	Package() { nr##ffff, 1, lnk1, 0 }, \
	Package() { nr##ffff, 2, lnk2, 0 }, \
	Package() { nr##ffff, 3, lnk3, 0 }

#define prt_slot0(nr) prt_slot(nr, LNKD, LNKA, LNKB, LNKC)
#define prt_slot1(nr) prt_slot(nr, LNKA, LNKB, LNKC, LNKD)
#define prt_slot2(nr) prt_slot(nr, LNKB, LNKC, LNKD, LNKA)
#define prt_slot3(nr) prt_slot(nr, LNKC, LNKD, LNKA, LNKB)

		prt_slot0(0x0000),
		prt_slot1(0x0001),
		prt_slot2(0x0002),
		prt_slot3(0x0003),
		prt_slot0(0x0004),
		prt_slot1(0x0005),
		prt_slot2(0x0006),
		prt_slot3(0x0007),
		prt_slot0(0x0008),
		prt_slot1(0x0009),
		prt_slot2(0x000a),
		prt_slot3(0x000b),
		prt_slot0(0x000c),
		prt_slot1(0x000d),
		prt_slot2(0x000e),
		prt_slot3(0x000f),
		prt_slot0(0x0010),
		prt_slot1(0x0011),
		prt_slot2(0x0012),
		prt_slot3(0x0013),
		prt_slot0(0x0014),
		prt_slot1(0x0015),
		prt_slot2(0x0016),
		prt_slot3(0x0017),
		prt_slot0(0x0018),
		prt_slot1(0x0019),
		prt_slot2(0x001a),
		prt_slot3(0x001b),
		prt_slot0(0x001c),
		prt_slot1(0x001d),
		prt_slot2(0x001e),
		prt_slot3(0x001f),
            })

            OperationRegion(PCST, SystemIO, 0xae00, 0x08)
            Field (PCST, DWordAcc, NoLock, WriteAsZeros)
	    {
		PCIU, 32,
		PCID, 32,
	    }

            OperationRegion(SEJ, SystemIO, 0xae08, 0x04)
            Field (SEJ, DWordAcc, NoLock, WriteAsZeros)
            {
                B0EJ, 32,
            }

#define hotplug_slot(name, nr) \
            Device (S##name) {                    \
               Name (_ADR, nr##0000)              \
               Method (_EJ0,1) {                  \
                    Store(ShiftLeft(1, nr), B0EJ) \
                    Return (0x0)                  \
               }                                  \
               Name (_SUN, name)                  \
            }

	    hotplug_slot(1, 0x0001)
	    hotplug_slot(2, 0x0002)
	    hotplug_slot(3, 0x0003)
	    hotplug_slot(4, 0x0004)
	    hotplug_slot(5, 0x0005)
	    hotplug_slot(6, 0x0006)
	    hotplug_slot(7, 0x0007)
	    hotplug_slot(8, 0x0008)
	    hotplug_slot(9, 0x0009)
	    hotplug_slot(10, 0x000a)
	    hotplug_slot(11, 0x000b)
	    hotplug_slot(12, 0x000c)
	    hotplug_slot(13, 0x000d)
	    hotplug_slot(14, 0x000e)
	    hotplug_slot(15, 0x000f)
	    hotplug_slot(16, 0x0010)
	    hotplug_slot(17, 0x0011)
	    hotplug_slot(18, 0x0012)
	    hotplug_slot(19, 0x0013)
	    hotplug_slot(20, 0x0014)
	    hotplug_slot(21, 0x0015)
	    hotplug_slot(22, 0x0016)
	    hotplug_slot(23, 0x0017)
	    hotplug_slot(24, 0x0018)
	    hotplug_slot(25, 0x0019)
	    hotplug_slot(26, 0x001a)
	    hotplug_slot(27, 0x001b)
	    hotplug_slot(28, 0x001c)
	    hotplug_slot(29, 0x001d)
	    hotplug_slot(30, 0x001e)
	    hotplug_slot(31, 0x001f)

            Name (_CRS, ResourceTemplate ()
            {
                WordBusNumber (ResourceProducer, MinFixed, MaxFixed, PosDecode,
                    0x0000,             // Address Space Granularity
                    0x0000,             // Address Range Minimum
                    0x00FF,             // Address Range Maximum
                    0x0000,             // Address Translation Offset
                    0x0100,             // Address Length
                    ,, )
                IO (Decode16,
                    0x0CF8,             // Address Range Minimum
                    0x0CF8,             // Address Range Maximum
                    0x01,               // Address Alignment
                    0x08,               // Address Length
                    )
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000,             // Address Space Granularity
                    0x0000,             // Address Range Minimum
                    0x0CF7,             // Address Range Maximum
                    0x0000,             // Address Translation Offset
                    0x0CF8,             // Address Length
                    ,, , TypeStatic)
                WordIO (ResourceProducer, MinFixed, MaxFixed, PosDecode, EntireRange,
                    0x0000,             // Address Space Granularity
                    0x0D00,             // Address Range Minimum
                    0xFFFF,             // Address Range Maximum
                    0x0000,             // Address Translation Offset
                    0xF300,             // Address Length
                    ,, , TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, Cacheable, ReadWrite,
                    0x00000000,         // Address Space Granularity
                    0x000A0000,         // Address Range Minimum
                    0x000BFFFF,         // Address Range Maximum
                    0x00000000,         // Address Translation Offset
                    0x00020000,         // Address Length
                    ,, , AddressRangeMemory, TypeStatic)
                DWordMemory (ResourceProducer, PosDecode, MinFixed, MaxFixed, NonCacheable, ReadWrite,
                    0x00000000,         // Address Space Granularity
                    0xE0000000,         // Address Range Minimum
                    0xFEBFFFFF,         // Address Range Maximum
                    0x00000000,         // Address Translation Offset
                    0x1EC00000,         // Address Length
                    ,, , AddressRangeMemory, TypeStatic)
            })
        }
    }

    Scope(\_SB.PCI0) {
        Device (VGA) {
                 Name (_ADR, 0x00020000)
                 Method (_S1D, 0, NotSerialized)
                 {
                         Return (0x00)
                 }
                 Method (_S2D, 0, NotSerialized)
                 {
                         Return (0x00)
                 }
                 Method (_S3D, 0, NotSerialized)
                 {
                         Return (0x00)
                 }
        }

	/* PIIX3 ISA bridge */
        Device (ISA) {
            Name (_ADR, 0x00010000)

            /* PIIX PCI to ISA irq remapping */
            OperationRegion (P40C, PCI_Config, 0x60, 0x04)

            /* Real-time clock */
            Device (RTC)
            {
                Name (_HID, EisaId ("PNP0B00"))
                Name (_CRS, ResourceTemplate ()
                {
                    IO (Decode16, 0x0070, 0x0070, 0x10, 0x02)
                    IRQNoFlags () {8}
                    IO (Decode16, 0x0072, 0x0072, 0x02, 0x06)
                })
            }

            /* Keyboard seems to be important for WinXP install */
            Device (KBD)
            {
                Name (_HID, EisaId ("PNP0303"))
                Method (_STA, 0, NotSerialized)
                {
                    Return (0x0f)
                }

                Method (_CRS, 0, NotSerialized)
                {
                     Name (TMP, ResourceTemplate ()
                     {
                    IO (Decode16,
                        0x0060,             // Address Range Minimum
                        0x0060,             // Address Range Maximum
                        0x01,               // Address Alignment
                        0x01,               // Address Length
                        )
                    IO (Decode16,
                        0x0064,             // Address Range Minimum
                        0x0064,             // Address Range Maximum
                        0x01,               // Address Alignment
                        0x01,               // Address Length
                        )
                    IRQNoFlags ()
                        {1}
                    })
                    Return (TMP)
                }
            }

	    /* PS/2 mouse */
            Device (MOU)
            {
                Name (_HID, EisaId ("PNP0F13"))
                Method (_STA, 0, NotSerialized)
                {
                    Return (0x0f)
                }

                Method (_CRS, 0, NotSerialized)
                {
                    Name (TMP, ResourceTemplate ()
                    {
                         IRQNoFlags () {12}
                    })
                    Return (TMP)
                }
            }

	    /* PS/2 floppy controller */
	    Device (FDC0)
	    {
	        Name (_HID, EisaId ("PNP0700"))
		Method (_STA, 0, NotSerialized)
		{
		    Return (0x0F)
		}
		Method (_CRS, 0, NotSerialized)
		{
		    Name (BUF0, ResourceTemplate ()
                    {
                        IO (Decode16, 0x03F2, 0x03F2, 0x00, 0x04)
                        IO (Decode16, 0x03F7, 0x03F7, 0x00, 0x01)
                        IRQNoFlags () {6}
                        DMA (Compatibility, NotBusMaster, Transfer8) {2}
                    })
		    Return (BUF0)
		}
	    }

	    /* Parallel port */
	    Device (LPT)
	    {
	        Name (_HID, EisaId ("PNP0400"))
		Method (_STA, 0, NotSerialized)
		{
		    Store (\_SB.PCI0.PX13.DRSA, Local0)
		    And (Local0, 0x80000000, Local0)
		    If (LEqual (Local0, 0))
		    {
			Return (0x00)
		    }
		    Else
		    {
			Return (0x0F)
		    }
		}
		Method (_CRS, 0, NotSerialized)
		{
		    Name (BUF0, ResourceTemplate ()
                    {
			IO (Decode16, 0x0378, 0x0378, 0x08, 0x08)
			IRQNoFlags () {7}
		    })
		    Return (BUF0)
		}
	    }

	    /* Serial Ports */
	    Device (COM1)
	    {
	        Name (_HID, EisaId ("PNP0501"))
		Name (_UID, 0x01)
		Method (_STA, 0, NotSerialized)
		{
		    Store (\_SB.PCI0.PX13.DRSC, Local0)
		    And (Local0, 0x08000000, Local0)
		    If (LEqual (Local0, 0))
		    {
			Return (0x00)
		    }
		    Else
		    {
			Return (0x0F)
		    }
		}
		Method (_CRS, 0, NotSerialized)
		{
		    Name (BUF0, ResourceTemplate ()
                    {
			IO (Decode16, 0x03F8, 0x03F8, 0x00, 0x08)
                	IRQNoFlags () {4}
		    })
		    Return (BUF0)
		}
	    }

	    Device (COM2)
	    {
	        Name (_HID, EisaId ("PNP0501"))
		Name (_UID, 0x02)
		Method (_STA, 0, NotSerialized)
		{
		    Store (\_SB.PCI0.PX13.DRSC, Local0)
		    And (Local0, 0x80000000, Local0)
		    If (LEqual (Local0, 0))
		    {
			Return (0x00)
		    }
		    Else
		    {
			Return (0x0F)
		    }
		}
		Method (_CRS, 0, NotSerialized)
		{
		    Name (BUF0, ResourceTemplate ()
                    {
			IO (Decode16, 0x02F8, 0x02F8, 0x00, 0x08)
                	IRQNoFlags () {3}
		    })
		    Return (BUF0)
		}
	    }
        }

	/* PIIX4 PM */
        Device (PX13) {
	    Name (_ADR, 0x00010003)

	    OperationRegion (P13C, PCI_Config, 0x5c, 0x24)
	    Field (P13C, DWordAcc, NoLock, Preserve)
	    {
		DRSA, 32,
		DRSB, 32,
		DRSC, 32,
		DRSE, 32,
		DRSF, 32,
		DRSG, 32,
		DRSH, 32,
		DRSI, 32,
		DRSJ, 32
	    }
	}
    }

    /* PCI IRQs */
    Scope(\_SB) {
         Field (\_SB.PCI0.ISA.P40C, ByteAcc, NoLock, Preserve)
         {
             PRQ0,   8,
             PRQ1,   8,
             PRQ2,   8,
             PRQ3,   8
         }

        Device(LNKA){
                Name(_HID, EISAID("PNP0C0F"))     // PCI interrupt link
                Name(_UID, 1)
                Name(_PRS, ResourceTemplate(){
                    Interrupt (, Level, ActiveHigh, Shared)
                        { 5, 10, 11 }
                })
                Method (_STA, 0, NotSerialized)
                {
                    Store (0x0B, Local0)
                    If (And (0x80, PRQ0, Local1))
                    {
                         Store (0x09, Local0)
                    }
                    Return (Local0)
                }
                Method (_DIS, 0, NotSerialized)
                {
                    Or (PRQ0, 0x80, PRQ0)
                }
                Method (_CRS, 0, NotSerialized)
                {
                    Name (PRR0, ResourceTemplate ()
                    {
                        Interrupt (, Level, ActiveHigh, Shared)
                            {1}
                    })
                    CreateDWordField (PRR0, 0x05, TMP)
                    Store (PRQ0, Local0)
                    If (LLess (Local0, 0x80))
                    {
                        Store (Local0, TMP)
                    }
                    Else
                    {
                        Store (Zero, TMP)
                    }
                    Return (PRR0)
                }
                Method (_SRS, 1, NotSerialized)
                {
                    CreateDWordField (Arg0, 0x05, TMP)
                    Store (TMP, PRQ0)
                }
        }
        Device(LNKB){
                Name(_HID, EISAID("PNP0C0F"))     // PCI interrupt link
                Name(_UID, 2)
                Name(_PRS, ResourceTemplate(){
                    Interrupt (, Level, ActiveHigh, Shared)
                        { 5, 10, 11 }
                })
                Method (_STA, 0, NotSerialized)
                {
                    Store (0x0B, Local0)
                    If (And (0x80, PRQ1, Local1))
                    {
                         Store (0x09, Local0)
                    }
                    Return (Local0)
                }
                Method (_DIS, 0, NotSerialized)
                {
                    Or (PRQ1, 0x80, PRQ1)
                }
                Method (_CRS, 0, NotSerialized)
                {
                    Name (PRR0, ResourceTemplate ()
                    {
                        Interrupt (, Level, ActiveHigh, Shared)
                            {1}
                    })
                    CreateDWordField (PRR0, 0x05, TMP)
                    Store (PRQ1, Local0)
                    If (LLess (Local0, 0x80))
                    {
                        Store (Local0, TMP)
                    }
                    Else
                    {
                        Store (Zero, TMP)
                    }
                    Return (PRR0)
                }
                Method (_SRS, 1, NotSerialized)
                {
                    CreateDWordField (Arg0, 0x05, TMP)
                    Store (TMP, PRQ1)
                }
        }
        Device(LNKC){
                Name(_HID, EISAID("PNP0C0F"))     // PCI interrupt link
                Name(_UID, 3)
                Name(_PRS, ResourceTemplate(){
                    Interrupt (, Level, ActiveHigh, Shared)
                        { 5, 10, 11 }
                })
                Method (_STA, 0, NotSerialized)
                {
                    Store (0x0B, Local0)
                    If (And (0x80, PRQ2, Local1))
                    {
                         Store (0x09, Local0)
                    }
                    Return (Local0)
                }
                Method (_DIS, 0, NotSerialized)
                {
                    Or (PRQ2, 0x80, PRQ2)
                }
                Method (_CRS, 0, NotSerialized)
                {
                    Name (PRR0, ResourceTemplate ()
                    {
                        Interrupt (, Level, ActiveHigh, Shared)
                            {1}
                    })
                    CreateDWordField (PRR0, 0x05, TMP)
                    Store (PRQ2, Local0)
                    If (LLess (Local0, 0x80))
                    {
                        Store (Local0, TMP)
                    }
                    Else
                    {
                        Store (Zero, TMP)
                    }
                    Return (PRR0)
                }
                Method (_SRS, 1, NotSerialized)
                {
                    CreateDWordField (Arg0, 0x05, TMP)
                    Store (TMP, PRQ2)
                }
        }
        Device(LNKD){
                Name(_HID, EISAID("PNP0C0F"))     // PCI interrupt link
                Name(_UID, 4)
                Name(_PRS, ResourceTemplate(){
                    Interrupt (, Level, ActiveHigh, Shared)
                        { 5, 10, 11 }
                })
                Method (_STA, 0, NotSerialized)
                {
                    Store (0x0B, Local0)
                    If (And (0x80, PRQ3, Local1))
                    {
                         Store (0x09, Local0)
                    }
                    Return (Local0)
                }
                Method (_DIS, 0, NotSerialized)
                {
                    Or (PRQ3, 0x80, PRQ3)
                }
                Method (_CRS, 0, NotSerialized)
                {
                    Name (PRR0, ResourceTemplate ()
                    {
                        Interrupt (, Level, ActiveHigh, Shared)
                            {1}
                    })
                    CreateDWordField (PRR0, 0x05, TMP)
                    Store (PRQ3, Local0)
                    If (LLess (Local0, 0x80))
                    {
                        Store (Local0, TMP)
                    }
                    Else
                    {
                        Store (Zero, TMP)
                    }
                    Return (PRR0)
                }
                Method (_SRS, 1, NotSerialized)
                {
                    CreateDWordField (Arg0, 0x05, TMP)
                    Store (TMP, PRQ3)
                }
        }
    }

    /*
     * S3 (suspend-to-ram), S4 (suspend-to-disk) and S5 (power-off) type codes:
     * must match piix4 emulation.
     */
    Name (\_S3, Package (0x04)
    {
        0x01,  /* PM1a_CNT.SLP_TYP */
        0x01,  /* PM1b_CNT.SLP_TYP */
        Zero,  /* reserved */
        Zero   /* reserved */
    })
    Name (\_S4, Package (0x04)
    {
        Zero,  /* PM1a_CNT.SLP_TYP */
        Zero,  /* PM1b_CNT.SLP_TYP */
        Zero,  /* reserved */
        Zero   /* reserved */
    })
    Name (\_S5, Package (0x04)
    {
        Zero,  /* PM1a_CNT.SLP_TYP */
        Zero,  /* PM1b_CNT.SLP_TYP */
        Zero,  /* reserved */
        Zero   /* reserved */
    })

    Scope (\_GPE)
    {
	Name(_HID, "ACPI0006")

        Method(_L00) {
            Return(0x01)
        }

#define gen_pci_hotplug(nr)                                       \
            If (And(\_SB.PCI0.PCIU, ShiftLeft(1, nr))) {          \
                Notify(\_SB.PCI0.S##nr, 1)                        \
            }                                                     \
            If (And(\_SB.PCI0.PCID, ShiftLeft(1, nr))) {          \
                Notify(\_SB.PCI0.S##nr, 3)                        \
            }

        Method(_L01) {
	    gen_pci_hotplug(1)
	    gen_pci_hotplug(2)
	    gen_pci_hotplug(3)
	    gen_pci_hotplug(4)
	    gen_pci_hotplug(5)
	    gen_pci_hotplug(6)
	    gen_pci_hotplug(7)
	    gen_pci_hotplug(8)
	    gen_pci_hotplug(9)
	    gen_pci_hotplug(10)
	    gen_pci_hotplug(11)
	    gen_pci_hotplug(12)
	    gen_pci_hotplug(13)
	    gen_pci_hotplug(14)
	    gen_pci_hotplug(15)
	    gen_pci_hotplug(16)
	    gen_pci_hotplug(17)
	    gen_pci_hotplug(18)
	    gen_pci_hotplug(19)
	    gen_pci_hotplug(20)
	    gen_pci_hotplug(21)
	    gen_pci_hotplug(22)
	    gen_pci_hotplug(23)
	    gen_pci_hotplug(24)
	    gen_pci_hotplug(25)
	    gen_pci_hotplug(26)
	    gen_pci_hotplug(27)
	    gen_pci_hotplug(28)
	    gen_pci_hotplug(29)
	    gen_pci_hotplug(30)
	    gen_pci_hotplug(31)

            Return(0x01)
        }

        Method(_L02) {
	    Return(\_PR.PRSC())
        }
        Method(_L03) {
            Return(0x01)
        }
        Method(_L04) {
            Return(0x01)
        }
        Method(_L05) {
            Return(0x01)
        }
        Method(_L06) {
            Return(0x01)
        }
        Method(_L07) {
            Return(0x01)
        }
        Method(_L08) {
            Return(0x01)
        }
        Method(_L09) {
            Return(0x01)
        }
        Method(_L0A) {
            Return(0x01)
        }
        Method(_L0B) {
            Return(0x01)
        }
        Method(_L0C) {
            Return(0x01)
        }
        Method(_L0D) {
            Return(0x01)
        }
        Method(_L0E) {
            Return(0x01)
        }
        Method(_L0F) {
            Return(0x01)
        }
    }
}
