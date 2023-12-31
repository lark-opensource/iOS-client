//
// Created by 张海阳 on 2020/3/11.
//

#import "CJPayRechargeResultMainView.h"
#import "CJPayUIMacro.h"
#import <BDWebImage/BDWebImage.h>
#import "CJPayBDTradeInfo.h"
#import "CJPayBDTradeInfo+Biz.h"
#import "UIView+CJTheme.h"

@interface CJPayRechargeResultMainView ()

@property (nonatomic, strong) UIImageView *stateImageView;
@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, strong) UILabel *unitLabel;
@property (nonatomic, strong) UILabel *fundLabel;
@property (nonatomic, strong) UILabel *reasonLabel;

@property (nonatomic, strong) CJPayBDTradeInfo *tradeInfo;
 
@end


@implementation CJPayRechargeResultMainView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI
{
    [self addSubview:self.stateImageView];
    [self addSubview:self.stateLabel];
    [self addSubview:self.unitLabel];
    [self addSubview:self.fundLabel];
    [self addSubview:self.reasonLabel];
    
    [self p_makeConstraints];
}

- (void)p_makeConstraints {
    
    CJPayMasMaker(self.stateImageView, {
        make.top.equalTo(self).offset(20);
        make.centerX.equalTo(self);
        make.width.height.mas_equalTo(40);
    });
    
    CJPayMasMaker(self.stateLabel, {
        make.left.equalTo(self).offset(15);
        make.right.equalTo(self).offset(-15);
        make.top.equalTo(self.stateImageView.mas_bottom).offset(13);
    });
    
    CJPayMasMaker(self.reasonLabel, {
        make.left.equalTo(self).offset(44);
        make.right.equalTo(self).offset(-44);
        make.top.equalTo(self.stateLabel.mas_bottom).offset(12);
    });
    
    CJPayMasMaker(self.fundLabel, {
        make.top.equalTo(self.stateLabel.mas_bottom).offset(22);
        make.centerX.equalTo(self).offset(10);
        make.height.mas_equalTo(42);
    });
    
    CJPayMasMaker(self.unitLabel, {
        make.right.equalTo(self.fundLabel.mas_left).offset(-4);
        make.bottom.equalTo(self.fundLabel.mas_bottom).offset(-2);
        make.width.mas_equalTo(CJ_SIZE_FONT_SAFE(28));
        make.height.mas_equalTo(CJ_SIZE_FONT_SAFE(28));
    });
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        
        self.stateLabel.textColor = localTheme.rechargeResultStateTextColorV2;
        self.fundLabel.textColor = localTheme.rechargeLinkTextColor;
        self.unitLabel.textColor = localTheme.rechargeLinkTextColor;
        
        if (self.tradeInfo) {
            CJBDPayWithdrawTradeStatus status = [CJPayBDTradeInfo statusFromString:self.tradeInfo.tradeStatusString];

            if (status == CJBDPayWithdrawTradeStatusSuccess) {
                [self.stateImageView cj_setImage:localTheme.resultSuccessIconName];
            } else if (status == CJBDPayWithdrawTradeStatusProcessing ||
                       status == CJBDPayWithdrawTradeStatusInit ||
                       status == CJBDPayWithdrawTradeStatusReviewing) {
                [self.stateImageView cj_setImage:localTheme.resultProcessIconName];
            } else {
                [self.stateImageView cj_setImage:localTheme.resultFailIconName];
            }
        }
    }
}

- (void)setFund:(NSString *)fund {
    _fund = fund;
    self.fundLabel.text = fund;
}

- (void)updateWithTradeInfo:(CJPayBDTradeInfo *)tradeInfo {
    self.tradeInfo = tradeInfo;
    
    CJBDPayWithdrawTradeStatus status = [CJPayBDTradeInfo statusFromString:tradeInfo.tradeStatusString];
    if (status == CJBDPayWithdrawTradeStatusSuccess) {
        self.stateLabel.text = CJPayLocalizedStr(@"充值成功");
        self.stateLabel.font = [UIFont cj_fontOfSize:16];
    } else if (status == CJBDPayWithdrawTradeStatusProcessing ||
               status == CJBDPayWithdrawTradeStatusInit ||
               status == CJBDPayWithdrawTradeStatusReviewing) {
        self.stateLabel.text = CJPayLocalizedStr(@"处理中，预计2小时内到账");
        self.stateLabel.font = [UIFont cj_fontOfSize:16];
    } else {
        self.stateLabel.text = CJPayLocalizedStr(@"充值失败");
        self.stateLabel.font = [UIFont cj_boldFontOfSize:20];
        self.reasonLabel.hidden = NO;
        self.fundLabel.hidden = self.unitLabel.hidden = YES;
        if (Check_ValidString(self.tradeInfo.failMsg)) {
            [self.reasonLabel setText:self.tradeInfo.failMsg];
        }
    }
}

- (UIImageView *)stateImageView {
    if (!_stateImageView) {
        _stateImageView = [UIImageView new];
    }
    return _stateImageView;
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [UILabel new];
        _stateLabel.textAlignment = NSTextAlignmentCenter;
        _stateLabel.font = [UIFont cj_fontOfSize:16];
    }
    return _stateLabel;
}

- (UILabel *)unitLabel {
    if (!_unitLabel) {
        _unitLabel = [UILabel new];
        _unitLabel.font = [UIFont cj_boldFontOfSize:28];
        _unitLabel.text = @"￥";
    }
    return _unitLabel;
}

- (UILabel *)fundLabel {
    if (!_fundLabel) {
        _fundLabel = [UILabel new];
        _fundLabel.font = [UIFont cj_denoiseBoldFontOfSize:40];
    }
    return _fundLabel;
}

- (UILabel *)reasonLabel {
    if (!_reasonLabel) {
        _reasonLabel = [UILabel new];
        _reasonLabel.font = [UIFont cj_fontOfSize:14];
        [_reasonLabel setTextColor:[UIColor cj_fe3824ff]];
        _reasonLabel.hidden = YES;
        _reasonLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _reasonLabel.textAlignment = NSTextAlignmentCenter;
        _reasonLabel.numberOfLines = 2;
        [_reasonLabel setText:CJPayLocalizedStr(@"充值失败，请联系银行确认银行卡是否异常")];
    }
    return _reasonLabel;
}

@end
