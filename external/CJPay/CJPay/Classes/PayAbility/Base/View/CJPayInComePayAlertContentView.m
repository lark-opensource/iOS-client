//
//  CJPayInComePayAlertContentView.m
//  Pods
//
//  Created by bytedance on 2021/6/25.
//

#import "CJPayInComePayAlertContentView.h"
#import "CJPayUIMacro.h"
#import "CJPaySubPayTypeIconTipModel.h"

@interface CJPayInComePayAlertContentView ()

@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) UILabel *contentLabel;

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *content;
@property (nonatomic, strong) CJPaySubPayTypeIconTipModel *iconTips;

@end

@implementation CJPayInComePayAlertContentView

- (instancetype)initWithIconTips:(CJPaySubPayTypeIconTipModel *)iconTips {
    self = [self init];
    if (self) {
        _iconTips = iconTips;
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.titleLabel];
    [self addSubview:self.contentLabel];
    
    CJPayMasMaker(self.titleLabel, {
        make.left.equalTo(self).offset(20);
        make.right.equalTo(self).offset(-20);
        make.top.equalTo(self).offset(24);
        make.height.mas_equalTo(24);
    });
    
    UIView *lastObject = self.titleLabel;
    
    for (CJPaySubPayTypeIconTipInfoModel *model in self.iconTips.contentList) {
        UILabel *titleLabel = [self titleLabelWithText:model.subTitle];
        [self addSubview:titleLabel];
        
        CJPayMasMaker(titleLabel, {
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
            make.top.equalTo(lastObject.mas_bottom).offset(8);
            make.height.mas_equalTo(20);
        });
        
        UILabel *contentLabel = [self contentLabelWithText:model.subContent lineHeight:20];
        [self addSubview:contentLabel];
        
        CJPayMasMaker(contentLabel, {
            make.left.equalTo(self).offset(20);
            make.right.equalTo(self).offset(-20);
            if (Check_ValidString(model.subTitle)) {
                make.top.equalTo(titleLabel.mas_bottom).offset(4);
            } else {
                make.top.equalTo(lastObject.mas_bottom).offset(8);
            }
        });
        
        lastObject = contentLabel;
    }
    CJPayMasMaker(self, {
        make.bottom.equalTo(lastObject).offset(24);
    });
}

- (UILabel *)titleLabelWithText:(NSString *)title {
    UILabel *titleLabel = [UILabel new];
    titleLabel.font = [UIFont cj_boldFontOfSize:14];
    titleLabel.textColor = [UIColor cj_161823ff];
    titleLabel.textAlignment = NSTextAlignmentLeft;
    [titleLabel btd_SetText:self.content lineHeight:20];
    titleLabel.text = title;
    return titleLabel;
}

- (UILabel *)contentLabelWithText:(NSString *)content lineHeight:(CGFloat)lineHeight {
    UILabel *contentLabel = [UILabel new];
    contentLabel.font = [UIFont cj_fontOfSize:14];
    contentLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
    contentLabel.textAlignment = NSTextAlignmentLeft;
    contentLabel.numberOfLines = 0;
    [contentLabel btd_SetText:content lineHeight:lineHeight];
    return contentLabel;
}
    
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.text = self.iconTips.title;
    }
    return _titleLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [UILabel new];
        _contentLabel.userInteractionEnabled = YES;
        _contentLabel.font = [UIFont cj_fontOfSize:14];
        _contentLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _contentLabel.numberOfLines = 0;
        [_contentLabel btd_SetText:self.content lineHeight:20];
        
    }
    return _contentLabel;
}

@end
