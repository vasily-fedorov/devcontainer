.PHONY: test

test:
	@echo "Running all tests..."
	@echo "Running feature-python test..."
	@./test/feature-python.sh
	@echo "Running devcontainer-features-python test..."
	@./test/devcontainer-features-python.sh
	@echo "Running devcontainers-cli-compat test..."
	@./test/devcontainers-cli-compat.sh
	@echo "All tests completed successfully!"
