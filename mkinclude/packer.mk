PACKER_VERSION := 1.8.6
OS ?= $(shell uname|tr A-Z a-z)

uname_m = $(shell uname -m|tr A-Z a-z)

ifeq ($(uname_m),arm64)
	ARCH = "arm64"
else ifeq ($(uname_m),aarch64)
	ARCH = "arm64
else	
	ARCH = amd64
endif


# Path to Terraform binary.
PACKER ?= tmp/packer.bin

# Packer plugin installs query api.github.com. Actions should set
# PACKER_GITHUB_API_TOKEN; fall back to GITHUB_TOKEN when unset.
export PACKER_GITHUB_API_TOKEN ?= $(GITHUB_TOKEN)

PACKER_INIT_RETRIES ?= 6
PACKER_INIT_RETRY_SLEEP ?= 120

packer.initialized: $(PACKER) vsphere.pkr.hcl
	@if [ -z "$$PACKER_GITHUB_API_TOKEN" ]; then \
		echo "warning: PACKER_GITHUB_API_TOKEN/GITHUB_TOKEN unset; unauthenticated GitHub API rate limits are likely"; \
	fi
	@n=0; \
	until $(PACKER) init vsphere.pkr.hcl >packer.log 2>&1; do \
		cat packer.log; \
		n=$$((n+1)); \
		if [ $$n -ge $(PACKER_INIT_RETRIES) ]; then \
			echo "packer init failed after $$n attempts"; \
			exit 1; \
		fi; \
		echo "packer init failed (attempt $$n/$(PACKER_INIT_RETRIES)); sleeping $(PACKER_INIT_RETRY_SLEEP)s for GitHub rate limit..."; \
		sleep $(PACKER_INIT_RETRY_SLEEP); \
	done
	@cat packer.log
	mv packer.log $@

tmp/packer_$(PACKER_VERSION)_$(OS)_$(ARCH).zip:
	wget -nv https://releases.hashicorp.com/packer/$(PACKER_VERSION)/packer_$(PACKER_VERSION)_$(OS)_$(ARCH).zip -O $@

$(PACKER): tmp/packer_$(PACKER_VERSION)_$(OS)_$(ARCH).zip
	unzip -n $< -d tmp/;
	chmod +x tmp/packer;
	cp tmp/packer $@;
