//
//  UIApplication+HMDUtility.m
//  Pods
//
//  Created by bytedance on 2020/5/26.
//

#import "UIApplication+HMDUtility.h"

@implementation UIApplication (HMDUtility)

+ (BOOL)isAppExtension {
    static BOOL sharedDecided = NO;
    static BOOL sharedIsAppExtension;
    
    // 当前全局是否已经判断完成
    BOOL currentDecided = __atomic_load_n(&sharedDecided, __ATOMIC_ACQUIRE);
    
    // 如果全局已经判断完成，返回全局判断结果
    if(currentDecided) return __atomic_load_n(&sharedIsAppExtension, __ATOMIC_ACQUIRE);
    
    // 当前查询结果: 是否是 APP Extension
    BOOL currentIsAppExtension = self.appExtensionPointIdentifier != nil;
    
    // 写入全局判断结果
    if(currentIsAppExtension)
         __atomic_store_n(&sharedIsAppExtension, YES, __ATOMIC_RELEASE);
    else __atomic_store_n(&sharedIsAppExtension, NO,  __ATOMIC_RELEASE);
    
    // 写入全局是否判断
    __atomic_store_n(&sharedDecided, YES, __ATOMIC_RELEASE);
    
    return currentIsAppExtension;
}

+ (NSString *)appExtensionPointIdentifier {
    id extensionDict = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"NSExtension"];
    if (!extensionDict) {
      return nil;
    }
    if (![extensionDict isKindOfClass:[NSDictionary class]]) {
      return nil;
    }
    id extensionType = [(NSDictionary*)extensionDict objectForKey:@"NSExtensionPointIdentifier"];
    if (![extensionType isKindOfClass:[NSString class]]) {
      return nil;
    }
    return extensionType;
}

+ (UIApplication *)hmdSharedApplication {
    if ([self isAppExtension]) {
        return nil;
    }
    return [[UIApplication class] performSelector:@selector(sharedApplication)];
}

@end
