//
//  NSOperation+BDPreloadTask.m
//  BDPreloadSDK
//
//  Created by wealong on 2019/8/14.
//

#import "NSOperation+BDPreloadTask.h"
#import <objc/runtime.h>

@implementation NSOperation (BDPreloadTask)

- (NSString *)bdp_preloadKey {
    return objc_getAssociatedObject(self, @selector(bdp_preloadKey));
}

- (void)setBdp_preloadKey:(NSString *)preloadKey {
    objc_setAssociatedObject(self, @selector(bdp_preloadKey), preloadKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)bdp_scene {
    return objc_getAssociatedObject(self, @selector(bdp_scene));
}

- (void)setBdp_scene:(NSString *)bdp_scene {
    objc_setAssociatedObject(self, @selector(bdp_scene), bdp_scene, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSTimeInterval)bdp_initTime {
    return [objc_getAssociatedObject(self, @selector(bdp_initTime)) doubleValue];
}

- (void)setBdp_initTime:(NSTimeInterval)initTime {
    objc_setAssociatedObject(self, @selector(bdp_initTime), @(initTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)bdp_startTime {
    return [objc_getAssociatedObject(self, @selector(bdp_startTime)) doubleValue];
}

- (void)setBdp_startTime:(NSTimeInterval)startTime {
    objc_setAssociatedObject(self, @selector(bdp_startTime), @(startTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSTimeInterval)bdp_finishTime {
    return [objc_getAssociatedObject(self, @selector(bdp_finishTime)) doubleValue];
}

- (void)setBdp_finishTime:(NSTimeInterval)finishTime {
    objc_setAssociatedObject(self, @selector(bdp_finishTime), @(finishTime), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bdp_onlyWifi {
    return [objc_getAssociatedObject(self, @selector(bdp_onlyWifi)) boolValue];
}

- (void)setBdp_onlyWifi:(BOOL)onlyWiFi {
    objc_setAssociatedObject(self, @selector(bdp_onlyWifi), @(onlyWiFi), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDPreloadType)bdp_preloadType {
    return [objc_getAssociatedObject(self, @selector(bdp_preloadType)) unsignedIntValue];
}

- (void)setBdp_preloadType:(BDPreloadType)bdp_preloadType {
    objc_setAssociatedObject(self, @selector(bdp_preloadType), @(bdp_preloadType), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (NSTimeInterval)bdp_waitTime {
    NSTimeInterval current = [[NSDate date] timeIntervalSince1970];
    if (self.bdp_startTime <= 0) {
        return current - self.bdp_initTime;
    } else {
        return self.bdp_startTime - self.bdp_initTime;
    }
}

- (void)setBdp_timeoutBlock:(dispatch_block_t)bdp_timeoutBlock {
    objc_setAssociatedObject(self, @selector(bdp_timeoutBlock), bdp_timeoutBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (dispatch_block_t)bdp_timeoutBlock {
    return objc_getAssociatedObject(self, @selector(bdp_timeoutBlock));
}

@end
