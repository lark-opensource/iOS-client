#import "BDWADBlockUtil.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <IESGeckoKit/IESGeckoKit.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <IESGeckoKit/IESGeckoCacheManager.h>
#import "BDWebViewDebugKit.h"
#import "BDWWebViewGeckoUtil.h"
#import <BDWebKit/BDWebKitSettingsManger.h>

static NSString * const kTTWebViewADBlockChannel = @"adblock";
static NSString * const kTTWebViewADBlockRuleList = @"adblock_rulelist.json";
static NSString * const kTTWebViewADBlockCompiled = @"ContentRuleList-adblock_compiled";

@implementation BDWADBlockUtil

+ (void)trackADBlockStatus {
    // 广告trace埋点
    NSMutableDictionary *trackParams = @{}.mutableCopy;
    [trackParams setValue:[[BDWebKitSettingsManger settingsDelegate] bdAdblockEnable] ? @(1) : @(0) forKey:@"local_setting_enable"];
    
    // 广告过滤功能状态
    NSString *adBlockStatus;
    if (![[BDWebKitSettingsManger settingsDelegate] bdAdblockEnable]) {
        adBlockStatus = @"setting_disable";
    } else if (![self adBlockRuleList]) {
        adBlockStatus = @"rule_dismiss";
    } else {
        adBlockStatus = @"success";
    }
    [trackParams setValue:adBlockStatus forKey:@"ad_block_status"];
    
    // adBlock版本号
    long adBlockVersionCode = [IESGurdCacheManager packageVersionForAccessKey:[BDWWebViewGeckoUtil geckoAccessKey] channel:@"adblock"];
    
    [trackParams setValue:@(adBlockVersionCode) forKey:@"adblock_version_code"];
    
    [BDTrackerProtocol eventV3:@"adblock_init_module" params:trackParams];
}

// 域名列表
+ (NSArray *)adBlockDomainWhiteList {
    return [[BDWebKitSettingsManger settingsDelegate] bdAdblockDomainWhiteList];
}

+ (NSString *)adBlockRuleList {
    NSString *rule = [self adBlockResourceWithName:kTTWebViewADBlockRuleList];
    return rule;
}

+ (NSString *)adBlockResourceWithName:(NSString *)name {
    if (name.length == 0) {
        return nil;
    }
    
    NSString *result = nil;
    NSData *data = [BDWWebViewGeckoUtil geckoDataForPath:name channel:kTTWebViewADBlockChannel];
    if (data) {
        result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
    return result;
}

+ (nullable WKContentRuleListStore *)precompiledAdblockStore  API_AVAILABLE(ios(11.0)) {
    if ([self precompileEnable] && [BDWWebViewGeckoUtil hasCacheForPath:kTTWebViewADBlockCompiled channel:kTTWebViewADBlockChannel]) {
        NSString *path = [IESGurdKit rootDirForAccessKey:BDWWebViewGeckoUtil.geckoAccessKey channel:kTTWebViewADBlockChannel];
        NSURL *storeURL = [NSURL fileURLWithPath:path];
        
        if (storeURL) {
            return [WKContentRuleListStore storeWithURL:storeURL];
        }
    }
    return nil;
}

+ (BOOL)precompileEnable {
    return [[BDWebKitSettingsManger settingsDelegate] bdAdblockPrecompileEnable];
}

@end
