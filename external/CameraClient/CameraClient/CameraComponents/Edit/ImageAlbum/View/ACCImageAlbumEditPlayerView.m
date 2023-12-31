//
//  ACCImageAlbumEditPlayerView.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/14.
//

#import "ACCImageAlbumEditPlayerView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <Masonry/View+MASAdditions.h>
#import "ACCImageAlbumEditPlayerItemCell.h"
#import "ACCImageAlbumEditPageControl.h"
#import "ACCImageAlbumEditPageProgressView.h"
#import <CreativeKit/ACCMacros.h>
#import "AWEXScreenAdaptManager.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/NSTimer+ACCAdditions.h>
#import <CreationKitArch/AWEStudioExcludeSelfView.h>
#import "ACCConfigKeyDefines.h"
#import "ACCImageAlbumPageControlProtocol.h"
#import "ACCImageAlbumCombinedPageControl.h"

NS_INLINE NSIndexPath * kIndexPathForItem(NSInteger item)
{
    return [NSIndexPath indexPathForItem:item inSection:0];
}

@interface ACCImageAlbumEditColletionView : UICollectionView

@end

@implementation ACCImageAlbumEditColletionView

/// Because of, https://stackoverflow.com/questions/4585718/disable-uiscrollview-scrolling-when-uitextfield-becomes-first-responder
- (void)scrollRectToVisible:(CGRect)rect animated:(BOOL)animated
{
    
}

@end

@interface ACCImageAlbumEditPlayerView ()
<
UICollectionViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout
>

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIView<ACCImageAlbumPageControlProtocol> *pageControl;
@property (nonatomic, strong) ACCImageAlbumEditPageProgressView *pageProgressView;
@property (nonatomic, strong) UIView *scrollFakeAnimationContentView;
@property (nonatomic, strong) AWEStudioExcludeSelfView *interactionContainerView;

@property (nonatomic, strong) NSTimer *autoplayTimer;

@property (nonatomic, assign) CGSize lastUpdateCollectionViewSize;

@property (nonatomic, copy) NSArray <NSNumber *> *currentPreloadIndexs;

@property (nonatomic, assign) BOOL enableAutoPlay;

@property (nonatomic, assign) BOOL isScrollByDragFlag;

@property (nonatomic, assign) BOOL isRefactor;

@end

@implementation ACCImageAlbumEditPlayerView

#pragma mark - life cycle
- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        _scrollEnable = YES;

        _isRefactor = ACCConfigBool(kConfigBool_enable_image_album_preview_opt);
        
        [self setup];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_stopAutoplayTimer) name:UIApplicationWillResignActiveNotification object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_updateAutoplayStatus) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
}

- (void)reloadData
{
    [self setupViewsIfNeed];
    self.lastUpdateCollectionViewSize = self.collectionView.frame.size;
    
    [self p_updatePageControlActiveStatus];
    NSInteger itemCount = [self p_dataSourceCount];
    [self.pageControl resetTotalPageNum:itemCount currentPageIndex:0];
    self.pageProgressView.numberOfPages = itemCount;
    self.pageProgressView.animationDuration = self.autoPlayInterval;
    self.pageProgressView.usingPageControlType = (self.pageControlStyle == ACCImageAlbumEditorPageControlStyleProgressAsPageCotrol);
    [self.collectionView reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self p_stopAutoplayTimer];
}

#pragma mark - public
- (void)updateInteractionContainerAlpha:(CGFloat)alpha
{
    self.interactionContainerView.alpha = alpha;
}

- (void)scrollToIndex:(NSInteger)index
{
    [self scrollToIndex:index isByAuto:NO withAnimation:NO completion:nil];
}

- (void)scrollToIndex:(NSInteger)index
             isByAuto:(BOOL)isByAuto
        withAnimation:(BOOL)withAnimation
           completion:(void (^)(void))completion
{
    if (index < 0 || index >= [self p_dataSourceCount]) {
        NSAssert(NO, @"index out of bounce");
        ACCBLOCK_INVOKE(completion);
        return;
    }
    
    if (isByAuto) {
        self.isScrollByDragFlag = NO;
    }
    
    if ([self.delegate respondsToSelector:@selector(albumEditPlayerView:willScrollToIndex:withAnimation:isByAutoTimer:)]) {
        [self.delegate albumEditPlayerView:self willScrollToIndex:index withAnimation:withAnimation isByAutoTimer:isByAuto];
    }
    
    NSInteger indexDiff = labs(self.currentIndex - index);
    BOOL needReadData = (indexDiff > 1); // 非相邻最好reload下
    
    BOOL hasPreloadedItemForIndex = NO;
    if ([self.dataSource respondsToSelector:@selector(albumEditPlayerView:hasPreloadedItemWithIndex:)]) {
        hasPreloadedItemForIndex = [self.dataSource albumEditPlayerView:self hasPreloadedItemWithIndex:index];
    }
    
    if (!hasPreloadedItemForIndex) {
        withAnimation = NO; // 无预加载的item无法做动画，一般都是非相邻的跳转
    }
    
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"scrollToIndex : %@, needReload:%@, withAnimation:%@", @(index),@(needReadData),@(withAnimation)]];

    __auto_type reloadCollectionInvoke = ^(void) {
        
        self.collectionView.scrollEnabled = NO;
        [self.collectionView reloadData];
        // collectionView的回调比scrollView晚一个runloop,立即滑动可能会出现时序问题
        // 实际异步切主线程到下个runloop执行即可，保险起见加了些延迟，实际用户无感知
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.collectionView.scrollEnabled = self.scrollEnable;
        });
    };

    if (withAnimation) {
        self.collectionView.scrollEnabled = NO;
        @weakify(self);
        [self p_doScrollAnimationWithTargetIndex:index
                                      completion:^{
            @strongify(self);
            self.collectionView.scrollEnabled = self.scrollEnable;
            if (needReadData) {
                ACCBLOCK_INVOKE(reloadCollectionInvoke);
            }
            ACCBLOCK_INVOKE(completion);
        }];
    } else {
        [self.collectionView scrollToItemAtIndexPath:kIndexPathForItem(index) atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        if (needReadData) {
            ACCBLOCK_INVOKE(reloadCollectionInvoke);
        }
        ACCBLOCK_INVOKE(completion);
    }
    // collectionView的回调比scrollView晚一个runloop,立即滑动可能会出现时序问题
    // 实际异步切主线程到下个runloop执行即可，保险起见加了些延迟，实际用户无感知
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.collectionView.scrollEnabled = self.scrollEnable;
    });
}

/// 将图片拿出来做一个切换的假动画，结束后再无动画将collectionView scroll到对应index
/// 视觉想要从最后一张切到第0张的时候也带动画，但是目前没有做循环，所以只能通过假动画实现
/// 后续如果循环实现后可以去掉这个实现用
- (void)p_doScrollAnimationWithTargetIndex:(NSInteger)index
                                completion:(void (^)(void))completion
{
    UIView *currentPreloadView = [self p_previewViewAtIndex:self.currentIndex];
    UIView *nextPreloadView = [self p_previewViewAtIndex:index];

    if (!currentPreloadView || !nextPreloadView) {
        NSAssert(NO, @"invaild preloadView, check");
        [self.collectionView scrollToItemAtIndexPath:kIndexPathForItem(index) atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        ACCBLOCK_INVOKE(completion);
        return;
    }
    
    BOOL isLeftDirection = (index > self.currentIndex || index == 0);
    
    ACCImageAlbumEditPlayerItemCell *currentCell = (ACCImageAlbumEditPlayerItemCell *)[self.collectionView cellForItemAtIndexPath:kIndexPathForItem(self.currentIndex)];
    
    UIView *contentView = self.scrollFakeAnimationContentView;
    contentView.hidden = NO;
    CGFloat contentWidth = contentView.acc_width;
    
    [currentPreloadView removeFromSuperview];
    currentPreloadView.frame = contentView.bounds;
    [contentView addSubview:currentPreloadView];

    [nextPreloadView removeFromSuperview];
    nextPreloadView.frame = contentView.bounds;
    nextPreloadView.acc_left = isLeftDirection ? contentWidth : (-contentWidth);
    [contentView addSubview:nextPreloadView];
    
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.3 :0.18 :0 :1]];
    [UIView animateWithDuration:0.7
                          delay:0
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{
        currentPreloadView.acc_right = isLeftDirection ? 0.f : (2 * contentWidth);
        nextPreloadView.acc_left = 0.f;
    } completion:^(BOOL finished) {
        // 上一张重置回去，否则划回来会黑屏
        [currentCell reloadCurrentPreviewViewIfNeed];
        [self.collectionView scrollToItemAtIndexPath:kIndexPathForItem(index) atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        contentView.hidden = YES;
        ACCBLOCK_INVOKE(completion);
    }];
    [CATransaction commit];
}

// 目前没用到，@see p_doScrollAnimationWithTargetIndex
// 因为目前看着这个方式还是有概率会触发collectionView的bug
// 另外也无法做成可循环的动画，所以后续待定在看下是否用这个方式
- (void)p_doMagicScrollAnimationWithTargetIndex:(NSInteger)index
                                completion:(void (^)(void))completion
{
    BOOL isLeftDirection = (index > self.currentIndex || index == 0);
    
    UICollectionViewLayoutAttributes *targetLayout = [self.collectionView layoutAttributesForItemAtIndexPath:kIndexPathForItem(index)];
    
    // offset这里需要-1，避免cell被回收后造成手动滚动cell会不显示的问题
    CGPoint targetOffset = CGPointMake(isLeftDirection ? (targetLayout.frame.origin.x - 1) : (targetLayout.frame.origin.x + 1), targetLayout.frame.origin.y);
    
    [CATransaction begin];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.3 :0.18 :0 :1]];
    [UIView animateWithDuration:0.7
                          delay:0
                        options:UIViewAnimationOptionTransitionNone
                     animations:^{

        self.collectionView.contentOffset = targetOffset;
        
    } completion:^(BOOL finished) {
        [self.collectionView scrollToItemAtIndexPath:kIndexPathForItem(index) atScrollPosition:UICollectionViewScrollPositionNone animated:NO];
        ACCBLOCK_INVOKE(completion);
    }];
}

- (void)setScrollEnable:(BOOL)scrollEnable
{
    if (_scrollEnable == scrollEnable) {
        return;
    }
    _scrollEnable = scrollEnable;
    self.collectionView.scrollEnabled = scrollEnable;
}

- (void)setPageControlStyle:(ACCImageAlbumEditorPageControlStyle)pageControlStyle
{
    if (_pageControlStyle != pageControlStyle) {
        _pageControlStyle = pageControlStyle;
        
        [self p_updatePageControlActiveStatus];
        
        self.pageProgressView.usingPageControlType = (self.pageControlStyle == ACCImageAlbumEditorPageControlStyleProgressAsPageCotrol);
        
        if (self.pageProgressView.usingPageControlType) {
            [self.pageProgressView setPageIndex:self.currentIndex animation:NO];
        }
    }
}

- (void)startAutoPlay
{
    self.enableAutoPlay = YES;
    [self p_updateAutoplayStatus];
}

- (void)stopAutoPlay
{
    self.enableAutoPlay = NO;
    [self p_updateAutoplayStatus];
}

- (void)setAutoPlayInterval:(NSTimeInterval)autoPlayInterval
{
    _autoPlayInterval = autoPlayInterval;
    self.pageProgressView.animationDuration = self.autoPlayInterval;
}

- (BOOL)isDraggingOrScrolling
{
    return self.collectionView.isDragging || self.collectionView.isDecelerating;
}

#pragma mark - autoplay control
- (BOOL)p_isAutoScrollEnvAllowed
{
    if (!self.enableAutoPlay ||
        self.autoPlayInterval <= 0 ||
        [self p_dataSourceCount] <=1) {
        
        return NO;
        
    } else {
        return YES;
    }
}

- (void)p_updateAutoplayStatus
{
    if (![self p_isAutoScrollEnvAllowed]) {
        [self p_stopAutoplayTimer];
    } else {
        [self p_startAutoPlayTimer];
    }
}

- (void)p_startAutoPlayTimer
{
    [self p_logInfoWithLogMsg:@"startAutoplay"];
    [self p_stopAutoplayTimer];
    @weakify(self);
    self.autoplayTimer = [NSTimer acc_timerWithTimeInterval:self.autoPlayInterval block:^(NSTimer * _Nonnull timer) {
        @strongify(self);
        [self p_autoplayTimerHander];
    } repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.autoplayTimer forMode:NSRunLoopCommonModes];
    [self.pageProgressView setPageIndex:self.currentIndex animation:NO];
    if (self.pageControlStyle == ACCImageAlbumEditorPageControlStyleProgress) {
        [self.pageProgressView setPageIndex:self.currentIndex + 1 animation:YES];
    }
}

- (void)p_stopAutoplayTimer
{
    if (self.autoplayTimer) {
        [self p_logInfoWithLogMsg:@"stopAutoplay"];
        [self.autoplayTimer invalidate];
        self.autoplayTimer = nil;
        [self.pageProgressView pauseAnimation];
    }
}

- (void)p_autoplayTimerHander
{
    [self p_stopAutoplayTimer];
    
    if (![self p_isAutoScrollEnvAllowed]) {
        return;
    }
    
    if (self.collectionView.isDragging || self.collectionView.isDecelerating) {
        return;
    }
    
    NSInteger totalCount = [self p_dataSourceCount];
    NSInteger nextIndex = self.currentIndex + 1;
    if (nextIndex >= totalCount) {
        nextIndex = 0;
    }
    @weakify(self);
    [self scrollToIndex:nextIndex isByAuto:YES withAnimation:YES completion:^{
        @strongify(self);
        [self p_updateAutoplayStatus];
    }];
}

- (void)p_onProgressViewSelectedIndex:(NSInteger)index
{
    if (!self.collectionView.isScrollEnabled) {
        return;
    }
    if (index == self.currentIndex) {
        return;
    }
    
    if (self.collectionView.isDragging || self.collectionView.decelerating || !self.collectionView.scrollEnabled) {
        // 避免滑动冲突 影响体验
        return;
    }
    
    // 逻辑比较奇怪 PM希望的是和日常播放器交互一致，点击后面则向后滚一页，点击前面则向前滚一页，而非真正跳转到点击的index
    NSInteger targetIndex = (index > self.currentIndex) ? (self.currentIndex + 1) : (self.currentIndex - 1);
    
    if (targetIndex < 0 || targetIndex >= [self p_dataSourceCount]) {
        return;
    }
    
    [self p_stopAutoplayTimer];
    
    [self scrollToIndex:targetIndex];
    
    [self p_updateAutoplayStatus];
}

#pragma mark - collection view datasource
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    
    return [self p_dataSourceCount];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    return collectionView.frame.size;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"cellForItemAtIndexPath: %@", @(indexPath.item)]];
    
    ACCImageAlbumEditPlayerItemCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(ACCImageAlbumEditPlayerItemCell.class) forIndexPath:indexPath];
    
    BOOL hasPreloadedItemForIndex = NO;
    if ([self.dataSource respondsToSelector:@selector(albumEditPlayerView:hasPreloadedItemWithIndex:)]) {
        hasPreloadedItemForIndex = [self.dataSource albumEditPlayerView:self hasPreloadedItemWithIndex:indexPath.item];
    }
    if (hasPreloadedItemForIndex) {
        [cell reloadWithPreviewView:[self p_previewViewAtIndex:indexPath.item]];
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"willDisplay: %@", @(indexPath.item)]];
    [(ACCImageAlbumEditPlayerItemCell *)cell reloadWithPreviewView:[self p_previewViewAtIndex:indexPath.item]];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.f;
}

#pragma mark -  collection view delegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if ([self.delegate respondsToSelector:@selector(albumEditPlayerView:didUpdateDraggingStatus:)]) {
        [self.delegate albumEditPlayerView:self didUpdateDraggingStatus:YES];
    }
    [self p_logInfoWithLogMsg:@"BeginDragging"];
    self.isScrollByDragFlag = YES;
    [self p_stopAutoplayTimer];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self p_logInfoWithLogMsg:@"EndDecelerating"];
    if (!scrollView.isDragging) {
        self.isScrollByDragFlag = NO;
        [self p_updateAutoplayStatus];
        if ([self.delegate respondsToSelector:@selector(albumEditPlayerViewDidEndAnimationAndDragging:)]) {
            [self.delegate albumEditPlayerViewDidEndAnimationAndDragging:self];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"EndDragging : decelerate: %@",@(decelerate)]];
    if ([self.delegate respondsToSelector:@selector(albumEditPlayerView:didUpdateDraggingStatus:)]) {
        [self.delegate albumEditPlayerView:self didUpdateDraggingStatus:NO];
    }
    if (!decelerate) {
        [self p_updateAutoplayStatus];
        self.isScrollByDragFlag = NO;
        if ([self.delegate respondsToSelector:@selector(albumEditPlayerViewDidEndAnimationAndDragging:)]) {
            [self.delegate albumEditPlayerViewDidEndAnimationAndDragging:self];
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self p_updatPlayerItemStatusWithContentOffsetX:scrollView.contentOffset.x];
}

/*
 * 核心预加载计算代码，因为VE的实例内存占用很大，所以内存及其脆弱
 * @warning 因此预加载的计算需要比较谨慎
 * 大致逻辑 ：
    其实和cell的复用逻辑比较像，但是自己计算可以避免使用scrollToIndex方法collectionView不回调导致的各种bug
    当静止状态下，加载当前index，预加载 前后两张
    当滚动状态下，加载当前index，当划过一定的阈值的时候，加载目标方向上的后两张
    当滚动状态下，加载当前index，当没有阈值的时候，index前后两张
**/

#pragma mark - index

- (void)p_updatPlayerItemStatusWithContentOffsetX:(CGFloat)offsetX
{
    CGFloat contentWidth = self.collectionView.acc_width;
    
    if (contentWidth <= 0.01) {
        return;
    }
    
    NSInteger currentIndex = self.currentIndex;
    
    if (![self isIndex:currentIndex inCurrentBounceWithOffsetX:offsetX contentWith:contentWidth]) {
        currentIndex = offsetX / contentWidth;
    }

    if (currentIndex != self.currentIndex) {
        [self p_updateCurrentIndexWithIndex:currentIndex];
    }
    
    NSInteger dataCount = [self p_dataSourceCount];
    if (dataCount > 3) {
        // 默认已经缓存了3个 小于最大缓存并不需要重计算缓存
        [self p_updatePreloadStatusWithContentOffsetX:offsetX
                                         contentWidth:contentWidth
                                         currentIndex:currentIndex];
    }

}

- (void)p_updatePreloadStatusWithContentOffsetX:(CGFloat)offsetX
                                   contentWidth:(CGFloat)contentWidth
                                   currentIndex:(NSInteger)currentIndex
{
    if (self.isRefactor) {
        // 之前预加载的计算逻辑写的比较急，逻辑搞得太复杂，比较难改了
        // 这次彻底重构一波，包在AB里不影响之前的
        [self p_modernUpdatePreloadStatusWithContentOffsetX:offsetX contentWidth:contentWidth currentIndex:currentIndex];
        return;
    }
    
    NSNumber *preloadLeftIndex = @(currentIndex);
    NSNumber *preloadRightIndex = @(currentIndex);
    
    // 当前index对应的offset最小值
    CGFloat currentIndexLeftFlag =  currentIndex * contentWidth;
    // 当前offset对应的 当前index最左边界的偏移量
    CGFloat currentOffsetToLeftFlagOffset = (offsetX - currentIndexLeftFlag);
    // 重计算preload的阈值
    CGFloat boundaryOffsetXThreshold = 0.25f * contentWidth;

    /* 这两种计算可以合并，但是从更清晰的可理解角度还是分开写了 */
    
    // 当向右偏移
    if (currentOffsetToLeftFlagOffset >= 0) {
        
            // 那么超过阈值则预加载当前index后两张
        if (currentOffsetToLeftFlagOffset >= boundaryOffsetXThreshold) {
            preloadLeftIndex = @(currentIndex + 1);
            preloadRightIndex = @(currentIndex + 2);
        } else {
            // 未超过阈值则预加载index前后两张
            preloadLeftIndex = @(currentIndex - 1);
            preloadRightIndex = @(currentIndex + 1);
        }
        
    } else {
        
        // 当向左偏移
        currentOffsetToLeftFlagOffset = -currentOffsetToLeftFlagOffset;
        
            // 那么超过阈值则预加载当前index后两张
        if (currentOffsetToLeftFlagOffset >= boundaryOffsetXThreshold) {
            preloadLeftIndex = @(currentIndex -2);
            preloadRightIndex = @(currentIndex -1);
        } else {
            // 未超过阈值则预加载index前后两张
            preloadLeftIndex = @(currentIndex - 1);
            preloadRightIndex = @(currentIndex + 1);
        }
    }
    
    if (preloadLeftIndex.integerValue < 0) {
        preloadLeftIndex = @(preloadRightIndex.integerValue + 1);
    }
    
    if (preloadRightIndex.integerValue >= [self p_dataSourceCount]) {
        if (self.enableAutoPlay) {
            preloadRightIndex = @(0);
        } else {
            preloadRightIndex = @(preloadLeftIndex.integerValue - 1); // 如果不是自动滚动没必要刷新首个item
        }
    }
    
    if (![self.currentPreloadIndexs containsObject:preloadLeftIndex] || ![self.currentPreloadIndexs containsObject:preloadRightIndex]) {
        self.currentPreloadIndexs = @[preloadLeftIndex, preloadRightIndex];
        
        if ([self.delegate respondsToSelector:@selector(albumEditPlayerView:didUpdatePreloadIndexs:)]) {
            
            [self p_logInfoWithLogMsg:@"willPrereloadIndexs"];
            
            [self.delegate albumEditPlayerView:self didUpdatePreloadIndexs:self.currentPreloadIndexs];
        }
    }
}

/*
 * 大致逻辑 ：
    其实和cell的复用逻辑比较像，但是自己计算可以避免特殊状态collection不回调导致的各种bug
    当静止状态下，加载当前index，预加载 前后两张
    当滚动状态下，加载当前index，当划过一定的阈值的时候，加载目标方向上的后两张
                            当没有阈值的时候，index前后两张
    计算的时候需要注意index为0，以及index为最后的一个时候自动播状态下需要加载第一张
**/

- (void)p_modernUpdatePreloadStatusWithContentOffsetX:(CGFloat)offsetX
                                         contentWidth:(CGFloat)contentWidth
                                         currentIndex:(NSInteger)currentIndex
{
    // 对应方向上超出的offset是否已经超过进入到下一个index的阈值，阈值为contentWidth的0.25
    BOOL isOffsetXOverCurrentIndexBoundary = fabs(offsetX - currentIndex * contentWidth) >= (0.25f * contentWidth);
    
    NSInteger targetIndex = currentIndex;
    // 当滑动的已经超过当前index的阈值则计算对应方向的后一个
    if (isOffsetXOverCurrentIndexBoundary) {
        if (offsetX >= (contentWidth * currentIndex)) { // 往当前index的右方向
            targetIndex = targetIndex + 1;
        } else { // 往当前index的左方向
            targetIndex = targetIndex - 1;
        }
    }
    
    NSInteger dataSourceCount = [self p_dataSourceCount];
    if (targetIndex < 0 || targetIndex >= dataSourceCount) {
        NSAssert(NO, @"check");
        targetIndex = MIN(dataSourceCount - 1,  MAX(0, targetIndex));
    }
    
    NSArray <NSNumber *> *preloadIndexs;
    if (targetIndex >= (dataSourceCount - 1)) {
        // 例如target为5，自动播则预加载0，也就是4,5,0 否则加载3，4，5
        NSInteger lastIndex = self.enableAutoPlay? 0 : (targetIndex - 2);
        preloadIndexs = @[@(targetIndex -1), @(targetIndex), @(lastIndex)];
    } else {
        NSInteger startIndex = MAX(0, targetIndex - 1);
        preloadIndexs = @[@(startIndex), @(startIndex + 1), @(startIndex + 2)];
    }
    
    __block BOOL isSameToCurrentIndexs = NO;
    if (self.currentPreloadIndexs) {
        isSameToCurrentIndexs = [[NSSet setWithArray:preloadIndexs] isEqualToSet:[NSSet setWithArray:self.currentPreloadIndexs]];
    }
    
    if (!isSameToCurrentIndexs) {
        self.currentPreloadIndexs = preloadIndexs;
        if ([self.delegate respondsToSelector:@selector(albumEditPlayerView:didUpdatePreloadIndexs:)]) {
            [self p_logInfoWithLogMsg:@"willPrereloadIndexs"];
            [self.delegate albumEditPlayerView:self didUpdatePreloadIndexs:self.currentPreloadIndexs];
        }
    }
}

- (BOOL)isIndex:(NSInteger)index inCurrentBounceWithOffsetX:(CGFloat)offsetX contentWith:(CGFloat)contentWidth
{
    CGFloat leftBounce = (index - 1) * contentWidth;
    CGFloat rightBounce = (index + 1) * contentWidth;
    
    return ((offsetX - leftBounce) > ACC_FLOAT_ZERO) && ((rightBounce - offsetX) > ACC_FLOAT_ZERO) ;
}

- (void)p_updateCurrentIndexWithIndex:(NSInteger)index
{
    if (index == self.currentIndex) {
        return;
    }
    _currentIndex = index;
    [self p_logInfoWithLogMsg:[NSString stringWithFormat:@"update current: %@", @(index)]];
    
    [self.pageControl updateCurrentPageIndex:index];
    [self.pageProgressView setPageIndex:index animation:NO];
    
    if ([self p_isAutoScrollEnvAllowed] && self.pageControlStyle == ACCImageAlbumEditorPageControlStyleProgress) {
        [self.pageProgressView setPageIndex:index + 1 animation:YES];
    }
    
    if ([self.delegate respondsToSelector:@selector(albumEditPlayerView:didUpdateCurrentIndex:isByAutoTimer:)]) {
        [self.delegate albumEditPlayerView:self didUpdateCurrentIndex:index isByAutoTimer:!self.isScrollByDragFlag];
    }
}

#pragma mark - getter
- (UIView *)p_previewViewAtIndex:(NSInteger)index
{
    if ([self.dataSource respondsToSelector:@selector(albumEditPlayerView:previewViewAtIndex:)]) {
        return [self.dataSource albumEditPlayerView:self previewViewAtIndex:index];
    }
    NSAssert(NO, @"preview view should not be nil");
    return [[UIView alloc] init];
}

- (NSInteger)p_dataSourceCount
{
    if ([self.dataSource respondsToSelector:@selector(numberOfPreviewForAlbumEditPlayerView:)]) {
        return [self.dataSource numberOfPreviewForAlbumEditPlayerView:self];
    }
    return 0;
}

#pragma mark - util
- (void)p_logInfoWithLogMsg:(NSString *)logMsg
{
    NSString *log = [NSString stringWithFormat:@"\n>>>>>>>ImageAlbumPlayerView : msg:%@, currentIndex:%@, preloadIndexs:%@,%@\n", logMsg, @(self.currentIndex),[self.currentPreloadIndexs acc_objectAtIndex:0], [self.currentPreloadIndexs acc_objectAtIndex:1] ];
    AWELogToolInfo(AWELogToolTagEdit, log);
}

#pragma mark - view
- (void)p_updatePageControlActiveStatus
{
    self.pageProgressView.active = ((self.pageControlStyle == ACCImageAlbumEditorPageControlStyleProgress ||
                                     self.pageControlStyle == ACCImageAlbumEditorPageControlStyleProgressAsPageCotrol) &&
                                    [self p_dataSourceCount] > 1);
    
    self.pageProgressView.hidden = !self.pageProgressView.active;
    
    self.pageControl.hidden = (self.pageControlStyle != ACCImageAlbumEditorPageControlStylePageCotrol || [self p_dataSourceCount] <= 1);
}

- (void)setupViewsIfNeed
{
    if (self.collectionView) {
        return;
    }
    
    self.collectionView = ({
        
        UICollectionView *collectionView = [[ACCImageAlbumEditColletionView alloc] initWithFrame:self.bounds collectionViewLayout:({
            UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
            flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
            flowLayout;
        })];
        [self addSubview:collectionView];
        ACCMasMaker(collectionView, {
            make.left.right.top.bottom.equalTo(self);
        });
        collectionView.backgroundColor = [UIColor clearColor];
        collectionView.showsHorizontalScrollIndicator = NO;
        collectionView.showsVerticalScrollIndicator   = NO;
        if (@available(iOS 11.0, *)) {
            collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        collectionView.bounces = NO;
        collectionView.pagingEnabled = YES;
        [collectionView registerClass:[ACCImageAlbumEditPlayerItemCell class] forCellWithReuseIdentifier:NSStringFromClass([ACCImageAlbumEditPlayerItemCell class])];
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView;
    });
    
    self.scrollFakeAnimationContentView = ({
        
        UIView *view = [[UIView alloc] init];
        [self addSubview:view];
        view.backgroundColor = [UIColor clearColor];
        view.hidden = YES;
        ACCMasMaker(view, {
            make.left.right.top.bottom.equalTo(self);
        });
        view;
    });
    
    self.interactionContainerView = ({
        
        AWEStudioExcludeSelfView *view = [[AWEStudioExcludeSelfView alloc] init];
        [self addSubview:view];
        view.backgroundColor = [UIColor clearColor];
        ACCMasMaker(view, {
            make.left.right.top.bottom.equalTo(self);
        });
        view;
    });
    
    self.pageProgressView = ({
        
        ACCImageAlbumEditPageProgressView *progressView = [[ACCImageAlbumEditPageProgressView alloc] initWithViewWidth:self.acc_width];
        @weakify(self);
        progressView.selectedIndexHander = ^(NSInteger index) {
            @strongify(self);
            [self p_onProgressViewSelectedIndex:index];
        };
        progressView.hidden = YES;
        [self.interactionContainerView addSubview:progressView];
        ACCMasMaker(progressView, {
            make.left.right.equalTo(self.interactionContainerView);
            make.height.mas_equalTo([ACCImageAlbumEditPageProgressView defaultHeight]);
            make.bottom.equalTo(self.interactionContainerView).inset([self p_getProgressBottomInsert]);
        });
        progressView;
    });
    
    self.pageControl = ({
        
        UIView<ACCImageAlbumPageControlProtocol> *pageControl;
        NSDictionary *dict = ACCConfigDict(kConfigDict_image_works_experience_optimization);
        NSInteger indicatorStyle = [dict acc_integerValueForKey:kConfigInt_image_indicator_style defaultValue:0];
        if (indicatorStyle == 1) {
            pageControl = [[ACCImageAlbumCombinedPageControl alloc] init];
        } else {
            pageControl = [[ACCImageAlbumEditPageControl alloc] init];
        }
        [self.interactionContainerView addSubview:pageControl];
        ACCMasMaker(pageControl, {
            make.centerX.equalTo(self.interactionContainerView);
            make.bottom.equalTo(self.interactionContainerView).inset([self p_getPageControlBottomInsert] - 10.f);
            if (indicatorStyle == 1) {
                make.height.mas_equalTo(40);
            }
        });
        [pageControl updateCurrentPageIndex:0];
        pageControl;
    });
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGSize collectionViewSize = self.collectionView.frame.size;
    if (!CGSizeEqualToSize(collectionViewSize, self.lastUpdateCollectionViewSize)) {
        self.lastUpdateCollectionViewSize  = collectionViewSize;
        [self.collectionView reloadData];
    }
}

- (void)setBottomOffset:(CGFloat)bottomOffset
{
    if (ACC_FLOAT_EQUAL_TO(bottomOffset, _bottomOffset)) {
        return;
    }
    
    _bottomOffset = bottomOffset;
    
    if (self.pageControl) {
        ACCMasUpdate(self.pageControl, {
            make.bottom.equalTo(self).inset([self p_getPageControlBottomInsert]);
        });
    }
    
    if (self.pageProgressView) {
        ACCMasUpdate(self.pageProgressView, {
            make.bottom.equalTo(self).inset([self p_getProgressBottomInsert]);
        });
    }
}

- (CGFloat)p_getPageControlBottomInsert
{
    CGFloat baseOffset = [AWEXScreenAdaptManager needAdaptScreen] ? 24.f : 75.f;
    // 编辑页的bar有可能是放在下面的
    return baseOffset + self.bottomOffset;
}

- (CGFloat)p_getProgressBottomInsert
{
    CGFloat baseOffset = [AWEXScreenAdaptManager needAdaptScreen] ? 1.f : 52.f;
    // 编辑页的bar有可能是放在下面的
    return baseOffset + self.bottomOffset;
}

@end
