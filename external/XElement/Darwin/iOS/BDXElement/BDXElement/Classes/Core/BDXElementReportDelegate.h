//
//  BDXElementReportDelegate.h
//  BDXElement-Pods-Aweme
//
//  Created by zhoumin.zoe on 2020/10/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BDXElementReportDelegate <NSObject>

- (void)trackEventWithParams:(NSString *)event params:(NSDictionary *)params;

- (void)startTimingForKey:(NSString *)key;
- (NSTimeInterval)timeIntervalForKey:(NSString *)key;
// 结束timing，适用于一个生命周期内多次计时
- (BOOL)endTimingForKey:(id<NSCopying>)key service:(NSString *)service label:(NSString *)label duration:(nullable NSTimeInterval *)duration;
// 取消timing，适用于一个生命周期内一次计时
- (void)cancelTimingForKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
