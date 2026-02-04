#include "transpose.h"

/* The naive transpose function as a reference. */
void transpose_naive(int n, int blocksize, int *dst, int *src) {
    for (int x = 0; x < n; x++) {
        for (int y = 0; y < n; y++) {
            dst[y + x * n] = src[x + y * n];
        }
    }
}

/* Implement cache blocking below. You should NOT assume that n is a
 * multiple of the block size. */
void transpose_blocking(int n, int blocksize, int *dst, int *src) {
    //外层两个循环，遍历每一个块
    //怎么遍历呢？每次递增blocksize，直到达到边界n
    for (int i = 0; i < n;i+=blocksize) {
        for (int j = 0; j < n;j += blocksize) {
            //内层循环开始转置操作
            int maxX = (i + blocksize > n) ? n : (i + blocksize);
            int maxY = (j + blocksize > n) ? n : (j + blocksize);
            for (int x = i; x < maxX;x++){
                for (int y = j;y<maxY;y++){
                    //注意这里要乘一个n而不是blocksize，因为二维数组实际上是一维数组的坐标条跳跃
                    dst[y + x * n] = src[x + y * n];
                }
            }
        }
    }
}
