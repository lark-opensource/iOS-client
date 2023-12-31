//
//  CJPaySuperPayResultView.m
//  Pods
//
//  Created by 易培淮 on 2022/4/20.
//

#import "CJPaySuperPayResultView.h"
#import "CJPayUIMacro.h"
#import "CJPaySuperPayQueryRequest.h"

@interface CJPaySuperPayResultView ()

@property (nonatomic, strong) UIImageView *logoImageView;

@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIView *showView;

@property (nonatomic, strong) UILabel *subTitleLabel;

@property (nonatomic, strong) CJPayPaymentInfoModel *paymentInfo;

@end



@implementation CJPaySuperPayResultView

- (instancetype)initWithTitle:(NSString *)title subTitle:(NSString *)subTitle {
    self = [super init];
    if (self) {
        self.titleLabel.text = title;
        self.subTitleLabel.text = subTitle;
        [self p_setupUI];
    }
    return self;
}

- (instancetype)initWithModel:(CJPayPaymentInfoModel *)paymentInfo {
    self = [super init];
    if (self) {
        _paymentInfo = paymentInfo;
        [self p_setupUI];
        [self p_setTitle];
    }
    return self;
}

#pragma mark - Private Method

- (void)p_setupUI {
    [self addSubview:self.logoImageView];
    CJPayMasMaker(self.logoImageView, {
        make.centerX.equalTo(self);
        make.top.equalTo(self).offset(24);
        make.height.width.mas_equalTo(32);
    });
    
    [self addSubview:self.titleLabel];
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.logoImageView.mas_bottom).offset(8);
        make.centerX.equalTo(self);
        make.height.mas_equalTo(18);
    });
    
    [self addSubview:self.subTitleLabel];
    CJPayMasMaker(self.subTitleLabel, {
       make.top.equalTo(self.titleLabel.mas_bottom).offset(6);
       make.centerX.equalTo(self);
       make.height.mas_equalTo(15);
       make.bottom.equalTo(self).offset(-19);
    });
}

- (void)p_setTitle {
    NSString *amountStr = [NSString stringWithFormat:@"%.2f", self.paymentInfo.deductAmount/(double)100];
    
    NSString *title = CJPayLocalizedStr(@"付款成功 ¥");
    title = [title stringByAppendingString:amountStr];
    NSString *subTitle = [NSString stringWithFormat:@"%@", CJString(self.paymentInfo.channelName)];;
    if ([self.paymentInfo.deductType isEqualToString:@"bankcard"] && Check_ValidString(self.paymentInfo.cardMaskCode)) {
        subTitle = [subTitle stringByAppendingString:[NSString stringWithFormat:@" (%@)", CJString(self.paymentInfo.cardMaskCode)]];
    }
    
    self.titleLabel.text = title;
    self.subTitleLabel.text = [self p_shortHandWithBankName:subTitle];
    [self.logoImageView cj_setImage:@"cj_superpay_success"];
}

- (NSString *)p_shortHandWithBankName:(NSString *)text {
    NSString *shortName = text;
    if(text.length > 15) {
        NSRange range = NSMakeRange(4, text.length - 14);//银行卡名前4后3，加尾号6，加空格1 = 14
        shortName = [text stringByReplacingCharactersInRange:range withString:@"..."];
    }
    return shortName;
}

#pragma mark - Getter

- (UIImageView *)logoImageView
{
    if (!_logoImageView) {
        _logoImageView = [UIImageView new];
        [_logoImageView cj_setImage:@"cj_super_pay_result_icon"];
    }
    return _logoImageView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.textColor = [UIColor whiteColor];
        _titleLabel.font = [UIFont cj_fontOfSize:13];
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel
{
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.textAlignment = NSTextAlignmentCenter;
        _subTitleLabel.textColor = [UIColor cj_ffffffWithAlpha:0.6];
        _subTitleLabel.font = [UIFont cj_fontOfSize:11];
        _subTitleLabel.numberOfLines = 0;
    }
    return _subTitleLabel;
}

@end
