.PHONY: test check-docker check-vagrant test-quick test-quick-ubuntu24 test-quick-debian12 test-quick-arch test-full test-full-ubuntu24 test-full-debian12 test-full-arch test-ubuntu24 test-debian12 test-arch test-shell-ubuntu24 test-shell-debian12 test-shell-arch test-clean test-all

DOCKER := $(shell command -v docker)
TEST_DIR := test
RESULTS_DIR := test-results

GREEN := \033[32m
RED := \033[31m
YELLOW := \033[33m
NC := \033[0m

check-docker:
	@if [ -z "$(DOCKER)" ]; then \
		echo "$(RED)Docker not installed$(NC)"; \
		exit 1; \
	else \
		echo "$(GREEN)Docker found$(NC)"; \
	fi

test: check-docker
	./test.sh

test-quick-ubuntu24: check-docker
	@echo "Testing Ubuntu 24.04 (Docker) with role=workstation..."
	@cd $(TEST_DIR)/docker && ./run-docker-test.sh ubuntu24 && \
		echo "$(GREEN)✓ PASS$(NC)" || \
		{ echo "$(RED)✗ FAIL$(NC)"; exit 1; }

test-quick-debian12: check-docker
	@echo "Testing Debian 12 (Docker) with role=server..."
	@cd $(TEST_DIR)/docker && ./run-docker-test.sh debian12 && \
		echo "$(GREEN)✓ PASS$(NC)" || \
		{ echo "$(RED)✗ FAIL$(NC)"; exit 1; }

test-quick-arch: check-docker
	@echo "Testing Arch (Docker) with role=workstation..."
	@cd $(TEST_DIR)/docker && ./run-docker-test.sh arch && \
		echo "$(GREEN)✓ PASS$(NC)" || \
		{ echo "$(RED)✗ FAIL$(NC)"; exit 1; }

test-quick: test-quick-ubuntu24 test-quick-debian12 test-quick-arch
	@echo "$(GREEN)Quick tests: 3/3 passed$(NC)"

check-vagrant:
	@if [ -z "$$(command -v vagrant)" ]; then \
		echo "$(RED)Vagrant not installed$(NC)"; \
		exit 1; \
	else \
		echo "$(GREEN)Vagrant found$(NC)"; \
	fi

test-full-ubuntu24: check-vagrant
	@echo "Testing Ubuntu 24.04 (Vagrant) with role=workstation..."
	@cd $(TEST_DIR)/vagrant && vagrant up ubuntu24 && \
		echo "$(GREEN)✓ PASS$(NC)" && vagrant destroy -f ubuntu24 || \
		{ echo "$(RED)✗ FAIL$(NC)"; exit 1; }

test-full-debian12: check-vagrant
	@echo "Testing Debian 12 (Vagrant) with role=server..."
	@cd $(TEST_DIR)/vagrant && vagrant up debian12 && \
		echo "$(GREEN)✓ PASS$(NC)" && vagrant destroy -f debian12 || \
		{ echo "$(RED)✗ FAIL$(NC)"; exit 1; }

test-full-arch: check-vagrant
	@echo "Testing Arch (Vagrant) with role=workstation..."
	@cd $(TEST_DIR)/vagrant && vagrant up arch && \
		echo "$(GREEN)✓ PASS$(NC)" && vagrant destroy -f arch || \
		{ echo "$(RED)✗ FAIL$(NC)"; exit 1; }

test-full: test-full-ubuntu24 test-full-debian12 test-full-arch
	@echo "$(GREEN)Full tests: 3/3 passed$(NC)"

test-ubuntu24: test-quick-ubuntu24 test-full-ubuntu24
	@echo "$(GREEN)Ubuntu 24.04: Quick + Full passed$(NC)"

test-debian12: test-quick-debian12 test-full-debian12
	@echo "$(GREEN)Debian 12: Quick + Full passed$(NC)"

test-arch: test-quick-arch test-full-arch
	@echo "$(GREEN)Arch: Quick + Full passed$(NC)"

test-shell-ubuntu24: check-vagrant
	@cd $(TEST_DIR)/vagrant && vagrant up ubuntu24 && vagrant ssh ubuntu24

test-shell-debian12: check-vagrant
	@cd $(TEST_DIR)/vagrant && vagrant up debian12 && vagrant ssh debian12

test-shell-arch: check-vagrant
	@cd $(TEST_DIR)/vagrant && vagrant up arch && vagrant ssh arch

test-clean:
	@echo "Cleaning up test infrastructure..."
	@docker rmi machines-test:ubuntu24 machines-test:debian12 machines-test:arch 2>/dev/null || true
	@cd $(TEST_DIR)/vagrant && vagrant destroy -f 2>/dev/null || true
	@rm -rf $(RESULTS_DIR)
	@echo "$(GREEN)Cleanup complete$(NC)"

test-all: test-quick test-full
	@echo "$(GREEN)All tests passed: Quick + Full for all distros$(NC)"
