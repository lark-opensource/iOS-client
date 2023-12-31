//
//  CJPaySkippwdAfterpayGuideView.h
//  Pods
//
//  Created by 利国卿 on 2022/4/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayBDOrderResultResponse;
@class CJPayAccountInsuranceTipView;
@class CJPayCommonProtocolView;
@class CJPayStyleButton;
@class CJPayUIMacro;

@interface CJPaySkippwdAfterpayGuideView : UIView

@property (nonatomic, strong) UIImageView *topImageView;
@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;
@property (nonatomic, strong) UIStackView *tipsStackView;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;

- (instancetype)initWithOrderResponse:(CJPayBDOrderResultResponse *)orderResponse;
@end

NS_ASSUME_NONNULL_END
