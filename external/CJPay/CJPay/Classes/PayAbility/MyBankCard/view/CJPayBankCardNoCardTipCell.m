//
//  CJPayBankCardNoCardTipCell.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/23.
//

#import "CJPayBankCardNoCardTipCell.h"
#import "CJPayUIMacro.h"
#import "UIView+CJTheme.h"

@interface CJPayBankCardNoCardTipCell()

@property (nonatomic, strong) UILabel *firstTipLabel;

@end

@implementation CJPayBankCardNoCardTipCell

- (void)setupUI {
    [super setupUI];
    [self.containerView addSubview:self.firstTipLabel];
    
    CJPayMasMaker(self.firstTipLabel, {
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
        make.top.equalTo(self.containerView).offset(16);
        make.bottom.lessThanOrEqualTo(self.containerView);
    });
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        _firstTipLabel.textColor = localTheme.subtitleColor;
    }
}

- (UILabel *)firstTipLabel {
    if (!_firstTipLabel) {
        _firstTipLabel = [[UILabel alloc] init];
        _firstTipLabel.font = [UIFont cj_fontOfSize:15];
        _firstTipLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].subtitleColor;
        _firstTipLabel.numberOfLines = 0;
        _firstTipLabel.text = CJPayLocalizedStr(@"首次绑定银行卡时即完成实名认证，后续只能绑定同一自然人的银行卡。");
    }
    return _firstTipLabel;
}


@end
