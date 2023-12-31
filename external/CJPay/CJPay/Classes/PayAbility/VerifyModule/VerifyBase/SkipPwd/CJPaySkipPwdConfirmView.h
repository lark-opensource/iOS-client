//
//  CJPaySkipPwdConfirmView.h
//  Pods
//
//  Created by wangxiaohong on 2021/12/21.
//

#import <UIKit/UIKit.h>
#import "CJPayMarketingMsgView.h"
#import "CJPayCombineDetailView.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayButton;
@class CJPayStyleButton;
@class CJPayStyleCheckBox;
@class CJPaySecondaryConfirmInfoModel;
@interface CJPaySkipPwdConfirmView : UIView

@property (nonatomic, strong, readonly) CJPayButton *closeButton;
@property (nonatomic, strong, readonly) CJPayStyleButton *confirmPayBtn;
@property (nonatomic, strong, readonly) CJPayStyleCheckBox *checkBox;
@property (nonatomic, strong, readonly) CJPayMarketingMsgView *marketingMsgView;
@property (nonatomic, strong, readonly) CJPayCombineDetailView * combineDetailView;
@property (nonatomic, strong, readonly) UILabel *checkDescLabel;

- (instancetype)initWithModel:(CJPaySecondaryConfirmInfoModel *)model;
- (void)updateWithIsShowCombine:(BOOL)isShowCombine;

@end

NS_ASSUME_NONNULL_END
