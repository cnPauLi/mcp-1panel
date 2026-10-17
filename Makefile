GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOARCH=$(shell go env GOARCH)
GOOS=$(shell go env GOOS )

BASE_PATH := $(shell pwd)
BUILD_PATH = $(BASE_PATH)/build

MAIN_PATH=$(BASE_PATH)/.
BIN_NAME=mcp-1panel

APP_KEY=mcp-1panel
APP_VERSION=0.2.0
APP_PATH=$(BASE_PATH)/1panel-app/$(APP_KEY)
APP_VERSION_PATH=$(APP_PATH)/$(APP_VERSION)
DIST_PATH=$(BASE_PATH)/dist

.PHONY: build build-linux package-1panel-app

build:
	mkdir -p $(BUILD_PATH)
	cd $(BASE_PATH) \
	&& GOOS=$(GOOS) GOARCH=$(GOARCH) $(GOBUILD) -trimpath -ldflags '-s -w' -o $(BUILD_PATH)/$(BIN_NAME) $(MAIN_PATH)

build-linux:
	mkdir -p $(APP_VERSION_PATH)
	cd $(BASE_PATH) \
	&& CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -trimpath -ldflags '-s -w' -o $(APP_VERSION_PATH)/$(BIN_NAME)-linux-amd64 $(MAIN_PATH)
	cd $(BASE_PATH) \
	&& CGO_ENABLED=0 GOOS=linux GOARCH=arm64 $(GOBUILD) -trimpath -ldflags '-s -w' -o $(APP_VERSION_PATH)/$(BIN_NAME)-linux-arm64 $(MAIN_PATH)

package-1panel-app: build-linux
	mkdir -p $(DIST_PATH)
	tar -czf $(DIST_PATH)/$(APP_KEY)-$(APP_VERSION)-1panel-app.tar.gz -C $(BASE_PATH)/1panel-app $(APP_KEY)