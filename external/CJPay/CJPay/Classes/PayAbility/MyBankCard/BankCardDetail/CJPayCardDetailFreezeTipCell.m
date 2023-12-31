//
//  CJPayCardDetailFreezeTipCell.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/20.
//

#import "CJPayCardDetailFreezeTipCell.h"
#import "CJPayUIMacro.h"
#import "CJPayCardDetailFreezeTipViewModel.h"
#import "UITapGestureRecognizer+CJPay.h"
#import "UIView+CJTheme.h"

NSString * const CJPayBankCardDetailCancelBindEvent =  @"CJPayBankCardDetailCancelBindEvent";

@interface CJPayCardDetailFreezeTipCell()

@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) UILabel *tipsLabel;
@property (nonatomic,strong) UILabel *unbindLabel;
@property (nonatomic,strong) UIView  *labelView;
@property (nonatomic,strong) UIImageView *arrowImageView;

@end

@implementation CJPayCardDetailFreezeTipCell

- (void)setupUI {
    [super setupUI];
    [self.containerView addSubview:self.titleLabel];
    [self.labelView addSubview:self.tipsLabel];
    [self.labelView addSubview:self.unbindLabel];
    [self.labelView addSubview:self.arrowImageView];
    [self.containerView addSubview:self.labelView];
    
    CJPayMasMaker(self.titleLabel, {
        make.left.equalTo(self.containerView).offset(16);
        make.top.equalTo(self.containerView).offset(20);
        make.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.labelView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(13);
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
        make.height.mas_equalTo(50);
    });
    
    CJPayMasMaker(self.tipsLabel, {
        make.left.top.equalTo(self.labelView);
    });

    CJPayMasMaker(self.unbindLabel, {
        make.top.equalTo(self.labelView);
        make.left.equalTo(self.tipsLabel.mas_right).offset(5);
    });

    CJPayMasMaker(self.arrowImageView, {
        make.centerY.equalTo(self.unbindLabel);
        make.left.equalTo(self.unbindLabel.mas_right);
        make.height.width.mas_equalTo(12);
    });

    self.containerView.backgroundColor = [CJPayLocalThemeStyle defaultThemeStyle].mainBackgroundColor;//支持多主题
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        self.containerView.backgroundColor = localTheme.mainBackgroundColor;
        [_arrowImageView cj_setImage:localTheme.unbindCardArrowImageName];
        _arrowImageView.backgroundColor = localTheme.unbindCardTextColor;
        _titleLabel.textColor = localTheme.subtitleColor;
        _tipsLabel.textColor = localTheme.subtitleColor;
        _unbindLabel.textColor = localTheme.unbindCardTextColor;
    }
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    CJPayCardDetailFreezeTipViewModel *tipViewModel = (CJPayCardDetailFreezeTipViewModel *)viewModel;
    
    if (tipViewModel) {
        self.tipsLabel.text = CJString(tipViewModel.freezeReason);
        self.unbindLabel.text = CJPayLocalizedStr(@"解绑银行卡");
        CGFloat viewWidth = [tipViewModel.freezeReason cj_sizeWithFont:[UIFont cj_fontOfSize:15] maxSize:CGSizeMake(MAXFLOAT, 21)].width
        + [self.unbindLabel.text cj_sizeWithFont:[UIFont cj_fontOfSize:15] maxSize:CGSizeMake(MAXFLOAT, 21)].width + 5 + 12;
        if (viewWidth > (CJ_SCREEN_WIDTH - 32)) {
            CJPayMasReMaker(self.tipsLabel, {
                make.left.top.equalTo(self.labelView);
            });
    
            CJPayMasReMaker(self.unbindLabel, {
                make.top.equalTo(self.tipsLabel.mas_bottom).offset(5);
                make.left.equalTo(self.labelView);
            });
    
            CJPayMasReMaker(self.arrowImageView, {
                make.centerY.equalTo(self.unbindLabel);
                make.left.equalTo(self.unbindLabel.mas_right);
                make.height.width.mas_equalTo(12);
            });
        }
    }
}

- (void)tipsLabelTapped {
    CJPayCardDetailFreezeTipViewModel *tipViewModel = (CJPayCardDetailFreezeTipViewModel *)self.viewModel;
    if (tipViewModel) {
        [self.eventHandler handleWithEventName:CJPayBankCardDetailCancelBindEvent data:nil];
    }
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont cj_semiboldFontOfSize:15];
        _titleLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].subtitleColor;
        _titleLabel.text = [NSString stringWithFormat:@"%@%@", CJPayLocalizedStr(@"提示"), @":" ];
    }
    return _titleLabel;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [[UILabel alloc] init];
        _tipsLabel.font = [UIFont cj_fontOfSize:15];
        _tipsLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].subtitleColor;
        _tipsLabel.numberOfLines = 0;
    }
    return _tipsLabel;
}

- (UILabel *)unbindLabel {
    if (!_unbindLabel) {
        _unbindLabel = [[UILabel alloc] init];
        _unbindLabel.userInteractionEnabled = YES;
        _unbindLabel.numberOfLines = 0;
        _unbindLabel.font = [UIFont cj_fontOfSize:15];
        _unbindLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].unbindCardTextColor;
        
        [_unbindLabel cj_viewAddTarget:self
                                action:@selector(tipsLabelTapped)
                      forControlEvents:UIControlEventTouchUpInside];
    }
    return _unbindLabel;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [[UIImageView alloc] init];
        [_arrowImageView cj_setImage:[CJPayLocalThemeStyle defaultThemeStyle].unbindCardArrowImageName ];
    }
    return _arrowImageView;
}

- (UIView *)labelView {
    if (!_labelView){
        _labelView = [[UIView alloc] init];
        _labelView.userInteractionEnabled = YES;
    }
    return _labelView;
}

@end
