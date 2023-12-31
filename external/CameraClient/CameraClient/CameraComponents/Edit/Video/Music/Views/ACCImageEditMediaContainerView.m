//
//  ACCImageEditMediaContainerView.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/23.
//

#import "ACCImageEditMediaContainerView.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCConfigKeyDefines.h"
#import "AWEXScreenAdaptManager.h"
#import <CreativeKit/ACCMacros.h>

@interface ACCImageEditMediaContainerView ()

@property (nonatomic, assign, readwrite) CGRect originalPlayerFrame;
@property (nonatomic, assign, readwrite) CGRect videoContentFrame;
@property (nonatomic, assign, readwrite) CGRect editPlayerFrame;
@property (nonatomic, assign, readwrite) CGSize containerSize;
@property (nonatomic, assign) BOOL needAdaptForXScreen;

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;

@end

@implementation ACCImageEditMediaContainerView
@synthesize coverImage = _coverImage;
@synthesize boomerangIndicatorView = _boomerangIndicatorView;
@synthesize coverImageView = _coverImageView;
@synthesize contentModeFit = _contentModeFit;


- (instancetype)initWithPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    if (self = [super init]) {
        _publishModel = publishModel;
        _containerSize = [ACCImageEditMediaContainerView imagePlayerDefaultContainerSize];
        _originalPlayerFrame = [UIScreen mainScreen].bounds;
        if ([AWEXScreenAdaptManager needAdaptScreen]) {
            _needAdaptForXScreen = ACCViewFrameOptimizeContains(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize), ACCViewFrameOptimizeFullDisplay);
        }
        _editPlayerFrame = _originalPlayerFrame;
    }
    return self;
}

- (void)builder
{
    CGRect playerFrame = [self mediaBigMediaFrameForSize:self.containerSize];
    self.originalPlayerFrame = playerFrame;
    self.editPlayerFrame = playerFrame;
    self.frame = playerFrame;
    self.layer.masksToBounds = YES;
    
    if (!self.needAdaptForXScreen && [AWEXScreenAdaptManager needAdaptScreen]) {
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        
        CGRect rect = CGRectMake(0, 0, CGRectGetWidth(playerFrame), CGRectGetHeight(playerFrame));
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(12.0, 12.0)];
        maskLayer.path = path.CGPath;
        self.layer.mask = maskLayer;
    }
}

- (CGRect)mediaBigMediaFrameForSize:(CGSize)size
{
    return [ACCImageEditMediaContainerView mediaBigMediaFrameForSize:size];
}

+ (CGRect)mediaBigMediaFrameForSize:(CGSize)size
{
    CGRect standRect = CGRectMake(0, 0, size.width, size.height);
    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        if ([UIDevice acc_isIPad]) {
            standRect = CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT - 49 - ACC_SafeAreaInsets.bottom);
        } else {
            standRect = [AWEXScreenAdaptManager standPlayerFrame];
        }
    }
    
    CGRect playerFrame = standRect;

    if (AWECGRectIsNaN(playerFrame)) {
        playerFrame = [AWEXScreenAdaptManager standPlayerFrame];
    }
    
    return playerFrame;
}

- (BOOL)isPlayerContainsRect:(CGRect)rect
{
    return CGRectContainsRect(self.originalPlayerFrame, rect);
}

+ (CGSize)imagePlayerDefaultContainerSize
{
    CGSize containerSize = [UIScreen mainScreen].bounds.size;
    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        containerSize = [AWEXScreenAdaptManager standPlayerFrame].size;
    }
    return containerSize;
}

+ (CGRect)imagePlayerDefaultOriginalFrame
{
    return [self mediaBigMediaFrameForSize:[self imagePlayerDefaultContainerSize]];
}

#pragma mark - unsupported for image edit mode

- (void)updateOriginalFrameWithSize:(CGSize)size
{
    // unsupported feature for image edit mode
}

- (void)resetView
{
    self.frame = [self mediaBigMediaFrameForSize:self.containerSize];
}

- (UIImageView *)coverImageView
{
    if (!_coverImageView) {
        _coverImageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _coverImageView.hidden = YES;
    }
    return _coverImageView;
}

@end
