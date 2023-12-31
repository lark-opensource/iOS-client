//
//  CJPayQuickBindCardFooterView.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/28.
//

#import "CJPayQuickBindCardFooterView.h"
#import "CJPayUIMacro.h"
#import "CJPayAccountInsuranceTipView.h"

@interface CJPayQuickBindCardFooterView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;

@end

@implementation CJPayQuickBindCardFooterView

- (void)setupUI {
    [super setupUI];
    
    [self.containerView addSubview:self.titleLabel];
    [self.containerView addSubview:self.safeGuardTipView];
    
    CJPayMasMaker(self.titleLabel, {
        make.centerX.equalTo(self.containerView);
        make.height.mas_equalTo(18);
        make.top.equalTo(self.containerView).offset(24);
    });
    CJPayMasMaker(self.safeGuardTipView, {
        make.center.width.equalTo(self.titleLabel);
        make.height.mas_equalTo(18);
    });
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontOfSize:13];
        _titleLabel.textColor = [UIColor cj_cacacaff];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = CJPayLocalizedStr(@"本服务由合众易宝提供");
    }
    return _titleLabel;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
        _safeGuardTipView.hidden = YES;
    }
    return _safeGuardTipView;
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];

    if ([CJPayAccountInsuranceTipView shouldShow]) {
        self.titleLabel.hidden = YES;
        self.safeGuardTipView.hidden = NO;
    } else {
        self.titleLabel.hidden = NO;
        self.safeGuardTipView.hidden = YES;
    }
}

@end
