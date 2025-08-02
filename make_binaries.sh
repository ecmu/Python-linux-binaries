#!/usr/bin/env bash
set -x #echo on
set -e #Exists on errors

#alias ll="ls -al"

SCRIPTPATH=$(cd $(dirname "$BASH_SOURCE") && pwd)
echo "SCRIPTPATH = $SCRIPTPATH"
pushd ${SCRIPTPATH}

export APP=Python
export LOWERAPP=${APP,,}
export APPDIR="${SCRIPTPATH}/appdir"

#=== Define GnuCash version to build

#Workaround for build outside github: "env" file should then contain exports of github variables.
if [ -f "./env" ];
then
  source ./env
fi

if [ "$GITHUB_REF_NAME" = "" ];
then
	echo "Please define tag for this release (GITHUB_REF_NAME)"
	exit 1
fi

#Get App version from tag, excluding suffixe "-Revision" used only for specific AppImage builds...
export VERSION=$(echo $GITHUB_REF_NAME | cut -d'-' -f1)

#=== Package installations for building

sudo DEBIAN_FRONTEND=noninteractive apt-get install --yes libbz2-dev libncurses-dev libgdbm-dev libz-dev tk-dev libsqlite3-dev libreadline-dev liblzma-dev libffi-dev libssl-dev

#=== Get App source

if [ ! -f "./${LOWERAPP}-${VERSION}.tar.gz" ];
then
  wget --continue "https://github.com/python/cpython/archive/refs/tags/v${VERSION}.tar.gz" --output-document="${LOWERAPP}-${VERSION}.tar.gz"
  rm --recursive --force "./${LOWERAPP}-${VERSION}"
fi

if [ ! -d "./cpython-${VERSION}" ];
then
  tar --extract --file="./${LOWERAPP}-${VERSION}.tar.gz"
fi

#=== Compile main App

APP_BuildDir="${LOWERAPP}-${VERSION}_build"

if [ ! -d "${APP_BuildDir}" ];
then
  mkdir "${APP_BuildDir}"
  pushd "${APP_BuildDir}"

  #if [ -z "$TZ" ];
  #then #dpkg-reconfigure tzdata
  #  export TZ='America/Los_Angeles' #'Europe/Paris'
  #fi

	../cpython-${VERSION}/configure --prefix=/usr --enable-shared --enable-optimizations --without-static-libpython --with-builtin-libffi
	make -j$(nproc)

  popd
fi

#=== Install main application into AppDir

if [ ! -d "${APPDIR}" ];
then
  mkdir --parents "${APPDIR}"

  pushd "${APP_BuildDir}"
  make  DESTDIR="${APPDIR}" install
  popd
  
  #chown --recursive 1000 "${APPDIR}"
fi

#=== Bundle additional libraries into AppDir

cp --archive /usr/lib/x86_64-linux-gnu/libcrypto.so* "${APPDIR}/usr/lib"
cp --archive /usr/lib/x86_64-linux-gnu/libffi.so* "${APPDIR}/usr/lib"
cp --archive /usr/lib/x86_64-linux-gnu/libssl.so* "${APPDIR}/usr/lib"

#=== Create global wrapper to launch python

cat >${APPDIR}/usr/python <<EOF
#!/usr/bin/env bash
#set -x #echo on
#set -e #Exists on errors

export PYTHONHOME=\$(cd \$(dirname \$(realpath "\$BASH_SOURCE")) && pwd)
export PATH="\$PYTHONHOME"/bin:\$PATH
export LD_LIBRARY_PATH="\${PYTHONHOME}/lib\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
python3 \$@
EOF

chmod +x ${APPDIR}/usr/python
 
#=== Make binary tarball

pushd ${APPDIR}/usr
tar --create --file="${SCRIPTPATH}/python_binaries-${VERSION}.tar.gz" *
popd

#===

popd
