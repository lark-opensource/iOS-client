//
//  CJPayCountDownTimerView.m
//  CJPay
//
//  Created by 王新华 on 2019/4/23.
//

#import "CJPayCountDownTimerView.h"
#import "CJPayUIMacro.h"

@interface CJPayCountDownTimerView()

@property (nonatomic, strong) UILabel *titleL;
@property (nonatomic, assign, readwrite) BOOL curTimeIsValid;

@end

@implementation CJPayCountDownTimerView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    self.backgroundColor = UIColor.whiteColor;
    
    [self addSubview:self.titleL];
    
    CJPayMasMaker(self.titleL, {
        make.left.right.equalTo(self);
        make.centerY.equalTo(self);
    });
    
    self.style = CJPayCountDownTimerViewStyleNormal;
}

- (void)setStyle:(CJPayCountDownTimerViewStyle)style {
    _style = style;
    if (style == CJPayCountDownTimerViewStyleSmall) {
        self.titleL.font = [UIFont cj_monospacedDigitSystemFontOfSize:13];
        self.titleL.textColor = [UIColor cj_161823WithAlpha:0.5];
    } else {
        self.titleL.font = [UIFont cj_monospacedDigitSystemFontOfSize:14];
        self.titleL.textColor = UIColor.cj_999999ff;
    }
}

- (void)startTimerWithCountTime:(int)countTime {
    [super startTimerWithCountTime:countTime];
    self.curTimeIsValid = YES;
}

- (void)currentCountChangeTo:(int)value {
    [super currentCountChangeTo:value];
    _titleL.text = [NSString stringWithFormat:@"%@ %@ %@ ",CJPayLocalizedStr(@"请在"), [CJPayCommonUtil getMMSSFromSS:value], CJPayLocalizedStr(@"内完成付款")];
}

- (void)reset {
    [super reset];
    if (self.delegate && [self.delegate respondsToSelector:@selector(countDownTimerRunOut)]) {
        [self.delegate countDownTimerRunOut];
    }
    self.curTimeIsValid = NO;
}

- (void)invalidate {
    [super reset];
    self.curTimeIsValid = NO;
}

- (UILabel *)titleL {
    if (!_titleL) {
        _titleL = [UILabel new];
        _titleL.textAlignment = NSTextAlignmentCenter;
    }
    return _titleL;
}

@end
