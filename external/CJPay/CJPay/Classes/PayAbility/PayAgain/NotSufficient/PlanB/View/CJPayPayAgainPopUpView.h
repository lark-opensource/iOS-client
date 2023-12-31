//
//  CJPayPayAgainPopUpView.h
//  Pods
//
//  Created by wangxiaohong on 2021/6/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayButton;
@class CJPayStyleButton;
@class CJPayHintInfo;
@interface CJPayPayAgainPopUpView : UIView

@property (nonatomic, strong, readonly) CJPayButton *closeBtn;
@property (nonatomic, strong, readonly) CJPayStyleButton *confirmPayBtn;
@property (nonatomic, strong, readonly) CJPayButton *otherPayMethodButton;

- (void)refreshWithHintInfo:(CJPayHintInfo *)hintInfo;

@end

NS_ASSUME_NONNULL_END
