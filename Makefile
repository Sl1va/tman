#all: release
.PHONY: lua_test lua_fmt lua_lint lua_docs

lua_test:
	@lua test/tests.lua

# stylua is install by cargo (rust something)
lua_fmt:
	echo "===> Formatting"
	stylua . --config-path=.stylua.toml

lua_lint:
	echo "===> Linting"
	luacheck .

lua_docs:
	echo "===> Docs"
	ldoc .


release: lua_fmt lua_lint lua_docs
