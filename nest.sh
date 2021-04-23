#!/bin/bash
dome-nest -zo game.egg -- *.wren core entity res/font res/img scene utils config.json tileRules.json
cp game.egg ~/Downloads/dome-builds/cartomancer
