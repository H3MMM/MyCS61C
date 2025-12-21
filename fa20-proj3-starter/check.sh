#!/bin/bash

# 获取参数，如果没有传参，默认使用 "addi"
TEST_NAME=${1:-addi}

echo "========================================"
echo "   Debugging CPU Test: $TEST_NAME"
echo "========================================"

# 1. 运行 Test Runner
# 注意：这通常会运行这一组的所有测试。如果 test_runner 支持过滤特定测试(比如 -t)，建议加上以加快速度
echo "[1/4] Running test runner..."
python3 test_runner.py part_b pipelined

# 2. 检查目录是否存在，防止报错
TARGET_DIR="tests/part_b/pipelined"
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Directory $TARGET_DIR not found!"
    exit 1
fi

# 进入目录
cd "$TARGET_DIR" || exit

# 3. 定义文件名变量
STUDENT_OUT="student_output/cpu-${TEST_NAME}-student.out"
REF_OUT="reference_output/cpu-${TEST_NAME}-ref.out"

# 检查输出文件是否生成了
if [ ! -f "$STUDENT_OUT" ]; then
    echo "Error: Student output file '$STUDENT_OUT' not found."
    echo "Did the test runner actually run the '$TEST_NAME' test?"
    exit 1
fi

# 4. 转换 Binary 为 Hex
echo "[2/4] Converting output to Hex..."
python3 binary_to_hex_cpu.py "$STUDENT_OUT" > s.out
python3 binary_to_hex_cpu.py "$REF_OUT" > r.out

# 5. 进行 Diff 对比
echo "[3/4] Comparing results..."
DIFF_OUTPUT=$(diff r.out s.out)

# 6. 输出结果
echo "[4/4] Result:"
if [ -z "$DIFF_OUTPUT" ]; then
    # 绿色文字显示通过
    echo -e "\033[32m  🎉 PASS: $TEST_NAME matches reference! \033[0m"
else
    # 红色文字显示失败，并打印具体的 diff
    echo -e "\033[31m  ❌ FAIL: $TEST_NAME differs from reference! \033[0m"
    echo "---------------- Diff Output ----------------"
    diff r.out s.out
    echo "---------------------------------------------"
fi
