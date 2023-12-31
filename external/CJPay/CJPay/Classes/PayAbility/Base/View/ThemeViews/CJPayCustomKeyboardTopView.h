//
//  CJPayCustomKeyboardTopView.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/29.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayCustomKeyboardTopView : UIView

@property (nonatomic,copy) void(^completionBlock)(void);

- (void)setInsuranceURLString:(NSString *)insuranceUrlString;
- (void)setCompletionBtnHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
