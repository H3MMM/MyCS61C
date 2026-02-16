from distutils.core import setup, Extension
import sysconfig

def main():
    CFLAGS = ['-g', '-Wall', '-std=c99', '-fopenmp', '-mavx', '-mfma', '-pthread', '-O3']
    LDFLAGS = ['-fopenmp']
    # Use the setup function we imported and set up the modules.
    # You may find this reference helpful: https://docs.python.org/3.6/extending/building.html
    # TODO: YOUR CODE HERE
    extensions = [
        Extension(
            name = 'numc', 
            sources = ['numc.c', 'matrix.c'], 
            extra_compile_args = CFLAGS, 
            extra_link_args = LDFLAGS, 
        )
    ]
    setup(
        name = "numc", 
        version = "1.0", 
        author = "H3M", 
        author_email = "3435359630@qq.com", 
        description = "CS61C Proj4 Woooooo!!!",
        ext_modules = extensions  
    )


if __name__ == "__main__":
    main()

    
