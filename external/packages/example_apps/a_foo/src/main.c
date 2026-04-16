#include <stdio.h>
#include "a_foo.h"

int main(int argc, char **argv) {
    printf("Hello from a_foo user-space application!\n");
    
    for (int i = 0; i < argc; i++) {
        printf("Argument %d: %s\n", i, argv[i]);
    }
    
    return 0;
}
