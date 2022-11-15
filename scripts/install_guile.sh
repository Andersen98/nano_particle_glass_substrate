#!/bin/bash

trap '$(read -p "[$BASH_SOURCE:$LINENO]] $BASH_COMMAND")' DEBUG
set -euo pipefail

max_threads=128
gmp_ver=6.2.1
libunistring_ver=1.1
guile_ver=3.0.8

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
    local url_prefix
    url_prefix="${3/%\//}" #removes trailing fron slash
    local url_suffix
    url_suffix="${4:-tar.gz}"
    local pkg_file
    pkg_file="${pkg_name}-${pkg_ver}.${url_suffix}"

    echo "Downloading and extracting ${pkg_file}."
    curl -LO "${url_prefix}/${pkg_file}"
    tar -vxf "$pkg_file"
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
    get_pkg_dir 'gmp' "$gmp_ver" 'https://gmplib.org/download/gmp/' 'tar.xz'
    cd "gmp-${gmp_ver}"
    ./configure --prefix="$install"
    make -j
    make check
    make install
}

libunistring(){
    cd "$build" 
    get_pkg_dir 'libunistring' "$libunistring_ver" 'https://ftp.gnu.org/gnu/libunistring'
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

guile(){
    cd "$build"
    get_pkg_dir 'guile' "$guile_ver" 'ftp://ftp.gnu.org/gnu/guile/'
    cd "guile-$guile_ver"
    env PKG_CONFIG_PATH="${install}/lib64/pkgconfig:${install}/lib/pkgconfig:$PKG_CONFIG_PATH" \
	./configure  --prefix="$install" \
	LDFLAGS="-L${install}/lib -L${install}/lib64 -Wl,-rpath -Wl,${install}/lib -Wl,-rpath -Wl, ${install}/lib64"
    make -j"$max_threads" #prevents from spawning way too many threads
    make check
    make install
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
	gmp
	;;
    2)
	libunistring
	;;
    3)
	bdwgc
	;;
    4)
	guile
	;;
    5)
	gmp && libunistring && bdwgc && guile
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



