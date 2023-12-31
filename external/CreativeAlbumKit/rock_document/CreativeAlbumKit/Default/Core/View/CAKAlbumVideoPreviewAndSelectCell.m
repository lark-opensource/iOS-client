//
//  CAKAlbumVideoPreviewAndSelectCell.m
//  AWEStudio
//
//  Created by xulei on 2020/3/15.
//
//#import <CameraClient/UIView+ACCRTL.h>
#import <AVFoundation/AVFoundation.h>
#import <CreativeKit/ACCMacros.h>

#import "CAKAlbumVideoPreviewAndSelectCell.h"
#import "CAKLanguageManager.h"
#import "CAKToastProtocol.h"
#import "CAKPhotoManager.h"
#import "CAKAlbumAssetModel.h"

@interface CAKAlbumVideoPreviewAndSelectCell () <UIScrollViewDelegate>

@property (nonatomic, strong) UIImage *coverImage;
@property (nonatomic, assign) int32_t imageRequestID;
@property (nonatomic, assign) CGFloat zoomScaleBeforeZooming;

@end

@implementation CAKAlbumVideoPreviewAndSelectCell

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentView.backgroundColor = [UIColor blackColor];
        self.contentView.clipsToBounds = YES;
        
        self.coverImageView = [[UIImageView alloc] init];
        self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
//        self.contentView.accrtl_viewType = ACCRTLViewTypeNormal;
        [self setupZoomScrollView];
    }
    return self;
}

- (void)setupZoomScrollView
{
    [self.zoomScrollView removeFromSuperview];
    self.zoomScrollView = nil;
    self.zoomScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.zoomScrollView.showsVerticalScrollIndicator = NO;
    self.zoomScrollView.showsHorizontalScrollIndicator = NO;
    self.zoomScrollView.scrollEnabled = NO;
    if (@available(iOS 11.0, *)) {
        self.zoomScrollView.insetsLayoutMarginsFromSafeArea = NO;
        self.zoomScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    self.zoomScrollView.delegate = self;
    
    [self.contentView addSubview:self.zoomScrollView];
    [self.zoomScrollView addSubview:self.coverImageView];
}

- (void)configCellWithAsset:(CAKAlbumAssetModel *)assetModel withPlayFrame:(CGRect)playFrame greyMode:(BOOL)greyMode{
    [super configCellWithAsset:assetModel withPlayFrame:playFrame greyMode:greyMode];
    [self setupZoomScrollView];
    self.zoomScrollView.scrollEnabled = NO;
    self.zoomScrollView.contentOffset = CGPointZero;
    self.coverImageView.image = assetModel.coverImage;
    self.coverImageView.hidden = NO;
    @weakify(self);
    int32_t imageRequestID = [CAKPhotoManager getUIImageWithPHAsset:assetModel.phAsset networkAccessAllowed:NO progressHandler:^(CGFloat progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
        
    } completion:^(UIImage * _Nonnull photo, NSDictionary * _Nonnull info, BOOL isDegraded) {
        @strongify(self);
        if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue]) {
            [CAKPhotoManager getOriginalPhotoDataFromICloudWithAsset:assetModel.phAsset progressHandler:^(CGFloat progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
            } completion:^(NSData * _Nonnull data, NSDictionary * _Nonnull info) {
            }];
            [CAKToastShow() showToast:CAKLocalizedString(@"creation_icloud_download", @"Syncing from iCloud...")];
        } else {
            if (photo) {
                self.coverImageView.frame = playFrame;
                self.coverImageView.image = photo;
            } else {
                [CAKPhotoManager cancelImageRequest:self.imageRequestID];
            }
            if (!isDegraded) {
                self.imageRequestID = 0;
            }
        }
    }];
    
    if (imageRequestID && self.imageRequestID && self.imageRequestID != imageRequestID) {
        [CAKPhotoManager cancelImageRequest:self.imageRequestID];
    }
    self.imageRequestID = imageRequestID;
}

- (void)setPlayerLayer:(AVPlayerLayer *)playerLayer withPlayerFrame:(CGRect)playerFrame {
    [self setupZoomScrollView];
    self.zoomScrollView.scrollEnabled = NO;
    self.zoomScrollView.contentOffset = CGPointZero;
    self.playerView = [[UIView alloc] initWithFrame:playerFrame];
    [self.zoomScrollView insertSubview:self.playerView belowSubview:self.coverImageView];
    playerLayer.frame = self.playerView.bounds;
    [self.playerView.layer addSublayer:playerLayer];
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    [doubleTapGesture setNumberOfTapsRequired:2];
    [self.playerView addGestureRecognizer:doubleTapGesture];
    self.playerView.userInteractionEnabled = YES;
}

- (void)removeCoverImageView{
    self.coverImageView.hidden = YES;
}

- (void)handleDoubleTap:(UIGestureRecognizer *)gesture
{
    CGFloat zoomScale = self.zoomScrollView.zoomScale == 1.0 ? 3.0 : 1.0;
    CGPoint center = [gesture locationInView:gesture.view];
    CGRect zoomRect;
    zoomRect.size.height = self.zoomScrollView.frame.size.height / zoomScale;
    zoomRect.size.width = self.zoomScrollView.frame.size.width / zoomScale;
    zoomRect.origin.x = center.x - zoomRect.size.width / 2.0;
    zoomRect.origin.y = center.y - zoomRect.size.height / 2.0;
    [self.zoomScrollView zoomToRect:zoomRect animated:YES];
}

#pragma mark - UIScrollViewDelegate
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.playerView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGFloat xcenter = scrollView.frame.size.width / 2;
    CGFloat ycenter = scrollView.frame.size.height / 2;
    xcenter = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView.contentSize.width / 2 : xcenter;
    ycenter = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView.contentSize.height / 2 : ycenter;
    self.playerView.center = CGPointMake(xcenter, ycenter);
    if (scrollView.zoomScale == 1) {
        scrollView.scrollEnabled = NO;
    } else {
        scrollView.scrollEnabled = YES;
    }
    ACCBLOCK_INVOKE(self.scrollViewDidZoomBlock, scrollView.zoomScale);
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    self.zoomScaleBeforeZooming = scrollView.zoomScale;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    BOOL isZoomIn = scale > self.zoomScaleBeforeZooming ? YES : NO;
    ACCBLOCK_INVOKE(self.scrollViewDidEndZoomBlock, scrollView.zoomScale, isZoomIn);
}

@end
