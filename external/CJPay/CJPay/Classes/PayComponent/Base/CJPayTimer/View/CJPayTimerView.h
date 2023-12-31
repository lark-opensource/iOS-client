//
//  CJPayTimerView.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayTimerView : UIButton

@property (nonatomic, assign, readonly) int curCount;

- (void)startTimerWithCountTime:(int) countTime;

- (void)currentCountChangeTo:(int) value;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
