//
//  CJPayLoginbillView.m
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/3.
//

#import "CJPayLoginBillView.h"
#import "CJPayLoginBillStatusView.h"
#import "CJPayLoginBillDetailView.h"
#import "UIView+CJPay.h"
#import "CJPayQueryPayOrderInfoRequest.h"

#import "CJPayUIMacro.h"

@interface CJPayLoginBillView ()

@property (nonatomic, strong) UIImageView *headerView;
@property (nonatomic, strong) UILabel *headerLabel;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) CJPayLoginBillStatusView *statusView;
@property (nonatomic, strong) CJPayLoginBillDetailView *marketView;

@end

@implementation CJPayLoginBillView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.headerView];
    [self.headerView addSubview:self.headerLabel];
    [self addSubview:self.contentView];
    [self.contentView addSubview:self.statusView];
    [self.contentView addSubview:self.marketView];
    
    self.marketView.hidden = YES;
}

- (void)setupConstraints {
    CJPayMasMaker(self.headerView, {
        make.top.mas_equalTo(self).mas_offset(18);
        make.left.mas_equalTo(self).mas_offset(16);
        make.right.mas_equalTo(self).mas_offset(-16);
        make.height.mas_equalTo(72);
    });
    
    CJPayMasMaker(self.headerLabel, {
        make.center.mas_equalTo(self.headerView);
    });
    
    CJPayMasMaker(self.contentView, {
        make.top.mas_equalTo(self.headerView.mas_bottom);
        make.left.mas_equalTo(self).mas_equalTo(24);
        make.right.mas_equalTo(self).mas_equalTo(-24);
        make.height.mas_equalTo(221);
    });
    
    CJPayMasMaker(self.statusView, {
        make.edges.mas_equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.marketView, {
        make.edges.mas_equalTo(self.contentView);
    });
}

- (void)updateLoginBillViewWithResponse:(CJPayQueryPayOrderInfoResponse *)response {
    CJPayLoginOrderStatus resultStatus = response ? [response resultStatus] : CJPayLoginOrderStatusError;
    
    if (resultStatus == CJPayLoginOrderStatusSuccess) {
        self.statusView.hidden = YES;
        self.marketView.hidden = NO;
        NSDecimalNumber *tradeNumber = [NSDecimalNumber decimalNumberWithString:response.tradeInfo.tradeAmount];
        CGFloat tradeFloat;
        NSString *tradeAmount;
         if ([tradeNumber compare:[NSDecimalNumber zero]] == NSOrderedSame || [[NSDecimalNumber notANumber] isEqualToNumber:tradeNumber]) {
             [self showStatus:CJPayLoginOrderStatusError msg:nil];
             CJPayLogInfo(@"金额错误 tradeInfo.tradeAmount");
             return;
         } else {
             tradeFloat = [[tradeNumber decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100"]] floatValue] ;
             tradeAmount = [NSString stringWithFormat:@"%.2f",tradeFloat];
         }
        [self.marketView updateLoginBillDetail:tradeAmount merchantName:response.merchantInfo.merchantName];
        
    } else if (resultStatus == CJPayLoginOrderStatusWarning) {
        self.statusView.hidden = NO;
        self.marketView.hidden = YES;
        [self showStatus:CJPayLoginOrderStatusWarning msg:response.msg];
    } else if (resultStatus == CJPayLoginOrderStatusProcess) {
        self.marketView.hidden = YES;
        [self showStatus:CJPayLoginOrderStatusProcess msg:nil];
    } else {
        self.statusView.hidden = NO;
        self.marketView.hidden = YES;
        [self showStatus:CJPayLoginOrderStatusError msg:nil];
    }
}

- (void)showStatus:(CJPayLoginOrderStatus)loginOrderStatus msg:(nullable NSString *)msg {
    [self.statusView showStatus:loginOrderStatus msg:msg];
}

#pragma mark - lazy load

- (UIImageView *)headerView {
    if (!_headerView) {
        _headerView = [[UIImageView alloc] init];
        [_headerView cj_setImage:@"cj_pay_outer_pay_login_pay_info_top"];
    }
    return _headerView;
}

- (UILabel *)headerLabel {
    if (!_headerLabel) {
        _headerLabel = [[UILabel alloc] init];
        _headerLabel.font = [UIFont cj_fontOfSize:17];
        _headerLabel.textColor = [UIColor cj_161823ff];
        _headerLabel.text = CJPayLocalizedStr(@"待支付订单");
    }
    return _headerLabel;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        _contentView.backgroundColor = [UIColor cj_colorWithHexString:@"#FFFFFF"];
    }
    return _contentView;
}

- (CJPayLoginBillStatusView *)statusView {
    if (!_statusView) {
        _statusView = [[CJPayLoginBillStatusView alloc] init];
    }
    return _statusView;
}

- (CJPayLoginBillDetailView *)marketView {
    if (!_marketView) {
        _marketView = [[CJPayLoginBillDetailView alloc] init];
    }
    return _marketView;
}

@end
