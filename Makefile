all: release
.PHONY: lua_fmt lua_lint lua_docs lua_tests

all: release


# stylua is install by cargo (rust something)
lua_fmt:
	@echo "===> Formatting"
	stylua -f .configs/stylua.toml src

lua_docs:
	@echo "\n===> Docs"
	ldoc -c .configs/luacheck.ld src

lua_lint:
	@echo "\n===> Linting"
	luacheck src

lua_tests:
	@echo "\n===> Tests (under development)"
	#@lua tests/unit/tests.lua

release: lua_fmt lua_docs lua_lint lua_tests
