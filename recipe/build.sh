#!/bin/sh

XVFB_RUN=""
if test `uname` = "Linux"
then
  xvfb-run -h
  XVFB_RUN="xvfb-run -s '-screen 0 640x480x24'"
fi

pushd sources/shiboken2
mkdir build && cd build

cmake \
  -DCMAKE_PREFIX_PATH=${PREFIX} \
  -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_RPATH=${PREFIX}/lib \
  -DBUILD_TESTS=OFF \
  -DPYTHON_EXECUTABLE=${PYTHON} \
  ..
make install -j${CPU_COUNT}
popd

pushd sources/pyside2
mkdir build && cd build

cmake \
  -DCMAKE_PREFIX_PATH=${PREFIX} \
  -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_BUILD_TYPE=Release \
  -DPYTHON_EXECUTABLE=${PYTHON} \
  -DCMAKE_INSTALL_RPATH="${PREFIX}/lib" -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON -DCMAKE_MACOSX_RPATH=ON \
  ..
make install -j${CPU_COUNT}

cp ./tests/pysidetest/libpysidetest${SHLIB_EXT} ${PREFIX}/lib
# create a single X server connection rather than one for each test using the PySide USE_XVFB cmake option
eval ${XVFB_RUN} ctest -j${CPU_COUNT} --output-on-failure --timeout 200 -E QtWebKit || echo "no ok"
popd

pushd sources/pyside2-tools
git checkout 5.9
patch -p1 -i ${RECIPE_DIR}/0001-Return-0-with-pyside2-rcc-help.patch
patch -p1 -i ${RECIPE_DIR}/0001-Make-pyside2-uic-executable-by-windows-shell.patch
mkdir build && cd build

cmake \
  -DCMAKE_PREFIX_PATH=${PREFIX} \
  -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_TESTS=OFF \
  ..
make install -j${CPU_COUNT}
