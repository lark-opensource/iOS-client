//
//  HMDCrashDynamicDataProvider.m
//  Pods
//
//  Created by yuanzhangjing on 2019/12/8.
//

#include <stdatomic.h>
#import <TTReachability/TTReachability.h>

#import "HMDMacro.h"
#import "HMDCrashKit.h"
#import "HMDCrashKit+Internal.h"

#import "HMDCrashDynamicDataProvider.h"
#import "HMDNetworkHelper.h"
#import "HMDDynamicCall.h"
#import "NSDictionary+HMDJSON.h"
#import "HMDInjectedInfo.h"
#if !SIMPLIFYEXTENSION
#import "HMDTracker.h"
#import "HMDSessionTracker.h"
#endif
#import "HMDCrashHeader.h"
#import "UIApplication+HMDUtility.h"

@implementation HMDCrashDynamicDataProvider
{
    BOOL _needRefreshContext;
    BOOL _needRefreshFilters;
}
- (instancetype)init {
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

- (void)dealloc {
    [self removeObserver];
}

- (void)setup {
    /* access */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkAccessChanged:)
                                                 name:TTReachabilityChangedNotification
                                               object:nil];
    [HMDSharedCrashKit setDynamicValue:[HMDNetworkHelper connectTypeName] key:@"access"];
    
    hmd_perform_on_mainthread(^{
        BOOL isBackground = ([UIApplication hmdSharedApplication].applicationState == UIApplicationStateBackground);
        [HMDSharedCrashKit setDynamicValue:@(isBackground).stringValue key:@"is_background"];
    });
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationStateChanged:)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationStateChanged:)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationStateChanged:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    /* is_exit */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    typeof(self) __weak weakSelf = self;
    atexit_b(^{
        typeof(self) __strong strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf applicationWillTerminate];
        }
    });
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sceneDidUpdate)
                                                 name:@"kHMDUITrackerSceneDidChangeNotification"
                                               object:nil];

    /* last_scene */
    __kindof NSObject *manager = DC_CL(HMDUITrackerManager, sharedManager);
    if(manager != nil) {
        SEL scene_selector = sel_registerName("scene");
        if([manager respondsToSelector:scene_selector])
            [manager addObserver:self
                      forKeyPath:@"scene"
                         options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                         context:NULL];
    }

    /* net quality*/
    NSInteger netQuality = [HMDNetworkHelper currentNetQuality];
    [HMDSharedCrashKit setDynamicValue:[NSString stringWithFormat:@"%ld",netQuality] key:@"network_quality"];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkQualityDidChanged:)
                                                 name:@"kHMDCurrentNetworkQualityDidChange"
                                               object:nil];
    
    HMDInjectedInfo * injectedInfo = HMDInjectedInfo.defaultInfo;
    if(injectedInfo != nil) {
        SEL userID_selector = @selector(userID);
        if([injectedInfo respondsToSelector:userID_selector])
            [injectedInfo addObserver:self
                           forKeyPath:NSStringFromSelector(userID_selector)
                              options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                              context:NULL];
        
        SEL scopedUserID_selector = @selector(scopedUserID);
        if([injectedInfo respondsToSelector:scopedUserID_selector])
            [injectedInfo addObserver:self
                           forKeyPath:NSStringFromSelector(scopedUserID_selector)
                              options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                              context:NULL];
        
        SEL userName_selector = @selector(userName);
        if([injectedInfo respondsToSelector:userName_selector])
            [injectedInfo addObserver:self
                           forKeyPath:NSStringFromSelector(userName_selector)
                              options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                              context:NULL];
        
        SEL email_selector = @selector(email);
        if([injectedInfo respondsToSelector:email_selector])
            [injectedInfo addObserver:self
                           forKeyPath:NSStringFromSelector(email_selector)
                              options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                              context:NULL];
        
        SEL business_selector = @selector(business);
        if([injectedInfo respondsToSelector:business_selector])
            [injectedInfo addObserver:self
                           forKeyPath:NSStringFromSelector(business_selector)
                              options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                              context:NULL];
        
        SEL customContext_selector = @selector(customContext);
        if([injectedInfo respondsToSelector:customContext_selector])
            [injectedInfo addObserver:self
                           forKeyPath:NSStringFromSelector(customContext_selector)
                              options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                              context:NULL];
        
        SEL filters_selector = @selector(filters);
        if([injectedInfo respondsToSelector:filters_selector])
            [injectedInfo addObserver:self
                           forKeyPath:NSStringFromSelector(filters_selector)
                              options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew
                              context:NULL];
    }
    
#if !SIMPLIFYEXTENSION
    
    /* internal_session_id */
    [HMDSharedCrashKit setDynamicValue:HMDSessionTracker.sharedInstance.eternalSessionID
                                   key:@"internal_session_id"];
#endif
}

#pragma mark - op

- (void)sceneDidUpdate {
#if !SIMPLIFYEXTENSION
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *dict = [HMDTracker getOperationTraceIfAvailable];
        NSString *json = [dict hmd_jsonString];
        [HMDSharedCrashKit setDynamicValue:json key:@"operation_trace"];
    });
#endif
}

#pragma mark  access

- (void)networkAccessChanged:(NSNotification *)notification {
    [HMDSharedCrashKit setDynamicValue:[HMDNetworkHelper connectTypeName] key:@"access"];
}

- (void)networkQualityDidChanged:(NSNotification *)notification {
    NSInteger netQuality = -1;
    id netQualityNum = [notification.object valueForKey:@"network_quality"];
    if ([netQualityNum isKindOfClass:[NSNumber class]]) {
        netQuality = [netQualityNum integerValue];
    } else if ([netQualityNum isKindOfClass:[NSString class]]) {
        netQuality = [netQualityNum integerValue];
    }
    [HMDSharedCrashKit setDynamicValue:[NSString stringWithFormat:@"%ld",netQuality] key:@"network_quality"];
}

#pragma mark background state

- (void)applicationStateChanged:(NSNotification *)notification {
    if ([notification.name isEqualToString:UIApplicationWillEnterForegroundNotification] ||
        [notification.name isEqualToString:UIApplicationDidBecomeActiveNotification]) {
        [HMDSharedCrashKit setDynamicValue:@"0" key:@"is_background"];
    } else {
        [HMDSharedCrashKit setDynamicValue:@"1" key:@"is_background"];
    }
}

#pragma mark exit state

- (void)applicationWillTerminate {
    [HMDSharedCrashKit syncDynamicValue:@"1" key:@"is_exit"];
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    id value = [change valueForKey:NSKeyValueChangeNewKey];
    if(value != nil) {
        BOOL isNull = value == [NSNull null];
        BOOL isString = [value isKindOfClass:NSString.class];
        if([keyPath isEqualToString:@"customContext"]) {
            [self requestRefreshCustomContext];
        } else if([keyPath isEqualToString:@"filters"]) {
            [self requestRefreshFilters];
        } else {
            NSString *key = keyPath;
            if ([key isEqualToString:@"scene"]) {
                key = @"last_scene";
            }
            if (isNull) {
                [HMDSharedCrashKit removeDynamicValue:key];
            } else if (isString) {
                [HMDSharedCrashKit setDynamicValue:value key:key];
            }
        }
    }
}

#pragma mark refresh request

- (void)requestRefreshCustomContext {
    hmd_perform_on_mainthread(^{
        if (self->_needRefreshContext) {
            return;
        }
        self->_needRefreshContext = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshCustomContext];
            self->_needRefreshContext = NO;
        });
    });
}

- (void)requestRefreshFilters {
    hmd_perform_on_mainthread(^{
        if (self->_needRefreshFilters) {
            return;
        }
        self->_needRefreshFilters = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshFilters];
            self->_needRefreshFilters = NO;
        });
    });
}

- (void)refreshCustomContext {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSDictionary *dictionary = DC_IS(DC_OB(DC_CL(HMDInjectedInfo, defaultInfo), customContext), NSDictionary);
        NSString *str = [dictionary hmd_jsonString];
        if(str.length > 0) {
            [HMDSharedCrashKit setDynamicValue:str key:@"custom"];
        }
    });
}

- (void)refreshFilters {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSDictionary *dictionary = DC_IS(DC_OB(DC_CL(HMDInjectedInfo, defaultInfo), filters), NSDictionary);
        NSString *str = [dictionary hmd_jsonString];
        if (str.length > 0) {
            [HMDSharedCrashKit setDynamicValue:str key:@"filters"];
        }
    });
}

#pragma mark removeObserver

-(void)removeObserver {
        
    __kindof NSObject *manager = DC_CL(HMDUITrackerManager, sharedManager);
    if(manager != nil) {
        SEL scene_selector = sel_registerName("scene");
        if([manager respondsToSelector:scene_selector])
            [manager removeObserver:self forKeyPath:@"scene"];
    }
    
    HMDInjectedInfo * injectedInfo = HMDInjectedInfo.defaultInfo;
    if(injectedInfo != nil) {
        SEL userID_selector = @selector(userID);
        if([injectedInfo respondsToSelector:userID_selector])
            [injectedInfo removeObserver:self forKeyPath:NSStringFromSelector(userID_selector)];
        
        SEL scopedUserID_selector = @selector(scopedUserID);
        if([injectedInfo respondsToSelector:scopedUserID_selector])
            [injectedInfo removeObserver:self forKeyPath:NSStringFromSelector(scopedUserID_selector)];
        
        SEL userName_selector = @selector(userName);
        if([injectedInfo respondsToSelector:userName_selector])
            [injectedInfo removeObserver:self forKeyPath:NSStringFromSelector(userName_selector)];
        
        SEL email_selector = @selector(email);
        if([injectedInfo respondsToSelector:email_selector])
            [injectedInfo removeObserver:self forKeyPath:NSStringFromSelector(email_selector)];
        
        SEL business_selector = @selector(business);
        if([injectedInfo respondsToSelector:business_selector])
            [injectedInfo removeObserver:self forKeyPath:NSStringFromSelector(business_selector)];
        
        SEL customContext_selector = @selector(customContext);
        if([injectedInfo respondsToSelector:customContext_selector])
            [injectedInfo removeObserver:self forKeyPath:NSStringFromSelector(customContext_selector)];
        
        SEL filters_selector = @selector(filters);
        if([injectedInfo respondsToSelector:filters_selector])
            [injectedInfo removeObserver:self forKeyPath:NSStringFromSelector(filters_selector)];
    }
}


@end
