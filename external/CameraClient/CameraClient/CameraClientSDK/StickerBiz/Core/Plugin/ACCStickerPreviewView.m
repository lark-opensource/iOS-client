//
//  ACCStickerPreviewView.m
//  CameraClient
//
//  Created by guocheng on 2020/5/28.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCStickerPreviewView.h"
#import "AWEStickerContainerFakeProfileView.h"
#import <CreativeKit/ACCMacros.h>
#import "AWEXScreenAdaptManager.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKitSticker/ACCBaseStickerView.h>
#import "ACCConfigKeyDefines.h"

#import <Masonry/View+MASAdditions.h>
#import "ACCStickerBizDefines.h"
#import "ACCCommonStickerConfig.h"

@interface ACCStickerPreviewView ()

@property (nonatomic, strong) AWEStickerContainerFakeProfileView *fakeProfileView;
@property (nonatomic, copy) NSValue *playerFrameValue;

@end

@implementation ACCStickerPreviewView
@synthesize stickerContainer = _stickerContainer;

+ (instancetype)createPlugin
{
    return [[ACCStickerPreviewView alloc] initWithFrame:CGRectZero];
}

- (void)loadPlugin
{
    
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _fakeProfileView = [[AWEStickerContainerFakeProfileView alloc] initWithNeedIgnoreRTL:YES];
        [self addSubview:_fakeProfileView];
        _fakeProfileView.bottomContainerView.hidden = YES;
        _fakeProfileView.rightContainerView.hidden = YES;
    }
    return self;
}

- (UIView *)pluginView
{
    return self;
}

- (void)playerFrameChange:(CGRect)playerFrame
{
    self.playerFrameValue = [NSValue valueWithCGRect:playerFrame];
    self.frame = [self.stickerContainer containerView].bounds;
    [self updateWithPlayerPreviewView:self.stickerContainer.playerPreviewView];
}

- (void)updateWithPlayerPreviewView:(UIView *)playerPreviewView
{
    // According on logic in AWEVideoEditorPlayerService playerFrame will always be 9/16 in normal mode, in story mode, but story mode does not need fakeProfileView and any interactive sticker
    ACCMasReMaker(self.fakeProfileView, {
        make.left.equalTo(self).offset((self.acc_width - ACC_SCREEN_WIDTH) / 2.f);
        make.width.equalTo(@(ACC_SCREEN_WIDTH));
        make.top.equalTo(self);
        if ([UIDevice acc_isIPhoneX]) {
            if ([AWEXScreenAdaptManager needAdaptScreen]) {
                if (ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay) && self.playerFrameValue) {
                    make.bottom.equalTo(self.mas_top).mas_offset(CGRectGetMaxY([self.playerFrameValue CGRectValue]) + 29);
                } else if ([UIDevice acc_isIPad]) {
                    make.bottom.equalTo(playerPreviewView?playerPreviewView.mas_bottom:self).offset(29);
                } else {
                    make.bottom.equalTo(playerPreviewView?playerPreviewView.mas_bottom:self).offset(64);
                }
            }
        } else {
            if (@available(iOS 10.0, *)) {
                make.bottom.equalTo(self);
            } else {
                make.height.mas_equalTo(ACC_SCREEN_HEIGHT);
            }
        }
    });
}

- (void)didChangeLocationWithOperationStickerView:(UIView *)stickerView
{
    if ([stickerView isKindOfClass:[ACCBaseStickerView class]]) {
        if (((ACCBaseStickerView *)stickerView).config.typeId == ACCStickerTypeIdCanvas) {
            return;
        }
    }
    CGRect rightRect = self.fakeProfileView.rightContainerView.frame;
    rightRect.origin.x -= 2;
    CGRect playerFrame = [self.stickerContainer playerRect];
    if (playerFrame.size.width < self.acc_width) {
        rightRect.origin.x -= (self.acc_width - playerFrame.size.width) / 2.f;
    }
    if (!CGRectIsNull(CGRectIntersection(stickerView.frame, rightRect))) {
        self.fakeProfileView.rightContainerView.hidden = NO;
    } else {
        self.fakeProfileView.rightContainerView.hidden = YES;
    }
    
    CGRect bottomRect = self.fakeProfileView.bottomContainerView.frame;
    bottomRect.origin.y -= 2;
    if (!CGRectIsNull(CGRectIntersection(stickerView.frame, bottomRect))) {
        self.fakeProfileView.bottomContainerView.hidden = NO;
    } else {
        self.fakeProfileView.bottomContainerView.hidden = YES;
    }
}

- (void)sticker:(nonnull ACCBaseStickerView *)stickerView didEndGesture:(nonnull UIGestureRecognizer *)gesture
{
    self.fakeProfileView.rightContainerView.hidden = YES;
    self.fakeProfileView.bottomContainerView.hidden = YES;
}

- (void)sticker:(nonnull ACCBaseStickerView *)stickerView didHandleGesture:(nonnull UIGestureRecognizer *)gesture
{
    
}

- (void)sticker:(nonnull ACCBaseStickerView *)stickerView willHandleGesture:(nonnull UIGestureRecognizer *)gesture
{
    
}

- (ACCStickerContainerFeature)implementedContainerFeature
{
    return ACCStickerContainerFeatureReserved;
}

- (BOOL)featureSupportSticker:(id<ACCStickerProtocol>)sticker
{
    if (![sticker.config isKindOfClass:[ACCCommonStickerConfig class]]) {
        return NO;
    }
    return [self implementedContainerFeature] & ((ACCCommonStickerConfig *)sticker.config).preferredContainerFeature;
}

#pragma mark - Public APIs
- (void)updateMusicCoverWithMusicModel:(id<ACCMusicModelProtocol>)model
{
    [self.fakeProfileView updateMusicCoverWithMusicModel:model];
}

@end
