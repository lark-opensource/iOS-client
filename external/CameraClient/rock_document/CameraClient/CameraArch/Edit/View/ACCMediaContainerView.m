//
//  ACCMediaContainerView.m
//  CameraClient-Pods-Aweme
//
//  Created by Liu Deping on 2020/12/6.
//

#import "AWERepoVideoInfoModel.h"
#import "AWERepoContextModel.h"
#import "ACCMediaContainerView.h"
#import "AWEXScreenAdaptManager.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitInfra/ACCMakeRect.h>
#import "ACCConfigKeyDefines.h"
#import "AWEXScreenAdaptManager.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCRTL.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

static CGFloat kAWETolerance = 0.01;

typedef NS_ENUM(NSInteger, ACCPlayerExtensionDirectionType) {
    ACCPlayerExtensionDirectionNone = 0,            // 未扩展
    ACCPlayerExtensionDirectionHorizontal = 1,      // 左右加黑框
    ACCPlayerExtensionDirectionVertical = 2,        // 上下加黑框
};

@interface ACCMediaContainerView ()

@property (nonatomic, assign, readwrite) CGRect originalPlayerFrame;
@property (nonatomic, assign, readwrite) CGRect videoContentFrame;
@property (nonatomic, assign, readwrite) CGRect editPlayerFrame;
@property (nonatomic, assign, readwrite) CGSize containerSize;

@property (nonatomic, weak) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, assign) BOOL needAdaptForXScreen;
@property (nonatomic, assign) ACCPlayerExtensionDirectionType extensionDirectionType;

@end

@implementation ACCMediaContainerView
@synthesize coverImage = _coverImage;
@synthesize boomerangIndicatorView = _boomerangIndicatorView;
@synthesize coverImageView = _coverImageView;
@synthesize contentModeFit = _contentModeFit;

- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    if (self = [super initWithFrame:CGRectZero]) {
        _publishModel = publishModel;
        _containerSize = [UIScreen mainScreen].bounds.size;
        if ([AWEXScreenAdaptManager needAdaptScreen]) {
            _containerSize = [AWEXScreenAdaptManager standPlayerFrame].size;
            _needAdaptForXScreen = ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay);
        }
    }
    return self;
}

- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}


- (void)builder
{
    CGRect playerFrame = [self mediaBigMediaFrameForSize:self.containerSize];
    self.frame = playerFrame;
    
    if (!self.coverImageView.superview) {
        [self addSubview:self.coverImageView];
    }
    
    if (self.coverImage) {
        self.coverImageView.hidden = NO;
        self.coverImageView.image = self.coverImage;
    }
    
    if (self.publishModel.repoContext.videoRecordType == AWEVideoRecordTypeBoomerang) {
        if (!self.boomerangIndicatorView) {
            self.boomerangIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        }
        [self addSubview:self.boomerangIndicatorView];
        self.boomerangIndicatorView.center = CGPointMake(CGRectGetWidth(self.bounds) / 2.0, CGRectGetHeight(self.bounds) / 2.0);
        [self.boomerangIndicatorView startAnimating];
    }
    
    if (!self.needAdaptForXScreen) {
        CAShapeLayer *maskLayer = [AWEXScreenAdaptManager maskLayerWithPlayerFrame:playerFrame];
        if (maskLayer) {
            self.layer.mask = maskLayer;
        }
    }
}

#pragma mark - Helper

- (void)updateOriginalFrameWithSize:(CGSize)size
{
    CGRect standRect = CGRectMake(0, 0, size.width, size.height);
    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        if ([UIDevice acc_isIPad]) {
            standRect = [AWEXScreenAdaptManager customFullFrame];
        } else {
            standRect = [AWEXScreenAdaptManager standPlayerFrame];
        }
    }
    CGRect playerFrame = standRect;
    NSValue *sizeOfVideoValue = nil;
    if (self.publishModel.repoContext.isQuickStoryPictureVideoType || self.publishModel.repoContext.videoType == AWEVideoTypeStoryPicVideo) {
        if (!CGSizeEqualToSize(self.publishModel.repoUploadInfo.toBeUploadedImage.size, CGSizeZero)) {
            sizeOfVideoValue = [NSValue valueWithCGSize:self.publishModel.repoUploadInfo.toBeUploadedImage.size];
        }
    } else {
        sizeOfVideoValue = [self.publishModel.repoVideoInfo sizeOfVideo];
    }
    
    if (sizeOfVideoValue && !AWECGSizeIsNaN(sizeOfVideoValue.CGSizeValue) ) {
        CGSize sizeOfVideo = [sizeOfVideoValue CGSizeValue];
        CGSize sizeOfScreen = standRect.size;
        
        CGFloat videoScale = sizeOfVideo.width / sizeOfVideo.height;
        CGFloat screenScale = sizeOfScreen.width / sizeOfScreen.height;
        
        CGFloat playerWidth = 0;
        CGFloat playerHeight = 0;
        CGFloat playerX = 0;
        CGFloat playerY = 0;
        
        if (self.publishModel.repoDuet.isDuet) {
            //duet的视频 产品要求可以被全部展示
            playerFrame = AVMakeRectWithAspectRatioInsideRect(sizeOfVideo, standRect);
        } else if ([UIDevice acc_isIPhoneX]) {
            if (videoScale > 9.0 / 16.0 + kAWETolerance) {//两边不裁剪
                playerFrame = AVMakeRectWithAspectRatioInsideRect(sizeOfVideo, playerFrame);
            } else if ([AWEXScreenAdaptManager needAdaptScreen]) {
                // 全面屏适配用高度
                playerHeight = standRect.size.height;
                playerWidth = playerHeight * videoScale;
                playerY = standRect.origin.y;
                playerX = - (playerWidth - standRect.size.width) * 0.5;
                playerFrame = CGRectMake(playerX, playerY, playerWidth, playerHeight);
            } else if (videoScale > screenScale) {//按高度
                playerHeight = standRect.size.height;
                playerWidth = playerHeight * videoScale;
                playerY = standRect.origin.y;
                playerX = - (playerWidth - standRect.size.width) * 0.5;
                playerFrame = CGRectMake(playerX, playerY, playerWidth, playerHeight);
            } else {//按宽度
                playerWidth = standRect.size.width;
                playerHeight = playerWidth / videoScale;
                playerX = 0;
                playerY = - (playerHeight - standRect.size.height) * 0.5;
                playerFrame = CGRectMake(playerX, playerY, playerWidth, playerHeight);
            }
        } else {
            //不是iphoneX全使用fit方式
            playerFrame = AVMakeRectWithAspectRatioInsideRect(sizeOfVideo, playerFrame);
        }
    }

    self.originalPlayerFrame = playerFrame;
}

- (CGRect)mediaBigMediaFrameForSize:(CGSize)size
{
    CGRect standRect = CGRectMake(0, 0, size.width, size.height);
    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        if ([UIDevice acc_isIPad]) {
            standRect = [AWEXScreenAdaptManager customFullFrame];
        } else {
            standRect = [AWEXScreenAdaptManager standPlayerFrame];
        }
    }
    CGRect playerFrame = standRect;
    NSValue *sizeOfVideoValue = [self sizeOfVideo];
    
    if (sizeOfVideoValue) {
        CGSize sizeOfVideo = [sizeOfVideoValue CGSizeValue];
        CGSize sizeOfScreen = standRect.size;
        
        CGFloat videoScale = sizeOfVideo.width / sizeOfVideo.height;
        CGFloat screenScale = sizeOfScreen.width / sizeOfScreen.height;
        
        CGFloat playerWidth = 0;
        CGFloat playerHeight = 0;
        CGFloat playerX = 0;
        CGFloat playerY = 0;
        
        if (self.needAdaptForXScreen) {
            BOOL aspectFill = [AWEXScreenAdaptManager aspectFillForRatio:sizeOfVideo isVR:NO];
            if (aspectFill) {
                playerFrame = ACCMakeRectWithAspectRatioOutsideRect(sizeOfVideo, standRect);
            } else {
                playerFrame = AVMakeRectWithAspectRatioInsideRect(sizeOfVideo, standRect);
            }
        } else {
            if (self.publishModel.repoDuet.isDuet) {
                //duet的视频 产品要求可以被全部展示
                playerFrame = AVMakeRectWithAspectRatioInsideRect(sizeOfVideo, standRect);
            } else if ([UIDevice acc_isIPhoneX]) {
                if (videoScale > 9.0 / 16.0 + kAWETolerance) {//两边不裁剪
                    playerFrame = AVMakeRectWithAspectRatioInsideRect(sizeOfVideo, playerFrame);
                } else if ([AWEXScreenAdaptManager needAdaptScreen]) {
                    // 全面屏适配用高度
                    playerHeight = standRect.size.height;
                    playerWidth = playerHeight * videoScale;
                    playerY = standRect.origin.y;
                    playerX = - (playerWidth - standRect.size.width) * 0.5;
                    playerFrame = CGRectMake(playerX, playerY, playerWidth, playerHeight);
                } else if (videoScale > screenScale) {//按高度
                    playerHeight = standRect.size.height;
                    playerWidth = playerHeight * videoScale;
                    playerY = standRect.origin.y;
                    playerX = - (playerWidth - standRect.size.width) * 0.5;
                    playerFrame = CGRectMake(playerX, playerY, playerWidth, playerHeight);
                } else {//按宽度
                    playerWidth = standRect.size.width;
                    playerHeight = playerWidth / videoScale;
                    playerX = 0;
                    playerY = - (playerHeight - standRect.size.height) * 0.5;
                    playerFrame = CGRectMake(playerX, playerY, playerWidth, playerHeight);
                }
            } else {
                //不是iphoneX全使用fit方式
                playerFrame = AVMakeRectWithAspectRatioInsideRect(sizeOfVideo, playerFrame);
            }
        }
    }
        
    playerFrame = [self resetPlayerFrame:playerFrame sizeOfVideo:sizeOfVideoValue];
    
    if (AWECGRectIsNaN(playerFrame)) {
        playerFrame = [AWEXScreenAdaptManager standPlayerFrame];
    }
    
    return playerFrame;
}

- (CGRect)resetPlayerFrame:(CGRect)frame sizeOfVideo:(NSValue *)sizeOfVideoValue
{
    self.originalPlayerFrame = frame;
    
    if (self.needAdaptForXScreen &&
        sizeOfVideoValue != nil) {
        CGSize sizeOfVideo = [sizeOfVideoValue CGSizeValue];
        CGFloat ratioOfVideo = sizeOfVideo.width / sizeOfVideo.height;
        // IM相册超长图片可能黑屏或崩溃,实验添加保护逻辑
        NSInteger kConfigRatio = ACCConfigInt(kConfigInt_im_edit_long_picture_extension_horizontal);
        BOOL isOverLong = kConfigRatio > 0 && ratioOfVideo < 1./kConfigRatio;
        if ([AWEXScreenAdaptManager aspectFillForRatio:sizeOfVideo isVR:NO]
            && !isOverLong) {
            self.extensionDirectionType = ACCPlayerExtensionDirectionNone;
        } else {
            frame = [AWEXScreenAdaptManager standPlayerFrame];
            if (ratioOfVideo > (9. / 16.)) {
                // Top-bottom black edge
                self.extensionDirectionType = ACCPlayerExtensionDirectionVertical;
            } else {
                self.extensionDirectionType = ACCPlayerExtensionDirectionHorizontal;
            }
        }
    } else {
        CGSize size = frame.size;
        CGPoint origin = frame.origin;
        
        CGFloat standRatio = 9.0 / 16.0;
        CGFloat ratio = size.height > 0 ? size.width / size.height : standRatio;
        
        if (ratio - standRatio > kAWETolerance) {
            CGFloat height = size.width / standRatio;
            origin.y = origin.y - (height - size.height) * 0.5;
            size.height = height;
            self.extensionDirectionType = ACCPlayerExtensionDirectionVertical;
        }
        
        if (standRatio - ratio > kAWETolerance) {
            CGFloat width = size.height * standRatio;
            origin.x = origin.x - (width - size.width) * 0.5;
            size.width = width;
            self.extensionDirectionType = ACCPlayerExtensionDirectionHorizontal;
        }
        
        frame.size = size;
        frame.origin = origin;
    }
    
    self.editPlayerFrame = frame;
    
    return frame;
}

- (NSValue *)sizeOfVideo
{
    NSValue * sizeOfVideoValue = nil;
    if (self.publishModel.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone) {
        sizeOfVideoValue = @(CGSizeMake(1080, 1920));
    } else if (self.publishModel.repoContext.videoType == AWEVideoTypeStoryPicture || self.publishModel.repoContext.isQuickStoryPictureVideoType || self.publishModel.repoContext.videoType == AWEVideoTypeStoryPicVideo) {
        if (!CGSizeEqualToSize(self.publishModel.repoUploadInfo.toBeUploadedImage.size, CGSizeZero)) {
            sizeOfVideoValue = [NSValue valueWithCGSize:self.publishModel.repoUploadInfo.toBeUploadedImage.size];
        }
    } else {
        sizeOfVideoValue = [self.publishModel.repoVideoInfo sizeOfVideo];
    }
    if (sizeOfVideoValue && !AWECGSizeIsNaN(sizeOfVideoValue.CGSizeValue)) {
        return sizeOfVideoValue;
    }
    return nil;
}

- (BOOL)isPlayerContainsRect:(CGRect)rect
{
    if (ACC_FLOAT_EQUAL_ZERO(rect.size.width) && ACC_FLOAT_EQUAL_ZERO(rect.size.width)) {
        return YES;
    }
    
    CGRect playerRect = self.originalPlayerFrame;
    if (self.extensionDirectionType == ACCPlayerExtensionDirectionNone) {
        return CGRectContainsRect(playerRect, rect);
    }
    
    if (self.extensionDirectionType == ACCPlayerExtensionDirectionHorizontal) {
        return CGRectGetMinX(rect) > CGRectGetMinX(playerRect) && CGRectGetMaxX(rect) < CGRectGetMaxX(playerRect);
    }
    
    if (self.extensionDirectionType == ACCPlayerExtensionDirectionVertical) {
        return CGRectGetMinY(rect) > CGRectGetMinY(playerRect) && CGRectGetMaxY(rect) < CGRectGetMaxY(playerRect);
    }
    
    return NO;
}

- (void)resetView
{
    self.containerSize = [UIScreen mainScreen].bounds.size;
    self.frame = [self mediaBigMediaFrameForSize:self.containerSize];

    CGSize videoSize = [[self sizeOfVideo] CGSizeValue];
    if (videoSize.width > 0 && videoSize.height > 0) {
        self.publishModel.repoVideoInfo.videoFrameRatio = videoSize.width / videoSize.height;
    }
}

#pragma mark - getter

- (UIImageView *)coverImageView
{
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _coverImageView.accrtl_viewType = ACCRTLViewTypeNormal;
        _coverImageView.contentMode = UIViewContentModeScaleAspectFit;
        _coverImageView.backgroundColor = [UIColor blackColor];
        _coverImageView.hidden = YES;
    }
    
    return _coverImageView;
}

- (CGRect)originalPlayerFrame
{
    if ([self.publishModel.repoContext supportNewEditClip]) {
        CGRect standRect = CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT);
        if ([AWEXScreenAdaptManager needAdaptScreen]) {
            if ([UIDevice acc_isIPad]) {
                standRect = [AWEXScreenAdaptManager customFullFrame];
            } else {
                standRect = [AWEXScreenAdaptManager standPlayerFrame];
            }
        }
        [self updateOriginalFrameWithSize:standRect.size];
        return _originalPlayerFrame;
    } else {
        return _originalPlayerFrame;
    }
}

@end
