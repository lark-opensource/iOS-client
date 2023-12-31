//
//  CJWithdrawResultArrivingView.m
//  CJPay
//
//  Created by liyu on 2019/10/12.
//

#import "CJPayWithDrawResultArrivingView.h"
#import "CJPayUIMacro.h"
#import <BDWebImage/BDWebImage.h>
#import "CJPayWithDrawResultMethodView.h"
#import "CJPayLineUtil.h"
#import "UIView+CJTheme.h"

@interface CJPayWithDrawResultArrivingView ()

@property (nonatomic, strong) UILabel *methodTitleLabel;
@property (nonatomic, strong) UILabel *timeTitleLabel;
@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, strong) CJPayWithDrawResultMethodView *methodView;

@property (nonatomic, copy) NSString *methodText;
@end

@implementation CJPayWithDrawResultArrivingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
        
    return self;
}

#pragma mark - Private
- (void)p_setupUI {
    self.clipsToBounds = YES;
    [self addSubview:self.methodTitleLabel];
    [self addSubview:self.timeTitleLabel];
    [self addSubview:self.timeLabel];
    [self addSubview:self.methodView];
    
    CJPayMasMaker(self.methodTitleLabel,{
        make.top.equalTo(self);
        make.left.equalTo(self).offset(16);
    });
    
    CJPayMasMaker(self.timeTitleLabel,{
        make.top.equalTo(self.methodTitleLabel.mas_bottom).offset(14);
        make.bottom.equalTo(self);
        make.left.equalTo(self).offset(16);
    });
    
    CJPayMasMaker(self.timeLabel,{
        make.right.equalTo(self).offset(-16);
        make.left.equalTo(self.timeTitleLabel.mas_right).offset(16);
        make.centerY.equalTo(self.timeTitleLabel);
    });
    
    CJPayMasMaker(self.methodView, {
        make.right.equalTo(self.timeLabel);
        make.centerY.equalTo(self.methodTitleLabel);
        make.left.greaterThanOrEqualTo(self.methodTitleLabel.mas_right).offset(5);
    });
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        
        self.methodTitleLabel.textColor = localTheme.withdrawSubTitleTextColorV2;
        self.timeTitleLabel.textColor = localTheme.withdrawSubTitleTextColorV2;
        self.timeLabel.textColor = localTheme.withdrawAmountTextColor;
        self.methodView.contentLabel.textColor = localTheme.withdrawAmountTextColor;
    }
}

#pragma mark - Views

- (UILabel *)methodTitleLabel {
    if (!_methodTitleLabel) {
        _methodTitleLabel = [[UILabel alloc] init];
        _methodTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _methodTitleLabel.font = [UIFont cj_fontOfSize:13];
        _methodTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _methodTitleLabel.text = CJPayLocalizedStr(@"到账方式");
        _methodTitleLabel.clipsToBounds = NO;
    }
    return _methodTitleLabel;
}

- (UILabel *)timeTitleLabel {
    if (!_timeTitleLabel) {
        _timeTitleLabel = [[UILabel alloc] init];
        _timeTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _timeTitleLabel.font = [UIFont cj_fontOfSize:13];
        _timeTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _timeTitleLabel.text = CJPayLocalizedStr(@"到账时间");
        _timeTitleLabel.clipsToBounds = NO;
    }
    return _timeTitleLabel;
}

- (UILabel *)timeLabel {
    if (!_timeLabel) {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _timeLabel.font = [UIFont cj_fontOfSize:13];
        _timeLabel.textColor = [UIColor cj_222222ff];
        _timeLabel.textAlignment = NSTextAlignmentRight;
        _timeLabel.text = @"";
    }
    return _timeLabel;
}

- (CJPayWithDrawResultMethodView *)methodView {
    if (!_methodView) {
        _methodView = [[CJPayWithDrawResultMethodView alloc] init];
//        _methodView.contentLabel.textColor = [UIColor cj_222222ff];
    }
    
    return _methodView;
}

#pragma mark - Update

- (void)updateWithAccountText:(NSString *)accountText
               accountIconUrl:(nullable NSString *)accountIconUrl
                       status:(CJPayOrderStatus)status
                     timeText:(NSString *)timeText {
    if ([[self.methodView.imageView bd_imageURL].absoluteString isEqualToString:accountIconUrl]
            && [self.methodView.contentLabel.text isEqualToString:accountText]
            && [self.timeLabel.text isEqualToString:timeText]) {
        return;
    }

    if (accountIconUrl != nil) {
        [self.methodView setImageUrl:accountIconUrl content:accountText];
    } else {
        self.methodView.contentLabel.text = accountText;
    }

    if (([self.timeLabel.text length] > 0 && timeText == nil)
            || ([self.timeLabel.text length] == 0 && timeText != nil)) {
        self.timeLabel.text = timeText;
        [self invalidateIntrinsicContentSize];
    }

    if (status == CJPayOrderStatusSuccess) {
        self.timeTitleLabel.text = CJPayLocalizedStr(@"到账时间");
    } else {
        self.timeTitleLabel.text = CJPayLocalizedStr(@"提现时间");
    }
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

@end
