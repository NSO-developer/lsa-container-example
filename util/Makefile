SUBDIRS := $(wildcard */src/.)

all: $(SUBDIRS)
$(SUBDIRS):
	$(MAKE) clean all -C $@ 

.PHONY: all $(SUBDIRS)
