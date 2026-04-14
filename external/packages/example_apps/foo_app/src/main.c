#include <stdio.h>
#include "foo_app.h"

int main(int argc, char **argv) {
    printf("Hello from foo_app user-space application!\n");
    
    for (int i = 0; i < argc; i++) {
        printf("Argument %d: %s\n", i, argv[i]);
    }
    
    return 0;
}
