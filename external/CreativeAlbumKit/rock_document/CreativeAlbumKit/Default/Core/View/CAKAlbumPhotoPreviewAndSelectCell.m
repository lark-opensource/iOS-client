//
//  CAKAlbumPhotoPreviewAndSelectCell.m
//  AWEStudio
//
//  Created by xulei on 2020/3/15.
//
#import <CreativeKit/ACCMacros.h>

#import "CAKAlbumPhotoPreviewAndSelectCell.h"
#import "CAKLanguageManager.h"
#import "CAKToastProtocol.h"
#import "CAKPhotoManager.h"
#import "CAKAlbumAssetModel.h"
#import <CreationKitInfra/ACCLogHelper.h>

@interface CAKAlbumPhotoPreviewAndSelectCell() <UIScrollViewDelegate>
@property (nonatomic, assign) int32_t imageRequestID;
@property (nonatomic, assign) CGFloat zoomScaleBeforeZooming;
@end

@implementation CAKAlbumPhotoPreviewAndSelectCell

- (instancetype) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]){
        self.backgroundColor = [UIColor blackColor];

        self.imageView = [[UIImageView alloc] init];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
        [doubleTapGesture setNumberOfTapsRequired:2];
        [self.imageView addGestureRecognizer:doubleTapGesture];
        self.imageView.userInteractionEnabled = YES;
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
    if (@available(iOS 11.0, *)) {
        self.zoomScrollView.insetsLayoutMarginsFromSafeArea = NO;
        self.zoomScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    self.zoomScrollView.delegate = self;
    [self.contentView addSubview:self.zoomScrollView];
    [self.zoomScrollView addSubview:self.imageView];
    self.imageView.transform = CGAffineTransformIdentity;
}

- (void)configCellWithAsset:(CAKAlbumAssetModel *)assetModel withPlayFrame:(CGRect)playFrame greyMode:(BOOL)greyMode
{
    [super configCellWithAsset:assetModel withPlayFrame:playFrame greyMode:greyMode];
    [self setupZoomScrollView];
    self.imageView.image = assetModel.coverImage;
    @weakify(self);
    int32_t imageRequestID = [CAKPhotoManager getUIImageWithPHAsset:assetModel.phAsset networkAccessAllowed:NO progressHandler:^(CGFloat progress, NSError * _Nonnull error, BOOL * _Nonnull stop, NSDictionary * _Nonnull info) {
        if (error) {
            AWELogToolInfo(AWELogToolTagImport, @"upload: preview fetch photo with error : %@", error);        }
    } completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        @strongify(self);
        if ([[info objectForKey:PHImageResultIsInCloudKey] boolValue]) {
            NSTimeInterval icloudFetchStart = CFAbsoluteTimeGetCurrent();
            [CAKPhotoManager getPhotoDataFromICloudWithAsset:assetModel.phAsset progressHandler:^(CGFloat progress, NSError *error, BOOL *stop, NSDictionary *info) {
                if (error) {
                    AWELogToolInfo(AWELogToolTagImport, @"upload: preview fetch photo with error : %@", error);
                }
            } completion:^(NSData *data, NSDictionary *info) {
                @strongify(self);
                if (data) {
                    NSInteger duration = (NSInteger)((CFAbsoluteTimeGetCurrent() - icloudFetchStart) * 1000);
                    ACCBLOCK_INVOKE(self.fetchIcloudCompletion, duration, data.length);

                    UIImage *iCloudImage = [UIImage imageWithData:data];
                    self.imageView.frame = self.contentView.frame;
                    self.imageView.image = iCloudImage;
                    assetModel.coverImage = iCloudImage;
                } else {
                    [CAKPhotoManager cancelImageRequest:self.imageRequestID];
                }
            }];
            [CAKToastShow() showToast:CAKLocalizedString(@"creation_icloud_download", @"Syncing from iCloud...")];
        } else {
            if (photo) {
                self.imageView.frame = self.contentView.frame;
                if (assetModel.coverImage == nil) {
                    self.imageView.image = photo;
                }
            } else {
                [CAKPhotoManager cancelImageRequest:self.imageRequestID];
            }
            if (!isDegraded) {
                if (photo) {
                    assetModel.coverImage = photo;
                    self.imageView.image = photo;
                }
                self.imageRequestID = 0;
            }
        }
    }];
    
    if (imageRequestID && self.imageRequestID && self.imageRequestID != imageRequestID) {
        [CAKPhotoManager cancelImageRequest:self.imageRequestID];
    }
    self.imageRequestID = imageRequestID;
}

-(void)removeCoverImageView{
    
}

- (void)setPlayerLayer:(AVPlayerLayer *)playerLayer withPlayerFrame:(CGRect)playerFrame{
    
}

- (CGSize)p_resizeFromSize:(CGSize)size toWidth:(CGFloat)width
{
    if (size.width > 0) {
        return CGSizeMake(width, size.height / size.width * width);
    } else {
        return CGSizeMake(0, 0);
    }
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
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    CGFloat xcenter = scrollView.frame.size.width / 2;
    CGFloat ycenter = scrollView.frame.size.height / 2;
    xcenter = scrollView.contentSize.width > scrollView.frame.size.width ? scrollView.contentSize.width / 2 : xcenter;
    ycenter = scrollView.contentSize.height > scrollView.frame.size.height ? scrollView.contentSize.height / 2 : ycenter;
    self.imageView.center = CGPointMake(xcenter, ycenter);
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
