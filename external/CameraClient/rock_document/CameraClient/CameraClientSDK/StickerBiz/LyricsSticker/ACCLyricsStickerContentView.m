//
//  ACCLyricsStickerContentView.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2020/12/1.
//

#import "ACCLyricsStickerContentView.h"
#import <TTVideoEditor/VEEditorSession+Effect.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <CreativeKit/ACCMacros.h>

@implementation ACCLyricsStickerContentView
@synthesize coordinateDidChange;
@synthesize stickerContainer;
@synthesize transparent = _transparent;
@synthesize triggerDragDeleteCallback = _triggerDragDeleteCallback;

- (id)copyForContext:(id)contextId
{
    ACCLyricsStickerContentView *viewCopy = [[[self class] alloc] initWithFrame:self.frame];
    viewCopy.stickerInfos = [[IESInfoStickerProps alloc] init];
    {
        viewCopy.stickerInfos.stickerId = self.stickerInfos.stickerId;
        viewCopy.stickerInfos.angle = self.stickerInfos.angle;
        viewCopy.stickerInfos.offsetX = self.stickerInfos.offsetX;
        viewCopy.stickerInfos.offsetY = self.stickerInfos.offsetY;
        viewCopy.stickerInfos.scale = self.stickerInfos.scale;
        viewCopy.stickerInfos.alpha = self.stickerInfos.alpha;
        viewCopy.stickerInfos.startTime = self.stickerInfos.startTime;
        viewCopy.stickerInfos.duration = self.stickerInfos.duration;
        viewCopy.stickerInfos.userInfo = self.stickerInfos.userInfo;
        viewCopy.stickerInfos.pinStatus = self.stickerInfos.pinStatus;
        viewCopy.stickerInfos.srtColor = self.stickerInfos.srtColor;
        viewCopy.stickerInfos.srtFontPath = self.stickerInfos.srtFontPath;
        viewCopy.stickerInfos.srt = self.stickerInfos.srt;
        viewCopy.stickerInfos.srtStartTime = self.stickerInfos.srtStartTime;
    }
    
    viewCopy.beginOrigin = self.beginOrigin;
    viewCopy.config = [self.config copy];
    viewCopy.stickerId = self.stickerId;
    viewCopy.transparentChanged = self.transparentChanged;
    viewCopy.ignoreUpdateFrameWithGesture = self.ignoreUpdateFrameWithGesture;
    return viewCopy;
}

- (void)updateWithInstance:(ACCLyricsStickerContentView *)instance context:(id)contextId
{
    self.config = [instance.config copy];
    self.stickerId = instance.stickerId;
    self.stickerInfos = instance.stickerInfos;
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

#pragma mark - ACCStickerEditContentProtocol

- (NSString *)stickerViewIdentifier
{
    return ACCDynamicCast([self.stickerInfos.userInfo objectForKey:kACCStickerUUIDKey], NSString);
}

@end
