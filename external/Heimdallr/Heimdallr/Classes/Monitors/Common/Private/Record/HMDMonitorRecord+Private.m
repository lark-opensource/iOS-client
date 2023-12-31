//
//  HMDMonitorRecord+Private.m
//  Heimdallr
//
//  Created by bytedance on 2022/11/21.
//

#import "HMDMonitorRecord+Private.h"
#import "HMDInjectedInfo.h"

@implementation HMDMonitorRecord (Private)

+ (nullable NSDictionary *)getInjectedPatchFilters {
    NSMutableDictionary *patchDic = [NSMutableDictionary dictionary];
    NSDictionary *filters = [HMDInjectedInfo defaultInfo].filters;
    [filters enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
            // 热修相关筛选
            if([key isEqualToString:@"better_info"] || [key isEqualToString:@"better_ver"]) {
                [patchDic setValue:obj forKey:key];
            }
    }];
    return [patchDic copy];
}

@end
