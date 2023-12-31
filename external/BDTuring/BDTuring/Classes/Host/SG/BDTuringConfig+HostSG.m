//
//  BDTuringConfig+HostSG.m
//  BDTuring
//
//  Created by bob on 2020/3/10.
//

#import "BDTuringConfig+HostSG.h"

#import "BDTuringSettings+Default.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringCoreConstant.h"

static NSString *const BDTuringVerifyCDNHost   = @"https://sf16-scmcdn-sg.ibytedtos.com/obj/static-sg/";
NSString *const BDTuringSGHostSetting          = @"https://vcs-sg.byteoversea.com";
NSString *const BDTuringSGVerifyHostPicture    = @"https://verify-sg.byteoversea.com";


@implementation BDTuringConfig (HostSG)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BDTuringSettings registerDefaultSettingBlock:^(BDTuringSettings * _Nonnull settings) {
            [settings addPlugin:kBDTuringSettingsPluginCommon
                           key1:kBDTuringSettingsHost
                         region:kBDTuringRegionSG
                          value:BDTuringSGHostSetting];
            
            [settings addPlugin:kBDTuringSettingsPluginPicture
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionSG
                          value:[BDTuringVerifyCDNHost stringByAppendingString:@"secsdk-captcha/sg/2.21.2/index.html"]];
            [settings addPlugin:kBDTuringSettingsPluginPicture
                           key1:kBDTuringSettingsHost
                         region:kBDTuringRegionSG
                          value:BDTuringSGVerifyHostPicture];
        } forKey:kBDTuringRegionSG];
        
        
    });
}

@end
