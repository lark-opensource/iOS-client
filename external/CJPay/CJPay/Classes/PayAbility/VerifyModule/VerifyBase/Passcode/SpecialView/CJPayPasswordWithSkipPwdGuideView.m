//
//  CJPayPasswordWithSkipPwdGuideView.m
//  arkcrypto-minigame-iOS
//
//  Created by chenbocheng on 2022/4/14.
//

#import "CJPayPasswordWithSkipPwdGuideView.h"
#import "CJPayPasswordBaseContentView.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPayUIMacro.h"
#import "CJPayGuideWithConfirmView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayStyleButton.h"

@interface CJPayPasswordWithSkipPwdGuideView ()

@property (nonatomic, strong) CJPayVerifyPasswordViewModel *viewModel;
@property (nonatomic, strong) CJPayPasswordBaseContentView *baseContentView;
@property (nonatomic, strong) CJPayGuideWithConfirmView *guideView;
@property (nonatomic, assign) CGFloat containerHeight;

@end

@implementation CJPayPasswordWithSkipPwdGuideView

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel containerHeight:(CGFloat)containerHeight {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.containerHeight = containerHeight;
        @CJWeakify(self)
        self.viewModel.inputChangeBlock = ^(NSString * _Nonnull inputText) {
            @CJStrongify(self)
            self.guideView.confirmButton.enabled = inputText.length == 6;
        };
        [self p_setupUI];
    }
    return self;
}

#pragma mark - private method

- (void)p_setupUI {
    [self addSubview:self.baseContentView];
    [self addSubview:self.guideView];
    [self addSubview:self.viewModel.errorInfoActionView];
    
    CJPayMasMaker(self.baseContentView, {
        make.top.left.right.equalTo(self);
    });
    
    CJPayMasMaker(self.viewModel.errorInfoActionView, {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self.viewModel.marketingMsgView);
    });
    [self.viewModel.marketingMsgView setMinHeightForDiscountLabel];
    
    int guideViewOffset = 16;
    CJPayMasMaker(self.guideView, {
        make.bottom.equalTo(self).offset(-[self.viewModel.inputPasswordView getFixKeyBoardHeight] - guideViewOffset);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
    });
    
    if (self.viewModel.response.topRightBtnInfo) {
        self.viewModel.forgetPasswordBtn.hidden = YES;
    }
}

- (BOOL)p_isShowGuideButton {
    return self.viewModel.response.skipPwdGuideInfoModel.isShowButton;
}

- (void)p_resetButtonTitle {
    if ([self.guideView.protocolView isCheckBoxSelected]) {
        NSString *buttonText = Check_ValidString(self.viewModel.response.skipPwdGuideInfoModel.buttonText) ? self.viewModel.response.skipPwdGuideInfoModel.buttonText : CJPayLocalizedStr(@"开通并支付");
        [self.guideView.confirmButton cj_setBtnTitle:buttonText];
    } else {
        [self.guideView.confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"确认支付")];
    }
}

#pragma mark - lazy views

- (CJPayPasswordBaseContentView *)baseContentView {
    if (!_baseContentView) {
        _baseContentView = [[CJPayPasswordBaseContentView alloc] initWithViewModel:self.viewModel];
    }
    return _baseContentView;
}

- (CJPayGuideWithConfirmView *)guideView {
    if (!_guideView) {
        CJPayCommonProtocolModel *protocolModel = [CJPayCommonProtocolModel new];
        protocolModel.guideDesc = self.viewModel.response.skipPwdGuideInfoModel.guideMessage;
        protocolModel.groupNameDic = self.viewModel.response.skipPwdGuideInfoModel.protocolGroupNames;
        protocolModel.agreements = self.viewModel.response.skipPwdGuideInfoModel.protocoList;
        protocolModel.isSelected = self.viewModel.response.skipPwdGuideInfoModel.isChecked || self.viewModel.response.skipPwdGuideInfoModel.isSelectedManually;
        self.viewModel.isGuideSelected = protocolModel.isSelected;
        protocolModel.selectPattern = CJPaySelectButtonPatternCheckBox;
        protocolModel.protocolDetailContainerHeight = @(self.containerHeight);
        _guideView = [[CJPayGuideWithConfirmView alloc] initWithCommonProtocolModel:protocolModel isShowButton:[self p_isShowGuideButton]];
        _guideView.confirmButton.enabled = NO;
        
        NSString *choosedBtnText = Check_ValidString(self.viewModel.response.skipPwdGuideInfoModel.buttonText) ? self.viewModel.response.skipPwdGuideInfoModel.buttonText : CJPayLocalizedStr(@"开通并支付");
        NSString *buttonText = protocolModel.isSelected ? choosedBtnText : CJPayLocalizedStr(@"确认支付");
        [_guideView.confirmButton cj_setBtnTitle:buttonText];
        @CJWeakify(self)
        [_guideView.confirmButton btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.onConfirmClickBlock);
        }];
        _guideView.protocolView.protocolClickBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
            @CJStrongify(self)
            [self.viewModel trackPageClickWithButtonName:@"4"];
            CJ_CALL_BLOCK(self.protocolClickBlock);
        };
        _guideView.protocolView.checkBoxClickBlock = ^{
            @CJStrongify(self)
            [self p_resetButtonTitle];
            self.viewModel.isGuideSelected = [self.guideView.protocolView isCheckBoxSelected];
            NSString *buttonName = self.viewModel.isGuideSelected ? @"2" : @"3";
            [self.viewModel trackPageClickWithButtonName: buttonName];
        };
    }
    return _guideView;
}

@end

