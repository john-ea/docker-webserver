ifneq (,)
.error This Makefile requires GNU Make.
endif

# Ensure additional Makefiles are present
MAKEFILES = Makefile.docker Makefile.lint
$(MAKEFILES): URL=https://raw.githubusercontent.com/devilbox/makefiles/master/$(@)
$(MAKEFILES):
	@if ! (curl --fail -sS -o $(@) $(URL) || wget -O $(@) $(URL)); then \
		echo "Error, curl or wget required."; \
		echo "Exiting."; \
		false; \
	fi
include $(MAKEFILES)

# Set default Target
.DEFAULT_GOAL := help


# -------------------------------------------------------------------------------------------------
# Default configuration
# -------------------------------------------------------------------------------------------------
# Own vars
TAG        = latest

# Makefile.docker overwrites
DOCKER_USER       = johnea
# NAME    = no default
# VERSION = no default
SERVICE    = $(shell echo $(NAME) | tr '[:upper:]' '[:lower:]')
IMAGE      = $(DOCKER_USER)/webserver
FLAVOUR    = latest
DIR        = Dockerfiles
FILE       = Dockerfile-$(SERVICE)-$(VERSION).$(FLAVOUR)
ifeq ($(strip $(FLAVOUR)),latest)
	ifeq ($(strip $(TAG)),latest)
		DOCKER_TAG = $(SERVICE)-$(VERSION)
	else
		DOCKER_TAG = $(SERVICE)-$(VERSION)-$(TAG)
	endif
else
	ifeq ($(strip $(TAG)),latest)
		DOCKER_TAG = $(SERVICE)-$(VERSION)-$(FLAVOUR)
	else
		DOCKER_TAG = $(SERVICE)-$(VERSION)-$(FLAVOUR)-$(TAG)
	endif
endif
ARCH       = linux/amd64
EXAMPLE    = $(IMAGE):nginx-stable


# -------------------------------------------------------------------------------------------------
#  Default Target
# -------------------------------------------------------------------------------------------------
.PHONY: help
help:
	@echo "lint                                     Lint project files and repository"
	@echo
	@echo "build [ARCH=...] [TAG=...]               Build Docker image"
	@echo "rebuild [ARCH=...] [TAG=...]             Build Docker image without cache"
	@echo "push [ARCH=...] [TAG=...]                Push Docker image to Docker hub"
	@echo
	@echo "manifest-create [ARCHES=...] [TAG=...]   Create multi-arch manifest"
	@echo "manifest-push [TAG=...]                  Push multi-arch manifest"
	@echo
	@echo "test [ARCH=...]                          Test built Docker image"
	@echo


# -------------------------------------------------------------------------------------------------
#  Docker Targets
# -------------------------------------------------------------------------------------------------
.PHONY: build
build: ARGS=--build-arg ARCH=$(ARCH)
build: docker-arch-build

.PHONY: rebuild
rebuild: ARGS=--build-arg ARCH=$(ARCH)
rebuild: docker-arch-rebuild

.PHONY: push
push: docker-arch-push


# -------------------------------------------------------------------------------------------------
#  Manifest Targets
# -------------------------------------------------------------------------------------------------
.PHONY: manifest-create
manifest-create: docker-manifest-create

.PHONY: manifest-push
manifest-push: docker-manifest-push


# -------------------------------------------------------------------------------------------------
#  Test Targets
# -------------------------------------------------------------------------------------------------
.PHONY: test
test:
	./tests/start-ci.sh $(IMAGE) $(DOCKER_TAG) $(ARCH) $(DOCKER_USER)


# -------------------------------------------------------------------------------------------------
#  Internal Repository Targets
# -------------------------------------------------------------------------------------------------
.PHONY: _repo_fix
_repo_fix: __repo_fix_examples
_repo_fix: __repo_fix_doc
_repo_fix: __repo_fix_readme

###
### In case I've copied the examples/ from any repo, ensure to replace images with current
###
.PHONY: __repo_fix_examples
__repo_fix_examples:
	find examples/ -type f -print0 | xargs -0 -n1 sh -c \
		'if grep "nginx-stable" "$${1}">/dev/null; then sed -i"" "s|johnea/nginx-stable|$(EXAMPLE)|g" "$${1}";fi' --
	find examples/ -type f -print0 | xargs -0 -n1 sh -c \
		'if grep "nginx-mainline" "$${1}">/dev/null; then sed -i"" "s|johnea/nginx-mainline|$(EXAMPLE)|g" "$${1}";fi' --
	find examples/ -type f -print0 | xargs -0 -n1 sh -c \
		'if grep "apache-2.4" "$${1}">/dev/null; then sed -i"" "s|johnea/apache-2.4|$(EXAMPLE)|g" "$${1}";fi' --

###
### In case I've copied the doc/ from any repo, ensure to replace images with current
###
.PHONY: __repo_fix_doc
__repo_fix_doc:
	find doc/ -name '*.md' -type f -print0 | xargs -0 -n1 sh -c \
		'if grep "nginx-stable" "$${1}">/dev/null; then sed -i"" "s|johnea/nginx-stable|$(EXAMPLE)|g" "$${1}";fi' --
	find doc/ -name '*.md' -type f -print0 | xargs -0 -n1 sh -c \
		'if grep "nginx-mainline" "$${1}">/dev/null; then sed -i"" "s|johnea/nginx-mainline|$(EXAMPLE)|g" "$${1}";fi' --
	find doc/ -name '*.md' -type f -print0 | xargs -0 -n1 sh -c \
		'if grep "apache-2.4" "$${1}">/dev/null; then sed -i"" "s|johnea/apache-2.4|$(EXAMPLE)|g" "$${1}";fi' --

###
### In case I've copied the doc/ from any repo, ensure to replace images with current
###
.PHONY: __repo_fix_readme
__repo_fix_readme:
	sed -i'' "s/^# Nginx stable$$/# $(NAME) $(VERSION)/g"   README.md
	sed -i'' "s/^# Nginx mainline$$/# $(NAME) $(VERSION)/g" README.md
	sed -i'' "s/^# Apache 2.4$$/# $(NAME) $(VERSION)/g"     README.md
	@#
	sed -i'' "s|docker--nginx--stable|$$(   echo "docker/$(IMAGE)" | awk -F'/' '{print $$1"-"$$3}' | awk -F'-' '{print $$1"--"$$2"--"$$3}' )|g" README.md
	sed -i'' "s|docker--nginx--mainline|$$( echo "docker/$(IMAGE)" | awk -F'/' '{print $$1"-"$$3}' | awk -F'-' '{print $$1"--"$$2"--"$$3}' )|g" README.md
	sed -i'' "s|docker--apache--2.4|$$(     echo "docker/$(IMAGE)" | awk -F'/' '{print $$1"-"$$3}' | awk -F'-' '{print $$1"--"$$2"--"$$3}' )|g" README.md
	@#
	sed -i'' 's|johnea/nginx-stable|$(EXAMPLE)|g'   README.md
	sed -i'' 's|johnea/nginx-mainline|$(EXAMPLE)|g' README.md
	sed -i'' 's|johnea/apache-2.4|$(EXAMPLE)|g'     README.md
