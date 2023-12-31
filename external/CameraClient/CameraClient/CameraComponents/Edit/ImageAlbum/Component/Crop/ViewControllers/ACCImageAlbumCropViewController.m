//
//  ACCImageAlbumCropViewController.m
//  Indexer
//
//  Created by admin on 2021/11/8.
//

#import "ACCImageAlbumCropViewController.h"
#import "ACCImageAlbumCropContentView.h"
#import "ACCImageAlbumCropControlView.h"
#import "ACCImageAlbumCropViewModel.h"
#import "ACCImageAlbumData.h"
#import "ACCImageAlbumItemModel.h"

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>

static NSString *const kCropRatio9_16CountKey = @"kCropRatio9_16CountKey";

@interface ACCImageAlbumCropViewController () <ACCImageAlbumCropControlDelegate, ACCImageAlbumCropContentViewDelegate>

@property (nonatomic, strong) ACCImageAlbumItemModel *imageAlbumItem;
@property (nonatomic, strong) ACCImageAlbumCropContentView *cropContentView;
@property (nonatomic, strong) ACCImageAlbumCropControlView *cropControlView;
@property (nonatomic, copy) ConfirmBlock confirmBlock;
@property (nonatomic, copy) CancelBlock cancelBlock;
@property (nonatomic, copy) NSDictionary *commonTrackParams;
@property (nonatomic, assign) ACCImageAlbumItemCropRatio selectCropRatio;
@property (nonatomic, assign) CGFloat zoomScale;

@property (nonatomic, assign) CGSize originalImageSize;
@property (nonatomic, assign) BOOL showed9_16Toast;

@end

@implementation ACCImageAlbumCropViewController

- (instancetype)initWithData:(ACCImageAlbumItemModel *)imageAlbumItem
           commonTrackParams:(NSDictionary *)commonTrackParams
                confirmBlock:(ConfirmBlock)confirmBlock
                 cancelBlock:(CancelBlock)cancelBlock
{
    self = [super init];
    if (self) {
        _imageAlbumItem = imageAlbumItem;
        _confirmBlock = confirmBlock;
        _cancelBlock = cancelBlock;
        _commonTrackParams = commonTrackParams;
        _showed9_16Toast = NO;
        _selectCropRatio = _imageAlbumItem.cropInfo.cropRatio;
        _zoomScale = _imageAlbumItem.cropInfo.zoomScale;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupView];
    [self p_setupLayout];
}

#pragma mark - ACCImageAlbumCropControlDelegate

- (void)closeCrop
{
    [self p_trackCloseCrop];
    [self dismissViewControllerAnimated:YES completion:nil];
    ACCBLOCK_INVOKE(self.cancelBlock);
}

- (void)confirmCropRatio:(ACCImageAlbumItemCropRatio)cropRatio
{
    [self p_trackConfirmCropRatio:cropRatio];
    
    self.imageAlbumItem.cropInfo.cropRect = self.cropContentView.accessCropRect;
    self.imageAlbumItem.cropInfo.cropRatio = cropRatio;
    self.imageAlbumItem.cropInfo.zoomScale = self.cropContentView.zoomScale;
    self.imageAlbumItem.cropInfo.contentOffset = self.cropContentView.contentOffset;
    
    ACCBLOCK_INVOKE(self.confirmBlock, self.imageAlbumItem.cropInfo);
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)selectCropRatio:(ACCImageAlbumItemCropRatio)cropRatio
{
    self.selectCropRatio = cropRatio;
    [self.cropContentView updateCropView:cropRatio];
    [self p_showCropRatio9_16ToastIfNeeded:cropRatio];
    [self p_trackSelectCropRatio:cropRatio];
}

#pragma mark - ACCImageAlbumCropContentViewDelegate

- (void)didEndZoom:(CGFloat)zoomScale
{
    [self p_trackDidEndZoom:zoomScale];
    self.zoomScale = zoomScale;
}

#pragma mark - Private

- (void)p_setupView
{
    self.navigationController.navigationBarHidden = YES;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.view addSubview:self.cropContentView];
    [self.view addSubview:self.cropControlView];
}

- (void)p_setupLayout
{
    ACCMasMaker(self.cropControlView, {
        make.leading.trailing.bottom.equalTo(self.view);
        make.height.mas_equalTo(ACCImageAlbumCropControlViewHeight);
    });
    
    ACCMasMaker(self.cropContentView, {
        make.leading.trailing.top.equalTo(self.view);
        make.bottom.equalTo(self.cropControlView.mas_top).offset(ACCImageAlbumCropControlViewCornerRadius);
    });
}

- (void)p_showCropRatio9_16ToastIfNeeded:(ACCImageAlbumItemCropRatio)cropRatio
{
    if (self.showed9_16Toast) {
        return;
    }
    
    NSInteger cropRatio9_16Count = [ACCCache() integerForKey:kCropRatio9_16CountKey];
    if (cropRatio9_16Count >= 3) {
        return;
    }
    
    if (cropRatio == ACCImageAlbumItemCropRatio9_16) {
        [self p_showCropRatio9_16Toast];
        return;
    }
    
    if (cropRatio == ACCImageAlbumItemCropRatioOriginal && self.originalImageSize.height > 0) {
        CGFloat imageRatio = self.originalImageSize.width / self.originalImageSize.height;
        if (fabs(imageRatio - 9.0 / 16.0) < 1e-2) {
            [self p_showCropRatio9_16Toast];
            return;
        }
    }
}

- (void)p_showCropRatio9_16Toast
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [ACCToast() show:@"为保证全屏显示，该画幅下图片范围与裁切结果有差异" onView:self.view];
        self.showed9_16Toast = YES;
        NSInteger cropRatio9_16Count = [ACCCache() integerForKey:kCropRatio9_16CountKey];
        cropRatio9_16Count += 1;
        [ACCCache() setInteger:cropRatio9_16Count forKey:kCropRatio9_16CountKey];
    });
}

#pragma mark - Track

- (void)p_trackCloseCrop
{
    NSMutableDictionary *trackParams = [NSMutableDictionary dictionaryWithDictionary:self.commonTrackParams];
    [trackParams addEntriesFromDictionary:@{
        @"original_ratio": self.imageAlbumItem.cropInfo.cropRatioString
    }];
    [ACCTracker() trackEvent:@"close_photo_cut" params:trackParams.copy];
}

- (void)p_trackConfirmCropRatio:(ACCImageAlbumItemCropRatio)cropRatio
{
    NSMutableDictionary *trackParams = [NSMutableDictionary dictionaryWithDictionary:self.commonTrackParams];
    [trackParams addEntriesFromDictionary:@{
        @"change_photo_ratio": self.imageAlbumItem.cropInfo.cropRatio == cropRatio ? @"0" : @"1",
        @"photo_ratio": [ACCImageAlbumItemCropInfo cropRatioString:cropRatio],
        @"original_ratio": self.imageAlbumItem.cropInfo.cropRatioString,
        @"is_pinch": self.zoomScale == self.imageAlbumItem.cropInfo.zoomScale ? @"0" : @"1"  // 有缩放
    }];
    [ACCTracker() trackEvent:@"save_photo_cut" params:trackParams.copy];
}

- (void)p_trackSelectCropRatio:(ACCImageAlbumItemCropRatio)cropRatio
{
    NSMutableDictionary *trackParams = [NSMutableDictionary dictionaryWithDictionary:self.commonTrackParams];
    [trackParams addEntriesFromDictionary:@{
        @"photo_ratio": [ACCImageAlbumItemCropInfo cropRatioString:cropRatio],
        @"is_default": self.imageAlbumItem.cropInfo.cropRatio == cropRatio ? @"1" : @"0"
    }];
    [ACCTracker() trackEvent:@"click_cut_ratio" params:trackParams.copy];
}

- (void)p_trackDidEndZoom:(CGFloat)zoomScale
{
    if (self.zoomScale == zoomScale) {
        return;
    }
    
    NSMutableDictionary *trackParams = [NSMutableDictionary dictionaryWithDictionary:self.commonTrackParams];
    [trackParams addEntriesFromDictionary:@{
        @"photo_ratio": [ACCImageAlbumItemCropInfo cropRatioString:self.selectCropRatio],
        @"pinch_type": zoomScale > self.zoomScale ? @"zoom_in" : @"zoom_out"
    }];
    [ACCTracker() trackEvent:@"pinch_photo_cut" params:trackParams.copy];
}

#pragma mark - Getter

- (ACCImageAlbumCropContentView *)cropContentView
{
    if (!_cropContentView) {
        _cropContentView = ({
            ACCImageAlbumCropContentView *view = [ACCImageAlbumCropContentView.alloc initWithData:self.imageAlbumItem];
            view.delegate = self;
            view;
        });
    }
    return _cropContentView;
}

- (ACCImageAlbumCropControlView *)cropControlView
{
    if (!_cropControlView) {
        _cropControlView = ({
            ACCImageAlbumCropControlView *view = [ACCImageAlbumCropControlView.alloc initWithData:self.imageAlbumItem.cropInfo];
            CAShapeLayer *layer = [CAShapeLayer layer];
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:view.bounds
                                                       byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                             cornerRadii:CGSizeMake(ACCImageAlbumCropControlViewCornerRadius, ACCImageAlbumCropControlViewCornerRadius)];
            layer.path = path.CGPath;
            view.layer.mask = layer;
            view.delegate = self;
            view;
        });
    }
    return _cropControlView;
}

- (CGSize)originalImageSize
{
    NSString *originalImagePath = self.imageAlbumItem.backupImageInfo.getAbsoluteFilePath;
    if (!ACC_isEmptyString(originalImagePath) && [NSFileManager.defaultManager fileExistsAtPath:originalImagePath]) {
        return CGSizeMake(self.imageAlbumItem.backupImageInfo.width, self.imageAlbumItem.backupImageInfo.height);
    } else {
        return CGSizeMake(self.imageAlbumItem.originalImageInfo.width, self.imageAlbumItem.originalImageInfo.height);
    }
}

@end
