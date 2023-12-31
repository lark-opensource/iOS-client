//
//  TSPKSnapShotOfUIGraphicsPipeline.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/6/14.
//

#import "TSPKSnapShotOfUIGraphicsPipeline.h"
#include <BDFishhook/BDFishhook.h>
#import "TSPKFishhookUtils.h"
#import "TSPKUtils.h"
#import "TSPKCacheEnv.h"

static NSString *const GetImageFromCurrentImageContext = @"UIGraphicsGetImageFromCurrentImageContext";

static UIImage* (*old_UIGraphicsGetImageFromCurrentImageContext)(void) = UIGraphicsGetImageFromCurrentImageContext;

static UIImage* tspk_new_UIGraphicsGetImageFromCurrentImageContext(void)
{
    @autoreleasepool {
        TSPKHandleResult *result = [TSPKSnapShotOfUIGraphicsPipeline handleAPIAccess:GetImageFromCurrentImageContext];
        if (result.action == TSPKResultActionFuse) {
            return nil;
        } else if (result.action == TSPKResultActionCache) {
            NSString *api = GetImageFromCurrentImageContext;
            if (![[TSPKCacheEnv shareEnv] needUpdate:api]) {
                return [[TSPKCacheEnv shareEnv] get:api];
            }
            UIImage *originResult = old_UIGraphicsGetImageFromCurrentImageContext();
            [[TSPKCacheEnv shareEnv] updateCache:api newValue:originResult];
            return originResult;
        } else {
            return old_UIGraphicsGetImageFromCurrentImageContext();
        }
    }
}

@implementation TSPKSnapShotOfUIGraphicsPipeline

+ (NSString *)pipelineType {
    return TSPKPipelineSnapShotOfUIGraphics;
}

+ (NSString *)dataType {
    return TSPKDataTypeSnapshot;
}

+ (NSArray<NSString *> * _Nullable)stubbedCAPIs
{
    return @[GetImageFromCurrentImageContext];
}

+ (NSString *)stubbedClass
{
    return nil;
}

+ (void)preload {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct bd_rebinding uiGraphicsGetImageFromCurrentImageContext;
        uiGraphicsGetImageFromCurrentImageContext.name = [GetImageFromCurrentImageContext UTF8String];
        uiGraphicsGetImageFromCurrentImageContext.replacement = tspk_new_UIGraphicsGetImageFromCurrentImageContext;
        uiGraphicsGetImageFromCurrentImageContext.replaced = (void *)&old_UIGraphicsGetImageFromCurrentImageContext;
        struct bd_rebinding rebs[]={uiGraphicsGetImageFromCurrentImageContext};
        tspk_rebind_symbols(rebs, 1);
    });
}

- (BOOL)deferPreload
{
    return YES;
}

@end
