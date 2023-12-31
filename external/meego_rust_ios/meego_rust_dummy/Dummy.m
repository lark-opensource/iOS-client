//
//  Dummy.m
//  meego_rust_ios
//
//  Created by Qinghua Hong on 2022/5/31.
//

#import "meego_rust_ffi.h"

@interface MeegoRustDummy : NSObject

@end

@implementation MeegoRustDummy

+ (void)dummy {
    // FIXME: ios will strip all symbols from libmeego_rust.a
    // if there is no explicit usage in source code
    uniffi_rustbuffer_from_bytes((struct ForeignBytes){0}, NULL);
    uniffi_rustbuffer_free((struct RustBuffer){0}, NULL);
    molten_ffi_meego_rust_call0(0, NULL);
    molten_ffi_meego_rust_call1(0, (struct RustBuffer){0}, NULL);
    molten_ffi_meego_rust_call2(0, NULL);
    molten_ffi_meego_rust_call3(0, (struct RustBuffer){0}, NULL);
}

@end
