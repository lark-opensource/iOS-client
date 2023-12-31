//
//  CJPayBaseLoadingView.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/23.
//

#import "CJPayBaseLoadingView.h"
#import "CJPayUIMacro.h"

@interface CJPayBaseLoadingView()

@property (nonatomic, strong) UIImageView *loadingIconView;
@property (nonatomic, strong) UILabel *stateLabel;

@end

@implementation CJPayBaseLoadingView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    self.hidden = YES;
    self.loadingContainerView = [UIView new];
    self.loadingContainerView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8f];
    self.loadingContainerView.layer.cornerRadius = 6;
    
    self.loadingIconView = [UIImageView new];
    [self.loadingIconView cj_setImage:@"cj_web_loading_icon"];
    
    self.stateLabel = [UILabel new];
    self.stateLabel.textAlignment = NSTextAlignmentCenter;
    self.stateLabel.textColor = [UIColor whiteColor];
    self.stateLabel.font = [UIFont cj_fontOfSize:17];
    self.stateLabel.text = CJPayLocalizedStr(@"加载中...");
    
    [self addSubview:self.loadingContainerView];
    CJPayMasMaker(self.loadingContainerView, {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self).offset(-CJ_STATUS_AND_NAVIGATIONBAR_HEIGHT / 2);
        make.width.mas_greaterThanOrEqualTo(108);
        make.height.mas_greaterThanOrEqualTo(81);
    });
    
    [self.loadingContainerView addSubview:self.loadingIconView];
    [self.loadingContainerView addSubview:self.stateLabel];
    
    CJPayMasMaker(self.loadingIconView, {
        make.centerX.equalTo(self.loadingContainerView);
        make.width.height.mas_equalTo(24);
        make.top.equalTo(self.loadingContainerView).offset(16);
    });
    
    CJPayMasMaker(self.stateLabel, {
        make.left.equalTo(self.loadingContainerView).offset(12);
        make.right.equalTo(self.loadingContainerView).offset(-12);
        make.top.equalTo(self.loadingIconView.mas_bottom).offset(7);
        make.bottom.lessThanOrEqualTo(self.loadingContainerView).offset(-16);
    });
    
    self.backgroundColor = UIColor.clearColor;
}

- (void)startAnimating {
    self.hidden = NO;
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    animation.fromValue = @(0.0f);
    animation.toValue = @(M_PI * 2);
    animation.duration = 0.6;
    animation.repeatCount = MAXFLOAT;
    [self.loadingIconView.layer addAnimation:animation forKey:nil];
}

- (void)stopAnimating {
    self.hidden = YES;
    [self.loadingIconView.layer removeAllAnimations];
}

- (void)setStateDescText:(NSString *)stateDescText {
    _stateDescText = stateDescText;
    if (Check_ValidString(stateDescText)) {
        self.stateLabel.text = stateDescText;
    }
}

@end
