//
//  ACCStickerContainerView+CameraClient.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/11/13.
//

#import "ACCStickerContainerView+CameraClient.h"
#import <objc/runtime.h>
#import <CreativeKitSticker/ACCStickerProtocol.h>

@implementation ACCStickerContainerView (CameraClient)

- (void)editorStickerGestureStarted
{
    // No Need to do
}

- (UIImageView *)selectStickerDurationTmpSnapshotView
{
    return objc_getAssociatedObject(self, _cmd);;
}

- (void)setSelectStickerDurationTmpSnapshotView:(UIImageView *)selectStickerDurationTmpSnapshotView
{
    objc_setAssociatedObject(self, @selector(selectStickerDurationTmpSnapshotView), selectStickerDurationTmpSnapshotView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)generateTmpSnapshotView
{
    self.selectStickerDurationTmpSnapshotView = [[UIImageView alloc] initWithImage:[self generateImage]];
}

- (UIView <ACCStickerSelectTimeRangeProtocol> *)stickerContentView
{
    return nil;
}

- (nonnull NSArray<UIView<ACCSelectTimeRangeStickerProtocol> *> *)stickerViewList
{
    return self.allStickerViews;
}

#pragma mark - ACCEditorStickerArtboardProtocol

- (BOOL)isChildView:(UIView *)targetView
{
    if (![targetView isKindOfClass:[ACCBaseStickerView class]]) {
        return NO;
    }
    return [self.allStickerViews containsObject:(ACCBaseStickerView *)targetView];
}

// should optimize?
// better provide by gesture module
- (ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *)operatingView
{
    for (ACCBaseStickerView *view in self.allStickerViews) {
        if ([view conformsToProtocol:@protocol(ACCGestureResponsibleStickerProtocol)]) {
            ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *gestureResponsibleSticker = (ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *)view;
            if (gestureResponsibleSticker.gestureActiveState != ACCStickerGestureStateNone) {
                return gestureResponsibleSticker;
            }
        }
    }
    return nil;
}

- (NSInteger)hierarchy
{
    return [objc_getAssociatedObject(self, _cmd) integerValue];
}

- (void)setHierarchy:(NSInteger)hierarchy
{
    objc_setAssociatedObject(self, @selector(hierarchy), @(hierarchy), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGSize)mediaActualSize
{
    return [objc_getAssociatedObject(self, @selector(mediaActualSize)) CGSizeValue];
}

- (void)setMediaActualSize:(CGSize)mediaActualSize
{
    objc_setAssociatedObject(self, @selector(mediaActualSize), @(mediaActualSize), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
