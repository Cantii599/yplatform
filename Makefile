# include support-firecloud/repo/mk/js.common.node.mk
include repo/mk/js.common.node.mk

# ------------------------------------------------------------------------------

SF_PATH_FILES_IGNORE := \
	$(SF_PATH_FILES_IGNORE) \
	-e "^.github/" \
	-e "^generic/dot\.gitattributes_global$$" \
	-e "^generic/dot\.gitignore_global$$" \
	-e "^repo/AUTHORS$$" \
	-e "^repo/Brewfile.inc.sh$$" \
	-e "^repo/cfn/tpl\.Makefile$$" \
	-e "^repo/dot.github/" \
	-e "^repo/LICENSE$$" \
	-e "^repo/NOTICE$$" \
	-e "^repo/UNLICENSE$$" \

SF_ECLINT_FILES_IGNORE := \
	$(SF_ECLINT_FILES_IGNORE) \
	-e "^bin/" \
	-e "^repo/LICENSE$$" \
	-e "^repo/UNLICENSE$$" \
	-e "^support-firecloud$$" \

SF_TEST_TARGETS := \
	$(SF_TEST_TARGETS) \
	test-secret \

# ------------------------------------------------------------------------------

.PHONY: test-secret
test-secret:
ifeq (true,$(SF_IS_TRANSCRYPTED))
	$(CAT) doc/how-to-manage-secrets.md.test.secret | \
		$(GREP) -q "This is a test of transcrypt."; \
else
	:
endif
