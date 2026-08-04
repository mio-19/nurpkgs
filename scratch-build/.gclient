# Auto-updated on each sync.
#
# Customize via brave/.env:
#   - projects_chrome_custom_deps: Override chromium solution's custom_deps
#       Example: projects_chrome_custom_deps={"src/third_party/some_dep": null}
#   - projects_chrome_custom_vars: Override chromium solution's custom_vars
#       Example: projects_chrome_custom_vars={"checkout_clangd": true}
#   - gclient_global_vars: Override top-level .gclient variables
#       Example: gclient_global_vars={"delete_unversioned_trees": true}
#
# Key prefixes can be used to override specific values:
#   projects_chrome_custom_vars_checkout_clangd=true
#   gclient_global_vars_delete_unversioned_trees=true
#
# Multiline values can be defined using single quotes:
#   projects_chrome_custom_vars='{
#     "checkout_clang_tidy": true,
#     "checkout_clangd": true
#   }'
#
# Note: target_os and target_cpu persist unless set via CLI.

solutions = [
  {
    "managed": False,
    "name": "src",
    "url": "https://chromium.googlesource.com/chromium/src.git",
    "custom_deps": {
      "src/testing/libfuzzer/fuzzers/wasm_corpus": None,
      "src/third_party/chromium-variations": None
    },
    "custom_vars": {
      "checkout_pgo_profiles": False,
      "checkout_clang_coverage_tools": True,
      "checkout_clangd": True,
      "download_reclient": True
    }
  },
  {
    "managed": False,
    "name": "src/brave",
    "url": "https://github.com/brave/brave-core.git"
  }
]
target_os = []
target_cpu = []
