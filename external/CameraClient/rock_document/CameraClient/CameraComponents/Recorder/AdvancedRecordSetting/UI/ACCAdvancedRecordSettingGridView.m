//
//  ACCAdvancedRecordSettingGridView.m
//  Indexer
//
//  Created by Shichen Peng on 2021/11/8.
//

#import "ACCAdvancedRecordSettingGridView.h"
#import <CreativeKit/UIColor+CameraClientResource.h>

@interface ACCAdvancedRecordSettingGridView ()
@property (nonatomic, strong) UIBezierPath *path;
@property (nonatomic, strong) CAShapeLayer *drawLayer;

@end

@implementation ACCAdvancedRecordSettingGridView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.numOfseparation = 3;
        self.lineWidth = 1.0;
        [self drawLine];
    }
    return self;
}

- (void)updateGrid
{
    [self.path removeAllPoints];
    [self.drawLayer removeFromSuperlayer];
    [self drawLine];
}

- (void)drawLine
{
    if (self.numOfseparation == 0) {
        return;
    }
    CGFloat lineSeparationWidth = self.frame.size.width / self.numOfseparation;
    CGFloat lineSeparationHeight = self.frame.size.height / self.numOfseparation;
    // Vertical line
    for (int i = 1; i < self.numOfseparation; i++) {
        CGPoint start = CGPointMake(i * lineSeparationWidth, 0);
        CGPoint end = CGPointMake(i * lineSeparationWidth, self.frame.size.height);
        [self.path moveToPoint:start];
        [self.path addLineToPoint:end];
    }
    // Horizontal line
    for (int i = 1; i < self.numOfseparation; i++) {
        CGPoint start = CGPointMake(0, i * lineSeparationHeight);
        CGPoint end = CGPointMake(self.frame.size.width, i * lineSeparationHeight);
        [self.path moveToPoint:start];
        [self.path addLineToPoint:end];
    }
    
    CAShapeLayer *layer = [[CAShapeLayer alloc] init];
    layer.path = self.path.CGPath;
    layer.strokeColor = [[UIColor acc_colorWithColorName:ACCColorConstTextInverse5] colorWithAlphaComponent:0.3].CGColor;
    layer.lineWidth = self.lineWidth;
    
    [self.layer addSublayer:layer];
    self.drawLayer = layer;
}

- (UIBezierPath *)path
{
    if (!_path) {
        _path = [UIBezierPath bezierPath];
    }
    return _path;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *targetView = [super hitTest:point withEvent:event];
    if (targetView == self) {
        return nil;
    }
    return targetView;
}

@end
