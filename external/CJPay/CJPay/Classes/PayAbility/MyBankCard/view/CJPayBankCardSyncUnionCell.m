//
//  CJPayBankCardSyncUnionCell.m
//  CJPay-5b542da5
//
//  Created by chenbocheng on 2022/9/1.
//

#import "CJPayBankCardSyncUnionCell.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPaySyncUnionViewModel.h"
#import "UIView+CJTheme.h"

@interface CJPayBankCardSyncUnionCell ()

@property (nonatomic, strong) UIImageView *douyinIcon;
@property (nonatomic, strong) UILabel *douyinLabel;
@property (nonatomic, strong) UIView *divideView;
@property (nonatomic, strong) UIImageView *unionIcon;
@property (nonatomic, strong) UILabel *unionLabel;
@property (nonatomic, strong) UILabel *tipsLabel;
@property (nonatomic, strong) CJPayStyleButton *syncButton;
@property (nonatomic, strong) UIView *detailView;

@property (nonatomic, copy) void(^didClickBlock)(void);

@end

@implementation CJPayBankCardSyncUnionCell

- (void)setupUI {
    [super setupUI];
    
    [self.detailView addSubview:self.douyinIcon];
    [self.detailView addSubview:self.douyinLabel];
    [self.detailView addSubview:self.divideView];
    [self.detailView addSubview:self.unionIcon];
    [self.detailView addSubview:self.unionLabel];
    [self.detailView addSubview:self.tipsLabel];
    [self.detailView addSubview:self.syncButton];
    
    [self addSubview:self.detailView];
    
    CJPayMasMaker(self.detailView, {
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.top.equalTo(self).offset(20);
        make.bottom.equalTo(self);
    });
    
    CJPayMasMaker(self.douyinIcon, {
        make.left.equalTo(self.detailView).offset(20);
        make.top.equalTo(self.detailView).offset(16);
        make.size.mas_equalTo(CGSizeMake(20, 20));
    });
    
    CJPayMasMaker(self.douyinLabel, {
        make.left.equalTo(self.douyinIcon.mas_right).offset(4);
        make.centerY.equalTo(self.douyinIcon);
    });
    
    CJPayMasMaker(self.divideView, {
        make.left.equalTo(self.douyinLabel.mas_right).offset(10);
        make.centerY.equalTo(self.douyinLabel);
        make.size.mas_equalTo(CGSizeMake(0.5, 13.5));
    });
    
    CJPayMasMaker(self.unionIcon, {
        make.left.equalTo(self.divideView.mas_right).offset(10);
        make.centerY.equalTo(self.divideView);
        make.size.mas_equalTo(CGSizeMake(20, 20));
    });
    
    CJPayMasMaker(self.unionLabel, {
        make.left.equalTo(self.unionIcon.mas_right).offset(4);
        make.centerY.equalTo(self.unionIcon);
    });
    
    CJPayMasMaker(self.tipsLabel, {
        make.top.equalTo(self.douyinLabel.mas_bottom).offset(8);
        make.left.equalTo(self.detailView).offset(20);
        make.right.lessThanOrEqualTo(self.syncButton.mas_left).offset(-20);
    });
    
    CJPayMasMaker(self.syncButton, {
        make.centerY.equalTo(self.detailView);
        make.right.equalTo(self.detailView).offset(-20);
        make.size.mas_equalTo(CGSizeMake(80, 28));
    });
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    if ([viewModel isKindOfClass:[CJPaySyncUnionViewModel class]]) {
        CJPaySyncUnionViewModel *syncUnionViewModel = (CJPaySyncUnionViewModel *)viewModel;
        self.didClickBlock = syncUnionViewModel.didClickBlock;
        [self.douyinIcon cj_setImageWithURL:[NSURL URLWithString:CJString(syncUnionViewModel.bindCardDouyinIconUrl)]];
        [self.unionIcon cj_setImageWithURL:[NSURL URLWithString:CJString(syncUnionViewModel.bindCardUnionIconUrl)]];
    }
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        self.detailView.layer.borderColor = localTheme.bankActivityBorderColor.CGColor;
        self.detailView.backgroundColor = localTheme.addBankBigButtonBackgroundColor;
        self.douyinLabel.textColor = localTheme.addBankButtonTitleColor;
        self.unionLabel.textColor = localTheme.addBankButtonTitleColor;
        self.divideView.backgroundColor = localTheme.syncUnionCellDivideBackgroundColor;
        self.tipsLabel.textColor = localTheme.subtitleColor;
        self.detailView.layer.borderWidth = localTheme.syncUnionCellBorderWidth;
    }
}

#pragma mark - lazy views
- (UIView *)detailView {
    if (!_detailView) {
        _detailView = [UIView new];
        _detailView.layer.cornerRadius = 4;
    }
    return _detailView;
}

- (UIImageView *)douyinIcon {
    if (!_douyinIcon) {
        _douyinIcon = [UIImageView new];
    }
    return _douyinIcon;
}

- (UILabel *)douyinLabel {
    if (!_douyinLabel) {
        _douyinLabel = [UILabel new];
        _douyinLabel.text = CJPayLocalizedStr(@"抖音支付");
        _douyinLabel.font = [UIFont cj_boldFontOfSize:14];
    }
    return _douyinLabel;
}

- (UIView *)divideView {
    if (!_divideView) {
        _divideView = [UIView new];
    }
    return _divideView;
}

- (UIImageView *)unionIcon {
    if (!_unionIcon) {
        _unionIcon = [UIImageView new];
    }
    return _unionIcon;
}

- (UILabel *)unionLabel {
    if (!_unionLabel) {
        _unionLabel = [UILabel new];
        _unionLabel.text = CJPayLocalizedStr(@"云闪付");
        _unionLabel.font = [UIFont cj_boldFontOfSize:14];
    }
    return _unionLabel;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [UILabel new];
        _tipsLabel.text = CJPayLocalizedStr(@"支持同步银联云闪付已绑卡至抖音支付");
        _tipsLabel.font = [UIFont cj_fontOfSize:12];
        _tipsLabel.numberOfLines = 0;
    }
    return _tipsLabel;
}

- (CJPayStyleButton *) syncButton {
    if (!_syncButton) {
        _syncButton = [CJPayStyleButton new];
        [_syncButton setTitle:CJPayLocalizedStr(@"去同步") forState:UIControlStateNormal];
        _syncButton.titleLabel.font = [UIFont cj_boldFontOfSize:13];
        _syncButton.cjEventInterval = 2;
        @CJWeakify(self)
        [_syncButton btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.didClickBlock);
        }];
    }
    return _syncButton;
}

@end
