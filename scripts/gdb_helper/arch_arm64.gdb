# ==============================================================================
# ARM64 SPECIFIC HARDWARE RULES & MACROS
# ==============================================================================
set architecture aarch64



# --- 2. Quick Info Registers ---
define infr
    echo [\n] General Purpose Registers:\n
    info registers x30 x29
    info registers x0 x1 x2 x3 x4 x5 x6 x7
    info registers x9 x10 x11 x12 x13 x14 x15
    info registers sp pc cpsr
end

define info_sys_reg
    echo [\n] Exception Level 1 (EL1) System Registers [Linux State]:\n
    info registers esr_el1 elr_el1 far_el1 vbar_el1 spsr_el1
end

# --- Exception Level 2 (Hypervisor) Registers ---
define info_el2_reg
    echo [\n] Exception Level 2 (EL2) System Registers [Hypervisor State]:\n
    # esr_el2: Trap reason from EL1 to EL2
    # elr_el2: Return address back to Guest OS
    info registers esr_el2 elr_el2 far_el2 vbar_el2 spsr_el2
end

# --- Exception Level 3 (Secure Monitor) Registers ---
define info_el3_reg
    echo [\n] Exception Level 3 (EL3) System Registers [Firmware/TrustZone State]:\n
    info registers esr_el3 elr_el3 far_el3 vbar_el3 spsr_el3
end

# --- Current Privilege Level Check ---
define current_el
    # The CurrentEL register holds the Exception Level in bits [3:2]
    set $el = ($CurrentEL >> 2) & 3
    printf "CPU is currently executing in: EL%d\n", $el
end

# --- 3. RISC-V to ARM64 Muscle Memory Translator ---
# Allows you to use familiar RISC-V names in your manual commands
define map_riscv_aliases
    set $a0 = $x0
    set $a1 = $x1
    set $a2 = $x2
    set $a3 = $x3
    set $t0 = $x9
    set $t1 = $x10
    set $t2 = $x11
    set $fp = $x29
    set $ra = $x30
end

# --- 4. Python-Powered Exception Decoder ---
# ==============================================================================
# ARM64 ESR_EL1 DECODER (Complete Exception Class Dictionary)
# ==============================================================================
python
import gdb

class DecodeESR(gdb.Command):
    """Decodes the complete ARM64 ESR_EL1 (Exception Syndrome Register)."""
    
    def __init__(self):
        super(DecodeESR, self).__init__("decode_esr", gdb.COMMAND_USER)
        
        # The Complete ARMv8/ARMv9 Exception Class (EC) Dictionary
        self.ec_dict = {
            # --- System / General Traps ---
            0x00: "Unknown Reason (Often a bad instruction or manual break)",
            0x01: "Trapped WFI or WFE instruction",
            0x07: "Trapped SME, SVE, or Advanced SIMD/FP instruction",
            0x09: "Trapped Pointer Authentication (PAC) instruction",
            0x0A: "Trapped LD64B or ST64B execution",
            0x0D: "Branch Target Exception (BTI)",
            0x0E: "Illegal Execution State",
            0x18: "Trapped MSR, MRS or System instruction execution",
            0x19: "Trapped SVE instruction execution",
            0x1A: "Trapped ERET, ERETAA, or ERETAB execution",
            0x1C: "Failed Pointer Authentication (PAC) validation",

            # --- System Calls (Syscalls, Hypercalls, Secure Monitor) ---
            0x11: "SVC instruction execution in AArch32",
            0x12: "HVC instruction execution in AArch32",
            0x13: "SMC instruction execution in AArch32",
            0x15: "SVC instruction execution in AArch64 (Syscall from U-Mode)",
            0x16: "HVC instruction execution in AArch64 (Hypercall to EL2)",
            0x17: "SMC instruction execution in AArch64 (Secure Monitor Call to EL3)",

            # --- AArch32 (32-bit Compat) Specific Traps ---
            0x03: "Trapped CP15 MCR or MRC (AArch32)",
            0x04: "Trapped CP15 MCRR or MRRC (AArch32)",
            0x05: "Trapped CP14 MCR or MRC (AArch32)",
            0x06: "Trapped CP14 LDC or STC (AArch32)",
            0x08: "Trapped VMRS instruction (AArch32)",
            0x0C: "Trapped MRRC instruction (AArch32)",
            0x28: "Trapped Floating-Point exception in AArch32",

            # --- Memory & Alignment Faults (The Critical Ones) ---
            0x20: "Instruction Abort from a lower Exception Level (User-space trap)",
            0x21: "Instruction Abort taken without a change in Exception Level (Kernel crashed itself)",
            0x22: "PC alignment fault execution",
            0x24: "Data Abort from a lower Exception Level (User-space bad memory access)",
            0x25: "Data Abort taken without a change in Exception Level (Kernel bad memory access / NULL dereference)",
            0x26: "SP alignment fault execution",
            0x2C: "Trapped Floating-Point exception in AArch64",
            0x2F: "SError Interrupt (Asynchronous hardware fault)",

            # --- Hardware Debug (Breakpoints, Watchpoints, Stepping) ---
            0x30: "Hardware Breakpoint from a lower Exception Level",
            0x31: "Hardware Breakpoint taken without a change in Exception Level",
            0x32: "Software Step from a lower Exception Level",
            0x33: "Software Step taken without a change in Exception Level",
            0x34: "Hardware Watchpoint from a lower Exception Level",
            0x35: "Hardware Watchpoint taken without a change in Exception Level",
            0x38: "BKPT instruction execution in AArch32",
            0x3C: "BRK instruction execution in AArch64 (Software Breakpoint)"
        }

    def invoke(self, arg, from_tty):
        try:
            esr_val = int(gdb.parse_and_eval("$esr_el1"))
        except gdb.error:
            print("Error: Could not read $esr_el1. Ensure you are connected to the target.")
            return

        # Extract Exception Class (EC) from bits [31:26]
        ec = (esr_val >> 26) & 0x3F
        
        # O(1) Dictionary Lookup
        reason = self.ec_dict.get(ec, "Reserved/Unknown Exception Class (0x{:02x})".format(ec))
        
        print("ESR_EL1 Decode: [0x{:08x}] -> {}".format(esr_val, reason))
        
        # Automatically print the Faulting Address for Data/Instruction Aborts
        if ec in [0x20, 0x21, 0x24, 0x25]:
            try:
                far_val = int(gdb.parse_and_eval("$far_el1"))
                print("FAR_EL1 (Faulting Address): 0x{:016x}".format(far_val))
            except gdb.error:
                pass

DecodeESR()
end

# --- 5. Architecture Specific Stop Hook ---
define hook-stop
    echo \n=======================================================\n
    echo [ARM64] CPU Paused. Context:\n
    display /i $pc
    
    # Map convenience variables silently
    map_riscv_aliases
    
    # Automatically decode the crash reason if one exists
    decode_esr
    
    # Dump system and general registers
    info_sys_reg
    infr
    
    echo =======================================================\n
end




# ==============================================================================
# ARM64 PAGE TABLE WALKER (Python Implementation for 4KB/48-bit VA)
# ==============================================================================
python
import gdb
import re

class WalkPageTableARM64(gdb.Command):
    """
    Walks the ARM64 Translation Table for a given Virtual Address.
    Usage: pt_walk <virtual_address>
    Example: pt_walk $far_el1
    """
    
    def __init__(self):
        super(WalkPageTableARM64, self).__init__("pt_walk", gdb.COMMAND_USER)

    def invoke(self, arg, from_tty):
        if not arg:
            print("Error: Please provide a virtual address. (e.g., pt_walk $far_el1)")
            return
            
        try:
            va = int(gdb.parse_and_eval(arg))
        except gdb.error:
            print("Error: Could not parse address.")
            return

        # 1. Determine which Translation Table Base Register to use
        # In ARM64, if the top bits are 1s (0xFFFF...), it's Kernel Space (TTBR1)
        # If the top bits are 0s (0x0000...), it's User Space (TTBR0)
        is_kernel = (va >> 55) & 1
        
        try:
            if is_kernel:
                ttbr = int(gdb.parse_and_eval("$ttbr1_el1"))
                table_name = "TTBR1_EL1 (Kernel Space)"
            else:
                ttbr = int(gdb.parse_and_eval("$ttbr0_el1"))
                table_name = "TTBR0_EL1 (User Space)"
        except gdb.error:
            print("Error: Could not read TTBR registers.")
            return

        # Extract the physical base address of the Level 0 table
        # Masks out the ASID and control bits (Assumes standard 48-bit PA)
        root_pa = ttbr & 0x0000FFFFFFFFF000

        print("\n--- ARM64 Translation Table Walk ---")
        print("Target Virtual Address : 0x{:016x}".format(va))
        print("Root Register Selected : {}".format(table_name))
        print("Root Physical Address  : 0x{:016x}".format(root_pa))

        # Extract the 4 Level Indexes (9 bits each for 4KB pages)
        indexes = [
            (va >> 39) & 0x1FF,  # Level 0 (PGD)
            (va >> 30) & 0x1FF,  # Level 1 (PUD)
            (va >> 21) & 0x1FF,  # Level 2 (PMD)
            (va >> 12) & 0x1FF   # Level 3 (PTE)
        ]

        # 2. Walk the Tree
        curr_pa = root_pa
        for level in range(4):
            # Calculate physical address of the Descriptor
            desc_pa = curr_pa + (indexes[level] * 8)
            
            # USE QEMU BACKDOOR: Read 1 Giant word (8 bytes) of Physical memory
            monitor_cmd = "monitor xp /1gx 0x{:x}".format(desc_pa)
            try:
                out = gdb.execute(monitor_cmd, to_string=True)
                match = re.search(r':\s+([0-9a-fA-F]+)', out)
                if not match: raise ValueError
                desc = int(match.group(1), 16)
            except:
                print("Error: QEMU physical memory read failed at 0x{:016x}".format(desc_pa))
                return

            print("\nLevel {} (Index 0x{:03x}):".format(level, indexes[level]))
            print("  Descriptor Location : 0x{:016x}".format(desc_pa))
            print("  Descriptor Value    : 0x{:016x}".format(desc))

            # Extract basic valid/type bits
            valid = desc & 1
            is_table = (desc >> 1) & 1

            if not valid:
                print("  -> RESULT: TRANSLATION FAULT (Page not mapped!)")
                return

            # Check if we hit a Block/Page (Leaf Node) or if we need to keep walking
            is_leaf = False
            if level < 3 and not is_table:
                is_leaf = True  # Block entry (e.g., 1GB or 2MB block)
                if level == 1: page_size = "1GB Block"
                if level == 2: page_size = "2MB Block"
            elif level == 3 and is_table:
                is_leaf = True  # Level 3 Page entry (4KB)
                page_size = "4KB Page"

            if is_leaf:
                # Extract Physical Address (Bits 47:12)
                target_pa_base = desc & 0x0000FFFFFFFFF000
                
                # Extract Permissions
                ap = (desc >> 6) & 3
                pxn = (desc >> 53) & 1
                uxn = (desc >> 54) & 1
                
                perm_str = "R/W" if (ap == 0 or ap == 1) else "Read-Only"
                priv_str = "EL0/EL1" if (ap == 1 or ap == 3) else "EL1 Only"
                exec_str = "Executable" if not pxn else "Privileged Execute-Never (PXN)"

                print("  -> RESULT: VALID LEAF ({})".format(page_size))
                print("  -> Target Phys Base : 0x{:016x}".format(target_pa_base))
                print("  -> Access Rights    : {} ({})".format(perm_str, priv_str))
                print("  -> Execution        : {}".format(exec_str))
                return
            else:
                # It's a pointer to the next table level
                curr_pa = desc & 0x0000FFFFFFFFF000
                print("  -> Pointer to Level {} Table at 0x{:016x}".format(level + 1, curr_pa))

WalkPageTableARM64()
end