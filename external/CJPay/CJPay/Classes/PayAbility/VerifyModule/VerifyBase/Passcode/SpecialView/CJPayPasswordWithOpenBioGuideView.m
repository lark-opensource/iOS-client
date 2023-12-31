//
//  CJPayPasswordWithOpenBioGuideView.m
//  arkcrypto-minigame-iOS
//
//  Created by chenbocheng on 2022/4/14.
//

#import "CJPayPasswordWithOpenBioGuideView.h"
#import "CJPayPasswordBaseContentView.h"
#import "CJPayVerifyPasswordViewModel.h"
#import "CJPayUIMacro.h"
#import "CJPayGuideWithConfirmView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayCommonProtocolView.h"

@interface CJPayPasswordWithOpenBioGuideView ()

@property (nonatomic, strong) CJPayVerifyPasswordViewModel *viewModel;
@property (nonatomic, strong) CJPayPasswordBaseContentView *baseContentView;
@property (nonatomic, strong) CJPayGuideWithConfirmView *guideView;

@end

@implementation CJPayPasswordWithOpenBioGuideView

- (instancetype)initWithViewModel:(CJPayVerifyPasswordViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
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
    [self addSubview:self.viewModel.errorInfoActionView];
    [self addSubview:self.guideView];
    
    CJPayMasMaker(self.baseContentView, {
        make.top.left.right.equalTo(self);
    });
    
    CJPayMasMaker(self.viewModel.errorInfoActionView, {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self.viewModel.marketingMsgView);
    });
    
    [self.viewModel.marketingMsgView setMinHeightForDiscountLabel];
    
    CJPayMasMaker(self.guideView, {
        make.bottom.equalTo(self).offset(-[self.viewModel.inputPasswordView getFixKeyBoardHeight] - 16);
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
    });
    
    if (self.viewModel.response.topRightBtnInfo) {
        self.viewModel.forgetPasswordBtn.hidden = YES;
    }
    
    [self p_resetButtonTitle];
}

- (void)p_resetButtonTitleWithIsFirstAppear:(BOOL)isFirstAppear {
    NSString *choosedBtnText = Check_ValidString(self.viewModel.response.preBioGuideInfo.btnDesc) ? self.viewModel.response.preBioGuideInfo.btnDesc : CJPayLocalizedStr(@"确认升级并支付");
    NSString *defaultBtnText = CJPayLocalizedStr(@"确认支付");
    if (isFirstAppear) {
        [self.guideView.confirmButton cj_setBtnTitle:self.viewModel.response.preBioGuideInfo.choose ? choosedBtnText : defaultBtnText];
    } else {
        [self.guideView.confirmButton cj_setBtnTitle:self.guideView.protocolView.isCheckBoxSelected ? choosedBtnText : defaultBtnText];
    }
}

- (void)p_resetButtonTitle {
    [self p_resetButtonTitleWithIsFirstAppear:NO];
}

#pragma mark - lazy viewsv

- (CJPayPasswordBaseContentView *)baseContentView {
    if (!_baseContentView) {
        _baseContentView = [[CJPayPasswordBaseContentView alloc] initWithViewModel:self.viewModel];
    }
    return _baseContentView;
}

- (CJPayGuideWithConfirmView *)guideView {
    if (!_guideView) {
        CJPayCommonProtocolModel *protocolModel = [CJPayCommonProtocolModel new];
        protocolModel.guideDesc = self.viewModel.response.preBioGuideInfo.title;
        protocolModel.isSelected = self.viewModel.response.preBioGuideInfo.choose;
        self.viewModel.isGuideSelected = protocolModel.isSelected;
        protocolModel.protocolFont = [UIFont cj_fontOfSize:13];
        if ([self.viewModel.response.preBioGuideInfo.guideStyle isEqualToString:@"SWITCH"]) {
            protocolModel.selectPattern = CJPaySelectButtonPatternSwitch;
        } else {
            protocolModel.selectPattern = CJPaySelectButtonPatternCheckBox;
        }
        _guideView = [[CJPayGuideWithConfirmView alloc] initWithCommonProtocolModel:protocolModel isShowButton:self.viewModel.response.preBioGuideInfo.isShowButton];
        _guideView.confirmButton.enabled = NO;
        @CJWeakify(self)
        [_guideView.confirmButton btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.onConfirmClickBlock);
        }];
        _guideView.protocolView.checkBoxClickBlock = ^{
            @CJStrongify(self)
            [self p_resetButtonTitle];
            self.viewModel.isGuideSelected = self.guideView.protocolView.isCheckBoxSelected;
            NSString *buttonName = self.viewModel.isGuideSelected ? @"2" : @"3";
            [self.viewModel trackPageClickWithButtonName: buttonName];
        };
    }
    return _guideView;
}

@end
