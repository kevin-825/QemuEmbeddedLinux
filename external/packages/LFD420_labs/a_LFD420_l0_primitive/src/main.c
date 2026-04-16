#include <stdio.h>
#include "a_LFD420_l0_primitive.h"

int main(int argc, char **argv) {
    printf("Hello from a_LFD420_l0_primitive user-space application!\n");
    
    for (int i = 0; i < argc; i++) {
        printf("Argument %d: %s\n", i, argv[i]);
    }
    
    return 0;
}
