# An include file for Makefiles. It provides rules for building
# a static libpblog.a based on protobuf and nanopb.

# Path to the pblog root directory
PBLOG_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))../)
PBLOG_OUT := $(CURDIR)/.pblog

# Build Options
PBLOG_BUILD_STATIC ?= y
PBLOG_BUILD_SHARED ?= n

PBLOG_BUILD_MODULE_FILE ?= y

# Parameters
PBLOG_LIBRARIES =
PBLOG_STATIC = $(PBLOG_OUT)/libpblog.a
ifeq ($(BUILD_STATIC),y)
PBLOG_LIBRARIES += $(PBLOG_STATIC)
endif
PBLOG_SHARED = $(PBLOG_OUT)/libpblog.so
ifeq ($(BUILD_SHARED),y)
PBLOG_LIBRARIES += $(PBLOG_SHARED)
endif

# Command substitution
PBLOG_CC = $(or $(CC),cc)
PBLOG_MKDIR = $(or $(MKDIR),mkdir)
PBLOG_CP = $(or $(CP),cp)
PBLOG_AR = $(or $(AR),ar)
PBLOG_PROTOC = $(or $(PROTOC),protoc)

# We need certain CPP / C flags for correctness of struct generation
ifdef NANOPB_SRC_DIR
CPPFLAGS += -DPB_FIELD_32BIT=1
CFLAGS += -DPB_FIELD_32BIT=1
endif

PBLOG_CFLAGS = $(CPPFLAGS) $(CFLAGS) -Wall $(if $(NANOPB_SRC_DIR),-DPB_FIELD_32BIT=1,)
ifeq ($(PBLOG_BUILD_SHARED),y)
PBLOG_CFLAGS += -fPIC
endif

PBLOG_PROTOC_ARGS = --plugin=$(if $(NANOPB_SRC_DIR),protoc-gen-nanopb=$(NANOPB_SRC_DIR)/generator/protoc-gen-nanopb,nanopb)
ifdef NANOPB_SRC_DIR
PBLOG_PROTOC_ARGS += -I$(NANOPB_SRC_DIR)/generator
else
PBLOG_PROTOC_ARGS += -I$(NANOPB_INC_DIR)
endif
PBLOG_PROTOC_ARGS += -I$(or $(shell pkg-config --silence-errors --variable=includedir protobuf),/usr/include)

HEADER_FILTER =
SOURCE_FILTER =
ifeq ($(PBLOG_BUILD_MODULE_FILE),n)
HEADER_FILTER += %/file.h
SOURCE_FILTER += %/file.c
endif

PBLOG_SRC_INCLUDE = $(PBLOG_DIR)/include
PBLOG_SRC_HEADERS = $(filter-out $(HEADER_FILTER),$(wildcard $(PBLOG_SRC_INCLUDE)/pblog/*.h))
PBLOG_SRC_PROTOS = $(wildcard $(PBLOG_DIR)/proto/*.proto)
PBLOG_SRC_FILES = $(filter-out $(SOURCE_FILTER),$(wildcard $(PBLOG_DIR)/src/*.c))

PBLOG_INCLUDE = $(PBLOG_OUT)/include
PBLOG_ONLY_HEADERS = $(patsubst $(PBLOG_SRC_INCLUDE)/%,$(PBLOG_INCLUDE)/%,$(PBLOG_SRC_HEADERS))
PBLOG_PROTO_HEADERS = $(patsubst $(PBLOG_DIR)/proto/%.proto,$(PBLOG_INCLUDE)/pblog/%.pb.h,$(PBLOG_SRC_PROTOS))
PBLOG_HEADERS = $(PBLOG_ONLY_HEADERS) $(PBLOG_PROTO_HEADERS)
PBLOG_ONLY_OBJECTS = $(patsubst $(PBLOG_DIR)/src/%.c,$(PBLOG_OUT)/pblog/%.o,$(PBLOG_SRC_FILES))
PBLOG_PROTO_OBJECTS = $(patsubst $(PBLOG_DIR)/proto/%.proto,$(PBLOG_OUT)/pblog/%.pb.o,$(PBLOG_SRC_PROTOS))
PBLOG_OBJECTS = $(PBLOG_ONLY_OBJECTS) $(PBLOG_PROTO_OBJECTS)

ifdef NANOPB_SRC_DIR
PBLOG_NANOPB_HEADERS = $(patsubst $(NANOPB_SRC_DIR)/%.h,$(PBLOG_INCLUDE)/nanopb/%.h,$(wildcard $(NANOPB_SRC_DIR)/*.h)) \
                       $(PBLOG_INCLUDE)/nanopb/config.h
PBLOG_NANOPB_OBJECTS = $(patsubst $(NANOPB_SRC_DIR)/%.c,$(PBLOG_OUT)/nanopb/%.o,$(wildcard $(NANOPB_SRC_DIR)/*.c))
PBLOG_HEADERS += $(PBLOG_NANOPB_HEADERS)
PBLOG_OBJECTS += $(PBLOG_NANOPB_OBJECTS)
else
PBLOG_CFLAGS += -I$(NANOPB_INC_DIR)
PBLOG_OBJECTS += $(NANOPB_LIB_DIR)/libprotobuf-nanopb.a
endif

PBLOG_SECONDARY: $(PBLOG_HEADERS)
PBLOG_PHONY: pblog_clean

.SECONDARY: $(PBLOG_SECONDARY)
.PHONY: $(PBLOG_PHONY) pblog_nanopb_protos

ifdef NANOPB_SRC_DIR
# Nanopb protos
pblog_nanopb_protos:
	make -C $(NANOPB_SRC_DIR)/generator/nanopb

# Nanopb headers
$(NANOPB_SRC_DIR)/config.h: $(NANOPB_SRC_DIR)/config.h.template
	$(PBLOG_CP) -p $< $@

$(PBLOG_INCLUDE)/nanopb/%.h: $(NANOPB_SRC_DIR)/%.h
	@$(PBLOG_MKDIR) -p $(PBLOG_INCLUDE)/nanopb
	$(PBLOG_CP) -p $< $@
else
pblog_nanopb_protos:
endif

# Pblog headers
$(PBLOG_INCLUDE)/pblog/%.h: $(PBLOG_SRC_INCLUDE)/pblog/%.h
	@$(PBLOG_MKDIR) -p $(PBLOG_INCLUDE)/pblog
	$(PBLOG_CP) $< $@

# Protobuf code generation
$(PBLOG_OUT)/pblog/%.pb.c $(PBLOG_OUT)/pblog/%.pb.h: $(PBLOG_DIR)/proto/%.proto pblog_nanopb_protos
	@$(PBLOG_MKDIR) -p $(PBLOG_OUT)/pblog
	$(PBLOG_PROTOC) $(PBLOG_PROTOC_ARGS) -I$(PBLOG_DIR)/proto \
		--nanopb_out="$(PBLOG_OUT)/pblog" \
		$<

# Pblog proto headers
$(PBLOG_INCLUDE)/pblog/%.pb.h: $(PBLOG_OUT)/pblog/%.pb.h
	$(PBLOG_CP) $< $@

# Pblog proto sources
$(PBLOG_OUT)/pblog/%.pb.o: $(PBLOG_OUT)/pblog/%.pb.c $(PBLOG_PROTO_HEADERS) $(PBLOG_NANOPB_HEADERS)
	@$(PBLOG_MKDIR) -p $(PBLOG_OUT)/pblog
	$(PBLOG_CC) $(PBLOG_CFLAGS) -I$(PBLOG_INCLUDE) -I$(PBLOG_INCLUDE)/pblog -c $< -o $@

ifdef NANOPB_SRC_DIR
# Nanopb sources
$(PBLOG_OUT)/nanopb/%.o: $(NANOPB_SRC_DIR)/%.c $(PBLOG_NANOPB_HEADERS)
	@$(PBLOG_MKDIR) -p $(PBLOG_OUT)/nanopb
	$(PBLOG_CC) $(PBLOG_CFLAGS) -c $< -o $@
endif

# Pblog sources
$(PBLOG_OUT)/pblog/%.o: $(PBLOG_DIR)/src/%.c $(PBLOG_HEADERS)
	@$(PBLOG_MKDIR) -p $(PBLOG_OUT)/pblog
	$(PBLOG_CC) $(PBLOG_CFLAGS) -I$(PBLOG_INCLUDE) -c $< -o $@

# Libraries
$(PBLOG_OUT)/libpblog.a: $(PBLOG_OBJECTS)
	@$(PBLOG_MKDIR) -p $(PBLOG_OUT)
	$(PBLOG_AR) rcs $(PBLOG_OUT)/libpblog.a $(PBLOG_OBJECTS)

$(PBLOG_OUT)/libpblog.so: $(PBLOG_OBJECTS)
	@$(PBLOG_MKDIR) -p $(PBLOG_OUT)
	$(PBLOG_CC) -shared -Wl,-soname,libpblog.so $(PBLOG_OBJECTS) -o $(PBLOG_OUT)/libpblog.so

pblog_clean:
	rm -rf $(PBLOG_OUT)
