import json
import sys
import os

def generate_zig(wit_json, out_dir):
    zig_code = """// Generated native Zig bindings
const std = @import("std");

pub const string = extern struct {
    ptr: [*]u8,
    len: usize,
};

pub const field = extern struct {
    key: string,
    at: u32,
};

pub const list_u32 = extern struct {
    ptr: [*]u32,
    len: usize,
};

pub const list_field = extern struct {
    ptr: [*]field,
    len: usize,
};

pub const cell_tag = enum(u8) {
    empty = 0,
    flag = 1,
    int = 2,
    float = 3,
    text = 4,
    items = 5,
    dict = 6,
    fail = 7,
};

pub const cell = extern struct {
    tag: u8,
    val: extern union {
        flag: bool,
        int: i64,
        float: f64,
        text: string,
        items: list_u32,
        dict: list_field,
        fail: string,
    },
};

pub const list_cell = extern struct {
    ptr: [*]cell,
    len: usize,
};

pub const value = extern struct {
    cells: list_cell,
    root: u32,
};

pub const list_string = extern struct {
    ptr: [*]string,
    len: usize,
};

pub extern "hanga:engine/host" fn log(level: *const string, message: *const string) void;
pub extern "hanga:engine/host" fn @"now-ms"() i64;
pub extern "hanga:engine/host" fn id(ret: *string) void;
pub extern "hanga:engine/host" fn peers(ret: *list_string) void;
pub extern "hanga:engine/host" fn @"has-mod"(name: *const string) bool;
pub extern "hanga:engine/host" fn invoke(peer: *const string, method: *const string, args: *const value, ret: *value) void;
pub extern "hanga:engine/host" fn send(peer: *const string, method: *const string, args: *const value) void;
pub extern "hanga:engine/host" fn emit(method: *const string, args: *const value) bool;
pub extern "hanga:engine/host" fn voxel(x: i32, y: i32, z: i32, ret: *value) void;
pub extern "hanga:engine/host" fn @"voxel-set"(x: i32, y: i32, z: i32, name: *const string) void;
pub extern "hanga:engine/host" fn player(ret: *value) void;
pub extern "hanga:engine/host" fn after(ms: i32, method: *const string, args: *const value) void;

pub export fn cabi_realloc(orig_ptr: ?*anyopaque, orig_size: usize, align_: usize, new_size: usize) ?*anyopaque {
    _ = orig_ptr;
    _ = orig_size;
    _ = align_;
    if (new_size == 0) return null;
    const slice = std.heap.wasm_allocator.alloc(u8, new_size) catch return null;
    return @ptrCast(slice.ptr);
}
"""
    os.makedirs(out_dir, exist_ok=True)
    with open(os.path.join(out_dir, "plugin.zig"), "w") as f:
        f.write(zig_code)

if __name__ == "__main__":
    generate_zig(sys.argv[1], sys.argv[2])
