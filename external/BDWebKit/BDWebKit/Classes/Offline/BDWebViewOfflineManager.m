//
//  BDWebViewOfflineManager.m
//  BDWebKit
//
//  Created by wealong on 2020/1/5.
//

#import "BDWebViewOfflineManager.h"
#import "BDWebKitSettingsManger.h"
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <BDPreloadCachedResponse+Falcon.h>
#import <BDWebKit/IESFalconManager.h>
#import <BDPreloadSDK/BDWebViewPreloadManager.h>
#import <BDWebKit/BDWebViewDebugKit.h>
#import <BDPreloadSDK/BDPreloadConfig.h>

@interface BDWebViewOfflineManager () <IESFalconCustomInterceptor>

@property (strong, nonatomic) NSMutableArray <Class>*customUrlProtocols;

@end

@implementation BDWebViewOfflineManager

+ (instancetype)sharedInstance {
    static BDWebViewOfflineManager *sharedManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[BDWebViewOfflineManager alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [IESFalconManager registerCustomInterceptor:self];
        [BDPreloadConfig sharedConfig].skipSSLCertificateList = [BDWebKitSettingsManger skipSSLCertificateList];
    }
    return self;
}

+ (BOOL)interceptionEnable {
    return [IESFalconManager interceptionEnable];
}

+ (void)setInterceptionEnable:(BOOL)interceptionEnable{
    BDALOG_PROTOCOL_INFO_TAG(@"BDWebView", @"offline enable: %@", interceptionEnable ? @"YES" : @"NO");
    if (interceptionEnable) {
        if (![IESFalconManager interceptionEnable]) {
            [self sharedInstance];
            BDALOG_PROTOCOL_INFO_TAG(@"BDWebView", @"Enable Falcon");
            BDWDebugLog(@"Enable Falcon");
            IESFalconManager.interceptionWKHttpScheme = YES;
            [IESFalconManager setInterceptionEnable:interceptionEnable];
        }
    } else {
        if ([IESFalconManager interceptionEnable]) {
            BDALOG_PROTOCOL_INFO_TAG(@"BDWebView", @"Disable Falcon");
            BDWDebugLog(@"Disable Falcon");
            IESFalconManager.interceptionWKHttpScheme = NO;
            [IESFalconManager setInterceptionEnable:interceptionEnable];
        }
    }
}

- (id<IESFalconMetaData>)falconMetaDataForURLRequest:(NSURLRequest *)request {
    BDPreloadCachedResponse *response = [[BDWebViewPreloadManager sharedInstance] responseForURLString:request.URL.absoluteString];
    if (request && response.data) {
        BDWDebugLog(@"%@ hit the preload caches",request.URL.absoluteString);
    }
    return response;
}

+ (void)registerCustomInterceptor:(id<IESFalconCustomInterceptor>)interceptor {
    if (![IESFalconManager interceptionEnable]) {
        BDALOG_PROTOCOL_INFO_TAG(@"BDWebView", @"Enable CustomInterceptor");
        IESFalconManager.interceptionWKHttpScheme = YES;
        [IESFalconManager setInterceptionEnable:YES];
        [IESFalconManager registerCustomInterceptor:interceptor];
    }
}


+ (void)unregisterCustomInterceptor:(id<IESFalconCustomInterceptor>)interceptor {
    if ([IESFalconManager interceptionEnable]) {
        BDALOG_PROTOCOL_INFO_TAG(@"BDWebView", @"Disable CustomInterceptor");
        [IESFalconManager setInterceptionEnable:NO];
        [IESFalconManager setInterceptionWKHttpScheme:NO];
        [IESFalconManager unregisterCustomInterceptor:interceptor];
    }
}

+ (void)registerCustomInterceptorList:(NSArray<IESFalconCustomInterceptor> *)interceptorList {
    if (![IESFalconManager interceptionEnable]) {
        BDALOG_PROTOCOL_INFO_TAG(@"BDWebView", @"Enable CustomInterceptor");
        IESFalconManager.interceptionWKHttpScheme = YES;
        [IESFalconManager setInterceptionEnable:YES];
        for (id<IESFalconCustomInterceptor>interceptor in interceptorList) {
            [IESFalconManager registerCustomInterceptor:interceptor];
        }
    }
}

+ (void)unregisterCustomInterceptorList:(NSArray<IESFalconCustomInterceptor> *)interceptorList {
    if ([IESFalconManager interceptionEnable]) {
        BDALOG_PROTOCOL_INFO_TAG(@"BDWebView", @"Disable CustomInterceptor");
        IESFalconManager.interceptionWKHttpScheme = NO;
        [IESFalconManager setInterceptionEnable:NO];
        for (id<IESFalconCustomInterceptor>interceptor in interceptorList) {
            [IESFalconManager unregisterCustomInterceptor:interceptor];
        }
    }
}


@end
