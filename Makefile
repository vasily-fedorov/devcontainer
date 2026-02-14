.PHONY: test test-cli test-features test-python help

# Цель по умолчанию
.DEFAULT_GOAL := help

# Основная цель - запуск всех тестов
test: test-cli test-features test-python
	@echo "✓ All tests completed successfully!"

# Тесты совместимости с devcontainers CLI
test-cli:
	@echo "Running devcontainers CLI compatibility tests..."
	@./test/devcontainers-cli-compat.sh
	@echo "✓ CLI compatibility tests completed!"

# Тесты features (включая Python)
test-features: 
	@echo "Running features tests..."
	@./test/devcontainer-features-python.sh
	@echo "✓ Features tests completed!"

# Тесты Python feature
test-python:
	@echo "Running Python feature tests..."
	@./test/feature-python.sh
	@echo "✓ Python feature tests completed!"

# Справка по доступным командам
help:
	@echo "DevContainer Test Suite"
	@echo "======================"
	@echo ""
	@echo "Available targets:"
	@echo "  make test        - Run all tests (default)"
	@echo "  make test-cli    - Run devcontainers CLI compatibility tests"
	@echo "  make test-features - Run devcontainer features tests"
	@echo "  make test-python - Run Python feature tests"
	@echo "  make help        - Show this help message"
	@echo ""
	@echo "See README.org for more details."
