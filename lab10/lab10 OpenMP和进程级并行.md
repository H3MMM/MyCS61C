# OpenMP是什么？

用最直白的话来总结OpenMP的内容就是：

OpenMP是C语言的一个实现并行计算的库，使用方法很简单，在循环前面加上一句注释即可：

```c
void v_add_naive(double *x, double *y, double *z)
{
#pragma omp parallel
  {
    for (int i = 0; i < ARRAY_SIZE; i++)
      z[i] = x[i] + y[i];
  }
}
```

其内置了对for循环的优化，可以在parallel后加上for，即可非常方便的优化for循环的并行计算

```c
#pragma omp parallel
  {
    for (int i = 0; i < ARRAY_SIZE; i++)
      z[i] = x[i] + y[i];
  }
```

还有一个知识点，并行计算中的同步操作，比如多个线程需要同时写入一个数，绝对要避免这种事的发生

OpenMP提供了另一句简单的指令来指定以下操作是原子操作

```c
#pragma omp parallel
{
    int id = omp_get_thread_num();
    for (int i=id; i<num_steps; i+=NUM_THREADS) {
        double x = (i+0.5)*step;
        sum[id] += 4.0*step/(1.0+x*x);
    }
    #pragma omp critical  
    pi += sum[id];
}
```



# 关于并行代码要注意的地方

```c
double dotp_manual_optimized(double* x, double* y, int arr_size) {
  double global_sum = 0.0;
  int threads = omp_get_num_threads();
  double tmp[threads]; 
  for (int i = 0; i < threads; i++) {
    tmp[i] = 0.0;
  }
  #pragma omp parallel
  {
    int curThread = omp_get_thread_num();
    #pragma omp for
    for (int i = 0; i < arr_size; i++)
    {
      tmp[curThread] += x[i] * y[i];
    }
  }
  
  for(int i = 0;i < threads; i++) {
    global_sum += tmp[i];
  }
  return global_sum;
}
```

这段代码乍一看没有什么问题，但是注意，omp_get_num_threads()这个函数没有写在parallel的并行部分里，所以获取的实际是串行部分的线程数，那么问题又来了，如果把threads放在parallel部分中，难道每个线程都要一个tmp数组？

实际上，在解决这种可能导致数据竞争的问题上，我们一般采用“本地变量+critical原子操作”来完成

```c
// 在并行区域中获取线程数，而不是在并行区域外
  #pragma omp parallel
  {
    int threads = omp_get_num_threads();  // 在并行区域中获取正确线程数
    int curThread = omp_get_thread_num();
    // 为每个线程分配局部变量，而不是使用数组
    double local_sum = 0.0;
    #pragma omp for
    for (int i = 0; i < arr_size; i++) {
      local_sum += x[i] * y[i];
    }
    // 通过 critical 保护 global_sum 的更新
    #pragma omp critical
    {
      global_sum += local_sum;
    }
  }
```



OpenMP也有该操作的便捷指令：reduction

用法：

```c
double dotp_reduction_optimized(double* x, double* y, int arr_size) {
  // TODO: Modify this function
  // Please DO use the `reduction` directive here!
  double global_sum = 0.0;
  #pragma omp parallel
  {
    #pragma omp for reduction(+:global_sum)
    //把要做对应操作的变量写成  操作：变量名的形式
    for (int i = 0; i < arr_size; i++)
      global_sum += x[i] * y[i];
  }
  return global_sum;
}
```





# 进程级并行

首先要分清进程和线程的区别，进程是操作系统层面的线程，相互隔离，互不干扰，各自拥有的资源很多，权限很大，线程是微观层面的

进程级并行指的是通过一父一子两个进程并行处理某一个程序，特别是需要一直待命的程序，例如：

网页相应请求，如果不用进程并行，那么会出现第一个相应处理后才轮到第二个，串行进行，效率非常低

可以设计成：父进程等待请求，子进程处理请求，这样的网页相应迅速

## fork的概念

> **1. `fork()` 系统调用的作用**
> `fork()` 是一个系统调用 。它的主要任务是创建一个新进程，这个新进程是调用 `fork()` 的那个进程（称为**父进程**）的精确副本（几乎完全一样）。这个新创建的进程被称为**子进程** 。
>
> **2. `fork()` 的独特返回值**
>
> `fork()` 最让人困惑的地方在于它会返回*两次*，并且在父进程和子进程中返回的值不同：
>
> - **在父进程中**：`fork()` 返回新创建的子进程的进程ID (PID)。这是一个大于0的正数。这使得父进程可以知道子进程的PID，以便后续对其进行管理和通信。
> - **在子进程中**：`fork()` 返回 `0`。这告诉子进程自己是新创建的那个。
> - **如果失败**：`fork()` 在父进程中返回一个负数。

## 思路

### 什么时候fork

在父进程accept请求之后就可以fork，把请求转接给子进程处理

### fork后的过程中，父子进程都在做什么

#### 父进程

继续监听端口，等待下一个request

#### 子进程

1. 处理请求，调用函数做事情
2. 检测父进程有没有被杀死
   1. 被杀死：抛出异常
   2. 没有被杀死：exit(0)

为什么要exit(0)？

因为子进程本身也在循环中，如果它在处理请求后没有exit，自身就会回到循环开头开始fork，变为另一个进程的父进程，无限循环



