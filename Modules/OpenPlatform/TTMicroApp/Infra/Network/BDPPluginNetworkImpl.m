//
//  BDPPluginNetworkImpl.m
//  Timor
//
//  Created by yinyuan on 2018/12/18.
//

#import "BDPPluginNetworkImpl.h"
#import <OPFoundation/BDPBootstrapHeader.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/EEFeatureGating.h>
#import <BDWebImage/BDWebImage.h>
#import <TTReachability/TTReachability.h>
#import <objc/runtime.h>
#import <pthread.h>
#import <ECOInfra/ECOInfra-Swift.h>

@interface BDPPluginNetworkImpl ()

@property (nonatomic, strong) TTReachability *reachability;

@end


@implementation BDPPluginNetworkImpl
@dynamic customNetworkManager;

// BDPPluginNetworkImpl 和 BDPPluginNetworkCustomImpl 注册时序错乱会导致网络能力异常
#define kNetworkPluginBugfixFGDisabledKey @"openplatform.api.network_plugin_init_opt_disabled"

+ (BOOL)networkPluginBugfixFGDisabled {
    static BOOL disabled = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        disabled = [[NSUserDefaults standardUserDefaults] boolForKey:kNetworkPluginBugfixFGDisabledKey];
    });
    return disabled;
}

+ (void)refreshNetworkPluginBugfixFGOnce {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        BOOL disabled = [EMAFeatureGating boolValueForKey:kNetworkPluginBugfixFGDisabledKey];
        [[NSUserDefaults standardUserDefaults] setBool:disabled forKey:kNetworkPluginBugfixFGDisabledKey];
    });
}

@BDPBootstrapLaunch(BDPPluginNetworkImpl, {
    if ([self networkPluginBugfixFGDisabled]) {
        [BDPTimorClient sharedClient].networkPlugin = [BDPPluginNetworkImpl class];
    }
});

- (instancetype)init {
    self = [super init];
    _reachability = [TTReachability reachabilityWithHostName:@"toutiao.com"];
    return self;
}

+ (id<BDPBasePluginDelegate>)sharedPlugin {
    static BDPPluginNetworkImpl *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - Accessor
-(void)setCustomNetworkManager:(id<BDPNetworkRequestProtocol>) networkManager
{
    objc_setAssociatedObject(self, @"CustomNetworkManager", networkManager, OBJC_ASSOCIATION_RETAIN);
}

-(id<BDPNetworkRequestProtocol>)customNetworkManager
{
    return objc_getAssociatedObject(self, @"CustomNetworkManager");
}

#pragma mark - WebImage
- (void)bdp_setImageView:(UIImageView *)imageView url:(NSURL *)url placeholder:(UIImage *)placeholder {
    BDPAssertWithLog(@"Please over the method in the host layer!");
    [imageView bd_setImageWithURL:url placeholder:placeholder];
}

#pragma mark - Reachability
- (BOOL)bdp_inner_isWifiConnected {
    static NSString *channelName = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        channelName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CHANNEL_NAME"];
    });
    if ([channelName isEqualToString:@"local_test"] || [channelName isEqualToString:@"dev"]) {
        BOOL isDebugDisbaleWIFI = [[LSUserDefault standard] getBoolForKey:@"debug_disable_network"];
        if (isDebugDisbaleWIFI) {
            return NO;
        }
    }
    return [self.reachability currentReachabilityStatus] == ReachableViaWiFi;
}

- (BOOL)bdp_isNetworkConnected {
    if ([[LSUserDefault standard] getBoolForKey:@"kTMANetworkConnectOptimize"]) {
        return [TTReachability isNetworkConnected];
    } else {
        //return NO; // force for offline testing
        NetworkStatus netStatus = [self.reachability currentReachabilityStatus];
        if (netStatus != NotReachable) return YES;

        //double check，防止误伤
        TTReachability *retry = [TTReachability reachabilityWithHostName:@"www.apple.com"];
        netStatus = [retry currentReachabilityStatus];
        return (netStatus != NotReachable);
    }
}

- (BDPNetworkType)bdp_networkType {
    NSInteger type = 0;
    if ([TTReachability is2GConnected]) {
        type |= BDPNetworkType2G;
        type |= BDPNetworkTypeMobile;
    }
    if ([TTReachability is3GConnected]) {
        type |= BDPNetworkType3G;
        type |= BDPNetworkTypeMobile;
    }
    if ([TTReachability is4GConnected]) {
        type |= BDPNetworkType4G;
        type |= BDPNetworkTypeMobile;
    }
    if ([self bdp_inner_isWifiConnected]) {
        type |= BDPNetworkTypeWifi;
    }
    return type;
}

//TODO yinhao先注释
- (void)bdp_startReachabilityChangedNotifier {
    BDPExecuteOnMainQueue(^{
        // TTR每次startNotifier, 都会先stopNotifier, 没有意义, _startedNotifier又是private, 我们自己记录好了
        if (![objc_getAssociatedObject(self.reachability, _cmd) boolValue]) {
            [self.reachability startNotifier];
            objc_setAssociatedObject(self.reachability, _cmd, @(1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    });
}

- (void)bdp_stopReachabilityChangedNotifier {
    BDPExecuteOnMainQueue(^{
        [self.reachability stopNotifier];
        objc_setAssociatedObject(self, @selector(bdp_startReachabilityChangedNotifier), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    });
}

- (NSNotificationName)bdp_reachabilityChangedNotification {
    return TTReachabilityChangedNotification;
}

@end

