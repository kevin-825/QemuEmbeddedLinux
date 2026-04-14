#include <linux/init.h>
#include <linux/module.h>
#include "helloMod_core.h"
#include "helloMod_debug.h"

static int __init helloMod_init(void)
{
    /* Self-Awareness: Log exactly how this was compiled */
#ifdef MODULE
    pr_info("[%s] Core initialized as a Loadable Module (M).\n", KBUILD_MODNAME);
#else
    pr_info("[%s] Core initialized directly into kernel boot (Y).\n", KBUILD_MODNAME);
#endif

    /* Initialize the debug subsystem if enabled */
    helloMod_debug_init();

    return 0;
}

static void __exit helloMod_exit(void)
{
    /* Safely cleanup debug allocations before exiting */
    helloMod_debug_cleanup();

    pr_info("[%s] Core module unloaded safely.\n", KBUILD_MODNAME);
}

module_init(helloMod_init);
module_exit(helloMod_exit);

MODULE_AUTHOR("Kevin");
MODULE_DESCRIPTION("External Kernel Module for helloMod");
MODULE_LICENSE("GPL");
