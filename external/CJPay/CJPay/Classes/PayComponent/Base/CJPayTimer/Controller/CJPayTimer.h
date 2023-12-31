//
//  CJPayTimer.h
//  Pods
//
//  Created by 王新华 on 2020/12/10.
//

#import <Foundation/Foundation.h>

@protocol CJPayTimerProtocol <NSObject>

- (void)currentCountChangeTo:(int) value;

@end

NS_ASSUME_NONNULL_BEGIN

@interface CJPayTimer : NSObject

@property (nonatomic, assign, readonly) int curCount;

@property (nonatomic, weak) id<CJPayTimerProtocol> delegate;

- (void)startTimerWithCountTime:(int) countTime;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
