#!/bin/bash

prefix=$HOME
install="$prefix/install"
build="$prefix/build"
export PKG_CONFIG_PATH="$install/lib/pkgconfig:$install/lib64/pkgconfg:$PKG_CONFIG_PATH"
export LD_LIBRARY_PATH="$install/lib:$install/lib64:$LD_LIBRARY_PATH"
export PATH="$install/bin:$prefix/.local/bin:$PATH"
MY_LDFLAGS="-L/usr/lib -Wl,-rpath,/usr/lib -L/usr/lib64 -Wl,-rpath,/usr/lib64 -L${install}/lib -Wl,-rpath,${install}/lib -L${install}/lib64 -Wl,-rpath,${install}/lib64"
MY_CPPFLAGS="-I${install}/include"
CXX="mpicxx"
CC="mpicc"   #flags that arch used to build
FC="mpif90"
F9X="mpif90" 


#-----------
echo "gonna install harmoninv"
read -r 
cd "$build"
curl -LO 'https://github.com/NanoComp/harminv/releases/download/v1.4.1/harminv-1.4.1.tar.gz'
    tar -vxf harminv-*.tar.gz
    cd harminv-*/
    PKG_CONFIG_PATH="$install/lib/pkgconfig:$install/lib64/pkgconfg:$PKG_CONFIG_PATH"\
         ./configure --prefix="$install"\
              LDFLAGS="$MY_LDFLAGS" CXXFLAGS="$MY_CPPFLAGS"\
              CC="$CC" F77="$F77"\
              --with-libctl="$install/share/libctl"\
              --with-openmp --enable-shared\
              --with-blas="$install/lib"\
              --with-lapack="$install/lib"
    make -j
    make install




#-----------
echo "gonna install libctl"
read -r 
cd "$build"
curl -LO https://github.com/NanoComp/libctl/releases/download/v4.5.1/libctl-4.5.1.tar.gz
tar -vxf libctl-*.tar.gz
cd libctl-*/
PATH=${install}/bin:$PATH\
./configure  --enable-shared --prefix=${install}\ 
   LDFLAGS="$MY_LDFLAGS" CPPFLAGS="$MY_CPPFLAGS"\
   CC="$CC" F77="$F77"\
  
    

#-----------
echo "gonna install h5utils"
read -r 
cd "$build"
cd "$build"
    curl -LO 'https://github.com/NanoComp/h5utils/releases/download/1.13.1/h5utils-1.13.1.tar.gz'
    tar -vxf h5utils-*.tar.gz
    cd h5utils-*/
    PKG_CONFIG_PATH="$install/lib/pkgconfig:$install/lib64/pkgconfg:$PKG_CONFIG_PATH"\
        ./configure --prefix="$install" --exec-prefix="$install/bin"\
            LDFLAGS="$MY_LDFLAGS" CPPFLAGS="$MY_CPPFLAGS"\
            CC=mpicc
    make -j
    make install


#-----------
echo "gonna install h5utils"
read -r 
cd "$build"
curl -LO 'https://www.fftw.org/fftw-3.3.10.tar.gz'
tar -vxf fftw-*.gz
cd fftw-*/
PKG_CONFIG_PATH="$install/lib/pkgconfig:$install/lib64/pkgconfg:$PKG_CONFIG_PATH"\
    ./configure LDFLAGS="$MY_LDFLAGS" CPPFLAGS="$MY_CPPFLAGS"\
        CC="$CC" F77="$F77" MPICC="$CC"\
        --enable-shared=yes --enable-openmp --prefix="$install"
make -j
make check
make install

#-----------
echo "gonna install mpb"
read -r 
cd "$build"
curl -LO 'https://github.com/NanoComp/mpb/releases/download/v1.11.1/mpb-1.11.1.tar.gz'
tar -vxf mpb-*.gz
cd mpb-*/
./configure --prefix="$install"\
    LDFLAGS="${MY_LDFLAGS}" CPPFLAGS="${MY_CPPFLAGS}"\
    --with-openmp --with-libctl="$install/share/libctl"\
    --enable-shared CC=mpicc --with-hermitian-eps
make -j

#-----------
echo "gonna install pip packages"
read -r 
pip3 install --user --no-cache-dir mpi4py
pip3 install --user Cython==0.29.16
export HDF5_MPI="ON"
pip3 install --user --no-binary=h5py h5py
pip3 install --user autograd
pip3 install --user scipy
pip3 install --user matplotlib>3.0.0
pip3 install --user ffmpeg


#-----------
echo "gonna install nlopt"
read -r 
cd "$build"
curl -L -o nlopt.tar.gz 'https://github.com/stevengj/nlopt/archive/refs/tags/v2.7.1.tar.gz'
tar -vxf nlopt.tar.gz
cd nlopt*/
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX="$install" ..
make -j
make install

#-----------
echo "gonna install meep"
read -r 
cd "$build"
curl -LO 'https://github.com/NanoComp/meep/releases/download/v1.24.0/meep-1.24.0.tar.gz'
tar -vxf meep-1.24.0.tar.gz
mkdir meep-build
cd meep-build/
$build/meep-1.24.0/configure --prefix="$install"\
    LDFLAGS="$MY_LDFLAGS" CPPFLAGS="$MY_CPPFLAGS"\
    MPICXX=mpicc F77=mpif77 PYTHON=python3\
    --with-libctl="$install/share/libctl"\
    --with-openmp --enable-shared --enable-single