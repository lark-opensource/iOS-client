//
//  CJPayPayAgainDiscountView.m
//  Pods
//
//  Created by bytedance on 2022/3/15.
//

#import "CJPayPayAgainDiscountView.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPayLineUtil.h"

@interface CJPayPayAgainDiscountView ()

@property (nonatomic, strong) UILabel *discountLabel;
@property (nonatomic, strong) UIImageView *discountImageView;
@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, assign) BOOL isHiddenImageView;

@end

@implementation CJPayPayAgainDiscountView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame hiddenImageView:(BOOL)hidden {
    self = [super initWithFrame:frame];
    if (self) {
        self.isHiddenImageView = hidden;
        [self p_setupUI];
    }
    return self;
}

- (void)setDiscountStr:(NSString *)discountStr {
    self.discountLabel.text = discountStr;
}

- (void)drawRect:(CGRect)rect {
    [self cj_clipTopLeftCorner:16];
    [CJPayLineUtil cj_drawLines:CJPayLineAllLines withRoundedCorners:UIRectCornerTopLeft radius:16 viewRect:CGRectInset(CGRectMake(0, 0, self.frame.size.width, self.frame.size.height), CJ_PIXEL_WIDTH, CJ_PIXEL_WIDTH) color:[UIColor cj_fe2c55WithAlpha:0.12]];
}

- (void)p_setupUI {
    [self addSubview:self.discountLabel];
    if (!self.isHiddenImageView) {
        [self addSubview:self.discountImageView];
    }
    [self addSubview:self.bgView];
    
    CJPayMasReMaker(self.discountLabel, {
        make.top.equalTo(self).offset(7);
        if (!self.isHiddenImageView) {
            make.left.equalTo(self).offset(30);
        } else {
            make.left.equalTo(self).offset(10);
        }
        make.right.equalTo(self).offset(-12);
    })
    
    if (!self.isHiddenImageView) {
        CJPayMasMaker(self.discountImageView, {
            make.top.equalTo(self).offset(8);
            make.left.equalTo(self).offset(12);
            make.height.mas_equalTo(16);
            make.width.mas_equalTo(16);
        })
    }
    
    CJPayMasMaker(self.bgView, {
        make.edges.equalTo(self);
    })
}

- (UILabel *)discountLabel {
    if (!_discountLabel) {
        _discountLabel = [UILabel new];
        _discountLabel.textColor = [UIColor cj_fe2c55ff];
        _discountLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _discountLabel;
}

- (UIImageView *)discountImageView {
    if (!_discountImageView) {
        _discountImageView = [UIImageView new];
        [_discountImageView cj_setImage:@"cj_discount_icon"];
    }
    return _discountImageView;
}

- (UIView *)bgView {
    if (!_bgView) {
        _bgView = [UIView new];
        _bgView.backgroundColor = [UIColor cj_fe2c55WithAlpha:0.06];
    }
    return _bgView;
}

@end
