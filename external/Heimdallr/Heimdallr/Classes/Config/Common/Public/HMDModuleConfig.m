//
//  HMDModuleConfig.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/13.
//

#import "HMDModuleConfig.h"
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"

@implementation HMDModuleConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(enableOpen, enable_open, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(enableUpload, enable_upload, @(NO), @(NO))
    };
}

+ (NSArray *)allRemoteModuleClasses
{
    static NSArray *classes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classes = [self loadClassesFromSectionName:"HMDModule"];
    });
    return classes;
}

+ (NSArray<HeimdallrLocalModule> *)allLocalModuleClasses;
{
    static NSArray <HeimdallrLocalModule> *classes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classes = (NSArray <HeimdallrLocalModule> *)[self loadClassesFromSectionName:"HMDLocalModule"];
    });
    return (NSArray<HeimdallrLocalModule> *)classes;
}

+ (NSArray *)loadClassesFromSectionName:(char *)sectionName
{
    NSMutableArray *array = [NSMutableArray array];
    unsigned long count = 0;
    char const ** modules = hmd_get_sectiondata_with_name(sectionName, &count);
    if (count > 0 && modules) {
        for (NSInteger index = 0; index < count; index++) {
#if __has_feature(address_sanitizer)
            // 无法直接转为struct __asan_global，否则会触发ASan的crash
            char const *name = (char const *)modules[index * (sizeof(struct __asan_global_var)/sizeof(uintptr_t))];
#else
            char const *name = (char const *)modules[index];
#endif
            Class clazz = NSClassFromString(@(name));
            if (clazz) {
                [array addObject:clazz];
            }
        }
    }
    
    return [array copy];
}

- (instancetype)initWithDictionary:(NSDictionary *)data
{
    self = [super init];
    if (self) {
        [self hmd_setAttributes:data];
    }
    return self;
}

+ (NSString *)configKey
{
    return nil;
}

- (id<HeimdallrModule>)getModule
{
    return nil;
}

- (BOOL)isValid {
    return YES;
}

- (BOOL)canStart
{
    return self.enableOpen;
}

- (BOOL)canStartTaskIndependentOfStart
{
    return NO;
}

- (void)updateWithAPISettings:(HMDGeneralAPISettings *)apiSettings
{
    
}

@end
