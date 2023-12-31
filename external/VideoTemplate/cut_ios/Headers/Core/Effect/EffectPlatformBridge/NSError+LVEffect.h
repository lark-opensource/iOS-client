//
//  NSError+LVEffect.h
//  VideoTemplate
//
//  Created by wuweixin on 2020/10/30.
//

#import <Foundation/Foundation.h>
#import "LVEffectDataSource.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *LVEffectDownloadProxyErrorDomain;

typedef NS_ENUM(NSInteger, LVEffectDownloadProxyError) {
    LVEffectDownloadProxyErrorUnknown = 0,
    LVEffectDownloadProxyErrorPlatformUnmatched = 90000, // 平台不匹配
    LVEffectDonwloadProxyErrorUnresolved = 90001,
};

@interface NSError (LVEffect)

+(NSError *)lv_effectDownloadProxyErrorWithCode:(LVEffectDownloadProxyError)code userInfo:(nullable NSDictionary<NSErrorUserInfoKey,id> *)userInfo;

+(NSError *)lv_effectDownloadProxyUnmatchedPlatform:(LVEffectSourcePlatform)unmatched expectedPlatform:(LVEffectSourcePlatform)expected;

+(NSError *)lv_effectDownloadProxyUnknownError;

@end

NS_ASSUME_NONNULL_END
