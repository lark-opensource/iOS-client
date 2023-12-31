//
//  CJPayVerifyCodeTimerLabel.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/19.
//

#import "CJPayVerifyCodeTimerLabel.h"
#import "CJPayUIMacro.h"

@interface CJPayVerifyCodeTimerLabel ()

@property (nonatomic, copy) NSString *silentTitle;
@property (nonatomic, copy) NSString *dynamicTitle;
@property (nonatomic, strong) UIColor *silentColor;
@property (nonatomic, strong) UIColor *dynamicColor;

@end

@implementation CJPayVerifyCodeTimerLabel

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)configTimerLabel:(NSString *)dynamicTitle silentT:(NSString *)silentTitle dynamicColor:(UIColor *)dynamicColor silentColor:(UIColor *)silentColor {
    _silentTitle = silentTitle;
    _dynamicTitle = dynamicTitle;
    _silentColor = silentColor;
    _dynamicColor = dynamicColor;
    [self contentChange];
    [self reset];
}

- (void)setupUI {
    self.titleLabel.textAlignment = NSTextAlignmentRight;
    self.titleLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)reset {
    [super reset];
    [self setTitle:self.silentTitle forState:UIControlStateNormal];
    [self cj_setBtnTitleColor:self.silentColor ?: [UIColor cj_2c2f36ff]];
    CJ_CALL_BLOCK(self.timeRunOutBlock);
    [self contentChange];
}

-(void)startTimerWithCountTime:(int)countTime {
    [super startTimerWithCountTime:countTime];
    [self cj_setBtnTitleColor:self.dynamicColor ?: [UIColor cj_c8cad0ff]];
    [self contentChange];
}

-(void)currentCountChangeTo:(int)value{
    [super currentCountChangeTo:value];
    if (value <= 0) {
        [self reset];
    } else {
        [self setTitle:[NSString stringWithFormat:self.dynamicTitle, value] forState:UIControlStateNormal];
    }
}

- (void)contentChange{
    if (self.sizeChangedTo) {
        self.sizeChangedTo(self.intrinsicContentSize);
    }
}

@end
