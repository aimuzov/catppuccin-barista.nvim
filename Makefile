.PHONY: test test-file lint

test:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

test-file:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedFile tests/barista_spec.lua"

lint:
	luacheck lua/ tests/ --globals vim describe it before_each assert
