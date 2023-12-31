//
//  ACCStickerAngleAdsorbingPlugin.m
//  CameraClient
//
//  Created by Yangguocheng on 2020/6/22.
//

#import "ACCStickerAngleAdsorbingPlugin.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import "ACCBaseStickerView+Adsorbing.h"
#import "ACCStickerBizDefines.h"
#import "ACCCommonStickerConfig.h"

@interface ACCStickerAngleAdsorbingPlugin ()

@property (nonatomic, strong) CAShapeLayer *centerHorizontalDashLayer;
@property (nonatomic, assign) CGFloat rotationInAdsorbing;
@property (nonatomic, strong) UIView *pluginContentView;

@end

@implementation ACCStickerAngleAdsorbingPlugin
@synthesize stickerContainer;

static const CGFloat kACCStickerViewCenterHelperLineLength = 2000.f;
static const CGFloat kACCStickerViewCenterHelperLineWidth = 1.f;

+ (nonnull instancetype)createPlugin
{
    return [[ACCStickerAngleAdsorbingPlugin alloc] init];
}

- (void)loadPlugin
{
    self.centerHorizontalDashLayer.frame = CGRectMake(- kACCStickerViewCenterHelperLineLength / 2.0f, (self.pluginContentView.bounds.size.height - 1) / 2.f, kACCStickerViewCenterHelperLineLength, kACCStickerViewCenterHelperLineWidth);
    self.centerHorizontalDashLayer.hidden = YES;
    [self.pluginContentView.layer addSublayer:self.centerHorizontalDashLayer];
}

- (UIView *)pluginContentView
{
    if (!_pluginContentView) {
        _pluginContentView = [[UIView alloc] initWithFrame:self.stickerContainer.containerView.bounds];
    }
    return _pluginContentView;
}

- (UIView *)pluginView
{
    return self.pluginContentView;
}

- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (CAShapeLayer *)centerHorizontalDashLayer
{
    if (!_centerHorizontalDashLayer) {
        CAShapeLayer *dashLineLayer = [CAShapeLayer layer];
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathMoveToPoint(path, &CGAffineTransformIdentity, 0, 0);
        CGPathAddLineToPoint(path, &CGAffineTransformIdentity, kACCStickerViewCenterHelperLineLength, 0);
        dashLineLayer.path = path;
        dashLineLayer.lineWidth = kACCStickerViewCenterHelperLineWidth;
        dashLineLayer.lineDashPattern = @[@4, @4];
        dashLineLayer.lineCap = kCALineCapButt;
        dashLineLayer.strokeColor = UIColor.redColor.CGColor;
        _centerHorizontalDashLayer = dashLineLayer;
        NSDictionary *newActions = @{
            @"transform": [NSNull null],
            @"position": [NSNull null]
        };
        dashLineLayer.actions = newActions;
        CGPathRelease(path);
    }
    return _centerHorizontalDashLayer;
}

- (void)generateLightImpactFeedBack
{
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *fbGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [fbGenerator prepare];
        [fbGenerator impactOccurred];
    }
}

- (void)showAngleHelperDashLine
{
    if (self.centerHorizontalDashLayer.hidden) {
        [self generateLightImpactFeedBack];
        self.centerHorizontalDashLayer.hidden = NO;
        [UIView animateWithDuration:0.2f animations:^{
            self.centerHorizontalDashLayer.strokeColor = ACCResourceColor(ACCUIColorConstSecondary).CGColor;
        }];
    }
}

- (void)hideAngleHelperDashLine
{
    if (!self.centerHorizontalDashLayer.hidden) {
        self.centerHorizontalDashLayer.hidden = YES;
        self.centerHorizontalDashLayer.strokeColor = [UIColor clearColor].CGColor;
    }
}

- (CGPoint)anchorDiffWithStickerView:(UIView *)stickerView
{
    CGPoint newPoint = CGPointMake(stickerView.bounds.size.width * stickerView.layer.anchorPoint.x,
                                   stickerView.bounds.size.height * stickerView.layer.anchorPoint.y);
    CGPoint oldPoint = CGPointMake(stickerView.bounds.size.width * 0.5,
                                   stickerView.bounds.size.height * 0.5);
    newPoint = CGPointApplyAffineTransform(newPoint, stickerView.transform);
    oldPoint = CGPointApplyAffineTransform(oldPoint, stickerView.transform);
    return CGPointMake(newPoint.x - oldPoint.x, newPoint.y - oldPoint.y);
}

- (void)updateHorizontalWithStickerView:(UIView *)stickerView
{
    CGPoint diff = [self anchorDiffWithStickerView:stickerView];
    self.centerHorizontalDashLayer.affineTransform = CGAffineTransformMakeRotation(atan2f(stickerView.transform.b, stickerView.transform.a));
    self.centerHorizontalDashLayer.position = CGPointMake(stickerView.center.x - diff.x, stickerView.center.y - diff.y);
}

- (void)playerFrameChange:(CGRect)playerFrame
{
    _pluginContentView.frame = self.stickerContainer.containerView.bounds;
}

- (void)interceptStickerView:(ACCBaseStickerView <ACCGestureResponsibleStickerProtocol> *)stickerView toAngleAdsorbingWithGesture:(UIRotationGestureRecognizer *)gesture
{
    float currentRota = gesture.rotation;
    if (stickerView.isAngleAdsorbing && fabs(currentRota + self.rotationInAdsorbing) > (6.f * M_PI / 180)) {
        // 3 degree over the current Adsorbing state will de-Adsorbing
        gesture.rotation = currentRota + self.rotationInAdsorbing;
        self.rotationInAdsorbing = 0;
        stickerView.isAngleAdsorbing = NO;
        [self hideAngleHelperDashLine];
        return;
    }
    
    if (currentRota == 0 || stickerView.isAngleAdsorbing) {
        if (stickerView.isAngleAdsorbing) {
            self.rotationInAdsorbing += gesture.rotation;
            gesture.rotation = 0;
        }
        return;
    }
    
    CGAffineTransform _trans = stickerView.transform;
    CGFloat rotate = atanf(_trans.b/_trans.a);
    if (_trans.a < 0 && _trans.b > 0) {
        rotate += M_PI;
    } else if(_trans.a <0 && _trans.b < 0){
        rotate -= M_PI;
    }
    // split transform to Pan, Scale and Rotation to Adsorbing
    CGFloat tx = _trans.tx;
    CGFloat ty = _trans.ty;
    CGFloat scale = sqrt(_trans.a * _trans.a + _trans.c * _trans.c);
    __block CGAffineTransform aimedTransform = CGAffineTransformMakeTranslation(tx, ty);
    aimedTransform = CGAffineTransformScale(aimedTransform, scale, scale);
    
    NSArray<NSNumber *> *AdsorbingAngleInRadians = @[@(-M_PI / 4), @(-M_PI / 2), @(-M_PI / 4 * 3), @(-M_PI), @(-M_PI / 4 * 5), @(-M_PI / 2 * 3), @(-M_PI / 4 * 7),
                                                     @0,
                                                     @(M_PI / 4), @(M_PI / 2), @(M_PI / 4 * 3), @(M_PI), @(M_PI / 4 * 5), @(M_PI / 2 * 3), @(M_PI / 4 * 7)];
    CGFloat continuousMoveThreshold = 4.f * M_PI / 180;
    [AdsorbingAngleInRadians enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (((rotate + currentRota) > (-continuousMoveThreshold + obj.floatValue)) && ((rotate + currentRota) < (continuousMoveThreshold + obj.floatValue))) {
            stickerView.isAngleAdsorbing = YES;
            aimedTransform = CGAffineTransformRotate(aimedTransform, obj.floatValue);
            *stop = YES;
        }
    }];
    
    if (stickerView.isAngleAdsorbing) {
        stickerView.transform = aimedTransform;
        // IMPORT Adsorbing plugin consume roration Before sticker response to roration
        if ([gesture isKindOfClass:[UIRotationGestureRecognizer class]]) {
            ((UIRotationGestureRecognizer *)gesture).rotation = 0;
        }
        [self updateHorizontalWithStickerView:stickerView];
        [self showAngleHelperDashLine];
    }
}

- (void)didChangeLocationWithOperationStickerView:(UIView *)stickerView
{
    
}

- (void)sticker:(ACCBaseStickerView *)stickerView willHandleGesture:(UIGestureRecognizer *)gesture
{
    [self updateHorizontalWithStickerView:stickerView];
    if ([gesture isKindOfClass:[UIRotationGestureRecognizer class]] && [stickerView conformsToProtocol:@protocol(ACCGestureResponsibleStickerProtocol)]) {
        [self interceptStickerView:(ACCBaseStickerView <ACCGestureResponsibleStickerProtocol> *)stickerView toAngleAdsorbingWithGesture:(UIRotationGestureRecognizer *)gesture];
    }
}

- (void)sticker:(ACCBaseStickerView *)stickerView didHandleGesture:(UIGestureRecognizer *)gesture
{
    [self updateHorizontalWithStickerView:stickerView];
}

- (void)sticker:(ACCBaseStickerView *)stickerView didEndGesture:(UIGestureRecognizer *)gesture
{
    [self hideAngleHelperDashLine];
    stickerView.isAngleAdsorbing = NO;
    self.rotationInAdsorbing = 0;
}

- (BOOL)featureSupportSticker:(id<ACCStickerProtocol>)sticker
{
    if (![sticker.config isKindOfClass:[ACCCommonStickerConfig class]]) {
        return NO;
    }
    return [self implementedContainerFeature] & ((ACCCommonStickerConfig *)sticker.config).preferredContainerFeature;
}

- (ACCStickerContainerFeature)implementedContainerFeature
{
    return ACCStickerContainerFeatureAngleAdsorbing;
}

@end
