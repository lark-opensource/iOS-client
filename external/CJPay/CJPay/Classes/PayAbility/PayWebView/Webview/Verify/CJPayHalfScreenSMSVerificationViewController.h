//
//  CJPayHalfScreenSMSVerificationViewController.h
//  CJPay
//
//  Created by liyu on 2020/7/9.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPaySMSInputView.h"
#import "CJPayVerifyCodeTimerLabel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayHalfScreenSMSVerificationViewController;

@protocol CJPayHalfScreenSMSVerificationViewInterface

// Presenter -> View
- (void)render:(CJPayHalfScreenSMSVerificationViewController *)vc;

// View -> Presenter
- (void)didEnterCode:(NSString *)code;

- (void)didTapCloseButton;
- (void)didTapResendButton;

@end

@class CJPayStyleErrorLabel;

@interface CJPayHalfScreenSMSVerificationViewController : CJPayHalfPageBaseViewController

@property (nonatomic, strong) CJPaySMSInputView *smsInputView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayButton *helpButton;

@property (nonatomic, strong) CJPayStyleErrorLabel *errorLabel;
@property (nonatomic, strong) CJPayVerifyCodeTimerLabel *countDownTimerView;

@property (nonatomic, copy) void(^completeBlock)(BOOL success, NSString *content);
@property (nonatomic, assign) BOOL textInputFinished;

@property (nonatomic, strong) id <CJPayHalfScreenSMSVerificationViewInterface> viewDelegate;


@property (nonatomic, assign) NSUInteger codeCount;

- (instancetype)initWithAnimationType:(HalfVCEntranceType)animationType;

- (void)verifySMS;

- (void)back;

- (void)showErrorMessage:(NSString *)message;

@end

NS_ASSUME_NONNULL_END
