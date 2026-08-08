{
  art-standalone,
  lib,
  stdenv,
  bionic-translation_patched,
  vixl,
  wolfssl,
  expat,
  icu,
  libbsd,
  libpng,
  lz4,
  openssl,
  xz,
  zlib,
  libcap,
  ...
}:

let
  vixl_patched = vixl.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      find . -type f -exec sed -i -E -e 's/-Werror//g' -e 's/werror=true/werror=false/g' -e 's/operator"" _h/operator""_h/g' {} + || true
    '';
  });
in
art-standalone.overrideAttrs (old: {
  pname = "art-standalone-patched";

  patches = [
    ./no-hardcode-path-addr2line.patch
    ./dx-workaround.patch
    ./art-datetime-formatter-lambda-crash.patch
    ./dex2oat-path.patch
    ./wolfssljni-freed-session-timeout.patch
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    ./darwin-libcore.patch
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ libcap ] ++ [
    bionic-translation_patched
    ((wolfssl.override { enableJni = true; }).overrideAttrs (old: {
      doCheck = false;
    }))
    expat
    icu
    libbsd
    libpng
    lz4
    openssl
    xz
    zlib
    vixl_patched
  ];

  postPatch = (old.postPatch or "") + lib.optionalString stdenv.hostPlatform.isDarwin ''
    cp build/core/combo/HOST_darwin-x86.mk build/core/combo/HOST_darwin-arm.mk
    cp build/core/combo/HOST_darwin-x86.mk build/core/combo/HOST_darwin-arm64.mk
    find . -type f \( -name "*.mk" -o -name "Makefile" \) -exec sed -i -E -e 's/-arch [a-zA-Z0-9_]+//g' -e 's/-m32//g' -e 's/-m64//g' {} +
    sed -i 's/dladdr(art_sigsegv_fault/dladdr(reinterpret_cast<const void*>(art_sigsegv_fault)/g' art/dex2oat/dex2oat.cc
    mkdir -p prebuilts/gcc/darwin-x86/host/i686-apple-darwin-4.2.1/bin
    ln -s $(which c++) prebuilts/gcc/darwin-x86/host/i686-apple-darwin-4.2.1/bin/i686-apple-darwin10-g++
    ln -s $(which cc) prebuilts/gcc/darwin-x86/host/i686-apple-darwin-4.2.1/bin/i686-apple-darwin10-gcc
    ln -s $(which ar) prebuilts/gcc/darwin-x86/host/i686-apple-darwin-4.2.1/bin/i686-apple-darwin10-ar
    ln -s $(which nm) prebuilts/gcc/darwin-x86/host/i686-apple-darwin-4.2.1/bin/i686-apple-darwin10-nm
    ln -s $(which ld) prebuilts/gcc/darwin-x86/host/i686-apple-darwin-4.2.1/bin/i686-apple-darwin10-ld
    sed -i 's/\$(error/\$(info/g' build/core/main.mk
    sed -i 's/\$(error/\$(info/g' build/core/combo/mac_version.mk
    # darwin-libcore.patch handles libcore_io_Linux.cpp compatibility
    sed -i 's/\$(error HOST_OS must define.*/\$(info Ignore)/g' build/core/definitions.mk
    sed -i 's/\$(error.*already defined by.*)/\$(info Ignore redefined module)/g' build/core/base_rules.mk
    sed -i -e 's/-isysroot \$(mac_sdk_root)//g' -e 's/-isysroot \/Developer\/SDKs\/MacOSX10.6.sdk//g' -e 's/-mmacosx-version-min=\$(mac_sdk_version)//g' -e 's/-mmacosx-version-min=10.6//g' -e 's/-DMACOSX_DEPLOYMENT_TARGET=\$(mac_sdk_version)//g' build/core/combo/HOST_darwin-*.mk
    echo -e "define get-file-size\nstat -f \"%z\" \$\$1\nendef" >> build/core/config.mk
    sed -i 's/art::Runtime::callee_save_methods_/callee_save_methods_/g' art/runtime/runtime.h
    find . -type f \( -name "*.mk" -o -name "Makefile" \) -exec sed -i -E -e 's/libunwind//g' {} +
    sed -i '1i #include <stdbool.h>' system/core/liblog/fake_log_device.c
    sed -i 's/if (char \*liblog_color = getenv("LIBLOG_COLOR"))/char \*liblog_color = getenv("LIBLOG_COLOR");\n    if (liblog_color)/g' system/core/liblog/fake_log_device.c
    sed -i '1i typedef void (*sighandler_t)(int);' art/sigchainlib/sigchain.h
    echo "#include <sys/uio.h>" > system/core/include/log/uio.h
    mkdir -p system/core/include/sys
    cat <<'EOF_EPOLL' > system/core/include/sys/epoll.h
#ifndef _SYS_EPOLL_H
#define _SYS_EPOLL_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef union epoll_data { void *ptr; int fd; uint32_t u32; uint64_t u64; } epoll_data_t;
struct epoll_event { uint32_t events; epoll_data_t data; };
#define EPOLLIN 1
#define EPOLLWAKEUP 2
#define EPOLLOUT 4
#define EPOLLERR 8
#define EPOLLHUP 16
#define EPOLL_CTL_ADD 1
#define EPOLL_CTL_DEL 2
#define EPOLL_CTL_MOD 3
#define EPOLL_CLOEXEC 0
static inline int epoll_create(int size) { return -1; }
static inline int epoll_create1(int flags) { return -1; }
static inline int epoll_ctl(int epfd, int op, int fd, struct epoll_event *event) { return -1; }
static inline int epoll_wait(int epfd, struct epoll_event *events, int maxevents, int timeout) { return -1; }
#ifdef __cplusplus
}
#endif
#endif
EOF_EPOLL
    sed -i '/static_assert/d' system/core/libutils/include/utils/Compat.h
    sed -i '/Looper/d' system/core/libutils/Android.mk
    sed -i '/Looper/d' system/core/libutils/Android.bp
    cp ${./elf.h} system/core/include/elf.h
    find . -type f \( -name "*.mk" -o -name "Makefile" -o -name "*.bp" \) -exec sed -i 's/-Werror//g' {} +
    rm -f build/core/tasks/cts.mk build/core/tasks/boot_jars_package_check.mk
    rm -rf adb dalvik/dexdump dalvik/libdex build/tools/check_prereq
    sed -i '/libgtest/d' build/core/host_test_internal.mk build/core/target_test_internal.mk
    sed -i '71,73d' system/core/libbacktrace/Android.mk
    sed -i '78,136d' system/core/libbacktrace/Android.mk
    sed -i 's/boot-jars-package-check//g' build/core/main.mk
    sed -i '/include $(BUILD_SYSTEM)\/Makefile/d' build/core/main.mk
    find external -name Android.mk -exec sed -i -e '/include \$(BUILD_JAVA_LIBRARY)/d' -e '/include \$(BUILD_STATIC_JAVA_LIBRARY)/d' {} +
    rm -f external/icu/android_icu4j/Android.mk

    sed -i "s|-I/usr/local/include/vixl|-I${vixl_patched}/include/vixl|g" art/build/Android.common_build.mk
    sed -i 's/libvixld//g' art/disassembler/Android.mk

    sed -i 's/#include <byteswap.h>/#ifndef __APPLE__\n#include <byteswap.h>\n#else\n#include <libkern\/OSByteOrder.h>\n#define bswap_16 OSSwapInt16\n#define bswap_32 OSSwapInt32\n#define bswap_64 OSSwapInt64\n#endif/' libcore/luni/src/main/native/Portability.h
    sed -i 's/#include <sys\/sendfile.h>/#ifndef __APPLE__\n#include <sys\/sendfile.h>\n#endif/' libcore/luni/src/main/native/Portability.h libcore/luni/src/main/native/libcore_io_Linux.cpp
    sed -i 's/#include <sys\/prctl.h>/#ifndef __APPLE__\n#include <sys\/prctl.h>\n#endif/' libcore/luni/src/main/native/android_system_OsConstants.cpp libcore/luni/src/main/native/libcore_io_Linux.cpp
    if [ "$(uname)" = "Darwin" ]; then
        sed -i '/netpacket\/packet\.h/d; /sys\/capability\.h/d; /linux\/if_ether\.h/d; /linux\/if_addr\.h/d; /linux\/rtnetlink\.h/d; /linux\/udp\.h/d; /linux\/capability\.h/d' libcore/luni/src/main/native/android_system_OsConstants.cpp libcore/luni/src/main/native/libcore_io_Linux.cpp
        sed -i '/ETH_P_/d; /RTMGRP_/d; /UDP_ENCAP/d; /AF_PACKET/d; /AF_NETLINK/d' libcore/luni/src/main/native/android_system_OsConstants.cpp
        sed -i '/RT_SCOPE_/d; /ST_MANDLOCK/d; /ST_NOATIME/d; /ST_NODEV/d; /ST_NODIRATIME/d; /ST_NOEXEC/d; /ST_RELATIME/d; /ST_SYNCHRONOUS/d' libcore/luni/src/main/native/android_system_OsConstants.cpp
        sed -i '/ARPHRD_LOOPBACK/d; /ENONET/d; /IP_MULTICAST_ALL/d; /MAP_POPULATE/d; /NETLINK_NETFILTER/d; /NETLINK_ROUTE/d' libcore/luni/src/main/native/android_system_OsConstants.cpp
        find libandroidfw libziparchive -type f -exec sed -i -E -e 's/off64_t/off_t/g' -e 's/android-base\/off_t\.h/android-base\/off64_t.h/g' -e 's/lseek64/lseek/g' -e 's/pread64/pread/g' -e 's/pwrite64/pwrite/g' -e 's/ftruncate64/ftruncate/g' -e 's/mmap64/mmap/g' -e 's/stat64/stat/g' -e 's/fstat64/fstat/g' -e 's/lstat64/lstat/g' {} +
    fi
    find build/core/combo -name "HOST_darwin-*.mk" -exec bash -c 'echo "HOST_GLOBAL_LDFLAGS += -Wl,-undefined,dynamic_lookup" >> "$1"' _ {} \;
    find . -type f \( -name "Android.mk" -o -name "Android.*.mk" \) -exec sed -i -e 's/-Wl,--export-dynamic//g' {} +
    find art/runtime/arch -type f -name "*.S" -exec sed -i -E -e 's/\.fnstart//g' -e 's/\.fnend//g' -e '/\.size/d' -e '/\.type/d' -e '/\.hidden/d' {} +
    sed -i -e '105s/.*/ifneq ($(HOST_OS),windows)/' -e '174s/.*/endif/' libcore/NativeCode.mk
    sed -i -e '97s/.*/ifneq ($(HOST_OS),windows)/' -e '226s/.*/endif/' libcore/JavaLibrary.mk
    echo "#!/bin/sh" > build/tools/check_radio_versions.py
    echo "exit 0" >> build/tools/check_radio_versions.py
    chmod +x build/tools/check_radio_versions.py
    echo -e "\nsystemimage:\n\t@echo Dummy systemimage\n" >> build/core/main.mk
  '';

  meta = (old.meta or {}) // {
    platforms = lib.platforms.all;
  };
})
