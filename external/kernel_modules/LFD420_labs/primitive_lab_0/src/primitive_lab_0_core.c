#include <linux/init.h>
#include <linux/module.h>
#include "primitive_lab_0_core.h"
#include "primitive_lab_0_debug.h"

static int __init primitive_lab_0_init(void)
{
    /* Self-Awareness: Log exactly how this was compiled */
#ifdef MODULE
    pr_info("[%s] Core initialized as a Loadable Module (M).\n", KBUILD_MODNAME);
#else
    pr_info("[%s] Core initialized directly into kernel boot (Y).\n", KBUILD_MODNAME);
#endif

    /* Initialize the debug subsystem if enabled */
    primitive_lab_0_debug_init();

    return 0;
}

static void __exit primitive_lab_0_exit(void)
{
    /* Safely cleanup debug allocations before exiting */
    primitive_lab_0_debug_cleanup();

    pr_info("[%s] Core module unloaded safely.\n", KBUILD_MODNAME);
}

module_init(primitive_lab_0_init);
module_exit(primitive_lab_0_exit);

MODULE_AUTHOR("Kevin");
MODULE_DESCRIPTION("External Kernel Module for primitive_lab_0");
MODULE_LICENSE("GPL");
