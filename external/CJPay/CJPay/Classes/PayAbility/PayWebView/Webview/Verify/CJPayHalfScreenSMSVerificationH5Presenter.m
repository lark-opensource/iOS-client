//
//  CJPayHalfScreenSMSVerificationH5Presenter.m
//  CJPay
//
//  Created by liyu on 2020/7/12.
//

#import "CJPayHalfScreenSMSVerificationH5Presenter.h"
#import "CJPaySMSVerificationRequestModel.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPaySimpleHalfScreenWebViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayLoadingManager.h"

@interface CJPayHalfScreenSMSVerificationH5Presenter ()

@property (nonatomic, weak) CJPayHalfScreenSMSVerificationViewController *vc;
@property (nonatomic, strong) CJPaySMSVerificationRequestModel *model;
@property (nonatomic, copy) void(^sendingBlock)(NSInteger code, NSString *type, NSString *data);

@end;

//static NSUInteger const kResendTimeoutSeconds = 10;

@implementation CJPayHalfScreenSMSVerificationH5Presenter

- (instancetype)initWithVC:(CJPayHalfScreenSMSVerificationViewController *)vc
                     model:(CJPaySMSVerificationRequestModel *)model
              sendingBlock:(void(^)(NSInteger code, NSString *type, NSString *data))sendingBlock
{
    self = [super init];
    if (self) {
        _vc = vc;
        _model = model;
        _sendingBlock = [sendingBlock copy];
    }
    return self;
}

#pragma mark - CJPayHalfScreenSMSVerificationViewInterface

- (void)render:(CJPayHalfScreenSMSVerificationViewController *)vc {
    self.vc.title = self.model.titleText ?: CJPayLocalizedStr(@"输入验证码");
    self.vc.codeCount = self.model.codeCount;
    self.vc.titleLabel.text = [NSString stringWithFormat:CJPayLocalizedStr(@"验证码已发送到你的%@手机"), self.model.phoneNumberText];

    if ([self.model.qaURLString length] > 0) {
        [self.vc.navigationBar addSubview:self.vc.helpButton];
        CJPayMasMaker(self.vc.helpButton, {
            make.width.height.equalTo(@24);
            make.trailing.equalTo(self.vc.navigationBar).inset(13);
            make.centerY.equalTo(self.vc.navigationBar);
        });
        
        [self.vc.helpButton addTarget:self action:@selector(goToHelpVC) forControlEvents:UIControlEventTouchUpInside];
    }

    [self.vc.countDownTimerView startTimerWithCountTime:(int)self.model.countDownSeconds];
}

- (void)didTapResendButton
{
    self.vc.countDownTimerView.enabled = NO;

    [self.vc.smsInputView resignFirstResponder];
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading title:self.model.titleText];
    CJ_CALL_BLOCK(self.sendingBlock,0,@"resend",@"");// 等待H5的resend-ok
    self.vc.countDownTimerView.enabled = YES;
}

- (void)didTapCloseButton
{
    CJ_CALL_BLOCK(self.sendingBlock,0, @"left", @"");
}

- (void)didEnterCode:(NSString *)code
{
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading title:self.model.titleText];
    CJ_CALL_BLOCK(self.sendingBlock,0, @"complete", CJString(code));
}

- (void) onReceiveH5Message:(NSDictionary *)message {
    NSString *messageType = [message btd_stringValueForKey:@"type"];
    NSString *extraData = [message btd_stringValueForKey:@"data"];
    NSString *action = [message[@"action"] cj_stringValueForKey:@"close_type"];
    CGFloat delayTime = [message[@"action"] cj_floatValueForKey:@"delay_time"];
    
    if ([messageType isEqualToString:@"resend-ok"]) {
        [[CJPayLoadingManager defaultService] stopLoading];
        [self.vc showErrorMessage:@""];
        [self.vc.smsInputView becomeFirstResponder];
        [self.vc.countDownTimerView startTimerWithCountTime:(int)self.model.countDownSeconds];
    } else if ([messageType isEqualToString:@"verify-ok"]) {
        [self.vc showState:CJPayStateTypeSuccess];
        [self closeWithAction:action delayTime:delayTime];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [[CJPayLoadingManager defaultService] stopLoading];
        });
    } else if ([messageType isEqualToString:@"verify-err"]) {
        [self.vc.smsInputView clearText];
        [[CJPayLoadingManager defaultService] stopLoading];
        [self.vc showErrorMessage:extraData];
        [self.vc.smsInputView becomeFirstResponder];
    } else if ([messageType isEqualToString:@"verify-close"]) {
        [self closeWithAction:action delayTime:delayTime];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [[CJPayLoadingManager defaultService] stopLoading];
        });
    }
}

- (void)closeWithAction:(nullable NSString *)action delayTime:(CGFloat)delayTime {
    [self.vc.countDownTimerView reset];
    if (!action || !Check_ValidString(action)) {
        [self.vc back];
    } else {
        if ([action isEqualToString:@"close-source"]) {
            NSArray *stackvcs = self.vc.navigationController.viewControllers;
            NSInteger index = [stackvcs indexOfObject:self.vc];
            if (index - 1 > 0) {
                [self.vc.navigationController popToViewController:[self.vc.navigationController.viewControllers objectAtIndex:index - 1] animated:YES];
            } else {
                [self.vc.presentingViewController dismissViewControllerAnimated:YES completion:nil];
            }
        } else if ([action isEqualToString:@"delay_close"]) {
            @CJWeakify(self);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                @CJStrongify(self);
                NSMutableArray *stackvcs = [self.vc.navigationController.viewControllers mutableCopy];
                [stackvcs removeObject:self.vc];
                if (stackvcs.count > 0) {
                    [self.vc.navigationController setViewControllers:[stackvcs copy]];
                }
            });
        } else {
            [self.vc back];
        }
    }
}

#pragma mark - Actions
-(void)goToHelpVC {
    CJPaySimpleHalfScreenWebViewController *vc = [[CJPaySimpleHalfScreenWebViewController alloc] initWithUrlString:self.model.qaURLString];
    vc.title = self.model.qaTitle ?: CJPayLocalizedStr(@"收不到验证码？");
    @CJWeakify(self)
    vc.didTapCloseButtonBlock = ^{
        CJ_CALL_BLOCK(weak_self.sendingBlock,0,@"back", @"");
    };
    CJ_CALL_BLOCK(self.sendingBlock,0,@"right",@"");
    [self.vc.navigationController pushViewController:vc animated:YES];
}

@end
