#include <linux/init.h>   // Required for the __init and __exit macros
#include <linux/module.h> // Core header for loading LKMs into the kernel
#include <linux/kernel.h> // Contains types, macros, and functions for the kernel

// -----------------------------------------------------------------------------
// Module Metadata
// -----------------------------------------------------------------------------
MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("A simple Hello World kernel module.");
MODULE_VERSION("1.0");

// -----------------------------------------------------------------------------
// Initialization Function
// -----------------------------------------------------------------------------
// The __init macro tells the kernel to free up this function's memory 
// immediately after the module finishes loading.
static int __init hello_init(void) 
{
    // pr_info is the kernel's equivalent of printf. 
    // It logs messages to the kernel ring buffer (viewable via dmesg).
    pr_info("Hello, World! The kernel module has been loaded.\n");
    
    // Returning 0 indicates successful loading. 
    // A non-zero return means initialization failed and the module won't load.
    return 0; 
}

// -----------------------------------------------------------------------------
// Cleanup Function
// -----------------------------------------------------------------------------
// The __exit macro tells the compiler to omit this function if the module 
// is built directly into the kernel (since it can never be unloaded).
static void __exit hello_exit(void) 
{
    pr_info("Goodbye, World! The kernel module has been unloaded.\n");
}

// -----------------------------------------------------------------------------
// Module Registration
// -----------------------------------------------------------------------------
module_init(hello_init);
module_exit(hello_exit);
