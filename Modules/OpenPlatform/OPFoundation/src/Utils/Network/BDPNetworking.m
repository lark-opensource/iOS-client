//
//  BDPNetworking.m
//  Timor
//
//  Created by yinyuan on 2018/12/17.
//

#import "BDPNetworking.h"
#import "BDPUtils.h"

@implementation BDPNetworking

/// 小程序引擎相关网络请求共用的url session
+ (NSURLSession *)sharedSession {
    NSURLSession *session;
    BDPPlugin(networkPlugin, BDPNetworkPluginDelegate);
    if ([networkPlugin respondsToSelector:@selector(bdp_sharedSession)]) {
        session = [networkPlugin bdp_sharedSession];
    } else {
        session = [NSURLSession sharedSession];
    }
    return session;
}

+ (NSDictionary *)rustMetricsForTask:(NSURLSessionTask *)task {
    BDPPlugin(networkPlugin, BDPNetworkPluginDelegate);
    if ([networkPlugin respondsToSelector:@selector(bdp_rustMetricsForTask:)]) {
        return [networkPlugin bdp_rustMetricsForTask:task];
    } else {
        return [NSDictionary dictionary];
    }
}

+ (BOOL)isNetworkTransmitOverRustChannel {
    BDPPlugin(networkPlugin, BDPNetworkPluginDelegate);
    if ([networkPlugin respondsToSelector:@selector(bdp_isNetworkTransmitOverRustChannel)]) {
        return [networkPlugin bdp_isNetworkTransmitOverRustChannel];
    } else {
        return NO;
    }
}

#pragma mark - WebImage
+ (void)setImageView:(UIImageView *)imageView url:(NSURL *)url placeholder:(UIImage *)placeholder {
    BDPPlugin(networkPlugin, BDPNetworkPluginDelegate);
    if ([networkPlugin respondsToSelector:@selector(bdp_setImageView:url:placeholder:)]) {
        [networkPlugin bdp_setImageView:imageView url:url placeholder:placeholder];
    }
}

#pragma mark - Reachability
+ (BOOL)isNetworkConnected {
    BDPPlugin(networkPlugin, BDPNetworkPluginDelegate);
    if ([networkPlugin respondsToSelector:@selector(bdp_isNetworkConnected)]) {
        return [networkPlugin bdp_isNetworkConnected];
    }
    return NO;
}

+ (BDPNetworkType)networkType {
    BDPPlugin(networkPlugin, BDPNetworkPluginDelegate);
    if ([networkPlugin respondsToSelector:@selector(bdp_networkType)]) {
        return [networkPlugin bdp_networkType];
    }
    return 0;
}

+ (void)startReachabilityChangedNotifier {
    BDPPlugin(networkPlugin, BDPNetworkPluginDelegate);
    if ([networkPlugin respondsToSelector:@selector(bdp_startReachabilityChangedNotifier)]) {
        return [networkPlugin bdp_startReachabilityChangedNotifier];
    }
}

+ (void)stopReachabilityChangedNotifier {
    BDPPlugin(networkPlugin, BDPNetworkPluginDelegate);
    if ([networkPlugin respondsToSelector:@selector(bdp_stopReachabilityChangedNotifier)]) {
        return [networkPlugin bdp_stopReachabilityChangedNotifier];
    }
}

+ (NSNotificationName)reachabilityChangedNotification {
    BDPPlugin(networkPlugin, BDPNetworkPluginDelegate);
    if ([networkPlugin respondsToSelector:@selector(bdp_reachabilityChangedNotification)]) {
        return [networkPlugin bdp_reachabilityChangedNotification];
    }
    return nil;
}

#pragma mark - Request
+ (id<BDPNetworkTaskProtocol>)taskWithRequestUrl:(NSString *)URLString
                                      parameters:(id)parameters
                                     extraConfig:(BDPNetworkRequestExtraConfiguration*)extraConfig
                                      completion:(void (^)(NSError *error, id jsonObj, id<BDPNetworkResponseProtocol> response))completion
{
    BDPPlugin(networkPlugin, BDPNetworkPluginDelegate);
    if ([networkPlugin.customNetworkManager respondsToSelector:@selector(taskWithRequestUrl:parameters:extraConfig:completion:)]) {
        return [networkPlugin.customNetworkManager taskWithRequestUrl:URLString parameters:parameters extraConfig:extraConfig completion:completion];
    } else {
        NSAssert(NO, @"should not do this in app");
        BDPLogError(@"should not do this in app!!");
    }
    return nil;
}

+ (BOOL)HTTPShouldHandleCookies {
    BDPPlugin(networkPlugin, BDPNetworkPluginDelegate);
    if ([networkPlugin respondsToSelector:@selector(bdp_HTTPShouldHandleCookies)]) {
        return [networkPlugin bdp_HTTPShouldHandleCookies];
    }
    return NO;
}

@end
