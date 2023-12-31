//
//  AWECircularProgressView.m
//  Pods
//
//  Created by jindulys on 2019/5/13.
//

#import "AWECircularProgressView.h"

#import <CreativeKit/ACCMacros.h>
#import <KVOController/NSObject+FBKVOController.h>

@interface _AWECircularProgressViewKVOObject : NSObject

@property (nonatomic, assign) CGFloat progress;

@property (nonatomic, strong) UIColor *progressTintColor;

@property (nonatomic, strong) UIColor *progressBackgroundColor;

@property (nonatomic, assign) CGFloat lineWidth;

@property (nonatomic, assign) CGFloat backgroundWidth;

@end

@implementation _AWECircularProgressViewKVOObject

@end

@interface AWECircularProgressView ()

@property (nonatomic, strong) _AWECircularProgressViewKVOObject *kvoObject;

@end

@implementation AWECircularProgressView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        _kvoObject = [_AWECircularProgressViewKVOObject new];
        _progressBackgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.3];
        _progressTintColor = [UIColor whiteColor];
        [self setupObservers];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    UIBezierPath *progressBackgroundPath = [UIBezierPath bezierPath];
    progressBackgroundPath.lineWidth = self.backgroundWidth;
    progressBackgroundPath.lineCapStyle = kCGLineCapRound;
    CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
    CGFloat radius = (self.progressRadius != 0) ? self.progressRadius : ((MIN(self.bounds.size.width, self.bounds.size.height) - self.backgroundWidth) / 2);
    CGFloat startAngle = - (M_PI / 2);
    CGFloat endAngle = (2 * M_PI) + startAngle;
    [progressBackgroundPath addArcWithCenter:center radius:radius startAngle:startAngle endAngle:endAngle clockwise:YES];
    [self.progressBackgroundColor set];
    [progressBackgroundPath stroke];
    
    UIBezierPath *progressPath = [UIBezierPath bezierPath];
    progressPath.lineWidth = self.lineWidth;
    progressPath.lineCapStyle = kCGLineCapRound;
    endAngle = (self.progress * 2 * M_PI) + startAngle;

    [progressPath addArcWithCenter:center radius:(_backgroundRadius != 0 ? _backgroundRadius : radius) startAngle:startAngle endAngle:endAngle clockwise:YES];
    [self.progressTintColor set];
    [progressPath stroke];
}

#pragma mark - Setter

- (void)setProgress:(CGFloat)progress
{
    _progress = progress;
    self.kvoObject.progress = progress;
}

- (void)setProgressTintColor:(UIColor *)progressTintColor
{
    _progressTintColor = progressTintColor;
    self.kvoObject.progressTintColor = progressTintColor;
}

- (void)setProgressBackgroundColor:(UIColor *)progressBackgroundColor
{
    _progressBackgroundColor = progressBackgroundColor;
    self.kvoObject.progressBackgroundColor = progressBackgroundColor;
}

- (void)setLineWidth:(CGFloat)lineWidth
{
    _lineWidth = lineWidth;
    self.kvoObject.lineWidth = lineWidth;
}

- (void)setBackgroundWidth:(CGFloat)backgroundWidth
{
    _backgroundWidth = backgroundWidth;
    self.kvoObject.backgroundWidth = backgroundWidth;
}

#pragma mark - Private

- (void)setupObservers
{
    @weakify(self);
    for (NSString *keypath in [self observableKeypaths]) {
        [self.KVOController observe:self.kvoObject
                            keyPath:keypath
                            options:NSKeyValueObservingOptionNew
                              block:^(typeof(self) _Nullable observer, id object,NSDictionary<NSString *, id> *_Nonnull change) {
                                  @strongify(self);
                                  [self setNeedsDisplay];
                              }];
    }
}

- (NSArray *)observableKeypaths
{
    return @[NSStringFromSelector(@selector(progress)),
             NSStringFromSelector(@selector(progressTintColor)),
             NSStringFromSelector(@selector(progressBackgroundColor)),
             NSStringFromSelector(@selector(lineWidth)),
             NSStringFromSelector(@selector(backgroundWidth))];
}

@end
