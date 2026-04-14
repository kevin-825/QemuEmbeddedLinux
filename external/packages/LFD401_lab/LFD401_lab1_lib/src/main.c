#include <stdio.h>
#include "LFD401_lab1_lib.h"

int main(int argc, char **argv) {
    printf("Hello from LFD401_lab1_lib user-space application!\n");
    
    for (int i = 0; i < argc; i++) {
        printf("Argument %d: %s\n", i, argv[i]);
    }
    
    return 0;
}
