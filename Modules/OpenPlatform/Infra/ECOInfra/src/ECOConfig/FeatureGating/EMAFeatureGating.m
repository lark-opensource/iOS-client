//
//  EMAFeatureGating.m
//  ECOInfra
//
//  Created by Meng on 2021/3/31.
//

#import "EMAFeatureGating.h"
#import <ECOInfra/BDPLog.h>
#import <ECOInfra/ECOInfra-Swift.h>

@implementation EMAFeatureGating

#pragma mark - get & set

+ (BOOL)boolValueForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    if (key.length == 0) {
        return defaultValue;
    }
    return [ECOConfigDependency getFeatureGatingBoolValueFor:key defaultValue:defaultValue];
}

+ (BOOL)boolValueForKey:(NSString *)key {
    return [self boolValueForKey:key defaultValue:NO];
}

+ (void)checkForKey:(NSString *)key completion:(void (^)(BOOL enable))completion {
    if (key.length == 0) {
        if (completion) {
            completion(NO);
        }
        return;
    }
    void (^safeCompletion)(BOOL) = ^(BOOL enable) {
        BDPLogInfo(@"checkForKey key=%@, enable=%@", key, @(enable))

        if (completion) {
            completion(enable);
        }
    };
    [ECOConfigDependency checkFeatureGatingFor:key completion:safeCompletion];
}

+ (BOOL)staticBoolValueForKey:(NSString *)key {
    return [ECOConfigDependency getStaticFeatureGatingBoolValueFor:key];
}

@end

