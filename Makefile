# ==============================================
# UVM Verification Environment Makefile
# Version: 3.1.0
# Features:
# - 完全使用test_results/<testname>/目录结构
# - 移除所有旧目录兼容代码
# - 更清晰的路径管理
# ==============================================

# -------------------------------
# 基础配置
# -------------------------------
SIMULATOR    ?= vcs
UVM_VERSION  ?= 1.2
TIMESCALE    := 1ns/1ps
MAX_RETRIES  ?= 3
DEFAULT_THREADS := 1
MAX_THREADS     := $(shell nproc)

# LSF命令配置
#BSUB_CMD     := bsub -Is -q large
BSUB_CMD     :=

# 线程控制
THREADS ?= $(DEFAULT_THREADS)
THREADS := $(shell if [ $(THREADS) -gt $(MAX_THREADS) ]; then echo $(MAX_THREADS); else echo $(THREADS); fi)
COMPILE_THREADS ?= $(THREADS)
SIM_THREADS     ?= 1

# -------------------------------
# 目录结构配置
# -------------------------------
TEST_OUTPUT_ROOT := work
TEST_DIR         := $(TEST_OUTPUT_ROOT)/$(TEST)
TEST_BUILD_DIR   := $(TEST_DIR)/build
TEST_LOG_DIR     := $(TEST_DIR)/logs
TEST_WAVE_DIR    := $(TEST_DIR)/waves
TEST_COV_DIR     := $(TEST_DIR)/coverage
TEST_REPORT_DIR  := $(TEST_DIR)/reports

# -------------------------------
# 文件列表配置
# -------------------------------
TESTLIST     := ../vc/tests.list
FILELIST     := ../vc/filelist.f
COV_MERGE    := $(TEST_OUTPUT_ROOT)/merged_cov

# -------------------------------
# 仿真器配置
# -------------------------------
ifeq ($(SIMULATOR),vcs)
    COMPILE_CMD := $(BSUB_CMD) VCS_ARCH_OVERRIDE=linux bash $(VCS_HOME)/bin/vcs -full64 -sverilog \
                   -ntb_opts uvm-$(UVM_VERSION) \
                   -timescale=$(TIMESCALE) \
				   -debug_access+all -kdb \
                   $(VERDI_HOME)/share/PLI/VCS/linux64/pli.a
    RUN_CMD     := $(BSUB_CMD) ./simv
else ifeq ($(SIMULATOR),xcelium)
    COMPILE_CMD := $(BSUB_CMD) $(XCELIUM_HOME)/tools/bin/xrun -64bit -sv \
                   -uvm$(UVM_VERSION) \
                   -timescale $(TIMESCALE)
    RUN_CMD     := $(BSUB_CMD) xmsim
endif

# -------------------------------
# 主目标
# -------------------------------
.PHONY: all all_regression compile regression run wave clean cov_report prepare help check_threads check_build clean_build

# -------------------------------
# 环境准备
# -------------------------------
prepare:
	@echo "[ENV] Creating directory structure for $(TEST)..."
	@mkdir -p $(TEST_BUILD_DIR) $(TEST_LOG_DIR) $(TEST_WAVE_DIR) $(TEST_COV_DIR) $(TEST_REPORT_DIR)
	@chmod 755 $(TEST_DIR) $(TEST_BUILD_DIR) $(TEST_LOG_DIR) $(TEST_WAVE_DIR) $(TEST_COV_DIR) $(TEST_REPORT_DIR)
	@touch $(TEST_LOG_DIR)/compile.log
	@chmod 644 $(TEST_LOG_DIR)/compile.log
	@echo "[ENV] Directories created at:"
	@ls -ld $(TEST_DIR) $(TEST_DIR)/*

# -------------------------------
# 检查目标
# -------------------------------
check_threads:
	@echo "[CONFIG] Using $(THREADS) thread(s) (Max available: $(MAX_THREADS))"
	@if [ $(THREADS) -lt 1 ]; then \
		echo "Error: THREADS must be >= 1"; exit 1; \
	fi

check_build:
	@test -d $(TEST_BUILD_DIR) || { \
		echo "Error: $(TEST_BUILD_DIR) does not exist. Run 'make all' first."; \
		exit 1; \
	}

# -------------------------------
# 清理目标
# -------------------------------
clean_build:
	@echo "[CLEAN] Removing build directory for $(TEST)..."
	@rm -rf $(TEST_BUILD_DIR)

clean:
	@echo "[CLEAN] Removing all generated files for $(TEST)..."
	@rm -rf $(TEST_DIR)

distclean: clean
	@echo "[DISTCLEAN] Removing all test results..."
	@rm -rf $(TEST_OUTPUT_ROOT)
	@echo "[DISTCLEAN] Done."

# -------------------------------
# 编译目标
# -------------------------------
$(TEST_BUILD_DIR)/simv: $(FILELIST) | prepare
	@echo "[COMPILE] Building for $(TEST)..."
	@echo "Executing in $(TEST_BUILD_DIR):"
	@echo "$(COMPILE_CMD) -f ../../../$(FILELIST) -j$(COMPILE_THREADS) -l ../logs/compile.log"
	cd $(TEST_BUILD_DIR) && \
	$(COMPILE_CMD) \
	-f ../../../$(FILELIST) \
	-j$(COMPILE_THREADS) \
	-l ../logs/compile.log
	@echo "[COMPILE] Build completed. Log: $(TEST_LOG_DIR)/compile.log"

compile: $(TEST_BUILD_DIR)/simv

# -------------------------------
# 测试执行目标
# -------------------------------
all: clean compile
	@echo "[ALL] Running test: $(TEST)"
	@$(MAKE) run TEST=$(TEST)

all_regression: clean_build compile
	@echo "[ALL_REGRESSION] Running full regression..."
	@$(MAKE) regression

run: compile $(TEST_BUILD_DIR)/dump_fsdb.tcl
	@test -n "$(TEST)" || { echo "Error: TEST variable not defined"; exit 1; }
	@echo "[TEST] Running $(TEST)"
	@cd $(TEST_BUILD_DIR) && \
	$(RUN_CMD) +UVM_TESTNAME=$(TEST) \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir ../coverage \
	-ucli -do dump_fsdb.tcl \
	-l ../logs/run.log
	@if grep -q "UVM_ERROR" $(TEST_LOG_DIR)/run.log; then \
		echo "[TEST] $(TEST) FAILED" > $(TEST_LOG_DIR)/result.txt; \
	else \
		echo "[TEST] $(TEST) PASSED" > $(TEST_LOG_DIR)/result.txt; \
	fi

$(TEST_BUILD_DIR)/dump_fsdb.tcl:
	@mkdir -p $(TEST_WAVE_DIR)
	@echo 'fsdbDumpfile "../waves/$(TEST).fsdb"' > $@
	@echo 'fsdbDumpvars 0 "tb_top"' >> $@
	@echo 'fsdbDumpvars +mda' >> $@
	@echo 'run' >> $@
	@echo 'quit' >> $@

# -------------------------------
# 回归测试
# -------------------------------
TESTS := $(shell grep -v '^\#' $(TESTLIST) | tr '\n' ' ')

regression: compile
	@echo "[REGRESSION] Starting regression with $(words $(TESTS)) tests..."
	@for test in $(TESTS); do \
		for i in `seq 1 $(MAX_RETRIES)`; do \
			$(MAKE) run TEST=$$test && break; \
			[ $$i -eq $(MAX_RETRIES) ] && echo "$$test: FAILED (Max retries)" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt && exit 1; \
			echo "[RETRY] Attempt $$i/$(MAX_RETRIES) for $$test"; \
		done; \
	done
	@$(MAKE) regression_report

regression_report:
	@echo "Regression Summary - $(shell date)" > $(TEST_OUTPUT_ROOT)/regression_summary.txt
	@echo "=================================" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt
	@for test in $(TESTS); do \
		echo "$$test: $$(cat $(TEST_OUTPUT_ROOT)/$$test/logs/result.txt 2>/dev/null || echo "NOT RUN")" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt; \
	done
	@echo "\nError Details:" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt
	@grep -e "UVM_ERROR" -e "UVM_FATAL" $(TEST_OUTPUT_ROOT)/*/logs/run.log >> $(TEST_OUTPUT_ROOT)/regression_summary.txt || \
		echo "No UVM errors detected" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt

# -------------------------------
# 辅助功能
# -------------------------------
wave:
	@test -n "$(TEST)" || { echo "Usage: make wave TEST=<testname>"; exit 1; }
	$(BSUB_CMD) verdi -ssf $(TEST_WAVE_DIR)/$(TEST).fsdb -nologo &

cov_report:
	@echo "[COV] Merging coverage data..."
	urg -dir $(TEST_OUTPUT_ROOT)/*/coverage -dbname $(COV_MERGE) \
	    -format both -report $(TEST_OUTPUT_ROOT)/coverage_report
	@echo "[COV] Report: file://$(PWD)/$(TEST_OUTPUT_ROOT)/coverage_report/dashboard.html"

# -------------------------------
# 帮助信息
# -------------------------------
help:
	@echo "UVM Verification Environment Makefile (v3.1.0)"
	@echo "=============================================="
	@echo "核心命令:"
	@echo "  make all TEST=xxx      - 完整构建并运行单个测试"
	@echo "  make run TEST=xxx      - 运行已编译的测试"
	@echo "  make regression        - 运行所有测试"
	@echo "  make wave TEST=xxx     - 查看波形"
	@echo ""
	@echo "目录结构:"
	@echo "  test_results/"
	@echo "  └── <testname>/"
	@echo "      ├── build/     # 编译产物"
	@echo "      ├── logs/      # 运行日志"
	@echo "      ├── waves/     # 波形文件"
	@echo "      ├── coverage/  # 覆盖率数据"
	@echo "      └── reports/   # 报告文件"
	@echo ""
	@echo "示例:"
	@echo "  make all TEST=smoke_test"
	@echo "  make wave TEST=smoke_test"
	@echo "=============================================="
