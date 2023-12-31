//
//  CJPayRetainVoucherView.m
//  Pods
//
//  Created by youerwei on 2022/2/7.
//

#import "CJPayRetainVoucherView.h"
#import "CJPayUIMacro.h"
#import "CJPayRetainMsgModel.h"

@interface CJPayRetainVoucherView ()

@property (nonatomic, strong) UILabel *leftMsgLabel;
@property (nonatomic, strong) UILabel *rightMsgLabel;
@property (nonatomic, strong) UIImageView *seperateView;
@property (nonatomic, strong) UILabel *topLeftLabel;

@end

@implementation CJPayRetainVoucherView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    
    UIImageView *imageView = [UIImageView new];
    [imageView cj_setImage:@"cj_voucher_background_icon"];
    [self addSubview:imageView];
    CJPayMasMaker(imageView, {
        make.edges.equalTo(self);
    });
    
    [self addSubview:self.leftMsgLabel];
    [self addSubview:self.rightMsgLabel];
    [self addSubview:self.seperateView];
    [self addSubview:self.topLeftLabel];
    
    CJPayMasMaker(self.seperateView, {
        make.top.equalTo(self).offset(16);
        make.bottom.equalTo(self).offset(-16);
        make.centerX.equalTo(self.mas_right).dividedBy(3);
        make.width.mas_equalTo(0.5);
    })
    
    CJPayMasMaker(self.leftMsgLabel, {
        make.left.equalTo(self).offset(5);
        make.right.equalTo(self.seperateView);
        make.centerY.equalTo(self);
    })
    
    CJPayMasMaker(self.rightMsgLabel, {
        make.left.equalTo(self.seperateView).offset(12);
        make.right.equalTo(self).offset(-5);
        make.centerY.equalTo(self);
    })
    
    CJPayMasMaker(self.topLeftLabel, {
        make.top.left.equalTo(self);
        make.height.mas_equalTo(18);
        make.width.mas_equalTo(52);
    })
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.topLeftLabel cj_customCorners:UIRectCornerTopLeft | UIRectCornerBottomRight radius:4];
    });
}

- (void)updateWithRetainMsgModel:(CJPayRetainMsgModel *)retainMsgModel {
    if (retainMsgModel.leftMsgType == 1) {
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:@"¥" attributes:@{
            NSFontAttributeName: [UIFont cj_denoiseBoldFontOfSize:18],
            NSForegroundColorAttributeName: [UIColor cj_fe2c55ff],
            NSParagraphStyleAttributeName: paragraphStyle
        }];
        NSAttributedString *amountString = [[NSAttributedString alloc] initWithString:CJString(retainMsgModel.leftMsg) attributes:@{
            NSFontAttributeName: [UIFont cj_denoiseBoldFontOfSize:24],
            NSForegroundColorAttributeName: [UIColor cj_fe2c55ff],
            NSParagraphStyleAttributeName: paragraphStyle,
            NSKernAttributeName: @-1
        }];
        [attributedString appendAttributedString:amountString];
        self.leftMsgLabel.attributedText = attributedString;
    } else {
        self.leftMsgLabel.font = [UIFont cj_boldFontOfSize:22];
        self.leftMsgLabel.text = retainMsgModel.leftMsg;
        self.leftMsgLabel.textColor = [UIColor cj_fe2c55ff];
    }
    
    self.rightMsgLabel.text = retainMsgModel.rightMsg;
    
    if (Check_ValidString(retainMsgModel.topLeftMsg)) {
        self.topLeftLabel.hidden = NO;
        self.topLeftLabel.text = retainMsgModel.topLeftMsg;
    }
}

- (UILabel *)leftMsgLabel {
    if (!_leftMsgLabel) {
        _leftMsgLabel = [UILabel new];
        _leftMsgLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _leftMsgLabel;
}

- (UILabel *)rightMsgLabel {
    if (!_rightMsgLabel) {
        _rightMsgLabel = [UILabel new];
        _rightMsgLabel.font = [UIFont cj_boldFontOfSize:14];
        _rightMsgLabel.textColor = [UIColor cj_161823WithAlpha:0.9];
        _rightMsgLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _rightMsgLabel;
}

- (UIImageView *)seperateView {
    if (!_seperateView) {
        _seperateView = [UIImageView new];
        [_seperateView cj_setImage:@"cj_seperate_line_icon"];
    }
    return _seperateView;
}

- (UILabel *)topLeftLabel {
    if (!_topLeftLabel) {
        _topLeftLabel = [UILabel new];
        _topLeftLabel.clipsToBounds = YES;
        _topLeftLabel.backgroundColor = [UIColor cj_fe2c55WithAlpha:0.9];
        _topLeftLabel.font = [UIFont cj_boldFontOfSize:10];
        _topLeftLabel.textColor = [UIColor whiteColor];
        _topLeftLabel.textAlignment = NSTextAlignmentCenter;
        _topLeftLabel.hidden = YES;
    }
    return _topLeftLabel;
}

@end
