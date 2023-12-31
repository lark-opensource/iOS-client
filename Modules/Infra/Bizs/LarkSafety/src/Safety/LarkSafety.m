//
//  LarkSafety.m
//  LarkApp
//
//  Created by KT on 2019/7/18.
//

#import "UIKit/UIKit.h"
#import "LarkSafety.h"
#import "LarkSafetyUtils.h"

@implementation LarkSafety

+ (instancetype)shared {
    static LarkSafety *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[LarkSafety alloc] init];
    });
    return _sharedInstance;
}

@end

#pragma mark - 反调试
__attribute__((always_inline)) void AntiDebug() {
#ifdef DEBUG
#else
#ifdef __arm64__
    __asm__("mov X0, #31 \t\n"
            "mov X1, #0 \t\n"
            "mov X2, #0 \t\n"
            "mov X3, #0 \t\n"
            "mov w16, #26 \t\n" // ip1 指针
            "svc #0x80 \t\n"
            );
#elif __arm__
    __asm__(
            "mov r0, #31 \t\n"
            "mov r1, #0 \t\n"
            "mov r2, #0 \t\n"
            "mov r3, #0 \t\n"
            "mov ip, #26 \t\n"
            "svc #0x80 \t\n"
            );
#endif
#endif
    return;
}

#pragma mark - 反注入
__attribute__((always_inline)) void AntiDylibInject (const struct mach_header *mh, intptr_t vmaddr_slide) {
    //将反注入相关代码放入子线程执行，避免出现runtime lock死锁问题
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Dl_info info;
        if (dladdr(mh, &info) == 0) {
            return;
        }

        // 反注入黑名单
        NSArray *list = @[@"libcycript.dylib"];

        for (int i = 0; i < list.count; i ++) {
            if (strstr(info.dli_fname, [list[i] UTF8String])) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    Lark_ExitApp();
                });
            }
        }
    });
}
