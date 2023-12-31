#import "WKUserContentController+BDWADBlock.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "BDWADBlockUtil.h"
#import "BDWWebViewGeckoUtil.h"
#import "BDWebViewDebugKit.h"
#import <BDWebKit/BDWebKitSettingsManger.h>
#import <WebKit/WKContentRuleListStore.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
static NSString * const kTTADBlockRuleListID = @"kTTADBlockRuleListID";
#ifndef BDABlockLog
#define BDABlockLog(...) BDALOG_PROTOCOL_TAG(kLogLevelInfo, @"BDABlockLog", __VA_ARGS__);
#endif

@implementation WKUserContentController (BDWADBlock)

API_AVAILABLE(ios(11.0))
static NSString *  wkIdentifier = nil;
static WKContentRuleList *wkContentRuleList = nil;
static CFTimeInterval startContentRuleTime;

+ (void)bdw_initADBlockRultList:(NSString *_Nonnull)geckoAccessKey {
    if (![[BDWebKitSettingsManger settingsDelegate] bdAdblockEnable] || ![[BDWebKitSettingsManger settingsDelegate] bdUserSettingADBlockEnable]) {
        BDABlockLog(@"初始化-功能关闭");
        return;
    }
    
    if (@available(iOS 11.0, *)) {
        if (wkContentRuleList) {
            return;
        }
        
        // update gecko access key
        [BDWWebViewGeckoUtil updateGeckoAccessKey:geckoAccessKey];
        
        // 记录首次尝试获取规则的时间
        startContentRuleTime = CACurrentMediaTime();
        
        // 先看看是否下发了预编译好的规则
        WKContentRuleListStore *store = [BDWADBlockUtil precompiledAdblockStore];
        
        if (store) {
            [store lookUpContentRuleListForIdentifier:@"adblock_compiled" completionHandler:^(WKContentRuleList *ruleList, NSError *error) {
                BDABlockLog(@"找到可用的预编译规则");
                wkContentRuleList = ruleList;
                [WKUserContentController trackAdblockReady];
            }];
            return;
        }
        
        // 若没有预编译好的规则，查看是否下发了规则文件，如果有则编译
        NSString *ruleList = [BDWADBlockUtil adBlockRuleList];
        if (ruleList.length == 0) {
            BDABlockLog(@"过滤规则为空");
            return;
        }
    
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSString *identifier = [@(ruleList.length) stringValue];
            wkIdentifier = identifier;
            [[WKContentRuleListStore defaultStore] lookUpContentRuleListForIdentifier:identifier
                                                                    completionHandler:^(WKContentRuleList *contentRuleList, NSError *error) {
                                                                        if (contentRuleList) {
                                                                            BDABlockLog(@"找到可用的规则,%@",identifier);
                                                                            wkContentRuleList = contentRuleList;
                                                                            [WKUserContentController trackAdblockReady];
                                                                        } else {
                                                                            BDABlockLog(@"更新过滤规则");
                                                                            [WKUserContentController updateContentRuleList:ruleList andIdentifier:identifier];
                                                                        }
                                                                    }];
        });
    }
}

+ (void)trackAdblockReady {
    NSInteger adblockReadyTime = (NSInteger)((CACurrentMediaTime() - startContentRuleTime) * 1000);
    [BDTrackerProtocol eventV3:@"adblock_ready" params:@{ @"adblock_time": @(adblockReadyTime)}];
}

+ (void)updateContentRuleList:(NSString *)ruleList andIdentifier:(NSString *)ruleListId {
    if (@available(iOS 11.0, *)) {
        [WKContentRuleListStore.defaultStore getAvailableContentRuleListIdentifiers:^(NSArray<NSString *> *identifiers) {
            // remove content rule
            BDABlockLog(@"清理旧的过滤规则");
            for (NSString *identifier in identifiers) {
                [WKContentRuleListStore.defaultStore removeContentRuleListForIdentifier:identifier
                                                                      completionHandler:^(NSError *error) {
                    if (error) {
                        BDABlockLog(@"清理%@规则, error:%@",identifier, error);
                    }
                }];
            }
        }];
    } else {
        // Fallback on earlier versions
    }

    BDWDebugLog(@"过滤规则编译");
    if (@available(iOS 11.0, *)) {
        [WKContentRuleListStore.defaultStore compileContentRuleListForIdentifier:ruleListId encodedContentRuleList:ruleList completionHandler:^(WKContentRuleList *ruleList, NSError *error) {
            if (error || !ruleList) {
                BDABlockLog(@"过滤规则编译失败：%@", error.description);
                return;
            }
            
            wkContentRuleList = ruleList;
            BDABlockLog(@"过滤规则编译成功,id%@",ruleListId);
            [WKUserContentController trackAdblockReady];
        }];
    } else {
        // Fallback on earlier versions
    }
}

- (BOOL)bdw_registerADBlockRultList:(BOOL)useTestRuleList {
    if (![[BDWebKitSettingsManger settingsDelegate] bdAdblockEnable] || ![[BDWebKitSettingsManger settingsDelegate] bdUserSettingADBlockEnable]) {
        BDABlockLog(@"注册rule-功能关闭");
        return NO;
    }
    
    if (useTestRuleList) {
        if (@available(iOS 11.0, *)) {
            [WKContentRuleListStore.defaultStore lookUpContentRuleListForIdentifier:@"Test"
                                                                  completionHandler:^(WKContentRuleList *ruleList, NSError *error) {
                if (ruleList) {
                    BDABlockLog(@"添加test过滤规则");
                    [self addContentRuleList:ruleList];
                }
            }];
        } else {
            // Fallback on earlier versions
        }
    }
    
    if (@available(iOS 11.0, *)) {
        if (!wkContentRuleList) {
            if(wkIdentifier != nil){
                __weak typeof(self) weakSelf = self;
                [WKContentRuleListStore.defaultStore lookUpContentRuleListForIdentifier:wkIdentifier
                                                                      completionHandler:^(WKContentRuleList *ruleList, NSError *error) {
                    if (ruleList) {
                        [weakSelf addContentRuleList:ruleList];
                    }
                }];
                BDABlockLog(@"过滤规则生效，但是还未初始化");
                return YES;
            }
            BDABlockLog(@"过滤规则无效");
            return NO;
        }

        BDABlockLog(@"添加过滤规则");
        [self addContentRuleList:wkContentRuleList];
        return YES;
    }
    return NO;
}

- (BOOL)bdw_unregisterADBlockRultList {
    if (@available(iOS 11.0, *)) {
        BDABlockLog(@"移除过滤规则");
        [self removeAllContentRuleLists];
        return YES;
    }
    return NO;
}

@end
