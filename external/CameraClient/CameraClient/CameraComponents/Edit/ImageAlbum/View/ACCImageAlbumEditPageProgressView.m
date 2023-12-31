//
//  ACCImageAlbumEditPageProgressView.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/6/28.
//

#import "ACCImageAlbumEditPageProgressView.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogHelper.h>

static CGFloat const kItemGap    = 5.f;
static CGFloat const kItemHeight = 3.f;
static CGFloat const kItemTopInsert = 19.f;
static CGFloat const kItemBottomInsert = 10.f;
static CGFloat const kViewHInset = 12.f;

@interface ACCImageAlbumEditPageProgressView ()

@property (nonatomic, assign) CGFloat contentWidth;
@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, assign) NSInteger lastUpdateProgressPage;
@property (nonatomic, strong) UIView *progressView;

@end

@implementation ACCImageAlbumEditPageProgressView

- (instancetype)initWithViewWidth:(CGFloat)viewWidth
{
    if (self = [super initWithFrame:CGRectZero]) {
        _contentWidth = viewWidth - 2 * kViewHInset;
        NSParameterAssert(_contentWidth > 0);
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_tapGestureHandler:)];
        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:tapGesture];
    }
    return self;
}

#pragma mark - public
- (void)setNumberOfPages:(NSInteger)numberOfPages
{
    if (numberOfPages == _numberOfPages) {
        return;
    }
    _numberOfPages = numberOfPages;
    [self p_updateProgressParagraphShapeLayer];
}

- (void)setPageIndex:(NSInteger)pageIndex animation:(BOOL)animation
{
    if (_pageIndex == pageIndex) {
        return;
    }
    _pageIndex = pageIndex;
    [self p_updateProgressViewWithTargetPage:pageIndex animation:animation];
}

- (void)setUsingPageControlType:(BOOL)usingPageControlType
{
    if (_usingPageControlType == usingPageControlType) {
        return;
    }
    
    _usingPageControlType = usingPageControlType;
    [self p_updateProgressViewWithTargetPage:_pageIndex animation:NO];
}

- (void)pauseAnimation
{
    CFTimeInterval pauseTime = [self.progressView.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    self.progressView.layer.speed = 0.f;
    self.progressView.layer.timeOffset = pauseTime;
}

- (void)resetAnimation
{
    [self.progressView.layer removeAllAnimations];
    self.progressView.layer.speed = 1.0;
    self.progressView.layer.timeOffset = 0.0;
    self.progressView.layer.beginTime = 0.0;
}

#pragma mark - update handler
/* 采用镂空的方式来模拟多段样式，而不是初始化N个subView，大幅减少相关代码 */
- (void)p_updateProgressParagraphShapeLayer
{
    if (!self.active || self.numberOfPages <= 0 || [self p_getItemWidth] <= 0) {
        return;
    }

    UIBezierPath *allProgressItemPath = [UIBezierPath bezierPath];
    
    CGFloat itemWith = (self.contentWidth - kItemGap *(self.numberOfPages - 1)) / self.numberOfPages;
    
    // 将除了进度条区域以外的地方都镂空
    CGFloat py = kItemTopInsert;
    for (int i=0; i<self.numberOfPages; i++) {
        CGFloat px = kViewHInset + (itemWith + kItemGap) * i;
        UIBezierPath *itemPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(px, py, itemWith, kItemHeight) cornerRadius:kItemHeight / 2.f];
        [allProgressItemPath appendPath:itemPath];
    }
    
    CAShapeLayer *shapeLayer = [CAShapeLayer layer];
    shapeLayer.path = allProgressItemPath.CGPath;
    self.layer.mask = shapeLayer;
    
    [self setupViewIfNeed];
    
    // 避免立即设置动画后的影响
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)p_updateProgressViewWithTargetPage:(NSInteger)targetPage animation:(BOOL)animation
{
    if (!self.active || [self p_getItemWidth] <= 0 || targetPage > self.numberOfPages) {
        return;
    }
    
    if (self.usingPageControlType) {
        targetPage = targetPage + 1;
        animation = NO;
    }

    if (targetPage < self.lastUpdateProgressPage) {
        animation = NO;
    }
    
    AWELogToolInfo(AWELogToolTagEdit, @"\nImageAlbumEditPageProgress >>>><<<< targetPage:%@, animation:%@", @(targetPage), animation?@"YES":@"NO");
    
    self.lastUpdateProgressPage = targetPage;
    
    [self resetAnimation];
    
    CGFloat itemWith = [self p_getItemWidth];
    CGFloat targetWidth = itemWith  * targetPage;
    if (targetPage > 1) {
        targetWidth += (kItemGap * (targetPage - 1));
    }
    
    targetWidth = MIN(targetWidth, self.contentWidth);
    
    if (animation) {
        // 先重置到起点
        CGFloat startPx = targetWidth  - itemWith;
        ACCMasUpdate(self.progressView, {
            make.width.mas_equalTo(startPx);
        });
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
    
    ACCMasUpdate(self.progressView, {
        make.width.mas_equalTo(targetWidth);
    });
    
    if (animation) {
        // 短暂延迟避免快速滑动每次都漏出一点
        NSTimeInterval delay = 0.25;
        [UIView animateWithDuration:self.animationDuration - delay delay:delay options:UIViewAnimationOptionCurveLinear animations:^{
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
        }];
    } else {
        [self setNeedsLayout];
        [self layoutIfNeeded];
    }
}

#pragma mark - tapGesture
- (void)p_tapGestureHandler:(UITapGestureRecognizer *)tapGesture
{
    CGFloat px = [tapGesture locationInView:self].x;
    
    CGFloat itemWidth = [self p_getItemWidth];
    
    if (itemWidth <= 0.1f) {
        return;
    }
    
    // 相当于向下取整
    NSInteger index = (int)(px / (itemWidth + kItemGap));
    ACCBLOCK_INVOKE(self.selectedIndexHander, index);
}

#pragma mark - getter
+ (CGFloat)defaultHeight
{
    return kItemHeight + kItemTopInsert + kItemBottomInsert; // 扩大点击区域
}

- (CGFloat)p_getItemWidth
{
    if (self.numberOfPages <= 0) {
        return 0.f;
    }
    return (self.contentWidth - kItemGap *(self.numberOfPages - 1)) / self.numberOfPages;
}

#pragma mark - view
- (void)setupViewIfNeed
{
    if (self.progressView) {
        return;
    }
    
    self.layer.masksToBounds = YES;
    self.backgroundColor = ACCResourceColor(ACCColorConstTextInverse5);
    self.progressView = ({
        
        UIView *view = [[UIView alloc] init];
        view.userInteractionEnabled = NO;
        [self addSubview:view];
        view.backgroundColor = [UIColor whiteColor];
        view.layer.cornerRadius = kItemHeight / 2.f;
        ACCMasMaker(view, {
            make.top.equalTo(self).offset(kItemTopInsert);
            make.height.mas_equalTo(kItemHeight);
            make.left.equalTo(self).inset(kViewHInset);
            make.width.mas_equalTo(0.f);
        });
        view;
    });
}

@end
