{
  lib,
  stdenv,
  android-translation-layer,
  art-standalone_patched,
  bionic-translation_patched,
  cacert,
  webp-pixbuf-loader,
  gdk-pixbuf,
  librsvg,
  fetchpatch,
  wrapGAppsHook4,
  vulkan-loader,
  vulkan-headers,
}:

(android-translation-layer.override (
  {
    art-standalone = art-standalone_patched;
    bionic-translation = bionic-translation_patched;
  }
  // lib.optionalAttrs (!stdenv.hostPlatform.isLinux) {
    alsa-lib = null;
    libdrm = null;
    libgudev = null;
    wayland = null;
    wayland-protocols = null;
    wayland-scanner = null;
    libportal-gtk4 = null;
    webkitgtk_6_0 = null;
  }
)).overrideAttrs
  (old: {
    pname = "android-translation-layer-patched";
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
      wrapGAppsHook4
    ];
    buildInputs = (old.buildInputs or [ ]) ++ [
      webp-pixbuf-loader
      vulkan-loader
      vulkan-headers
    ];
    patches = (old.patches or [ ]) ++ [
      ./android-translation-layer-bitmap-unlock.patch
      ./android-translation-layer-bitmapfactory-logs.patch
      ./android-translation-layer-kotatsu-stub.patch
      (fetchpatch {
        url = "https://gitlab.com/android_translation_layer/android_translation_layer/-/merge_requests/290.patch";
        hash = "sha256-Aan2AnrLSFLURWVggpxMM2Sztkhy0g7atSeQDGJasz8=";
      })
      (fetchpatch {
        url = "https://gitlab.com/android_translation_layer/android_translation_layer/-/merge_requests/251.patch";
        hash = "sha256-Y39nuhVGcGP/H61ZbyclMyAO2HjsC2VVl4R86N8c0K0=";
      })
      ./android-translation-layer-fdroid-stub.patch
      ./android-translation-layer-context-stub.patch
      ./android-translation-layer-newpipe-esc-stub.patch
      ./android-translation-layer-newpipe-red-layer.patch
      ./android-translation-layer-wifiinfo-ssid-stub.patch
      ./android-translation-layer-apk-sourcedir.patch
      ./android-translation-layer-wifi-ap-stub.patch
      ./android-translation-layer-system-app-certs.patch
      ./android-translation-layer-gtk-measure.patch
      ./android-translation-layer-wrapper-measure-fix.patch
      ./android-translation-layer-imagebutton-scale.patch
      ./android-translation-layer-view-fullscreen-fix.patch
      ./android-translation-layer-gtk-native-check.patch
      ./android-translation-layer-media-data-source.patch
      ./android-translation-layer-drawlines-bounds.patch
      ./android-translation-layer-concat-2d.patch
      ./android-translation-layer-audiomanager-getdevices.patch
      ./android-translation-layer-networkcapabilities.patch
      ./android-translation-layer-path-op.patch
      ./android-translation-layer-bitmap-pixels-fix.patch
      ./android-translation-layer-bitmap-factory-null-pixbuf.patch
      ./android-translation-layer-bitmap-factory-fd.patch
      ./android-translation-layer-color-state-list-magenta.patch
      ./android-translation-layer-paint-color-filter-matrix.patch
      ./android-translation-layer-cairo-fallback.patch
      ./android-translation-layer-mr248-ads-stubs.patch
      ./android-translation-layer-microg-poc.patch
      ./android-translation-layer-gms-startservice-poc.patch
      ./android-translation-layer-gms-availability-stub.patch
      ./android-translation-layer-firebase-stubs.patch
      ./android-translation-layer-gms-client-stubs.patch
      ./android-translation-layer-gms-tasks-stubs.patch
      ./android-translation-layer-gms-location-stubs.patch
    ];
    postPatch = (old.postPatch or "") + lib.optionalString stdenv.isDarwin ''
      substituteInPlace meson.build \
        --replace-warn "dependency('wayland-protocols', version: '>=1.12')" "dependency('dummy', required: false)" \
        --replace-warn "dependency('wayland-client')" "dependency('dummy', required: false)" \
        --replace-warn "dependency('libportal')" "dependency('dummy', required: false)" \
        --replace-warn "dependency('libdrm')" "dependency('dummy', required: false)" \
        --replace-warn "dependency('gudev-1.0')" "dependency('dummy', required: false)" \
        --replace-warn "dependency('webkitgtk-6.0')" "dependency('dummy', required: false)" \
        --replace-warn "'-lasound'" "" \
        --replace-warn "'-Wl,-z,lazy'," "" \
        --replace-warn "subdir('protocol')" "wl_proto_headers = []" \
        --replace-warn "wl_proto_sources," ""
      rm -rf protocol

      substituteInPlace src/libandroid/native_window.c \
        --replace-warn "typedef XrResult (*xr_func)(...);" "typedef XrResult (*xr_func)();" \
        --replace-warn "return func(__builtin_va_arg_pack());" "return -1;"

      echo -e "#ifdef __APPLE__\n#include <jni.h>\nJNIEXPORT jint JNICALL Java_android_os_Vibrator_native_1constructor(JNIEnv *env, jobject this) { return -1; }\nJNIEXPORT void JNICALL Java_android_os_Vibrator_native_1vibrate(JNIEnv *env, jobject this, jint fd, jlong duration) {}\n#else\n$(cat src/api-impl-jni/android_os_Vibrator.c)\n#endif" > src/api-impl-jni/android_os_Vibrator.c
      
      echo -e "#ifndef __APPLE__\n$(cat src/main-executable/bionic_compat.c)\n#else\nvoid init__r_debug() {}\n#endif" > src/main-executable/bionic_compat.c

      echo -e "#ifdef __APPLE__\n#include <jni.h>\nJNIEXPORT jlong JNICALL Java_android_app_NotificationManager_nativeInitBuilder(JNIEnv *env, jobject this) { return 0; }\nJNIEXPORT void JNICALL Java_android_app_NotificationManager_nativeAddAction(JNIEnv *env, jobject this, jlong builder_ptr, jstring name_jstr, jint type, jobject intent) {}\nJNIEXPORT void JNICALL Java_android_app_NotificationManager_nativeShowNotification(JNIEnv *env, jobject this, jlong builder_ptr, jint id, jstring title_jstr, jstring text_jstr, jstring icon_jstr, jboolean ongoing, jint type, jobject intent) {}\nJNIEXPORT void JNICALL Java_android_app_NotificationManager_nativeCancel(JNIEnv *env, jobject this, jint id) {}\nJNIEXPORT void JNICALL Java_android_app_NotificationManager_nativeShowMPRIS(JNIEnv *env, jobject this, jstring package_name_jstr, jstring identity_jstr) {}\nJNIEXPORT void JNICALL Java_android_app_NotificationManager_nativeCancelMPRIS(JNIEnv *env, jobject this) {}\n#else\n$(cat src/api-impl-jni/app/android_app_NotificationManager.c)\n#endif" > src/api-impl-jni/app/android_app_NotificationManager.c

      echo -e "#ifdef __APPLE__\n#include <jni.h>\nJNIEXPORT jlong JNICALL Java_android_inputmethodservice_InputMethodService_00024ATLInputConnection_nativeInit(JNIEnv *env, jobject this) { return 0; }\nJNIEXPORT jboolean JNICALL Java_android_inputmethodservice_InputMethodService_00024ATLInputConnection_nativeSetCompositingText(JNIEnv *env, jobject this, jlong ptr, jstring text, jint newCursorPosition) { return 0; }\nJNIEXPORT jboolean JNICALL Java_android_inputmethodservice_InputMethodService_00024ATLInputConnection_nativeSetCompositingRegion(JNIEnv *env, jobject this, jlong ptr, jint start, jint end) { return 0; }\nJNIEXPORT jboolean JNICALL Java_android_inputmethodservice_InputMethodService_00024ATLInputConnection_nativeFinishComposingText(JNIEnv *env, jobject this, jlong ptr) { return 0; }\nJNIEXPORT jboolean JNICALL Java_android_inputmethodservice_InputMethodService_00024ATLInputConnection_nativeCommitText(JNIEnv *env, jobject this, jlong ptr, jstring text, jint newCursorPosition) { return 0; }\nJNIEXPORT jboolean JNICALL Java_android_inputmethodservice_InputMethodService_00024ATLInputConnection_nativeDeleteSurroundingText(JNIEnv *env, jobject this, jlong ptr, jint beforeLength, jint afterLength) { return 0; }\nJNIEXPORT jboolean JNICALL Java_android_inputmethodservice_InputMethodService_00024ATLInputConnection_nativeSetSelection(JNIEnv *env, jobject this, jlong ptr, jint start, jint end) { return 0; }\nJNIEXPORT jboolean JNICALL Java_android_inputmethodservice_InputMethodService_00024ATLInputConnection_nativeSendKeyEvent(JNIEnv *env, jobject this, jlong ptr, jlong time, jlong key, jlong state) { return 0; }\n#else\n$(cat src/api-impl-jni/android_inputmethodservice_InputMethodService.c)\n#endif" > src/api-impl-jni/android_inputmethodservice_InputMethodService.c

      echo -e "#ifdef __APPLE__\n#include <jni.h>\nJNIEXPORT void JNICALL Java_android_app_WallpaperManager_set_1bitmap(JNIEnv *env, jclass clazz, jlong texture_ptr) {}\n#else\n$(cat src/api-impl-jni/app/android_app_WallpaperManager.c)\n#endif" > src/api-impl-jni/app/android_app_WallpaperManager.c
    '';
    preConfigure = (old.preConfigure or "") + lib.optionalString stdenv.isDarwin ''
      mkdir -p $NIX_BUILD_TOP/darwin_headers
      cat << 'EOF' > $NIX_BUILD_TOP/darwin_headers/uchar.h
#ifndef UCHAR_H
#define UCHAR_H
#include <stdint.h>
typedef uint_least16_t char16_t;
typedef uint_least32_t char32_t;
#endif
EOF
      mkdir -p $NIX_BUILD_TOP/darwin_headers/gdk/wayland
      cat << 'EOF' > $NIX_BUILD_TOP/darwin_headers/gdk/wayland/gdkwayland.h
#ifndef GDK_WAYLAND_H
#define GDK_WAYLAND_H
#define GDK_IS_WAYLAND_DISPLAY(display) (0)
#define GDK_IS_WAYLAND_TOPLEVEL(...) (0)
#define GDK_WAYLAND_TOPLEVEL(...) NULL
#define gdk_wayland_toplevel_set_application_id(...)
#define gdk_wayland_display_get_wl_display(display) NULL
#define gdk_wayland_display_get_wl_compositor(display) NULL
#define gdk_wayland_surface_get_wl_surface(surface) NULL
#endif
EOF
      mkdir -p $NIX_BUILD_TOP/darwin_headers/gdk/x11
      cat << 'EOF' > $NIX_BUILD_TOP/darwin_headers/gdk/x11/gdkx.h
#ifndef GDK_X11_H
#define GDK_X11_H
#define GDK_IS_X11_DISPLAY(display) (0)
#define gdk_x11_display_get_egl_version(...) 0
#define gdk_x11_display_get_xdisplay(...) NULL
#define gdk_x11_surface_get_xid(...) 0
#endif
EOF
      cat << 'EOF' > $NIX_BUILD_TOP/darwin_headers/wayland-client.h
#ifndef WAYLAND_CLIENT_H
#define WAYLAND_CLIENT_H
#include <stdint.h>
struct wl_display {};
struct wl_compositor {};
struct wl_surface {};
struct wl_subsurface {};
struct wl_region {};
struct wl_registry {};
struct wl_registry_listener {
    void (*global)(void *, struct wl_registry *, uint32_t, const char *, uint32_t);
    void (*global_remove)(void *, struct wl_registry *, uint32_t);
};
struct wl_interface {};
#define wl_display_get_registry(...) NULL
#define wl_registry_add_listener(...)
#define wl_display_roundtrip(...)
#define wl_compositor_create_surface(...) NULL
#define wl_subcompositor_get_subsurface(...) NULL
#define wl_subsurface_set_desync(...)
#define wl_subsurface_set_position(...)
#define wl_subsurface_place_below(...)
#define wl_compositor_create_region(...) NULL
#define wl_surface_set_input_region(...)
#define wl_region_destroy(...)
#define wl_surface_destroy(...)
#define wl_registry_bind(...) NULL
extern struct wl_interface wl_subcompositor_interface;
extern struct wl_interface wl_compositor_interface;
#endif
EOF
      cat << 'EOF' > $NIX_BUILD_TOP/darwin_headers/wayland-egl.h
#ifndef WAYLAND_EGL_H
#define WAYLAND_EGL_H
#include <wayland-client.h>
struct wl_egl_window {};
#define wl_egl_window_create(...) NULL
#define wl_egl_window_destroy(...)
#define wl_egl_window_resize(...)
#endif
EOF
      mkdir -p $NIX_BUILD_TOP/darwin_headers/X11/extensions
      cat << 'EOF' > $NIX_BUILD_TOP/darwin_headers/X11/Xlib.h
#ifndef XLIB_H
#define XLIB_H
typedef void* Display;
typedef unsigned long Window;
#define XDestroyWindow(...)
#define XResizeWindow(...)
#define XCreateSimpleWindow(...) 0
#define DefaultRootWindow(...) 0
#define XReparentWindow(...)
#define XMapWindow(...)
#endif
EOF
      cat << 'EOF' > $NIX_BUILD_TOP/darwin_headers/X11/Xutil.h
#ifndef XUTIL_H
#define XUTIL_H
typedef void* Region;
typedef struct { short x, y; unsigned short width, height; } XRectangle;
#define XCreateRegion(...) NULL
#define XUnionRectWithRegion(...)
#define XDestroyRegion(...)
#endif
EOF
      cat << 'EOF' > $NIX_BUILD_TOP/darwin_headers/X11/extensions/shape.h
#ifndef SHAPE_H
#define SHAPE_H
#define ShapeBounding 0
#define ShapeSet 0
#define XShapeCombineRegion(...)
#endif
EOF
      mkdir -p $NIX_BUILD_TOP/darwin_headers/vulkan
      cat << 'EOF' > $NIX_BUILD_TOP/darwin_headers/vulkan/vulkan_wayland.h
#ifndef VULKAN_WAYLAND_H
#define VULKAN_WAYLAND_H
#include <vulkan/vulkan.h>
typedef struct VkWaylandSurfaceCreateInfoKHR {
    int sType;
    void* display;
    void* surface;
} VkWaylandSurfaceCreateInfoKHR;
#define VK_STRUCTURE_TYPE_WAYLAND_SURFACE_CREATE_INFO_KHR 0
#define vkCreateWaylandSurfaceKHR(...) VK_ERROR_EXTENSION_NOT_PRESENT
#endif
EOF
      cat << 'EOF' > $NIX_BUILD_TOP/darwin_headers/vulkan/vulkan_xlib.h
#ifndef VULKAN_XLIB_H
#define VULKAN_XLIB_H
#include <vulkan/vulkan.h>
typedef void* Display;
typedef unsigned long Window;
typedef struct VkXlibSurfaceCreateInfoKHR {
    int sType;
    const void* pNext;
    int flags;
    Display* dpy;
    Window window;
} VkXlibSurfaceCreateInfoKHR;
#define VK_STRUCTURE_TYPE_XLIB_SURFACE_CREATE_INFO_KHR 0
#define vkCreateXlibSurfaceKHR(...) VK_ERROR_EXTENSION_NOT_PRESENT
#endif
EOF
      mkdir -p $NIX_BUILD_TOP/darwin_headers/sys
      cat << 'EOF' > $NIX_BUILD_TOP/darwin_headers/sys/mman.h
#include_next <sys/mman.h>
#include <stdlib.h>
#include <unistd.h>
#ifndef MFD_CLOEXEC
#define MFD_CLOEXEC 0
#endif
static inline int memfd_create(const char *name, unsigned int flags) {
    char path[] = "/tmp/memfd-XXXXXX";
    int fd = mkstemp(path);
    if (fd >= 0) unlink(path);
    return fd;
}
EOF
      mkdir -p $NIX_BUILD_TOP/darwin_headers/gudev
      touch $NIX_BUILD_TOP/darwin_headers/gudev/gudev.h
      mkdir -p $NIX_BUILD_TOP/darwin_headers/libportal
      cat << 'EOF' > $NIX_BUILD_TOP/darwin_headers/libportal/portal.h
#ifndef PORTAL_H
#define PORTAL_H
typedef struct XdpPortal XdpPortal;
#define XDP_OPEN_URI_FLAG_NONE 0
#define XDP_LAUNCHER_APPLICATION 0
#define XDP_PORTAL(x) ((XdpPortal*)(x))
#define XDP_WALLPAPER_FLAG_NONE 0
static inline XdpPortal* xdp_portal_new(void) { return 0; }
static inline void xdp_portal_open_uri(XdpPortal* portal, void* parent, const char* uri, int flags, void* cancellable, void* callback, void* user_data) {}
static inline void* xdp_portal_dynamic_launcher_prepare_install_finish(XdpPortal* p1, void* p2, void* p3) { return 0; }
static inline void xdp_portal_dynamic_launcher_install(XdpPortal* p1, void* p2, void* p3, void* p4, void* p5) {}
static inline void xdp_portal_dynamic_launcher_prepare_install(XdpPortal* p1, void* p2, void* p3, void* p4, void* p5, void* p6, int p7, int p8, void* p9, void* p10, void* p11) {}
static inline void xdp_portal_set_wallpaper_finish(XdpPortal* p1, void* p2, void* p3) {}
static inline void xdp_portal_set_wallpaper(XdpPortal* p1, void* p2, void* p3, int p4, void* p5, void* p6, void* p7) {}
#endif
EOF
      cat << 'EOF' > $NIX_BUILD_TOP/darwin_headers/elf.h
#ifndef ELF_H
#define ELF_H
#endif
EOF
      cat << 'EOF' > $NIX_BUILD_TOP/darwin_headers/link.h
#ifndef LINK_H
#define LINK_H
struct r_debug {};
typedef struct { int d_tag; union { void* d_ptr; } d_un; } ElfW_Dyn;
#define ElfW(type) ElfW_##type
#define DT_DEBUG 21
#endif
EOF
      export CFLAGS="-I$NIX_BUILD_TOP/darwin_headers -Wno-int-conversion -Wno-c23-extensions -Doff64_t=off_t -Dlseek64=lseek -Dftruncate64=ftruncate -Dpread64=pread -Dpwrite64=pwrite -DCLOCK_BOOTTIME=CLOCK_MONOTONIC $CFLAGS"
      substituteInPlace src/main-executable/main.c \
        --replace-warn "__attribute__((section(\".interp\")))" ""
    '';
    postInstall = (old.postInstall or "") + ''
      mkdir -p $out/etc/security
      ln -s ${cacert.unbundled}/etc/ssl/certs $out/etc/security/cacerts
    '';
    preFixup = (old.preFixup or "") + ''
      mkdir -p $out/lib/gdk-pixbuf-2.0/2.10.0
      GDK_PIXBUF_MODULEDIR=${gdk-pixbuf}/lib/gdk-pixbuf-2.0/2.10.0/loaders ${gdk-pixbuf.dev}/bin/gdk-pixbuf-query-loaders > $out/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
      cat ${librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache >> $out/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
      GDK_PIXBUF_MODULEDIR=${webp-pixbuf-loader}/lib/gdk-pixbuf-2.0/2.10.0/loaders ${gdk-pixbuf.dev}/bin/gdk-pixbuf-query-loaders >> $out/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache

      gappsWrapperArgs+=(
        --set ANDROID_ROOT $out
        --set GDK_PIXBUF_MODULE_FILE $out/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
      )
    '';
    postFixup = (old.postFixup or "") + "";
  })
