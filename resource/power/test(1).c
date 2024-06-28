#include<linux/init.h>
#include<linux/module.h>

static int hello_init(void)
{
	printk("chenzimo");
	return 0;
}
static void hello_exit(void) {
	printk("chenzimo out");
	return;
}
module_init(hello_init);
module_exit(hello_exit);