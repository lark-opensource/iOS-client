//
//  OPVideoControlSlider.m
//  OPPluginBiz
//
//  Created by zhujingcheng on 2/12/23.
//

#import "OPVideoControlSlider.h"
#import <OPFoundation/UIImage+EMA.h>
#import <Masonry/Masonry.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>

@interface OPVideoControlSlider () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UISlider *controlSlider;
@property (nonatomic, strong) UIProgressView *bufferingProgress;
@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGesture;

@end

@implementation OPVideoControlSlider

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.controlSlider.frame = self.bounds;
    self.bufferingProgress.frame = [self.controlSlider trackRectForBounds:self.controlSlider.frame];
    self.longPressGesture.allowableMovement = self.controlSlider.bounds.size.width;
}

- (void)setup {
    [self addSubview:self.bufferingProgress];
    [self addSubview:self.controlSlider];
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanGestureRecognized:)];
    panGesture.delegate = self;
    [self addGestureRecognizer:panGesture];
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressGestureRecognized:)];
    longPressGesture.minimumPressDuration = 0.1;
    longPressGesture.delegate = self;
    [self addGestureRecognizer:longPressGesture];
    self.longPressGesture = longPressGesture;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTapGestureRecognized:)];
    tapGesture.delegate = self;
    [self addGestureRecognizer:tapGesture];
}

- (void)onPanGestureRecognized:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.controlSlider];
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self.delegate videoSliderTouchBegan:self.controlSlider.value];
            break;
        case UIGestureRecognizerStateChanged: {
            CGFloat targetValue = MIN(MAX(self.controlSlider.value + translation.x / self.controlSlider.bounds.size.width, 0), 1);
            self.controlSlider.value = targetValue;
            [self.delegate videoSliderValueChanged:targetValue];
        }
            break;
        case UIGestureRecognizerStateEnded:
            [self.delegate videoSliderTouchEnded:self.controlSlider.value];
            break;
        default:
            break;
    }
    [recognizer setTranslation:CGPointZero inView:self.controlSlider];
}

- (void)onLongPressGestureRecognized:(UILongPressGestureRecognizer *)recognizer {
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self.delegate videoSliderTouchBegan:self.controlSlider.value];
            break;
        case UIGestureRecognizerStateChanged: {
            CGPoint touchLocation = [recognizer locationInView:self.controlSlider];
            CGRect trackRect = [self.controlSlider trackRectForBounds:self.controlSlider.bounds];
            CGRect thumbRect = [self.controlSlider thumbRectForBounds:self.controlSlider.bounds trackRect:trackRect value:self.controlSlider.value];
            CGFloat moveMent = touchLocation.x - (thumbRect.origin.x + thumbRect.size.width / 2);
            CGFloat targetValue = MIN(MAX(self.controlSlider.value + moveMent / self.controlSlider.bounds.size.width, 0), 1);
            self.controlSlider.value = targetValue;
            [self.delegate videoSliderValueChanged:targetValue];
        }
            break;
        case UIGestureRecognizerStateEnded:
            [self.delegate videoSliderTouchEnded:self.controlSlider.value];
            break;
        default:
            break;
    }
}

- (void)onSingleTapGestureRecognized:(UITapGestureRecognizer *)recognizer {
    [self.delegate videoSliderSingleTapGestureRecognized:recognizer];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGRect trackRect = [self.controlSlider trackRectForBounds:self.controlSlider.bounds];
    CGRect thumbRect = [self.controlSlider thumbRectForBounds:self.controlSlider.bounds trackRect:trackRect value:self.controlSlider.value];
    CGRect area = CGRectInset(thumbRect, -2, -2);
    CGPoint touchLocation = [touch locationInView:self];
    BOOL isInThumbArea = CGRectContainsPoint(area, touchLocation);
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] || [gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return isInThumbArea;
    }
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return !isInThumbArea;
    }
    return NO;
}

#pragma mark - Public

- (void)showDraggingTime:(NSString *)time {
    if (BTD_isEmptyString(time)) {
        return;
    }
    if (!self.timeLabel) {
        self.timeLabel = [[UILabel alloc] init];
        self.timeLabel.font = [UIFont monospacedDigitSystemFontOfSize:14 weight:UIFontWeightRegular];
        self.timeLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.timeLabel];
    }
    NSMutableAttributedString *timeStr = [[NSMutableAttributedString alloc] initWithString:time];
    NSUInteger index = [time rangeOfString:@"/"].location;
    [timeStr addAttribute:NSForegroundColorAttributeName value:[UIColor btd_colorWithHexString:@"#F0F0F0"] range:NSMakeRange(0, index)];
    [timeStr addAttribute:NSForegroundColorAttributeName value:[UIColor btd_colorWithHexString:@"#A6A6A6"] range:NSMakeRange(index, time.length - index)];
    self.timeLabel.attributedText = timeStr;
    CGRect trackRect = [self.controlSlider trackRectForBounds:self.controlSlider.bounds];
    CGRect thumbRect = [self.controlSlider thumbRectForBounds:self.controlSlider.bounds trackRect:trackRect value:self.controlSlider.value];
    CGFloat width = 90;
    CGFloat height = 22;
    CGFloat maxOriginX = trackRect.size.width - width;
    CGFloat originX = thumbRect.origin.x + thumbRect.size.width / 2 - width / 2;
    if (originX < 0) {
        originX = 0;
    } else if (originX > maxOriginX) {
        originX = maxOriginX;
    }
    CGFloat originY = -12 - height;
    self.timeLabel.frame = CGRectMake(originX, originY, width, height);
}

- (void)hideDraggingTime {
    [self.timeLabel removeFromSuperview];
    self.timeLabel = nil;
}

- (void)updateBufferingProgress:(CGFloat)bufferingProgress {
    [self.bufferingProgress setProgress:bufferingProgress];
}

- (void)highlightSlider:(BOOL)highlight {
    self.controlSlider.highlighted = highlight;
}

- (void)updateCurrentValue:(CGFloat)value {
    self.controlSlider.value = value;
}

- (CGFloat)currentValue {
    return self.controlSlider.value;
}

- (void)reset {
    self.controlSlider.value = 0;
    self.bufferingProgress.progress = 0;
    [self hideDraggingTime];
}

#pragma mark - Getter

- (UISlider *)controlSlider {
    if (!_controlSlider) {
        _controlSlider = [[UISlider alloc] init];
        _controlSlider.userInteractionEnabled = NO;
        _controlSlider.minimumTrackTintColor = [UIColor btd_colorWithHexString:@"#3370FF"];
        _controlSlider.maximumTrackTintColor = UIColor.clearColor;
        [_controlSlider setThumbImage:[self normalThumbImage] forState:UIControlStateNormal];
        [_controlSlider setThumbImage:[self highlightedThumbImage] forState:UIControlStateHighlighted];
    }
    return _controlSlider;
}

- (UIProgressView *)bufferingProgress {
    if (!_bufferingProgress) {
        _bufferingProgress = [[UIProgressView alloc] init];
        _bufferingProgress.trackTintColor = [UIColor btd_colorWithHexString:@"#D0D3D6"];
        _bufferingProgress.progressTintColor = UIColor.whiteColor;
    }
    return _bufferingProgress;
}

- (UIImage *)normalThumbImage {
    CGRect rect = CGRectMake(0, 0, 12, 12);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, UIColor.whiteColor.CGColor);
    CGContextFillEllipseInRect(context, rect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (UIImage *)highlightedThumbImage {
    CGRect rect = CGRectMake(0, 0, 28, 28);
    CGRect borderRect = CGRectInset(rect, 8, 8);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, UIColor.whiteColor.CGColor);
    CGContextSetStrokeColorWithColor(context, [UIColor btd_colorWithHexString:@"#5B8DFF80"].CGColor);
    CGContextSetLineWidth(context, 16);
    CGContextStrokeEllipseInRect(context, borderRect);
    CGContextFillEllipseInRect(context, borderRect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

@end
