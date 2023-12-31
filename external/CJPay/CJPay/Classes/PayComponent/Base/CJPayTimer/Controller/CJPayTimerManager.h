//
//  CJPayTimerManager.h
//  Pods
//
//  Created by 易培淮 on 2021/8/17.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayTimerManager : NSObject

@property (nonatomic, copy) void(^timeOutBlock)(void);

- (void)startTimer:(NSTimeInterval)time;
- (void)stopTimer;
- (void)createTimer:(NSTimeInterval)time;
- (void)detoryTimer;
- (BOOL)isTimerValid;
- (void)appendTimeoutBlock:(void (^)(void))appendBlock;

@end

NS_ASSUME_NONNULL_END
