# Adds a 'ci/<BRANCH>' target that will force push HEAD to the BRANCH,
# triggering a CI build on a specific CI platform.
#
# ------------------------------------------------------------------------------
#
# Adds a 'debug-ci/<BRANCH>' target that will force push a '[debug ci]' commit to the BRANCH,
# triggering a CI build on a specific CI platform, and start a debug session.
#
# ------------------------------------------------------------------------------

CI_PREFIX += \
	appveyor \
	bitrise \
	buddy \
	circle \
	cirrus \
	codeship \
	github \
	gitlab \
	semaphore \
	sourcehut \
	travis \

CI_TARGETS += \
	$(patsubst %,ci/%-\%,$(CI_PREFIX)) \

DEBUG_CI_TARGETS += \
	$(patsubst %,debug-ci/%-\%,$(CI_PREFIX)) \

BOOTSTRAP_CI_TARGETS += \
	$(patsubst %,bootstrap-ci/%-\%,$(CI_PREFIX)) \

# ------------------------------------------------------------------------------

.PHONY: $(CI_TARGETS)
# NOTE: below is a workaround for 'make help-all' to work
ci/appveyor-%:
ci/bitrise-%:
ci/buddy-%:
ci/circle-%:
ci/cirrus-%:
ci/codeship-%:
ci/github-%:
ci/gitlab-%:
ci/semaphore-%:
ci/sourcehut-%:
ci/travis-%:
$(CI_TARGETS):
ci/%: ## Force push to a CI branch.
	$(eval BRANCH := $(@:ci/%=%))
	$(GIT) push --force --no-verify $(GIT_REMOTE_OR_ORIGIN) head:refs/heads/$(BRANCH)

.PHONY: $(DEBUG_CI_TARGETS)
# NOTE: below is a workaround for 'make help-all' to work
debug-ci/appveyor-%:
debug-ci/bitrise:
debug-ci/buddy:
debug-ci/circle-%:
debug-ci/cirrus-%:
debug-ci/codeship-%:
debug-ci/github-%:
debug-ci/gitlab-%:
debug-ci/semaphore-%:
debug-ci/sourcehut-%:
debug-ci/travis-%:
$(DEBUG_CI_TARGETS):
debug-ci/%: ## Force push to a CI branch and debug post-ci-bootstrap (tmate session).
	$(eval BRANCH := $(@:debug-ci/%=%))
	$(ECHO) "$(GIT_COMMIT_MSG)" | $(GREP) -q "\[debug ci\]" || \
		$(GIT) commit --allow-empty -m "$(GIT_COMMIT_MSG) [debug ci]"
	$(GIT) push --force --no-verify $(GIT_REMOTE_OR_ORIGIN) head:refs/heads/$(BRANCH)

.PHONY: $(BOOTSTRAP_CI_TARGETS)
# NOTE: below is a workaround for 'make help-all' to work
bootstrap-ci/appveyor-%:
bootstrap-ci/bitrise:
bootstrap-ci/buddy:
bootstrap-ci/bootstraprcle-%:
bootstrap-ci/bootstraprrus-%:
bootstrap-ci/codeship-%:
bootstrap-ci/github-%:
bootstrap-ci/gitlab-%:
bootstrap-ci/semaphore-%:
bootstrap-ci/sourcehut-%:
bootstrap-ci/travis-%:
$(BOOTSTRAP_CI_TARGETS):
bootstrap-ci/%: ## Force push to a CI branch and debug pre-bootstrap (tmate session).
	$(eval BRANCH := $(@:bootstrap-ci/%=%))
	$(ECHO) "$(GIT_COMMIT_MSG)" | $(GREP) -q "\[bootstrap ci\]" || \
		$(GIT) commit --allow-empty -m "$(GIT_COMMIT_MSG) [bootstrap ci]"
	$(GIT) push --force --no-verify $(GIT_REMOTE_OR_ORIGIN) head:refs/heads/$(BRANCH)
