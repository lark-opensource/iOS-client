//
//  ACCImageAlbumCropContentView.m
//  Indexer
//
//  Created by admin on 2021/11/11.
//

#import "ACCImageAlbumCropContentView.h"
#import "ACCImageAlbumData.h"
#import "ACCBubbleProtocol.h"
#import "ACCImageAlbumCropViewModel.h"

#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/ACCLogProtocol.h>

static const CGFloat kCropViewHorizontalMargin = 16.0;
static const CGFloat kLightFillLayerOpacity = 0.7;
static const CGFloat kDarkFillLayerOpacity = 0.8;

static NSString *const kCropContentViewShowBubbleViewKey = @"kCropContentViewShowBubbleViewKey";

/**
 1、ACCImageAlbumCropContentView 实际高度：self.height = ACC_SCREEN_HEIGHT - ACCImageAlbumCropControlViewHeight + ACCImageAlbumCropControlViewCornerRadius；
 2、CropView 边界参考区域：ACC_SCREEN_HEIGHT - ACCImageAlbumCropControlViewHeight - ACC_STATUS_BAR_NORMAL_HEIGHT；
 3、CropView 的实际宽高：宽高比小于 9:16 上下边距相对“CropView 边界参考区域”为16，否则左右边距相对“CropView 边界参考区域”为16；
 */

@interface ACCImageAlbumCropContentView () <UIScrollViewDelegate>

@property (nonatomic, assign) ACCImageAlbumItemCropRatio cropRatio;
@property (nonatomic, strong) ACCImageAlbumItemModel *imageAlbumItem;
@property (nonatomic, assign) CGFloat zoomScale;
@property (nonatomic, assign) CGPoint contentOffset;
@property (nonatomic, assign) CGRect accessCropRect;

@property (nonatomic, assign) CGSize originalImageSize;

@property (nonatomic, strong) UIScrollView *containerScrollView;
@property (nonatomic, strong) UIImageView *contentImageView;

@property (nonatomic, strong) UIView *cropView;
@property (nonatomic, strong) CAShapeLayer *fillLayer;
@property (nonatomic, strong) UIView *topHorizontalLineView;
@property (nonatomic, strong) UIView *bottomHorizontalLineView;
@property (nonatomic, strong) UIView *topVerticalLineView;
@property (nonatomic, strong) UIView *bottomVerticalLineView;
@property (nonatomic, strong) UIView *bubbleView;

@end

@implementation ACCImageAlbumCropContentView

- (instancetype)initWithData:(ACCImageAlbumItemModel *)imageAlbumItem
{
    CGFloat selfHeight = ACC_SCREEN_HEIGHT - ACCImageAlbumCropControlViewHeight + ACCImageAlbumCropControlViewCornerRadius;
    self = [super initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, selfHeight)];
    if (self) {
        _imageAlbumItem = imageAlbumItem;
        _cropRatio = imageAlbumItem.cropInfo.cropRatio;
        _zoomScale = imageAlbumItem.cropInfo.zoomScale;
        
        [self p_setupView];
        [self p_addCropFillLayer];
        [self p_addCropAlignLine];
        
        self.contentImageView.image = [self p_getOriginalImageWithImageItemModel:imageAlbumItem];
        [self p_resetImageViewFrame];
        [self.containerScrollView setZoomScale:self.zoomScale animated:NO];
        self.containerScrollView.contentOffset = imageAlbumItem.cropInfo.contentOffset;
        
        self.cropView.frame = [self p_cropViewFrame:self.cropRatio];
        [self p_setupBubbleView];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.cropView.frame = [self p_cropViewFrame:self.cropRatio];
    
    if (self.bubbleView) {
        [ACCBubble() redoLayout:self.bubbleView];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self.cropView) {
        return self.containerScrollView;
    }

    return view;
}

#pragma mark - Public

// 切换了比例选择
- (void)updateCropView:(ACCImageAlbumItemCropRatio)cropRatio
{
    self.cropRatio = cropRatio;
    
    [self p_resetCropFillLayer];
    [self p_resetCropAlignLine];
    if (self.zoomScale > 1.0) {
        // 有过放大则不能再resetImageViewFrame，因为会把放大系数给resset（imageView的size会乘上放大系数）
        // 切换比例后，如果cropViewFrame变化了则contentImageView.image也会发生变化，同时contentSize也要跟着变
        CGRect originalImageViewFrame = [self p_imageViewFrame];
        CGRect imageViewFrame = CGRectMake(originalImageViewFrame.origin.x,
                                           originalImageViewFrame.origin.y,
                                           originalImageViewFrame.size.width * self.zoomScale,
                                           originalImageViewFrame.size.height * self.zoomScale);
        self.contentImageView.frame = imageViewFrame;
        self.containerScrollView.contentSize = imageViewFrame.size;
        [self p_resetContentInsets];
    } else {
        [self p_resetImageViewFrame];
    }
    
    [self setNeedsLayout];
}

- (CGPoint)contentOffset
{
    return self.containerScrollView.contentOffset;
}

- (CGRect)accessCropRect
{
    // 将子视图 self.cropView 的 frame 转换到 self.contentImageView 上
    CGRect cropRect = [self convertRect:self.cropView.frame toView:self.contentImageView];
    
    CGFloat scale = 1.0;  // 用于裁切的尺寸应该是相对于 image.size，而不是 imageView.size
    // 因为图片刚好填满 contentImageView，而 contentImageView 又与 cropView 视觉上的关系是 AspectFill，所以必然会有一个边是视觉上相等的，以相等的这个边为基准算一个比例关系
    if ([self p_imageViewFrame].size.height == CGRectGetHeight(self.cropView.frame)) {
        if (CGRectGetHeight(self.cropView.frame)) {
            scale = self.originalImageSize.height / CGRectGetHeight(self.cropView.frame);
        }
    } else {
        if (CGRectGetWidth(self.cropView.frame) > 0) {
            scale = self.originalImageSize.width / CGRectGetWidth(self.cropView.frame);
        }
    }
    
    return CGRectMake(CGRectGetMinX(cropRect) * scale,
                      CGRectGetMinY(cropRect) * scale,
                      CGRectGetWidth(cropRect) * scale,
                      CGRectGetHeight(cropRect) * scale);
}

#pragma mark - UIScrollViewDelegate - Scroll

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.fillLayer.opacity = kLightFillLayerOpacity;
    [self setNeedsDisplay];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        self.fillLayer.opacity = kDarkFillLayerOpacity;
        [self setNeedsDisplay];
        [self p_selectionFeedback];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.fillLayer.opacity = kDarkFillLayerOpacity;
    [self setNeedsDisplay];
    [self p_selectionFeedback];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self p_resetContentInsets];
}

#pragma mark - UIScrollViewDelegate - Zoom

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.contentImageView;
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    self.fillLayer.opacity = kLightFillLayerOpacity;
    [self p_removeBubbleView];
    [self setNeedsDisplay];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{
    self.fillLayer.opacity = kDarkFillLayerOpacity;
    self.zoomScale = scale;
    CGSize cropViewSize = [self p_cropViewFrame:self.cropRatio].size;
    CGSize contentImageViewSize = self.contentImageView.frame.size;
    if (contentImageViewSize.width < cropViewSize.width || contentImageViewSize.height < cropViewSize.height) {
        // 边框发生变化后，这里与[scrollView setMinimumZoomScale:1.0]会有冲突，所以会顿一下
        [UIView animateWithDuration:0.25 animations:^{
            [self p_resetImageViewFrame];
        }];
    }
    
    [self setNeedsDisplay];
    
    if ([self.delegate respondsToSelector:@selector(didEndZoom:)]) {
        [self.delegate didEndZoom:scale];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    
}

#pragma mark - Private

- (void)p_addCropFillLayer
{
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:self.bounds];
    UIBezierPath *innerPath = [UIBezierPath bezierPathWithRect:[self p_cropViewFrame:self.cropRatio]];
    [path appendPath:innerPath];
    [path setUsesEvenOddFillRule:YES];
    
    CAShapeLayer *fillLayer = [CAShapeLayer layer];
    fillLayer.path = path.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.fillColor = UIColor.blackColor.CGColor;
    fillLayer.opacity = kDarkFillLayerOpacity;
    self.fillLayer = fillLayer;
    [self.layer addSublayer:fillLayer];
}

- (void)p_resetCropFillLayer
{
    [self.fillLayer removeFromSuperlayer];
    [self p_addCropFillLayer];
}

- (void)p_addCropAlignLine
{
    CGSize cropViewSize = [self p_cropViewFrame:self.cropRatio].size;
    
    UIView *topHorizontalLineView = [UIView.alloc init];
    topHorizontalLineView.backgroundColor = UIColor.whiteColor;
    self.topHorizontalLineView = topHorizontalLineView;
    [self.cropView addSubview:topHorizontalLineView];
    ACCMasMaker(topHorizontalLineView, {
        make.leading.trailing.equalTo(self.cropView);
        make.height.mas_equalTo(0.5);
        make.top.equalTo(self.cropView).offset(cropViewSize.height / 3.0);
    });
    
    UIView *bottomHorizontalLineView = [UIView.alloc init];
    bottomHorizontalLineView.backgroundColor = UIColor.whiteColor;
    self.bottomHorizontalLineView = bottomHorizontalLineView;
    [self.cropView addSubview:bottomHorizontalLineView];
    ACCMasMaker(bottomHorizontalLineView, {
        make.leading.trailing.equalTo(self.cropView);
        make.height.mas_equalTo(0.5);
        make.top.equalTo(self.cropView).offset(cropViewSize.height * 2.0 / 3.0);
    });
    
    UIView *topVerticalLineView = [UIView.alloc init];
    topVerticalLineView.backgroundColor = UIColor.whiteColor;
    self.topVerticalLineView = topVerticalLineView;
    [self.cropView addSubview:topVerticalLineView];
    ACCMasMaker(topVerticalLineView, {
        make.top.bottom.equalTo(self.cropView);
        make.width.mas_equalTo(0.5);
        make.leading.equalTo(self.cropView).offset(cropViewSize.width / 3.0);
    });
    
    UIView *bottomVerticalLineView = [UIView.alloc init];
    bottomVerticalLineView.backgroundColor = UIColor.whiteColor;
    self.bottomVerticalLineView = bottomVerticalLineView;
    [self.cropView addSubview:bottomVerticalLineView];
    ACCMasMaker(bottomVerticalLineView, {
        make.top.bottom.equalTo(self.cropView);
        make.width.mas_equalTo(0.5);
        make.leading.equalTo(self.cropView).offset(cropViewSize.width * 2.0 / 3.0);
    });
}

- (void)p_resetCropAlignLine
{
    [self.topHorizontalLineView removeFromSuperview];
    [self.bottomHorizontalLineView removeFromSuperview];
    [self.topVerticalLineView removeFromSuperview];
    [self.bottomVerticalLineView removeFromSuperview];
    [self p_addCropAlignLine];
}

- (CGRect)p_cropViewFrame:(ACCImageAlbumItemCropRatio)cropRatio
{
    switch (cropRatio) {
        case ACCImageAlbumItemCropRatioOriginal: {
            if (self.originalImageSize.height > 0) {
                return [self p_originalCropViewFrameWithRatio:self.originalImageSize.width / self.originalImageSize.height];
            } else {
                return self.bounds;
            }
            break;
        }
            
        case ACCImageAlbumItemCropRatio9_16: {
            return [self p_cropViewFrameWithRatio:9.0 / 16.0];
            break;
        }
            
        case ACCImageAlbumItemCropRatio3_4:
            return [self p_cropViewFrameWithRatio:3.0 / 4.0];
            break;
            
        case ACCImageAlbumItemCropRatio1_1:
            return [self p_cropViewFrameWithRatio:1.0];
            break;
            
        case ACCImageAlbumItemCropRatio4_3:
            return [self p_cropViewFrameWithRatio:4.0 / 3.0];
            break;
            
        case ACCImageAlbumItemCropRatio16_9:
            return [self p_cropViewFrameWithRatio:16.0 / 9.0];
            break;
            
        default:
            return self.bounds;
            break;
    }
}

- (CGRect)p_originalCropViewFrameWithRatio:(CGFloat)cropRatio
{
    CGFloat ratio9_14 = 9.0 / 14.0;  // 9:16=0.5625，9:15=0.6
    CGFloat ratio3_4 = 3.0 / 4.0;
    if (cropRatio <= ratio9_14) {
        return [self p_cropViewFrameWithRatio:9.0 / 16.0];
    } else if (cropRatio <= ratio3_4) {
        return [self p_cropViewFrameWithRatio:ratio3_4];
    } else {
        return [self p_cropViewFrameWithRatio:cropRatio];
    }
}

- (CGRect)p_cropViewFrameWithRatio:(CGFloat)cropRatio
{
    CGFloat cropViewX, cropViewY, cropViewWidth, cropViewHeight;
    // cropView的限定框，即：屏幕高度 - 顶部栏 - controlViewHeight
    CGFloat containerViewHeight = ACC_SCREEN_HEIGHT - ACC_STATUS_BAR_NORMAL_HEIGHT - ACCImageAlbumCropControlViewHeight;
    if (cropRatio <= 9.0 / 16.0) {
        cropViewHeight = containerViewHeight - kCropViewHorizontalMargin * 2.0;
        cropViewWidth = cropViewHeight * cropRatio;
    } else {
        cropViewWidth = ACC_SCREEN_WIDTH - kCropViewHorizontalMargin * 2.0;
        cropViewHeight = cropViewWidth / cropRatio;
    }
    cropViewX = (ACC_SCREEN_WIDTH - cropViewWidth) / 2.0;
    cropViewY = (containerViewHeight - cropViewHeight) / 2.0 + ACC_STATUS_BAR_NORMAL_HEIGHT;
    return CGRectMake(cropViewX, cropViewY, cropViewWidth, cropViewHeight);
}

- (UIImage *)p_getOriginalImageWithImageItemModel:(ACCImageAlbumItemModel *)itemModel
{
    NSString *originalImagePath = itemModel.backupImageInfo.getAbsoluteFilePath;
    if (ACC_isEmptyString(originalImagePath)) {
        originalImagePath = itemModel.originalImageInfo.getAbsoluteFilePath;
    }
    
    UIImage *originalImage = [UIImage imageWithContentsOfFile:originalImagePath];
    if (!originalImage) {
        AWELogToolError(AWELogToolTagEdit, @"ACCImageAlbumCropContentView: get original image failed, originalImagePath = %@", originalImagePath);
    }
    return originalImage;
}

- (void)p_resetImageViewFrame
{
    CGRect imageViewFrame = [self p_imageViewFrame];
    self.contentImageView.frame = imageViewFrame;
    // 放大后 contentSize 会变大，乘以放大倍数
    self.containerScrollView.contentSize = imageViewFrame.size;
    [self p_resetContentInsets];
}

- (CGRect)p_imageViewFrame
{
    CGRect cropViewFrame = [self p_cropViewFrame:self.cropRatio];
    CGFloat imageViewWidth = cropViewFrame.size.width;
    CGFloat imageViewHeight = cropViewFrame.size.height;
    CGFloat imageViewX = cropViewFrame.origin.x;
    CGFloat imageViewY = cropViewFrame.origin.y;
    
    CGFloat cropViewRatio = cropViewFrame.size.width / cropViewFrame.size.height;
    CGFloat imageViewRatio = self.contentImageView.image.size.width / self.contentImageView.image.size.height;
    if (imageViewRatio < cropViewRatio) {
        imageViewHeight = imageViewWidth / imageViewRatio;
        imageViewY -= (imageViewHeight - cropViewFrame.size.height) / 2.0;
    } else if (imageViewRatio > cropViewRatio) {
        imageViewWidth = imageViewHeight * imageViewRatio;
        imageViewX -= (imageViewWidth - cropViewFrame.size.width) / 2.0;
    }
    return CGRectMake(imageViewX, imageViewY, imageViewWidth, imageViewHeight);
}

- (void)p_resetContentInsets
{
    CGRect cropViewFrame = [self p_cropViewFrame:self.cropRatio];
    CGRect imageViewFrame = [self p_imageViewFrame];
    CGFloat imageViewWidth = imageViewFrame.size.width;
    CGFloat imageViewHeight = imageViewFrame.size.height;
    CGFloat cropViewWidth = cropViewFrame.size.width;
    CGFloat cropViewHeight = cropViewFrame.size.height;
    CGFloat insetTop = (imageViewHeight - cropViewHeight) / 2.0;
    CGFloat insetLeft = (imageViewWidth - cropViewWidth) / 2.0;
    CGFloat insetBottom = self.bounds.size.height - cropViewHeight - insetTop;
    CGFloat insetRight = self.bounds.size.width - cropViewWidth - insetLeft;
    self.containerScrollView.contentInset = UIEdgeInsetsMake(insetTop, insetLeft, insetBottom, insetRight);
}

- (void)p_selectionFeedback
{
    if (@available(iOS 11.0, *)) {
        UISelectionFeedbackGenerator *feedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        [feedbackGenerator prepare];
        [feedbackGenerator selectionChanged];
    }
}

- (void)p_setupBubbleView
{
    BOOL hasShownBubbleView = [ACCCache() boolForKey:kCropContentViewShowBubbleViewKey];
    if (hasShownBubbleView) {
        return;
    }
    
    UIImageView *iconView = [UIImageView.alloc initWithFrame:CGRectMake(8.0, 0, 22.0, 42.0)];
    iconView.image = ACCResourceImage(@"image_album_crop_zoom_guide");
    iconView.contentMode = UIViewContentModeCenter;
    
    self.bubbleView = [ACCBubble() showBubble:@"使用双指可以缩放图片"
                                      forView:self.cropView
                                     iconView:iconView
                              inContainerView:self
                               iconViewInsets:UIEdgeInsetsZero
                                   fromAnchor:CGPointZero
                             anchorAdjustment:CGPointMake(0, 65.0)
                             cornerAdjustment:CGPointZero
                                    fixedSize:CGSizeZero
                                    direction:ACCBubbleDirectionUp
                                      bgStyle:ACCBubbleBGStyleDefault
                                 showDuration:CGFLOAT_MAX
                                   completion:^{}];
    self.bubbleView.userInteractionEnabled = NO;
}

- (void)p_removeBubbleView
{
    if (self.bubbleView) {
        [ACCCache() setBool:YES forKey:kCropContentViewShowBubbleViewKey];
        [ACCBubble() removeBubble:self.bubbleView];
        self.bubbleView = nil;
    }
}

- (void)p_setupView
{
    self.backgroundColor = ACCResourceColor(ACCColorToastDefault);
    
    [self addSubview:self.containerScrollView];
    [self.containerScrollView addSubview:self.contentImageView];
    [self addSubview:self.cropView];
}

#pragma mark - Getter

- (UIScrollView *)containerScrollView
{
    if (!_containerScrollView) {
        _containerScrollView = ({
            UIScrollView *scrollView = [UIScrollView.alloc initWithFrame:self.bounds];
            scrollView.delegate = self;
            [scrollView setMinimumZoomScale:1.0];
            [scrollView setMaximumZoomScale:4.0];
            scrollView.showsVerticalScrollIndicator = NO;
            scrollView.showsHorizontalScrollIndicator = NO;
            if (@available(iOS 11.0, *)) {
                scrollView.insetsLayoutMarginsFromSafeArea = NO;
                scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            } else {
                
            }
            scrollView;
        });
    }
    return _containerScrollView;
}

- (UIImageView *)contentImageView
{
    if (!_contentImageView) {
        _contentImageView = ({
            UIImageView *imageView = [UIImageView.alloc initWithFrame:self.bounds];
            imageView.contentMode = UIViewContentModeScaleAspectFill;
            imageView.layer.masksToBounds = YES;
            imageView;
        });
    }
    return _contentImageView;
}

- (UIView *)cropView
{
    if (!_cropView) {
        _cropView = ({
            UIView *view = [UIView.alloc init];
            view.layer.borderColor = UIColor.whiteColor.CGColor;
            view.layer.borderWidth = 1.0;
            view;
        });
    }
    return _cropView;
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
