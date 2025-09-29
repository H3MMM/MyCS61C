#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include "lfsr.h"

uint16_t getBit(uint16_t *reg, int n);

void lfsr_calculate(uint16_t *reg)
{
    // 取最低位
    uint16_t num = getBit(reg, 0);
    num ^= getBit(reg, 2);
    num ^= getBit(reg, 3);
    num ^= getBit(reg, 5);
    // 右移一位
    *reg >>= 1;
    // 把运算结果放到第1位，因右移会在最高位补0，所以不用额外清零操作
    *reg |= (num << 15);
}

uint16_t getBit(uint16_t *reg, int n)
{
    return (*reg >> n) & 1;
}
