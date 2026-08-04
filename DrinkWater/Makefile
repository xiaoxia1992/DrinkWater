.PHONY: all build clean run install

PROJECT_DIR := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR := $(PROJECT_DIR)build
APP_PATH := $(BUILD_DIR)/饮水提醒.app

all: build

build:
	@bash $(PROJECT_DIR)build.sh < /dev/null

clean:
	rm -rf $(BUILD_DIR)

run: build
	open "$(APP_PATH)"

install:
	cp -R "$(APP_PATH)" /Applications/

uninstall:
	rm -rf /Applications/饮水提醒.app
