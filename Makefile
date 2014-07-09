OSTYPE := $(shell echo $$OSTYPE)
ifeq (,$(findstring darwin,$(OSTYPE)))
  EMACS := emacs
  VC_GIT_PATH := -L /usr/share/doc/git-core/contrib/emacs -L ~/.emacs.d/
else
  EMACS := /Applications/Emacs.app/Contents/MacOS/Emacs
  VC_GIT_PATH := -L /usr/local/Cellar/git/1.8.3.1/share/git-core/contrib/emacs -L /Applications/Emacs.app/Contents/Resources/lisp/vc
endif

BATCH := $(EMACS) -batch -q -no-site-file -L site-lisp -L vendor/confluence-el
# -eval "(setq max-specpdl-size 2000 max-lisp-eval-depth 1000)"

ELC := $(BATCH) -f batch-byte-compile

SITE_ELFILES := $(filter-out site-lisp/readme-md-export.el site-lisp/my-loaddefs.el,$(wildcard site-lisp/*.el))
SITE_ELCFILES := $(SITE_ELFILES:%.el=%.elc)

ELFILES := init.el site-lisp/my-loaddefs.el $(SITE_ELFILES)
ELCFILES := init.elc $(SITE_ELCFILES)

ORG_VERSION := 8.2.4
ORG_PKGNAME := org-$(ORG_VERSION)
ORG_TARBALL := $(ORG_PKGNAME).tar.gz
ORG_DOWNLOAD_URL := http://orgmode.org/$(ORG_TARBALL)

ENSIME_VERSION := 0.9.8.9
ENSIME_SCALA_VERSION := 2.10.0
ENSIME_PKGNAME := ensime_$(ENSIME_SCALA_VERSION)-$(ENSIME_VERSION)
ENSIME_TARBALL := $(ENSIME_PKGNAME).tar.gz
ENSIME_DOWNLOAD_URL := https://www.dropbox.com/sh/ryd981hq08swyqr/ZiCwjjr_vm/ENSIME%20Releases/$(ENSIME_TARBALL)

ESS_VERSION := 12.09-2
ESS_PKGNAME := ess-$(ESS_VERSION)
ESS_TARBALL := $(ESS_PKGNAME).tgz
ESS_DOWNLOAD_URL := http://ess.r-project.org/downloads/ess/$(ESS_TARBALL)

YAS_DIR := $(firstword $(wildcard elpa/yasnippet-*))
YAS_SUBDIRS = $(wildcard snippets/*)
YAS_COMPILED = $(YAS_SUBDIRS:%=%/.yas-compiled-snippets.el)

CONFLUENCE_VERSION := 1.7
CONFLUENCE_PKGNAME := confluence-el
CONFLUENCE_TARBALL := $(CONFLUENCE_PKGNAME)-$(CONFLUENCE_VERSION).tar.gz
CONFLUENCE_DOWNLOAD_URL := "http://jaist.dl.sourceforge.net/project/confluence-el/$(CONFLUENCE_TARBALL)"

all: init.elc

ifneq (,$(wildcard vendor/$(ORG_PKGNAME)/lisp))
all: doc
endif

ifneq (,$(YAS_DIR))
all: $(YAS_COMPILED)
endif

.SUFFIXES: .el .elc

.el.elc:
	$(ELC) $<

init.elc: site-lisp/my-loaddefs.el $(SITE_ELCFILES)

site-lisp/my-loaddefs.el: $(SITE_ELFILES)
	$(BATCH) -eval "(setq generated-autoload-file (expand-file-name \"$@\"))" \
		 -f batch-update-autoloads site-lisp

init.el: README.org
	$(BATCH) -l ob-tangle -eval "(org-babel-tangle-file \"$<\" \"$@\")"

doc: README.md

README.md: README.org
	$(BATCH) -L vendor/$(ORG_PKGNAME)/lisp -l ox-md --file $< -l site-lisp/readme-md-export.el -f org-md-export-to-markdown

$(YAS_COMPILED):
	$(BATCH) -L $(YAS_DIR) -l yasnippet -eval "(let ((yas-snippet-dirs (list \"snippets\"))) (yas-recompile-all))"

snippets: snippets-clean $(YAS_COMPILED)

snippets-clean:
	rm -f $(YAS_COMPILED)

clean:
	rm -rf init.el site-lisp/my-loaddefs.el $(ELCFILES)

vendor-clean: org-clean git-emacs-clean emacs-rails-clean ensime-clean ess-clean confluence-clean distel-clean

vendor: org git-emacs emacs-rails ensime ess confluence distel

org: vendor/$(ORG_PKGNAME)/lisp/org-loaddefs.el

org-clean:
	rm -rf tmp/org-* vendor/org-*

vendor/$(ORG_PKGNAME)/lisp/org-loaddefs.el: vendor/$(ORG_PKGNAME)
	cd $< && $(MAKE) EMACS=$(EMACS) compile

vendor/$(ORG_PKGNAME): tmp/${ORG_TARBALL}
	tar -xzf $< -C vendor

tmp/${ORG_TARBALL}:
	curl -o $@ ${ORG_DOWNLOAD_URL}

ensime: vendor/$(ENSIME_PKGNAME)/bin/server

ensime-clean:
	rm -rf tmp/ensime-* vendor/ensime-*

vendor/$(ENSIME_PKGNAME)/bin/server: tmp/${ENSIME_TARBALL}
	tar -xzf $< -C vendor

tmp/${ENSIME_TARBALL}:
	curl -o $@ ${ENSIME_DOWNLOAD_URL}

ess: vendor/$(ESS_PKGNAME)/lisp/ess.elc

ess-clean:
	rm -rf tmp/ess-* vendor/ess-*

vendor/$(ESS_PKGNAME)/lisp/ess.elc: vendor/$(ESS_PKGNAME)
	cd $< && $(MAKE) EMACS=$(EMACS) all

vendor/$(ESS_PKGNAME): tmp/${ESS_TARBALL}
	tar -xzf $< -C vendor

tmp/${ESS_TARBALL}:
	curl -o $@ ${ESS_DOWNLOAD_URL}

git-emacs: vendor/git-emacs/git-emacs.elc

git-emacs-clean:
	rm -f vendor/git-emacs/*.elc

vendor/git-emacs/git-emacs.elc: vendor/git-emacs/git-emacs.el
	cd vendor/git-emacs && VC_GIT_PATH="$(VC_GIT_PATH)" EMACS=$(EMACS) $(MAKE)

distel: vendor/distel/ebin/distel.beam

distel-clean:
	rm -rf vendor/distel/elisp/*.elc vendor/distel/ebin

vendor/distel/ebin/distel.beam: vendor/distel/src/distel.erl
	which erlc &> /dev/null && cd vendor/distel && $(MAKE)

emacs-rails: vendor/emacs-rails/rails.elc

emacs-rails-clean:
	rm -f vendor/emacs-rails/*.elc

EMACS_RAILS_LIBS := -L vendor/emacs-rails -l cl -l vendor/emacs-rails/inflections.el -l vendor/emacs-rails/rails-lib.el -l vendor/emacs-rails/rails-refactoring.el -l vendor/emacs-rails/rails-project.el
EMACS_RAILS_IGNORE := vendor/emacs-rails/behave-rails.el

vendor/emacs-rails/rails.elc: vendor/emacs-rails/rails.el
	$(BATCH) $(EMACS_RAILS_LIBS) -f batch-byte-compile \
		$(filter-out $(EMACS_RAILS_IGNORE),$(wildcard vendor/emacs-rails/*.el))

vendor/git-emacs/git-emacs.el vendor/distel/src/distel.erl:
	git submodule init
	git submodule update

confluence: vendor/$(CONFLUENCE_PKGNAME)/confluence.elc

confluence-clean:
	rm -rf tmp/confluence-* vendor/confluence-*

vendor/$(CONFLUENCE_PKGNAME)/confluence.el: tmp/${CONFLUENCE_TARBALL}
	tar -xzf $< -C vendor

tmp/${CONFLUENCE_TARBALL}:
	curl -o $@ ${CONFLUENCE_DOWNLOAD_URL}

verify: init.elc
	$(EMACS) --debug-init -q -eval "(setq module-black-list '(server))" -l ./init.elc -f module-initialize

elpa: init.elc
	$(BATCH) -l ./init.elc -l dash -f module-initialize

site-lisp-update:
	curl -k -L -o site-lisp/alternative-files.el https://github.com/doitian/alternative-files-el/raw/master/alternative-files.el
	curl -k -L -o site-lisp/dash.el https://github.com/magnars/dash.el/raw/master/dash.el
	curl -k -L -o site-lisp/dtrt-indent.el http://git.savannah.gnu.org/gitweb/\?p\=dtrt-indent.git\;a\=blob_plain\;f\=dtrt-indent.el\;hb\=HEAD
	curl -k -L -o site-lisp/external-abook.el http://www.emacswiki.org/emacs/download/external-abook.el
	curl -k -L -o site-lisp/hide-comnt.el http://www.emacswiki.org/emacs-en/download/hide-comnt.el
	curl -k -L -o site-lisp/inf-ruby.el https://raw.github.com/nonsequitur/inf-ruby/master/inf-ruby.el
	curl -k -L -o site-lisp/notify.el http://www.emacswiki.org/emacs/download/notify.el
	curl -k -L -o site-lisp/moz.el http://download-mirror.savannah.gnu.org/releases/espresso/moz.el
	curl -k -L -o site-lisp/pick-backup.el https://raw.github.com/emacsmirror/pick-backup/master/pick-backup.el
	curl -k -L -o site-lisp/sequential-command.el http://www.emacswiki.org/emacs/download/sequential-command.el
	curl -k -L -o site-lisp/thing-actions.el https://github.com/doitian/thing-actions.el/raw/master/thing-actions.el
	curl -k -L -o "site-lisp/thingatpt+.el" http://www.emacswiki.org/emacs-en/download/thingatpt%2b.el
	curl -k -L -o site-lisp/thing-cmds.el http://www.emacswiki.org/emacs-en/download/thing-cmds.el
	curl -k -L -o site-lisp/winring.el https://launchpadlibrarian.net/43687812/winring.el
	curl -k -L -o site-lisp/windata.el http://www.emacswiki.org/emacs/download/windata.el
	curl -k -L -o site-lisp/orgbox.el https://raw.githubusercontent.com/yasuhito/orgbox/develop/orgbox.el
	$(MAKE)

update: site-lisp-update

.PHONY: all doc verify clean vendor vendor-clean org git-emacs distel emacs-rails
.PHONY: org-clean git-emacs-clean distel-clean emacs-rails-clean
.PHONY: snippets snippets-clean
.PHONY: elpa site-lisp-update update
.PHONY: ensime-clean ensime ess ess-clean
.PHONY: confluence-clean confluence
