//
//  CJPayLoginBillStatusView.m
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/7/3.
//

#import "CJPayLoginBillStatusView.h"
#import "CJPayQueryPayOrderInfoRequest.h"

#import "CJPayUIMacro.h"

@interface CJPayLoginBillStatusView ()

@property (nonatomic, strong) UIImageView *statusIcon;
@property (nonatomic, strong) UILabel *tipLabel;

@end

@implementation CJPayLoginBillStatusView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

#pragma mark - public func

- (void)showStatus:(CJPayLoginOrderStatus)loginOrderStatus msg:(nullable NSString *)msg{
    if (loginOrderStatus == CJPayLoginOrderStatusError) {
        [self.statusIcon cj_setImage:@"cj_sorry_icon"];
        self.tipLabel.text = @"网络错误，请返回重试";
    } else if (loginOrderStatus == CJPayLoginOrderStatusProcess) {
        [self.statusIcon cj_setImage:@"cj_new_pay_processing_icon"];
        self.tipLabel.text = @"加载中...";
    } else {
        [self.statusIcon cj_setImage:@"cj_pay_outer_pay_login_warning_img"];
        self.tipLabel.text = CJString(msg);
    }
}

#pragma mark - private func

- (void)p_setupUI {
    [self addSubview:self.statusIcon];
    [self addSubview:self.tipLabel];
    
    CJPayMasMaker(self.statusIcon, {
        make.top.mas_equalTo(self).mas_offset(30);
        make.centerX.mas_equalTo(self);
        make.height.width.mas_equalTo(64);
    });
    
    CJPayMasMaker(self.tipLabel, {
        make.top.mas_equalTo(self.statusIcon.mas_bottom).mas_offset(24);
        make.centerX.mas_equalTo(self);
    });
}

#pragma mark - lazy load

- (UIImageView *)statusIcon {
    if (!_statusIcon) {
        _statusIcon = [UIImageView new];
    }
    return _statusIcon;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [UILabel new];
    }
    return _tipLabel;
}

@end
