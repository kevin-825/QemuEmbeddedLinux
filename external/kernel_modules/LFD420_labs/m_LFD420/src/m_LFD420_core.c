#include <linux/init.h>
#include <linux/module.h>
#include "m_LFD420_core.h"
#include "m_LFD420_debug.h"

static int __init m_LFD420_init(void)
{
    /* Self-Awareness: Log exactly how this was compiled */
#ifdef MODULE
    pr_info("[%s] Core initialized as a Loadable Module (M).\n", KBUILD_MODNAME);
#else
    pr_info("[%s] Core initialized directly into kernel boot (Y).\n", KBUILD_MODNAME);
#endif

    /* Initialize the debug subsystem if enabled */
    m_LFD420_debug_init();

    return 0;
}

static void __exit m_LFD420_exit(void)
{
    /* Safely cleanup debug allocations before exiting */
    m_LFD420_debug_cleanup();

    pr_info("[%s] Core module unloaded safely.\n", KBUILD_MODNAME);
}

module_init(m_LFD420_init);
module_exit(m_LFD420_exit);

MODULE_AUTHOR("Kevin");
MODULE_DESCRIPTION("External Kernel Module for m_LFD420");
MODULE_LICENSE("GPL");
