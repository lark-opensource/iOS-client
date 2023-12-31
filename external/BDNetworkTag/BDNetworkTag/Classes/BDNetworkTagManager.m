//
//  BDNetworkTagManager.m
//  AWEIMImpl-Pods-Aweme
//
//  Created by zoujianfeng on 2021/4/8.
//

#import "BDNetworkTagManager.h"

NSString * const BDNetworkTagIsFirstStartUp = @"network_tag_is_first_start_up";
NSString * const BDNetworkTagRequestKey = @"x-tt-request-tag";

@implementation BDNetworkTagManager

static BOOL disableTag;

+ (nonnull NSDictionary *)autoTriggerTagInfo {
    if (disableTag) {
        return @{};
    }
    return @{BDNetworkTagRequestKey : [NSString stringWithFormat:@"t=0;n=%d", [BDNetworkTagManager isNewUser]]};
}

+ (nonnull NSDictionary *)manualTriggerTagInfo {
    if (disableTag) {
        return @{};
    }
    return @{BDNetworkTagRequestKey : [NSString stringWithFormat:@"t=1;n=%d", [BDNetworkTagManager isNewUser]]};
}

+ (nullable NSDictionary *)tagForType:(BDNetworkTagType)type {
    switch (type) {
        case BDNetworkTagTypeAuto:
            return [BDNetworkTagManager autoTriggerTagInfo];
            break;
        case BDNetworkTagTypeManual:
            return [BDNetworkTagManager manualTriggerTagInfo];
            break;
        default:
            return nil;
            break;
    }
    
    return nil;
}

+ (nullable NSDictionary *)filterTagFromContext:(NSDictionary *)context {
    if (!context || ![context isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    [result setValue:context[BDNetworkTagRequestKey] forKey:BDNetworkTagRequestKey];
    
    return result.count > 0 ? [result copy] : nil;
}

+ (BOOL)isNewUser {
    static BOOL isFirstStarUp;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        isFirstStarUp = [[NSUserDefaults standardUserDefaults] boolForKey:BDNetworkTagIsFirstStartUp] == NO;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:BDNetworkTagIsFirstStartUp];
        });
    });
    return isFirstStarUp;
}

+ (void)disableTagCapacity:(BOOL)disable {
    disableTag = disable;
}

@end
