//
//  ACCInfoStickerContentView.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/9/14.
//

#import "ACCInfoStickerContentView.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <TTVideoEditor/VEEditorSession+Effect.h>
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

@interface ACCInfoStickerContentView()

@property (nonatomic, weak) UILabel *authorLabel;

@end

@implementation ACCInfoStickerContentView

#pragma mark - ACCStickerContentProtocol
@synthesize coordinateDidChange;
@synthesize stickerContainer;
@synthesize transparent = _transparent;
@synthesize triggerDragDeleteCallback = _triggerDragDeleteCallback;

#pragma mark - ACCStickerCopyingProtocol
- (instancetype)copyForContext:(id)contextId
{
    ACCInfoStickerContentView *viewCopy = [[[self class] alloc] initWithFrame:self.frame];
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
    
    viewCopy.config = [self.config copy];
    viewCopy.stickerId = self.stickerId;
    viewCopy.editService = self.editService;
    
    return viewCopy;
}

- (void)updateWithInstance:(ACCInfoStickerContentView *)instance context:(id)contextId
{
    self.stickerInfos = instance.stickerInfos;
}

- (void)didCancledPin
{
    if (self.didCancledPinCallback) {
        self.didCancledPinCallback(self);
    }
}

- (void)bubbleChanged:(BOOL)show
{
    if (self.authorName.length > 0 && self.shouldShowAuthor && self.hintView) {
        if (!self.authorLabel) {
            UILabel *authorLabel = [[UILabel alloc] init];
            authorLabel.textColor = [UIColor whiteColor];
            authorLabel.font = [UIFont acc_systemFontOfSize:10.f weight:ACCFontWeightMedium];
            authorLabel.text = [NSString stringWithFormat:@"作者: 黑罐头素材平台%@",self.authorName];
            CGSize size = [authorLabel sizeThatFits:CGSizeMake(CGFLOAT_MAX, 16.f)];
            [self.hintView addSubview:authorLabel];
            ACCMasMaker(authorLabel, {
                make.size.equalTo(@(size));
                make.right.equalTo(self.hintView);
                make.top.equalTo(@(self.hintView.acc_height + 5.f));
            });
            self.authorLabel = authorLabel;
        }
    } else {
        [self.authorLabel removeFromSuperview];
    }
}

- (void)setTransparent:(BOOL)transparent
{
    _transparent = transparent;
    
    [self.editService.sticker setSticker:self.stickerId alpha:(transparent? 0.34: 1.0)];
    if (!transparent) {
        [self.editService.sticker setStickerAboveForInfoSticker:self.stickerId];
    }
}

- (void)setStickerId:(NSInteger)stickerId
{
    _stickerId = stickerId;
    _stickerInfos.stickerId = stickerId;
}

#pragma mark - ACCStickerEditContentProtocol

- (NSString *)stickerViewIdentifier
{
    return ACCDynamicCast([self.stickerInfos.userInfo objectForKey:kACCStickerUUIDKey], NSString);
}

@end
