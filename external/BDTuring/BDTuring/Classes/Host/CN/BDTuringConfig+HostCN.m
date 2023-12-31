//
//  BDTuringConfig+HostCN.m
//  BDTuring
//
//  Created by bob on 2020/3/10.
//

#import "BDTuringConfig+HostCN.h"

#import "BDTuringSettings+Default.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringCoreConstant.h"

static NSString *const BDTuringCDNHost           = @"https://unpkg.byted-static.com/byted/";
static NSString *const BDTuringVerifyCDNHost     = @"https://lf-cdn-tos.bytescm.com/obj/static/";

NSString *const BDTuringCNHostSetting          = @"https://vcs.snssdk.com";
NSString *const BDTuringCNVerifyHostPicture    = @"https://verify.snssdk.com";
NSString *const BDTuringCNVerifyHostSMS        = @"https://rc.snssdk.com";
NSString *const BDTuringCNVerifyHostQA         = BDTuringCNVerifyHostSMS;
NSString *const BDTuringCNVerifyHostSeal         = BDTuringCNVerifyHostSMS;
NSString *const BDTuringCNVerifyHostTwice        = @"https://i.snssdk.com/";

@implementation BDTuringConfig (HostCN)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BDTuringSettings registerDefaultSettingBlock:^(BDTuringSettings * _Nonnull settings) {
            [settings addPlugin:kBDTuringSettingsPluginCommon
                                   key1:kBDTuringSettingsHost
                                 region:kBDTuringRegionCN
                                  value:BDTuringCNHostSetting];

            [settings addPlugin:kBDTuringSettingsPluginPicture
                                   key1:kBDTuringSettingsURL
                                 region:kBDTuringRegionCN
                                  value:[BDTuringVerifyCDNHost stringByAppendingString:@"secsdk-captcha/cn2/2.21.2/index.html"]];
            [settings addPlugin:kBDTuringSettingsPluginPicture
                                   key1:kBDTuringSettingsHost
                                 region:kBDTuringRegionCN
                                  value:BDTuringCNVerifyHostPicture];
            
            [settings addPlugin:kBDTuringSettingsPluginQA
                                   key1:kBDTuringSettingsURL
                                 region:kBDTuringRegionCN
                                  value:[BDTuringCDNHost stringByAppendingString:@"secsdk-qa/1.2.5/build/index.html"]];
            [settings addPlugin:kBDTuringSettingsPluginQA
                                   key1:kBDTuringSettingsHost
                                 region:kBDTuringRegionCN
                                  value:BDTuringCNVerifyHostQA];
            
            [settings addPlugin:kBDTuringSettingsPluginSMS
                                   key1:kBDTuringSettingsURL
                                 region:kBDTuringRegionCN
                                  value:[BDTuringCDNHost stringByAppendingString:@"secsdk-mobile-original/1.9.9/build/index.html"]];
            [settings addPlugin:kBDTuringSettingsPluginSMS
                                   key1:kBDTuringSettingsHost
                                 region:kBDTuringRegionCN
                                  value:BDTuringCNVerifyHostSMS];
            
            [settings addPlugin:kBDTuringSettingsPluginSeal
                                   key1:kBDTuringSettingsURL
                                 region:kBDTuringRegionCN
                                  value:[BDTuringCDNHost stringByAppendingString:@"secsdk-unpunish/1.7.3/output/index.html"]];
            [settings addPlugin:kBDTuringSettingsPluginSeal
                           key1:kBDTuringSettingsHost
                         region:kBDTuringRegionCN
                          value:BDTuringCNVerifyHostSeal];
            
            [settings addPlugin:kBDTuringSettingsPluginAutoVerify
                           key1:kBDTuringSettingsHost
                         region:kBDTuringRegionCN
                          value:BDTuringCNVerifyHostSMS];
            
            [settings addPlugin:kBDTuringSettingsPluginFullAutoVerify
                           key1:kBDTuringSettingsHost
                         region:kBDTuringRegionCN
                          value:BDTuringCNVerifyHostSMS];
            
            [settings addPlugin:kBDTuringSettingsPluginAutoVerify
                                   key1:kBDTuringSettingsURL
                                 region:kBDTuringRegionCN
                                  value:[BDTuringCDNHost stringByAppendingString:@"secsdk-smart-captcha/0.0.8/output/app/smarter/index.html"]];
            [settings addPlugin:kBDTuringSettingsPluginFullAutoVerify
                                   key1:kBDTuringSettingsURL
                                 region:kBDTuringRegionCN
                                  value:[BDTuringCDNHost stringByAppendingString:@"secsdk-smart-captcha/0.0.8/output/app/smartest/index.html"]];
            
            [settings addPlugin:kBDTuringSettingsPluginTwiceVerify
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionCN
                          value:[BDTuringCNVerifyHostTwice stringByAppendingString:@"verifycenter/authentication/"]];
            
        } forKey:kBDTuringRegionCN];
    });
}

@end
