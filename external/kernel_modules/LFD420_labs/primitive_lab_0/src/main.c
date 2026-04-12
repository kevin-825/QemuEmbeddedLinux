#include <linux/init.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");

static int __init primitive_lab_0_init(void) {
    printk(KERN_INFO "primitive_lab_0: Loaded\n");
    return 0;
}

static void __exit primitive_lab_0_exit(void) {
    printk(KERN_INFO "primitive_lab_0: Unloaded\n");
}

module_init(primitive_lab_0_init);
module_exit(primitive_lab_0_exit);
