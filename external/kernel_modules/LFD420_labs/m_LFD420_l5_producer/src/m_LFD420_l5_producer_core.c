#include <linux/init.h>
#include <linux/module.h>
#include "m_LFD420_l5_producer_core.h"
#include "m_LFD420_l5_producer_debug.h"

unsigned int my_producer_buf_szie = 512;
unsigned int my_producer_buf[512];
static int __init m_LFD420_l5_producer_init(void)
{
    /* Self-Awareness: Log exactly how this was compiled */
#ifdef MODULE
    pr_info("[%s] Core initialized as a Loadable Module (M).\n", KBUILD_MODNAME);
#else
    pr_info("[%s] Core initialized directly into kernel boot (Y).\n", KBUILD_MODNAME);
#endif

    /* Initialize the debug subsystem if enabled */
    m_LFD420_l5_producer_debug_init();

    return 0;
}

int m_LFD420_l5_producer_generate_fabonaci(int n)
{
    if (n <= 2)
    {
        return n;
    }

    return m_LFD420_l5_producer_generate_fabonaci(n - 1) + m_LFD420_l5_producer_generate_fabonaci(n - 2);
}

static void __exit m_LFD420_l5_producer_exit(void)
{
    /* Safely cleanup debug allocations before exiting */
    m_LFD420_l5_producer_debug_cleanup();

    pr_info("[%s] Core module unloaded safely.\n", KBUILD_MODNAME);
}

module_init(m_LFD420_l5_producer_init);
module_exit(m_LFD420_l5_producer_exit);

EXPORT_SYMBOL(m_LFD420_l5_producer_generate_fabonaci);
EXPORT_SYMBOL(my_producer_buf_szie);
EXPORT_SYMBOL(my_producer_buf);

MODULE_AUTHOR("Kevin");
MODULE_DESCRIPTION("External Kernel Module for m_LFD420_l5_producer");
MODULE_LICENSE("GPL");
