SHELL := /bin/bash
DEPS ?= build
COVERAGE ?= .tmp
ROCKS_PACKAGE_VERSION := $(shell ./.rocks-version ver)
ROCKS_PACKAGE_REVISION := $(shell ./.rocks-version rev)

LUA_VERSION ?= luajit 2.1.0-beta3
NVIM_BIN ?= nvim
NVIM_LUA_VERSION := $(shell $(NVIM_BIN) -v 2>/dev/null | grep -E '^Lua(JIT)?' | tr A-Z a-z)
ifdef NVIM_LUA_VERSION
LUA_VERSION ?= $(NVIM_LUA_VERSION)
endif
LUA_NUMBER := $(word 2,$(LUA_VERSION))

TARGET_DIR := $(DEPS)/$(LUA_NUMBER)

HEREROCKS ?= $(DEPS)/hererocks.py
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
HEREROCKS_ENV ?= MACOSX_DEPLOYMENT_TARGET=10.15
endif
HEREROCKS_URL ?= https://raw.githubusercontent.com/luarocks/hererocks/master/hererocks.py
HEREROCKS_ACTIVE := source $(TARGET_DIR)/bin/activate

LUAROCKS ?= $(TARGET_DIR)/bin/luarocks
NLUA ?= $(TARGET_DIR)/bin/nlua

BUSTED ?= $(TARGET_DIR)/bin/busted
BUSTED_HELPER ?= $(PWD)/spec/busted_helper.lua
COVERAGE_HELPER ?= $(PWD)/spec/busted_helper.lua

LUAROCKS_DEPS ?= $(TARGET_DIR)/.deps_installed
BUSTED_HTEST ?= $(TARGET_DIR)/lib/luarocks/rocks-5.1/busted-htest

LUV ?= $(TARGET_DIR)/lib/lua/$(LUA_NUMBER)/luv.so

LUA_LS ?= $(DEPS)/lua-language-server
LINT_LEVEL ?= Information

BUSTED_TAG ?= unit

ifndef BUSTED_TAG
override BUSTED_TAG = unit
endif

.EXPORT_ALL_VARIABLES:

all: deps

deps: | $(HEREROCKS) $(BUSTED) $(LUAROCKS_DEPS)

luarocks_deps: $(LUAROCKS_DEPS)

test: test_lua test_nvim

test_lua: $(BUSTED) $(LUAROCKS_DEPS) $(LUV)
	@echo Test with $(LUA_VERSION) tag=$(BUSTED_TAG) ......
	@$(HEREROCKS_ACTIVE) && eval $$(luarocks path) && \
		lua spec/init.lua --coverage --helper=$(BUSTED_HELPER) --run=$(BUSTED_TAG) -o htest spec/tests

coverage_clean:
	rm -fr $(COVERAGE)
	mkdir $(COVERAGE)

coverage: coverage_clean
	@echo coverage with $(LUA_VERSION) tag=$(BUSTED_TAG) ......
	@$(HEREROCKS_ACTIVE) && eval $$(luarocks path) && \
		busted --coverage --lua=$(TARGET_DIR)/bin/lua --helper=$(BUSTED_HELPER) --run=$(BUSTED_TAG) spec/tests/reload_spec.lua


test_nvim: $(BUSTED) $(LUV) $(NLUA)
	@echo Test with $(LUA_VERSION) ......
	@$(HEREROCKS_ACTIVE) && eval $$(luarocks path) && \
	busted --lua="$(NLUA)" --helper=spec/init.lua --run=$(BUSTED_TAG) -o htest spec/tests
	# busted --lua=$(NLUA) --helper=spec/init.lua -o htest $(BUSTED_ARGS) spec/unit 


new-rocks-version: 
	./.new-rocks-version

rocks-version: 
	$(info $(ROCKS_PACKAGE_VERSION)-$(ROCKS_PACKAGE_REVISION))

$(HEREROCKS):
	mkdir -p $(DEPS)
	curl $(HEREROCKS_URL) -o $@

$(LUAROCKS): $(HEREROCKS)
	$(HEREROCKS_ENV) python3 $< $(TARGET_DIR) --$(LUA_VERSION) -r latest

$(BUSTED): $(LUAROCKS)
	$(HEREROCKS_ACTIVE) && eval $$(luarocks path) && \
	luarocks install busted

$(BUSTED_HTEST): $(LUAROCKS)
	$(HEREROCKS_ACTIVE) && eval $$(luarocks path) && \
	luarocks install busted-htest

$(NLUA): $(LUAROCKS)
	$(HEREROCKS_ACTIVE) && eval $$(luarocks path) && \
	luarocks install nlua

$(LUAROCKS_DEPS): $(LUAROCKS) $(BUSTED_HTEST) $(NLUA)
	@echo build for $(LUA_VERSION) $(ROCKS_PACKAGE_VERSION)-$(ROCKS_PACKAGE_REVISION) ......
	@$(HEREROCKS_ACTIVE) && eval $$(luarocks path) && \
	luarocks make lua-nvl-utils-$(ROCKS_PACKAGE_VERSION)-$(ROCKS_PACKAGE_REVISION).rockspec && \
	luarocks test --prepare lua-nvl-utils-$(ROCKS_PACKAGE_VERSION)-$(ROCKS_PACKAGE_REVISION).rockspec && \
	touch $(TARGET_DIR)/.deps_installed


$(LUV): $(LUAROCKS)
	@$(HEREROCKS_ACTIVE) && [[ ! $$(luarocks which luv) ]] && \
		luarocks install luv || true
#
# lint:
# 	@rm -rf $(LUA_LS)
# 	@mkdir -p $(LUA_LS)
# 	@lua-language-server --check $(PWD) --checklevel=$(LINT_LEVEL) --logpath=$(LUA_LS)
# 	@grep -q '^\[\]\s*$$' $(LUA_LS)/check.json || (cat $(LUA_LS)/check.json && exit 1)
#
clean:
	rm -rf $(DEPS)

.PHONY: all deps clean lint test test_nvim test_lua rocks-version new-rocks-version
#

