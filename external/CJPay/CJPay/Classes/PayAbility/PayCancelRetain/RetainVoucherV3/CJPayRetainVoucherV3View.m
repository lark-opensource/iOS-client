//
//  CJPayRetainVoucherV3View.m
//  Aweme
//
//  Created by 尚怀军 on 2022/12/1.
//

#import "CJPayRetainVoucherV3View.h"
#import "CJPayUIMacro.h"
#import "CJPayRetainMsgModel.h"

@interface CJPayRetainVoucherV3View ()

@property (nonatomic, strong) UIImageView *backgroundImgView;
@property (nonatomic, strong) UIView *leftView;
@property (nonatomic, strong) UILabel *leftTagLabel;
@property (nonatomic, strong) UILabel *leftMsgLabel;
@property (nonatomic, strong) UILabel *rightMsgLabel;
@property (nonatomic, strong) UIImageView *seperateView;
@property (nonatomic, strong) UIView *topRightBackgroudView;
@property (nonatomic, strong) UILabel *topRightLabel;

@end

@implementation CJPayRetainVoucherV3View

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.backgroundImgView];
    [self addSubview:self.leftView];
    [self.leftView addSubview:self.leftTagLabel];
    [self.leftView addSubview:self.leftMsgLabel];
    [self addSubview:self.rightMsgLabel];
    [self addSubview:self.seperateView];
    [self addSubview:self.topRightBackgroudView];
    [self addSubview:self.topRightLabel];
    
    CJPayMasMaker(self.backgroundImgView, {
        make.edges.equalTo(self);
    });
    
    CJPayMasMaker(self.seperateView, {
        make.top.equalTo(self).offset(11);
        make.bottom.equalTo(self).offset(-11);
        make.centerX.equalTo(self.mas_right).dividedBy(2.9);
        make.width.mas_equalTo(2);
    })
    
    CJPayMasMaker(self.leftView, {
        make.top.left.bottom.equalTo(self);
        make.right.equalTo(self.seperateView.mas_left);
    })
    
    CJPayMasMaker(self.leftMsgLabel, {
        make.left.greaterThanOrEqualTo(self.leftView.mas_left).offset(5);
        make.right.lessThanOrEqualTo(self.leftView.mas_right);
        make.centerX.equalTo(self.leftView).offset(2);
        make.centerY.equalTo(self);
    })
    
    CJPayMasMaker(self.rightMsgLabel, {
        make.left.equalTo(self.seperateView).offset(12);
        make.right.equalTo(self).offset(-5);
        make.centerY.equalTo(self);
    })
    
    CJPayMasMaker(self.topRightBackgroudView, {
        make.top.right.equalTo(self);
        make.height.mas_equalTo(15);
        make.width.mas_equalTo(44);
    })
    
    CJPayMasMaker(self.topRightLabel, {
        make.edges.equalTo(self.topRightBackgroudView);
    })
    
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self.topRightBackgroudView cj_customCorners:UIRectCornerTopRight | UIRectCornerBottomLeft radius:8];
    [self.topRightBackgroudView cj_applyGradientWithStartColor:[UIColor cj_ff938aff]
                                                      endColor:[UIColor cj_fe2c55ff]
                                                    startPoint:CGPointMake(0, 0.5)
                                                    startPoint:CGPointMake(1, 0.5)];
}

- (void)updateWithRetainMsgModel:(CJPayRetainMsgModel *)retainMsgModel {
    if (retainMsgModel.leftMsgType == 1) {
        self.leftMsgLabel.attributedText = [self p_getAttributeStrWithAmount:retainMsgModel.leftMsg];
    } else {
        self.leftMsgLabel.text = retainMsgModel.leftMsg;
    }
    
    self.rightMsgLabel.text = retainMsgModel.rightMsg;
    if (Check_ValidString(retainMsgModel.topLeftMsg)) {
        [self p_setupWithTag:retainMsgModel];
    } else {
        [self p_setupWithoutTag:retainMsgModel];
    }
}

// 有标签 标签在右上角或金额左边
- (void)p_setupWithTag:(CJPayRetainMsgModel *)retainMsgModel {
    CGFloat centerYOffset = retainMsgModel.leftMsgType == 1 ? -1 : 0;
    if ([retainMsgModel.topLeftPosition isEqualToString:@"left"]) {
        CJPayMasReMaker(self.leftTagLabel, {
            make.right.equalTo(self.leftMsgLabel.mas_left).offset(-2);
            make.width.mas_equalTo(13);
            make.centerY.equalTo(self.leftView);
        })
        
        CJPayMasReMaker(self.leftMsgLabel, {
            make.left.greaterThanOrEqualTo(self.leftView.mas_left).offset(10);
            make.right.lessThanOrEqualTo(self.leftView.mas_right).priorityHigh;
            make.centerX.equalTo(self.leftView).offset(10);
            make.centerY.equalTo(self).offset(centerYOffset);
        })
        
        self.topRightBackgroudView.hidden = YES;
        self.topRightLabel.hidden = YES;
        self.leftTagLabel.hidden = NO;
        self.leftTagLabel.text = retainMsgModel.topLeftMsg;
    } else {
        CJPayMasMaker(self.leftMsgLabel, {
            make.left.greaterThanOrEqualTo(self.leftView.mas_left).offset(2);
            make.right.lessThanOrEqualTo(self.leftView.mas_right);
            make.centerX.equalTo(self.leftView).offset(2);
            make.centerY.equalTo(self).offset(centerYOffset);
        })
        
        self.topRightBackgroudView.hidden = NO;
        self.topRightLabel.hidden = NO;
        self.leftTagLabel.hidden = YES;
        self.topRightLabel.text = retainMsgModel.topLeftMsg;
    }
}

// 无标签
- (void)p_setupWithoutTag:(CJPayRetainMsgModel *)retainMsgModel {
    CGFloat centerYOffset = retainMsgModel.leftMsgType == 1 ? -1 : 0;
    CJPayMasMaker(self.leftMsgLabel, {
        make.left.greaterThanOrEqualTo(self.leftView.mas_left).offset(2);
        make.right.lessThanOrEqualTo(self.leftView.mas_right);
        make.centerX.equalTo(self.leftView).offset(2);
        make.centerY.equalTo(self).offset(centerYOffset);
    })
    self.topRightBackgroudView.hidden = YES;
    self.topRightLabel.hidden = YES;
    self.leftTagLabel.hidden = YES;
    self.topRightLabel.text = @"";
}

- (NSAttributedString *)p_getAttributeStrWithAmount:(NSString *)amountStr {
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:CJString(amountStr)
                                                                                         attributes:@{
        NSFontAttributeName: [UIFont cj_denoiseBoldFontOfSize:26],
        NSForegroundColorAttributeName: [UIColor cj_fe2c55ff],
        NSParagraphStyleAttributeName: paragraphStyle
    }];
    NSAttributedString *amountAttrString = [[NSAttributedString alloc] initWithString:@"元"
                                                                           attributes:@{
        NSFontAttributeName: [UIFont cj_denoiseBoldFontOfSize:11],
        NSForegroundColorAttributeName: [UIColor cj_fe2c55ff],
        NSParagraphStyleAttributeName: paragraphStyle,
        NSBaselineOffsetAttributeName: @(1)
    }];
    
    [attributedString appendAttributedString:amountAttrString];
    return attributedString;
}

- (UIImageView *)backgroundImgView {
    if (!_backgroundImgView) {
        _backgroundImgView = [UIImageView new];
        [_backgroundImgView cj_setImage:@"cj_voucher_background_v3_icon"];
    }
    return _backgroundImgView;
}

- (UIView *)leftView {
    if (!_leftView) {
        _leftView = [UIView new];
    }
    return _leftView;
}

- (UILabel *)leftTagLabel {
    if (!_leftTagLabel) {
        _leftTagLabel = [UILabel new];
        _leftTagLabel.textAlignment = NSTextAlignmentCenter;
        _leftTagLabel.backgroundColor = [UIColor clearColor];
        _leftTagLabel.numberOfLines = 0;
        _leftTagLabel.layer.cornerRadius = 2;
        _leftTagLabel.layer.borderWidth = CJ_PIXEL_WIDTH;
        _leftTagLabel.layer.borderColor = [[UIColor cj_fe496aff] CGColor];
        _leftTagLabel.font = [UIFont cj_fontOfSize:9];
        _leftTagLabel.textColor = [UIColor cj_fe496aff];
        _leftTagLabel.hidden = YES;
    }
    return _leftTagLabel;
}

- (UILabel *)leftMsgLabel {
    if (!_leftMsgLabel) {
        _leftMsgLabel = [UILabel new];
        _leftMsgLabel.textAlignment = NSTextAlignmentCenter;
        _leftMsgLabel.font = [UIFont cj_boldFontOfSize:22];
        _leftMsgLabel.textColor = [UIColor cj_fe2c55ff];
    }
    return _leftMsgLabel;
}

- (UILabel *)rightMsgLabel {
    if (!_rightMsgLabel) {
        _rightMsgLabel = [UILabel new];
        _rightMsgLabel.font = [UIFont cj_boldFontOfSize:13];
        _rightMsgLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
        _rightMsgLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _rightMsgLabel;
}

- (UIImageView *)seperateView {
    if (!_seperateView) {
        _seperateView = [UIImageView new];
        [_seperateView cj_setImage:@"cj_seperate_line_v3_icon"];
    }
    return _seperateView;
}

- (UIView *)topRightBackgroudView {
    if (!_topRightBackgroudView) {
        _topRightBackgroudView = [UIView new];
        _topRightLabel.clipsToBounds = YES;
        _topRightLabel.hidden = YES;
    }
    return  _topRightBackgroudView;
}

- (UILabel *)topRightLabel {
    if (!_topRightLabel) {
        _topRightLabel = [UILabel new];
        _topRightLabel.font = [UIFont cj_boldFontOfSize:9];
        _topRightLabel.textColor = [UIColor whiteColor];
        _topRightLabel.textAlignment = NSTextAlignmentCenter;
        _topRightLabel.hidden = YES;
    }
    return _topRightLabel;
}

@end
