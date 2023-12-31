//
//  CJPayOrderInfoView.m
//  Pods
//
//  Created by bytedance on 2022/4/12.
//

#import "CJPayOrderInfoView.h"
#import "CJPayUIMacro.h"

@interface CJPayOrderInfoView ()

@property (nonatomic, strong) UILabel *orderInfoLabel;
@property (nonatomic, strong) UIImageView *tickCircleView;

@end

@implementation CJPayOrderInfoView

- (instancetype)init{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.tickCircleView];
    [self addSubview:self.orderInfoLabel];
    
    CJPayMasMaker(self.tickCircleView, {
        make.left.equalTo(self);
        make.centerY.equalTo(self);
        make.width.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.orderInfoLabel, {
        make.left.equalTo(self.tickCircleView.mas_right).offset(4);
        make.right.equalTo(self);
        make.centerY.equalTo(self.tickCircleView);
        make.top.equalTo(self);
        make.bottom.equalTo(self);
    })
}

- (void)updateWithText:(NSString *)text iconURL:(NSString *)URL {
    self.orderInfoLabel.text = CJPayLocalizedStr(text);
    if (Check_ValidString(URL)) {
        [self.tickCircleView cj_setImageWithURL:[NSURL URLWithString:URL]];
    }
}

- (UILabel *)orderInfoLabel {
    if (!_orderInfoLabel) {
        _orderInfoLabel = [UILabel new];
        _orderInfoLabel.textColor = [UIColor cj_161823WithAlpha:0.7];
        _orderInfoLabel.font = [UIFont cj_fontOfSize:12];
        _orderInfoLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _orderInfoLabel;
}

- (UIImageView *)tickCircleView {
    if (!_tickCircleView) {
        _tickCircleView = [UIImageView new];
    }
    return _tickCircleView;
}

@end
