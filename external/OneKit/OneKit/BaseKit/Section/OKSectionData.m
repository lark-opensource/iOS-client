//
//  OKSectionData.m
//  OneKit
//
//  Created by bob on 2020/10/2.
//

#import "OKSectionData.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import <mach-o/ldsyms.h>

#ifdef __LP64__
typedef uint64_t OKExportValue;
typedef struct section_64 OKExportSection;
#define OKGetSectByNameFromHeader getsectbynamefromheader_64
#else
typedef uint32_t OKExportValue;
typedef struct section OKExportSection;
#define OKGetSectByNameFromHeader getsectbynamefromheader
#endif

@interface OKSectionData ()

@property (atomic, copy) NSDictionary<NSString *, NSMutableArray *> *keyValues;

+ (instancetype)sharedInstance;

@end

static void OKGetString() {
    if ([OKSectionData sharedInstance].keyValues) {
        return;
    }
    Dl_info info;
    dladdr((const void *)&OKGetString, &info);
    const OKExportValue mach_header = (OKExportValue)info.dli_fbase;
    const OKExportSection *section = OKGetSectByNameFromHeader((void *)mach_header, "__DATA", "__OKString");
    if (section == NULL) {
        [OKSectionData sharedInstance].keyValues = [NSDictionary new];
        return;
    }
    
    OKString *dataArray = (OKString *)(mach_header + section->offset);
    unsigned long counter = section->size/sizeof(OKString);
    
    NSMutableDictionary<NSString *, NSMutableArray *> *keyValues = [NSMutableDictionary dictionary];
    for (int idx = 0; idx < counter; ++idx) {
        OKString data = dataArray[idx];
        NSString *entryKey = [NSString stringWithUTF8String:data.key];
        NSString *entryValue = [NSString stringWithUTF8String:data.value];
        NSMutableArray<NSString *> *values = [keyValues objectForKey:entryKey];
        if (values == nil) {
            values = [NSMutableArray new];
            [keyValues setValue:values forKey:entryKey];
        }
        [values addObject:entryValue];
    }
    
    [OKSectionData sharedInstance].keyValues = keyValues;
}

@implementation OKSectionData

+ (instancetype)sharedInstance {
    static OKSectionData *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

+ (NSArray<NSString *> *)exportedStringsForKey:(NSString *)key {
    OKGetString();
    NSDictionary<NSString *, NSArray *> * keyValues = [OKSectionData sharedInstance].keyValues;
    
    return [keyValues objectForKey:key].copy;
}

@end
