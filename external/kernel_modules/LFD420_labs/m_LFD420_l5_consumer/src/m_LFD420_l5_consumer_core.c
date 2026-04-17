#include <linux/init.h>
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/slab.h>
#include <linux/of.h>

#include "m_LFD420_l5_consumer_core.h"
#include "m_LFD420_l5_consumer_debug.h"

extern int m_LFD420_l5_producer_generate_fabonaci(int n);
extern unsigned int my_producer_buf[];
extern unsigned int my_producer_buf_szie;

void m_LFD420_l5_consumer_gen_10_fab(void);

static int __init m_LFD420_l5_consumer_init(void)
{
    /* Self-Awareness: Log exactly how this was compiled */
#ifdef MODULE
    pr_info("[%s] Core initialized as a Loadable Module (M).\n", KBUILD_MODNAME);
#else
    pr_info("[%s] Core initialized directly into kernel boot (Y).\n", KBUILD_MODNAME);
#endif

    /* Initialize the debug subsystem if enabled */
    m_LFD420_l5_consumer_debug_init();
    pr_info("my_producer_buf_szie: %d\n", my_producer_buf_szie);
    pr_info("my_producer_buf: %p\n", my_producer_buf);
    m_LFD420_l5_consumer_gen_10_fab();

    return 0;
}

void m_LFD420_l5_consumer_gen_10_fab(void)
{
    for (int i = 0; i < 10; i++)
    {
        my_producer_buf[i] = m_LFD420_l5_producer_generate_fabonaci(i);
    }
    printk(KERN_INFO "10 fab generated.");
    for (int i = 0; i < 10; i++)
    {
        pr_info("fab%d: %d", i,my_producer_buf[i]);
    }
}

static void __exit m_LFD420_l5_consumer_exit(void)
{
    /* Safely cleanup debug allocations before exiting */
    m_LFD420_l5_consumer_debug_cleanup();

    pr_info("[%s] Core module unloaded safely.\n", KBUILD_MODNAME);
}

module_init(m_LFD420_l5_consumer_init);
module_exit(m_LFD420_l5_consumer_exit);

MODULE_AUTHOR("Kevin");
MODULE_DESCRIPTION("External Kernel Module for m_LFD420_l5_consumer");
MODULE_LICENSE("GPL");
