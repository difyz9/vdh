# Video Downloader Helper (VDH) - Makefile

BINARY_NAME = vdh
SOURCE_FILE = main.swift
INSTALL_PATH = /usr/local/bin
HOMEBREW_PREFIX = $(shell brew --prefix 2>/dev/null || echo "/usr/local")
FORMULA_PATH = $(HOMEBREW_PREFIX)/Library/Taps/homebrew/homebrew-core/Formula

.PHONY: all build install uninstall clean test homebrew-install homebrew-uninstall service-start service-stop service-status help

all: build

# 构建二进制文件
build:
	@echo "🔨 Building $(BINARY_NAME)..."
	@swiftc $(SOURCE_FILE) -o $(BINARY_NAME)
	@echo "✅ Build completed: $(BINARY_NAME)"

# 安装到系统
install: build
	@echo "📦 Installing $(BINARY_NAME) to $(INSTALL_PATH)..."
	@sudo cp $(BINARY_NAME) $(INSTALL_PATH)/
	@sudo chmod +x $(INSTALL_PATH)/$(BINARY_NAME)
	@echo "✅ Installation completed"
	@echo "📍 Binary installed at: $(INSTALL_PATH)/$(BINARY_NAME)"

# 卸载
uninstall:
	@echo "🗑️  Uninstalling $(BINARY_NAME)..."
	@sudo rm -f $(INSTALL_PATH)/$(BINARY_NAME)
	@echo "✅ Uninstallation completed"

# 清理构建文件
clean:
	@echo "🧹 Cleaning build files..."
	@rm -f $(BINARY_NAME)
	@echo "✅ Clean completed"

# 测试构建
test: build
	@echo "🧪 Running tests..."
	@./$(BINARY_NAME) --version
	@./$(BINARY_NAME) --help | head -5
	@echo "✅ Tests passed"

# Homebrew 安装（开发模式）
homebrew-install: build
	@echo "🍺 Setting up Homebrew formula..."
	@mkdir -p $(HOME)/.homebrew/Formula
	@cp vdh.rb $(HOME)/.homebrew/Formula/
	@echo "📝 Formula copied to: $(HOME)/.homebrew/Formula/"
	@echo ""
	@echo "To install via Homebrew:"
	@echo "  brew install --formula $(HOME)/.homebrew/Formula/vdh.rb"

# 创建本地 Homebrew tap
homebrew-tap:
	@echo "🍺 Creating local Homebrew tap..."
	@mkdir -p $(HOME)/.homebrew-tap/Formula
	@cp vdh.rb $(HOME)/.homebrew-tap/Formula/
	@echo "✅ Local tap created at: $(HOME)/.homebrew-tap/"
	@echo ""
	@echo "To use the local tap:"
	@echo "  brew tap local/vdh $(HOME)/.homebrew-tap"
	@echo "  brew install local/vdh/vdh"

# 服务管理
service-start:
	@echo "🚀 Starting vdh service..."
	@if command -v brew >/dev/null 2>&1; then \
		brew services start vdh || echo "❌ Service not installed via Homebrew"; \
	else \
		echo "❌ Homebrew not found"; \
	fi

service-stop:
	@echo "🛑 Stopping vdh service..."
	@if command -v brew >/dev/null 2>&1; then \
		brew services stop vdh || echo "❌ Service not installed via Homebrew"; \
	else \
		echo "❌ Homebrew not found"; \
	fi

service-status:
	@echo "📊 Checking service status..."
	@if command -v brew >/dev/null 2>&1; then \
		brew services list | grep vdh || echo "❌ Service not found"; \
	else \
		echo "❌ Homebrew not found"; \
	fi
	@echo ""
	@echo "📊 Checking application status..."
	@if [ -S "/tmp/video_downloader.sock" ]; then \
		echo "✅ Socket server is running"; \
		if [ -f "$(BINARY_NAME)" ]; then \
			./$(BINARY_NAME) status; \
		elif command -v vdh >/dev/null 2>&1; then \
			vdh status; \
		fi; \
	else \
		echo "❌ Socket server is not running"; \
	fi

# 创建发布包
package: build
	@echo "📦 Creating release package..."
	@mkdir -p release
	@cp $(BINARY_NAME) release/
	@cp vdh.rb release/
	@cp README.md release/ 2>/dev/null || echo "README.md not found, skipping..."
	@cp test_*.sh release/ 2>/dev/null || true
	@echo "✅ Release package created in ./release/"

# 显示帮助
help:
	@echo "VDH (Video Downloader Helper) - Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  build              Build the binary"
	@echo "  install            Install to system (/usr/local/bin)"
	@echo "  uninstall          Remove from system"
	@echo "  clean              Clean build files"
	@echo "  test               Run basic tests"
	@echo "  homebrew-install   Setup for Homebrew development"
	@echo "  homebrew-tap       Create local Homebrew tap"
	@echo "  service-start      Start the service (via Homebrew)"
	@echo "  service-stop       Stop the service (via Homebrew)"
	@echo "  service-status     Check service and app status"
	@echo "  package            Create release package"
	@echo "  help               Show this help"
	@echo ""
	@echo "Quick start:"
	@echo "  make build         # Build the application"
	@echo "  make install       # Install system-wide"
	@echo "  make service-start # Start as service"

# 检查依赖
check-deps:
	@echo "🔍 Checking dependencies..."
	@command -v swift >/dev/null 2>&1 || (echo "❌ Swift not found" && exit 1)
	@command -v yt-dlp >/dev/null 2>&1 || echo "⚠️  yt-dlp not found (recommended)"
	@command -v brew >/dev/null 2>&1 || echo "⚠️  Homebrew not found (optional)"
	@echo "✅ Dependencies check completed"
