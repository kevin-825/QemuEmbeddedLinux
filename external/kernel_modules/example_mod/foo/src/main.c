#include <linux/init.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");

static int __init foo_init(void) {
    printk(KERN_INFO "foo: Loaded\n");
    return 0;
}

static void __exit foo_exit(void) {
    printk(KERN_INFO "foo: Unloaded\n");
}

module_init(foo_init);
module_exit(foo_exit);
