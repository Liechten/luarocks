
include config.unix

.PHONY: all build dev build_bins luadoc check_makefile cleanup_bins clean \
 install_site_config write_sysconfig install bootstrap install_rock \
 run_luarocks

ROCKS_TREE ?= $(PREFIX)
SYSCONFDIR ?= $(PREFIX)/etc/luarocks
LUA_DIR ?= /usr/local
LUA_BINDIR ?= $(LUA_DIR)/bin

CONFIG_FILE = $(SYSCONFDIR)/config-$(LUA_VERSION).lua

SAFEPWD=`echo "$$PWD" | sed -e 's/\([][]\)\1/]]..'\''\1\1'\''..[[/g'`

all: 
	@echo "- Type 'make build' and 'make install':"
	@echo "  to install to $(PREFIX) as usual."
	@echo "- Type 'make bootstrap':"
	@echo "  to install LuaRocks in $(PREFIX) as a rock."
	@echo

include Makefile.setup.inc
include Makefile.install.inc

build: $(SITE_CONFIG) build_bins
	@echo
	@echo "Done. Type 'make install' to install into $(PREFIX)."
	@echo

$(SITE_CONFIG): config.unix
	rm -f $(SITE_CONFIG)
	echo 'local site_config = {}' >> $(SITE_CONFIG)
	if [ -n "$(PREFIX)" ] ;\
	then \
	   echo "site_config.LUAROCKS_PREFIX=[[$(PREFIX)]]" >> $(SITE_CONFIG) ;\
	fi
	if [ -n "$(LUA_INCDIR)" ] ;\
	then \
	   echo "site_config.LUA_INCDIR=[[$(LUA_INCDIR)]]" >> $(SITE_CONFIG) ;\
	fi
	if [ -n "$(LUA_LIBDIR)" ] ;\
	then \
	   echo "site_config.LUA_LIBDIR=[[$(LUA_LIBDIR)]]" >> $(SITE_CONFIG) ;\
	fi
	if [ -n "$(LUA_BINDIR)" ] ;\
	then \
	   echo "site_config.LUA_BINDIR=[[$(LUA_BINDIR)]]" >> $(SITE_CONFIG) ;\
	fi
	if [ -n "$(LUA_SUFFIX)" ] ;\
	then \
	   echo "site_config.LUA_INTERPRETER=[[lua$(LUA_SUFFIX)]]" >> $(SITE_CONFIG) ;\
	fi
	if [ -n "$(SYSCONFDIR)" ] ;\
	then \
	   echo "site_config.LUAROCKS_SYSCONFDIR=[[$(SYSCONFDIR)]]" >> $(SITE_CONFIG) ;\
	fi
	if [ -n "$(ROCKS_TREE)" ] ;\
	then \
	   echo "site_config.LUAROCKS_ROCKS_TREE=[[$(ROCKS_TREE)]]" >> $(SITE_CONFIG) ;\
	fi
	if [ -n "$(FORCE_CONFIG)" ] ;\
	then \
	   echo "site_config.LUAROCKS_FORCE_CONFIG=true" >> $(SITE_CONFIG) ;\
	fi
	if [ "$(LUA_DIR_SET)" = "yes" ] ;\
	then \
	   echo "site_config.LUA_DIR_SET=true" >> $(SITE_CONFIG) ;\
	fi
	echo "site_config.LUAROCKS_UNAME_S=[[$(LUAROCKS_UNAME_S)]]" >> $(SITE_CONFIG)
	echo "site_config.LUAROCKS_UNAME_M=[[$(LUAROCKS_UNAME_M)]]" >> $(SITE_CONFIG)
	echo "site_config.LUAROCKS_DOWNLOADER=[[$(LUAROCKS_DOWNLOADER)]]" >> $(SITE_CONFIG)
	echo "site_config.LUAROCKS_MD5CHECKER=[[$(LUAROCKS_MD5CHECKER)]]" >> $(SITE_CONFIG)
	if [ -n "$(MULTIARCH_SUBDIR)" ] ;\
	then \
	   echo 'site_config.LUAROCKS_EXTERNAL_DEPS_SUBDIRS={ bin="bin", lib={ "lib", [[$(MULTIARCH_SUBDIR)]] }, include="include" }' >> $(SITE_CONFIG) ;\
	   echo 'site_config.LUAROCKS_RUNTIME_EXTERNAL_DEPS_SUBDIRS={ bin="bin", lib={ "lib", [[$(MULTIARCH_SUBDIR)]] }, include="include" }' >> $(SITE_CONFIG) ;\
	fi
	echo "return site_config" >> $(SITE_CONFIG)

dev:
	$(MAKE) build_bins LUADIR=$(PWD)/src

build_bins: cleanup_bins
	for f in $(BIN_FILES) ;\
	do \
	   sed "1d" src/bin/$$f > src/bin/$$f.bak ;\
	   echo "#!$(LUA_BINDIR)/lua$(LUA_SUFFIX)" > src/bin/$$f ;\
	   echo "package.path = [[$(LUADIR)/?.lua;]]..package.path" | sed "s,//,/,g" >> src/bin/$$f ;\
	   cat src/bin/$$f.bak >> src/bin/$$f ;\
	   chmod +rx src/bin/$$f ;\
	   rm -f src/bin/$$f.bak ;\
	done

luadoc:
	rm -rf doc/luadoc
	mkdir -p doc/luadoc
	cd src && luadoc -d ../doc/luadoc --nofiles luarocks/*.lua

check_makefile: clean
	echo $(BIN_FILES) | tr " " "\n" | sort > makefile_list.txt
	( cd src/bin && ls -d * ) | sort > luarocks_dir.txt
	echo $(LUAROCKS_FILES) | tr " " "\n" | sort >> makefile_list.txt
	( cd src/luarocks && find * -name "*.lua" ) | sort >> luarocks_dir.txt
	diff makefile_list.txt luarocks_dir.txt
	rm -f makefile_list.txt luarocks_dir.txt
	@echo
	@echo "Makefile is sane."
	@echo

cleanup_bins:
	for f in $(BIN_FILES) ;\
	do \
	   mv src/bin/$$f src/bin/$$f.bak ;\
	   sed "s,^#!.*lua.*,#!/usr/bin/env lua,;/^package.path/d" < src/bin/$$f.bak > src/bin/$$f ;\
	   chmod +rx src/bin/$$f ;\
	   rm -f src/bin/$$f.bak ;\
	done

clean: cleanup_bins
	rm -f $(SITE_CONFIG)

run_luarocks:
	'$(LUA_BINDIR)/lua$(LUA_SUFFIX)' -e "package.path=[[$(SAFEPWD)/src/?.lua;]]..package.path" src/bin/luarocks make rockspec --tree="$(PREFIX)"

install_site_config: $(SITE_CONFIG)
	mkdir -p "$(DESTDIR)$(LUADIR)/luarocks/core"
	cp $(SITE_CONFIG) "$(DESTDIR)$(LUADIR)/luarocks/core"

write_sysconfig:
	mkdir -p "$(DESTDIR)$(ROCKS_TREE)"
	if [ ! -f "$(DESTDIR)$(CONFIG_FILE)" ] ;\
	then \
	   mkdir -p `dirname "$(DESTDIR)$(CONFIG_FILE)"` ;\
	   echo 'rocks_trees = {' >> "$(DESTDIR)$(CONFIG_FILE)" ;\
	   if  [ ! -n "$(FORCE_CONFIG)" ] ;\
	   then \
	      echo '   { name = [[user]], root = home..[[/.luarocks]] },' >> "$(DESTDIR)$(CONFIG_FILE)" ;\
	   fi ;\
	   echo '   { name = [[system]], root = [[$(ROCKS_TREE)]] }' >> "$(DESTDIR)$(CONFIG_FILE)" ;\
	   echo '}' >> "$(DESTDIR)$(CONFIG_FILE)" ;\
	fi

install: build install_bins install_luas install_site_config write_sysconfig

bootstrap: $(SITE_CONFIG) run_luarocks install_site_config write_sysconfig cleanup_bins

install_rock: install_bins install_luas

