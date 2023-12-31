//
//  HMDHTTPDetailRecord+Private.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/7/19.
//

#import "HMDHTTPDetailRecord+Private.h"
#import "NSDictionary+HMDSafe.h"

@implementation HMDHTTPDetailRecord (Private)

@dynamic isHitSDKURLAllowedListBefore;

- (void)addCustomExtraValueWithKey:(NSString *)key value:(id)value {
    if (!self.customExtraValue) {
        self.customExtraValue = [NSMutableDictionary dictionary];
    }
    [self.customExtraValue hmd_setObject:value forKey:key];
}

@end
