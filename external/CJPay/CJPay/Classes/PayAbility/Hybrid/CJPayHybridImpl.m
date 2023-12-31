//
//  CJPayHybridImpl.m
//  CJPaySandBox
//
//  Created by 高航 on 2023/3/6.
//

#import "CJPayHybridImpl.h"
#import "CJPayHybridPlugin.h"
#import "CJPaySDKMacro.h"
#import "CJPayHybridBaseConfig.h"
#import "CJPayHybridView.h"
#import <HybridKit/HybridKit.h>
#import <HybridKit/HybridKitViewProtocol.h>
#import "CJPayBizWebViewController.h"
#import "UIViewController+CJTransition.h"

@interface CJPayHybridImpl()<CJPayHybridPlugin>

@end

@implementation CJPayHybridImpl

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayHybridPlugin)
})

+ (instancetype)defaultService {
    static CJPayHybridImpl *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CJPayHybridImpl new];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [[HybridKit sharedInstance] setupWebKit];
    }
    return self;
}

- (UIView *)createHybridViewWithScheme:(NSString *)scheme delegate:(id)delegate initialData:(NSDictionary *)params {
    CJPayHybridBaseConfig *config = [self p_buildConfigWithScheme:scheme params:params delegate:delegate];
    CJPayHybridView *hybridView = [[CJPayHybridView alloc] initWithConfig:config];
    return hybridView;
}


- (BOOL)isContainerView:(UIView *)view {
    return view && [view isKindOfClass:CJPayHybridView.class];
}

-(WKWebView *)getRawWebview:(UIView *)view {
    if ([self isContainerView:view]) {
        CJPayHybridView *hybridView = (CJPayHybridView *)view;
        if (hybridView.kitView.rawView && [hybridView.kitView.rawView isKindOfClass:WKWebView.class]) {
            return (WKWebView *)hybridView.kitView.rawView;
        }
    }
    return nil;
}

- (NSString *)getContainerID:(UIView *)container {
    if (![self isContainerView:container]) {
        return @"";
    }
    CJPayHybridView *view = (CJPayHybridView *)container;
    return CJString(view.kitView.containerID);
}

- (void)sendEvent:(nonnull NSString *)event params:(nullable NSDictionary *)data container:(nonnull UIView *)container {
    if ([self isContainerView:container]) {
        CJPayHybridView *hybridView = (CJPayHybridView *)container;
        [hybridView sendEvent:event params:data];
    }
}

- (BOOL)pluginHasInstalled {
    return YES;
}

#pragma mark - Private Method

- (CJPayHybridBaseConfig *)p_buildConfigWithScheme:(NSString *)scheme params:(nonnull NSDictionary *)params delegate:(nullable id)delegate{
    NSDictionary *schemeParams = [scheme cj_urlQueryParams];
    
    NSError *error = nil;
    CJPayHybridBaseConfig *config = [[CJPayHybridBaseConfig alloc] initWithDictionary:schemeParams error:&error];
    config.scheme = scheme;
    config.initialParams = params;
    config.WKDelegate = delegate;
    return config;
}

@end
