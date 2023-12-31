//
//  IESGeckoDefines.h
//  IESGeckoKit
//
//  Created by willorfang on 2017/8/4.
//
//

#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

#ifndef IES_isEmptyString
#define IES_isEmptyString(param)        ( !(param) ? YES : ([(param) isKindOfClass:[NSString class]] ? (param).length == 0 : NO) )
#endif

#ifndef IES_isEmptyArray
#define IES_isEmptyArray(param)         ( !(param) ? YES : ([(param) isKindOfClass:[NSArray class]] ? (param).count == 0 : NO) )
#endif

#ifndef IES_isEmptyDictionary
#define IES_isEmptyDictionary(param)    ( !(param) ? YES : ([(param) isKindOfClass:[NSDictionary class]] ? (param).count == 0 : NO) )
#endif

#define GURD_CHECK_DICTIONARY(dict)     ([dict isKindOfClass:[NSDictionary class]] ? (dict.count > 0) : NO)

#pragma mark - Log

#if DEBUG

__unused static NSString *IESGurdKitCurrentTimeString()
{
    return [IESGurdNormalDateFormatter() stringFromDate:[NSDate date]];
}

#define GurdLog(s, ...) \
fprintf(stderr, "%s <%s:%d> %s\n", [IESGurdKitCurrentTimeString() UTF8String], [[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, [[NSString stringWithFormat:(s), ##__VA_ARGS__] UTF8String])

#else

#define GurdLog(s, ...)

#endif

#pragma mark - OnExit

#ifndef gurd_keywordify
#if DEBUG
#define gurd_keywordify autoreleasepool {}
#else
#define gurd_keywordify try {} @catch (...) {}
#endif
#endif

#ifndef gurdOnExit
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wunused-function"
static void gurdBlockCleanUp(__strong void(^_Nonnull* _Nonnull block)(void));
NS_INLINE void gurdBlockCleanUp(__strong void(^_Nonnull* _Nonnull block)(void))
{
    (*block)();
}
#pragma clang diagnostic pop
#define gurdOnExit \
gurd_keywordify __strong void(^block)(void) __attribute__((cleanup(gurdBlockCleanUp), unused)) = ^

#endif

#pragma mark - Lock

#ifndef GURD_MUTEX_LOCK
#define GURD_MUTEX_LOCK(lock) \
pthread_mutex_lock(&(lock)); \
@gurdOnExit{ \
pthread_mutex_unlock(&(lock)); \
};
#endif

#ifndef GURD_SEMEPHORE_LOCK
#define GURD_SEMEPHORE_LOCK(lock) \
dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER); \
@gurdOnExit{ \
dispatch_semaphore_signal(lock); \
};
#endif

#pragma mark - Time

#define GURD_TIK    NSDate *start = [NSDate date]
#define GURD_TOK    (NSInteger)([[NSDate date] timeIntervalSinceDate:start] * 1000)
#define GURD_TOK_WITH_START(start)    (NSInteger)([[NSDate date] timeIntervalSinceDate:start] * 1000)

#pragma mark - Network param keys

__unused static NSString *kIESGurdRequestColdLaunchKey = @"is_cold_launch";
__unused static NSString *kIESGurdRequestConfigLocalInfoKey = @"local";
__unused static NSString *kIESGurdRequestConfigDeploymentsInfoKey = @"deployments";
__unused static NSString *kIESGurdRequestConfigCustomInfoKey = @"custom";
__unused static NSString *kIESGurdRequestConfigRequestMetaKey = @"req_meta";
__unused static NSString *kIESGurdNetworkCommonKey = @"common";
__unused static NSString *kIESGurdSettingsRequestKey = @"settings";

/**
* ==== 预设请求自定义参数 ====
*/
__unused static NSString * const IESGurdCustomParamKeyBusinessVersion = @"business_version"; //资源版本

#pragma mark - Network completion

@class IESGurdFetchResourcesResult;
typedef void(^IESGurdFetchResourcesCompletion)(NSDictionary<NSString *, IESGurdFetchResourcesResult *> *results);

#pragma mark - NSSecureCoding - Decode

#define IES_DECODE_STRING(__decoder, __key)     \
self.__key = [__decoder decodeObjectOfClass:[NSString class] forKey:NSStringFromSelector(@selector(__key))]                     \

#define IES_DECODE_INT(__decoder, __key)        \
self.__key = [[__decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(__key))] intValue]          \

#define IES_DECODE_BOOL(__decoder, __key)       \
self.__key = [[__decoder decodeObjectOfClass:[NSNumber class] forKey:NSStringFromSelector(@selector(__key))] boolValue]         \

#pragma mark - NSSecureCoding - Encode

#define IES_ENCODE_OBJECT(__coder, __key)    \
[__coder encodeObject:self.__key forKey:NSStringFromSelector(@selector(__key))];        \

#define IES_ENCODE_NUMBER(__coder, __key)    \
[__coder encodeObject:@(self.__key) forKey:NSStringFromSelector(@selector(__key))];     \

NS_ASSUME_NONNULL_END


