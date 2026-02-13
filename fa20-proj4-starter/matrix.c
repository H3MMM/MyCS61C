#include "matrix.h"
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

// Include SSE intrinsics
#if defined(_MSC_VER)
#include <intrin.h>
#elif defined(__GNUC__) && (defined(__x86_64__) || defined(__i386__))
#include <immintrin.h>
#include <x86intrin.h>
#endif

/* Below are some intel intrinsics that might be useful
 * void _mm256_storeu_pd (double * mem_addr, __m256d a)
 * __m256d _mm256_set1_pd (double a)
 * __m256d _mm256_set_pd (double e3, double e2, double e1, double e0)
 * __m256d _mm256_loadu_pd (double const * mem_addr)
 * __m256d _mm256_add_pd (__m256d a, __m256d b)
 * __m256d _mm256_sub_pd (__m256d a, __m256d b)
 * __m256d _mm256_fmadd_pd (__m256d a, __m256d b, __m256d c)
 * __m256d _mm256_mul_pd (__m256d a, __m256d b)
 * __m256d _mm256_cmp_pd (__m256d a, __m256d b, const int imm8)
 * __m256d _mm256_and_pd (__m256d a, __m256d b)
 * __m256d _mm256_max_pd (__m256d a, __m256d b)
*/

/*
 * Generates a random double between `low` and `high`.
 */
double rand_double(double low, double high) {
    double range = (high - low);
    double div = RAND_MAX / range;
    return low + (rand() / div);
}

/*
 * Generates a random matrix with `seed`.
 */
void rand_matrix(matrix *result, unsigned int seed, double low, double high) {
    srand(seed);
    for (int i = 0; i < result->rows; i++) {
        for (int j = 0; j < result->cols; j++) {
            set(result, i, j, rand_double(low, high));
        }
    }
}

/*
 * Allocate space for a matrix struct pointed to by the double pointer mat with
 * `rows` rows and `cols` columns. You should also allocate memory for the data array
 * and initialize all entries to be zeros. Remember to set all fieds of the matrix struct.
 * `parent` should be set to NULL to indicate that this matrix is not a slice.
 * You should return -1 if either `rows` or `cols` or both have invalid values, or if any
 * call to allocate memory in this function fails. If you don't set python error messages here upon
 * failure, then remember to set it in numc.c.
 * Return 0 upon success and non-zero upon failure.
 */
int allocate_matrix(matrix **mat, int rows, int cols) {
    // TODO: YOUR CODE HERE
    
    //错误申请
    if(rows < 1 || cols < 1) {
        PyErr_SetString(PyExc_ValueError, "Incorrect values for rows or cols");
        return -1;
    }
    //申请结构体
    *mat = (matrix*)malloc(sizeof(matrix));
    if(!mat) {
        PyErr_SetString(PyExc_RuntimeError, "malloc matrix failed!");
        return -1;
    }
    //实例化
    (*mat)->cols = cols;
    (*mat)->rows = rows;
    (*mat)->parent = NULL;
    (*mat)->ref_cnt = 1;
    (*mat)->is_1d = (cols == 1 || rows == 1) ? 1 : 0;
    //申请内存
    (*mat)->data = (double**) malloc(sizeof(double*) * rows);
    if (!(*mat) ->data) {
        PyErr_SetString(PyExc_RuntimeError, "malloc data failed!");
        return -1;
    }
    for(int i = 0; i < rows;i++){
        (*mat)->data[i] = (double*)calloc(cols, sizeof(double));
    }
    return 0;
}

/*
 * Allocate space for a matrix struct pointed to by `mat` with `rows` rows and `cols` columns.
 * This is equivalent to setting the new matrix to be
 * from[row_offset:row_offset + rows, col_offset:col_offset + cols]
 * If you don't set python error messages here upon failure, then remember to set it in numc.c.
 * Return 0 upon success and non-zero upon failure.
 */
int allocate_matrix_ref(matrix **mat, matrix *from, int row_offset, int col_offset,
                        int rows, int cols) {
    // TODO: YOUR CODE HERE
    // 错误申请
    if (rows < 1 || cols < 1 || row_offset < 0 || col_offset < 0 || 
        row_offset + rows > from->rows || col_offset + cols > from -> cols)
    {
        PyErr_SetString(PyExc_ValueError, "Incorrect values for rows or cols");
        return -1;
    }
    // 申请结构体
    *mat = (matrix *)malloc(sizeof(matrix));
    if (!mat)
    {
        PyErr_SetString(PyExc_RuntimeError, "malloc matrix failed!");
        return -1;
    }
    // 实例化
    (*mat)->cols = cols;
    (*mat)->rows = rows;
    (*mat)->parent = from;
    (*mat)->is_1d = (cols == 1 || rows == 1) ? 1 : 0;
    (*mat)->ref_cnt = 1;
   
    // 申请内存
    (*mat)->data = (double **)malloc(sizeof(double *) * rows);
    if (!(*mat)->data)
    {
        PyErr_SetString(PyExc_RuntimeError, "malloc data failed!");
        return -1;
    }

    for (int i = 0; i < rows; i++)
    {
        (*mat)->data[i] = from -> data[i + row_offset] + col_offset;
    }
   
    from -> ref_cnt++;
    return 0;
}

/*
 * This function will be called automatically by Python when a numc matrix loses all of its
 * reference pointers.
 * You need to make sure that you only free `mat->data` if no other existing matrices are also
 * referring this data array.
 * See the spec for more information.
 */
void deallocate_matrix(matrix *mat) {
    /* TODO: YOUR CODE HERE */
    if(mat == NULL) {
        PyErr_SetString(PyExc_RuntimeError, "This matrix is NULL!!!");
        return;
    }
    if(mat->parent != NULL) {
        mat->parent->ref_cnt--;
        free(mat->data);
    }
    else {
        mat->ref_cnt--; //第一件事是先更新ref_cnt
        if((*mat).ref_cnt == 0) {
            for (int i = 0; i < (*mat).rows; i++)
            {
                free((*mat).data[i]);
            }
            free((*mat).data);
        }
    }
}

/*
 * Return the double value of the matrix at the given row and column.
 * You may assume `row` and `col` are valid.
 */
double get(matrix *mat, int row, int col) {
    /* TODO: YOUR CODE HERE */
    return mat->data[row][col];
}

/*
 * Set the value at the given row and column to val. You may assume `row` and
 * `col` are valid
 */
void set(matrix *mat, int row, int col, double val) {
    /* TODO: YOUR CODE HERE */
    mat -> data[row][col] = val;
}

/*
 * Set all entries in mat to val
 */
void fill_matrix(matrix *mat, double val) {
    /* TODO: YOUR CODE HERE */
    int rows = (*mat).rows;
    int cols = (*mat).cols;
    for(int i = 0; i< rows;i++){
        for(int j = 0; j < cols;j++) {
            mat -> data[i][j] = val;
        }
    }
}

/*
 * Store the result of adding mat1 and mat2 to `result`.
 * Return 0 upon success and a nonzero value upon failure.
 */
int add_matrix(matrix *result, matrix *mat1, matrix *mat2) {
    /* TODO: YOUR CODE HERE */
    if(mat1->rows != mat2->rows || mat1->cols != mat2->cols) {
        PyErr_SetString(PyExc_ValueError, "Incorrect values for rows or cols");
        return -1;
    } 
    int rows = (*mat1).rows;
    int cols = (*mat1).cols;
    for(int i = 0;i < rows;i++){
        for(int j = 0; j < cols;j++) {
            result->data[i][j] = mat1->data[i][j] + mat2->data[i][j];
        }
    }
    return 0;
}

/*
 * Store the result of subtracting mat2 from mat1 to `result`.
 * Return 0 upon success and a nonzero value upon failure.
 */
int sub_matrix(matrix *result, matrix *mat1, matrix *mat2) {
    /* TODO: YOUR CODE HERE */
    if (mat1->rows != mat2->rows || mat1->cols != mat2->cols)
    {
        PyErr_SetString(PyExc_ValueError, "Incorrect values for rows or cols");
        return -1;
    }
    int rows = (*mat1).rows;
    int cols = (*mat1).cols;
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++)
        {
            result->data[i][j] = mat1->data[i][j] - mat2->data[i][j];
        }
    }
    return 0;
}

/*
 * Store the result of multiplying mat1 and mat2 to `result`.
 * Return 0 upon success and a nonzero value upon failure.
 * Remember that matrix multiplication is not the same as multiplying individual elements.
 */
int mul_matrix(matrix *result, matrix *mat1, matrix *mat2) {
    /* TODO: YOUR CODE HERE */
    if(mat1->cols != mat2->rows) {
        PyErr_SetString(PyExc_ValueError, "Incorrect values for rows or cols");
        return -1;
    }
    int rows = (*mat1).rows;
    int cols = (*mat2).cols;
    int n = (*mat1).cols;
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++) {
            for(int k = 0; k < n; k++) {
                result->data[i][j] += mat1->data[i][k] * mat2->data[k][j];
            }
        }
    }
    return 0;
    
}

/*
 * Store the result of raising mat to the (pow)th power to `result`.
 * Return 0 upon success and a nonzero value upon failure.
 * Remember that pow is defined with matrix multiplication, not element-wise multiplication.
 */
int pow_matrix(matrix *result, matrix *mat, int pow) {
    /* TODO: YOUR CODE HERE */
    if(mat->rows != mat->cols) {
        PyErr_SetString(PyExc_ValueError, "Incorrect values for rows or cols");
        return -1;
    }
    int n = (*mat).rows;
    for(int i = 0; i < n; i++) {
        for (int j = 0; j < n; j++) {
            // result->data[i][i] = 1;   这里不能只把对角线元素置1，其他的没有清零
            result->data[i][j] = (i == j) ? 1 : 0;
        }
    }
    matrix* tmp;
    allocate_matrix(&tmp, n,n);
    for(int s = 0; s < pow; s++) {
        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                tmp->data[i][j] = 0;
                for (int k = 0; k < n; k++){
                    tmp->data[i][j] += result->data[i][k] * mat->data[k][j];
                }
            }
        }
        for(int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                result->data[i][j] = tmp->data[i][j];
            }
        }
    }
    deallocate_matrix(tmp);
    return 0;
}

/*
 * Store the result of element-wise negating mat's entries to `result`.
 * Return 0 upon success and a nonzero value upon failure.
 */
int neg_matrix(matrix *result, matrix *mat) {
    /* TODO: YOUR CODE HERE */
    int rows = (*mat).rows;
    int cols = (*mat).cols;
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++)
        {
            (*result).data[i][j] = -mat->data[i][j];
        }
    }
    return 0;
}

/*
 * Store the result of taking the absolute value element-wise to `result`.
 * Return 0 upon success and a nonzero value upon failure.
 */
int abs_matrix(matrix *result, matrix *mat) {
    /* TODO: YOUR CODE HERE */
    int rows = (*mat).rows;
    int cols = (*mat).cols;
    for (int i = 0; i < rows; i++) {
        for (int j = 0; j < cols; j++)
        {
            if(mat->data[i][j] >= 0) {
                (*result).data[i][j] = mat->data[i][j];
            }
            else {
                (*result).data[i][j] = -mat->data[i][j];
            }
        }
    }
    return 0;
}

