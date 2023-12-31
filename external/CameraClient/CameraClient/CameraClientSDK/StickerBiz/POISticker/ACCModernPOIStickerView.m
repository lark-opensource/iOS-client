//
//  ACCModernPOIStickerView.m
//  CameraClient-Pods-Aweme
//
//  Created by 卜旭阳 on 2020/9/20.
//

#import "ACCModernPOIStickerView.h"
#import "ACCPOIStickerModel.h"
#import "ACCStickerPlayerApplying.h"

@implementation ACCModernPOIStickerView

#pragma mark - ACCStickerContentProtocol
@synthesize coordinateDidChange;
@synthesize stickerContainer;
@synthesize transparent = _transparent;
@synthesize triggerDragDeleteCallback = _triggerDragDeleteCallback;

- (id)copyForContext:(id)contextId
{
    ACCModernPOIStickerView *viewCopy = [[[self class] alloc] initWithFrame:self.frame];
    viewCopy.stickerId = self.stickerId;
    viewCopy.model = self.model;
    viewCopy.helper = self.helper;
    viewCopy.poiIdentifier = [self.poiIdentifier copy];

    return viewCopy;
}

#pragma mark - ACCStickerEditContentProtocol
- (void)setTransparent:(BOOL)transparent
{
    _transparent = transparent;
    // Wait for new structure
    if ([self.helper respondsToSelector:@selector(currentPlayer)]) {
        [[self.helper currentPlayer] setSticker:self.stickerId alpha:(transparent ? 0.34 : 1.0)];
    }
    self.alpha = transparent? 0.5: 1.0;
}

- (NSString *)stickerViewIdentifier
{
    return self.poiIdentifier;
}

@end
