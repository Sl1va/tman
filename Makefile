test:
	lua taskid.lua

git:
	lua git.lua

run:
	lua taskman.lua


lua_fmt:
	echo "===> Formatting"
	stylua . --config-path=.stylua.toml

lua_lint:
	echo "===> Linting"
	luacheck lua/ --globals vim
