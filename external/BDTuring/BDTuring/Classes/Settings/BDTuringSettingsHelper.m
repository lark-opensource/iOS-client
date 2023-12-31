//
//  BDTuringSettingsHelper.m
//  BDTuring
//
//  Created by bytedance on 2021/11/10.
//

#import "BDTuringSettingsHelper.h"
#import "BDTuringSettings.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringSettings+Custom.h"
#import "BDTuringCoreConstant.h"

@implementation BDTuringSettingsHelper

+ (instancetype)sharedInstance {
    static BDTuringSettingsHelper *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });

    return sharedInstance;
}

- (void) updateSettingCustomBlock:(NSString *)service
                     key1:(NSString *)key1
                      value:(NSString *)value
             forAppId:(NSString *)appID
          inRegion:(NSString *)region{
    
    NSString *key = [NSString stringWithFormat:@"%@%@%@%@",service, appID, region, NSStringFromSelector(_cmd)];
    if (value == nil) {
        [BDTuringSettings unregisterCustomSettingBlockForKey:key];
        return;
    }
    [BDTuringSettings registerCustomSettingBlock:^(BDTuringSettings *settings) {
        if ([settings.appID isEqualToString:appID]) {
            [settings addPlugin:service
                           key1:key1
                         region:region
                          value:value forceUpdate:YES];
        }
    } forKey:key];
    
}
- (instancetype)init {
    self = [super init];
    
    return self;
}


@end
