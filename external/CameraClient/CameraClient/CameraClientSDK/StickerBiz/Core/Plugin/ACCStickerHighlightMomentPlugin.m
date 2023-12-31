//
//  ACCStickerHighlightMomentPlugin.m
//  CameraClient
//
//  Created by Yangguocheng on 2020/6/22.
//

#import "ACCStickerHighlightMomentPlugin.h"
#import <CreativeKitSticker/ACCBaseStickerView.h>
#import "ACCStickerBizDefines.h"
#import "ACCCommonStickerConfig.h"

@interface ACCStickerHighlightMomentPlugin ()

@property (nonatomic, assign) CGPoint backupCenter;
@property (nonatomic, assign) CGAffineTransform backupTransform;
@property (nonatomic, assign) BOOL invalidAction;
@property (nonatomic, assign) BOOL hasBackup;

@end

@implementation ACCStickerHighlightMomentPlugin
@synthesize stickerContainer;

+ (nonnull instancetype)createPlugin
{
    return [[ACCStickerHighlightMomentPlugin alloc] init];
}

- (ACCStickerContainerFeature)implementedContainerFeature
{
    return ACCStickerContainerFeatureHighlightMoment;
}

- (void)loadPlugin
{

}

- (void)playerFrameChange:(CGRect)playerFrame
{
    
}

- (void)didChangeLocationWithOperationStickerView:(ACCBaseStickerView *)stickerView
{
    
}

- (void)sticker:(ACCBaseStickerView *)stickerView willHandleGesture:(UIGestureRecognizer *)gesture
{
    if ([gesture isKindOfClass:[UIPanGestureRecognizer class]] && gesture.state == UIGestureRecognizerStateBegan) {
        self.invalidAction = NO;
        if (!self.hasBackup) {
            self.hasBackup = YES;
            self.backupCenter = stickerView.center;
            self.backupTransform = stickerView.transform;
        }
    }
}

// NSValue of CGPoint
BOOL isPointInPolygon(NSArray <NSValue *> *polygonList, CGPoint point)
{
    BOOL bRet = NO;
    for (NSUInteger i = 0, j = polygonList.count - 1; i < polygonList.count; j = i++) {
        CGPoint polygonPointi = [polygonList[i] CGPointValue];
        CGPoint polygonPointj = [polygonList[j] CGPointValue];

         // this checks whether y-coord i.e. point.y is between edge's vertices
        if ((((polygonPointi.y >= point.y) && (polygonPointj.y <= point.y)) || ((polygonPointi.y <= point.y) && (polygonPointj.y >= point.y)))
            // this checks whether x-coord i.e. point.x is to the left of the line
            && (point.x < (polygonPointj.x - polygonPointi.x) * (point.y - polygonPointi.y) / (polygonPointj.y - polygonPointi.y) + polygonPointi.x)) {
            bRet = !bRet;
        }
    }
    return bRet;
}

BOOL isLineIntersect(CGPoint a1, CGPoint a2, CGPoint b1, CGPoint b2)
{
    CGFloat ua_t = (b2.x - b1.x) * (a1.y - b1.y) - (b2.y - b1.y) * (a1.x - b1.x);
    CGFloat ub_t = (a2.x - a1.x) * (a1.y - b1.y) - (a2.y - a1.y) * (a1.x - b1.x);
    CGFloat u_b  = (b2.y - b1.y) * (a2.x - a1.x) - (b2.x - b1.x) * (a2.y - a1.y);

    // not parallel
    if (u_b != 0 ) {
        CGFloat ua = ua_t / u_b;
        CGFloat ub = ub_t / u_b;

        if (0 <= ua && ua <= 1 && 0 <= ub && ub <= 1) {
            return YES;
        }
    }
    return NO;
}

// NSValue of CGPoint
- (BOOL)isPolygon:(NSArray <NSValue *> *)polygonList intersectWithPolygon:(NSArray <NSValue *> *)otherPolygonList
{
    if (polygonList.count < 2 || otherPolygonList.count < 2) {
        return NO;
    }
    for (NSInteger index1 = 0; index1 < polygonList.count; ++index1) {
        for (NSInteger index2 = 0; index2 < otherPolygonList.count; ++index2) {
            NSInteger line1From = index1;
            NSInteger line1To = index1 + 1;
            if (line1To == polygonList.count) {
                line1To = 0;
            }
            NSInteger line2From = index2;
            NSInteger line2To = index2 + 1;
            if (line2To == otherPolygonList.count) {
                line2To = 0;
            }
            BOOL lineIntersect = isLineIntersect([polygonList[line1From] CGPointValue], [polygonList[line1To] CGPointValue], [otherPolygonList[line2From] CGPointValue], [otherPolygonList[line2To] CGPointValue]);
            if (lineIntersect) {
                return YES;
            }
        }
    }
    for (NSValue *value in polygonList) {
        if (isPointInPolygon(otherPolygonList, [value CGPointValue])) {
            return YES;
        }
    }
    for (NSValue *value in otherPolygonList) {
        if (isPointInPolygon(polygonList, [value CGPointValue])) {
            return YES;
        }
    }
    return NO;
}

- (void)sticker:(ACCBaseStickerView *)stickerView didHandleGesture:(UIGestureRecognizer *)gesture
{
    CGRect invalidFrame = CGRectZero;
    if ([stickerView.config isKindOfClass:[ACCCommonStickerConfig class]]) {
        ACCCommonStickerConfig *config = (ACCCommonStickerConfig *)stickerView.config;
        invalidFrame = [config.gestureInvalidFrameValue CGRectValue];
    }
    CGRect stickerRectLeftBottom = [stickerView convertRect:CGRectMake(0, stickerView.bounds.size.height, 1, 1) toView:stickerView.superview];
    CGRect stickerRectLeftTop = [stickerView convertRect:CGRectMake(0, 0, 1, 1) toView:stickerView.superview];
    CGRect stickerRectRightTop = [stickerView convertRect:CGRectMake(stickerView.bounds.size.width, 0, 1, 1) toView:stickerView.superview];
    CGRect stickerRectRightBottom = [stickerView convertRect:CGRectMake(stickerView.bounds.size.width, stickerView.bounds.size.height, 1, 1) toView:stickerView.superview];

    if (!CGRectIsEmpty(invalidFrame) && [self isPolygon:@[@(invalidFrame.origin), @(CGPointMake(invalidFrame.origin.x + invalidFrame.size.width, invalidFrame.origin.y)), @(CGPointMake(invalidFrame.origin.x + invalidFrame.size.width, invalidFrame.origin.y + invalidFrame.size.height)), @(CGPointMake(invalidFrame.origin.x, invalidFrame.origin.y + invalidFrame.size.height))] intersectWithPolygon:@[@(stickerRectLeftTop.origin), @(stickerRectRightTop.origin), @(stickerRectRightBottom.origin), @(stickerRectLeftBottom.origin)]]) {
        self.invalidAction = YES;
    } else {
        self.invalidAction = NO;
    }
    if (self.invalidAction) {
        stickerView.alpha = 0.34;
    } else if (stickerView.alpha == 0.34) {
        stickerView.alpha = 1;
    }
}

- (void)resetStickerView:(ACCBaseStickerView *)stickerView
{
    stickerView.alpha = 1.0f;
    [UIView animateWithDuration:0.49 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.30 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        stickerView.center = self.backupCenter;
        stickerView.transform = self.backupTransform;
    } completion:^(BOOL finished) {

    }];
}

- (void)sticker:(ACCBaseStickerView *)stickerView didEndGesture:(UIGestureRecognizer *)gesture
{
    if (self.invalidAction) {
        [self resetStickerView:stickerView];
    }
    self.invalidAction = NO;
    self.hasBackup = NO;
}

- (BOOL)featureSupportSticker:(id<ACCStickerProtocol>)sticker
{
    if (![sticker.config isKindOfClass:[ACCCommonStickerConfig class]]) {
        return NO;
    }
    return [self implementedContainerFeature] & ((ACCCommonStickerConfig *)sticker.config).preferredContainerFeature;
}

@end
