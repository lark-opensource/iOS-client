//
//  LKNativeAppExtensionFinder.m
//  LKNativeAppContainer
//
//  Created by bytedance on 2021/12/20.
//

@import LKNativeAppExtension;
#import "LKNativeAppExtensionFinder.h"
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <mach-o/ldsyms.h>

@interface LKNativeAppExtensionFinder()

@property (nonatomic, strong) NSMutableDictionary *configMap;

@end

@implementation LKNativeAppExtensionFinder

+ (LKNativeAppExtensionFinder *)shared {
    static LKNativeAppExtensionFinder *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
        instance.configMap = [NSMutableDictionary new];
    });
    return instance;
}

- (LKNativeAppExtensionConfig * _Nullable)getConfigByAppId:(NSString *)appId {
    return self.configMap[appId];
}

NSArray<NSString *>* KGReadConfiguration(char *sectionName,const struct mach_header *mhp);

static void dyld_callback(const struct mach_header *mhp, intptr_t vmaddr_slide)
{
    NSArray *apps = KGReadConfiguration(LKNativeAppSec, mhp);
    for (NSString *app in apps) {
        NSData *jsonData =  [app dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (!error) {
            if ([json isKindOfClass:[NSDictionary class]] && [json allKeys].count) {
                LKNativeAppExtensionConfig *config = [[LKNativeAppExtensionConfig alloc] initWithDictionary:json];
                if (config.appId && config.implName) {
                    [LKNativeAppExtensionFinder shared].configMap[config.appId] = config;
                }
            }
        }
    }
}

//注册main之前的析构函数,析构函数仅爱周注解才能生效
__attribute__((constructor))
void initProphet() {
    //动态链接库加载的时候的hook，可能会回调次数比较多，可能不建议
    _dyld_register_func_for_add_image(dyld_callback);
}

NSArray<NSString *>* KGReadConfiguration(char *sectionName,const struct mach_header *mhp)
{
    NSMutableArray *configs = [NSMutableArray array];
    unsigned long size = 0;
#ifndef __LP64__
    uintptr_t *memory = (uintptr_t*)getsectiondata(mhp, SEG_DATA, sectionName, &size);
#else
    const struct mach_header_64 *mhp64 = (const struct mach_header_64 *)mhp;
    uintptr_t *memory = (uintptr_t*)getsectiondata(mhp64, SEG_DATA, sectionName, &size);
#endif
    unsigned long counter = size/sizeof(void*);
    for(int idx = 0; idx < counter; ++idx){
        char *string = (char*)memory[idx];
        NSString *str = [NSString stringWithUTF8String:string];
        if(!str)continue;
        if(str) [configs addObject:str];
    }

    return configs;
}

@end

@interface LKNativeAppExtensionConfig()

@property (nonatomic, copy) NSString *implName;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, assign) BOOL preLaunch;

@end

@implementation LKNativeAppExtensionConfig

- (instancetype)initWithDictionary:(NSDictionary *)params {
    if (self = [super init]) {
        [self _setupWithParams:params];
    }
    return self;
}

- (void)_setupWithParams:(NSDictionary *)params {
    self.implName = params[@"name"];
    self.appId = params[@"appId"];
    self.preLaunch = [params[@"preLaunch"] isEqualToString: @"true"] ? YES : NO;
}

@end
