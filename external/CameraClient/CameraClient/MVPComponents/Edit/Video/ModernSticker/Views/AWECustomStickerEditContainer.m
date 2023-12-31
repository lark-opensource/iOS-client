//
//  AWECustomStickerEditContainer.m
//  CameraClient
//
//  Created by 卜旭阳 on 2020/6/17.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWECustomStickerEditContainer.h"
#import <CreativeKit/ACCMacros.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/ACCRTLProtocol.h>

NSString *const AWECustomStickerEditContainerOuterStrokeAniKey = @"kAWECustomStickerEditContainer";

CGFloat const AWECustomStickerEditContainerOuterScale = 0.75;
CGFloat const AWECustomStickerEditContainerScaleAniDuration = 0.5;
CGFloat const AWECustomStickerEditContainerEdgeAniDuration = 1.2;

@interface AWECustomStickerEditContainer()<CAAnimationDelegate>

@property (nonatomic, assign) CGFloat aspectRatio;

@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIImageView *originImageView;
@property (nonatomic, strong) CAShapeLayer *edgeAniLayer;
@property (nonatomic, strong) UIImageView *processedContentView;

@property (nonatomic, assign) NSTimeInterval loadingStartTime;

@property (nonatomic, assign) BOOL continueAnimation;

@end

@implementation AWECustomStickerEditContainer

- (instancetype)initWithImage:(UIImage *)image aspectRatio:(CGFloat)aspectRatio
{
    self = [super init];
    if(self) {
        _aspectRatio = (aspectRatio > 0) ? aspectRatio : 1;
        [self setupUIWithImage:image];
    }
    return self;
}

- (void)setupUIWithImage:(UIImage *)image
{
    self.contentView = [[UIView alloc] init];
    self.contentView.alpha = 1;
    self.contentView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.contentView];
    ACCMasMaker(self.contentView, {
        make.edges.equalTo(self);
    });
    
    self.originImageView = [[UIImageView alloc] init];
    self.originImageView.alpha = 1;
    self.originImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.originImageView];
    self.originImageView.image = image;
    ACCMasMaker(self.originImageView, {
        make.edges.equalTo(self.contentView);
    });
    
    self.processedContentView = [[UIImageView alloc] init];
    self.processedContentView.alpha = 0;
    self.processedContentView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.processedContentView];
}

#pragma mark - outer interface

- (void)prepareForProcess
{
    self.continueAnimation = YES;
    self.loadingStartTime = [[NSDate date] timeIntervalSince1970];
    [self processToLoadingStatus];
}

- (void)processWithResult:(UIImage *)image points:(NSArray<NSArray *> *)points maxRect:(CGRect)maxRect
{
    NSTimeInterval interval = [[NSDate date] timeIntervalSince1970] - self.loadingStartTime;
    @weakify(self);
    void(^applyProcessBlock)(void) = ^{
        @strongify(self);
        if(self.continueAnimation) {
            [self clearAniShapeLayer];
            [self processClipEdgeAnimationWithImage:image points:points maxRect:maxRect];
        }
    };
    if(interval >= 2*AWECustomStickerEditContainerEdgeAniDuration) {
        applyProcessBlock();
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((2*AWECustomStickerEditContainerEdgeAniDuration-interval) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            applyProcessBlock();
        });
    }
    
    //Add result Image
    CGFloat originX = CGRectGetMinX(maxRect)/self.aspectRatio;
    if([ACCRTL() isRTL])
    {
        originX = CGRectGetWidth(self.contentView.bounds) - CGRectGetMinX(maxRect)/self.aspectRatio - CGRectGetWidth(maxRect)/self.aspectRatio;
    }
    self.processedContentView.frame = CGRectMake(originX, CGRectGetMinY(maxRect)/self.aspectRatio, CGRectGetWidth(maxRect)/self.aspectRatio, CGRectGetHeight(maxRect)/self.aspectRatio);
    self.processedContentView.image = image;
}

- (void)applyUseProcessed:(BOOL)useUseProcessed
{
    self.continueAnimation = NO;
    [self.layer removeAllAnimations];
    [self clearAniShapeLayer];
    self.contentView.transform = CGAffineTransformIdentity;
    
    self.originImageView.alpha = useUseProcessed ? 0 : 1;
    self.processedContentView.alpha = useUseProcessed ? 1 : 0;
}

- (void)clearAniShapeLayer
{
    [self.edgeAniLayer removeAllAnimations];
    [self.edgeAniLayer removeFromSuperlayer];
    self.edgeAniLayer = nil;
}

#pragma mark - Animation Process
//Step1:Scale down and loading
- (void)processToLoadingStatus
{
    [UIView animateWithDuration:AWECustomStickerEditContainerScaleAniDuration animations:^{
        self.originImageView.alpha = 0.4;
        self.contentView.transform = CGAffineTransformMakeScale(AWECustomStickerEditContainerOuterScale, AWECustomStickerEditContainerOuterScale);
    }completion:^(BOOL finished) {
        if(self.continueAnimation) {
            UIBezierPath *rectPath = [UIBezierPath bezierPathWithRect:self.contentView.bounds];
            CAShapeLayer *rectLayer = [[CAShapeLayer alloc] init];
            rectLayer.lineWidth = 3;
            rectLayer.strokeColor = [UIColor whiteColor].CGColor;
            rectLayer.fillColor = nil;
            rectLayer.strokeStart = 0;
            rectLayer.strokeEnd = 0;
            rectLayer.path = rectPath.CGPath;
            self.edgeAniLayer = rectLayer;
            [self.contentView.layer addSublayer:rectLayer];
            
            CAKeyframeAnimation *startAnimation = [CAKeyframeAnimation new];
            startAnimation.keyPath = @"strokeStart";
            startAnimation.values = @[@(0.0),@(0.0),@(0.25),@(0.5),@(0.75),@(1.0)];

            CAKeyframeAnimation *endAnimation = [CAKeyframeAnimation new];
            endAnimation.keyPath = @"strokeEnd";
            endAnimation.values = @[@(0.0),@(0.25),@(0.5),@(0.75),@(1.0),@(1.0)];
            
            CAAnimationGroup *aniGroup = [CAAnimationGroup animation];
            aniGroup.duration = AWECustomStickerEditContainerEdgeAniDuration;
            aniGroup.repeatCount = INT_MAX;
            aniGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
            aniGroup.animations = @[startAnimation,endAnimation];
            [rectLayer addAnimation:aniGroup forKey:AWECustomStickerEditContainerOuterStrokeAniKey];
        }
    }];
}
//Step2:Add clip path to origin-image
- (void)processClipEdgeAnimationWithImage:(UIImage *)image points:(NSArray<NSArray *> *)points maxRect:(CGRect)maxRect
{
    UIBezierPath *shapePath = [self pathWithPointsArray:points aspectRatio:self.aspectRatio];
    CAShapeLayer *shapeLayer = [[CAShapeLayer alloc] init];
    shapeLayer.lineWidth = 3;
    shapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    shapeLayer.fillColor = nil;
    shapeLayer.strokeStart = 0;
    shapeLayer.strokeEnd = 0;
    shapeLayer.path = shapePath.CGPath;
    self.edgeAniLayer = shapeLayer;
    [self.contentView.layer addSublayer:shapeLayer];
    
    CAKeyframeAnimation *startAnimation = [CAKeyframeAnimation new];
    startAnimation.keyPath = @"strokeStart";
    startAnimation.values = @[@(1.0),@(0.7),@(0.3),@(0.15),@(0.0)];

    CAKeyframeAnimation *endAnimation = [CAKeyframeAnimation new];
    endAnimation.keyPath = @"strokeEnd";
    endAnimation.values = @[@(1.0),@(0.9),@(0.7),@(0.35),@(0.0)];

    CAAnimationGroup *aniGroup = [CAAnimationGroup animation];
    aniGroup.duration = AWECustomStickerEditContainerEdgeAniDuration;
    aniGroup.repeatCount = 1;
    //aniGroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    aniGroup.animations = @[startAnimation,endAnimation];
    aniGroup.delegate = self;
    [shapeLayer addAnimation:aniGroup forKey:AWECustomStickerEditContainerOuterStrokeAniKey];
}
//Step3:Hidden origin_image and show clipped image
- (void)processShowClipResult
{
    [UIView animateWithDuration:0.5 animations:^{
        self.originImageView.alpha = 0;
        self.processedContentView.alpha = 1;
    }completion:^(BOOL finished) {
        if(self.continueAnimation) {
            [self processRecoverToNormalScale];
        }
    }];
}
//Step4:Recover to big scale
- (void)processRecoverToNormalScale
{
    [UIView animateWithDuration:AWECustomStickerEditContainerScaleAniDuration animations:^{
        self.contentView.transform = CGAffineTransformIdentity;
    }completion:^(BOOL finished) {
        if(self.continueAnimation) {
            [self.delegate processAnimationCompleted];
        }
    }];
}

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if(self.continueAnimation) {
        [self processShowClipResult];
    }
}

#pragma mark - private
- (UIBezierPath *)pathWithPointsArray:(NSArray<NSArray *> *)originalPoints aspectRatio:(CGFloat)aspectRatio
{
    if(originalPoints.count == 0) {
        return [UIBezierPath bezierPath];
    }
    if(originalPoints.count == 1) {
        return [self singlePathWithLine:originalPoints.firstObject aspectRatio:aspectRatio];
    } else {
        return [self multiPathWithLines:originalPoints aspectRatio:aspectRatio];
    }
}

- (UIBezierPath *)singlePathWithLine:(NSArray<NSDictionary *> *)line aspectRatio:(CGFloat)aspectRatio
{
    CGMutablePathRef path = CGPathCreateMutable();
    
    __block CGFloat firstX = 0;
    __block CGFloat firstY = 0;
    [line enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGFloat x = [ACCRTL() isRTL] ? (CGRectGetWidth(self.contentView.bounds)-((NSNumber *)obj[@"x"]).doubleValue/aspectRatio) : ((NSNumber *)obj[@"x"]).doubleValue/aspectRatio;
        CGFloat y = ((NSNumber *)obj[@"y"]).doubleValue/aspectRatio;
        if(idx == 0) {
            firstX = x;
            firstY = y;
            CGPathMoveToPoint(path, NULL, x, y);
        } else {
            CGPathAddLineToPoint(path, NULL, x, y);
        }
    }];
    CGPathAddLineToPoint(path, NULL, firstX, firstY);
    UIBezierPath *allPath = [UIBezierPath bezierPathWithCGPath:path];
    CGPathRelease(path);
    return allPath;
}

- (UIBezierPath *)multiPathWithLines:(NSArray<NSArray *> *)lines aspectRatio:(CGFloat)aspectRatio
{
    CGMutablePathRef path = CGPathCreateMutable();
    int maxLength = (int)lines.firstObject.count;
    int currentCount = 0;
    while(currentCount < maxLength)
    {
        @autoreleasepool {
            for(NSArray * line in lines)
            {
                if(line.count > currentCount) {
                    NSDictionary *point = [line objectAtIndex:currentCount];
                    CGFloat x = [ACCRTL() isRTL] ? (CGRectGetWidth(self.contentView.bounds)-((NSNumber *)point[@"x"]).doubleValue/aspectRatio) : ((NSNumber *)point[@"x"]).doubleValue/aspectRatio;
                    CGFloat y = ((NSNumber *)point[@"y"]).doubleValue/aspectRatio;
                    CGPathMoveToPoint(path, NULL, x, y);
                    NSDictionary *nextPoint = (line.count > currentCount+1) ? [line objectAtIndex:currentCount+1] : line.firstObject;
                    CGFloat nextX = [ACCRTL() isRTL] ? (CGRectGetWidth(self.contentView.bounds)-((NSNumber *)nextPoint[@"x"]).doubleValue/aspectRatio) : ((NSNumber *)nextPoint[@"x"]).doubleValue/aspectRatio;
                    CGFloat nextY = ((NSNumber *)nextPoint[@"y"]).doubleValue/aspectRatio;
                    CGPathAddLineToPoint(path, NULL, nextX, nextY);
                }
            }
        }
        currentCount++;
    }
    
    UIBezierPath *allPath = [UIBezierPath bezierPathWithCGPath:path];
    CGPathRelease(path);
    return allPath;
}

#pragma mark - Utils
+ (CGSize)containerSizeWithImageSize:(CGSize)imageSize maxSize:(CGSize)maxSize
{
    if(imageSize.width > 0 && imageSize.height > 0) {
        CGFloat imgRatio = imageSize.width/imageSize.height;
        CGFloat containerRatio = maxSize.width/maxSize.height;
        CGSize containerSize = maxSize;
        if(imgRatio > containerRatio) {
            containerSize = CGSizeMake(containerSize.width, containerSize.width/imgRatio);
        } else {
            containerSize = CGSizeMake(containerSize.height*imgRatio,containerSize.height);
        }
        return containerSize;
    } else {
        return maxSize;
    }
}

+ (CGFloat)aspectRatioWithImageSize:(CGSize)imageSize containerSize:(CGSize)containerSize
{
    return MAX(imageSize.width/containerSize.width,imageSize.height/containerSize.height);
}
@end
