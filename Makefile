#all: release
.PHONY: test

test:
	@lua test/db_add.lua

git:
	lua git.lua

run:
	lua taskman.lua


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
