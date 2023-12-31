//
//  CJPayAlertSheetView.h
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import <UIKit/UIKit.h>

@class CJPayAlertSheetAction;

NS_ASSUME_NONNULL_BEGIN

/*
 * action按从下到上顺序排列
 * */
@interface CJPayAlertSheetView : UIView

@property (nonatomic, copy) void (^cancelBlock)(void);

- (instancetype)initWithFrame:(CGRect)frame isAlwaysShow:(BOOL)isAlwaysShow;

- (void)showOnView:(UIView *)view;

- (void)dismissWithCompletionBlock:(nullable void (^)(void))completionBlock;

- (void)addAction:(CJPayAlertSheetAction *)action;

@end


NS_ASSUME_NONNULL_END
