//
//  CJPaySkipPwdConfirmHalfPageView.h
//  Aweme
//
//  Created by 陈博成 on 2023/5/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayButton;
@class CJPayStyleButton;
@class CJPayStyleCheckBox;
@class CJPayMarketingMsgView;
@class CJPaySecondaryConfirmInfoModel;

@interface CJPaySkipPwdConfirmHalfPageView : UIView

@property (nonatomic, strong, readonly) CJPayButton *closeButton;
@property (nonatomic, strong, readonly) CJPayStyleButton *confirmPayBtn;
@property (nonatomic, strong, readonly) CJPayStyleCheckBox *checkBox;
@property (nonatomic, strong, readonly) CJPayMarketingMsgView *marketingMsgView;
@property (nonatomic, strong, readonly) UILabel *checkDescLabel;

- (instancetype)initWithModel:(CJPaySecondaryConfirmInfoModel *)model;

@end

NS_ASSUME_NONNULL_END
