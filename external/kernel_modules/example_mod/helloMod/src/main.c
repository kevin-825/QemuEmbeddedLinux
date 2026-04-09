#include <linux/init.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");

static int __init helloMod_init(void) {
    printk(KERN_INFO "helloMod: Loaded\n");
    return 0;
}

static void __exit helloMod_exit(void) {
    printk(KERN_INFO "helloMod: Unloaded\n");
}

module_init(helloMod_init);
module_exit(helloMod_exit);
