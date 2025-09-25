/************************************************************************
**
** NAME:        imageloader.c
**
** DESCRIPTION: CS61C Fall 2020 Project 1
**
** AUTHOR:      Dan Garcia  -  University of California at Berkeley
**              Copyright (C) Dan Garcia, 2020. All rights reserved.
**              Justin Yokota - Starter Code
**				YOUR NAME HERE
**
**
** DATE:        2020-08-15
**
**************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <string.h>
#include "imageloader.h"

// Opens a .ppm P3 image file, and constructs an Image object.
// You may find the function fscanf useful.
// Make sure that you close the file with fclose before returning.
Image *readData(char *filename)
{
	// 先创建一个image对象和读取的缓冲区
	Image *img = (Image *)malloc(sizeof(Image));
	char buf[1024];

	FILE *fp = fopen(filename, "r");
	fgets(buf, sizeof(buf), fp);						 // P3 忽略  跳过一整行
	fscanf(fp, "%" SCNu32 "%" SCNu32, &img->cols, &img->rows); // 读入行和列的宽度
	fgets(buf, sizeof(buf), fp);						// 读取第二行行末的\n
	fgets(buf, sizeof(buf), fp);						//跳过第三行
	
	uint32_t rows = img->rows;
	uint32_t cols = img->cols;

	// 用c语言malloc二维数组的方法分配内存
	img->image = (Color **)malloc(rows * sizeof(Color *));
	Color **arr = img->image;  //别名一定要在malloc之后才能加上
	if (arr == NULL)
	{
		printf("error");
	}
	for (int i = 0; i < rows; i++)
	{
		arr[i] = (Color *)malloc(cols * sizeof(Color));
		if (arr[i] == NULL)
		{
			printf("error");
		}
	}

	// 开始读取ppm文件中的像素点
	for (int i = 0; i < rows; i++)
	{
		for (int j = 0; j < cols; j++)
		{
			fscanf(fp, "%" SCNu8 "%" SCNu8 "%" SCNu8, &arr[i][j].R, &arr[i][j].G, &arr[i][j].B);
		}
	}
	
	fclose(fp);
	return img;
}

// Given an image, prints to stdout (e.g. with printf) a .ppm P3 file with the image's data.
void writeData(Image *image)
{
	// YOUR CODE HERE
	uint32_t rows = image->rows;
	uint32_t cols = image->cols;
	Color **arr = image->image;
	printf("P3\n");
	printf("%" PRIu32 " %" PRIu32 "\n", cols, rows);
	printf("255\n");
	for (int i = 0; i < rows; i++)
	{
		for (int j = 0; j < cols; j++)
		{
			printf("%3" PRIu8 " %3" PRIu8 " %3" PRIu8, arr[i][j].R, arr[i][j].G, arr[i][j].B);
			if(j != cols - 1) {
				printf("   ");
			}
		}
		printf("\n");
	}

}

// Frees an image
void freeImage(Image *image)
{
	for (int i = 0; i < image->rows; i++){
		free(image->image[i]);
	}
	free(image->image);
	free(image);
}