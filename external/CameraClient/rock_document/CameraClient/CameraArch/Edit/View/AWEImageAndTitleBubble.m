//
//  AWEImageAndTitleBubble.m
//  Pods
//
//  Created by li xingdong on 2019/7/2.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEImageAndTitleBubble.h"
#import <CameraClient/UIView+ACCBubbleAnimation.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>

#define AWEStudioBubbleArrowWidth   13.0
#define AWEStudioBubbleArrowHeight  6.5
#define AWEStudioBubbleHeight       66.5
#define AWEStudioBubbleMaxWidth     (ACC_SCREEN_WIDTH - 168.0)
#define AWEStudioBubbleInsetWidth   8.0
#define AWEStudioBubbleImageWidth   44.0
#define AWEStudioBubbleMinOffset    16.0
#define AWEStudioBubbleRadius       8.0

@interface AWEImageAndTitleBubble()

@property (nonatomic, strong) UIView *bgView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, weak) UIView *containerView;

//用来描边
@property (nonatomic, strong) CAShapeLayer *stroke;

@property (nonatomic, assign) CGPoint adjustPoint;
@property (nonatomic, assign) BOOL isDarkBackGround;
@property (nonatomic, assign) AWEImageAndTitleBubbleDirection direction;

@property (nonatomic, assign) CGPoint scaleAnchorPoint;

@end

@implementation AWEImageAndTitleBubble

- (instancetype)initWithTitle:(NSString *)title
                     subTitle:(NSString *)subTitle
                        image:(UIImage *)image
                      forView:(UIView *)view
              inContainerView:(UIView *)containerView
             anchorAdjustment:(CGPoint)adjustPoint
                    direction:(AWEImageAndTitleBubbleDirection)direction
             isDarkBackGround:(BOOL)isDarkBackGround
{
    self = [super init];
    if (self) {
        self.containerView = containerView;
        self.adjustPoint = adjustPoint;
        self.direction = direction;
        self.isDarkBackGround = isDarkBackGround;
        if (!containerView) {
            self.containerView = view.superview;
        }
        self.backgroundColor = ACCResourceColor(ACCUIColorConstSDPrimary);
        self.layer.masksToBounds = YES;
        self.hidden = YES;
        
        [self setupUIWithTitle:title subTitle:subTitle image:image forView:view anchorAdjustment:adjustPoint direction:direction];
    }
    
    return self;
}

- (void)setupUIWithTitle:(NSString *)title
                subTitle:(NSString *)subTitle
                   image:(UIImage *)image
                 forView:(UIView *)view
        anchorAdjustment:(CGPoint)adjustPoint
               direction:(AWEImageAndTitleBubbleDirection)direction
{
    self.titleLabel.text = title;
    self.subTitleLabel.text = subTitle;
    self.imageView.image = image;
    
    CGFloat titleWidth = MAX([self widthOfTitle:self.titleLabel.text], [self widthOfSubTitle:self.subTitleLabel.text]);
    CGFloat bgWidth = titleWidth + 3 * AWEStudioBubbleInsetWidth + AWEStudioBubbleImageWidth;
    CGFloat bgHeight = AWEStudioBubbleHeight - AWEStudioBubbleArrowHeight;
    
    CGRect viewFrame = [view.superview convertRect:view.frame toView:self.containerView];
    CGRect bgFrame = CGRectMake(0, 0, bgWidth, bgHeight);
    CGRect frame = CGRectMake(0, 0, bgWidth, AWEStudioBubbleHeight);
    
    CGPoint anchorPoint = CGPointZero;
    
    switch (direction) {
        case AWEImageAndTitleBubbleDirectionUp:
        {
            frame.origin.x = CGRectGetMidX(viewFrame) - bgWidth / 2.0;
            if (frame.origin.x < AWEStudioBubbleMinOffset) {
                frame.origin.x = AWEStudioBubbleMinOffset;
            } else if (frame.origin.x + bgWidth > ACC_SCREEN_WIDTH - AWEStudioBubbleMinOffset) {
                frame.origin.x = ACC_SCREEN_WIDTH - bgWidth - AWEStudioBubbleMinOffset;
            }
            
            frame.origin.y = CGRectGetMinY(viewFrame) + adjustPoint.y - AWEStudioBubbleHeight;
            
            anchorPoint.x = CGRectGetMidX(viewFrame) - CGRectGetMinX(frame) - adjustPoint.x;
            anchorPoint.y = AWEStudioBubbleHeight;
        }
            break;
            
        case AWEImageAndTitleBubbleDirectionDown:
        {
            bgFrame.origin.y += AWEStudioBubbleArrowHeight;
            
            frame.origin.x = CGRectGetMidX(viewFrame) - bgWidth / 2.0;
            if (frame.origin.x < AWEStudioBubbleMinOffset) {
                frame.origin.x = AWEStudioBubbleMinOffset;
            } else if (frame.origin.x + bgWidth > ACC_SCREEN_WIDTH - AWEStudioBubbleMinOffset) {
                frame.origin.x = ACC_SCREEN_WIDTH - bgWidth - AWEStudioBubbleMinOffset;
            }

            frame.origin.y = CGRectGetMaxY(viewFrame) - adjustPoint.y;
            
            anchorPoint.x = CGRectGetMidX(viewFrame) - CGRectGetMinX(frame) - adjustPoint.x;
            anchorPoint.y = 0;
        }
            break;
            
        case AWEImageAndTitleBubbleDirectionLeft:
        {
            frame.size.width = bgWidth + AWEStudioBubbleArrowHeight;
            frame.size.height = bgHeight;
            
            frame.origin.y = CGRectGetMidY(viewFrame) - bgHeight / 2.0;
            if (frame.origin.y < AWEStudioBubbleMinOffset) {
                frame.origin.y = AWEStudioBubbleMinOffset;
            } else if (frame.origin.y + bgHeight > ACC_SCREEN_HEIGHT - AWEStudioBubbleMinOffset) {
                frame.origin.y = ACC_SCREEN_HEIGHT - bgHeight - AWEStudioBubbleMinOffset;
            }
            
            frame.origin.x = CGRectGetMinX(viewFrame) - adjustPoint.x - bgWidth - AWEStudioBubbleArrowHeight;
            
            anchorPoint.x = bgWidth + AWEStudioBubbleArrowHeight;
            anchorPoint.y = bgHeight / 2.0 + adjustPoint.y;
        }
            break;
        case AWEImageAndTitleBubbleDirectionRight:
        {
            frame.size.width = bgWidth + AWEStudioBubbleArrowHeight;
            frame.size.height = bgHeight;
            
            bgFrame.origin.x += AWEStudioBubbleArrowHeight;
            
            frame.origin.y = CGRectGetMidY(viewFrame) - bgHeight / 2.0;
            if (frame.origin.y < AWEStudioBubbleMinOffset) {
                frame.origin.y = AWEStudioBubbleMinOffset;
            } else if (frame.origin.y + bgHeight > ACC_SCREEN_HEIGHT - AWEStudioBubbleMinOffset) {
                frame.origin.y = ACC_SCREEN_HEIGHT - bgHeight - AWEStudioBubbleMinOffset;
            }
            
            frame.origin.x =  CGRectGetMaxX(viewFrame) + adjustPoint.x;
            
            anchorPoint.x = 0;
            anchorPoint.y = bgHeight / 2.0 + adjustPoint.y;
        }
            break;
    }
    
    // 箭头特殊情况处理
    if (AWEImageAndTitleBubbleDirectionUp == direction || AWEImageAndTitleBubbleDirectionDown == direction) {
        if (anchorPoint.x > (bgWidth - AWEStudioBubbleRadius - AWEStudioBubbleArrowWidth / 2.0)) {
            // 箭头太偏右
            frame.origin.x += anchorPoint.x - (bgWidth - AWEStudioBubbleRadius - AWEStudioBubbleArrowWidth / 2.0);
            anchorPoint.x = CGRectGetMidX(viewFrame) - CGRectGetMinX(frame) - adjustPoint.x;
        } else if (anchorPoint.x < AWEStudioBubbleRadius + AWEStudioBubbleArrowWidth / 2.0) {
            // 箭头太偏左
            frame.origin.x -= AWEStudioBubbleRadius + AWEStudioBubbleArrowWidth / 2.0 - anchorPoint.x;
            anchorPoint.x = CGRectGetMidX(viewFrame) - CGRectGetMinX(frame) - adjustPoint.x;
        }
    } else {
        if (anchorPoint.y > (bgHeight - AWEStudioBubbleRadius - AWEStudioBubbleArrowWidth / 2.0)) {
            // 箭头太偏下
            frame.origin.y += anchorPoint.y - (bgHeight - AWEStudioBubbleRadius - AWEStudioBubbleArrowWidth / 2.0);
            anchorPoint.y = bgHeight / 2.0 - adjustPoint.y;
        } else if (anchorPoint.y < AWEStudioBubbleRadius + AWEStudioBubbleArrowWidth / 2.0) {
            // 箭头太偏上
            frame.origin.y -= AWEStudioBubbleRadius + AWEStudioBubbleArrowWidth / 2.0 - anchorPoint.y;
            anchorPoint.y = bgHeight / 2.0 - adjustPoint.y;
        }
    }
    
    self.frame = frame;
    self.bgView.frame = bgFrame;
    self.scaleAnchorPoint = anchorPoint;
    
    [self addSubview:self.bgView];
    [self setupBgViewWithTitleWidth:titleWidth];
    [self makeMaskLayerWithDirection:direction anchorPoint:anchorPoint];
}

- (void)setupBgViewWithTitleWidth:(CGFloat)titleWidth
{
    [self.bgView addSubview:self.imageView];
    [self.bgView addSubview:self.titleLabel];
    [self.bgView addSubview:self.subTitleLabel];
    
    ACCMasMaker(self.imageView, {
        make.leading.top.equalTo(self.bgView).offset(AWEStudioBubbleInsetWidth);
        make.size.mas_equalTo(CGSizeMake(AWEStudioBubbleImageWidth, AWEStudioBubbleImageWidth));
    });
    
    ACCMasMaker(self.titleLabel, {
        make.top.equalTo(self.bgView).offset(11.0);
        make.leading.equalTo(self.imageView.mas_trailing).offset(AWEStudioBubbleInsetWidth);
        make.size.mas_equalTo(CGSizeMake(titleWidth, 18.0));
    });
    
    ACCMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(4.0);
        make.leading.equalTo(self.titleLabel.mas_leading);
        make.size.mas_equalTo(CGSizeMake(titleWidth, 16.0));
    });
}

- (void)showWithAnimated:(BOOL)animated
{
    if (![self superview]) {
        [self.containerView addSubview:self];
    }

    if (animated) {
        self.hidden = NO;
        [self animationForShow:YES completion:nil];
    } else {
        self.hidden = NO;
    }
}

- (void)dismissWithAnimated:(BOOL)animated
{
    if (animated) {
        [self animationForShow:NO completion:^{
            self.hidden = YES;
            [self removeFromSuperview];
        }];
    } else {
        self.hidden = YES;
        [self removeFromSuperview];
    }
}

- (void)animationForShow:(BOOL)isShow completion:(void (^)(void))completion
{
    CGFloat xAddtion = 0, yAddition = 0;
    CGFloat xOffset = self.scaleAnchorPoint.x - CGRectGetWidth(self.frame) / 2.0 - self.adjustPoint.x;
    CGFloat yOffset = self.scaleAnchorPoint.y - CGRectGetHeight(self.frame) / 2.0 - self.adjustPoint.y;
    
    switch (self.direction) {
        case AWEImageAndTitleBubbleDirectionUp:
        {
            xAddtion = 0;
            yAddition = - 10;
            break;
        }
        case AWEImageAndTitleBubbleDirectionDown:
        {
            xAddtion = 0;
            yAddition = 10;
            break;
        }
        case AWEImageAndTitleBubbleDirectionLeft:
        {
            xAddtion = - 10;
            yAddition = 0;
            break;
        }
        case AWEImageAndTitleBubbleDirectionRight:
        {
            xAddtion = 10;
            yAddition = 0;
            break;
        }
    }
    
    void (^showAnimations)(ACCBubbleAnimation *animation) = ^(ACCBubbleAnimation *animation) {
        animation
        .timing(kACCBubbleAnimationTimingFunctionCubicEaseOut)
        .scale(0,0)
        .move(xOffset,yOffset,0)
        .parallel(3)
        .move(-xOffset + xAddtion, -yOffset + yAddition,0.3)
        .scale(1,0.3)
        .reveal(0.3)
        .timing(kACCBubbleAnimationTimingFunctionDefault)
        .move(-xAddtion,-yAddition,0.5)
        
        .sleep(5)
        
        .timing(kACCBubbleAnimationTimingFunctionDefault)
        .move(xAddtion,yAddition,0.15)
        .timing(kACCBubbleAnimationTimingFunctionCubicEaseIn)
        .parallel(3)
        .move(xOffset - xAddtion, yOffset - yAddition,0.3)
        .scale(0,0.3)
        .dismiss(0.3);
    };
    
    void (^dismissAnimations)(ACCBubbleAnimation *animation) = ^(ACCBubbleAnimation *animation) {
        animation
        .timing(kACCBubbleAnimationTimingFunctionDefault)
        .move(xAddtion,yAddition,0.15)
        .timing(kACCBubbleAnimationTimingFunctionCubicEaseIn)
        .parallel(3)
        .move(xOffset - xAddtion, yOffset - yAddition,0.3)
        .scale(0,0.3)
        .dismiss(0.3);
    };

    if (isShow) {
        [self acc_bubbleAnimate:showAnimations completion:completion];
    } else {
        [self acc_bubbleAnimate:dismissAnimations completion:completion];
    }
}

#pragma mark - utils

- (CGFloat)widthOfTitle:(NSString *)title
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObject:[ACCFont() systemFontOfSize:15 weight:ACCFontWeightSemibold] forKey:NSFontAttributeName];
    CGSize size = [title boundingRectWithSize:CGSizeMake(AWEStudioBubbleMaxWidth, 0.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:dic context:nil].size;
    
    return size.width + 2.0;
}

- (CGFloat)widthOfSubTitle:(NSString *)title
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithObject:[ACCFont() systemFontOfSize:13 weight:ACCFontWeightRegular] forKey:NSFontAttributeName];
    CGSize size = [title boundingRectWithSize:CGSizeMake(AWEStudioBubbleMaxWidth, 0.0) options:NSStringDrawingUsesLineFragmentOrigin attributes:dic context:nil].size;
    
    return size.width + 2.0;
}

- (void)makeMaskLayerWithDirection:(AWEImageAndTitleBubbleDirection)direction anchorPoint:(CGPoint)anchorPoint
{
    CGRect frame = self.bounds;
    CGFloat radius = AWEStudioBubbleRadius;
    
    CAShapeLayer *layer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    switch (direction) {
        case AWEImageAndTitleBubbleDirectionUp:
        {
            [path moveToPoint:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMinY(frame))];
            [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame))];
            [path addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame) + radius) radius:radius startAngle:1.5 * M_PI endAngle:2 * M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame) - radius - AWEStudioBubbleArrowHeight)];
            [path addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMaxY(frame) - radius - AWEStudioBubbleArrowHeight) radius:radius startAngle:0 * M_PI endAngle:0.5 * M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake(anchorPoint.x + AWEStudioBubbleArrowWidth / 2.0, CGRectGetMaxY(frame) - AWEStudioBubbleArrowHeight)];
            [path addLineToPoint:CGPointMake(anchorPoint.x, anchorPoint.y)];
            [path addLineToPoint:CGPointMake(anchorPoint.x - AWEStudioBubbleArrowWidth / 2.0, CGRectGetMaxY(frame) - AWEStudioBubbleArrowHeight)];
            [path addLineToPoint:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame) - AWEStudioBubbleArrowHeight)];
            [path addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame) - radius - AWEStudioBubbleArrowHeight) radius:radius startAngle:0.5 * M_PI endAngle:1.0 * M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame) + radius)];
            [path addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMinY(frame) + radius) radius:radius startAngle:1.0 * M_PI endAngle:1.5 * M_PI clockwise:YES];
        }
            break;
            
        case AWEImageAndTitleBubbleDirectionDown:
        {
            [path moveToPoint:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMinY(frame) + AWEStudioBubbleArrowHeight)];
            [path addLineToPoint:CGPointMake(anchorPoint.x - AWEStudioBubbleArrowWidth / 2.0, CGRectGetMinY(frame) + AWEStudioBubbleArrowHeight)];
            [path addLineToPoint:CGPointMake(anchorPoint.x, anchorPoint.y)];
            [path addLineToPoint:CGPointMake(anchorPoint.x + AWEStudioBubbleArrowWidth / 2.0, CGRectGetMinY(frame) + AWEStudioBubbleArrowHeight)];
            [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame) + AWEStudioBubbleArrowHeight)];
            [path addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame) + radius + AWEStudioBubbleArrowHeight) radius:radius startAngle:1.5 * M_PI endAngle:2 * M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame) - radius)];
            [path addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMaxY(frame) - radius) radius:radius startAngle:0 * M_PI endAngle:0.5 * M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame))];
            [path addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame) - radius) radius:radius startAngle:0.5 * M_PI endAngle:1.0 * M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame) + radius + AWEStudioBubbleArrowHeight)];
            [path addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMinY(frame) + radius + AWEStudioBubbleArrowHeight) radius:radius startAngle:1.0 * M_PI endAngle:1.5 * M_PI clockwise:YES];
        }
            break;
            
        case AWEImageAndTitleBubbleDirectionLeft:
        {
            [path moveToPoint:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMinY(frame))];
            [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - radius - AWEStudioBubbleArrowHeight, CGRectGetMinY(frame))];
            [path addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius - AWEStudioBubbleArrowHeight, CGRectGetMinY(frame) + radius) radius:radius startAngle:1.5 * M_PI endAngle:2 * M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - AWEStudioBubbleArrowHeight, anchorPoint.y - AWEStudioBubbleArrowWidth / 2.0)];
            [path addLineToPoint:CGPointMake(anchorPoint.x, anchorPoint.y)];
            [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - AWEStudioBubbleArrowHeight, anchorPoint.y + AWEStudioBubbleArrowWidth / 2.0)];
            [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - AWEStudioBubbleArrowHeight, CGRectGetMaxY(frame) - radius)];
            [path addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius - AWEStudioBubbleArrowHeight, CGRectGetMaxY(frame) - radius) radius:radius startAngle:0 * M_PI endAngle:0.5 * M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame))];
            [path addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame) - radius) radius:radius startAngle:0.5 * M_PI endAngle:1.0 * M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame) + radius)];
            [path addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMinY(frame) + radius) radius:radius startAngle:1.0 * M_PI endAngle:1.5 * M_PI clockwise:YES];
        }
            break;
        case AWEImageAndTitleBubbleDirectionRight:
        {
            [path moveToPoint:CGPointMake(CGRectGetMinX(frame) + radius + AWEStudioBubbleArrowHeight, CGRectGetMinY(frame))];
            [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame))];
            [path addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame) + radius) radius:radius startAngle:1.5 * M_PI endAngle:2 * M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame) - radius)];
            [path addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMaxY(frame) - radius) radius:radius startAngle:0 * M_PI endAngle:0.5 * M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake(CGRectGetMinX(frame) + radius + AWEStudioBubbleArrowHeight, CGRectGetMaxY(frame))];
            [path addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius + AWEStudioBubbleArrowHeight, CGRectGetMaxY(frame) - radius) radius:radius startAngle:0.5 * M_PI endAngle:1.0 * M_PI clockwise:YES];
            [path addLineToPoint:CGPointMake(CGRectGetMinX(frame) + AWEStudioBubbleArrowHeight, anchorPoint.y + AWEStudioBubbleArrowWidth / 2.0)];
            [path addLineToPoint:CGPointMake(anchorPoint.x, anchorPoint.y)];
            [path addLineToPoint:CGPointMake(CGRectGetMinX(frame) + AWEStudioBubbleArrowHeight, anchorPoint.y - AWEStudioBubbleArrowWidth / 2.0)];
            [path addLineToPoint:CGPointMake(CGRectGetMinX(frame) + AWEStudioBubbleArrowHeight, CGRectGetMinY(frame) + radius)];
            [path addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius + AWEStudioBubbleArrowHeight, CGRectGetMinY(frame) + radius) radius:radius startAngle:1.0 * M_PI endAngle:1.5 * M_PI clockwise:YES];
        }
            break;
    }

    layer.path = path.CGPath;
    self.layer.mask = layer;
    
    if (self.isDarkBackGround) {
        self.stroke.path = path.CGPath;
        [self.layer addSublayer:self.stroke];
    }
}

#pragma mark - getter

- (UIView *)bgView
{
    if (!_bgView) {
        _bgView = [[UIView alloc] init];
        _bgView.backgroundColor = [UIColor clearColor];
    }
    
    return _bgView;
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
        _imageView.userInteractionEnabled = YES;
    }
    
    return _imageView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.numberOfLines = 0;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        _titleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightSemibold];
    }
    
    return _titleLabel;
}

- (UILabel *)subTitleLabel
{
    if (!_subTitleLabel) {
        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.textAlignment = NSTextAlignmentLeft;
        _subTitleLabel.numberOfLines = 0;
        _subTitleLabel.backgroundColor = [UIColor clearColor];
        _subTitleLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse3);
        _subTitleLabel.font = [ACCFont() systemFontOfSize:13 weight:ACCFontWeightRegular];
    }
    
    return _subTitleLabel;
}

- (CAShapeLayer *)stroke
{
    if (!_stroke) {
        _stroke = [CAShapeLayer layer];
        _stroke.frame = self.bounds;
        CGFloat lineWidth = 2.f;
        _stroke.lineWidth = lineWidth;
        _stroke.strokeColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:0.2].CGColor;
        _stroke.fillColor = nil;
        _stroke.fillMode = kCAFillRuleEvenOdd;
    }
    return _stroke;
}

@end
