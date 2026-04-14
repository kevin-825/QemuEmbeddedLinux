#include <linux/init.h>
#include <linux/module.h>
#include "foo_core.h"
#include "foo_debug.h"

static int __init foo_init(void)
{
    /* Self-Awareness: Log exactly how this was compiled */
#ifdef MODULE
    pr_info("[%s] Core initialized as a Loadable Module (M).\n", KBUILD_MODNAME);
#else
    pr_info("[%s] Core initialized directly into kernel boot (Y).\n", KBUILD_MODNAME);
#endif

    /* Initialize the debug subsystem if enabled */
    foo_debug_init();

    return 0;
}

static void __exit foo_exit(void)
{
    /* Safely cleanup debug allocations before exiting */
    foo_debug_cleanup();

    pr_info("[%s] Core module unloaded safely.\n", KBUILD_MODNAME);
}

module_init(foo_init);
module_exit(foo_exit);

MODULE_AUTHOR("Kevin");
MODULE_DESCRIPTION("External Kernel Module for foo");
MODULE_LICENSE("GPL");
