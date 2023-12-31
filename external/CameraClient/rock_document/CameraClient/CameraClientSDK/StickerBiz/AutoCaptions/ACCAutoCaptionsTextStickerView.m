//
//  ACCAutoCaptionsTextStickerView.m
//  CameraClient
//
//  Created by Yangguocheng on 2020/7/27.
//

#import "ACCAutoCaptionsTextStickerView.h"

@implementation ACCAutoCaptionsTextStickerView
@synthesize coordinateDidChange;
@synthesize stickerContainer;
@synthesize transparent = _transparent;
@synthesize stickerId = _stickerId;
@synthesize triggerDragDeleteCallback = _triggerDragDeleteCallback;

- (id)copyForContext:(id)contextId
{
    ACCAutoCaptionsTextStickerView *viewCopy = [[[self class] alloc] initWithFrame:self.frame];
    viewCopy.transparentChanged = self.transparentChanged;
    return viewCopy;
}

- (void)updateWithInstance:(ACCAutoCaptionsTextStickerView *)instance context:(id)contextId
{
}

- (void)setTransparent:(BOOL)transparent
{
    _transparent = transparent;
    self.transparentChanged ?: self.transparentChanged(transparent);
}

- (void)updateSize:(CGSize)size
{
    self.bounds = CGRectMake(0, 0, size.width, size.height);
    !self.coordinateDidChange ?: self.coordinateDidChange();
}

@end
