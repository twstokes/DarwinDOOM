SHELL := /bin/bash

# Usage examples:
#   make release-macos VERSION=0.1.0 IDENTITY="Developer ID Application: Tanner Stokes (AE76EV48ND)" DRY_RUN=true
#   make release-macos VERSION=0.1.0 IDENTITY="Developer ID Application: Tanner Stokes (AE76EV48ND)" NOTARIZE=true NOTARY_PROFILE=DarwinDOOM-notary

VERSION ?=
IDENTITY ?= Developer ID Application: Tanner Stokes (AE76EV48ND)
REPO ?= twstokes/DarwinDOOM
BUNDLE_ID ?= com.tannr.DarwinDOOM
PROVISIONING_PROFILE ?=
NOTARY_PROFILE ?=
ALLOW_DIRTY ?= false
PUSH_TAG ?= true
BUILD_DIR ?=
NOTES ?=

release-macos:
	@if [ -z "$(VERSION)" ]; then \
		echo "VERSION is required. Example: make release-macos VERSION=0.1.0"; \
		exit 1; \
	fi
	@cmd=(bundle exec fastlane mac release_macos \
		version:"$(VERSION)" \
		identity:"$(IDENTITY)" \
		repo:"$(REPO)" \
		bundle_id:"$(BUNDLE_ID)" \
		allow_dirty:"$(ALLOW_DIRTY)" \
		push_tag:"$(PUSH_TAG)" \
		dry_run:false \
		notarize:false); \
	if [ -n "$(PROVISIONING_PROFILE)" ]; then \
		cmd+=(provisioning_profile:"$(PROVISIONING_PROFILE)"); \
	fi; \
	if [ -n "$(NOTARY_PROFILE)" ]; then \
		cmd+=(notary_profile:"$(NOTARY_PROFILE)"); \
	fi; \
	if [ -n "$(BUILD_DIR)" ]; then \
		cmd+=(build_dir:"$(BUILD_DIR)"); \
	fi; \
	if [ -n "$(NOTES)" ]; then \
		cmd+=(notes:"$(NOTES)"); \
	fi; \
	echo "$${cmd[@]}"; \
	"$${cmd[@]}"

release:
	@$(MAKE) release-macos

format:
	@swiftformat .
