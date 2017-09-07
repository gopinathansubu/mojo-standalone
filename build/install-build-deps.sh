#!/bin/bash

ROOT_DIR="$(dirname $(realpath $(dirname "${BASH_SOURCE[0]}")))"
BUILD_DIR="$ROOT_DIR/build"
BUILDTOOLS_DIR="$ROOT_DIR/buildtools"
THIRD_PARTY_DIR="$ROOT_DIR/third_party/"
GTEST_DIR="$ROOT_DIR/testing/gtest"

function install_dep_from_tarfile {
  SRC_URL=$1
  PACKAGE_DIR=$2
  FILENAME="$(basename $SRC_URL)"

  DOWNLOAD_DIR="$(basename $FILENAME .tar.gz)/$PACKAGE_DIR"
  INSTALL_DIR="$THIRD_PARTY_DIR/$PACKAGE_DIR"
  OLD_DIR="$THIRD_PARTY_DIR/$PACKAGE_DIR.old"

  mkdir -p "$INSTALL_DIR"
  cd "$INSTALL_DIR"
  echo "Downloading $SRC_URL"
  curl --remote-name "$SRC_URL"
  tar xvzf "$FILENAME"

  cd "$DOWNLOAD_DIR"

  # Replace with new directory
  cd "$ROOT_DIR"
  mv "$INSTALL_DIR" "$OLD_DIR"
  mv "$OLD_DIR/$DOWNLOAD_DIR" "$INSTALL_DIR"
  rm -fr "$OLD_DIR"
}

# BODY

# Install gsutil.
cd $THIRD_PARTY_DIR
curl --remote-name https://storage.googleapis.com/pub/gsutil.tar.gz
tar xfz gsutil.tar.gz
rm gsutil.tar.gz

# Install gn.
$THIRD_PARTY_DIR/gsutil/gsutil cp gs://chromium-gn/56e78e1927e12e5c122631b7f5a46768e527f1d2 $BUILDTOOLS_DIR/gn
chmod 700 $BUILDTOOLS_DIR/gn

# Build and install ninja.
cd $THIRD_PARTY_DIR
rm -rf ninja
git clone https://github.com/martine/ninja.git -b v1.5.1
./ninja/bootstrap.py
cp ./ninja/ninja $BUILDTOOLS_DIR
chmod 700 $BUILDTOOLS_DIR/ninja

# Install gtest at the correct revision.
rm -rf $GTEST_DIR
mkdir -p $GTEST_DIR
git clone https://chromium.googlesource.com/external/googletest.git $GTEST_DIR
cd $GTEST_DIR
git checkout 4650552ff637bb44ecf7784060091cbed3252211 # from svn revision 692

# Download and extract PLY.
# Homepage:
# http://dabeaz.com/ply
install_dep_from_tarfile "http://dabeaz.com/ply/ply-3.4.tar.gz" "ply"

# Download and extract Jinja2.
# Homepage:
# http://jinja.pocoo.org/
# Installation instructions:
# http://jinja.pocoo.org/docs/intro/#from-the-tarball-release
# Download page:
# https://pypi.python.org/pypi/Jinja2
JINJA2_SRC_URL="https://pypi.python.org/packages/source/"
JINJA2_SRC_URL+="J/Jinja2/Jinja2-2.7.1.tar.gz"
install_dep_from_tarfile $JINJA2_SRC_URL 'jinja2'

# Download and extract MarkupSafe.
# Homepage:
# https://pypi.python.org/pypi/MarkupSafe
MARKUPSAFE_SRC_URL="https://pypi.python.org/packages/source/"
MARKUPSAFE_SRC_URL+="M/MarkupSafe/MarkupSafe-0.23.tar.gz"
install_dep_from_tarfile $MARKUPSAFE_SRC_URL 'markupsafe'

# Download and extract Cython.
mkdir -p $THIRD_PARTY_DIR/cython
cd $THIRD_PARTY_DIR/cython
read prefix cython_version <<< `pip show cython | grep "^Version:"`
echo "cython version = $cython_version"

pip_output=`pip install cython -d . --no-binary :all:`
echo "pip saved in $pip_output"

zip_type="zip"
tar_type="tar.gz"
zip_cython_package="Cython-$cython_version.$zip_type" 
#echo "zip = $zip_cython_package"
tar_cython_package="Cython-$cython_version.$tar_type"
#echo "gunzip = $tar_cython_package"

if [ -f ./$zip_cython_package ]
then
    echo "$zip_cython_package found "
    unzip $zip_cython_package
    rm -rf $zip_cython_package
elif [ -f $tar_cython_package ]
then
    echo "$tar_cython_package found "
    gunzip $tar_cython_package
    tar -xf "Cython-$cython_version.tar"
else
    echo "unknown found: `ls Cython-*` "
fi


mv "Cython-$cython_version" src

# Install the Mojo shell
$BUILD_DIR/download_mojo_shell.py
