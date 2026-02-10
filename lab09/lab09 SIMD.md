本节的任务是**对下面这两个函数SIMD化**，函数目的是**找到数组中大于等于128的数加起来求总和**

```c
long long int sum(int vals[NUM_ELEMS]) {
	clock_t start = clock();

	long long int sum = 0;
	for(unsigned int w = 0; w < OUTER_ITERATIONS; w++) {
		for(unsigned int i = 0; i < NUM_ELEMS; i++) {
			if(vals[i] >= 128) {
				sum += vals[i];
			}
		}
	}
	clock_t end = clock();
	printf("Time taken: %Lf s\n", (long double)(end - start) / CLOCKS_PER_SEC);
	return sum;
}

long long int sum_unrolled(int vals[NUM_ELEMS]) {
	clock_t start = clock();
	long long int sum = 0;

	for(unsigned int w = 0; w < OUTER_ITERATIONS; w++) {
		for(unsigned int i = 0; i < NUM_ELEMS / 4 * 4; i += 4) {
			if(vals[i] >= 128) sum += vals[i];
			if(vals[i + 1] >= 128) sum += vals[i + 1];
			if(vals[i + 2] >= 128) sum += vals[i + 2];
			if(vals[i + 3] >= 128) sum += vals[i + 3];
		}

		//This is what we call the TAIL CASE
		//For when NUM_ELEMS isn't a multiple of 4
		//NONTRIVIAL FACT: NUM_ELEMS / 4 * 4 is the largest multiple of 4 less than NUM_ELEMS
		for(unsigned int i = NUM_ELEMS / 4 * 4; i < NUM_ELEMS; i++) {
			if (vals[i] >= 128) {
				sum += vals[i];
			}
		}
	}
	clock_t end = clock();
	printf("Time taken: %Lf s\n", (long double)(end - start) / CLOCKS_PER_SEC);
	return sum;
}
```

# 思路是什么

SIMD本质是把几个数变成向量，一起算，所以思路就是

1. 四个32位int组合成一个__m128i向量
2. 和四个127组成的_127向量相比较得到掩码(具体见下文代码)
3. 原数和掩码相与得到过滤后的原数,四个通道过滤后的原数同时相加到sumVector
4. 提取sumVector的向量到tmp数组，遍历tmp数组进行相加
5. tail case 收尾处理剩下不足4位的数

```c
long long int sum_simd(int vals[NUM_ELEMS]) {
	clock_t start = clock();
	__m128i _127 = _mm_set1_epi32(127);		// This is a vector with 127s in it... Why might you need this?
	long long int result = 0;				   // This is where you should put your final result!
	/* DO NOT DO NOT DO NOT DO NOT WRITE ANYTHING ABOVE THIS LINE. */
	
	for(unsigned int w = 0; w < OUTER_ITERATIONS; w++) {
		/* YOUR CODE GOES HERE */
		__m128i sumVector= _mm_setzero_si128(); 
		int i = 0;
		for(; i < NUM_ELEMS / 4 * 4; i+=4) {
			//第一步：四个数拼成一个_m128i
			__m128i data;
			//不要用_mm_set_si128,CPU会执行加四个标量的操作，SIMD优势尽失
			data = _mm_loadu_si128((__m128i*)&vals[i]);
			// 第二步：把它跟_127比较,大于得到全1，小于等于得到全0
			// 再跟原来的数相与，全1保留原数，全0得0，这样就实现了大于则加起来，小于则舍去
			__m128i mask = _mm_cmpgt_epi32(data, _127);
			__m128i filteredData = _mm_and_si128(data, mask);
			// 第三步：累加四个通道的值
			// Q:这里为什么不是每读取四个val就清零一次？
			// A:这里的原理是把原来单个值累加，变成把四个int向量化，变成四个通道
			// 一直对四个通道累加，等循环结束再一起转化为int数组，把四个通道的累加和加起来得到最终result
			// 如果每读取四个val就清零一次，那么sumVector只保留的最后四个值
			sumVector = _mm_add_epi32(sumVector, filteredData);
		}

		int tmp[4];
		_mm_storeu_si128((__m128i *)tmp, sumVector);
		result += tmp[0] + tmp[1] + tmp[2] + tmp[3]; 
		/* You'll need a tail case. */
		for(;i < NUM_ELEMS;i++) {
			if (vals[i] >= 128) {
				result += vals[i];
			}
		}
		
	}
	clock_t end = clock();
	printf("Time taken: %Lf s\n", (long double)(end - start) / CLOCKS_PER_SEC);
	return result;
}
```



# 如何把四个32位的int拼成一个128位向量

```c
__m128i data;
//不要用_mm_set_si128,CPU会执行加四个标量的操作，SIMD优势尽失
data = _mm_loadu_si128((__m128i*)&vals[i]);
```

直接取vals[i]这个地址往后的128位

之前写的是

```c
data = _mm_set_epi32(vals[i + 3],vals[i + 2],vals[i + 1],vals[i]);
```

发现非常慢

# 为什么用_mm_set_epi32拼向量很慢

你现在的 `sum_simd` **慢的根本原因只有一个**：

> **你用 `_mm_set_epi32` 在“手动拼向量”，把 SIMD 退化成了 4 次标量 load**

这一步直接把 SIMD 的优势全杀掉了。

------

## 一、为什么 `_mm_set_epi32` 会让 SIMD 变慢（关键）

你现在写的是：

```c
__m128i data;
data = _mm_set_epi32(
    vals[i + 3],
    vals[i + 2],
    vals[i + 1],
    vals[i]
);
```

### 这在 CPU 眼里意味着什么？

等价于：

```c
int a = vals[i];
int b = vals[i+1];
int c = vals[i+2];
int d = vals[i+3];
把 a b c d 塞进寄存器
```

也就是说：

- 4 次 **独立的内存 load**
- 再 1 次 pack
- 编译器**无法把它当成一次向量 load**

而 SIMD 的正确姿势是：

> **一次 load 128 bit = 一条指令读 4 个 int**

------

## 二、正确的 SIMD load 应该长这样

### 你应该用的是这个：

```c
__m128i data = _mm_loadu_si128((__m128i*)&vals[i]);
```

这条指令的含义是：

- 从内存一次性读 16 字节
- 自动变成 `[vals[i], vals[i+1], vals[i+2], vals[i+3]]`

这才是真正的 SIMD。

------

## 三、为什么这一个点就能决定 2× 还是 <1×

### 你现在的瓶颈

- `set_epi32` → 4 次 load + pack
- SIMD 算术是快的
- **内存访问完全没并行**

### 改成 `loadu` 之后

- 1 次 load
- 4 个 int 并行比较 + 并行加
- 内层循环指令数直接砍半以上

这也是为什么助教文档里**强烈暗示你用 `_mm_loadu_si128`**。





# 比较的那一步是什么原理？

好，这一步确实是 **SIMD 新手最容易卡住的点**，我们慢慢来，把它拆到“按位”层面，你就懂了。

------

## 一、先看标量世界在干嘛

原来的代码是：

```c
if (x > 127)
    sum += x;
```

也就是说：

- 条件成立：加 x
- 条件不成立：加 0（啥也不干）

你可以把它理解成：

```c
sum += (x > 127 ? x : 0);
```

------

## 二、SIMD 世界没有 if，只能“算出来”

SIMD 里 **不能对每个元素写 if**，所以我们用一个技巧：

> 用“掩码（mask）”把不该加的数变成 0

------

## 三、`_mm_cmpgt_epi32` 到底返回了啥？

```c
__m128i mask = _mm_cmpgt_epi32(x, _127);
```

这是**重点中的重点**。

假设 `x` 里是 4 个 int：

```
x = [ 200, 100, 130, 50 ]
```

比较 `x > 127`，结果不是 1 或 0，而是：

```
mask = [
  0xffffffff,   // 200 > 127  成立
  0x00000000,   // 100 > 127  不成立
  0xffffffff,   // 130 > 127  成立
  0x00000000    // 50  > 127  不成立
]
```

也就是：

- 成立 → **32 位全 1**
- 不成立 → **32 位全 0**

------

## 四、`x & mask` 在干嘛？

```c
masked_x = x & mask;
```

这是 **按位与**，逐元素算。

### 对刚才的例子：

```
x       = [ 200, 100, 130, 50 ]
mask    = [ 0xffffffff, 0x00000000, 0xffffffff, 0x00000000 ]
```

逐位 AND：

```
masked_x =
[
  200 & 0xffffffff = 200,
  100 & 0x00000000 = 0,
  130 & 0xffffffff = 130,
  50  & 0x00000000 = 0
]
```

结果就是：

```
masked_x = [ 200, 0, 130, 0 ]
```

**神奇吧？**
这一步就等价于：

```c
(x > 127 ? x : 0)
```

但这是 **4 个元素同时完成的**。

------

## 五、`sum_vec += masked_x` 就很好理解了

```c
sum_vec = _mm_add_epi32(sum_vec, masked_x);
```

等价于：

```c
sum_vec[0] += (x0 > 127 ? x0 : 0);
sum_vec[1] += (x1 > 127 ? x1 : 0);
sum_vec[2] += (x2 > 127 ? x2 : 0);
sum_vec[3] += (x3 > 127 ? x3 : 0);
```

**完全复刻原来的 if 逻辑，只是一次干 4 个。**

------

## 六、一句话记忆法（考试 / Lab 都好用）

> SIMD 里没有 if
> **用 compare 造 mask，用 AND 把不合法的值变成 0**

公式级记忆：

```
if (cond) sum += x
↓
mask = (cond ? 0xffffffff : 0)
sum += x & mask
```

------

## 七、为什么不用乘法？

你可能会想：

```c
sum += x * (x > 127);
```

原因是：

- SIMD 没有“返回 0/1 的比较”
- 比较直接给你 **全 1 / 全 0**
- AND 是最便宜、最快的做法

------

如果你愿意，下一步我可以：

- 用 **画内存格子的方式**帮你再“可视化一轮”
- 或直接把你 `simd.c` 中那几行逐行解释一遍

你说一句就行。



# SIMD怎么做循环展开？

简单！一个向量读4个int，我一次做4个向量不就完了

```c
long long int sum_simd_unrolled(int vals[NUM_ELEMS]) {
	clock_t start = clock();
	__m128i _127 = _mm_set1_epi32(127);
	long long int result = 0;
	for(unsigned int w = 0; w < OUTER_ITERATIONS; w++) {
		/* COPY AND PASTE YOUR sum_simd() HERE */
		/* MODIFY IT BY UNROLLING IT */
		__m128i sumVector = _mm_setzero_si128();
		int i = 0;
		for (; i + 15 < NUM_ELEMS; i += 16)
		{
			// 第一步：四个数拼成一个_m128i
			__m128i data1 = _mm_setzero_si128();
			__m128i data2 = _mm_setzero_si128();
			__m128i data3 = _mm_setzero_si128();
			__m128i data4 = _mm_setzero_si128();

			data1 = _mm_loadu_si128((__m128i *)&vals[i]);
			data2 = _mm_loadu_si128((__m128i *)&vals[i+4]);
			data3 = _mm_loadu_si128((__m128i *)&vals[i+8]);
			data4 = _mm_loadu_si128((__m128i *)&vals[i+12]);
			
			// 第二步：把它跟_127比较,大于得到全1，小于等于得到全0
			// 再跟原来的数相与，全1保留原数，全0得0，这样就实现了大于则加起来，小于则舍去
			__m128i mask1 = _mm_cmpgt_epi32(data1, _127);
			__m128i mask2 = _mm_cmpgt_epi32(data2, _127);
			__m128i mask3 = _mm_cmpgt_epi32(data3, _127);
			__m128i mask4 = _mm_cmpgt_epi32(data4, _127);

			__m128i filteredData1 = _mm_and_si128(data1, mask1);
			__m128i filteredData2 = _mm_and_si128(data2, mask2);
			__m128i filteredData3 = _mm_and_si128(data3, mask3);
			__m128i filteredData4 = _mm_and_si128(data4, mask4);
			// 第三步：累加四个通道的值
			// Q:这里为什么不是每读取四个val就清零一次？
			// A:这里的原理是把原来单个值累加，变成把四个int向量化，变成四个通道
			// 一直对四个通道累加，等循环结束再一起转化为int数组，把四个通道的累加和加起来得到最终result
			// 如果每读取四个val就清零一次，那么sumVector只保留的最后四个值
			sumVector = _mm_add_epi32(sumVector, filteredData1);
			sumVector = _mm_add_epi32(sumVector, filteredData2);
			sumVector = _mm_add_epi32(sumVector, filteredData3);
			sumVector = _mm_add_epi32(sumVector, filteredData4);
		}
		for (; i + 3 < NUM_ELEMS; i+=4) {
			__m128i d = _mm_loadu_si128((__m128i*)&vals[i]);
			__m128i m = _mm_cmpgt_epi32(d, _127);
			sumVector = _mm_add_epi32(sumVector,_mm_and_si128(d,m));
		}
		int tmp[4];
		_mm_storeu_si128((__m128i *)tmp, sumVector);
		result += tmp[0] + tmp[1] + tmp[2] + tmp[3];
		for (; i < NUM_ELEMS; i++)
		{
			if(vals[i] >= 128) {
				result += vals[i];
			}
		}
		/* You'll need 1 or maybe 2 tail cases here. */
	}
	clock_t end = clock();
	printf("Time taken: %Lf s\n", (long double)(end - start) / CLOCKS_PER_SEC);
	return result;
}
```

注意这里有两个tail case：

1. 满4但未满16
2. 未满4

第一种还能拼成向量接着凹