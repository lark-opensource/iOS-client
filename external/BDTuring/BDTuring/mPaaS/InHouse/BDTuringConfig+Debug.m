//
//  BDTuringConfig+Debug.m
//  BDTuring
//
//  Created by bob on 2020/6/5.
//

#import "BDTuringConfig+Debug.h"
#import "BDTuringSettings.h"
#import "BDTuringSettingsKeys.h"
#import "BDTuringSettings+Custom.h"
#import "BDTuringCoreConstant.h"

@implementation BDTuringConfig (Debug)

- (void)setPictureURL:(NSString *)requestURL {
    NSString *appID = self.appID;
    NSCAssert(appID,@"please set appid first");
    NSString *key = [NSString stringWithFormat:@"%@%@", appID, NSStringFromSelector(_cmd)];
    if (requestURL == nil) {
        [BDTuringSettings unregisterCustomSettingBlockForKey:key];
        return;
    }
    [BDTuringSettings registerCustomSettingBlock:^(BDTuringSettings *settings) {
        if ([settings.appID isEqualToString:appID]) {
            [settings addPlugin:kBDTuringSettingsPluginPicture
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionVA
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginPicture
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionSG
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginPicture
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionCN
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginPicture
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionIN
                          value:requestURL forceUpdate:YES];
        }
    } forKey:key];
}

- (void)setSMSURL:(NSString *)requestURL {
    NSString *appID = self.appID;
    NSCAssert(appID,@"please set appid first");
    NSString *key = [NSString stringWithFormat:@"%@%@", appID, NSStringFromSelector(_cmd)];
    if (requestURL == nil) {
        [BDTuringSettings unregisterCustomSettingBlockForKey:key];
        return;
    }
    [BDTuringSettings registerCustomSettingBlock:^(BDTuringSettings *settings) {
        if ([settings.appID isEqualToString:appID]) {
            [settings addPlugin:kBDTuringSettingsPluginSMS
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionVA
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginSMS
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionSG
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginSMS
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionCN
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginSMS
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionIN
                          value:requestURL forceUpdate:YES];
        }
    } forKey:key];
}

- (void)setQAURL:(NSString *)requestURL {
    NSString *appID = self.appID;
    NSCAssert(appID,@"please set appid first");
    NSString *key = [NSString stringWithFormat:@"%@%@", appID, NSStringFromSelector(_cmd)];
    if (requestURL == nil) {
        [BDTuringSettings unregisterCustomSettingBlockForKey:key];
        return;
    }
    [BDTuringSettings registerCustomSettingBlock:^(BDTuringSettings *settings) {
        if ([settings.appID isEqualToString:appID]) {
            [settings addPlugin:kBDTuringSettingsPluginQA
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionVA
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginQA
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionSG
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginQA
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionCN
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginQA
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionIN
                          value:requestURL forceUpdate:YES];
        }
    } forKey:key];
}

- (void)setSealURL:(NSString *)requestURL {
    NSString *appID = self.appID;
    NSCAssert(appID,@"please set appid first");
    NSString *key = [NSString stringWithFormat:@"%@%@", appID, NSStringFromSelector(_cmd)];
    if (requestURL == nil) {
        [BDTuringSettings unregisterCustomSettingBlockForKey:key];
        return;
    }
    [BDTuringSettings registerCustomSettingBlock:^(BDTuringSettings *settings) {
        if ([settings.appID isEqualToString:appID]) {
            [settings addPlugin:kBDTuringSettingsPluginSeal
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionVA
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginSeal
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionSG
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginSeal
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionCN
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginSeal
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionIN
                          value:requestURL forceUpdate:YES];
        }
    } forKey:key];
}

- (void)setFullAutoVerifyURL:(NSString *)requestURL {
    NSString *appID = self.appID;
    NSCAssert(appID,@"please set appid first");
    NSString *key = [NSString stringWithFormat:@"%@%@", appID, NSStringFromSelector(_cmd)];
    if (requestURL == nil) {
        [BDTuringSettings unregisterCustomSettingBlockForKey:key];
        return;
    }
    [BDTuringSettings registerCustomSettingBlock:^(BDTuringSettings *settings) {
        if ([settings.appID isEqualToString:appID]) {
            [settings addPlugin:kBDTuringSettingsPluginFullAutoVerify
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionVA
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginFullAutoVerify
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionSG
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginFullAutoVerify
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionCN
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginFullAutoVerify
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionIN
                          value:requestURL forceUpdate:YES];
        }
    } forKey:key];
}

- (void)setAutoVerifyURL:(NSString *)requestURL {
    NSString *appID = self.appID;
    NSCAssert(appID,@"please set appid first");
    NSString *key = [NSString stringWithFormat:@"%@%@", appID, NSStringFromSelector(_cmd)];
    if (requestURL == nil) {
        [BDTuringSettings unregisterCustomSettingBlockForKey:key];
        return;
    }
    [BDTuringSettings registerCustomSettingBlock:^(BDTuringSettings *settings) {
        if ([settings.appID isEqualToString:appID]) {
            [settings addPlugin:kBDTuringSettingsPluginAutoVerify
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionVA
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginAutoVerify
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionSG
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginAutoVerify
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionCN
                          value:requestURL forceUpdate:YES];
            [settings addPlugin:kBDTuringSettingsPluginAutoVerify
                           key1:kBDTuringSettingsURL
                         region:kBDTuringRegionIN
                          value:requestURL forceUpdate:YES];
        }
    } forKey:key];
}


@end
