test:
	lua tman.lua

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
