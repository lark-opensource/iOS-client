//
//  VEEditorSession+ACCPreview.m
//  CameraClient
//
//  Created by haoyipeng on 2020/8/18.
//

#import "VEEditorSession+ACCPreview.h"
#import <objc/runtime.h>

@implementation VEEditorSession (ACCPreview)

- (void)acc_continuePlay
{
    if (self.status == HTSPlayerStatusIdle || self.status == HTSPlayerStatusWaitingPlay) {
        [self start];
    }
}

- (void)acc_setStickerEditMode:(BOOL)mode
{
    self.acc_stickerEditMode = mode;
    [self setStickerEditMode:mode];
    if (!mode) {
        [self acc_continuePlay];
    }
}

#pragma mark -

- (void)setAcc_stickerEditMode:(BOOL)acc_stickerEditMode {
    objc_setAssociatedObject(self, @selector(acc_stickerEditMode), @(acc_stickerEditMode), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)acc_stickerEditMode {
    return [objc_getAssociatedObject(self, @selector(acc_stickerEditMode)) boolValue];
}

- (void)setAcc_playerFrame:(CGRect)acc_playerFrame
{
    objc_setAssociatedObject(self, @selector(acc_playerFrame), [NSValue valueWithCGRect:acc_playerFrame], OBJC_ASSOCIATION_RETAIN);
}

- (CGRect)acc_playerFrame
{
    return [objc_getAssociatedObject(self, @selector(acc_playerFrame)) CGRectValue];
}

@end
