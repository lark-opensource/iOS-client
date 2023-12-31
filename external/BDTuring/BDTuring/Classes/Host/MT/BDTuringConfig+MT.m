//
//  BDTuringConfig+MT.m
//  BDTuring
//
//  Created by bob on 2020/6/7.
//

#import "BDTuringConfig+MT.h"

#import "BDTuringSettings+Default.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringCoreConstant.h"

NSString *const BDTuringMTVAHostSetting          = @"https://vcs-va.tiktokv.com";
NSString *const BDTuringMTVAVerifyHostPicture    = @"https://verification-va.tiktokv.com";
NSString *const BDTuringMTSGHostSetting          = @"https://vcs-sg.tiktokv.com";
NSString *const BDTuringMTSGVerifyHostPicture    = @"https://verify-sg.tiktokv.com";

static NSString *const BDTuringMTSGApp = @"1180";
static NSString *const BDTuringMTVAApp = @"1233";

@implementation BDTuringConfig (MT)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BDTuringSettings registerAppDefaultSettingBlock:^(BDTuringSettings *settings) {
            if ([settings.appID isEqualToString:BDTuringMTSGApp]) {
                [settings addPlugin:kBDTuringSettingsPluginCommon
                               key1:kBDTuringSettingsHost
                             region:kBDTuringRegionSG
                              value:BDTuringMTSGHostSetting];
                [settings addPlugin:kBDTuringSettingsPluginPicture
                               key1:kBDTuringSettingsHost
                             region:kBDTuringRegionSG
                              value:BDTuringMTSGVerifyHostPicture];
            }
            
            if ([settings.appID isEqualToString:BDTuringMTVAApp]) {
                [settings addPlugin:kBDTuringSettingsPluginCommon
                               key1:kBDTuringSettingsHost
                             region:kBDTuringRegionVA
                              value:BDTuringMTVAHostSetting];
                [settings addPlugin:kBDTuringSettingsPluginPicture
                               key1:kBDTuringSettingsHost
                             region:kBDTuringRegionVA
                              value:BDTuringMTVAVerifyHostPicture];
            }
        } forKey:[BDTuringMTSGApp stringByAppendingString:BDTuringMTVAApp]];
    });
}

@end
