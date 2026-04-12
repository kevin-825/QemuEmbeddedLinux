#include <linux/init.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");

static int __init primitive_lab_1_init(void) {
    printk(KERN_INFO "primitive_lab_1: Loaded\n");
    return 0;
}

static void __exit primitive_lab_1_exit(void) {
    printk(KERN_INFO "primitive_lab_1: Unloaded\n");
}

module_init(primitive_lab_1_init);
module_exit(primitive_lab_1_exit);
