//
//  HMDOTTrace+Private.h
//  Heimdallr-iOS13.0
//
//  Created by fengyadong on 2020/2/24.
//
#import "HMDOTTrace.h"
NS_ASSUME_NONNULL_BEGIN


@interface HMDOTTrace (Private)

/// 待上报的字典数据
- (NSDictionary *)reportDictionary;

/// 所有被缓存过的span
- (NSArray<HMDOTSpan *> *)allCachedSpans;

/// 将采样率没获取之前的span缓存起来
/// @param span 被缓存的span
- (void)cacheOneSpan:(HMDOTSpan *)span;

/// 将采样率没获取之前的span缓存起来
/// @param spans 被缓存的spans
- (void)cacheCallbackSpans:(NSArray<HMDOTSpan *> *)spans;

/// 立即更新trace是否采样命中的标志
- (void)updateHitRules;

/// 获取trace所有tags
- (NSDictionary<NSString*, NSString*> *)obtainTraceTags;

/// 获取trace所有的span的ispanID
- (NSArray<NSString*> *)obtainSpanIDList;

/// 添加一个spanID到spanIDList
- (void)addOneSpanID:(NSString *)spanID;

/// 是否满足缓存未命中日志条件
- (BOOL)needCacheUnHit;

/// 将未命中采样trace的span缓存起来，需要满足needCacheUnhit条件
- (void)cacheOneSpanUnHit:(HMDOTSpan *)span;

/// 获取未命中采样trace的Span序列，需要满足needCacheUnhit条件，否则返回空数组
- (NSArray<HMDOTSpan *> *)obtainSpansUnHit;

#ifdef DEBUG
- (void)ignoreUnfinishedTraceAssert;
#endif

@end

NS_ASSUME_NONNULL_END
