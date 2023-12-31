//
//  CJPayBindCardNumberView.m
//  Pods
//
//  Created by renqiang on 2021/7/2.
//

#import "CJPayBindCardNumberView.h"
#import "CJPayBindCardHeaderView.h"
#import "CJPayCenterTextFieldContainer.h"
#import "CJPayBindCardFirstStepOCRView.h"
#import "CJPayBindCardFirstStepCardTipView.h"
#import "CJPayBindCardFirstStepPhoneTipView.h"
#import "CJPayCardOCRResultModel.h"
#import "CJPayBindCardAuthPhoneTipsView.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayProtocolViewManager.h"
#import "CJPayStyleButton.h"
#import "CJPayMemCardBinResponse.h"
#import "CJPayUserInfo.h"
#import "CJPayUIMacro.h"
#import "CJPayMemBankInfoModel.h"
#import "CJPayBindCardVoucherInfo.h"
#import "CJPayBindCardRecommendBankView.h"
#import "CJPayMethodCellTagView.h"

@interface CJPayBindCardNumberView ()

#pragma mark - flag
@property (nonatomic, assign) BOOL isFrontSecondStepBindCardShown;
@property (nonatomic, assign) BOOL isCloseAuthTips;
@property (nonatomic, strong) MASConstraint *cardNumContainerTopConstraint;
@property (nonatomic, strong) MASConstraint *nextBtnTopAlighCardImgViewConstraint;
@property (nonatomic, strong) MASConstraint *nextBtnTopAlighProtocolViewConstraint;
@property (nonatomic, assign, readwrite) CJPayBindCardNumberViewShowType curShowType;
@property (nonatomic, strong) UIView *innerCardbackView;

@end

@implementation CJPayBindCardNumberView

- (instancetype)initWithBindCardDictonary:(NSDictionary *)dict {
    if (self = [super initWithBindCardDictonary:dict]) {
        [self p_setupUI];
        [self changeShowTypeTo:CJPayBindCardNumberViewShowTypeOriginal];
    }
    return self;
}

- (void)p_setupUI {
    
    self.innerCardbackView = [UIView new];
    self.innerCardbackView.backgroundColor = UIColor.whiteColor;
    self.innerCardbackView.clipsToBounds = YES;
    self.innerCardbackView.layer.cornerRadius = 8;
    self.innerCardbackView.layer.borderColor = [UIColor cj_ffffffWithAlpha:1].CGColor;
    [self addSubview:self.innerCardbackView];
    
    [self addSubview:self.headerView];
    [self addSubview:self.cardTipView];
    [self addSubview:self.cardNumContainer];
    [self addSubview:self.ocrButtonView];
    [self addSubview:self.recommendBankView];
    [self addSubview:self.cardImgView];
    [self addSubview:self.nextStepButton];
    [self addSubview:self.phoneContainer];
    [self addSubview:self.phoneTipView];
    [self addSubview:self.authPhoneTipsView];
    [self addSubview:self.protocolView];
    
    CJPayMasMaker(self.innerCardbackView, {
        make.top.bottom.equalTo(self);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
    })
        
    CJPayMasMaker(self.headerView, {
        make.top.left.right.equalTo(self);
        make.height.mas_equalTo(48);
    });
    
    CJPayMasMaker(self.cardNumContainer, {
        self.cardNumContainerTopConstraint = make.top.equalTo(self.headerView.mas_bottom);
        make.left.equalTo(self).offset(32);
        make.right.equalTo(self).offset(-32);
        make.height.mas_equalTo(52);
    });
    CJPayMasMaker(self.ocrButtonView, {
        make.right.equalTo(self).offset(-47);
        make.centerY.equalTo(self.cardNumContainer);
        make.size.mas_equalTo(CGSizeMake(24, 24));
    });
    
    CJPayMasMaker(self.cardTipView, {
        make.bottom.equalTo(self.headerView).offset(11);
        make.left.equalTo(self).offset(32);
        make.right.equalTo(self).offset(-32);
        make.height.equalTo(@(20));
    });
    self.cardTipView.hidden = YES;
    
    CJPayMasMaker(self.recommendBankView, {
        make.bottom.equalTo(self.headerView).offset(11);
        make.left.equalTo(self).offset(32);
        make.right.equalTo(self).offset(-32);
    });
    self.recommendBankView.hidden = YES;
    
    CJPayMasMaker(self.cardImgView, {
        make.top.equalTo(self.cardNumContainer.mas_bottom);
        make.left.equalTo(self).offset(32);
        make.right.equalTo(self).offset(-32);
        make.height.mas_equalTo(0);
    });
    
    CJPayMasMaker(self.phoneContainer, {
        make.top.equalTo(self.cardImgView.mas_bottom).offset(34);
        make.height.left.right.equalTo(self.cardNumContainer);
    });
    CJPayMasMaker(self.phoneTipView, {
        make.bottom.equalTo(self.phoneContainer.mas_top).offset(-6);
        make.left.equalTo(self.phoneContainer);
        make.right.lessThanOrEqualTo(self.phoneContainer);
        make.height.mas_equalTo(12 * [UIFont cjpayFontScale]);
    });
    self.phoneContainer.hidden = YES;
    self.phoneTipView.hidden = YES;
    CJPayMasMaker(self.authPhoneTipsView, {
        make.top.equalTo(self.phoneContainer.mas_bottom).offset(4);
        make.left.equalTo(self).offset(32);
        make.right.equalTo(self).offset(-32);
        make.height.mas_equalTo(55);
    });
    CJPayMasMaker(self.protocolView, {
        make.top.equalTo(self.phoneContainer.mas_bottom).offset(15);
        make.left.equalTo(self.phoneContainer);
        make.right.lessThanOrEqualTo(self.phoneContainer);
    });
    CJPayMasMaker(self.nextStepButton, {
        self.nextBtnTopAlighCardImgViewConstraint = make.top.equalTo(self.cardImgView.mas_bottom).offset(28);
        self.nextBtnTopAlighProtocolViewConstraint = make.top.equalTo(self.protocolView.mas_bottom).offset(8);
        make.bottom.equalTo(self).offset(-16);
        make.height.mas_equalTo(44);
        make.left.equalTo(self.phoneContainer);
        make.right.equalTo(self.phoneContainer);
    });
    self.authPhoneTipsView.hidden = YES;
    self.protocolView.hidden = YES;
    self.nextStepButton.hidden = YES;

    [self.cardNumContainer bringSubviewToFront:self.ocrButtonView];
    if (self.viewModel.bankSupportListResponse) {
        [self updateCardTipsAsVoucherMsgWithResponse:self.viewModel.bankSupportListResponse];
    }
    
    [self p_updateContainerFont];
}

- (void)p_showCardTipView {
    self.cardTipView.hidden = NO;
    self.recommendBankView.hidden = YES;
}

- (void)p_showRecommentBankView {
    self.recommendBankView.hidden = NO;
    self.cardTipView.hidden = YES;
}

- (void)p_resetOriginalViewShowState {
    [self.nextBtnTopAlighCardImgViewConstraint deactivate];
    [self.nextBtnTopAlighProtocolViewConstraint deactivate];
    self.phoneContainer.hidden = YES;
    self.phoneTipView.hidden = YES;
    self.authPhoneTipsView.hidden = YES;
    self.protocolView.hidden = YES;
    self.nextStepButton.hidden = YES;
    self.recommendBankView.hidden = YES;
    [self.nextStepButton setTitle:CJPayLocalizedStr(@"下一步") forState:UIControlStateNormal];
}

- (BOOL)isNotInput {
    return ![self.cardNumContainer isFirstResponder] && !Check_ValidString(self.cardNumContainer.textField.text);
}

- (void)changeShowTypeTo:(CJPayBindCardNumberViewShowType)showType {
    [self p_resetOriginalViewShowState];
    self.curShowType = showType;
    switch (showType) {
        case CJPayBindCardNumberViewShowTypeOriginal:
            self.cardNumContainerTopConstraint.offset(0);
            self.cardTipView.hidden = YES;
            break;
        case CJPayBindCardNumberViewShowTypeShowRecommendBank:
            self.cardNumContainerTopConstraint.offset(20);
            [self p_showRecommentBankView];
            break;
        case CJPayBindCardNumberViewShowTypeOriginalShowBankCardVoucher:
            self.cardNumContainerTopConstraint.offset(20);
            [self p_showCardTipView];
            break;
        case CJPayBindCardNumberViewShowTypeOriginalNoAuth:
            self.cardNumContainerTopConstraint.offset(20);
            [self.nextBtnTopAlighCardImgViewConstraint activate];
            self.nextStepButton.hidden = NO;
            [self p_showCardTipView];
            break;
        case CJPayBindCardNumberViewShowTypeCardInputFocus:
            self.cardNumContainerTopConstraint.offset(0);
            [self.nextBtnTopAlighCardImgViewConstraint activate];
            self.nextStepButton.hidden = NO;
            if ([self.recommendBankView isTipsShow]) {
                self.cardNumContainerTopConstraint.offset(20);
                [self p_showRecommentBankView];
            } else {
                [self p_updateCardNumConstraint];
            }
            break;
        case CJPayBindCardNumberViewShowTypeShowPhoneInput:
            self.phoneTipView.hidden = NO;
            self.phoneContainer.hidden = NO;
            self.protocolView.hidden = NO;
            self.nextStepButton.hidden = NO;
            [self updatePhoneTips:CJPayLocalizedStr(@"银行预留手机号")];
            [self.nextBtnTopAlighProtocolViewConstraint activate];
            self.nextStepButton.hidden = NO;
            break;
        case CJPayBindCardNumberViewShowTypeShowPhoneAuth:
            self.phoneTipView.hidden = NO;
            self.phoneContainer.hidden = NO;
            self.protocolView.hidden = NO;
            self.nextStepButton.hidden = NO;
            
            self.authPhoneTipsView.hidden = NO;
            [self updatePhoneTips:CJPayLocalizedStr(@"银行预留手机号")];
            [self.nextBtnTopAlighProtocolViewConstraint activate];
            self.nextStepButton.hidden = NO;
            break;
            
        default:
            break;
    }
    [self invalidateIntrinsicContentSize];
}

- (void)updateCardNumContainerPlaceHolderTextWithName:(NSString *)name {
    NSString *preText = CJPayLocalizedStr(@"点击输入");
    NSString *midText = CJString(name);
    NSString *postText = CJPayLocalizedStr(@"的银行卡号");
    self.cardNumContainer.placeHolderText = [NSString stringWithFormat:@"%@ %@ %@", preText, midText, postText];
}

- (void)updateCardTipsMemBankInfoModel:(CJPayMemBankInfoModel *)model {
    [self.cardTipView updateWithBankInfoModel:model];
    [self p_updateCardNumConstraint];
}

- (void)updateCardTipsWithWarningText:(NSString *)tipsText {
    [self.cardTipView updateTips:tipsText];
    [self p_updateCardNumConstraint];
}

- (void)updateCardTipsWithNormalText:(NSString *)tipsText {
    [self.cardTipView updateTips:tipsText withColor:[UIColor cj_161823WithAlpha:0.75]];
    [self p_updateCardNumConstraint];
}

- (void)updateCardTipsAsVoucherMsgWithResponse:(CJPayMemBankSupportListResponse *)response {
    [self.cardTipView updateTipsWithSupportListResponse:response];
    [self p_updateCardNumConstraint];
}

- (void)updateCardTipsWithQuickBindCardModel:(CJPayQuickBindCardModel *)quickBindCardModel {
    [self.cardTipView updateCardTipsWithQuickBindCardModel:quickBindCardModel];
    if ([self.cardTipView isShowContent]) {
        self.recommendBankView.hidden = YES;
    }
    [self p_updateCardNumConstraint];
}

- (BOOL)layoutFrontSecondStepBindCard:(CJPayMemCardBinResponse *)response {
    if (![self p_isAuthorized]) {
        [self changeShowTypeTo:CJPayBindCardNumberViewShowTypeOriginalNoAuth];
        // 未实名用户不展示
        return NO;
    }
    
    BOOL showingFrontSecondStep = NO;
    
    if (!self.isFrontSecondStepBindCardShown) {
        [self bringSubviewToFront:self.authPhoneTipsView];
        
        [self changeShowTypeTo:CJPayBindCardNumberViewShowTypeShowPhoneAuth];
        
        self.isFrontSecondStepBindCardShown = YES;
        showingFrontSecondStep = YES;
        CJ_CALL_BLOCK(self.didFrontSecondStepBindCardAppearBlock);
    } else {
        [self changeShowTypeTo:CJPayBindCardNumberViewShowTypeShowPhoneInput];
    }
    
    if (response.agreements.count == 0) {
        CJPayMasUpdate(self.protocolView, {
            make.height.mas_equalTo(0);
        });
    } else {
        CJPayCommonProtocolModel *commonModel = [CJPayCommonProtocolModel new];
        commonModel.guideDesc = response.guideMessage;
        commonModel.groupNameDic = response.protocolGroupNames;
        commonModel.agreements = response.agreements;
        commonModel.protocolCheckBoxStr = response.protocolCheckBox;
        commonModel.supportRiskControl = YES;
        commonModel.isSelected = [self.protocolView isCheckBoxSelected];
        [self.protocolView updateWithCommonModel:commonModel];
        [self.nextStepButton setTitle:CJPayLocalizedStr(@"同意协议并继续") forState:UIControlStateNormal];
    }
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    
    return showingFrontSecondStep;
}

#pragma mark - private method
- (void)p_updateContainerFont {
    self.cardNumContainer.placeHolderLabel.font = [UIFont cj_fontOfSize:14];
    self.phoneContainer.placeHolderLabel.font = [UIFont cj_fontOfSize:14];
}

- (BOOL)p_isAuthorized {
    return [self.dataModel.userInfo hasValidAuthStatus] || self.dataModel.isCertification;
}

- (void)p_ocrButtonClick {
    if ([self.nextStepButton isHidden]) {
        [self changeShowTypeTo:CJPayBindCardNumberViewShowTypeCardInputFocus];
    }
    CJ_CALL_BLOCK(self.didClickOCRButtonBlock);
}

- (void)p_updateCardNumConstraint {
    if ([self p_isCardNumContainerHeadShow]) {
        self.cardNumContainerTopConstraint.offset(20);
    } else {
        self.cardNumContainerTopConstraint.offset(0);
    }
    
    [self invalidateIntrinsicContentSize];
}

- (BOOL)p_isCardNumContainerHeadShow {
    return [self.cardTipView isShowContent] ||
    ([self.recommendBankView isTipsShow] && self.recommendBankView.hidden == NO);
}

#pragma mark - CJPayCustomTextFieldContainerDelegate
- (void)textFieldBeginEdit:(CJPayCustomTextFieldContainer *)textContainer {
    if (textContainer == self.cardNumContainer) {
        if (!Check_ValidString(textContainer.textField.userInputContent)) {
            [self.cardNumContainer showBorder:YES withColor:[UIColor cj_161823WithAlpha:0.12]];
        }
        if (self.curShowType == CJPayBindCardNumberViewShowTypeOriginal ||
            self.curShowType == CJPayBindCardNumberViewShowTypeShowRecommendBank ||
            self.curShowType == CJPayBindCardNumberViewShowTypeOriginalShowBankCardVoucher) {
            [self changeShowTypeTo:CJPayBindCardNumberViewShowTypeCardInputFocus];
        }
        [self showOCRButton:[textContainer.textField.text isEqualToString:@""]];
    } else if (textContainer == self.phoneContainer) {
        [self updatePhoneTips:CJPayLocalizedStr(@"银行预留手机号")];
        [self.phoneContainer showBorder:YES withColor:[UIColor cj_161823WithAlpha:0.12]];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldBeginEdit:)]) {
        [self.delegate textFieldBeginEdit:textContainer];
    }
}

- (void)textFieldContentChange:(NSString *)curText textContainer:(CJPayCustomTextFieldContainer *)textContainer {
    // 从键盘删除输入内容时走这里的逻辑
    if (textContainer == self.cardNumContainer) {
        [self showOCRButton:[textContainer.textField.text isEqualToString:@""]];
        if (!Check_ValidString(textContainer.textField.userInputContent)) {
            if ([self.recommendBankView isTipsShow]) {
                [self p_showRecommentBankView];
            }
            [self.cardNumContainer showBorder:YES withColor:[UIColor cj_161823WithAlpha:0.12]];
        }
    } else if (textContainer == self.phoneContainer) {
        if (!Check_ValidString(textContainer.textField.userInputContent)) {
            [self updatePhoneTips:CJPayLocalizedStr(@"银行预留手机号")];
            [self.phoneContainer showBorder:YES withColor:[UIColor cj_161823WithAlpha:0.12]];
        }
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldContentChange:textContainer:)]) {
        [self.delegate textFieldContentChange:curText textContainer:textContainer];
    }
    
    [self p_updateCardNumConstraint];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textField:shouldChangeCharactersInRange:replacementString:)]) {
        return [self.delegate textField:textField shouldChangeCharactersInRange:range replacementString:string];
    }
    return YES;
}

- (void)textFieldEndEdit:(CJPayCustomTextFieldContainer *)textContainer {
    if (textContainer == self.cardNumContainer) {
        [self showOCRButton:YES];
        if (!Check_ValidString(self.cardNumContainer.textField.userInputContent)) {
            if ([self.recommendBankView isTipsShow] && self.cardTipView.hidden == YES) {
                [self p_showRecommentBankView];
            }
        }
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldEndEdit:)]) {
        [self.delegate textFieldEndEdit:textContainer];
    }
    
    [self p_updateCardNumConstraint];
}

- (void)textFieldWillClear:(CJPayCustomTextFieldContainer *)textContainer {
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldWillClear:)]) {
        [self.delegate textFieldWillClear:textContainer];
    }
}

- (void)textFieldDidClear:(CJPayCustomTextFieldContainer *)textContainer {
    // 从输入框中的删除快捷一次性全部删除输入内容时走这里的逻辑
    if (textContainer == self.cardNumContainer) {
        [self showOCRButton:YES];
        [self.cardNumContainer showBorder:YES withColor:[UIColor cj_161823WithAlpha:0.12]];
        if ([self.recommendBankView isTipsShow]) {
            [self p_showRecommentBankView];
        }
    } else if (textContainer == self.phoneContainer) {
        [self updatePhoneTips:CJPayLocalizedStr(@"银行预留手机号")];
        [self.phoneContainer showBorder:YES withColor:[UIColor cj_161823WithAlpha:0.12]];
    }
        
    if (self.delegate && [self.delegate respondsToSelector:@selector(textFieldDidClear:)]) {
        [self.delegate textFieldDidClear:textContainer];
    }
    
    [self p_updateCardNumConstraint];
}

- (CGSize)intrinsicContentSize {
    CGSize size = CGSizeZero;
    CGFloat viewWidth = self.cj_responseViewController.view.cj_width;
    switch (self.curShowType) {
        case CJPayBindCardNumberViewShowTypeOriginal:
            size = CGSizeMake(viewWidth, 120);
            break;
        case CJPayBindCardNumberViewShowTypeShowRecommendBank:
        case CJPayBindCardNumberViewShowTypeOriginalShowBankCardVoucher:
            size = CGSizeMake(viewWidth, 140);
            break;
        case CJPayBindCardNumberViewShowTypeCardInputFocus:
        case CJPayBindCardNumberViewShowTypeOriginalNoAuth:
            if ([self p_isCardNumContainerHeadShow]) {
                size = CGSizeMake(viewWidth, 216);
            } else {
                size = CGSizeMake(viewWidth, 196);
            }
            break;
        case CJPayBindCardNumberViewShowTypeShowPhoneInput:
        case CJPayBindCardNumberViewShowTypeShowPhoneAuth:
            if ([self p_isCardNumContainerHeadShow]) {
                size = CGSizeMake(viewWidth, 305);
            } else {
                size = CGSizeMake(viewWidth, 285);
            }
            break;
        default:
            break;
    }
    return size;
}

@end
