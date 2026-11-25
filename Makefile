# Coldline Backup Service
# GNU-style install: PREFIX, DESTDIR, sysconfdir, etc. are overridable.
PREFIX      ?= /usr/local
BINDIR      ?= $(PREFIX)/bin
LIBDIR      ?= $(PREFIX)/lib/coldline
MANDIR      ?= $(PREFIX)/share/man
SYSCONFDIR  ?= /etc
DESTDIR     ?=
VERSION     := $(shell cat VERSION)

SHELL_SRCS  := bin/coldline $(wildcard lib/coldline/*.sh)
INSTALL     ?= install

.PHONY: all install uninstall lint fmt test check clean

all:
	@echo "Nothing to build. Try: make test | sudo make install [PREFIX=/usr]"

install:
	$(INSTALL) -d $(DESTDIR)$(BINDIR) $(DESTDIR)$(LIBDIR) $(DESTDIR)$(MANDIR)/man1 $(DESTDIR)$(SYSCONFDIR)/coldline/conf.d
	sed -e 's|@LIBDIR@|$(LIBDIR)|g' -e 's|@VERSION@|$(VERSION)|g' bin/coldline > $(DESTDIR)$(BINDIR)/coldline
	chmod 0755 $(DESTDIR)$(BINDIR)/coldline
	$(INSTALL) -m 0644 lib/coldline/*.sh $(DESTDIR)$(LIBDIR)/
	sed -e 's|@VERSION@|$(VERSION)|g' man/coldline.1 > $(DESTDIR)$(MANDIR)/man1/coldline.1
	chmod 0644 $(DESTDIR)$(MANDIR)/man1/coldline.1
	$(INSTALL) -m 0644 etc/coldline.example.yaml $(DESTDIR)$(SYSCONFDIR)/coldline/coldline.yaml.example

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/coldline $(DESTDIR)$(MANDIR)/man1/coldline.1
	rm -rf $(DESTDIR)$(LIBDIR)
	rm -f $(DESTDIR)$(SYSCONFDIR)/coldline/coldline.yaml.example
	@echo "Left $(SYSCONFDIR)/coldline config and /var/lib/coldline state in place."

lint:
	shellcheck -x $(SHELL_SRCS)
	shfmt -i 2 -ci -bn -d $(SHELL_SRCS)

fmt:
	shfmt -i 2 -ci -bn -w $(SHELL_SRCS)

test:
	bats tests

check: lint test

clean:
	rm -rf pkgroot
