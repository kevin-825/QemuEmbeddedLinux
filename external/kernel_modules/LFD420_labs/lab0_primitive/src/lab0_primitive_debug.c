#include <linux/module.h>
#include <linux/debugfs.h>
#include "lab0_primitive_debug.h"

/* * The root directory for our module in /sys/kernel/debug/
 */
static struct dentry *lab0_primitive_debug_dir;

/* * Live variables we want to expose to the terminal 
 */
u32 lab0_primitive_debug_hit_count = 0;
u32 lab0_primitive_simulated_fault = 0;

void lab0_primitive_debug_init(void)
{
    /* 1. Create the root folder: /sys/kernel/debug/lab0_primitive/ */
    lab0_primitive_debug_dir = debugfs_create_dir("lab0_primitive", NULL);
    
    if (!lab0_primitive_debug_dir) {
        pr_err("[%s] Failed to create debugfs directory.\n", KBUILD_MODNAME);
        return;
    }

    /* 2. Create a Read-Only file to track how many times a function is hit */
    debugfs_create_u32("hit_count", 0444, lab0_primitive_debug_dir, &lab0_primitive_debug_hit_count);

    /* 3. Create a Read/Write file to let us manually trigger faults via bash */
    debugfs_create_u32("simulate_fault", 0644, lab0_primitive_debug_dir, &lab0_primitive_simulated_fault);

    LAB0_PRIMITIVE_DBG("Debug subsystem and debugfs initialized.\n");
}

void lab0_primitive_debug_cleanup(void)
{
    /* * debugfs_remove_recursive safely destroys the folder and all 
     * files inside it in one shot. 
     */
    debugfs_remove_recursive(lab0_primitive_debug_dir);
    
    pr_info("[%s:debug] Debug subsystem offline.\n", KBUILD_MODNAME);
}
