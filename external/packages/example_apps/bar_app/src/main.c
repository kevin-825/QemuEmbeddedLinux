#include <stdio.h>
#include "bar_app.h"

int main(int argc, char **argv) {
    printf("Hello from bar_app user-space application!\n");
    
    for (int i = 0; i < argc; i++) {
        printf("Argument %d: %s\n", i, argv[i]);
    }
    
    return 0;
}
