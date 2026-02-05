#!/usr/bin/env bash
set -euo pipefail

OPENSSL_VER="3.5.0"
PREFIX="/opt/openssl-3.5"
PKGNAME="openssl-3.5"
OPENSSL_TARBALL="openssl-${OPENSSL_VER}.tar.gz"
: "${OPENSSL_SHA256:?Set OPENSSL_SHA256 to the official sha256 for ${OPENSSL_TARBALL}}"

echo "Updating apt and installing build deps..."
sudo -v
sudo DEBIAN_FRONTEND=noninteractive apt update
sudo DEBIAN_FRONTEND=noninteractive apt install -y build-essential checkinstall wget

TMPDIR=$(mktemp -d)
cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT
cd "$TMPDIR"

echo "Downloading OpenSSL $OPENSSL_VER..."
wget "https://www.openssl.org/source/${OPENSSL_TARBALL}"
echo "${OPENSSL_SHA256}  ${OPENSSL_TARBALL}" | sha256sum -c -

echo "Extracting..."
tar xf "${OPENSSL_TARBALL}"
cd "openssl-${OPENSSL_VER}"

echo "Configuring..."
./Configure \
    --prefix="${PREFIX}" \
    --openssldir="${PREFIX}" \
    linux-x86_64 \
    no-fips \
    shared

echo "Building..."
make -j"$(nproc)"

echo "Packaging and installing with checkinstall..."
sudo checkinstall \
  --pkgname="${PKGNAME}" \
  --pkgversion="${OPENSSL_VER}" \
  --backup=no \
  --fstrans=no \
  --install=yes \
  --nodoc \
  -y

echo
echo "DONE."
echo "OpenSSL 3.5 installed in: ${PREFIX}"
echo
echo "Verify with:"
echo "  ${PREFIX}/bin/openssl version"
echo
echo "To use it temporarily:"
echo "  export PATH=${PREFIX}/bin:\$PATH"
echo "  export LD_LIBRARY_PATH=${PREFIX}/lib:\$LD_LIBRARY_PATH"
echo
echo "To remove:"
echo "  sudo dpkg -r ${PKGNAME}"
echo

