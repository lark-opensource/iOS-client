//
//  CJPayOCRScanWindowView.m
//  CJPay
//
//  Created by 尚怀军 on 2020/5/13.
//

#import "CJPayOCRScanWindowView.h"
#import "CJPayUIMacro.h"

@interface CJPayOCRScanWindowView()

@property (nonatomic, strong) UIImageView *leftTopImageView;
@property (nonatomic, strong) UIImageView *leftBottomImageView;
@property (nonatomic, strong) UIImageView *rightTopImageView;
@property (nonatomic, strong) UIImageView *rightBottomImageView;

@property (nonatomic, strong) UIImageView *scanImageView;

@end

@implementation CJPayOCRScanWindowView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

-(void)p_setupUI {
    [self addSubview:self.scanImageView];
    [self addSubview:self.leftTopImageView];
    [self addSubview:self.leftBottomImageView];
    [self addSubview:self.rightBottomImageView];
    [self addSubview:self.rightTopImageView];
    
    CJPayMasMaker(self.leftTopImageView, {
        make.left.equalTo(self);
        make.top.equalTo(self);
        make.width.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.leftBottomImageView, {
        make.left.equalTo(self);
        make.bottom.equalTo(self);
        make.width.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.rightBottomImageView, {
        make.right.equalTo(self);
        make.bottom.equalTo(self);
        make.width.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.rightTopImageView, {
        make.right.equalTo(self);
        make.top.equalTo(self);
        make.width.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.scanImageView, {
        make.left.equalTo(self);
        make.top.equalTo(self);
        make.height.mas_equalTo(72);
        make.width.equalTo(self);
    });
}

- (void)showScanLineView:(BOOL)shouldShow {
    self.scanImageView.hidden = !shouldShow;
}

-(void)p_startScanAnimation {
    CGFloat height = self.cj_height - 32;
    
    CABasicAnimation *scanAnimation = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    scanAnimation.fromValue = @(-72);
    scanAnimation.toValue = @(height - 72);
        
    CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath: @"opacity"];
    opacityAnimation.values = [NSArray arrayWithObjects:@(0.0), @(1.0), @(1.0), @(0.0), nil];
    opacityAnimation.keyTimes = [NSArray arrayWithObjects:@(0.0), @(0.2), @(0.8), @(1.0), nil];
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.duration = 2.5;
    animationGroup.repeatCount = MAXFLOAT;
    [animationGroup setAnimations:[NSArray arrayWithObjects:scanAnimation, opacityAnimation, nil]];
    animationGroup.removedOnCompletion = NO;
    
    [self.scanImageView.layer addAnimation:animationGroup forKey:@"OCRScanAnimation"];
}

- (UIImageView *)leftTopImageView {
    if (!_leftTopImageView) {
        _leftTopImageView = [UIImageView new];
        [_leftTopImageView cj_setImage:@"cj_corner_icon"];
    }
    return _leftTopImageView;
}

- (UIImageView *)leftBottomImageView {
    if (!_leftBottomImageView) {
        _leftBottomImageView = [UIImageView new];
        [_leftBottomImageView cj_setImage:@"cj_corner_icon"];
        _leftBottomImageView.transform = CGAffineTransformRotate(_leftBottomImageView.transform, M_PI * 1.5);
    }
    return _leftBottomImageView;
}

- (UIImageView *)rightTopImageView {
    if (!_rightTopImageView) {
        _rightTopImageView = [UIImageView new];
        [_rightTopImageView cj_setImage:@"cj_corner_icon"];
        _rightTopImageView.transform = CGAffineTransformRotate(_rightTopImageView.transform, M_PI * 0.5);
    }
    return _rightTopImageView;
}

- (UIImageView *)rightBottomImageView {
    if (!_rightBottomImageView) {
        _rightBottomImageView = [UIImageView new];
        [_rightBottomImageView cj_setImage:@"cj_corner_icon"];
        _rightBottomImageView.transform = CGAffineTransformRotate(_rightBottomImageView.transform, M_PI);
    }
    return _rightBottomImageView;
}

- (UIImageView *)scanImageView {
    if (!_scanImageView) {
        _scanImageView = [UIImageView new];
        [_scanImageView cj_setImage:@"cj_ocr_scan_line_icon"];
    }
    return _scanImageView;
}

- (void)setBounds:(CGRect)bounds {//动画依赖self size
    [super setBounds:bounds];
    [self p_startScanAnimation];
}

@end
