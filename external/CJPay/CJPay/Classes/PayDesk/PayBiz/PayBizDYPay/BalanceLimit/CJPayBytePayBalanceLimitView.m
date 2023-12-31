//
//  CJPayBytePayBalanceLimitView.m
//  Pods
//
//  Created by wangxiaohong on 2021/4/14.
//

#import "CJPayBytePayBalanceLimitView.h"

#import "CJPayUIMacro.h"
#import "CJPayCombinePayLimitModel.h"
#import "CJPayStyleButton.h"

@interface CJPayBytePayBalanceLimitView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;

@property (nonatomic, strong) CJPayButton *closeButton;

@end

@implementation CJPayBytePayBalanceLimitView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)updateWithButtonModel:(CJPayCombinePayLimitModel *)model {
    self.titleLabel.text = CJString(model.title);
    self.detailLabel.attributedText = [self p_getAttributeStringWithModel:model];
    [self.confirmButton cj_setBtnTitle:CJString(model.buttonDesc)];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat detailLabelLineHeight = 20;
        if (self.detailLabel.cj_size.height > detailLabelLineHeight * 4) {  //超过四行居左
            self.detailLabel.textAlignment = NSTextAlignmentLeft;
        }
    });
}

- (NSAttributedString *)p_getAttributeStringWithModel:(CJPayCombinePayLimitModel *)model {
    NSRange range = [model.desc rangeOfString:model.highLightDesc];
    NSMutableParagraphStyle *paraStyle = [NSMutableParagraphStyle new];
    paraStyle.cjMaximumLineHeight = 20;
    paraStyle.cjMinimumLineHeight = 20;
    paraStyle.lineBreakMode = NSLineBreakByCharWrapping;
    paraStyle.alignment = NSTextAlignmentCenter;
    
    NSDictionary *weakAttributes = @{NSFontAttributeName : [UIFont cj_fontOfSize:14],
                                     NSForegroundColorAttributeName : [UIColor cj_161823WithAlpha:0.75],
                                     NSParagraphStyleAttributeName : paraStyle};
    
    NSDictionary *mainAttributes = @{NSFontAttributeName : [UIFont cj_boldFontOfSize:14],
                                     NSForegroundColorAttributeName : [UIColor cj_161823ff],
                                     NSParagraphStyleAttributeName : paraStyle};
    
    NSMutableAttributedString *attributeStr = [[NSMutableAttributedString alloc] initWithString:CJString(model.desc) attributes:weakAttributes];
    [attributeStr setAttributes:mainAttributes range:range];
    
    return [attributeStr copy];
}

- (void)p_setupUI {
    
    self.backgroundColor = [UIColor whiteColor];
    self.layer.cornerRadius = 8;
    
    [self addSubview:self.titleLabel];
    [self addSubview:self.detailLabel];
    [self addSubview:self.confirmButton];
    [self addSubview:self.closeButton];
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self).offset(40);
        make.centerX.equalTo(self);
        make.left.right.lessThanOrEqualTo(self).inset(20);
    });
    
    CJPayMasMaker(self.detailLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.right.equalTo(self.titleLabel);
    });
    
    CJPayMasMaker(self.confirmButton, {
        make.top.equalTo(self.detailLabel.mas_bottom).offset(20);
        make.left.right.equalTo(self.titleLabel);
        make.bottom.equalTo(self).offset(-20);
        make.height.mas_equalTo(44);
    });
    
    CJPayMasMaker(self.closeButton, {
        make.top.left.equalTo(self).inset(12);
        make.width.height.mas_equalTo(20);
    });
}

- (void)p_closeClick {
    CJ_CALL_BLOCK(self.closeClickBlock);
}

- (void)p_buttonClick {
    CJ_CALL_BLOCK(self.confirmPayBlock);
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [UILabel new];
        _detailLabel.numberOfLines = 0;
    }
    return _detailLabel;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [CJPayStyleButton new];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        [_confirmButton addTarget:self action:@selector(p_buttonClick) forControlEvents:UIControlEventTouchUpInside];
        _confirmButton.layer.cornerRadius = 4;
    }
    return _confirmButton;
}

- (CJPayButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [CJPayButton new];
        [_closeButton cj_setBtnImageWithName:@"cj_close_denoise_icon"];
        [_closeButton addTarget:self action:@selector(p_closeClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

@end
