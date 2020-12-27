# This Makefile can be used to manually build the kernel module.

TARGET=acpi_ec.ko.xz
MODULES_DIR=/lib/modules/$(shell uname -r)
SRC_DIR=/usr/src/kernels/$(shell uname -r)
FILE_PATH=$(MODULES_DIR)/kernel/drivers/acpi/$(TARGET)
obj-m += src/$(basename $(basename $(TARGET))).o

PRIVATE_KEY_PATH=
PUBLIC_KEY_PATH=

all: build

build:
	@make -C $(MODULES_DIR)/build M=$(PWD) modules
clean:
	@make -C $(MODULES_DIR)/build M=$(PWD) clean

install: compress
	@sudo mv $(TARGET) $(FILE_PATH)
	@sudo depmod
	@sudo modprobe acpi_ec

.PHONY: uninstall

uninstall:
ifneq ("$(wildcard $(FILE_PATH))","")
	@sudo modprobe -r acpi_ec
	@sudo depmod
	@sudo rm $(FILE_PATH)
endif

# Use XZ as default format
compress: sign
	@xz -f $(basename $(TARGET))

# Secure Boot specific
sign: build
ifneq ("$(PRIVATE_KEY_PATH)","")
	@$(SRC_DIR)/scripts/sign-file \
	sha256 \
	$(PRIVATE_KEY_PATH) \
	$(PUBLIC_KEY_PATH) \
	$(basename $(TARGET))
endif
