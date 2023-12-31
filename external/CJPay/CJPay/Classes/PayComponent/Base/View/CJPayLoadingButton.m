//
//  CJPayLoadingButton.m
//  CJPay
//
//  Created by liyu on 2019/10/29.
//

#import "CJPayLoadingButton.h"

#import "CJPayUIMacro.h"

@interface CJPayLoadingButton ()

@property (nonatomic, strong) UIImageView *activityIndicator;
@property (nonatomic, copy) NSString *originalTitleText;
@property (nullable, nonatomic, strong) UIImage *originalImage;
@property (nonatomic, strong) UILabel *visibleTitleLabel;//真正显示的标题
@property (nonatomic, copy) NSArray<NSString *> *titleSyncProperty;//标题同步的属性
@property (nonatomic, assign) BOOL isKVOInit;//防止KVO未注册就被移除，后续将采用ByteDanceKit方法

@end

@implementation CJPayLoadingButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _isKVOInit = NO;
        _disablesInteractionWhenLoading = YES;
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.activityIndicator];
    [self addSubview:self.visibleTitleLabel];
    CJPayMasMaker(self.visibleTitleLabel, {
        make.centerY.equalTo(self);
        make.centerX.equalTo(self);
    });
    self.activityIndicator.hidden = YES;
    // 隐藏原有titleLabel
    [self.titleLabel removeFromSuperview];
}

- (void)dealloc {
    if (self.isKVOInit) {
        for (NSString *property in self.titleSyncProperty) {
            [self.titleLabel removeObserver:self forKeyPath:property];
        }
    }
}

#pragma mark - CJPayBaseLoadingProtocol

- (void)startLoading {
    [self startLoadingWithWindowEnable:YES];
}

- (void)stopLoading {
    [self setTitle:self.originalTitleText forState:UIControlStateNormal];
    if (self.originalImage) {
        [self setImage:self.originalImage forState:UIControlStateNormal];
    }
    self.activityIndicator.hidden = YES;
    [self.activityIndicator.layer removeAllAnimations];
    self.activityIndicator.alpha = 1;
    self.visibleTitleLabel.hidden = NO;
    self.userInteractionEnabled = YES;

    if (self.disablesInteractionWhenLoading) {
        [self cj_responseViewController].view.userInteractionEnabled = YES;
        [self cj_responseViewController].view.window.userInteractionEnabled = YES;
    }
}

#pragma mark - Loading

- (void)startLoadingWithWindowEnable:(BOOL)windowEnable {
    self.originalTitleText = [self titleForState:UIControlStateNormal];
    self.originalImage = [self imageForState:UIControlStateNormal];
    [self setTitle:nil forState:UIControlStateNormal];
    [self setImage:nil forState:UIControlStateNormal];
    self.activityIndicator.hidden = NO;
    self.visibleTitleLabel.hidden = YES;
    CJPayMasReMaker(self.activityIndicator, {
        make.centerX.centerY.equalTo(self);
        make.width.height.mas_equalTo(24);
    });
    
    CABasicAnimation *rotateAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotateAnim.fromValue = @(0);
    rotateAnim.toValue = @(2 * CJPI);
    rotateAnim.repeatCount = INT_MAX;
    rotateAnim.speed = 0.5;
    rotateAnim.removedOnCompletion = NO;
    [self.activityIndicator.layer addAnimation:rotateAnim forKey:@"rotate"];

    if (self.disablesInteractionWhenLoading) {
        self.userInteractionEnabled = NO;
        [self cj_responseViewController].view.userInteractionEnabled = NO;
        [self cj_responseViewController].view.window.userInteractionEnabled = windowEnable;
    }
}

- (void)stopLoadingWithTitle:(NSString *)title {
    [self setTitle:CJString(title) forState:UIControlStateNormal];
    if (self.originalImage) {
        [self setImage:self.originalImage forState:UIControlStateNormal];
    }
    self.activityIndicator.hidden = YES;
    [self.activityIndicator.layer removeAllAnimations];
    self.activityIndicator.alpha = 1;
    self.visibleTitleLabel.hidden = NO;
    self.userInteractionEnabled = YES;

    if (self.disablesInteractionWhenLoading) {
        [self cj_responseViewController].view.userInteractionEnabled = YES;
        [self cj_responseViewController].view.window.userInteractionEnabled = YES;
    }
}

- (void)startRightLoading {
    self.activityIndicator.hidden = NO;
    CJPayMasReMaker(self.visibleTitleLabel, {
        make.centerY.equalTo(self);
        make.centerX.equalTo(self).offset(-12);
    });
    
    CJPayMasReMaker(self.activityIndicator, {
        make.centerY.equalTo(self);
        make.left.equalTo(self.visibleTitleLabel.mas_right).offset(4);
        make.width.height.mas_equalTo(20);
    });

    CABasicAnimation *rotateAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotateAnim.fromValue = @(0);
    rotateAnim.toValue = @(2 * CJPI);
    rotateAnim.repeatCount = INT_MAX;
    rotateAnim.speed = 0.5;
    rotateAnim.removedOnCompletion = NO;
    [self.activityIndicator.layer addAnimation:rotateAnim forKey:@"rotate"];

    if (self.disablesInteractionWhenLoading) {
        self.userInteractionEnabled = NO;
        [self cj_responseViewController].view.userInteractionEnabled = NO;
    }
}

- (void)stopRightLoading {
    self.activityIndicator.hidden = YES;
    self.userInteractionEnabled = YES;
    [self.activityIndicator.layer removeAllAnimations];
    CJPayMasReMaker(self.visibleTitleLabel, {
        make.centerY.equalTo(self);
        make.centerX.equalTo(self);
    });
    if (self.disablesInteractionWhenLoading) {
        [self cj_responseViewController].view.userInteractionEnabled = YES;
    }
}

- (void)stopRightLoadingWithTitle:(NSString *)title {
    [self setTitle:CJString(title) forState:UIControlStateNormal];
    self.activityIndicator.hidden = YES;
    [self.activityIndicator.layer removeAllAnimations];
    CJPayMasReMaker(self.visibleTitleLabel, {
        make.center.equalTo(self);
    });
    self.userInteractionEnabled = YES;
    if (self.disablesInteractionWhenLoading) {
        [self cj_responseViewController].view.userInteractionEnabled = YES;
    }
}

- (void)startLeftLoading {
    self.activityIndicator.hidden = NO;
    CJPayMasReMaker(self.activityIndicator, {
        make.centerY.equalTo(self);
        make.right.equalTo(self.visibleTitleLabel.mas_left).offset(-4);
        make.width.height.mas_equalTo(20);
    });
    
    CJPayMasReMaker(self.visibleTitleLabel, {
        make.centerY.equalTo(self);
        make.centerX.equalTo(self.mas_centerX).offset(12);
    });

    CABasicAnimation *rotateAnim = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotateAnim.fromValue = @(0);
    rotateAnim.toValue = @(2 * CJPI);
    rotateAnim.repeatCount = INT_MAX;
    rotateAnim.speed = 0.5;
    rotateAnim.removedOnCompletion = NO;
    [self.activityIndicator.layer addAnimation:rotateAnim forKey:@"rotate"];

    if (self.disablesInteractionWhenLoading) {
        [self cj_responseViewController].view.userInteractionEnabled = NO;
    }
}

- (void)stopLeftLoading {
    [self stopRightLoading];
    CJPayMasReMaker(self.visibleTitleLabel, {
        make.centerY.equalTo(self);
        make.centerX.equalTo(self);
    });
}

#pragma mark - KVO

-(void)observeValueForKeyPath:(NSString *)keyPath
                   ofObject:(id)object
                     change:(NSDictionary<NSString *,id> *)change
                    context:(void *)context {
    if ([self.titleSyncProperty containsObject:keyPath]) {
        [self.visibleTitleLabel setValue:[change valueForKey:NSKeyValueChangeNewKey] forKeyPath:keyPath];
    }
}

#pragma mark - Setter

- (void)setOriginalImage:(UIImage *)originalImage {
    if (originalImage) {
        _originalImage = originalImage;
    }
}

- (void)setOriginalTitleText:(NSString *)originalTitleText {
    if (originalTitleText) {
        _originalTitleText = originalTitleText;
    }
}

#pragma mark - Getter

- (UIImageView *)activityIndicator {
    if (!_activityIndicator) {
        _activityIndicator = [UIImageView new];
        [_activityIndicator cj_setImage:@"cj_loading_button_icon"];
    }
    return _activityIndicator;
}

- (UILabel *)visibleTitleLabel {
    if (!_visibleTitleLabel) {
        _visibleTitleLabel = [UILabel new];
        for (NSString *property in self.titleSyncProperty) {
            [self.titleLabel addObserver:self
                    forKeyPath:property
                       options:NSKeyValueObservingOptionNew
                       context:nil];
        }
        _isKVOInit = YES;
    }
    return _visibleTitleLabel;
}

- (NSArray<NSString *> *)titleSyncProperty {
    if (!_titleSyncProperty) {
        _titleSyncProperty = @[@"text",@"font",@"textColor",@"alpha",@"attributedText"];
    }
    return _titleSyncProperty;
}

@end
