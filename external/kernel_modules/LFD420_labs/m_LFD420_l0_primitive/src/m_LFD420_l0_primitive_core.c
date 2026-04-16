#include <linux/init.h>
#include <linux/module.h>
#include <linux/sched.h>   /* Required for 'current' task struct */
#include <linux/jiffies.h> /* Required for 'jiffies' */
#include <linux/slab.h>    /* Required for kmalloc/kfree */

#include "m_LFD420_l0_primitive_core.h"
#include "m_LFD420_l0_primitive_debug.h"

/* Pointer to hold our dynamically allocated memory for the lab */
static char *my_buffer;

static int __init m_LFD420_l0_primitive_init(void)
{
    /* Self-Awareness: Log exactly how this was compiled */
#ifdef MODULE
    pr_info("[%s] Core initialized as a Loadable Module (M).\n", KBUILD_MODNAME);
#else
    pr_info("[%s] Core initialized directly into kernel boot (Y).\n", KBUILD_MODNAME);
#endif

    /* LFD420 Lab Requirement: Timer tick and Process Context */
    pr_info("[%s] Current jiffies: %lu\n", KBUILD_MODNAME, jiffies);
    pr_info("[%s] Loaded by process: %s (PID: %d)\n", KBUILD_MODNAME, current->comm, current->pid);

    /* LFD420 Lab Requirement: Dynamic Memory Allocation */
    my_buffer = kmalloc(256, GFP_KERNEL);
    if (!my_buffer)
    {
        pr_err("[%s] Failed to allocate 256 bytes of memory!\n", KBUILD_MODNAME);
        return -ENOMEM;
    }
    pr_info("[%s] Successfully allocated 256 bytes at %p\n", KBUILD_MODNAME, my_buffer);

    /* Initialize your custom debug subsystem */
    m_LFD420_l0_primitive_debug_init();

    return 0;
}

static void __exit m_LFD420_l0_primitive_exit(void)
{
    /* Safely cleanup your custom debug allocations before exiting */
    m_LFD420_l0_primitive_debug_cleanup();

    /* Clean up the lab memory allocation */
    if (my_buffer)
    {
        kfree(my_buffer);
        pr_info("[%s] Lab memory buffer freed.\n", KBUILD_MODNAME);
    }

    pr_info("[%s] Core module unloaded safely.\n", KBUILD_MODNAME);
}

module_init(m_LFD420_l0_primitive_init);
module_exit(m_LFD420_l0_primitive_exit);

MODULE_AUTHOR("Kevin");
MODULE_DESCRIPTION("External Kernel Module for m_LFD420_l0_primitive");
MODULE_LICENSE("GPL");
