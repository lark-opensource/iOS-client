//
//  LKCustomExceptionConfig.m
//  LarkMonitor
//
//  Created by sniperj on 2019/12/31.
//

#import "LKCustomExceptionConfig.h"
#import "NSObject+LKAttributes.h"

@implementation LKCustomExceptionConfig

/// 获取注册的所有自定义异常case的class
+ (NSArray *)getAllRegistExceptionClass {
    static NSArray *allClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        allClasses = [self loadClassesFromSectionName:"LKCExcption"];
    });
    return allClasses;
}

/// 通过section段名获取注册的class
/// @param sectionName 对应的machO文件的section段名字
+ (NSArray *)loadClassesFromSectionName:(char *)sectionName
{
    NSMutableArray *array = [NSMutableArray array];
    unsigned long count = 0;
    char const ** modules = lk_get_sectiondata_with_name(sectionName, &count);
    if (count > 0) {
        for (NSInteger index = 0; index < count; index++) {
#if __has_feature(address_sanitizer)
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

+ (NSString *)configKey {
    return nil;
}

- (id<LKCExceptionProtocol>)getCustomException {
    return nil;
}

- (instancetype)initWithDictionary:(NSDictionary *)data {
    self = [super init];
    if (self) {
        [self lk_setAttributes:data];
    }
    return self;
}

@end
