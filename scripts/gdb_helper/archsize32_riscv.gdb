define dprio
    x/4x 0x0C000000 + ($arg0 * 4)
end


define archsize32_riscv-stop-hook
    echo \n=======================================================\n
    echo [RISC-V 32] CPU Paused. Context:\n
    display /i $pc
    
    
    echo =======================================================\n
end