//
//  HMDThreadBacktraceFrame.m
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/5/8.
//

#import <dlfcn.h>
#import "HMDThreadBacktraceFrame.h"
#import "hmd_symbolicator.h"
#import "HMDCompactUnwind.hpp"
#import "HMDAsyncThread.h"
#import "hmd_mach.h"
#import "hmd_thread_backtrace.h"
#import "HMDMacro.h"
// Utility
#import "HMDMacroManager.h"

NSString* getDemangleName(NSString * mangleName){
//#if !HMD_APPSTORE_REVIEW_FIXUP
    static char* (*swift_demangle)(const char *mangledName,
                                   size_t mangledNameLength,
                                   char *outputBuffer,
                                   size_t *outputBufferSize,
                                   uint32_t flags) = nullptr;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        swift_demangle = (char *(*)(const char *, size_t, char *, size_t *, uint32_t))dlsym(RTLD_DEFAULT, "swift_demangle");
    });
    if (swift_demangle != nullptr) {
        size_t demangledSize = 0;
        char *demangleName = swift_demangle(mangleName.UTF8String, mangleName.length, nullptr, &demangledSize, 0);
        if (demangleName != nullptr) {
            NSString *demangleNameStr = [NSString stringWithFormat:@"%s",demangleName];
            free(demangleName);
            return demangleNameStr;
        }
    }
//#endif
    return mangleName;
}


@implementation HMDThreadBacktraceFrame

#pragma mark HMDJSONable
- (NSDictionary *)jsonObject {
    return @{
        @"stack_index" : @(self.stackIndex),
        @"address" : @(self.address),
        @"image_address" : @(self.imageAddress),
        @"image_name" : self.imageName ?: @"",
        @"symbol_address" : @(self.symbolAddress),
        @"symbol_name" : self.symbolName ?: @""
    };
}

- (NSString *)description {
    NSMutableString *string = [NSMutableString
        stringWithFormat:@"%-2lu   %-25s 0x%8lx 0x%8lx", (unsigned long)_stackIndex,
                         _imageName.length > 0 ? _imageName.UTF8String : "NULL", _imageAddress, _address];
    if (_symbolName) {
        [string appendFormat:@" %@ + %li", _symbolName, _address - _symbolAddress];
    }
    return string;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _stackIndex = 0;
        _address = 0;
        _imageAddress = 0;
        _imageName = nil;
        _symbolAddress = 0;
        _symbolName = nil;
    }
    
    return self;
}

- (BOOL)symbolicate:(bool)needSymbolName {
    if(_address == 0 || _imageAddress != 0) {
        return NO;
    }

    struct hmd_dl_info info = {0};
    bool rst;

    if (HMD_IS_DEBUG) {
        rst = hmd_symbolicate(CALL_INSTRUCTION_FROM_RETURN_ADDRESS(_address), &info, needSymbolName);
    } else {
        rst = hmd_symbolicate(CALL_INSTRUCTION_FROM_RETURN_ADDRESS(_address), &info, false);
    }
    
    if (rst) {
        _imageAddress = (uintptr_t)info.dli_fbase;
        _imageName = [[NSString stringWithUTF8String:info.dli_fname] lastPathComponent];
        if (HMD_IS_DEBUG) {
            _symbolAddress = (uintptr_t)info.dli_saddr;
            _symbolName = getDemangleName([NSString stringWithUTF8String: info.dli_sname]);
        }
    }
    
    return rst;
}

- (BOOL)isAppAddress {
    uintptr_t ptr = self.address;
    if (!ptr) {
        return NO;
    }
    hmd_setup_shared_image_list(); // 首次调用耗时
    hmd_async_image_list_set_reading(&shared_app_image_list, true);
    if (ptr > 0 && hmd_async_image_containing_address(&shared_app_image_list, ptr)) {
        return YES;
    }
    hmd_async_image_list_set_reading(&shared_app_image_list, false);

    return NO;
}

@end
