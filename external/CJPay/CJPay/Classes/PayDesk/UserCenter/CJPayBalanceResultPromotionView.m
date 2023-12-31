//
//  CJPayBalanceResultPromotionView.m
//  CJPaySandBox-1
//
//  Created by youerwei on 2023/2/23.
//

#import "CJPayBalanceResultPromotionView.h"
#import "CJPayStyleButton.h"
#import "CJPayUIMacro.h"
#import "CJPayBalanceResultPromotionModel.h"
#import "CJPayBalanceResultPromotionAmountView.h"
#import "CJPayBalanceResultPromotionDescView.h"

@interface CJPayBalanceResultPromotionView ()

@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) UIImageView *seperateView;
@property (nonatomic, strong) CJPayBalanceResultPromotionAmountView *amountView;
@property (nonatomic, strong) CJPayBalanceResultPromotionDescView *rightDescView;

@end

@implementation CJPayBalanceResultPromotionView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.amountView];
    [self addSubview:self.rightDescView];
    [self addSubview:self.seperateView];
    
    CJPayMasMaker(self.seperateView, {
        make.centerX.equalTo(self.mas_right).dividedBy(3.4);
        make.height.mas_equalTo(80);
        make.width.mas_equalTo(2);
        make.centerY.equalTo(self);
    });
    CJPayMasMaker(self.amountView, {
        make.left.top.bottom.equalTo(self);
        make.right.equalTo(self.seperateView.mas_left);
    });
    CJPayMasMaker(self.rightDescView, {
        make.left.equalTo(self.seperateView);
        make.top.right.bottom.equalTo(self);
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _backgroundImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [_backgroundImageView cj_setImage:@"cj_balance_promotion_background_icon"];
        [self insertSubview:_backgroundImageView atIndex:0];
        [self setNeedsLayout];
        [self layoutIfNeeded];
    });
}

- (void)updateWithPromotionModel:(CJPayBalanceResultPromotionModel *)promotionModel {
    [self.amountView updateWithPromotionModel:promotionModel];
    [self.rightDescView updateWithPromotionModel:promotionModel];
}

- (UIImageView *)seperateView {
    if (!_seperateView) {
        _seperateView = [UIImageView new];
        [_seperateView cj_setImage:@"cj_balance_result_sep_icon"];
    }
    return _seperateView;
}

- (CJPayBalanceResultPromotionAmountView *)amountView {
    if (!_amountView) {
        _amountView = [CJPayBalanceResultPromotionAmountView new];
    }
    return _amountView;
}

- (CJPayBalanceResultPromotionDescView *)rightDescView {
    if (!_rightDescView) {
        _rightDescView = [CJPayBalanceResultPromotionDescView new];
    }
    return _rightDescView;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
