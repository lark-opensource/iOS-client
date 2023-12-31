//
//  BDTuringConfig+HostVA.m
//  BDTuring
//
//  Created by bob on 2020/3/10.
//

#import "BDTuringConfig+HostVA.h"

#import "BDTuringSettings+Default.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringCoreConstant.h"

static NSString *const BDTuringVerifyCDNHost   = @"https://sf16-scmcdn-va.ibytedtos.com/obj/static-us/";
NSString *const BDTuringVAHostSetting          = @"https://vcs-va.byteoversea.com";
NSString *const BDTuringVAVerifyHostPicture    = @"https://verification-va.byteoversea.com";


@implementation BDTuringConfig (HostVA)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BDTuringSettings registerDefaultSettingBlock:^(BDTuringSettings * _Nonnull settings) {
            [settings addPlugin:kBDTuringSettingsPluginCommon
                                   key1:kBDTuringSettingsHost
                                 region:kBDTuringRegionVA
                                  value:BDTuringVAHostSetting];

            [settings addPlugin:kBDTuringSettingsPluginPicture
                                   key1:kBDTuringSettingsURL
                                 region:kBDTuringRegionVA
                                  value:[BDTuringVerifyCDNHost stringByAppendingString:@"secsdk-captcha/va/2.21.2/index.html"]];
            [settings addPlugin:kBDTuringSettingsPluginPicture
                                   key1:kBDTuringSettingsHost
                                 region:kBDTuringRegionVA
                                  value:BDTuringVAVerifyHostPicture];
        } forKey:kBDTuringRegionVA];
    });
}

@end
