//
//  BDTuringConfig+HostIN.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/7/17.
//

#import "BDTuringConfig+HostIN.h"
#import "BDTuringSettings+Default.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringCoreConstant.h"

static NSString *const BDTuringVerifyCDNHost   = @"https://sf16-scmcdn-useast2a.ibytedtos.com/obj/static-aiso/";

NSString *const BDTuringINHostSetting          = @"https://vcs-va-useast2a.byteoversea.com";
NSString *const BDTuringINVerifyHostPicture    = @"https://verification-va-useast2a.byteoversea.com/";

@implementation BDTuringConfig (HostIN)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BDTuringSettings registerDefaultSettingBlock:^(BDTuringSettings * _Nonnull settings) {
            [settings addPlugin:kBDTuringSettingsPluginCommon
                                   key1:kBDTuringSettingsHost
                                 region:kBDTuringRegionIN
                                  value:BDTuringINHostSetting];

            [settings addPlugin:kBDTuringSettingsPluginPicture
                                   key1:kBDTuringSettingsURL
                                 region:kBDTuringRegionIN
                                  value:[BDTuringVerifyCDNHost stringByAppendingString:@"secsdk-captcha/in/2.21.2/index.html"]];
            [settings addPlugin:kBDTuringSettingsPluginPicture
                                   key1:kBDTuringSettingsHost
                                 region:kBDTuringRegionIN
                                  value:BDTuringINVerifyHostPicture];
        } forKey:kBDTuringRegionIN];
    });}


@end
