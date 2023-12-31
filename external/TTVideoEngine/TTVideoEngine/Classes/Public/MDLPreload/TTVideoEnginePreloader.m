//
//  TTVideoEnginePreloader.m
//  TTVideoEngine
//
//  Created by 黄清 on 2020/4/20.
//

#import "TTVideoEnginePreloader.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEnginePreloader+Private.h"

NSString * const TTVideoEnginePreloadSuggestBytesSize = @"preload_size";
NSString * const TTVideoEnginePreloadSuggestCount = @"task_count";

NSString * const TTVideoEnginePreloadCancelReason = @"cancel_reason";
NSString * const TTVideoEnginePreloadNewPlayCancel = @"new_play";
NSString * const TTVideoEnginePreloadLowBufferCancel = @"low_buffer";
NSString * const TTVideoEnginePreloadStalledCancel = @"stalled";


NSString * const TTVideoEnginePreloadCancelConfigBuffer = @"cancel_config_buffer";
NSString * const TTVideoEnginePreloadCancelCurrentBuffer = @"cancel_current_buffer";

@interface TTVideoEnginePreloader ()

@end

@implementation TTVideoEnginePreloader

+ (void)engine:(TTVideoEngine *)engine playInfo:(NSDictionary<NSString *,id> *)info {
    
}

+ (void)engine:(TTVideoEngine *)engine prelaod:(NSDictionary<NSString *,id> *)suggestSetting {
    
}

+ (void)engine:(nullable TTVideoEngine *)engine cancelAllPrelaod:(NSDictionary<NSString *,id> *)info {
    
}

+ (BOOL)shouldPreload:(nullable TTVideoEngine *)engine {
    return YES;
}

+ (BOOL)registerClass:(Class)preloaderClass {
    if (preloaderClass == nil) {
        TTVideoEngineLog(@"class param is null");
        return NO;
    }
    
    if (![preloaderClass respondsToSelector:@selector(shouldPreload:)] &&
        ![preloaderClass respondsToSelector:@selector(engine:prelaod:)]) {
        TTVideoEngineLog(@"need imp method.");
        return NO;
    }
    
    @synchronized (TTVideoEnginePreloader.class) {
        if ([[self classSet] containsObject:preloaderClass]) {
            return NO;
        }
        
        [[self classSet] addObject:preloaderClass];
    }
    return YES;
}

+ (void)unregisterClass:(Class)preloaderClass {
    if (preloaderClass == nil) {
        return;
    }
    if (![preloaderClass respondsToSelector:@selector(shouldPreload:)] &&
        ![preloaderClass respondsToSelector:@selector(engine:prelaod:)]) {
        TTVideoEngineLog(@"need imp method.");
        return;
    }
    
    @synchronized (TTVideoEnginePreloader.class) {
        [[self classSet] removeObject:preloaderClass];
    }
}

@end
