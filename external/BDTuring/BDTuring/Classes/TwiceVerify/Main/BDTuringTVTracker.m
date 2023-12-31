//
//  BDTuringTVTracker.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/11/2.
//

#import "BDTuringTVTracker.h"
#import <BDTrackerProtocol/BDTrackerProtocol.h>

@implementation BDTuringTVTracker

+ (void)trackerShowTwiceVerifyWithScene:(NSString *)scene type:(kBDTuringTVBlockType)type aid:(NSString *)aid {
    NSMutableDictionary *paramDic = [[NSMutableDictionary alloc] init];
    [paramDic setValue:scene forKey:@"scene"];
    [paramDic setValue:[self.class changeVerifyMethodByType:type] forKey:@"verify_method"];
    [paramDic setValue:aid forKey:@"aid"];
    [self.class trackerEvent:@"verify_account_sdk_notify" params:[paramDic copy]];
}

+ (void)trackerTwiceVerifySubmitWithScene:(NSString *)scene type:(kBDTuringTVBlockType)type aid:(NSString *)aid result:(BOOL)success {
    NSMutableDictionary *paramDic = [[NSMutableDictionary alloc] init];
    [paramDic setValue:scene forKey:@"scene"];
    [paramDic setValue:[self.class changeVerifyMethodByType:type] forKey:@"verify_method"];
    [paramDic setValue:aid forKey:@"aid"];
    [paramDic setValue:success?@"success":@"fail" forKey:@"result"];
    [self.class trackerEvent:@"verify_account_sdk_notify" params:[paramDic copy]];
}

+ (void)trackerEvent:(NSString *)event params:(NSDictionary *)params {
    [BDTrackerProtocol eventV3:event params:params];
}

//3065: 'SCAN'
+ (NSNumber *)changeVerifyMethodByType:(kBDTuringTVBlockType)type {
    switch (type) {
        case kBDTuringTVBlockTypeSms:
            return @(3060);
        case kBDTuringTVBlockTypeUpsms:
            return @(3061);
        case kBDTuringTVBlockTypePassword:
            return @(3062);
        default:
            return @(-1);
    }
    return nil;
}


@end
