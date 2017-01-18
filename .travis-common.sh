export LOCAL_PREFIX="$(dirname "$(readlink -f "$0")")/../local-prefix"
mkdir -p "$LOCAL_PREFIX"
export PATH="$LOCAL_PREFIX/bin:$HOME/.local/bin:${PATH:+:}$PATH"
python_lib() {
  python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib(prefix='$1'))"
}
export PYTHONPATH="$(python_lib "$HOME/.local"):$(python_lib "$LOCAL_PREFIX")${PYTHONPATH+:}$PYTHONPATH"
export PKG_CONFIG_PATH="$LOCAL_PREFIX/lib/pkgconfig${PKG_CONFIG_PATH+:}$PKG_CONFIG_PATH"

# Make sure that we properly define dependencies in make
# and can parallel build.
export MAKEFLAGS=("-j" "$(( $(grep processor /proc/cpuinfo | wc -l) + 1))")

# Make sure that we use the right compiler
if [ "${MYCC:0:3}" = "gcc" ]; then
  export CC=gcc${MYCC:3}
  export CXX=g++${MYCC:3}
elif [ "${MYCC:0:5}" = "clang" ]; then
  export CC=clang${MYCC:5}
  export CXX=clang++${MYCC:5}
else
  export CC=not-a-compiler
  export CXX=not-a-compiler
fi
