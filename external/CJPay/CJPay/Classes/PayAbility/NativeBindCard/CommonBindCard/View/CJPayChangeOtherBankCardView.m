//
//  CJPayChangeOtherBankCardView.m
//  Pods
//
//  Created by wangxiao on 2022/9/15.
//

#import "CJPayChangeOtherBankCardView.h"
#import "CJPayButton.h"
#import "UIImage+CJPay.h"
#import "UIView+CJPay.h"
#import "CJPayUIMacro.h"

@interface CJPayChangeOtherBankCardView()

@property (strong, nonatomic) CJPayButton *changeOtherBankBtn;

@end

@implementation CJPayChangeOtherBankCardView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self p_setupUI];
    }
    return self;
}

#pragma mark - private
- (void)p_setupUI {
    [self addSubview:self.changeOtherBankBtn];
    CJPayMasReMaker(self.changeOtherBankBtn, {
        make.centerX.top.bottom.equalTo(self);
        make.width.mas_equalTo(187);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
    });
}

- (void)p_didSelected {
    CJ_CALL_BLOCK(self.changeBankCardBtnClick);
}

- (CJPayButton *)changeOtherBankBtn {
    if (!_changeOtherBankBtn) {
        _changeOtherBankBtn = [CJPayButton new];
        [_changeOtherBankBtn setBackgroundColor:[UIColor whiteColor]];
        _changeOtherBankBtn.layer.cornerRadius = 23;
        _changeOtherBankBtn.clipsToBounds = YES;

        UIImage *image = [UIImage cj_imageWithName:@"cj_change_bank_icon"];
        [_changeOtherBankBtn setImage:image forState:UIControlStateNormal];
        [_changeOtherBankBtn setImageEdgeInsets:UIEdgeInsetsMake(0, -3, 0, 3)];

        [_changeOtherBankBtn setTitle:CJPayLocalizedStr(@"更换其他银行卡") forState:UIControlStateNormal];
        [_changeOtherBankBtn setTitleColor:[UIColor cj_161823WithAlpha:1] forState:UIControlStateNormal];
        _changeOtherBankBtn.titleLabel.font = [UIFont cj_boldFontOfSize:14];
        [_changeOtherBankBtn setTitleEdgeInsets:UIEdgeInsetsMake(0, 3, 0, -3)];
        
        [_changeOtherBankBtn addTarget:self action:@selector(p_didSelected) forControlEvents:UIControlEventTouchUpInside];
    }
    return _changeOtherBankBtn;
}

@end
