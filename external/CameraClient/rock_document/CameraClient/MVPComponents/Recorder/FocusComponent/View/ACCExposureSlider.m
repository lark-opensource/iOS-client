//
//  ACCExposureSlider.m
//  CameraClient-Pods-Aweme
//
//  Created by guoshuai on 2020/11/10.
//

#import "ACCExposureSlider.h"

#import <CreativeKit/ACCMacros.h>

@interface ACCExposureSlider()

@property (nonatomic, assign) CGRect thumbBackgroundClearRect;

@property (nonatomic, strong) CAShapeLayer *minTrackMaskLayer;

@property (nonatomic, strong) CAShapeLayer *maxTrackMaskLayer;

@property (nonatomic, strong) UIView *originMinTrackView;

@property (nonatomic, strong) UIView *originMaxTrackView;

@property (nonatomic, strong) UIView *originThumbView;

@end

@implementation ACCExposureSlider

#pragma mark - LifeCycle

- (instancetype)init
{
    self = [super init];
    if (self) {
        _trackHeight = 1.0;
        _thumbSize = CGSizeMake(20, 20);
        _thumbBackgroundClear = NO;
        _thumbMargin = 5.0;
        _direction = ACCExposureSliderDirectionUp;
        _trackHidden = NO;
        _trackAlpha = 1.0;
    }

    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self updateSubViews];
}

#pragma mark - Override

- (CGRect)trackRectForBounds:(CGRect)bounds
{
    return CGRectMake(bounds.origin.x,
                      bounds.origin.y + (bounds.size.height - self.trackHeight) / 2,
                      bounds.size.width,
                      self.trackHeight);
}

- (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value
{
    float ratio;
    if (ACC_FLOAT_LESS_THAN(value, self.minimumValue) || ACC_FLOAT_GREATER_THAN(self.minimumValue, self.maximumValue)) {
        ratio = 0;
    } else {
        ratio = (value - self.minimumValue) / (self.maximumValue - self.minimumValue);
    }

    CGFloat realWidth = rect.size.width - self.thumbSize.width;
    CGFloat thumbX = rect.origin.x + ratio * realWidth;
    CGRect thumbRect = CGRectMake(thumbX,
                                  rect.origin.y + (self.trackHeight - self.thumbSize.height) / 2,
                                  self.thumbSize.width,
                                  self.thumbSize.height);
    if (self.thumbBackgroundClear) {
        self.thumbBackgroundClearRect = CGRectMake(thumbRect.origin.x - self.thumbMargin,
                                                   0,
                                                   thumbRect.size.width + self.thumbMargin * 2,
                                                   rect.size.height);
    }

    return thumbRect;
}

- (id)valueForUndefinedKey:(NSString *)key
{
    return nil;
}

#pragma mark - Public

- (void)setThumbScale:(CGFloat)scale
{
    if (self.originThumbView != nil) {
        self.originThumbView.transform = CGAffineTransformMakeScale(scale, scale);
    }
}

#pragma mark - Private

- (void)updateSubViews
{
    self.originMinTrackView.alpha = self.trackAlpha;
    self.originMaxTrackView.alpha = self.trackAlpha;

    if (self.trackHidden) {
        [self.originMinTrackView setHidden:YES];
        [self.originMaxTrackView setHidden:YES];
    } else {
        [self.originMaxTrackView setHidden:NO];
        [self.originMinTrackView setHidden:NO];
    }
}

- (void)p_updatePathForMaskLayer:(CAShapeLayer *)maskLayer withBounds:(CGRect)bounds insideRect:(CGRect)rect
{
    CGRect leftRect = CGRectMake(0, 0, rect.origin.x, bounds.size.height);
    CGRect rightRect = CGRectMake(rect.origin.x + rect.size.width,
                                  0,
                                  bounds.size.width - rect.origin.x - rect.size.width,
                                  bounds.size.height);
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:leftRect];
    [path appendPath:[UIBezierPath bezierPathWithRect:rightRect]];
    [path setUsesEvenOddFillRule:YES];
    maskLayer.path = [path CGPath];
}

#pragma mark - Setter

- (void)setDirection:(ACCExposureSliderDirection)direction
{
    _direction = direction;
    CGFloat angle = 0;
    switch (direction) {
        case ACCExposureSliderDirectionUp:
            angle = -M_PI / 2;
            break;
        case ACCExposureSliderDirectionRight:
            angle = 0;
            break;
        case ACCExposureSliderDirectionDown:
            angle = M_PI / 2;
            break;
        case ACCExposureSliderDirectionLeft:
            angle = M_PI;
            break;
    }

    self.transform = CGAffineTransformRotate(self.transform, angle);
}

- (void)setThumbBackgroundClear:(BOOL)thumbBackgroundClear
{
    _thumbBackgroundClear = thumbBackgroundClear;
    if (thumbBackgroundClear) {
        self.minTrackMaskLayer = [CAShapeLayer layer];
        [self p_updatePathForMaskLayer:self.minTrackMaskLayer
                            withBounds:self.originMinTrackView.bounds
                            insideRect:self.thumbBackgroundClearRect];
        self.minTrackMaskLayer.fillRule = kCAFillRuleEvenOdd;
        if (self.originMinTrackView != nil) {
            self.originMinTrackView.layer.mask = self.minTrackMaskLayer;
        }

        self.maxTrackMaskLayer = [CAShapeLayer layer];
        [self p_updatePathForMaskLayer:self.maxTrackMaskLayer
                            withBounds:self.originMaxTrackView.bounds
                            insideRect:self.thumbBackgroundClearRect];
        self.maxTrackMaskLayer.fillRule = kCAFillRuleEvenOdd;
        if (self.originMaxTrackView != nil) {
            self.originMaxTrackView.layer.mask = self.maxTrackMaskLayer;
        }
    } else {
        self.minTrackMaskLayer = nil;
        self.maxTrackMaskLayer = nil;
        self.originMinTrackView.layer.mask = nil;
        self.originMaxTrackView.layer.mask = nil;
    }
}

- (void)setThumbBackgroundClearRect:(CGRect)thumbBackgroundClearRect
{
    _thumbBackgroundClearRect = thumbBackgroundClearRect;
    if (self.thumbBackgroundClear) {
        [self p_updatePathForMaskLayer:self.minTrackMaskLayer
                            withBounds:self.originMinTrackView.bounds
                            insideRect:self.thumbBackgroundClearRect];
        if (self.originMinTrackView != nil) {
            self.originMinTrackView.layer.mask = self.minTrackMaskLayer;
        }

        [self p_updatePathForMaskLayer:self.maxTrackMaskLayer
                            withBounds:self.originMaxTrackView.bounds
                            insideRect:self.thumbBackgroundClearRect];
        if (self.originMaxTrackView != nil) {
            self.originMaxTrackView.layer.mask = self.maxTrackMaskLayer;
        }
    }
}

- (void)setTrackHidden:(BOOL)trackHidden
{
    _trackHidden = trackHidden;
    [self updateSubViews];
}

- (void)setTrackAlpha:(CGFloat)alpha
{
    CGFloat newAlpha = alpha > 1.0 ? 1.0 : (alpha < 0.0 ? 0.0 : alpha);
    _trackAlpha = newAlpha;
    self.originMaxTrackView.alpha = newAlpha;
    self.originMinTrackView.alpha = newAlpha;
}

#pragma mark - Getter

- (CGFloat)trackHeight
{
    if (_trackHeight < 0.1) {
        return 0.1;
    } else {
        return _trackHeight;
    }
}

- (UIView *)originMinTrackView
{
    if (_originMinTrackView != nil) {
        return _originMinTrackView;
    }

    id originMinTrackView = [self valueForKey:@"minTrackView"];
    if (originMinTrackView != nil && [originMinTrackView isKindOfClass:[UIView class]]) {
        _originMinTrackView = (UIView *)originMinTrackView;
        return _originMinTrackView;
    } else {
        return nil;
    }
}

- (UIView *)originMaxTrackView
{
    if (_originMaxTrackView != nil) {
        return _originMaxTrackView;
    }

    id originMaxTrackView = [self valueForKey:@"maxTrackView"];
    if (originMaxTrackView != nil && [originMaxTrackView isKindOfClass:[UIView class]]) {
        _originMaxTrackView = (UIView *)originMaxTrackView;
        return _originMaxTrackView;
    } else {
        return nil;
    }
}

- (UIView *)originThumbView
{
    if (_originThumbView != nil) {
        return _originThumbView;
    }

    id originThumbView = [self valueForKey:@"thumbView"];
    if (originThumbView != nil && [originThumbView isKindOfClass:[UIView class]]) {
        _originThumbView = (UIView *)originThumbView;
        return _originThumbView;
    } else {
        return nil;
    }
}

@end
