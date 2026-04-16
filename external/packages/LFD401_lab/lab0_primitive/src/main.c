#include <stdio.h>
#include "lab0_primitive.h"

int main(int argc, char **argv) {
    printf("Hello from lab0_primitive user-space application!\n");
    
    for (int i = 0; i < argc; i++) {
        printf("Argument %d: %s\n", i, argv[i]);
    }
    
    return 0;
}
