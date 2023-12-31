//
//  HMDOTSpan+Private.h
//  Heimdallr-8bda3036
//
//  Created by liuhan on 2022/4/18.
//

#import "HMDOTSpan.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDOTSpan (Private)
@property (nonatomic, assign, readonly) BOOL isInstant;
@property (nonatomic, assign) NSUInteger needReferenceOtherLog;

/// 待上报的字典数据
- (NSDictionary *)reportDictionary;


@end

NS_ASSUME_NONNULL_END
