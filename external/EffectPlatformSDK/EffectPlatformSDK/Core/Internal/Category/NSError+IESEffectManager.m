//
//  NSError+IESEffectManager.m
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/19.
//

#import "NSError+IESEffectManager.h"

@implementation NSError (IESEffectManager)

+ (NSError *)ieseffect_errorWithCode:(NSInteger)code description:(NSString *)description {
    return [NSError errorWithDomain:@"com.bytedance.ies.effectplatform.error"
                               code:code
                           userInfo:@{NSLocalizedDescriptionKey: description?:@""}];
}

@end
