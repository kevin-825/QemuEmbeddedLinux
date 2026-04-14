#include <stdio.h>
#include "LFD401_lab0_compiler.h"

int main(int argc, char **argv) {
    printf("Hello from LFD401_lab0_compiler user-space application!\n");
    
    for (int i = 0; i < argc; i++) {
        printf("Argument %d: %s\n", i, argv[i]);
    }
    
    return 0;
}
