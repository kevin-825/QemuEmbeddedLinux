#!/bin/sh

# \h = Hostname (e.g., riscv-qemu)
# \w = Current working directory (e.g., /etc/profile.d)
# \$ = Shows '#' if root, '$' if a normal user

# Option 1: Standard Plain Text Prompt
# Output: root@riscv-qemu:/etc# 
#export PS1="\u@\h:\w\$ "

# Option 2: Colored Prompt (Highly recommended for readability)
# Makes "root@riscv-qemu" green and the path blue.
export PS1="\[\e[32m\]\u@\h\[\e[m\]:\[\e[34m\]\w\[\e[m\]\$ "


