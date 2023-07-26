/*
 * This file is just an altered version of ec_sys.c in the Linux kernel.
 * I just modified it to make it work as an out-of-tree module and
 * to not use debugfs.
 *
 * Original copyright:
 * Copyright (C) 2010 SUSE Products GmbH/Novell
 * Author:
 *      Thomas Renninger <trenn@suse.de>
 */

// TODO: Add support for more than one EC controller.
#include <linux/acpi.h>
#include <linux/cdev.h>
#include <linux/device.h>
#include <linux/fs.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/uaccess.h>
#include <linux/version.h>

MODULE_AUTHOR("Thomas Renninger <trenn@suse.de>");
MODULE_DESCRIPTION("ACPI EC access driver");
MODULE_LICENSE("GPL");

#define EC_SPACE_SIZE 256

extern int ec_read(u8 addr, u8 *val);
extern int ec_write(u8 addr, u8 val);
extern struct acpi_ec *first_ec;

static dev_t first_dev;
static struct cdev c_dev;
static struct class *dev_class;

static ssize_t acpi_ec_read(struct file *f, char __user *buf, size_t count,
                            loff_t *off) {
  unsigned int size = EC_SPACE_SIZE;
  loff_t init_off = *off;
  int err = 0;

  if (*off >= size)
    return 0;

  if (*off + count >= size) {
    size -= *off;
    count = size;
  } else
    size = count;

  while (size) {
    u8 byte_read;
    err = ec_read(*off, &byte_read);
    if (err)
      return err;

    if (put_user(byte_read, buf + *off - init_off)) {
      if (*off - init_off)
        return *off - init_off; /* partial read */
      return -EFAULT;
    }

    *off += 1;
    size--;
  }
  return count;
}

static ssize_t acpi_ec_write(struct file *f, const char __user *buf,
                             size_t count, loff_t *off) {
  unsigned int size = count;
  loff_t init_off = *off;
  int err = 0;

  if (*off >= EC_SPACE_SIZE)
    return 0;

  if (*off + count >= EC_SPACE_SIZE) {
    size = EC_SPACE_SIZE - *off;
    count = size;
  }

  while (size) {
    u8 byte_write;
    if (get_user(byte_write, buf + *off - init_off)) {
      if (*off - init_off)
        return *off - init_off; /* partial write */
      return -EFAULT;
    }
    err = ec_write(*off, byte_write);
    if (err)
      return err;

    *off += 1;
    size--;
  }
  return count;
}

static const struct file_operations fops = {
    .owner = THIS_MODULE,
    .open = simple_open,
    .read = acpi_ec_read,
    .write = acpi_ec_write,
    .llseek = default_llseek,
};

static int acpi_ec_create_dev(void) {
  int err = -1;

  if ((err = alloc_chrdev_region(&first_dev, 0, 1, "ec")) < 0) {
    printk(KERN_ERR "acpi_ec: Failed to allocate a char_dev region\n");
    return err;
  }

#if LINUX_VERSION_CODE < KERNEL_VERSION(6, 4, 0)
  if (IS_ERR(dev_class = class_create(THIS_MODULE, "chardev")))
#else
  if (IS_ERR(dev_class = class_create("chardev")))
#endif
  {
    printk(KERN_ERR "acpi_ec: Failed to create a class\n");
    err = -1;
    goto error;
  }

  if (IS_ERR(device_create(dev_class, NULL, first_dev, NULL, "ec"))) {
    printk(KERN_ERR "acpi_ec: Failed to create a device\n");
    err = -1;
    class_destroy(dev_class);
    goto error;
  }

  cdev_init(&c_dev, &fops);

  if ((err = cdev_add(&c_dev, first_dev, 1)) < 0) {
    printk(KERN_ERR "acpi_ec: Failed to add a device\n");
    device_destroy(dev_class, first_dev);
    class_destroy(dev_class);
    goto error;
  }

  return 0;

error:
  unregister_chrdev_region(first_dev, 1);
  return err;
}

static int __init acpi_ec_init(void) {
  if (first_ec)
    return acpi_ec_create_dev();
  else
    return -1;
}

static void __exit acpi_ec_exit(void) {
  cdev_del(&c_dev);
  device_destroy(dev_class, first_dev);
  class_destroy(dev_class);
  unregister_chrdev_region(first_dev, 1);
}

module_init(acpi_ec_init);
module_exit(acpi_ec_exit);
