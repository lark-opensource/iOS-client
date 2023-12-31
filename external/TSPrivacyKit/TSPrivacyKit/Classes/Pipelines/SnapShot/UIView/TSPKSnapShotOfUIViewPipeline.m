//
//  TSPKSnapShotOfUIViewPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKSnapShotOfUIViewPipeline.h"
#import "NSObject+TSAddition.h"
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"
#import "TSPKPipelineSwizzleUtil.h"

@implementation UIView (TSPrivacyKitSnapShot)

+ (void)tspk_snapshot_preload {
    [TSPKPipelineSwizzleUtil swizzleMethodWithPipelineClass:[TSPKSnapShotOfUIViewPipeline class] clazz:self];
}

- (nullable UIView *)tspk_snapshot_resizableSnapshotViewFromRect:(CGRect)rect afterScreenUpdates:(BOOL)afterUpdates withCapInsets:(UIEdgeInsets)capInsets
{
    NSString *method = NSStringFromSelector(@selector(resizableSnapshotViewFromRect:afterScreenUpdates:withCapInsets:));
    NSString *className = [TSPKSnapShotOfUIViewPipeline stubbedClass];
    TSPKHandleResult *result = [TSPKSnapShotOfUIViewPipeline handleAPIAccess:method className:className];
    if (result.action == TSPKResultActionFuse) {
        return nil;
    } else if (result.action == TSPKResultActionCache) {
        NSString *api = [TSPKUtils concateClassName:className method:method];;
        if (![[TSPKCacheEnv shareEnv] needUpdate:api]) {
            return [[TSPKCacheEnv shareEnv] get:api];
        }
        UIView *originResult = [self tspk_snapshot_resizableSnapshotViewFromRect:rect afterScreenUpdates:afterUpdates withCapInsets:capInsets];
        [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
        return originResult;
    } else {
        return [self tspk_snapshot_resizableSnapshotViewFromRect:rect afterScreenUpdates:afterUpdates withCapInsets:capInsets];
    }
}

- (BOOL)tspk_snapshot_drawViewHierarchyInRect:(CGRect)rect afterScreenUpdates:(BOOL)afterUpdates
{
    TSPKHandleResult *result = [TSPKSnapShotOfUIViewPipeline handleAPIAccess:NSStringFromSelector(@selector(drawViewHierarchyInRect:afterScreenUpdates:)) className:[TSPKSnapShotOfUIViewPipeline stubbedClass]];
    if (result.action == TSPKResultActionFuse) {
        return NO;
    } else {
        return [self tspk_snapshot_drawViewHierarchyInRect:rect afterScreenUpdates:afterUpdates];
    }
}

@end

@implementation TSPKSnapShotOfUIViewPipeline

+ (NSString *)pipelineType {
    return TSPKPipelineSnapShotOfUIView;
}

+ (NSString *)dataType {
    return TSPKDataTypeSnapshot;
}

+ (NSString *)stubbedClass
{
    return @"UIView";
}

+ (NSArray<NSString *> *)stubbedClassAPIs
{
    return nil;
}

+ (NSArray<NSString *> *)stubbedInstanceAPIs
{
    return @[
        NSStringFromSelector(@selector(resizableSnapshotViewFromRect:afterScreenUpdates:withCapInsets:)),
        NSStringFromSelector(@selector(drawViewHierarchyInRect:afterScreenUpdates:))
    ];
}

+ (void)preload {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIView tspk_snapshot_preload];
    });
}

@end
