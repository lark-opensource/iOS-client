//
//  OPVideoLoadFailView.m
//  OPPluginBiz
//
//  Created by zhujingcheng on 2/21/23.
//

#import "OPVideoLoadFailView.h"
#import <OPFoundation/BDPI18n.h>
#import <Masonry/Masonry.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>
#import <OPPluginBiz/OPPluginBiz-Swift.h>

@interface OPVideoLoadFailView ()

@property (nonatomic, strong) UIView *container;
@property (nonatomic, strong) OPVideoEmptyView *failedBg;
@property (nonatomic, strong) UIView *textContainer;
@property (nonatomic, strong) UILabel *failedText;
@property (nonatomic, strong) UIButton *retryBtn;

@end

@implementation OPVideoLoadFailView

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutUI];
}

- (void)layoutUI {
    [self.container removeFromSuperview];
    [self.failedBg removeFromSuperview];
    [self.textContainer removeFromSuperview];
    [self.failedText removeFromSuperview];
    [self.retryBtn removeFromSuperview];
    
    if (self.btd_height > 140 && self.btd_width > 240) {
        [self normalLayout];
    } else {
        [self layoutWithoutBg];
    }
}

- (void)normalLayout {
    CGSize failedTextSize = self.failedTextSize;
    CGSize retryBtnTextSize = self.retryBtnTextSize;
    CGFloat retryBtnWidth = retryBtnTextSize.width + 8;
    CGFloat totalTextWidth = failedTextSize.width + retryBtnWidth + 4;
    // 单行文本溢出, 两行显示
    BOOL isDoubleLine = totalTextWidth > self.btd_width;
    BOOL equalToBg = totalTextWidth < 132;
    [self addSubview:self.container];
    [self.container mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.mas_equalTo(self);
    }];
    [self.container addSubview:self.failedBg];
    [self.failedBg mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.centerX.mas_equalTo(self.container);
        make.width.mas_equalTo(132);
        make.height.mas_equalTo(100);
        if (equalToBg) {
            make.leading.trailing.mas_equalTo(self.container);
        }
    }];
    
    if (isDoubleLine) {
        [self.container addSubview:self.failedText];
        [self.failedText mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.failedBg.mas_bottom).mas_equalTo(12);
            make.leading.trailing.centerX.equalTo(self.container);
        }];
        
        [self.container addSubview:self.retryBtn];
        [self.retryBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(self.failedText.mas_bottom).mas_offset(4);
            make.leading.trailing.centerX.equalTo(self.container);
            make.bottom.mas_equalTo(self.container);
        }];
        
        return;
    }
    
    [self.container addSubview:self.textContainer];
    [self.textContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.failedBg.mas_bottom).mas_equalTo(12);
        make.centerX.mas_equalTo(self.container);
        make.width.mas_equalTo(totalTextWidth);
        make.height.mas_equalTo(failedTextSize.height);
        if (!equalToBg) {
            make.leading.trailing.mas_equalTo(self.container);
        }
        make.bottom.mas_equalTo(self.container);
    }];
    [self.textContainer addSubview:self.failedText];
    [self.failedText mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.centerY.mas_equalTo(self.textContainer);
    }];
    [self.textContainer addSubview:self.retryBtn];
    [self.retryBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.failedText.mas_trailing).mas_offset(4);
        make.centerY.mas_equalTo(self.textContainer);
        make.width.mas_equalTo(retryBtnWidth);
        make.height.mas_equalTo(retryBtnTextSize.height);
    }];
}

- (void)layoutWithoutBg {
    CGSize failedTextSize = self.failedTextSize;
    CGSize retryBtnTextSize = self.retryBtnTextSize;
    CGFloat retryBtnWidth = retryBtnTextSize.width + 8;
    CGFloat totalTextWidth = failedTextSize.width + retryBtnWidth + 4;
    if (totalTextWidth < self.btd_width) {
        [self addSubview:self.textContainer];
        [self.textContainer mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(self);
            make.width.mas_equalTo(totalTextWidth);
            make.height.mas_equalTo(failedTextSize.height);
        }];
        [self.textContainer addSubview:self.failedText];
        [self.failedText mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.centerY.mas_equalTo(self.textContainer);
        }];
        [self.textContainer addSubview:self.retryBtn];
        [self.retryBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.mas_equalTo(self.failedText.mas_trailing).mas_offset(4);
            make.centerY.mas_equalTo(self.textContainer);
            make.width.mas_equalTo(retryBtnWidth);
            make.height.mas_equalTo(retryBtnTextSize.height);
        }];
    } else {
        [self addSubview:self.retryBtn];
        [self.retryBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.mas_equalTo(self);
            make.width.mas_equalTo(retryBtnWidth);
            make.height.mas_equalTo(retryBtnTextSize.height);
        }];
    }
}

- (void)onRetryBtnClicked {
    !self.actionBlock ?: self.actionBlock();
}

- (CGSize)failedTextSize {
    return [self.failedText.text btd_sizeWithFont:self.failedText.font width:HUGE_VALF];
}

- (CGSize)retryBtnTextSize {
    return [self.retryBtn.titleLabel.text btd_sizeWithFont:self.retryBtn.titleLabel.font width:HUGE_VALF];
}

- (UIView *)container {
    if (!_container) {
        _container = [[UIView alloc] init];
    }
    return _container;
}

- (OPVideoEmptyView *)failedBg {
    if (!_failedBg) {
        _failedBg = [[OPVideoEmptyView alloc] initWithFrame:CGRectZero];
    }
    return _failedBg;
}

- (UIView *)textContainer {
    if (!_textContainer) {
        _textContainer = [[UIView alloc] init];
    }
    return _textContainer;
}

- (UILabel *)failedText {
    if (!_failedText) {
        _failedText = [[UILabel alloc] init];
        _failedText.textColor = [UIColor btd_colorWithHexString:@"#A6A6A6"];
        _failedText.font = [UIFont systemFontOfSize:14];
        _failedText.text = BDPI18n.microapp_m_video_retry_tips;
    }
    return _failedText;
}

- (UIButton *)retryBtn {
    if (!_retryBtn) {
        _retryBtn = [[UIButton alloc] init];
        [_retryBtn setTitleColor:[UIColor btd_colorWithHexString:@"#4C88FF"] forState:UIControlStateNormal];
        _retryBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [_retryBtn setTitle:BDPI18n.LittleApp_ClientErrorCode_RetryIcon forState:UIControlStateNormal];
        [_retryBtn addTarget:self action:@selector(onRetryBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _retryBtn;
}

@end
