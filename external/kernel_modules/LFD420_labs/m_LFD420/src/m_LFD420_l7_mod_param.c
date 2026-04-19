#include <linux/module.h>
#include <linux/init.h>
#include <linux/moduleparam.h>

/* 1. The Debug Toggle (Permissions 0644 - Can be changed at runtime!) */
static bool debug_mode = false;
module_param(debug_mode, bool, 0644);
MODULE_PARM_DESC(debug_mode, "Set to 1 to enable verbose register logging");

/* 2. The DMA Fallback (Permissions 0444 - Read Only after boot) */
static bool use_dma = false;
module_param(use_dma, bool, 0444);
MODULE_PARM_DESC(use_dma, "Set to 0 to disable DMA and fallback to PIO mode");

/* 3. The Tuning Integer (Permissions 0644 - Can be tuned at runtime) */
static int poll_interval_ms = 500;
module_param(poll_interval_ms, int, 0644);
MODULE_PARM_DESC(poll_interval_ms, "Sensor polling interval in milliseconds");

/* 4. The Hardware Array (Passing a MAC Address) */
static int mac_addr[6] = {0, 0, 0, 0, 0, 0};
static int mac_addr_count = 0; /* The kernel will automatically populate this with the array size */
module_param_array(mac_addr, int, &mac_addr_count, 0644);
MODULE_PARM_DESC(mac_addr, "Override hardware MAC address (Array of 6 bytes)");

/* --------------------------------------------------------- */

static int __init my_practical_driver_init(void)
{
    pr_info("Driver loaded. Configuration:\n");
    pr_info(" - DMA Enabled: %s\n", use_dma ? "Yes" : "No");
    pr_info(" - Poll Interval: %d ms\n", poll_interval_ms);
    pr_info(" - Debug Mode: %s\n", debug_mode ? "Yes" : "No");
    pr_info(" - mac_addr_count: %d\n", mac_addr_count);
    for (int i = 0; i < mac_addr_count; i++) {
        pr_info(" - MAC Address %d: %02X \n", i, mac_addr[i]);
    }


    if (debug_mode) {
        pr_info("[DEBUG] Executing low-level hardware initialization...\n");
        /* Dump hardware registers... */
    }

    return 0;
}

static void __exit my_practical_driver_exit(void)
{
    pr_info("Driver unloaded.\n");
}



static int motor_speed_rpm = 0;
/* ------------------------------------------------------------------
 * 2. THE CALLBACK FUNCTION
 * This executes in Process Context the moment the user writes to the sysfs file.
 * ------------------------------------------------------------------ */
static int update_motor_speed_cb(const char *val, const struct kernel_param *kp)
{
    int ret;
    int old_speed = motor_speed_rpm;

    /* Step A: Let the kernel securely parse the string into our integer */
    /* param_set_int automatically updates the 'motor_speed_rpm' variable */
    ret = param_set_int(val, kp);
    if (ret != 0) {
        pr_err("[Motor Driver] Error: Invalid integer format provided.\n");
        return ret;
    }

    /* Step B: Validate the new input (Protect the hardware!) */
    if (motor_speed_rpm < 0 || motor_speed_rpm > 10000) {
        pr_err("[Motor Driver] Error: %d RPM is out of safe bounds (0-10000).\n", motor_speed_rpm);
        motor_speed_rpm = old_speed; /* Revert to safe state */
        return -EINVAL; /* Tell user-space the write failed */
    }

    /* Step C: Take immediate hardware action */
    pr_info("[Motor Driver] Dynamic update: Speed changed from %d to %d RPM.\n", old_speed, motor_speed_rpm);
    pr_info("[Motor Driver] --> Pushing new PWM values to I2C controller NOW...\n");
    
    /* * REAL HARDWARE LOGIC GOES HERE 
     * e.g., i2c_smbus_write_word_data(my_i2c_client, PWM_REGISTER, motor_speed_rpm);
     */

    return 0; /* Success */
}

/* ------------------------------------------------------------------
 * 1. THE OPERATIONS STRUCTURE
 * ------------------------------------------------------------------ */
static const struct kernel_param_ops motor_speed_ops = {
    .set = update_motor_speed_cb,  /* Call our custom function when the user uses 'echo' */
    .get = param_get_int,          /* Use the standard kernel function when the user uses 'cat' */
};

/* ------------------------------------------------------------------
 * 3. REGISTER THE PARAMETER
 * 0644 gives root write-access, and everyone else read-access.
 * ------------------------------------------------------------------ */
module_param_cb(motor_speed_rpm, &motor_speed_ops, &motor_speed_rpm, 0644);
MODULE_PARM_DESC(motor_speed_rpm, "Target motor speed in RPM (0 to 10000)");


module_init(my_practical_driver_init);
module_exit(my_practical_driver_exit);
MODULE_LICENSE("GPL");