#!/bin/bash
#~~~~~~~~~~
# Builds the upstream oatpp framework and publishes runtime/development apt
# packages. Oatpp's own CMake config is installed unchanged for consumers.

set -euo pipefail

version=$(tr -d ' \t\n' < VERSION.txt)
ubuntu_codename=$(lsb_release -sc)
package="simply-cpp-oatpp"
package_version="${version}~${ubuntu_codename}"

apt -y install cmake g++ git >/dev/null

rm -rf pkg work/build
mkdir -p pkg/root pkg/runtime/DEBIAN pkg/development/DEBIAN

if [ ! -d "work/oatpp-src" ]; then
    echo "Cloning oatpp $version"
    git clone --branch "$version" --depth 1 https://github.com/oatpp/oatpp.git work/oatpp-src
fi

cmake -S work/oatpp-src -B work/build \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=ON \
    -DOATPP_BUILD_TESTS=OFF \
    -DOATPP_LINK_TEST_LIBRARY=OFF \
    -DOATPP_INSTALL=ON \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build work/build -j"$(nproc)"
DESTDIR="$(pwd)/pkg/root" cmake --install work/build --prefix /usr

mkdir -p pkg/runtime/usr/lib pkg/development/usr/lib pkg/development/usr
mv pkg/root/usr/lib/liboatpp.so.* pkg/runtime/usr/lib/
if [ -e pkg/root/usr/lib/liboatpp.so ]; then
    mv pkg/root/usr/lib/liboatpp.so pkg/development/usr/lib/
fi
if [ -e pkg/root/usr/lib/liboatpp.a ]; then
    mv pkg/root/usr/lib/liboatpp.a pkg/development/usr/lib/
fi
mv pkg/root/usr/include pkg/development/usr/
if [ -d pkg/root/usr/lib/cmake ]; then
    mv pkg/root/usr/lib/cmake pkg/development/usr/lib/
fi
rmdir pkg/root/usr/lib pkg/root/usr

cat > pkg/runtime/DEBIAN/control <<EOF
Package: $package
Version: $package_version
Architecture: amd64
Section: libs
Priority: optional
Maintainer: Roelof Rossouw
Description: oatpp web framework runtime
 Oatpp web framework, built from upstream source for Ubuntu $ubuntu_codename.
EOF

cat > pkg/development/DEBIAN/control <<EOF
Package: ${package}-dev
Version: $package_version
Architecture: amd64
Section: libdevel
Priority: optional
Maintainer: Roelof Rossouw
Depends: $package (= $package_version)
Description: oatpp web framework development files
 Headers, CMake package configuration, and link-time files for oatpp.
EOF

for script in postinst postrm; do
    cat > "pkg/runtime/DEBIAN/$script" <<'EOF'
#!/bin/sh
set -e
ldconfig
EOF
    chmod 755 "pkg/runtime/DEBIAN/$script"
done

dpkg-deb --build --root-owner-group pkg/runtime "${package}_${package_version}_amd64.deb"
dpkg-deb --build --root-owner-group pkg/development "${package}-dev_${package_version}_amd64.deb"

pushd /var/www/build/repo >/dev/null
export GNUPGHOME=/var/www/build/signing
for package_name in "$package" "${package}-dev"; do
    if reprepro list "$ubuntu_codename" | grep -q "$package_name .*$package_version"; then
        echo "$ubuntu_codename: $package_name $package_version already published"
        continue
    fi
    reprepro remove "$ubuntu_codename" "$package_name" || true
    reprepro includedeb "$ubuntu_codename" "/var/www/build/sc-oatpp/${package_name}_${package_version}_amd64.deb"
done
popd >/dev/null

echo "Published oatpp $package_version for $ubuntu_codename"
