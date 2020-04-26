#include <stdio.h>
#include <stdlib.h>
#include <linux/types.h>
#include <linux/stat.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <stdint.h>

int main()
{
    int fd = open("/dev/ec", O_RDWR);
    int err;

    if (fd < 0)
    {
        printf("An error occured while opening /dev/ec: %s\n", strerror(errno));
        return fd;
    }

    for (int i = 0; i < 254; i++)
    {
        uint8_t read_buf;
        if ((err = pread(fd, &read_buf, 1, i)) < 0)
        {
            printf("An error occured during read: %s\n", strerror(errno));
            return err;
        }
        printf("read value %d at %2x\n", read_buf, i);
    }

    return 0;
}