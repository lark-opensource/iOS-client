//
//  TTVideoEngine+Private.m
//  TTVideoEngine
//
//  Created by 黄清 on 2019/1/9.
//

#import <TTPlayerSDK/TTPlayerDef.h>
#import "TTVideoEngine+Private.h"
#import "TTVideoEnginePlaySource.h"
#import "TTVideoEnginePlayer.h"
#import "TTVideoEngine+Options.h"
#import "TTVideoEngine+Preload.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEnginePreloader+Private.h"
#import "NSDictionary+TTVideoEngine.h"
#import "TTVideoEngineUtilPrivate.h"

UInt64 const kTTVideoEngineHardwareDecodMask    =  1;
UInt64 const kTTVideoEngineRenderEngineMask     =  2;
UInt64 const kTTVideoEngineNetworkTimeOutMask   =  4;
UInt64 const kTTVideoEngineCacheMaxSecondsMask  =  8;
UInt64 const kTTVideoEngineBufferingTimeOutMask =  16;
UInt64 const kTTVideoEngineReuseSocketMask      =  32;
UInt64 const kTTVideoEngineCacheVideoModelMask  =  64;
UInt64 const kTTVideoEngineUploadAppLogMask     =  128;

NSDictionary *TTVideoEngineAppInfo_Dict = nil;
#ifndef __TTVIDEOENGINE_COPY__
#define __TTVIDEOENGINE_COPY__
#define ENGINE_COPY  [TTVideoEngineCopy defaultInstance]
#endif

#ifdef DEBUG
static NSMutableDictionary *s_debugMethods = nil;
#endif

/// Private
@interface TTVideoEngine (SwitchResolution)
@property (nonatomic, strong) id<TTVideoEnginePlaySource> playSource;
@property (nonatomic,   copy) NSString *currentHostnameURL;
@property (nonatomic,   copy) NSString *currentIPURL;
@property (nonatomic, strong) NSMutableDictionary *urlIPDict;
@property (nonatomic, assign) TTVideoEngineState state;
@property (nonatomic, assign) TTVideoEngineResolutionType currentResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType lastResolution;
@property (nonatomic, strong) TTVideoEngineDNSParser *dnsParser;
@property (nonatomic, assign) BOOL isFirstURL;
@property (nonatomic, assign) BOOL isRetrying;
@property (nonatomic, assign) TTVideoEnginePlayAPIVersion apiVersion;
@property (nonatomic, assign) NSTimeInterval lastPlaybackTime;
@end

@implementation TTVideoEngine (Private)

/// MARK: - TTVideoEngineLocalServerToEngineProtocol

- (void)updateCacheProgress:(NSString *)key flag:(NSInteger)flag observer:(nonnull id)observer progress:(CGFloat)progress {
    if ((observer && observer == self) && [self.localServerTaskKeys containsObject:key]) { // current task
        // only finished
        if (progress >= 0.99999) {
            //
            /// custom preload.
            [TTVideoEnginePreloader notifyPreload:self
                                             info:@{TTVideoEnginePreloadSuggestBytesSize:@(800*1024*1024),
                                                    TTVideoEnginePreloadSuggestCount:@(3)}];
            
            if (!self.internalDelegate) {
                return;
            }
            
            if (flag == 2) {// did finish before
                if ([self.internalDelegate respondsToSelector:@selector(noVideoDataToDownloadForKey:)]  ) {
                    [self.internalDelegate noVideoDataToDownloadForKey:key];
                }
            } else if (flag == 1) {// downloading
                if ([self.internalDelegate respondsToSelector:@selector(didFinishVideoDataDownloadForKey:)]) {
                    [self.internalDelegate didFinishVideoDataDownloadForKey:key];
                }
            }
        }
    }
}

// MARK: - Debug

+ (void)_putWithKey:(NSString *)key method:(NSString *)method {
#ifdef DEBUG
    TTVideoRunOnMainQueue(^{
        if (!s_debugMethods) {
            s_debugMethods = [NSMutableDictionary dictionary];
        }
        NSMutableArray *array = [s_debugMethods objectForKey:key];
        if (array == nil) {
            array = [NSMutableArray array];
        }
        [array addObject:method];
        
        [s_debugMethods setObject:array forKey:key];
    }, NO);
#endif
}

+ (void)_printAllMethod {
#ifdef DEBUG
    TTVideoRunOnMainQueue(^{
        NSDictionary *tem = s_debugMethods.copy;
        for (NSString *key in tem.allKeys) {
            NSMutableString * logString = [NSMutableString string];
            [logString appendString:@"\n\n"];
            NSArray *array = [tem objectForKey:key];
            for (NSString *method in array) {
                [logString appendFormat:@"%@, %@ \n",key,method];
            }
            [logString appendString:@"\n\n"];
            TTVideoEngineLog(@"%@",logString.copy);
        }
    }, NO);
#endif
}

@end

@interface TTVideoEngineCopy ()

@property (nonatomic, strong) id<TTVideoEnginePlaySource> playSource;
@property (nonatomic,   copy) NSString *currentHostnameURL;
@property (nonatomic,   copy) NSString *currentIPURL;
@property (nonatomic, strong) NSDictionary *urlIPDict;
@property (nonatomic, assign) TTVideoEngineState state;
@property (nonatomic, assign) TTVideoEngineResolutionType currentResolution;
@property (nonatomic, assign) TTVideoEngineResolutionType lastResolution;
@property (nonatomic, strong) TTVideoEngineDNSParser *dnsParser;
@property (nonatomic, assign) BOOL isFirstURL;
@property (nonatomic, assign) BOOL isRetrying;
@property (nonatomic, assign) TTVideoEnginePlayAPIVersion apiVersion;
@property (nonatomic, assign) NSTimeInterval lastPlaybackTime;
@end

@implementation TTVideoEngineCopy

+ (instancetype)defaultInstance {
    static TTVideoEngineCopy *s_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_instance = [[TTVideoEngineCopy alloc] init];
    });
    return s_instance;
}

+ (void)copyEngine:(TTVideoEngine *)engine {
    ENGINE_COPY.playSource = engine.playSource.deepCopy;
    ENGINE_COPY.currentHostnameURL = engine.currentHostnameURL;
    ENGINE_COPY.currentIPURL = engine.currentIPURL;
    ENGINE_COPY.urlIPDict = engine.urlIPDict.copy;
    ENGINE_COPY.state = engine.state;
    ENGINE_COPY.currentResolution = engine.currentResolution;
    ENGINE_COPY.lastResolution = engine.lastResolution;
    ENGINE_COPY.dnsParser = engine.dnsParser;
    ENGINE_COPY.isFirstURL = engine.isFirstURL;
    ENGINE_COPY.isRetrying = engine.isRetrying;
    ENGINE_COPY.apiVersion = engine.apiVersion;
    ENGINE_COPY.lastPlaybackTime = engine.lastPlaybackTime;
}

+ (void)assignEngine:(TTVideoEngine *)engine {
    engine.playSource = ENGINE_COPY.playSource;
    engine.currentHostnameURL = ENGINE_COPY.currentHostnameURL;
    engine.currentIPURL = ENGINE_COPY.currentIPURL;
    engine.urlIPDict = [NSMutableDictionary dictionaryWithDictionary:ENGINE_COPY.urlIPDict];
    engine.state = ENGINE_COPY.state;
    engine.currentResolution = ENGINE_COPY.currentResolution;
    engine.lastResolution = ENGINE_COPY.lastResolution;
    engine.dnsParser = ENGINE_COPY.dnsParser;
    engine.isFirstURL = ENGINE_COPY.isFirstURL;
    engine.isRetrying = ENGINE_COPY.isRetrying;
    engine.apiVersion = ENGINE_COPY.apiVersion;
    engine.lastPlaybackTime = ENGINE_COPY.lastPlaybackTime;
}

+ (void)reset {
    if (ENGINE_COPY.playSource) {
        ENGINE_COPY.playSource = nil;
        ENGINE_COPY.currentHostnameURL = nil;
        ENGINE_COPY.currentIPURL = nil;
        ENGINE_COPY.urlIPDict = nil;
        ENGINE_COPY.state = 0;
        ENGINE_COPY.currentResolution = 0;
        ENGINE_COPY.lastResolution = 0;
        ENGINE_COPY.dnsParser = nil;
        ENGINE_COPY.isFirstURL = NO;
        ENGINE_COPY.isRetrying = NO;
        ENGINE_COPY.apiVersion = TTVideoEnginePlayAPIVersion0;
        ENGINE_COPY.lastPlaybackTime = 0.0;
    }
}

@end
