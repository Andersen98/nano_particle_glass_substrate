#!/bin/bash

#trap '$(read -p "[$BASH_SOURCE:$LINENO]] $BASH_COMMAND")' DEBUG
set -euo pipefail

max_threads=128
gmp_ver=6.2.1
libunistring_ver=1.1
guile_ver=3.0.8
hdf5_ver=1_13_3
libctl_ver=4.5.1
open_blas_ver=0.3.21
lapack_ver=3.11.0

show_help(){
    echo "USAGE: ./install_guile.sh -b|--build BUILD_DIR -i|--install INSTALL_DIR"
}
die() {
    printf '%s\n' "$1" >&2
    exit 1
}

get_pkg_dir(){
    local pkg_name
    pkg_name="$1"
    local pkg_ver
    pkg_ver="$2"
    local url
    url="$3"
    local file_suffix
    file_suffix="${url/*.tar/tar}"
    local file_name
    file_name="${pkg_name}-${pkg_ver}.$file_suffix"

    echo "Downloading and extracting ${file_name}."
    curl -L "$url" -o "$file_name"
    tar -vxf "$file_name"
}


# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.
build=
install=

while [ ${#@} -ne 0 ] ; do #number of args left is greater than 0.
    case $1 in
        -h|-\?|--help)
            show_help    # Display a usage synopsis.
            exit
            ;;
        -b|--build)       # Takes an option argument; ensure it has been specified.
            if [ -d "$2" ]; then
                build=$2
                shift
            else
                die 'ERROR: "--build" requires a non-empty option argument.'
            fi
            ;;
        --build=?*)
	    if [ -d "${1#*=}" ]; then
		build=${1#*=} # Delete everything up to "=" and assign the remainder.
	    else
		die 'ERROR: "--build" requires a non-empty option argument (directory with read/write permission).'
	    fi
	    
            ;;
        --build=)         # Handle the case of an empty --file=
            die 'ERROR: "--build" requires a non-empty option argument.'
            ;;
        -i|--install) #takes option argument; ensure it is specified.
	    if [ -d "$2" ]; then
		install=$2
		shift
	    else
		die 'ERROR: "--install" requires path to an existing directory.'
	    fi
	    ;;
	--install=?*)
	    if [ -d "${1#*=}" ]; then
	       install=${1#*=} #delete everything up to = sign.
	       else
		   die 'ERROR: "--install" requires a directory (should also have read write permission).'
	    fi
	    ;;
        --)              # End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: No more options, so break out of the loop.
            break
    esac

    shift
done



gmp(){
    cd "$build"
    get_pkg_dir 'gmp' "$gmp_ver" 'https://gmplib.org/download/gmp-6.2.1/gmp-6.2.1.tar.xz'
    cd "gmp-${gmp_ver}"
    ./configure --prefix="$install"
    make -j
    make check
    make install
}

libunistring(){
    cd "$build" 
    get_pkg_dir 'libunistring' 'https://ftp.gnu.org/gnu/libunistring/libunistring-1.1.tar.xz'
    cd "libunistring-${libunistring_ver}"
    ./configure --prefix="$install"
    make -j
    make check
    make install
}

bdwgc(){

    cd "$build"
    git clone https://github.com/ivmai/bdwgc
    cd bdwgc
    git clone https://github.com/ivmai/libatomic_ops
    mkdir build && cd build
    cmake \
	-DCMAKE_INSTALL_PREFIX:PATH="$install"\
	-Dbuild_tests=ON ..
    make all -j
    ./atomicopstest &&\
    ./disclaimtest &&\
    ./hugetest &&\
    ./leaktest &&\
    ./realloctest &&\
    ./staticrootstest &&\
    ./threadkeytest &&\
    ./weakmaptest &&\
    ./cordtest &&\
    ./gctest &&\
    ./initfromthreadtest &&\
    ./middletest &&\
    ./smashtest &&\
    ./subthreadcreatetest &&\
    ./threadleaktest
    make install
}

_guile(){
    cd "$build"
    get_pkg_dir 'guile' "$guile_ver" 'ftp://ftp.gnu.org/gnu/guile/'
    cd "guile-$guile_ver"
    PKG_CONFIG_PATH="${install}/lib64/pkgconfig:${install}/lib/pkgconfig:$PKG_CONFIG_PATH" \
        LDFLAGS="-L${install}/lib -Wl,-rpath,${install}/lib -L${install}/lib64 -Wl,-rpath,${install}/lib64" \
	    ./configure  --prefix="$install"
    PKG_CONFIG_PATH="${install}/lib64/pkgconfig:${install}/lib/pkgconfig:$PKG_CONFIG_PATH" \
        LDFLAGS="-L${install}/lib -Wl,-rpath,${install}/lib -L${install}/lib64 -Wl,-rpath,${install}/lib64" \
        make -j"${max_threads:-128}" #prevents from spawning way too many threads
    LDFLAGS="-L${install}/lib -Wl,-rpath,${install}/lib -L${install}/lib64 -Wl,-rpath,${install}/lib64" \
        make check
    make install
}

guile(){
    gmp && libunistring && bdwgc && _guile
}
libctl(){
    local MY_LDFLAGS
    local MY_LD_LIBRARY_PATH
    MY_LD_LIBRARY_PATH="$install/lib:$install/lib64:$LD_LIBRARY_PATH"
    MY_LDFLAGS="-L${install}/lib -Wl,-rpath,${install}/lib -L${install}/lib64 -Wl,-rpath,${install}/lib64"
    curl -LO https://github.com/NanoComp/libctl/releases/download/v4.5.1/libctl-4.5.1.tar.gz
    tar -vxf libctl-*.tar.gz
    cd libctl-*/
    PATH=${install}/bin:$PATH\
        ./configure --prefix="$install"\
            LDFLAGS="$MY_LDFLAGS" CPPFLAGS="$MY_CPPFLAGS"\
            CC=mpicc F77=mpif77\
            --enable-shared=yes
    make -j"${max_threads:-128}"
    make check
    make install   

}
hdf5(){
    cd "$build"
    local MY_LDFLAGS
    local MY_LD_LIBRARY_PATH
    MY_LD_LIBRARY_PATH="$install/lib:$install/lib64:$LD_LIBRARY_PATH"
    MY_LDFLAGS="-L${install}/lib -Wl,-rpath,${install}/lib -L${install}/lib64 -Wl,-rpath,${install}/lib64"
    get_pkg_dir 'hdf5' "$hdf5_ver" 'https://github.com/HDFGroup/hdf5/archive/refs/tags/'
    cd hdf5-*/
    PKG_CONFIG_PATH="$install/lib/pkgconfig:$install/lib64/pkgconfg:$PKG_CONFIG_PATH"\
        ./configure --prefix="$install"\
            LDFLAGS="$MY_LDFLAGS" CXXFLAGS="$MY_CPPFLAGS"\
            CC=mpicc CXX=mpic++ FC=mpif77\
            --enable-parallel --enable-parallel-tools
    make -j"${max_threads:-128}"
    make install
}
open_blas(){
    cd "$build"
    curl -LO https://github.com/xianyi/OpenBLAS/archive/refs/tags/v0.3.21.tar.gz
    tar -vxf v0.*.tar.gz
    cd OpenBLAS-*/
    make FC=mpif77 -j

}
harmoninv(){
    local MY_LDFLAGS
    local MY_LD_LIBRARY_PATH
    MY_LD_LIBRARY_PATH="$install/lib:$install/lib64:$LD_LIBRARY_PATH"
    MY_LDFLAGS="-L${install}/lib -Wl,-rpath,${install}/lib -L${install}/lib64 -Wl,-rpath,${install}/lib64"
    curl -LO 'https://github.com/NanoComp/harminv/releases/download/v1.4.1/harminv-1.4.1.tar.gz'
    tar -vxf harmoninv-*.tar.gz
    cd harminv-*/
     cd meep-build/
    PKG_CONFIG_PATH="$install/lib/pkgconfig:$install/lib64/pkgconfg:$PKG_CONFIG_PATH"\
         ./configure --prefix="$install"\
              LDFLAGS="$MY_LDFLAGS" CXXFLAGS="$MY_CPPFLAGS"\
              CC=mpicc F77=mpif77\
              --with-libctl="$install/share/libctl"\
              --with-openmp --enable-shared --enable-single\
              --with-blas="$install/lib"\
              --with-lapack="$install/lib"

    make -j
    make check
    make install
}
h5utils(){
    cd "$build"
    curl -LO 'https://github.com/NanoComp/h5utils/releases/download/1.13.1/h5utils-1.13.1.tar.gz'
    tar -vxf h5utils-*.tar.gz
    cd h5utils-*/
    PKG_CONFIG_PATH="$install/lib/pkgconfig:$install/lib64/pkgconfg:$PKG_CONFIG_PATH"\
        ./configure --prefix="$install"\
            LDFLAGS="$MY_LDFLAGS" CPPFLAGS="$MY_CPPFLAGS"\
            CC=mpicc
    make -j
    make check
    make install
}
fftw(){
    cd "$build"
    curl -LO 'https://www.fftw.org/fftw-3.3.10.tar.gz'
    tar -vxf fftw-*.gz
    cd fftw-*/
    PKG_CONFIG_PATH="$install/lib/pkgconfig:$install/lib64/pkgconfg:$PKG_CONFIG_PATH"\
        ./configure LDFLAGS="$MY_LDFLAGS"\
            CXXFLAGS="$MY_CPPFLAGS"\
            CPPFLAGS="$MY_CPPFLAGS"\
            --enable-shared=yes --enable-openmp --prefix="$install"
    make -j
    make check
    make install

}
mpb(){
    cd "$build"
    curl -LO 'https://github.com/NanoComp/mpb/releases/download/v1.11.1/mpb-1.11.1.tar.gz'
    tar -vxf mpb-*.gz
    cd mpb-*/
    PKG_CONFIG_PATH="$install/lib/pkgconfig:$install/lib64/pkgconfg:$PKG_CONFIG_PATH"\
        ./configure --prefix="$install"\
            LDFLAGS="${MY_LDFLAGS}" CPPFLAGS="${MY_CPPFLAGS}"\
            --with-blas="$install/lib" --with-lapack="$install/lib"\
            --with-openmp --with-libctl="$install/share/libctl"\
            --enable-shared CC=mpicc --with-hermitian-eps
    make -j


}


pip_packages(){
    pip3 install --user --no-cache-dir mpi4py
    pip3 install --user Cython==0.29.16
    export HDF5_MPI="ON"
    pip3 install --user --no-binary=h5py h5py
    pip3 install --user autograd
    pip3 install --user scipy
    pip3 install --user matplotlib>3.0.0
    pip3 install --user ffmpeg
}
nlopt(){
    cd "$build"
    curl -L -o nlopt.tar.gz 'https://github.com/stevengj/nlopt/archive/refs/tags/v2.7.1.tar.gz'
    tar -vxf nlopt.tar.gz
    cd nlopt*/
    mkdir build
    cd build
    PKG_CONFIG_PATH="$install/lib/pkgconfig:$install/lib64/pkgconfg:$PKG_CONFIG_PATH"\
        cmake -DCMAKE_INSTALL_PREFIX="$install" ..
    cmake --install . 
    make -j
    make install
}
meep(){
    cd "$build"
    curl -LO 'https://github.com/NanoComp/meep/releases/download/v1.24.0/meep-1.24.0.tar.gz'
    tar -vxf meep-1.24.0.tar.gz
    mkdir meep-build
    cd meep-build/
    PKG_CONFIG_PATH="$install/lib/pkgconfig:$install/lib64/pkgconfg:$PKG_CONFIG_PATH"\
         $build/meep-1.24.0/configure --prefix="$install"\
              LDFLAGS="$MY_LDFLAGS" CPPFLAGS="$MY_CPPFLAGS"\
              MPICXX=mpicc F77=mpif77 PYTHON=python3\
              --with-libctl="$install/share/libctl"\
              --with-openmp --enable-shared --enable-single\
              --with-blas="$install/lib"\
              --with-lapack="$install/lib"






}
clean_build(){
    rm -rf "${build:?ERROR build not set}"
    mkdir "$build"
}
clean_install(){
    rm -rf "${install:?ERROR INSTALL NOT SET}"
    mkdir "$install"
}
echo "Enter 1 for gmp, 2 for libunistring 3 for bdwgc 4 for guile 5 to build all"
echo "Enter 6 to clean build or 7 to clean install."
read -r target
case $target in
    1)
	guile
	;;
    2)
    libctl
    ;;
    3)
    hdf5
    ;;
    4)
    meep	
	;;
    6)
    clean_build
    ;;
    7)
    clean_install
    ;;
    *)
	die 'Error, must select something to install. Exiting.'
	;;
esac



