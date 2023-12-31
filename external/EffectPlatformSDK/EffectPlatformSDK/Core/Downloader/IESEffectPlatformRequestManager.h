//
//  IESEffectPlatformRequestManager.h
//  AWEStudio
//
//  Created by 李彦松 on 2018/10/22.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <EffectPlatformSDK/EffectPlatform.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IESEffectPlatformRequestManager : NSObject<EffectPlatformRequestDelegate>
+ (instancetype)requestManager;
@end


@interface IESEffectPlatformRequestManager (PreFetch)

- (void)setPreFetchHeaderFieldsWithDictionary:(nonnull NSDictionary *)dictionary;

- (BOOL)isPreFetchCompletionWithCompletionObject:(nonnull id)object;

- (void)addPreFetchCompletionObject:(nonnull id)object;

- (void)clearPreFetchInfos;

@end

#ifndef IESEffectPreFetchProcessIfNeed(prevCompletion, nextCompletion)
#define IESEffectPreFetchProcessIfNeed(prevCompletion, nextCompletion)                                                    \
    if ([[IESEffectPlatformRequestManager requestManager] isPreFetchCompletionWithCompletionObject:prevCompletion]) {     \
        [[IESEffectPlatformRequestManager requestManager] addPreFetchCompletionObject:nextCompletion];                    \
    }
#endif

NS_ASSUME_NONNULL_END
