//
//  EMAShowImageView.m
//  Article
//
//  Created by Zhang Leonardo on 12-11-12.
//  Edited by Cao Hua from 13-10-12.
//  Edited by 武嘉晟 from 20-01-20.
//  这个12年的老代码写的不好，日后如果有需求，推荐彻底推翻使用swift重构
//

#import <OPFoundation/BDPI18n.h>
#import "EMAImageLoadingView.h"
#import <OPFoundation/EMAMonitorHelper.h>
#import <ECOInfra/EMANetworkManager.h>
#import "EMAShowImageView.h"
#import "EMAUIShortTapGestureRecognizer.h"
#import <OPFoundation/UIImage+EMA.h>
#import <CoreGraphics/CoreGraphics.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <ECOInfra/OPError.h>

#define MaxZoomScale 2.5f
#define MinZoomScale 1.f

@interface EMAShowImageView() <UIScrollViewDelegate, UIGestureRecognizerDelegate, NSURLSessionDownloadDelegate>

/// 成功回调
@property (nonatomic, copy, nullable) dispatch_block_t success;
/// 失败回调
@property (nonatomic, copy, nullable) void (^failure)(NSString * _Nullable msg);
@property(nonatomic, strong) NSURLSession *session;
@property(nonatomic, strong)UIScrollView * imageContentScrollView;
@property(nonatomic, strong)UIImageView * largeImageView;
@property(nonatomic, strong)EMAUIShortTapGestureRecognizer * tapTwiceGestureRecognizer;
@property(nonatomic, strong)ALAssetsLibrary * assetsLbr;
// Loading progress view
@property(nonatomic, strong)EMAImageLoadingView * imageloadingProgressView;
@property(nonatomic, assign, readwrite)BOOL isDownloading;
@property(nonatomic, assign, readwrite)CGFloat loadingProgress;
@property(nonatomic, strong)NSDate *singleTapTime;

@end

@implementation EMAShowImageView
{
    int _currentTryIndex;
}

- (instancetype)initWithFrame:(CGRect)frame
                      success:(dispatch_block_t)success
                      failure:(void(^ _Nullable )(NSString  * _Nullable msg))failure {
    if (self = [super initWithFrame:frame]) {
        _currentTryIndex = 0;
        _isDownloading = NO;
        _success = success;
        _failure = failure;

        [self buildViews];
        [self addGesture];
        
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)dealloc {
    /// 这里之前的老代码质量比较差，在init和dealloc方法中请使用实例变量进行读写
    [_session invalidateAndCancel];
    _session = nil;
    _delegate = nil;
    _imageContentScrollView.delegate = nil;
    _imageContentScrollView = nil;
    _largeImageView = nil;
    _tapGestureRecognizer.delegate = nil;
    [self removeGestureRecognizer:_tapGestureRecognizer];
    _tapGestureRecognizer = nil;
    _tapTwiceGestureRecognizer.delegate = nil;
    [self removeGestureRecognizer:_tapTwiceGestureRecognizer];
    _tapTwiceGestureRecognizer = nil;
    _assetsLbr = nil;
    _placeholderImage = nil;
    _imageloadingProgressView = nil;
}


- (void)layoutSubviews
{
    [super layoutSubviews];
    BOOL singleTapDuration = NO;
    if (_singleTapTime){
        singleTapDuration = [[NSDate new] timeIntervalSinceDate:_singleTapTime] < .5;
    }
    if (!singleTapDuration){
        [self refreshUI];
        _imageloadingProgressView.center = CGPointMake(self.bdp_width / 2.0, self.bdp_height / 2.0);
    }
}

#pragma mark -- target

- (void)saveImage
{
    if (!self.hasImage) {
        return;
    }
    
    self.assetsLbr = nil;
    self.assetsLbr = [[ALAssetsLibrary alloc] init];

    NSData *gifData = [self.largeImageView.image ema_gifRepresentation];
    if (gifData) {
        // 保存gif
        [_assetsLbr ema_saveImageData:gifData window:self.window];
    }else {
        [_assetsLbr ema_saveImage:self.image window:self.window];
    }
}

#pragma mark -- private

- (void)addGesture
{
    // tapTwiceGestureRecognizer
    self.tapTwiceGestureRecognizer = [[EMAUIShortTapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapped:)];
    _tapTwiceGestureRecognizer.numberOfTapsRequired = 2;
    [self addGestureRecognizer:_tapTwiceGestureRecognizer];
    
    // tapGestureRecognizer
    self.tapGestureRecognizer = [[EMAUIShortTapGestureRecognizer alloc] initWithTarget:self action:@selector(onceTapped:)];
    _tapGestureRecognizer.numberOfTapsRequired = 1;
    //_tapGestureRecognizer.delegate = self;
    [_tapGestureRecognizer requireGestureRecognizerToFail:_tapTwiceGestureRecognizer];
    [self addGestureRecognizer:_tapGestureRecognizer];

}


- (void)buildViews {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame =self.bounds;
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:button];
    self.imageContentScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.imageContentScrollView.scrollsToTop = NO;
    _imageContentScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    _imageContentScrollView.contentSize = self.bounds.size;
    _imageContentScrollView.delegate = self;
    _imageContentScrollView.backgroundColor = [UIColor clearColor];
    _imageContentScrollView.minimumZoomScale = MinZoomScale;
    _imageContentScrollView.maximumZoomScale = MaxZoomScale;
    //_imageContentScrollView.alwaysBounceHorizontal = YES;
    
    [self addSubview:_imageContentScrollView];
    
    // image loading progress view
    self.imageloadingProgressView = [[EMAImageLoadingView alloc] init];
    _imageloadingProgressView.center = CGPointMake(self.bdp_width / 2.0, self.bdp_height / 2.0);
    _imageloadingProgressView.hidden = YES;
    [self addSubview:_imageloadingProgressView];

    self.largeImageView = [EMAAnimationView animationView];
    _largeImageView.contentMode = UIViewContentModeScaleAspectFill;
    _largeImageView.clipsToBounds = YES;
    _largeImageView.backgroundColor = [UIColor clearColor];
    [_imageContentScrollView addSubview:self.largeImageView];
}

- (UIImageView * _Nullable)imageView {
    return _largeImageView;
}

- (void)refreshUI
{
    _imageContentScrollView.zoomScale = MinZoomScale;
    _imageContentScrollView.frame = self.bounds;

    [self refreshLargeImageViewOrigin];
    [self refreshLargeImageViewSizeWithImage:self.imageView.image];
    _imageContentScrollView.contentSize = self.imageView.frame.size;
    [self refreshLargeImageViewOrigin];
    
    _imageContentScrollView.contentOffset = CGPointZero;
    if ([[UIDevice currentDevice] orientation] != UIDeviceOrientationLandscapeLeft && [[UIDevice currentDevice] orientation] != UIDeviceOrientationLandscapeRight){
        self.largeImageView.center = CGPointMake(self.largeImageView.center.x, self.largeImageView.center.y);
    }
}

- (void)refreshLargeImageViewOrigin
{
#warning to be add !!!! @yadong
    //[[TTPhotoDetailManager shareInstance] setTransitionActionValid:YES];
    
    float imageViewW = self.imageView.frame.size.width;
    float parentViewW = _imageContentScrollView.frame.size.width;
    
    float imageViewH = self.imageView.frame.size.height;
    float parentViewH = _imageContentScrollView.frame.size.height;
    
    float centerW = 0.f;
    float centerH = 0.f;
    
    if (imageViewW <= parentViewW) {
        centerW = parentViewW / 2.f;
    }
    else {
        centerW = imageViewW / 2.f;
#warning to be add !!!! @yadong
        //[[TTPhotoDetailManager shareInstance] setTransitionActionValid:NO];
    }
    
    if (imageViewH <= parentViewH) {
        centerH = parentViewH / 2.f;
    }
    else {
        centerH = imageViewH / 2.f;
#warning to be add !!!! @yadong
        //[[TTPhotoDetailManager shareInstance] setTransitionActionValid:NO];
    }
    CGPoint newCenter = CGPointMake(centerW, centerH);
    self.imageView.center = newCenter;

}

- (void)refreshLargeImageViewSizeWithImage:(UIImage *)img
{
    if(img == nil){
        self.imageView.frame = CGRectZero;
    } else {
        CGFloat imageWidth = img.size.width;
        CGFloat imageHeight = img.size.height;
        
        CGFloat maxWidth = CGRectGetWidth(self.bounds);
        CGFloat maxHeight = CGRectGetHeight(self.bounds);
        
        CGFloat imgViewWidth;
        CGFloat imgViewHeight;
        
        // 普通图片(除细长图外)适配屏幕宽高比等比缩放；
        // 默认 imageHeight >= imageWidth * 3 的图片为细长图，宽度按屏幕宽处理，高度等比缩放。
        if (imageWidth/imageHeight > maxWidth/maxHeight || imageHeight >= imageWidth * 3) {
            imgViewWidth = maxWidth;
            imgViewHeight = maxWidth * imageHeight / imageWidth;
        } else {
            imgViewHeight = maxHeight;
            imgViewWidth = imageWidth / imageHeight * maxHeight;
        }
        
        self.imageView.frame = CGRectMake(0, 0, imgViewWidth, imgViewHeight);
    }
    #warning to be add !!!! @yadong
    //[[TTPhotoDetailManager shareInstance] setTransitionActionValid:YES];
}

- (void)loadFinishedWithImage:(UIImage *)image
{
    [self.largeImageView setImage:image];

    [self loadFailed];
}

- (void)loadFinished
{
    [self.largeImageView sizeToFit];
    [self refreshUI];
    self.placeholderImage = self.image;
}

- (void)loadFailed
{
    _imageloadingProgressView.hidden = YES;
    [EMAHUD showFailure:BDPI18n.loading_failed window:self.window];
}

#pragma mark -- getter & setter

- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:EMANetworkManager.shared.urlSession.configuration.copy delegate:self delegateQueue:nil];
    }
    return _session;
}

- (void)setLargeImageURLRequest:(NSURLRequest *)largeImageURLRequest {
    _imageloadingProgressView.hidden = YES;
    /// TODO:后期优化，如果设置同样的图片，不用重新下载
    _largeImageURLRequest = largeImageURLRequest;
    [self.largeImageView setImage:_placeholderImage];
    [self downloadImageWithURLRequest:largeImageURLRequest];

}

- (void)replaceLargeImageURLRequest:(NSURLRequest *)largeImageURLRequest {
    self.placeholderImage = self.image;
    self.largeImageURLRequest = largeImageURLRequest;
}

- (void)setImage:(UIImage *)image
{
    _imageloadingProgressView.hidden = YES;
    [self loadFinishedWithImage:image];
}

- (UIImage *)image
{
    return self.largeImageView.image ?: self.placeholderImage;
}

- (BOOL)hasImage {
    return self.image != nil;
}

- (void)setAsset:(ALAsset *)asset
{
    _imageloadingProgressView.hidden = YES;
    if (_asset != asset) {
        _asset = asset;
        if (_asset) {
            [self loadImageFromAsset:_asset];
        }
    }
}

#pragma mark -- UIScrollViewDelegate

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self refreshLargeImageViewOrigin];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return [self imageView];
}

- (void)onceTapped:(UITapGestureRecognizer *)recognizer
{
    self.singleTapTime = [[NSDate alloc] init];
    if (_delegate && [_delegate respondsToSelector:@selector(showImageViewOnceTap:)]) {
        [_delegate performSelector:@selector(showImageViewOnceTap:) withObject:self];
    }
}   

- (void)doubleTapped:(UITapGestureRecognizer *)recognizer
{
    [_imageContentScrollView setZoomScale:(_imageContentScrollView.zoomScale==MaxZoomScale?MinZoomScale:MaxZoomScale)
                                 animated:YES];
    if (_delegate && [_delegate respondsToSelector:@selector(showImageViewDoubleTap:)]) {
        [_delegate performSelector:@selector(showImageViewDoubleTap:) withObject:self];
    }

}

#pragma mark -- public

- (void)resetZoom
{
    _imageContentScrollView.zoomScale = MinZoomScale;
}

#pragma mark - download image data

- (void)downloadImageWithURLRequest:(NSURLRequest *)request {
    BDPMonitorWithName(kEventName_ema_image_preview, nil).kv(@"load_status", @"load").flush();
    if (!request) {
        BDPMonitorWithName(kEventName_ema_image_preview, nil).kv(@"load_status", @"url_empty").flush();
        !self.failure ?: self.failure(@"request is empty");
        self.failure = nil;
        self.success = nil;
        return;
    }

    self.isDownloading = YES;
    // 延迟0.5秒出现，避免一闪过的情况
    _imageloadingProgressView.alpha = 0;
    WeakSelf;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        StrongSelfIfNilReturn;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.3];
        self.imageloadingProgressView.alpha = 1;
        [UIView commitAnimations];
    });

    _imageloadingProgressView.hidden = NO;
    _imageloadingProgressView.loadingProgress = 0;
    NSTimeInterval startTime = [NSDate date].timeIntervalSince1970;
    __block NSInteger imageFileSize = 0;

    self.largeImageView.image = _placeholderImage;
    /// 如果是GET就走原来的能力，不是的话，走新能力
    if (![request.HTTPMethod isEqualToString:@"GET"]) {
        /// 不可以使用回调类型的task，否则不会走代理方法的
        NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithRequest:request];
        [downloadTask resume];
        /// 加了下面一行可能会出现crash，但是不加可能会内存泄漏，老代码太难改造了
        //        [self.session finishTasksAndInvalidate];
        return;
    }

    NSMutableDictionary *headers = NSMutableDictionary.dictionary;
    /// 这里兼容一下老逻辑
    if (self.header) {
        [headers addEntriesFromDictionary:self.header];
    }
    /// 如果是GET方法，也需要补充header
    if (request.allHTTPHeaderFields) {
        [headers addEntriesFromDictionary:request.allHTTPHeaderFields];
    }
    
    
    [self.largeImageView ema_setImageWithUrl:request.URL placeHolder:_placeholderImage headers:headers progressBlock:^(int64_t receivedSize, int64_t expectedSize) {
        StrongSelfIfNilReturn;
        /// 进度回调需要处理UI的
        imageFileSize  = MAX(expectedSize, receivedSize);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imageloadingProgressView.loadingProgress = ((CGFloat)receivedSize)/expectedSize;
        });
    } completionBlock:^(UIImage * _Nullable image, NSURL * _Nullable url, BOOL fromCache, OPError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            StrongSelfIfNilReturn;
            self.isDownloading = NO;
            if (error) {
                self.imageloadingProgressView.hidden = YES;
                BDPLogError(@"downloadImageWithUrl action: end, event: wx.previewImage, %@", BDPParamStr(request.URL.absoluteString, error));
                BDPMonitorWithName(kEventName_ema_image_preview, nil).kv(@"load_status", @"download_error").kv(@"download_error_code", error.code).flush();

                [self loadFailed];
                !self.failure ?: self.failure(error.localizedDescription);
                self.failure = nil;
                self.success = nil;
                return;
            }
            !self.success ?: self.success();
            self.failure = nil;
            self.success = nil;
            self.imageloadingProgressView.hidden = YES;
            [self loadFinished];

            // 如果是从缓存中取图片，不打点
            if (!fromCache) {
                NSTimeInterval interval = [NSDate date].timeIntervalSince1970 - startTime;
                CGFloat scale = [UIScreen mainScreen].scale;
                NSString *imageResolution = NSStringFromCGSize(CGSizeMake(image.size.width * image.scale, image.size.height * image.scale));
                CGSize screenSize = [UIScreen mainScreen].bounds.size;
                NSString *screenResolution = NSStringFromCGSize(CGSizeMake(screenSize.width * scale, screenSize.height * scale));
                BDPMonitorWithName(kEventName_ema_image_preview, nil)
                .kv(@"duration", interval * 1000)
                .kv(@"image_size", imageFileSize / 1024)
                .kv(@"image_resolution",imageResolution)
                .kv(@"screen_resolution",screenResolution)
                .flush();
            }
        });
    }];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    if (!error) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        !self.failure ?: self.failure(error.localizedDescription);
        self.failure = nil;
        self.success = nil;
        self.imageloadingProgressView.hidden = YES;
        BDPLogError(@"downloadImageWithUrl action: end, event: wx.previewImage, %@", BDPParamStr(task.currentRequest.URL.absoluteString, error));
        BDPMonitorWithName(kEventName_ema_image_preview, nil).kv(@"load_status", @"download_error").kv(@"download_error_code", error.code).flush();
        [self loadFailed];
    });
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    dispatch_async(dispatch_get_main_queue(), ^{
        !self.success ?: self.success();
        self.failure = nil;
        self.success = nil;
        self.imageloadingProgressView.hidden = YES;
        [self loadFinished];
    });
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageloadingProgressView.loadingProgress = (CGFloat)totalBytesWritten/totalBytesExpectedToWrite;
    });
}


- (void)loadImageFromAsset:(ALAsset *)asset {
    if (asset) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            UIImage * image = [ALAssetsLibrary ema_getBigImageFromAsset:asset];
            if (image) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    [self loadFinishedWithImage:image];
                });
            }
        });
    }
}

- (CGPoint)touchPointInImageLocation:(CGPoint)touchPoint {

    CGPoint contentOffset =  _imageContentScrollView.contentOffset;
    CGPoint imagePoint = _largeImageView.frame.origin;

    CGPoint leftTop = CGPointMake(contentOffset.x + touchPoint.x - imagePoint.x, contentOffset.y + touchPoint.y - imagePoint.y);

    CGFloat scale = _largeImageView.image.size.width / _largeImageView.bdp_size.width;
    return CGPointMake(leftTop.x  * scale, leftTop.y  * scale);
}

@end
