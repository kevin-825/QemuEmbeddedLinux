#include <stdio.h>
#include "a_hello_world.h"

int main(int argc, char **argv) {
    printf("Hello from a_hello_world user-space application!\n");
    
    for (int i = 0; i < argc; i++) {
        printf("Argument %d: %s\n", i, argv[i]);
    }
    
    return 0;
}
