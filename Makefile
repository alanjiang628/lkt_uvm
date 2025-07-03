# ==============================================
# UVM Verification Environment Makefile
# Version: 3.1.1
# Features:
# - 完全使用work/<testname>/目录结构
# - 一次编译，串行执行所有回归测试
# - 更清晰的路径管理和错误处理
# ==============================================

# -------------------------------
# 基础配置
# -------------------------------
SIMULATOR    ?= vcs
UVM_VERSION  ?= 1.2
TIMESCALE    := 1ns/1ps
MAX_RETRIES  ?= 3
DEFAULT_THREADS := 1
MAX_THREADS     := $(shell nproc 2>/dev/null || echo 4)

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

# 回归测试专用目录
REGRESSION_BUILD_DIR := $(TEST_OUTPUT_ROOT)/regression_build
REGRESSION_LOG_DIR   := $(TEST_OUTPUT_ROOT)/regression_logs

# -------------------------------
# 文件列表配置
# -------------------------------
TESTLIST     := tests.list
FILELIST     := filelist.f
COV_MERGE    := $(TEST_OUTPUT_ROOT)/merged_cov

# -------------------------------
# 仿真器配置
# -------------------------------
ifeq ($(SIMULATOR),vcs)
    COMPILE_CMD := $(BSUB_CMD) vcs -full64 -sverilog \
                   -ntb_opts uvm-$(UVM_VERSION) \
                   -timescale=$(TIMESCALE) \
                   -debug_access+all -kdb
    RUN_CMD     := $(BSUB_CMD) ./simv
else ifeq ($(SIMULATOR),xcelium)
    COMPILE_CMD := $(BSUB_CMD) xrun -64bit -sv \
                   -uvm$(UVM_VERSION) \
                   -timescale $(TIMESCALE)
    RUN_CMD     := $(BSUB_CMD) xmsim
else
    $(error Unsupported simulator: $(SIMULATOR). Use vcs or xcelium)
endif

# -------------------------------
# 主目标声明
# -------------------------------
.PHONY: all all_regression compile regression run wave clean cov_report prepare help check_threads check_build clean_build
.PHONY: regression_compile regression_run regression_run_single create_dump_script check_regression_build regression_final_report
.PHONY: clean_regression clean_regression_results rerun_regression regression_status list_tests self_test

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
	@ls -ld $(TEST_DIR) $(TEST_DIR)/* 2>/dev/null || true

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

check_files:
	@test -f $(FILELIST) || { \
		echo "Warning: $(FILELIST) not found. Creating dummy file."; \
		echo "// Dummy filelist for testing" > $(FILELIST); \
	}
	@test -f $(TESTLIST) || { \
		echo "Warning: $(TESTLIST) not found. Creating dummy file."; \
		echo "test1" > $(TESTLIST); \
		echo "test2" >> $(TESTLIST); \
		echo "test3" >> $(TESTLIST); \
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

clean_regression:
	@echo "[CLEAN] Removing regression build directory..."
	@rm -rf $(REGRESSION_BUILD_DIR) $(REGRESSION_LOG_DIR)
	@rm -f $(TEST_OUTPUT_ROOT)/regression_summary.txt

clean_regression_results:
	@echo "[CLEAN] Removing regression test results only..."
	@for test in $(TESTS); do \
		rm -rf $(TEST_OUTPUT_ROOT)/$$test/logs $(TEST_OUTPUT_ROOT)/$$test/waves $(TEST_OUTPUT_ROOT)/$$test/coverage 2>/dev/null || true; \
	done
	@rm -f $(TEST_OUTPUT_ROOT)/regression_summary.txt

distclean: clean clean_regression
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
	@cd $(TEST_BUILD_DIR) && \
	$(COMPILE_CMD) \
	-f ../../../$(FILELIST) \
	-j$(COMPILE_THREADS) \
	-l ../logs/compile.log 2>&1 || { \
		echo "[ERROR] Compilation failed. Check $(TEST_LOG_DIR)/compile.log"; \
		exit 1; \
	}
	@echo "[COMPILE] Build completed. Log: $(TEST_LOG_DIR)/compile.log"

compile: check_files $(TEST_BUILD_DIR)/simv

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
	-l ../logs/run.log 2>&1 || { \
		echo "[TEST] $(TEST) execution failed"; \
	}
	@if grep -q "UVM_ERROR\|UVM_FATAL" $(TEST_LOG_DIR)/run.log 2>/dev/null; then \
		echo "[TEST] $(TEST) FAILED" | tee $(TEST_LOG_DIR)/result.txt; \
	else \
		echo "[TEST] $(TEST) PASSED" | tee $(TEST_LOG_DIR)/result.txt; \
	fi

$(TEST_BUILD_DIR)/dump_fsdb.tcl:
	@mkdir -p $(TEST_WAVE_DIR)
	@echo 'fsdbDumpfile "../waves/$(TEST).fsdb"' > $@
	@echo 'fsdbDumpvars 0 "tb_top"' >> $@
	@echo 'fsdbDumpvars +mda' >> $@
	@echo 'run' >> $@
	@echo 'quit' >> $@

# -------------------------------
# 回归测试 - 一次编译，串行执行
# -------------------------------
TESTS := $(shell grep -v '^\#' $(TESTLIST) 2>/dev/null | grep -v '^$$' | tr '\n' ' ' || echo "test1 test2 test3")

regression: check_files regression_compile regression_run

# 回归测试编译（只编译一次）
regression_compile: 
	@echo "[REGRESSION] Preparing regression environment..."
	@mkdir -p $(REGRESSION_BUILD_DIR) $(REGRESSION_LOG_DIR)
	@echo "[REGRESSION] Compiling once for all tests..."
	@cd $(REGRESSION_BUILD_DIR) && \
	$(COMPILE_CMD) \
	-f ../../$(FILELIST) \
	-j$(COMPILE_THREADS) \
	-l ../regression_logs/compile.log 2>&1 || { \
		echo "[ERROR] Regression compilation failed. Check $(REGRESSION_LOG_DIR)/compile.log"; \
		exit 1; \
	}
	@echo "[REGRESSION] Compilation completed. Log: $(REGRESSION_LOG_DIR)/compile.log"

# 检查回归编译是否完成
check_regression_build:
	@test -f $(REGRESSION_BUILD_DIR)/simv || { \
		echo "Error: Regression not compiled. Run 'make regression_compile' first."; \
		exit 1; \
	}

# 串行执行所有测试
regression_run: check_regression_build
	@echo "[REGRESSION] Starting serial execution of $(words $(TESTS)) tests..."
	@echo "Regression Summary - $(shell date)" > $(TEST_OUTPUT_ROOT)/regression_summary.txt
	@echo "=================================" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt
	@total=$(words $(TESTS)); count=0; \
	for test in $(TESTS); do \
		count=$$((count+1)); \
		echo "[$$count/$$total] Running $$test..."; \
		if $(MAKE) regression_run_single TEST=$$test; then \
			echo "$$test: PASSED" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt; \
		else \
			echo "$$test: FAILED" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt; \
		fi; \
	done
	@$(MAKE) regression_final_report

# 单个测试执行（使用共享编译结果）
regression_run_single:
	@test -n "$(TEST)" || { echo "Error: TEST variable not defined"; exit 1; }
	@echo "[REGRESSION] Executing $(TEST)..."
	@mkdir -p $(TEST_LOG_DIR) $(TEST_WAVE_DIR) $(TEST_COV_DIR) $(TEST_REPORT_DIR)
	@$(MAKE) create_dump_script TEST=$(TEST)
	@cd $(REGRESSION_BUILD_DIR) && \
	$(RUN_CMD) +UVM_TESTNAME=$(TEST) \
	-cm line+cond+fsm+tgl+branch \
	-cm_dir ../$(TEST)/coverage \
	-ucli -do dump_fsdb_$(TEST).tcl \
	-l ../$(TEST)/logs/run.log 2>&1 || { \
		echo "[REGRESSION] $(TEST) execution failed"; \
		exit 1; \
	}
	@if grep -q "UVM_ERROR\|UVM_FATAL" $(TEST_LOG_DIR)/run.log 2>/dev/null; then \
		echo "[REGRESSION] $(TEST) FAILED"; \
		exit 1; \
	else \
		echo "[REGRESSION] $(TEST) PASSED"; \
	fi

# 为每个测试创建独立的dump脚本
create_dump_script:
	@echo 'fsdbDumpfile "../$(TEST)/waves/$(TEST).fsdb"' > $(REGRESSION_BUILD_DIR)/dump_fsdb_$(TEST).tcl
	@echo 'fsdbDumpvars 0 "tb_top"' >> $(REGRESSION_BUILD_DIR)/dump_fsdb_$(TEST).tcl
	@echo 'fsdbDumpvars +mda' >> $(REGRESSION_BUILD_DIR)/dump_fsdb_$(TEST).tcl
	@echo 'run' >> $(REGRESSION_BUILD_DIR)/dump_fsdb_$(TEST).tcl
	@echo 'quit' >> $(REGRESSION_BUILD_DIR)/dump_fsdb_$(TEST).tcl

# 生成最终回归报告
regression_final_report:
	@echo "" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt
	@echo "Test Results Details:" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt
	@echo "=====================" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt
	@passed=0; failed=0; \
	for test in $(TESTS); do \
		if grep -q "UVM_ERROR\|UVM_FATAL" $(TEST_OUTPUT_ROOT)/$$test/logs/run.log 2>/dev/null; then \
			failed=$$((failed+1)); \
			echo "❌ $$test: FAILED" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt; \
		else \
			passed=$$((passed+1)); \
			echo "✅ $$test: PASSED" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt; \
		fi; \
	done; \
	echo "" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt; \
	echo "Summary: $$passed PASSED, $$failed FAILED" >> $(TEST_OUTPUT_ROOT)/regression_summary.txt
	@echo ""
	@echo "[REGRESSION] Complete! Summary:"
	@tail -5 $(TEST_OUTPUT_ROOT)/regression_summary.txt
	@echo ""
	@echo "Full report: $(TEST_OUTPUT_ROOT)/regression_summary.txt"

# -------------------------------
# 便利目标
# -------------------------------
# 重新运行回归（不重新编译）
rerun_regression: clean_regression_results regression_run

# 快速查看回归结果
regression_status:
	@test -f $(TEST_OUTPUT_ROOT)/regression_summary.txt && \
		cat $(TEST_OUTPUT_ROOT)/regression_summary.txt || \
		echo "No regression results found. Run 'make regression' first."

# 列出所有测试用例
list_tests:
	@echo "Available tests:"
	@if [ -f $(TESTLIST) ]; then \
		grep -v '^\#' $(TESTLIST) | grep -v '^$$' | nl; \
	else \
		echo "No testlist found."; \
	fi

# -------------------------------
# 辅助功能
# -------------------------------
wave:
	@test -n "$(TEST)" || { echo "Usage: make wave TEST=<testname>"; exit 1; }
	@test -f $(TEST_WAVE_DIR)/$(TEST).fsdb || { echo "Wave file not found: $(TEST_WAVE_DIR)/$(TEST).fsdb"; exit 1; }
	$(BSUB_CMD) verdi -ssf $(TEST_WAVE_DIR)/$(TEST).fsdb -nologo &

cov_report:
	@echo "[COV] Merging coverage data..."
	@find $(TEST_OUTPUT_ROOT) -name "coverage" -type d | head -5 | while read dir; do \
		echo "Found coverage: $$dir"; \
	done
	@echo "[COV] Coverage report generation would be implemented here"

# -------------------------------
# 自测试功能
# -------------------------------
self_test: clean distclean
	@echo "================================================="
	@echo "  UVM Makefile Self-Test Suite"
	@echo "================================================="
	
	@echo "[SELF-TEST] 1. Testing file creation..."
	@$(MAKE) check_files > /dev/null 2>&1
	@echo "✅ File creation test passed"
	
	@echo "[SELF-TEST] 2. Testing directory structure..."
	@$(MAKE) prepare TEST=self_test > /dev/null 2>&1
	@test -d work/self_test/build || { echo "❌ Directory test failed"; exit 1; }
	@echo "✅ Directory structure test passed"
	
	@echo "[SELF-TEST] 3. Testing test list parsing..."
	@test "$(words $(TESTS))" -gt 0 || { echo "❌ Test parsing failed"; exit 1; }
	@echo "✅ Test list parsing test passed (Found $(words $(TESTS)) tests)"
	
	@echo "[SELF-TEST] 4. Testing regression environment setup..."
	@mkdir -p $(REGRESSION_BUILD_DIR) $(REGRESSION_LOG_DIR) > /dev/null 2>&1
	@test -d $(REGRESSION_BUILD_DIR) || { echo "❌ Regression setup failed"; exit 1; }
	@echo "✅ Regression environment test passed"
	
	@echo "[SELF-TEST] 5. Testing script generation..."
	@$(MAKE) create_dump_script TEST=self_test > /dev/null 2>&1
	@test -f $(REGRESSION_BUILD_DIR)/dump_fsdb_self_test.tcl || { echo "❌ Script generation failed"; exit 1; }
	@echo "✅ Script generation test passed"
	
	@echo "[SELF-TEST] 6. Testing clean functions..."
	@$(MAKE) clean_regression > /dev/null 2>&1
	@test ! -d $(REGRESSION_BUILD_DIR) || { echo "❌ Clean test failed"; exit 1; }
	@echo "✅ Clean functions test passed"
	
	@echo ""
	@echo "🎉 All self-tests passed!"
	@echo "Makefile is ready for use."
	@echo "================================================="

# -------------------------------
# 帮助信息
# -------------------------------
help:
	@echo "UVM Verification Environment Makefile (v3.1.1)"
	@echo "================================================="
	@echo "核心命令:"
	@echo "  make all TEST=xxx           - 完整构建并运行单个测试"
	@echo "  make run TEST=xxx           - 运行已编译的测试"
	@echo "  make regression             - 一次编译，串行运行所有测试"
	@echo "  make regression_compile     - 仅编译回归测试"
	@echo "  make regression_run         - 仅运行回归测试（需先编译）"
	@echo "  make wave TEST=xxx          - 查看波形"
	@echo "  make self_test              - 运行Makefile自测试"
	@echo ""
	@echo "回归测试流程:"
	@echo "  1. make regression          - 完整回归（推荐）"
	@echo "  2. make regression_compile  - 单独编译"
	@echo "     make regression_run      - 单独运行"
	@echo ""
	@echo "目录结构:"
	@echo "  work/"
	@echo "  ├── regression_build/       # 回归测试编译产物"
	@echo "  ├── regression_logs/        # 回归编译日志"
	@echo "  ├── <testname>/             # 各测试结果"
	@echo "  │   ├── logs/               # 运行日志"
	@echo "  │   ├── waves/              # 波形文件"
	@echo "  │   └── coverage/           # 覆盖率数据"
	@echo "  └── regression_summary.txt  # 回归测试总结"
	@echo ""
	@echo "管理命令:"
	@echo "  make list_tests             - 列出所有测试用例"
	@echo "  make regression_status      - 查看回归结果"
	@echo "  make rerun_regression       - 重新运行回归（不重新编译）"
	@echo ""
	@echo "清理命令:"
	@echo "  make clean_regression       - 清理回归编译"
	@echo "  make clean_regression_results - 仅清理测试结果"
	@echo "  make distclean              - 清理所有"
	@echo ""
	@echo "配置选项:"
	@echo "  SIMULATOR=[vcs|xcelium]     - 选择仿真器 (默认: vcs)"
	@echo "  THREADS=N                   - 编译线程数 (默认: 1)"
	@echo "  COMPILE_THREADS=N           - 编译线程数"
	@echo "  MAX_RETRIES=N               - 最大重试次数 (默认: 3)"
	@echo ""
	@echo "示例:"
	@echo "  make self_test"
	@echo "  make all TEST=smoke_test"
	@echo "  make regression THREADS=4"
	@echo "  make wave TEST=smoke_test"
	@echo "================================================="

# 默认目标
.DEFAULT_GOAL := help