//
//  BDXWebContentPreloadManager.m
//  BDXWebKit-Pods-AwemeCore
//
//  Created by bytedance on 2022/5/5.
//

#import "BDWebContentPreloadManager.h"

#import <BytedanceKit/BTDMacros.h>
#import <BDPreloadSDK/BDPreloadManager.h>
#import <BDPreloadSDK/BDWebViewPreloadManager.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <BDALogProtocol/BDALogProtocol.h>

static NSString * const kPreloadManagerLogTag = @"WebContntPreloadManager";

@implementation BDWebContentPreloadManager

+ (void)preloadPageWithURLs:(NSArray *)urls userAgent:(NSString *)userAgent useHttpCaches:(BOOL)useHttpCaches
{
    [urls enumerateObjectsUsingBlock:^(NSString * _Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
        if (BTD_isEmptyString(url)) {
            return;
        }
        if ([self existPageCacheForURLString:url]) {
            return;
        }
        NSMutableDictionary *headerField = @{}.mutableCopy;
        if (!BTD_isEmptyString(userAgent)) {
            BDALOG_PROTOCOL_INFO_TAG(kPreloadManagerLogTag, @"userAgent is %@ with url %@", userAgent ,url);
            [headerField btd_setObject:userAgent forKey:@"User-Agent"];
        } else {
            BDALOG_PROTOCOL_INFO_TAG(kPreloadManagerLogTag, @"userAgent is empty with url %@", url);
        }
        NSTimeInterval cacheDuration = 60*60*2; //2h
        BDALOG_PROTOCOL_INFO_TAG(kPreloadManagerLogTag, @"start preload web content with url %@", url);
        [[BDWebViewPreloadManager sharedInstance] fetchDataForURLString:url
                                                            headerField:headerField
                                                          useHttpCaches:useHttpCaches
                                                          cacheDuration:cacheDuration
                                                          queuePriority:NSOperationQueuePriorityNormal
                                                             completion:^(NSError * _Nonnull error) {
            if (!error) {
                BDALOG_PROTOCOL_INFO_TAG(kPreloadManagerLogTag, @"preload web content successed with url %@", url);
            } else {
                BDALOG_PROTOCOL_INFO_TAG(kPreloadManagerLogTag, @"preload web content failed with url %@.\n Error: %@", url, error);
            }
        }];
    }];
}

+ (void)preloadPageWithURLs:(NSArray *)urls userAgent:(NSString *)userAgent
{
    [[self class] preloadPageWithURLs:urls userAgent:userAgent useHttpCaches:NO];
}

+ (BOOL)existPageCacheForURLString:(NSString *)urlString {
    return !!([[BDWebViewPreloadManager sharedInstance] responseForURLString:urlString]);
}


+ (BDPreloadCachedResponse *)fetchWebResourceSync:(NSString *)url
{
    return [[BDWebViewPreloadManager sharedInstance] responseForURLString:url];
}

+ (void)saveResponse:(BDPreloadCachedResponse *)response forURLString:(NSString *)urlString
{
    [[BDWebViewPreloadManager sharedInstance] saveResponse:response forURLString:urlString];
}

+ (void)cancelTasks:(NSArray *)urls {
    [urls enumerateObjectsUsingBlock:^(NSString *_Nonnull url, NSUInteger idx, BOOL * _Nonnull stop) {
        [[BDPreloadManager sharedInstance] cancelPreloadTaskWithKey:url];
    }];
}


@end
