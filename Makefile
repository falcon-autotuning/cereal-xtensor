# Cereal Xtensor Makefile
# Manages build configurations and testing using vcpkg

.PHONY: all configure build-debug build-release clean install help check-vcpkg

# Detect OS
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    PLATFORM := linux
    CMAKE_GENERATOR := Ninja
    VCPKG_TRIPLET ?= x64-linux-dynamic
    NPROC := $(shell nproc 2>/dev/null || echo 4)
    HAS_DOCKER := $(shell command -v docker-compose >/dev/null 2>&1 && echo yes || echo no)
    SUDO ?= sudo
		export CC=clang
		export CXX=clang++
endif
ifeq ($(OS),Windows_NT)
    PLATFORM := windows
    CMAKE_GENERATOR := "Visual Studio 17 2022"
    VCPKG_TRIPLET ?= x64-windows
    NPROC := 4
    HAS_DOCKER := $(shell where docker-compose >nul 2>&1 && echo yes || echo no)
    SUDO :=
endif

# vcpkg and NuGet binary cache
VCPKG_ROOT ?= $(CURDIR)/vcpkg
VCPKG_TOOLCHAIN ?= $(VCPKG_ROOT)/scripts/buildsystems/vcpkg.cmake
VCPKG_INSTALLED_DIR ?= $(CURDIR)/vcpkg_installed
NUGET_FEED ?= https://pkgs.dev.azure.com/falcon-autotuning/_packaging/falcon-autotuning/nuget/v3/index.json
VCPKG_BINARY_SOURCES ?= clear;nuget,$(NUGET_FEED),readwrite

BUILD_DIR_DEBUG := build/debug
BUILD_DIR_RELEASE := build/release

INSTALL_PREFIX ?= /opt/falcon
INSTALL_LIBDIR := $(INSTALL_PREFIX)/lib
INSTALL_INCLUDEDIR := $(INSTALL_PREFIX)/include

# Default target
all: build-release

help:
	@echo "Cereal Xtensor Build System"
	@echo "============================="
	@echo ""
	@echo "Build targets:"
	@echo "  make build-debug         - Build debug version"
	@echo "  make build-release       - Build release version"
	@echo "  make configure           - Configure both debug and release builds"
	@echo "  make clean               - Clean build artifacts"
	@echo "  make install             - Install the library"
	@echo ""
	@echo "vcpkg/NuGet targets:"
	@echo "  make vcpkg-bootstrap     - Clone and bootstrap vcpkg"
	@echo "  make vcpkg-install-deps  - Install vcpkg dependencies (with NuGet cache if configured)"
	@echo ""
	@echo "Environment variables:"
	@echo "  VCPKG_ROOT               - Path to vcpkg root (default: ./vcpkg)"
	@echo "  VCPKG_TRIPLET            - vcpkg triplet (default: x64-linux-dynamic)"
	@echo "  NUGET_API_KEY            - NuGet API key for binary cache (or .nuget_api_key file)"
	@echo "  NUGET_FEED               - NuGet feed URL (default: $(NUGET_FEED))"
	@echo ""
	@echo "Current configuration:"
	@echo "  Platform: $(PLATFORM)"
	@echo "  Generator: $(CMAKE_GENERATOR)"
	@echo "  Triplet: $(VCPKG_TRIPLET)"
	@echo "  Docker available: $(HAS_DOCKER)"

.PHONY: vcpkg-bootstrap
vcpkg-bootstrap:
	@if [ ! -d "$(VCPKG_ROOT)" ]; then \
		echo "Cloning vcpkg..."; \
		git clone https://github.com/microsoft/vcpkg.git $(VCPKG_ROOT); \
	fi
	@if [ ! -f "$(VCPKG_ROOT)/vcpkg" ]; then \
		echo "Bootstrapping vcpkg..."; \
		cd $(VCPKG_ROOT) && ./bootstrap-vcpkg.sh; \
	fi

setup-nuget-auth:
	@if [ ! -f .nuget_api_key ] && [ -z "$$NUGET_API_KEY" ]; then \
		echo "No .nuget_api_key or NUGET_API_KEY found, skipping NuGet setup (local-only build, no binary cache)."; \
		exit 0; \
	fi
	@echo "Setting up NuGet authentication for vcpkg binary caching..."
	@if ! command -v mono >/dev/null 2>&1; then \
		echo "Error: mono is not installed. Please install mono (e.g., 'sudo pacman -S mono' on Arch, 'sudo apt install mono-complete' on Ubuntu)."; \
		exit 1; \
	fi
	@mkdir -p $$HOME/.nuget/NuGet
	@API_KEY=$$(if [ -f .nuget_api_key ]; then cat .nuget_api_key; else echo $$NUGET_API_KEY; fi); \
	NUGET_EXE=$$(vcpkg fetch nuget | tail -n1); \
	mono "$$NUGET_EXE" sources remove -Name "falcon-autotuning" || true; \
	mono "$$NUGET_EXE" sources add -Name "falcon-autotuning" -Source "$(NUGET_FEED)" -Username "ADO" -Password "$$API_KEY"

.PHONY: vcpkg-install-deps
vcpkg-install-deps: setup-nuget-auth 
	@echo "Installing vcpkg dependencies" 
	@CC=clang CXX=clang++ VCPKG_FEATURE_FLAGS=binarycaching MAKELEVEL=0 \
		$(VCPKG_ROOT)/vcpkg install \
		--binarysource="$(VCPKG_BINARY_SOURCES)" \
		--triplet="$(VCPKG_TRIPLET)" \
		--debug

check-vcpkg: vcpkg-bootstrap  vcpkg-install-deps
	@echo "Checking vcpkg configuration..."
	@if [ ! -d "$(VCPKG_ROOT)" ]; then \
		echo "Error: vcpkg not found at $(VCPKG_ROOT)"; \
		echo "Run 'make deps' in the parent directory first"; \
		exit 1; \
	fi
	@if [ ! -f "$(VCPKG_TOOLCHAIN)" ]; then \
		echo "Error: vcpkg toolchain not found at $(VCPKG_TOOLCHAIN)"; \
		exit 1; \
	fi
	@echo "✓ vcpkg configuration OK"


configure-debug: check-vcpkg
	@echo "Configuring debug build..."
	@mkdir -p $(BUILD_DIR_DEBUG)
	cd $(BUILD_DIR_DEBUG) && cmake ../.. \
		-DCMAKE_BUILD_TYPE=Debug \
		-DCMAKE_TOOLCHAIN_FILE=$(VCPKG_TOOLCHAIN) \
		-DVCPKG_INSTALLED_DIR=$(VCPKG_INSTALLED_DIR) \
		-DVCPKG_TARGET_TRIPLET=$(VCPKG_TRIPLET) \
		-DUSE_CCACHE=ON \
		-DENABLE_PCH=ON \
		-DCMAKE_C_COMPILER=clang \
		-DCMAKE_CXX_COMPILER=clang++ \
		-DVCPKG_BINARY_SOURCES="$(VCPKG_BINARY_SOURCES)" \
		-G $(CMAKE_GENERATOR)
	@echo "✓ Debug build configured"

configure-release: check-vcpkg
	@echo "Configuring release build..."
	@mkdir -p $(BUILD_DIR_RELEASE)
	cd $(BUILD_DIR_RELEASE) && cmake ../.. \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_TOOLCHAIN_FILE=$(VCPKG_TOOLCHAIN) \
		-DVCPKG_INSTALLED_DIR=$(VCPKG_INSTALLED_DIR) \
		-DVCPKG_TARGET_TRIPLET=$(VCPKG_TRIPLET) \
		-DUSE_CCACHE=ON \
		-DENABLE_PCH=ON \
		-DCMAKE_C_COMPILER=clang \
		-DCMAKE_CXX_COMPILER=clang++ \
		-DVCPKG_BINARY_SOURCES="$(VCPKG_BINARY_SOURCES)" \
		-G $(CMAKE_GENERATOR)
	@echo "✓ Release build configured"

configure: configure-debug configure-release

build-debug: configure-debug
	@echo "Building debug..."
	ninja -C $(BUILD_DIR_DEBUG) -j$(NPROC)
	@echo "✓ Debug build complete"
	@$(MAKE) clangd-helpers

build-release: configure-release
	@echo "Building release..."
	ninja -C $(BUILD_DIR_RELEASE) -j$(NPROC)
	@echo "✓ Release build complete"

install: build-release
	@echo "Installing cereal-xtensor to $(INSTALL_PREFIX)..."
	$(SUDO) cmake --install $(BUILD_DIR_RELEASE) --prefix $(INSTALL_PREFIX)
	@echo "Copying vcpkg headers and libraries..."
	$(SUDO) cp -r $(VCPKG_INSTALLED_DIR)/$(VCPKG_TRIPLET)/include/* $(INSTALL_INCLUDEDIR)/
	$(SUDO) cp -r $(VCPKG_INSTALLED_DIR)/$(VCPKG_TRIPLET)/lib/* $(INSTALL_LIBDIR)/
	$(SUDO) cp -r $(VCPKG_INSTALLED_DIR)/$(VCPKG_TRIPLET)/bin/* $(INSTALL_LIBDIR)/ || true
	@echo "✓ Installation complete"

uninstall:
	@echo "Uninstalling falcon-database from $(INSTALL_PREFIX)..."
	$(SUDO) rm -r $(INSTALL_LIBDIR)/libcereal-xtensor* || true
	@echo "✓ Uninstall complete"

clean: uninstall
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR_DEBUG) $(BUILD_DIR_RELEASE) build/ compile_commands.json ./vcpkg_installed/
	@echo "✓ Clean complete"

.PHONY: clangd-helpers
clangd-helpers:
	@if [ -f $(BUILD_DIR_DEBUG)/compile_commands.json ]; then \
		ln -sf $(BUILD_DIR_DEBUG)/compile_commands.json compile_commands.json; \
		echo "✓ clangd compile_commands.json symlinked to database/ root"; \
	else \
		echo "No compile_commands.json found in debug build directory."; \
	fi
