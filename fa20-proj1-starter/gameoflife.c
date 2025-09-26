/************************************************************************
**
** NAME:        gameoflife.c
**
** DESCRIPTION: CS61C Fall 2020 Project 1
**
** AUTHOR:      Justin Yokota - Starter Code
**				YOUR NAME HERE
**
**
** DATE:        2020-08-23
**
**************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include "imageloader.h"

Color *evaluateOneCell(Image *image, int row, int col, uint32_t rule);
uint8_t convertR(uint8_t colorR, char bit[], Color neighbour[], char binRule[]);
uint8_t convertG(uint8_t colorG, char bit[], Color neighbour[], char binRule[]);
uint8_t convertB(uint8_t colorB, char bit[], Color neighbour[], char binRule[]);
uint32_t charToUint32(const char bin[]);
uint8_t charToUint8(char bin[]);
void ruleToBinary(uint32_t rule, char bin[]);
Image *life(Image *image, uint32_t rule);
const int ruleLength = 18;

// Determines what color the cell at the given row/col should be. This function allocates space for a new Color.
// Note that you will need to read the eight neighbors of the cell in question. The grid "wraps", so we treat the top row as adjacent to the bottom row
// and the left column as adjacent to the right column.
Color *evaluateOneCell(Image *image, int row, int col, uint32_t rule)
{
	Color **arr = image->image;
	uint32_t maxcols = image->cols;
	uint32_t maxrows = image->rows;
	char binRule[33];
	Color *nextColor = (Color *)malloc(sizeof(Color)); // 用于存储判断结果

	// 把rule转为一个二进制char[]
	// TODO:检查这个binary函数
	ruleToBinary(rule, binRule);//现在binRule是32位

	// 对单个元素开始解析
	// 获取其对应颜色块
	Color color = arr[row][col];
	Color neighbour[9];
	int pos = 0;
	// 获取该颜色块周围邻居
	for (int i = row - 1; i <= row + 1; i++)
	{
		for (int j = col - 1; j <= col + 1; j++)
		{
			if (i == row && j == col)
			{
				continue;
			}
			neighbour[pos++] = arr[(i + maxrows) % maxrows][(j + maxcols) % maxcols];
		}
	}
	char bit[10];
	nextColor->R = convertR(color.R, bit, neighbour, binRule);
	nextColor->G = convertG(color.G, bit, neighbour, binRule);
	nextColor->B = convertB(color.B, bit, neighbour, binRule);
	return nextColor;
}

uint8_t convertR(uint8_t colorR, char bit[], Color neighbour[], char binRule[])
{
	int binRuleStart = 32 - ruleLength;  //算出binrule数组第几位才是rule的真正起始位置（删掉前导0）
	for (int i = 7; i >= 0; i--)
	{
		// 遍历颜色的8位

		// 用color >> i & 1的方法获取第i位
		char c = (colorR >> i) & 1;
		int liveCount = 0;
		for (int j = 0; j < 8; j++)
		{
			// 开始循环，遍历八个邻居
			if ((neighbour[j].R >> i) & 1)
			{
				liveCount++;
			}
		}
		// 如果c本轮是活细胞
		if (c == 1)
		{
			if (binRule[binRuleStart + liveCount] == '1')
			{
				bit[7 - i] = '1';
			}
			else
			{
				bit[7 - i] = '0';
			}
		}
		// 如果c本轮是死细胞
		else
		{
			if (binRule[binRuleStart + liveCount + (ruleLength / 2)] == '1')
			{
				bit[7 - i] = '1';
			}
			else
			{
				bit[7 - i] = '0';
			}
		}
	}
	bit[8] = '\0';
	return charToUint8(bit);
}

uint8_t convertG(uint8_t colorG, char bit[], Color neighbour[], char binRule[])
{
	int binRuleStart = 32 - ruleLength; // 算出binrule数组第几位才是rule的真正起始位置（删掉前导0）
	for (int i = 7; i >= 0; i--)
	{
		// 遍历颜色的8位

		// 用color >> i & 1的方法获取第i位
		char c = (colorG >> i) & 1;
		int liveCount = 0;
		for (int j = 0; j < 8; j++)
		{
			// 开始循环，遍历八个邻居
			if ((neighbour[j].G >> i) & 1)
			{
				liveCount++;
			}
		}
		// 如果c本轮是活细胞
		if (c == 1)
		{
			if (binRule[binRuleStart + liveCount] == '1')
			{
				bit[7 - i] = '1';
			}
			else
			{
				bit[7 - i] = '0';
			}
		}
		// 如果c本轮是死细胞
		else
		{
			if (binRule[binRuleStart + liveCount + (ruleLength / 2)] == '1')
			{
				bit[7 - i] = '1';
			}
			else
			{
				bit[7 - i] = '0';
			}
		}
	}
	bit[8] = '\0';
	return charToUint8(bit);
}

uint8_t convertB(uint8_t colorB, char bit[], Color neighbour[], char binRule[])
{
	int binRuleStart = 32 - ruleLength; // 算出binrule数组第几位才是rule的真正起始位置（删掉前导0）
	for (int i = 7; i >= 0; i--)
	{
		// 遍历颜色的8位

		// 用color >> i & 1的方法获取第i位
		char c = (colorB >> i) & 1;
		int liveCount = 0;
		for (int j = 0; j < 8; j++)
		{
			// 开始循环，遍历八个邻居
			if ((neighbour[j].B >> i) & 1)
			{
				liveCount++;
			}
		}
		// 如果c本轮是活细胞
		if (c == 1)
		{
			if (binRule[binRuleStart + liveCount] == '1')
			{
				bit[7 - i] = '1';
			}
			else
			{
				bit[7 - i] = '0';
			}
		}
		// 如果c本轮是死细胞
		else
		{
			if (binRule[binRuleStart + liveCount + (ruleLength / 2)] == '1')
			{
				bit[7 - i] = '1';
			}
			else
			{
				bit[7 - i] = '0';
			}
		}
	}
	bit[8] = '\0';
	return charToUint8(bit);
}

// uint32_t charToUint32(const char bin[])
// {
// 	long result = strtol(bin, NULL, 0);
// 	return (uint32_t)result;
// }

uint32_t charToUint32(const char bin[])
{
	// 如果是0x开头，就按16进制解析
	if (bin[0] == '0' && (bin[1] == 'x' || bin[1] == 'X'))
	{
		return (uint32_t)strtol(bin, NULL, 16);
	}
	// 如果只包含'0'和'1'，就按二进制解析
	int isBinary = 1;
	for (int i = 0; bin[i] != '\0'; i++)
	{
		if (bin[i] != '0' && bin[i] != '1')
		{
			isBinary = 0;
			break;
		}
	}
	if (isBinary)
	{
		return (uint32_t)strtol(bin, NULL, 2);
	}
	// 否则就按十进制解析
	return (uint32_t)strtol(bin, NULL, 10);
}

uint8_t charToUint8(char bin[])
{	
	long result = strtol(bin, NULL, 2);
	return (uint8_t)result;
}

// void ruleToBinary(uint32_t rule, char bin[])
// {
// 	int pos = 0;
// 	int started = 0;
// 	for (int i = 0; i < 31; i++)
// 	{
// 		char bit = rule & (1u << i);
// 		if (!started && bit)
// 		{
// 			started = 1; // 去掉前导0
// 		}
// 		if (started)
// 		{
// 			bin[pos++] = bit ? '1' : '0';
// 		}
// 	}
// 	bin[pos++] = '\0';
// }

void ruleToBinary(uint32_t rule, char bin[])
{
	for (int i = 31; i >= 0; i--)
	{
		bin[31 - i] = ((rule >> i) & 1) ? '1' : '0';
	}
	bin[32] = '\0'; // 字符串结束符
	
}

// The main body of Life; given an image and a rule, computes one iteration of the Game of Life.
// You should be able to copy most of this from steganography.c
Image *life(Image *image, uint32_t rule)
{
	uint32_t rows = image->rows;
	uint32_t cols = image->cols;
	// malloc一个新的image对象
	Image *newImg = (Image *)malloc(sizeof(Image));
	newImg->image = (Color **)malloc(rows * sizeof(Color *));
	for (int i = 0; i < rows; i++)
	{
		newImg->image[i] = (Color *)malloc(cols * sizeof(Color));
	}
	newImg->cols = cols;
	newImg->rows = rows;

	// 开始计算下一代的结果
	Color **newArr = newImg->image;
	for (int i = 0; i < rows; i++)
	{
		for (int j = 0; j < cols; j++)
		{
			Color *color = evaluateOneCell(image, i, j, rule);
			newArr[i][j] = *color;
			free(color);
		}
	}
	return newImg;
}

/*
Loads a .ppm from a file, computes the next iteration of the game of life, then prints to stdout the new image.

argc stores the number of arguments.
argv stores a list of arguments. Here is the expected input:
argv[0] will store the name of the program (this happens automatically).
argv[1] should contain a filename, containing a .ppm.
argv[2] should contain a hexadecimal number (such as 0x1808). Note that this will be a string.
You may find the function strtol useful for this conversion.
If the input is not correct, a malloc fails, or any other error occurs, you should exit with code -1.
Otherwise, you should return from main with code 0.
Make sure to free all memory before returning!

You may find it useful to copy the code from steganography.c, to start.
*/
int main(int argc, char **argv)
{
	// YOUR CODE HERE
	Image *image;
	Image *nextImage;
	image = readData(argv[1]);
	uint32_t rule = charToUint32(argv[2]);
	nextImage = life(image, rule);
	writeData(nextImage);
	freeImage(image);
	freeImage(nextImage);
	return 0;
}
