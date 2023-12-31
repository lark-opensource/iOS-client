//
//  IESVdetectMonitorProtocol.h
//  IESVideoDetector
//
//  Created by geekxing on 2020/6/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol IESVdetectMonitorProtocol <NSObject>
// trackservice
- (void)trackService:(nullable NSString *)serviceName status:(NSInteger)status extra:(nullable NSDictionary *)extraValue;
// timing
- (void)startTimingForKey:(nonnull id<NSCopying>)key;
- (NSTimeInterval)timeIntervalForKey:(nonnull id<NSCopying>)key;
- (void)cancelTimingForKey:(nonnull id<NSCopying>)key;
@end

NS_ASSUME_NONNULL_END
