#include <linux/init.h>
#include <linux/module.h>
#include <linux/preempt.h> // To access preempt_count(), preempt_disable(), and preempt_enable()
#include <linux/smp.h>     // To access smp_processor_id()
#include <linux/kthread.h>      /* For kthread_run, kthread_stop */
#include <linux/sched.h>        /* For task_struct, current macro */
#include <linux/delay.h>        /* For msleep */
#include <uapi/linux/sched/types.h> /* For SCHED_FIFO and sched_param */

#include "m_LFD420_core.h"
#include "m_LFD420_debug.h"

struct task_struct *my_LFD420_task_handle;
/* Get current time in ticks */
// unsigned long current_time = jiffies;

/* Convert milliseconds to ticks (equivalent to pdMS_TO_TICKS in FreeRTOS) */
// unsigned long ticks = msecs_to_jiffies(100);

/* Sleep for X milliseconds (Puts task into TASK_INTERRUPTIBLE) */
//void msleep(unsigned int msecs);

/* Busy-wait for microseconds (Does NOT sleep. Spoons the CPU. Use with caution!) */
// void udelay(unsigned long usecs);

int my_LFD420_task(void *pvParameters)
{
    struct sched_param param;
    param.sched_priority = 50;
    pr_info("[Lab6 Task] Started! My Name: %s, My PID: %d\n", current->comm, current->pid);
    if (current->real_parent) {
        pr_info("[Lab6 Task] My Parent is: %s (PID: %d)\n", 
                current->real_parent->comm, current->real_parent->pid);
    }

    /* Apply the SCHED_FIFO policy to this specific task */
    /*if (sched_setscheduler(current, SCHED_FIFO, &param) == 0) {
        pr_info("[Lab6 Task] Successfully elevated to SCHED_FIFO Priority 50!\n");
    } else {
        pr_err("[Lab6 Task] Failed to elevate priority.\n");
    } */
    sched_set_fifo(current);

    /* 1. Initialization and Local Variables */
    /* NOTE: These live on the task's tiny fixed-size Kernel Stack (usually 8KB or 16KB). 
       Never declare massive arrays here! Use kmalloc. */
    
    int exec_count = 0;
    pr_info("Kernel Task [%s] Started with PID: %d\n", current->comm, current->pid);

    while (!kthread_should_stop())
    {
        exec_count++;
        pr_info("[Lab6 Task] Executing cycle %d. Going to sleep...\n", exec_count);
        msleep(1000);

    }
    /* 5. Clean up and Exit */
    pr_info("[Lab6 Task] Received stop signal. Exiting gracefully after %d cycles.\n", exec_count);
    return 0; /* Returning destroys the task safely */

}


static int __init m_LFD420_l6_init(void)
{
    /* Self-Awareness: Log exactly how this was compiled */
#ifdef MODULE
    pr_info("[%s] Core initialized as a Loadable Module (M).\n", KBUILD_MODNAME);
#else
    pr_info("[%s] Core initialized directly into kernel boot (Y).\n", KBUILD_MODNAME);
#endif

    /* Initialize the debug subsystem if enabled */
    m_LFD420_debug_init();

    my_LFD420_task_handle = kthread_run(my_LFD420_task, NULL, "my_LFD420_task");
    if (IS_ERR(my_LFD420_task_handle))
    {
        pr_err(" my_LFD420_task creation failed.\n");
        return PTR_ERR(my_LFD420_task_handle);
    }
    


    return 0;
}

static void __exit m_LFD420_l6_exit(void)
{
    /* Safely cleanup debug allocations before exiting */
    m_LFD420_debug_cleanup();
    kthread_stop(my_LFD420_task_handle);

    pr_info("[%s] Core module unloaded safely.\n", KBUILD_MODNAME);
}

module_init(m_LFD420_l6_init);
module_exit(m_LFD420_l6_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("LFD420 Kernel Developer");
MODULE_DESCRIPTION("LFD420 Chapter 6: Task Management and RT Preemption Lab");
