#all: release
.PHONY: lua_test lua_fmt lua_lint lua_docs

all: release

lua_test:
	@lua tests/unit/tests.lua

# stylua is install by cargo (rust something)
lua_fmt:
	@echo "===> Formatting (under development)"

lua_docs:
	@echo "\n===> Docs"
	ldoc .

lua_lint:
	@echo "\n===> Linting"
	luacheck src

release: lua_fmt lua_docs lua_lint
