//
//  EMAPhotoScrollViewController.m
//  Article
//
//  Created by Zhang Leonardo on 12-12-4.
//  Edited by Cao Hua from 13-10-12.
//  Edited by 武嘉晟 from 20-01-20.
//  这个12年的老代码写的不好，日后如果有需求，推荐彻底推翻使用swift重构
//

#import "EMAImagePreviewAnimateManager.h"
#import "EMAPageIndcatorView.h"
#import "EMAPhotoScrollViewController.h"
#import "EMAShowImageView.h"
#import <OPFoundation/UIImage+EMA.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPI18n.h>
#import <ECOInfra/BDPLog.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import <Masonry/Masonry.h>
#import <OPFoundation/OPFoundation-Swift.h>
#import <OPFoundation/BDPResponderHelper.h>

#define moveDirectionStartOffset 20.f

typedef NS_ENUM(NSInteger, EMAPhotoScrollViewMoveDirection) {
    EMAPhotoScrollViewMoveDirectionNone, //未知
    EMAPhotoScrollViewMoveDirectionVerticalTop, //向上
    EMAPhotoScrollViewMoveDirectionVerticalBottom //向下
};

@interface EMAPhotoScrollViewController () <UIScrollViewDelegate, EMAShowImageViewProtocol, UIGestureRecognizerDelegate>

@property (nonatomic, strong, nullable) id <EMAPhotoScrollViewControllerProtocol> delegate;

/// 成功回调
@property (nonatomic, copy, nullable) dispatch_block_t success;
/// 成功回调数
@property (nonatomic, assign) NSUInteger successCount;
/// 失败回调
@property (nonatomic, copy, nullable) void (^failure)(NSString * _Nullable msg);

/** 打开的时候需要展示的index */
@property(nonatomic, assign) NSUInteger startWithIndex;

@property(nonatomic, copy, nonnull) NSArray <NSURLRequest *> *requests;

/** UIImage(s); Optional ([NSNull null] is used to represent the absence) */
@property (nonatomic, strong) NSArray <UIImage *> * placeholders;

/// 一次性传入所有的placeholders UIImage可能耗时太久，使用placeholderTags和placeholderImageForTag:能够在图片即将展示时再解析对应的图片
@property (nonatomic, strong) NSArray <NSString *> * placeholderTags;

/// 原图URL数组Optional ([NSNull null] is used to represent the absence)
@property (nonatomic, strong) NSArray <NSString *> * originImageURLs;

@property (nonatomic, strong) NSArray * placeHolderSourceViewCornerRadius;

/** Frame(s) based on window coordinate; Optional */
@property (nonatomic, strong) NSArray * placeholderSourceViewFrames;

@property(nonatomic, strong)UIScrollView * photoScrollView;
@property(nonatomic, strong)UIView *containerView;

@property(nonatomic, assign, readwrite)NSInteger currentIndex;
@property(nonatomic, assign, readwrite)NSInteger photoCount;

@property(nonatomic, strong)NSMutableSet * photoViewPools;

@property(nonatomic, strong)UIPanGestureRecognizer * panGestureRecognizer;

//手势识别方向
@property (nonatomic, assign) EMAPhotoScrollViewMoveDirection direction;

//交互式推动退出所需的属性
@property (nonatomic, strong) EMAImagePreviewAnimateManager *animateManager;
@property (nonatomic, copy) NSArray<NSValue *> *animateFrames;
@property (nonatomic, copy) NSString *locationStr;

// 用于判断长按菜单是否显示 “查看原图”
@property (nonatomic, assign) BOOL currentShowOriginButton;

// 翻页指示器
@property (nonatomic, strong) EMAPageIndcatorView *pageIndcatorView;

@property (nonatomic, assign) BOOL alreadyFinished;// 防止多次点击回调造成多次popController
@property (nonatomic, assign) BOOL isRotating;
@property (nonatomic, assign) BOOL reachDismissCondition; //是否满足关闭图片控件条件
@property (nonatomic, assign) BOOL reachDragCondition; //是否满足过一次触发手势条件
@property (nonatomic, assign) BOOL popGestureEnable;

@property (nonatomic, assign) BOOL statusBarHidden;
@end

@implementation EMAPhotoScrollViewController

- (instancetype)initWithRequests:(NSArray <NSURLRequest *> * _Nonnull)reuqests
                  startWithIndex:(NSUInteger)index
               placeholderImages:(NSArray <UIImage *> * _Nullable)placeholders
                 placeholderTags:(NSArray <NSString *> * _Nullable)placeholderTags
                 originImageURLs:(NSArray <NSString *> * _Nullable)originImageURLs
                        delegate:(id <EMAPhotoScrollViewControllerProtocol> _Nullable)delegate
                         success:(dispatch_block_t _Nullable)success
                         failure:(void(^ _Nullable )(NSString  * _Nullable msg))failure {
    if (self = [super init]) {
        self.hidesBottomBarWhenPushed = YES;
        _requests = reuqests;
        _photoCount = reuqests.count;
        _startWithIndex = index;
        _placeholders = placeholders;
        _placeholderTags = placeholderTags;
        _originImageURLs = originImageURLs;
        _delegate = delegate;
        _success = success;
        _successCount = 0;
        _failure = failure;

        _currentIndex = -1;
        _photoViewPools = [[NSMutableSet alloc] initWithCapacity:5];
        _isRotating = NO;
        _whiteMaskViewEnable = YES;

        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        self.definesPresentationContext = YES;
        self.modalPresentationStyle = UIModalPresentationOverCurrentContext;

    }
    return self;
}

- (void)dealloc
{
    !_success ?: _success();
    @try {
        [self removeObserver:self forKeyPath:@"self.view.frame"];
    }
    @catch (NSException *exception) {
        BDPLogWarn(@"%@", exception);
    }
}

#pragma mark - View Life Cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addObserver:self forKeyPath:@"self.view.frame" options:NSKeyValueObservingOptionNew context:nil];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]){
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    // self.view
    self.view.alpha = 0;    //默认不显示，动画淡出
    self.view.backgroundColor = [UIColor clearColor];

    // containerView
    self.containerView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.containerView];
    
    // photoScrollView
    self.photoScrollView = [[UIScrollView alloc] initWithFrame:[self frameForPagingScrollView]];
    self.photoScrollView.delegate = self;
    self.photoScrollView.backgroundColor = UIColor.clearColor;
    self.photoScrollView.pagingEnabled = YES;
    self.photoScrollView.showsVerticalScrollIndicator = NO;
    self.photoScrollView.showsHorizontalScrollIndicator = YES;
    [self.view addSubview:self.photoScrollView];

    // pageIndcatorView
    CGFloat pageIndicatorHeight = 40;
    self.pageIndcatorView = [[EMAPageIndcatorView alloc] initWithFrame:CGRectZero];
    _pageIndcatorView.selectedColor = UIColor.whiteColor;
    _pageIndcatorView.unselectedColor = [UIColor colorWithWhite:1 alpha:0.4];
    _pageIndcatorView.dotMargin = 8;
    _pageIndcatorView.hideDotsWhenOnlyOnePage = YES;
    [self.view addSubview:_pageIndcatorView];
    [self.pageIndcatorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.mas_equalTo(self.view);
        make.height.mas_equalTo(pageIndicatorHeight);
        make.bottom.mas_equalTo(self.view).inset([BDPResponderHelper safeAreaInsets:self.view.window].bottom);
    }];
    
    // layout
    NSInteger maxIndex = _requests.count - 1;
    self.startWithIndex = MAX(0, MIN(maxIndex, _startWithIndex));
    [self setPhotoScrollViewContentSize];
    
    [self setCurrentIndex:_startWithIndex];
    [self scrollToIndex:_startWithIndex];

    self.panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    self.panGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:_panGestureRecognizer];
    
    if ([EMAImagePreviewAnimateManager interativeExitEnable]){
        self.animateManager.panDelegate = self;
        [_animateManager registeredPanBackWithGestureView:self.view];
        [self frameTransform];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // 入场动画
    [UIView animateWithDuration:0.3 animations:^{
        self.view.alpha = 1;
    } completion:^(BOOL finished) {
        self.statusBarHidden = YES; // 延迟一点执行避免显示背景VC由于隐藏StatusBar带来的抖动
    }];
}

#pragma mark - StatusBar
- (void)setStatusBarHidden:(BOOL)statusBarHidden {
    if (_statusBarHidden != statusBarHidden) {
        _statusBarHidden = statusBarHidden;

        self.modalPresentationCapturesStatusBarAppearance = YES;
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return self.statusBarHidden;
}

#pragma mark - Rotate
- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    if ([BDPDeviceHelper isPadDevice]) {
        [self refreshUI];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    self.photoScrollView.delegate = nil;
    self.isRotating = YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    self.photoScrollView.delegate = self;
    self.isRotating = NO;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"self.view.frame"]) {
        [self refreshUI];
    }
}

- (void)refreshUI
{
    self.containerView.frame = self.view.frame;
    self.photoScrollView.frame = [self frameForPagingScrollView];
    [self setPhotoScrollViewContentSize];
    
    for (UIView * view in [self.photoScrollView subviews]) {
        if ([view isKindOfClass:[EMAShowImageView class]]) {
            EMAShowImageView * v = (EMAShowImageView *)view;
            v.frame = [self frameForPageAtIndex:v.tag];
            [v resetZoom];
            [v refreshUI];
        }
    }
    
    [self scrollToIndex:_currentIndex];
    [self refreshPageIndcator];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    BOOL result = NO;
    if([BDPDeviceHelper isPadDevice])
    {
        result = YES;
    }
    else
    {
        result = interfaceOrientation == UIInterfaceOrientationPortrait;
    }

    return result;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if (![BDPDeviceHelper isPadDevice]) {
        return UIInterfaceOrientationMaskPortrait;
    }
    else {
        return UIInterfaceOrientationMaskAll;
    }
}

#pragma mark - Setter & Getter

- (EMAImagePreviewAnimateManager *)animateManager{
    if (_animateManager == nil){
        _animateManager = [[EMAImagePreviewAnimateManager alloc] initWithController:self];
        _animateManager.whiteMaskViewEnable = _whiteMaskViewEnable;
    }
    return _animateManager;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [[UIView alloc] initWithFrame:self.view.frame];
    }
    return _containerView;
}

- (void)setWhiteMaskViewEnable:(BOOL)whiteMaskViewEnable{
    _whiteMaskViewEnable = whiteMaskViewEnable;
    _animateManager.whiteMaskViewEnable = whiteMaskViewEnable;
}

- (BOOL)newGestureEnable
{
    if (![EMAImagePreviewAnimateManager interativeExitEnable]){
        return NO;
    }
    CGRect origionViewFrame = [self ttPreviewPanBackGetOriginView].frame;
    if (CGRectGetHeight(origionViewFrame) == 0 || CGRectGetWidth(origionViewFrame) == 0){
        return NO;
    }
    
    return [self showImageViewAtIndex:_currentIndex].image != nil;
}

#pragma mark - Private

- (void)frameTransform{
    UIView *targetView = [self ttPreviewPanBackGetBackMaskView];
    if (nil == targetView){
        return;
    }
    NSMutableArray *mutArray = [NSMutableArray array];
    for (NSValue *frameValue in self.placeholderSourceViewFrames){
        if ([frameValue isKindOfClass:[NSNull class]]){
            [mutArray addObject:[NSValue valueWithCGRect:CGRectZero]];
            continue;
        }
        CGRect frame = frameValue.CGRectValue;
        if (CGRectEqualToRect(frame, CGRectZero)){
            [mutArray addObject:frameValue];
            continue;
        }
        CGRect animateFrame = [targetView convertRect:frame fromView:nil];
        [mutArray addObject:[NSValue valueWithCGRect:animateFrame]];
    }
    self.animateFrames = [mutArray copy];
}

- (void)setPlaceholderSourceViewFrames:(NSArray *)placeholderSourceViewFrames {
    _placeholderSourceViewFrames = placeholderSourceViewFrames;
    if ([EMAImagePreviewAnimateManager interativeExitEnable]){
        [self frameTransform];
    }
}

- (void)refreshPageIndcator {
    self.pageIndcatorView.totalPage = _photoCount;
    self.pageIndcatorView.currentPage = _currentIndex;
}

/// 刷新全图
- (void)refreshFullImage {
    if (!self.requests || !self.originImageURLs || _currentIndex >= self.requests.count || _currentIndex >= self.originImageURLs.count) {
        self.currentShowOriginButton = NO;
        return;
    }
    NSString *originURL = self.originImageURLs[_currentIndex];
    if ([originURL isKindOfClass:NSString.class] && originURL.length) {
        NSString *currentURL = self.requests[_currentIndex].URL.absoluteString;
        if ([currentURL isEqualToString:originURL]) {
            self.currentShowOriginButton = NO;
            return;
        } else {
            if ([EMAImageUtils diskImageExistsWithUrl:[NSURL URLWithString:originURL]]) {
                [self useOriginImage];
            } else {
                self.currentShowOriginButton = YES;
            }
        }
    } else {
        self.currentShowOriginButton = NO;
    }
}

- (void)setCurrentShowOriginButton:(BOOL)currentShowOriginButton {
    if (_currentShowOriginButton != currentShowOriginButton) {
        _currentShowOriginButton = currentShowOriginButton;
    }
}

- (CGRect)frameForPagingScrollView
{
    return self.view.bounds;
}

- (void)setPhotoScrollViewContentSize
{
    NSInteger pageCount = _photoCount;
    if (pageCount == 0) {
        pageCount = 1;
    }
    
    CGSize size = CGSizeMake(self.photoScrollView.frame.size.width * pageCount, self.photoScrollView.frame.size.height);
    [self.photoScrollView setContentSize:size];
}

- (CGRect)frameForPageAtIndex:(NSInteger)index
{
    CGRect pageFrame = self.photoScrollView.bounds;
    pageFrame.origin.x = (index * pageFrame.size.width);
    return pageFrame;
}

/// 设置当前图片
/// @param newIndex 图片的index
- (void)setCurrentIndex:(NSInteger)newIndex {
    /// 避免重复或者index非法
    if (_currentIndex == newIndex || newIndex < 0) {
        return;
    }
    _currentIndex = newIndex;
    
    [self refreshPageIndcator];
    [self refreshFullImage];
    
    [self unloadPhoto:_currentIndex + 2];
    [self unloadPhoto:_currentIndex - 2];
    
    [self loadPhoto:_currentIndex];
    [self showImageViewAtIndex:_currentIndex];
    [self loadPhoto:_currentIndex + 1];
    [self loadPhoto:_currentIndex - 1];
}

- (void)scrollToIndex:(NSInteger)index
{
    [self.photoScrollView setContentOffset:CGPointMake((CGRectGetWidth(self.photoScrollView.frame) * index), 0)
                                  animated:NO];
}

- (void)setUpShowImageView:(EMAShowImageView *)showImageView atIndex:(NSUInteger)index {
    showImageView.tag = index;
    [showImageView resetZoom];
    
    if ([_placeholders count] > index && [[_placeholders objectAtIndex:index] isKindOfClass:[UIImage class]]) {
        /// 使用占位图
        showImageView.placeholderImage = [_placeholders objectAtIndex:index];
    } else {
        showImageView.placeholderImage = nil;
    }
    if (!showImageView.placeholderImage && [self.delegate respondsToSelector:@selector(placeholderImageForTag:)] && self.placeholderTags && self.placeholderTags.count > index) {
        /// 这里是从磁盘获取网络文件
        showImageView.placeholderImage = [self.delegate placeholderImageForTag:self.placeholderTags[index]];
    }
    
    if ([_placeholderSourceViewFrames count] > index && [_placeholderSourceViewFrames objectAtIndex:index] != [NSNull null]) {
        showImageView.placeholderSourceViewFrame = [[_placeholderSourceViewFrames objectAtIndex:index] CGRectValue];
    } else {
        showImageView.placeholderSourceViewFrame = CGRectZero;
    }

    if ([_requests count] > index) {
        [showImageView setLargeImageURLRequest:[_requests objectAtIndex:index]];
    }
}

/// 装载图片
/// @param index index
- (void)loadPhoto:(NSInteger)index {
    if (index < 0 || index >= _photoCount) {
        return;
    }
    
    if ([self isPhotoViewExistInScrollViewForIndex:index]) {
        return;
    }
    
    EMAShowImageView * showImageView = [_photoViewPools anyObject];
    __weak typeof(self) wself = self;
    if (!showImageView) {
        showImageView = [[EMAShowImageView alloc]
                         initWithFrame:[self frameForPageAtIndex:index]
                         success:^{
            wself.successCount ++;
            if (wself.successCount == wself.photoCount) {
                !wself.success ?: wself.success();
                wself.success = nil;
                wself.failure = nil;
            }
        }
                         failure:^(NSString * _Nullable msg) {
            !wself.failure ?: wself.failure(msg);
            wself.success = nil;
            wself.failure = nil;
        }];
        showImageView.backgroundColor = UIColor.clearColor;
        showImageView.delegate = self;
        showImageView.header = self.header.copy;
        UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
        gestureRecognizer.minimumPressDuration = 0.3;
        [showImageView addGestureRecognizer:gestureRecognizer];
    } else {
        [_photoViewPools removeObject:showImageView];
    }
    showImageView.frame = [self frameForPageAtIndex:index];

    [self setUpShowImageView:showImageView atIndex:index];
    [self.photoScrollView addSubview:showImageView];
}


- (BOOL)isPhotoViewExistInScrollViewForIndex:(NSInteger)index
{
    BOOL exist = NO;
    for (UIView * subView in [self.photoScrollView subviews]) {
        if ([subView isKindOfClass:[EMAShowImageView class]] && subView.tag == index) {
            exist = YES;
        }
    }
    return exist;
}

/// 获取index位置的图片view
/// @param index index

- (EMAShowImageView *)showImageViewAtIndex:(NSInteger)index
{
    if (index < 0 || index >= _photoCount) {
        return nil;
    }
    
    for (UIView * subView in [self.photoScrollView subviews]) {
        if ([subView isKindOfClass:[EMAShowImageView class]] && subView.tag == index) {
            return (EMAShowImageView *)subView;
        }
    }
    
    return nil;
}

/// 卸载图片到图片池
/// @param index index
- (void)unloadPhoto:(NSInteger)index
{
    if (index < 0 || index >= _photoCount) {
        return;
    }
    
    for (UIView * subView in [self.photoScrollView subviews]) {
        if ([subView isKindOfClass:[EMAShowImageView class]] && subView.tag == index) {
            [_photoViewPools addObject:subView];
            [subView removeFromSuperview];
        }
    }
}

/// 点击按钮使用原图
- (void)useOriginImage {
    if (!self.requests || !self.originImageURLs || _currentIndex >= self.requests.count || _currentIndex >= self.originImageURLs.count) {
        self.currentShowOriginButton = NO;
        return;
    }

    NSString *originURL = self.originImageURLs[_currentIndex];
    if ([originURL isKindOfClass:NSString.class] && originURL.length) {
        /// 使用原图的时候把self.requests的某个request的URL换掉
        NSMutableArray *newRequests = self.requests.mutableCopy;
        NSURLRequest *oldRequest = newRequests[_currentIndex];
        NSMutableURLRequest *newRequest = oldRequest.mutableCopy;
        newRequest.URL = [NSURL URLWithString:originURL];
        [newRequests replaceObjectAtIndex:_currentIndex withObject:newRequest];
        self.requests = newRequests.copy;
        EMAShowImageView * currentImageView = [self showImageViewAtIndex:_currentIndex];
        [currentImageView replaceLargeImageURLRequest:newRequest.copy];
    }
    self.currentShowOriginButton = NO;
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat pageWidth = scrollView.frame.size.width;
    
    float fractionalPage = (scrollView.contentOffset.x + pageWidth / 2) / pageWidth;
    
    NSInteger page = floor(fractionalPage);
    if (page != _currentIndex) {
        [self setCurrentIndex:page];
    }
}

#pragma mark - EMAShowImageViewDelegate

- (void)showImageViewOnceTap:(EMAShowImageView *)imageView
{
    [self dismissAnimated:YES completion:nil];
}

- (void)saveButtonClicked:(id)sender
{
    EMAShowImageView * currentImageView = [self showImageViewAtIndex:_currentIndex];
    [currentImageView saveImage];
}

- (void)pan:(UIPanGestureRecognizer *)recognizer
{
    if (self.interfaceOrientation != UIInterfaceOrientationPortrait) {
        return;
    }
    CGPoint translation = [recognizer translationInView:recognizer.view.superview];
    CGPoint velocity = [recognizer velocityInView:recognizer.view.superview];
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            break;
        case UIGestureRecognizerStateChanged: {
            [self refreshPhotoViewFrame:translation velocity:velocity];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            [self animatePhotoViewWhenGestureEnd];
            break;
        }
        default:
            break;
    }
}

#pragma mark - Pan close gesture
//整体的动画
- (void)refreshPhotoViewFrame:(CGPoint)translation velocity:(CGPoint)velocity   //!OCLint 待重构
{
    if (self.direction == EMAPhotoScrollViewMoveDirectionNone) {
        //刚开始识别方向
        if (translation.y > moveDirectionStartOffset) {
            self.direction = EMAPhotoScrollViewMoveDirectionVerticalBottom;
        }
        if (translation.y < -moveDirectionStartOffset) {
            self.direction = EMAPhotoScrollViewMoveDirectionVerticalTop;
        }
    } else {
        //重新识别方向
        EMAPhotoScrollViewMoveDirection currentDirection = EMAPhotoScrollViewMoveDirectionNone;
        if (translation.y > moveDirectionStartOffset) {
            currentDirection = EMAPhotoScrollViewMoveDirectionVerticalBottom;
        } else if (translation.y < -moveDirectionStartOffset) {
            currentDirection = EMAPhotoScrollViewMoveDirectionVerticalTop;
        } else {
            currentDirection = EMAPhotoScrollViewMoveDirectionNone;
        }
        
        if (currentDirection == EMAPhotoScrollViewMoveDirectionNone) {
            self.direction = currentDirection;
            return; //忽略其他手势
        }
        
        BOOL verticle = (self.direction == EMAPhotoScrollViewMoveDirectionVerticalBottom || self.direction == EMAPhotoScrollViewMoveDirectionVerticalTop);
        CGFloat y = 0;
        if (self.direction == EMAPhotoScrollViewMoveDirectionVerticalTop) {
            y = translation.y + moveDirectionStartOffset;
        } else if (self.direction == EMAPhotoScrollViewMoveDirectionVerticalBottom){
            y = translation.y - moveDirectionStartOffset;
        }
        
        CGFloat yFraction = fabs(translation.y / CGRectGetHeight(self.photoScrollView.frame));
        yFraction = fminf(fmaxf(yFraction, 0.0), 1.0);
        
        //距离判断+速度判断
        if (verticle) {
            if (yFraction > 0.2) {
                self.reachDismissCondition = YES;
            } else {
                self.reachDismissCondition  = NO;
            }
            
            if (velocity.y > 1500) {
                self.reachDismissCondition = YES;
            }
        }
        
        CGRect frame = CGRectMake(0, y, CGRectGetWidth(self.photoScrollView.frame), CGRectGetHeight(self.photoScrollView.frame));
        self.photoScrollView.frame = frame;
        
        //下拉动画
        if (verticle) {
            self.reachDragCondition = YES;
            [self addAnimatedViewToContainerView:yFraction];
        }
        
    }
    
}

//释放的动画
- (void)animatePhotoViewWhenGestureEnd
{
    EMAShowImageView *imageView = [self showImageViewAtIndex:_currentIndex];
    if (!_reachDragCondition) {
        imageView.hidden = NO;
        return; //未曾满足过一次识别手势，不触发动画
    } else {
        self.reachDragCondition = NO;
    }
    
    CGRect endRect = [self frameForPagingScrollView];
    CGFloat opacity = 1;
    
    if (_reachDismissCondition) {
        if (self.direction == EMAPhotoScrollViewMoveDirectionVerticalBottom)
        {
            endRect.origin.y += CGRectGetHeight(self.photoScrollView.frame);
        } else if (self.direction == EMAPhotoScrollViewMoveDirectionVerticalTop) {
            endRect.origin.y -= CGRectGetHeight(self.photoScrollView.frame);
        }
        opacity = 0;
    }else{
        imageView.hidden = NO;
    }
    
    [UIView animateWithDuration:0.25 animations:^{
        self.photoScrollView.frame = endRect;
        [self addAnimatedViewToContainerView: 1 - opacity];
    } completion:^(BOOL finished) {
        self.direction = EMAPhotoScrollViewMoveDirectionNone;
        if (_reachDismissCondition) {
            [self dismissAnimated:YES completion:nil];
        } else {
            [self removeAnimatedViewToContainerView];
        }
    }];
}

//添加顶部和底部的动画
- (void)addAnimatedViewToContainerView:(CGFloat)yFraction
{
    self.containerView.alpha = (1 - yFraction * 2 / 3);
    [UIView animateWithDuration:0.15 animations:^{
        self.pageIndcatorView.alpha = 0;
    }];
}

//移除顶部和底部的动画
- (void)removeAnimatedViewToContainerView
{
    self.photoScrollView.frame = [self frameForPagingScrollView];
    self.containerView.alpha = 1;
    [UIView animateWithDuration:0.15 animations:^{
        self.pageIndcatorView.alpha = 1;
    }];
}

#pragma mark - Present & dismiss
- (void)presentPhotoScrollView:(UIWindow *)window {
    window = window ?: OPWindowHelper.fincMainSceneWindow;
    UIViewController *rootViewController = window.rootViewController;
    while (rootViewController.presentedViewController) {
        rootViewController = rootViewController.presentedViewController;
    }
    // 不采用presentViewController默认动画是因为该动画打开和关闭后一小段时间内不响应点击事件，体验不佳
    [rootViewController presentViewController:self animated:NO completion:nil];

}

- (void)dismissAnimated:(BOOL)animated completion: (void (^ __nullable)(void))completion
{
    if (self.alreadyFinished) {
        if (completion) {
            completion();
        }
        return;
    }

    self.statusBarHidden = NO;
    if (animated) {
        [UIView animateWithDuration:0.3 animations:^{
            self.view.alpha = 0;
        } completion:^(BOOL finished) {
            [self dismissViewControllerAnimated:NO completion:completion];
        }];
    }else {
        [self dismissViewControllerAnimated:NO completion:completion];
    }

    self.alreadyFinished = YES;
}

#pragma EMAPreviewPanBackDelegate

- (void)ttPreviewPanBackStateChange:(EMAPreviewAnimateState)currentState scale:(float)scale{
    EMAShowImageView *imageView = [self showImageViewAtIndex:_currentIndex];
    switch (currentState) {
        case EMAPreviewAnimateStateWillBegin:
            self.statusBarHidden = NO;
            self.pageIndcatorView.alpha = 0;
            imageView.hidden = YES;
            break;
        case EMAPreviewAnimateStateChange:
            self.containerView.alpha = MAX(0,(scale*14-13 - _animateManager.minScale)/(1 - _animateManager.minScale));
            break;
        case EMAPreviewAnimateStateDidFinish:
            self.reachDismissCondition = YES;
            self.containerView.alpha = 0;
            [self dismissAnimated:NO completion:nil];
            break;
        case EMAPreviewAnimateStateWillCancel:
        {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.statusBarHidden = YES; // 延迟一点执行避免显示背景VC由于隐藏StatusBar带来的抖动
            });
        }
            break;
        case EMAPreviewAnimateStateDidCancel:
            self.containerView.alpha = 1;
            self.pageIndcatorView.alpha = 1;
            imageView.hidden = NO;
            break;
        default:
            break;
    }
}

- (UIView *)ttPreviewPanBackGetOriginView{
    
    return [self showImageViewAtIndex:_currentIndex].imageView;
}

- (UIView *)ttPreviewPanBackGetBackMaskView{
    return _targetView ? _targetView : self.finishBackView;
};

- (CGRect)ttPreviewPanBackTargetViewFrame{
    if (_currentIndex >= self.animateFrames.count){
        return CGRectZero;
    }
    NSValue *frameValue = [self.animateFrames objectAtIndex:_currentIndex];
    
    return frameValue.CGRectValue;
}

- (CGFloat)ttPreviewPanBackTargetViewCornerRadius {

    if (_currentIndex < 0 || _currentIndex >= self.placeHolderSourceViewCornerRadius.count) {
        return 0;
    }
    NSNumber *cornerRadiusValue = [self.placeHolderSourceViewCornerRadius objectAtIndex:_currentIndex];
    if ([cornerRadiusValue isKindOfClass:[NSNumber class]] && cornerRadiusValue.floatValue >= 0) {
        return cornerRadiusValue.floatValue;
    }
    return 0;
}

- (UIView *)ttPreviewPanBackGetFinishBackgroundView{
    return self.view.window ?: OPWindowHelper.fincMainSceneWindow;
}

- (void)ttPreviewPanBackFinishAnimationCompletion{
    self.containerView.alpha = 0;
}

- (void)ttPreviewPanBackCancelAnimationCompletion{
    self.containerView.alpha = 1;
}

- (BOOL)ttPreviewPanGestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return [self newGestureEnable];
}

#pragma UIGestureDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer == self.panGestureRecognizer){
        return ![self newGestureEnable];
    }
    return YES;
}

- (void)onLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        EMAShowImageView * currentImageView = [self showImageViewAtIndex:self->_currentIndex];
        if (currentImageView.hasImage || self.currentShowOriginButton) {
            __weak typeof(self) weakSelf = self;
            NSMutableArray *actions = [NSMutableArray array];
            if (self.shouldShowSaveOption && currentImageView.hasImage) {
                EMAActionSheetAction *action = [EMAActionSheetAction actionWithTitle:BDPI18n.save_image style:UIAlertActionStyleDefault handler:^{
                    [currentImageView saveImage];
                }];
                [actions addObject:action];
            }

            if (self.currentShowOriginButton) {
                EMAActionSheetAction *action = [EMAActionSheetAction actionWithTitle:BDPI18n.full_image style:UIAlertActionStyleDefault handler:^{
                    __strong typeof(self) self = weakSelf;
                    [self useOriginImage];
                }];
                [actions addObject:action];
            }

            EMAActionSheetAction *action = [EMAActionSheetAction actionWithTitle:BDPI18n.cancel style:UIAlertActionStyleCancel handler:nil];
            [actions addObject:action];
            
            UIViewController *actionSheet = [OPActionSheet createActionSheetWith:actions isAutorotatable:[UDRotation isAutorotateFrom:self]];

            if ([self.delegate respondsToSelector:@selector(handelQRCode:fromController:)]) {
                [self scanQRCode:currentImageView touchSender:sender resultBlock:^(NSString *result) {
                    if (result) {
                        BDPLogInfo(@"scanQRCode result: %@", result);
                        EMAActionSheetAction *action = [EMAActionSheetAction actionWithTitle:BDPI18n.extract_qr_code style:UIAlertActionStyleDefault handler:^{
                            __strong typeof(self) self = weakSelf;
                            [self.delegate handelQRCode:result fromController:self];
                        }];
                        [OPActionSheet dynamicAddActionsWith:[NSArray arrayWithObject:action] for:actionSheet];
                    }
                }];
            }
            [self presentViewController:actionSheet animated:YES completion:nil];
        }
    }
}

- (void)scanQRCode:(EMAShowImageView *)imageView touchSender:(UIGestureRecognizer *)sender resultBlock:(void(^)(NSString *result))resultBlock {
    UIImage *image = imageView.image;
    CGPoint touchPointInImage = [imageView touchPointInImageLocation:[sender locationInView:imageView]];

    dispatch_async(dispatch_get_global_queue(0, 0), ^(void) {
        NSString *result = [image ema_qrCodeNearPoint:touchPointInImage];
        dispatch_async(dispatch_get_main_queue(), ^(void){
            if(resultBlock) resultBlock(result);
        });
    });
}

@end

