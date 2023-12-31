//
//  TTVideoEnginePerformanceCollector.h
//  TTVideoEngine
//
//  Created by 黄清 on 2019/7/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TTVideoEnginePerformancePoint <NSObject>

@required
- (void)addCpuUsagesPoint:(CGFloat)point;
- (void)addMemUsagesPoint:(CGFloat)point;

@end

@interface TTVideoEnginePerformanceCollector : NSObject

+ (void)addObserver:(id<TTVideoEnginePerformancePoint>)observer;
+ (void)removeObserver:(id<TTVideoEnginePerformancePoint>)observer;

@end

NS_ASSUME_NONNULL_END
