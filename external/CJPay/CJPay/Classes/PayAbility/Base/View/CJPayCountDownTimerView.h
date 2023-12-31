//
//  CJPayCountDownTimerView.h
//  CJPay
//
//  Created by 王新华 on 2019/4/23.
//

#import "CJPayTimerView.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayCountDownTimerViewDelegate <NSObject>

- (void)countDownTimerRunOut;

@end

typedef NS_ENUM(NSInteger, CJPayCountDownTimerViewStyle) {
    CJPayCountDownTimerViewStyleNormal,   //普通倒计时样式，聚合收银台使用
    CJPayCountDownTimerViewStyleSmall     //小倒计时样式，品牌升级收银台使用
};

@interface CJPayCountDownTimerView : CJPayTimerView

@property (nonatomic, assign, readonly) BOOL curTimeIsValid;
@property (nonatomic, weak) id<CJPayCountDownTimerViewDelegate> delegate;
@property (nonatomic, assign) CJPayCountDownTimerViewStyle style;

- (void)invalidate;

@end

NS_ASSUME_NONNULL_END
