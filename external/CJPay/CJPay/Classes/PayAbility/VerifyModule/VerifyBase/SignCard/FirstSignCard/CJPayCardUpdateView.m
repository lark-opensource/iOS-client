//
//  CJPayCardUpdateView.m
//  CJPay
//
//  Created by wangxiaohong on 2020/3/30.
//

#import "CJPayCardUpdateView.h"

#import "CJPayBindCardContainerView.h"
#import "CJPayCustomTextFieldContainer.h"
#import "CJPayBindCardProtocolView.h"
#import "CJPayStyleButton.h"
#import "CJPayCardUpdateModel.h"
#import "CJPayQuickPayChannelModel.h"
#import "CJPayUIMacro.h"


@interface CJPayCardUpdateView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) CJPayBindCardContainerView *bankCardView;
@property (nonatomic, strong) CJPayCustomTextFieldContainer *phoneContainer;
@property (nonatomic, strong) CJPayBindCardProtocolView *protocolView;
@property (nonatomic, strong) CJPayStyleButton *nextStepButton;
@property (nonatomic, strong) MASConstraint *nextStepButtonBasePhoneContainerConstraint;
@property (nonatomic, strong) MASConstraint *nextStepButtonBaseProtocolViewConstraint;

@end

@implementation CJPayCardUpdateView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)updateWithBDPayCardUpdateModel:(CJPayCardUpdateModel *)model
{
    NSString *cardTailStr = @"";
    if (model.cardModel.cardNoMask.length >= 4) {
        cardTailStr = [model.cardModel.cardNoMask substringFromIndex:model.cardModel.cardNoMask.length - 4];
    }
    NSString *cardTotalName = [NSString stringWithFormat:@"%@%@(%@)", model.cardModel.frontBankCodeName, CJPayLocalizedStr(model.cardModel.cardTypeName), cardTailStr];
    [self.bankCardView updateWithMainStr:cardTotalName subStr:CJPayLocalizedStr(@"卡类型")];
    if(model.agreements.count == 0){
        [self p_updateUI];
    }else{
        [self.protocolView updateWithAgreements:model.agreements isNeedAgree:YES];
    }
    
    NSDictionary *weakAttributes = @{
        NSFontAttributeName : [UIFont cj_fontOfSize:13],
        NSForegroundColorAttributeName : [UIColor cj_999999ff]
    };
    
    NSDictionary *mainAttributes = @{
        NSFontAttributeName : [UIFont cj_fontOfSize:13],
        NSForegroundColorAttributeName : [UIColor cj_222222ff]
    };
    NSMutableAttributedString *subAtributeStr = [[NSMutableAttributedString alloc] initWithString:CJPayLocalizedStr(@"请更新") attributes:weakAttributes];
    NSString *name = [NSString stringWithFormat:@" %@ ", model.cardModel.trueNameMask];
    [subAtributeStr appendAttributedString:[[NSAttributedString alloc] initWithString:CJString(name) attributes:mainAttributes]];
    [subAtributeStr appendAttributedString:[[NSAttributedString alloc] initWithString:CJPayLocalizedStr(@"名下银行卡信息") attributes:weakAttributes]];
    
    self.subTitleLabel.attributedText = subAtributeStr;
}

- (void)p_setupUI
{
    [self addSubview:self.titleLabel];
    [self addSubview:self.subTitleLabel];
    [self addSubview:self.bankCardView];
    [self addSubview:self.phoneContainer];
    [self addSubview:self.protocolView];
    [self addSubview:self.nextStepButton];
     
    CJPayMasMaker(self.titleLabel, {
        make.top.left.equalTo(self).offset(24);
    });
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.equalTo(self.titleLabel);
    });
    
    CJPayMasMaker(self.bankCardView, {
        make.top.equalTo(self.subTitleLabel.mas_bottom).offset(16);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(69);
    });
    
    CJPayMasMaker(self.phoneContainer, {
        make.top.equalTo(self.bankCardView.mas_bottom);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(69);
    });
    
    CJPayMasMaker(self.protocolView, {
        make.top.equalTo(self.phoneContainer.mas_bottom);
        make.left.right.equalTo(self);
    });
    
    CJPayMasMaker(self.nextStepButton, {
        _nextStepButtonBaseProtocolViewConstraint = make.top.equalTo(self.protocolView.mas_bottom).offset(20);
        _nextStepButtonBasePhoneContainerConstraint = make.top.equalTo(self.phoneContainer.mas_bottom).offset(20);
        make.left.equalTo(self.titleLabel);
        make.right.equalTo(self).offset(-24);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
    });
    [_nextStepButtonBasePhoneContainerConstraint deactivate];
}

- (void)p_updateUI
{
    self.protocolView.hidden = YES;
    [_nextStepButtonBaseProtocolViewConstraint deactivate];
    [_nextStepButtonBasePhoneContainerConstraint activate];
}


- (void)p_nextButtonClick
{
    if (self.protocolView.isSelected) {
        [self endEditing:YES];
        CJ_CALL_BLOCK(self.confirmBlock);
    } else {
        [self.protocolView gotoProtocolDetail:NO
                           showContinueButton:!self.protocolView.isSelected];
    }
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textColor = [UIColor cj_222222ff];
        _titleLabel.font = [UIFont cj_boldFontOfSize:24];
        _titleLabel.text = CJPayLocalizedStr(@"更新卡信息");
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel
{
    if (!_subTitleLabel) {
        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.font = [UIFont cj_fontOfSize:13];
    }
    return _subTitleLabel;
}

- (CJPayBindCardContainerView *)bankCardView {
    if (!_bankCardView) {
        _bankCardView = [[CJPayBindCardContainerView alloc] init];
        _bankCardView.isClickStyle = NO;
    }
    return _bankCardView;
}

- (CJPayCustomTextFieldContainer *)phoneContainer {
    if (!_phoneContainer) {
        _phoneContainer = [[CJPayCustomTextFieldContainer alloc] initWithFrame:CGRectZero textFieldType:CJPayTextFieldTypePhone];
        _phoneContainer.placeHolderText = CJPayLocalizedStr(@"请输入正确的银行预留手机号");
        _phoneContainer.subTitleText = CJPayLocalizedStr(@"请输入正确的银行预留手机号");
        _phoneContainer.keyBoardType = CJPayKeyBoardTypeCustomNumOnly;
    }
    return _phoneContainer;
}

- (CJPayBindCardProtocolView *)protocolView {
    if (!_protocolView) {
        _protocolView = [[CJPayBindCardProtocolView alloc] init];
        _protocolView.clipsToBounds = YES;
        _protocolView.isSelected = YES;
    }
    return _protocolView;
}

- (CJPayStyleButton *)nextStepButton {
    if (!_nextStepButton) {
        _nextStepButton = [[CJPayStyleButton alloc] init];
        [_nextStepButton setTitleColor:[UIColor cj_colorWithHexString:@"ffffff"] forState:UIControlStateNormal];
        [_nextStepButton setTitle:CJPayLocalizedStr(@"继续支付") forState:UIControlStateNormal];
        _nextStepButton.layer.cornerRadius = 5;
        _nextStepButton.layer.masksToBounds = YES;
        _nextStepButton.cjEventInterval = 2;
        [_nextStepButton addTarget:self action:@selector(p_nextButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _nextStepButton.enabled = NO;
    }
    return _nextStepButton;
}

@end
