//
//  EMAComponentsVersionManager.m
//  EEMicroAppSDK
//
//  Created by Limboy on 2020/9/4.
//

#import "EMAComponentsVersionManager.h"
#import "EMAAppEngine.h"
#import <OPFoundation/EMADebugUtil.h>

#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>

#import <OPFoundation/BDPUtils.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>
#import <OPFoundation/BDPVersionManager.h>
#import <OPFoundation/BDPTracker.h>
#import <TTMicroApp/BDPAppPageFactory.h>
#import <OPFoundation/BDPSettingsManager+BDPExtension.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/OPFoundation-Swift.h>

@implementation EMAComponentsVersionManager

// 加载大组件，如果有必要
- (void)updateComponentsIfNeeded {
    BDPLogInfo(@"[BIG_COMPONENTS] updateComponentsIfNeeded");
    NSDictionary *config = [EMAAppEngine.currentEngine.onlineConfig jssdkConfig];
    if (!config) {
        BDPLogWarn(@"[BIG_COMPONENTS] config data not available");
        return;
    }

    NSDictionary *components = [config bdp_dictionaryValueForKey:@"components"];

    if (components) {
        [self updateComponents:components forType:BDPTypeNativeApp];
    } else {
        BDPLogInfo(@"[BIG_COMPONENTS] no components in jssdk");
    }
}

- (void)updateComponents:(NSDictionary *)components forType:(BDPType )appType {
    // 这里一定要赋值哦，因为后面都要靠自己了，现在不把数据给它，之后 meta 让它去拉组件，可就不知道怎么拉了哦
    // TODO 考虑下是否要内置一份 JSSDK Config 在本地，如果第一次网络不好没拉到怎么办？
    [ComponentsManager.shared setComponentsConfig:components forAppType:appType];

    [components enumerateKeysAndObjectsUsingBlock:^(NSString *componentName, NSDictionary *component, BOOL * _Nonnull stop) {
        ComponentModel *localModel = [ComponentsManager.shared localModelOfComponent:componentName appType:appType];
        BOOL shouldInstall = NO;

        if (localModel) {
            if ([self versionCompareVersionA:localModel.version versionB:component[@"version"]] < 0) {
                BDPLogInfo(@"[BIG_COMPONENTS] local model is outdated");
                shouldInstall = YES;
            }
        } else {
            // Config 里有，本地没有，那就需要下载之
            BDPLogInfo(@"[BIG_COMPONENTS] local model not found");
            shouldInstall = YES;
        }

        BDPLogInfo(@"[BIG_COMPONENTS] should install components? %@", shouldInstall ? @"YES" : @"NO");

        if (shouldInstall) {
            [ComponentsManager.shared installWithComponentName:componentName componentVersion:BDPSafeString(component[@"version"]) appType:appType uniqueID:nil completion:^(NSURLResponse *response, NSError * _Nullable error) {
                if (error) {
                    BDPLogTagError(BDPTag.appLoad, @"[BIG_COMPONENTS] component(%@) install failed. error: %@", componentName, error)
                } else {
                    BDPLogTagInfo(BDPTag.appLoad, @"[BIG_COMPONENTS] component(%@) installed.", componentName)
                }
            }];
        }
    }];
}

#pragma mark Utils

/// 相等返回 0；A > B，返回 1；A < B 返回 -1
- (int)versionCompareVersionA:(NSString *)versionA versionB:(NSString *)versionB {
    return [BDPVersionManager compareVersion:versionA with:versionB];
}

@end
