//
//  BDPBootstrapKit.m
//  Timor
//
//  Created by 傅翔 on 2019/6/12.
//

#import "BDPBootstrapKit.h"
#import "BDPBootstrapHeader.h"
#import "BDPMacroUtils.h"
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <mach-o/getsect.h>
#import <mach-o/loader.h>
#import <objc/runtime.h>
#import "EEFeatureGating.h"
#import <LKLoadable/Loadable.h>

#define BDP_LOAD_IDNEX 0
#define BDP_LAUNCH_IDNEX 1

@protocol BDPBootstrapProtocol <NSObject>
@optional
/** pre main阶段执行, 可充当+load方法 */
//该方法已不生效, 使用LKLoadable提供的方法;
+ (void)bootstrapLoad;

/** bootstrap启动时才执行(在main阶段之后的某个时机) */
+ (void)bootstrapLaunch;
@end

static NSMutableDictionary<NSString *, NSNumber *> *gLaunchNames = nil;

@implementation BDPBootstrapKit

static void handle_did_add_image(const struct mach_header *mhp, intptr_t vmaddr_slide) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary *launchNames = bootstap_names_in_section_data(BDP_LAUNCH_SECTION_NAME, mhp);
        if (launchNames.count) {
            if (!gLaunchNames) {
                gLaunchNames = [NSMutableDictionary dictionary];
            }
            [gLaunchNames addEntriesFromDictionary:launchNames];
        }
    });
}

#ifndef __LP64__
#define mach_header_u mach_header
#else
#define mach_header_u mach_header_64
#endif
const struct mach_header_u *machHeader = NULL;
static NSString *configuration = @"";
//_dyld_register_func_for_add_image 的时机可能会触发死锁问题
//https://bytedance.feishu.cn/docs/doccnswT4zCs3KF4O3x7xbZIlNh#
//切换调用时【BDPBootstrapKit】 的 +load 作为统一收口。同时不对原有的功能设计做较大改动】
LoadableMainFuncBegin(BDPBootstrapKitLoad)
//设置machheader信息
if (machHeader == NULL)
{
    Dl_info info;
    dladdr((__bridge const void *)configuration, &info);
    machHeader = (struct mach_header_u*)info.dli_fbase;
}
handle_did_add_image((const struct mach_header *)machHeader, 0);
LoadableMainFuncEnd(BDPBootstrapKitLoad)

///这个方法需要屏蔽内存检查，下面的 memory 内存块访问会产生异常，需要屏蔽
static NSDictionary<NSString *, NSNumber *> * bootstap_names_in_section_data(const char *secname, const struct mach_header *mhp) __attribute__((no_sanitize("address"))) {
    unsigned long size = 0;
#ifndef __LP64__
    uint32_t *memory = (uint32_t *)getsectiondata(mhp, BDP_BOOT_SEGMENT_NAME, secname, &size);
#else
    uint64_t *memory = (uint64_t *)getsectiondata((const struct mach_header_64 *)mhp, BDP_BOOT_SEGMENT_NAME, secname, &size);
#endif
    NSMutableDictionary<NSString *, NSNumber *> *names = nil;
    if (size) {
        names = [NSMutableDictionary dictionaryWithCapacity:size];
    }
    for(int i = 0; i < size / sizeof(void*); i++) {
        const char *str = (const char *)memory[i];
#if __has_feature(address_sanitizer)
        if (str == NULL) {
            continue;
        }
#endif
        NSString *clsName = [NSString stringWithUTF8String:str];
        if (clsName.length) {
            NSInteger index = 0;
            while (index < clsName.length && [clsName characterAtIndex:index] != '_') {
                index++;
            }
            clsName = index < clsName.length ? [clsName substringToIndex:index] : clsName;
            if (!names[clsName]) {
                names[clsName] = @(1);
            } else {
                names[clsName] = @([names[clsName] integerValue] + 1);
            }
        }
    }
    return [names copy];
}

static void bootstrap_execute(NSDictionary<NSString *, NSNumber *> *names, int idx) {
    if (!names.count) {
        return;
    }
    SEL selector = idx == BDP_LOAD_IDNEX ? @selector(bootstrapLoad) : @selector(bootstrapLaunch);
    for (NSString *name in names.allKeys) {
        id<BDPBootstrapProtocol> cls = (id<BDPBootstrapProtocol>)NSClassFromString(name);
        if (!cls) {
            continue;
        }
        Class metaCls = object_getClass(cls);
        uint listCount = 0, count = 0, impCount = names[name].unsignedIntValue;
        Method *methodList = class_copyMethodList(metaCls, &listCount);
        for (uint i = 0; i < listCount; i++) {
            SEL methodSEL = method_getName(methodList[i]);
            if (methodSEL == selector) {
                IMP imp = method_getImplementation(methodList[i]);
                ((void (*)(id, SEL))imp)(cls, methodSEL);
                if (++count == impCount) {
                    break;
                }
            }
        }
        if (methodList) {
            free(methodList);
        }
    }
}

+ (void)launch {
    NSDictionary *names = nil;
    @synchronized (self) {
        names = [gLaunchNames copy];
        gLaunchNames = nil;
    }
    if (!names.count) {
        return;
    }
    bootstrap_execute(names, BDP_LAUNCH_IDNEX);
}

@end
