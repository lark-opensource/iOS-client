//
//  CJPayLoopView.m
//  CJPay
//
//  Created by 王新华 on 2019/4/26.
//

#import "CJPayLoopView.h"
#import "CJPayUIMacro.h"

@interface CJPayLoopView()<UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, copy) NSArray <UIView *> *views;
@property (nonatomic, strong) UIImageView *leftPosView;
@property (nonatomic, strong) UIImageView *rightPosView;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, copy) NSArray<NSNumber *> *durationArray;

@property (nonatomic, assign) int pageNum;

@end

@implementation CJPayLoopView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        _pageNum = 0;
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return self.cj_size;
}

- (void)setupUI {
    self.scrollView = [[UIScrollView alloc] initWithFrame: self.bounds];
    self.scrollView.pagingEnabled = YES;
    self.scrollView.bounces = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.delegate = self;
    self.contentView = [UIView new];
    [self.scrollView addSubview:self.contentView];
    [self addSubview:self.scrollView];
}

- (void)updateSubViews:(NSArray<UIView *> *)views
             durations:(nullable NSArray<NSNumber *> *)durations
       startAutoScroll:(BOOL)yesOrNo {
    self.hidden = views.count < 1;
    if (views.count < 1) {
        return;
    }
    self.durationArray = durations;
    self.scrollView.frame = self.bounds;
//    CJPayLogAssert(self.frame.size.width > 0 && self.frame.size.height > 0, @"在未设置frame的情况下，不要更新views");
    [self.contentView cj_removeAllSubViews];
    self.views = views;
    if (views.count <= 0) {
        return;
    }
    CGFloat oneW = self.cj_width;
    CGFloat oneH = self.cj_height;
    self.scrollView.scrollEnabled = views.count > 1;
    __block CGFloat startX = views.count > 1 ? oneW : 0;
    @CJWeakify(self)
    [views enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.frame = CGRectMake(startX, 0, oneW, oneH);
        obj.clipsToBounds = YES;
        [weak_self.contentView addSubview:obj];
        startX = startX + oneW;
    }];
    if (views.count > 1) {
        [self.contentView addSubview:self.leftPosView];
        self.rightPosView.frame = CGRectMake(startX, 0, oneW, oneH);
        [self.contentView addSubview:self.rightPosView];
        self.scrollView.contentSize = CGSizeMake(oneW * (views.count + 2), oneH);
    } else {
        self.scrollView.contentSize = CGSizeMake(oneW, oneH);
    }
    self.contentView.frame = CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height);
    
    if ([self.indicatorDelegate respondsToSelector:@selector(configCount:)]) {
        [self.indicatorDelegate configCount:views.count];
    }
    [self.scrollView setContentOffset:CGPointMake(views.count > 1 ? oneW : 0, 0) animated:NO];
//    [self.scrollView setContentOffset:CGPointMake(oneW, 0) animated:NO];
    if (yesOrNo) {
        [self startAutoScroll];
    }
}

- (UIImageView *)leftPosView {
    if (!_leftPosView) {
        _leftPosView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.cj_width, self.cj_height)];
    }
    return _leftPosView;
}

- (UIImageView *)rightPosView {
    if (!_rightPosView) {
        _rightPosView = [UIImageView new];
    }
    return _rightPosView;
}

- (NSInteger)currentIndex {
    return (NSInteger) ceil(self.scrollView.contentOffset.x / self.scrollView.cj_width);
}

- (void)startAutoScroll {
    if ([self.delegate respondsToSelector:@selector(loopView:bannerAppearAtIndex:atPage:)]) {
        [self.delegate loopView:self
            bannerAppearAtIndex:(NSUInteger) (self.currentIndex - (self.views.count > 1 ? 1 : 0))
                atPage:self.pageNum];
    }

    if (self.views.count < 2) {
        [self stopAutoScroll];
        return;
    }
    // 未设置durationArray，timer不重复设置；设置了durationArray，需要更新timer
    if (self.timer && (!self.durationArray || self.durationArray.count == 0)) {
        return;
    }

    [self stopAutoScroll];

    NSTimeInterval duration;
    NSNumber *number = [self.durationArray cj_objectAtIndex:self.currentIndex - 1];
    if (number) {
        duration = number.doubleValue;
    } else {
        duration = 3;
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:duration target:[BTDWeakProxy proxyWithTarget:self] selector:@selector(autoScroll) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)stopAutoScroll {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)autoScroll {
    NSInteger trueCount = self.views.count + 2;
    NSInteger newIndex = @(ceil(_scrollView.contentOffset.x / _scrollView.cj_width) + 1).integerValue % trueCount;
    newIndex = MIN(newIndex, trueCount - 1);
    [_scrollView setContentOffset:CGPointMake(@(newIndex * _scrollView.cj_width).floatValue, 0) animated:YES];
}

- (void)correctContentOffset {
    NSInteger curIndex = self.currentIndex;
    if (curIndex == 0) {
        [_scrollView setContentOffset:CGPointMake(self.views.count * self.cj_width, 0) animated:NO];
        self.pageNum = MIN(0, self.pageNum - 1);
    }
    if (curIndex == self.views.count + 1) {
        [_scrollView setContentOffset:CGPointMake(self.cj_width, 0) animated:NO];
        self.pageNum += 1;
    }
}

#pragma mark scrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    NSInteger curIndex = self.currentIndex;
    if (curIndex < 2) {
        _leftPosView.image = [self.views.lastObject cjpay_snapShotImage];
    }
    if (curIndex > (NSInteger)self.views.count - 1) {
        _rightPosView.image = [self.views.firstObject cjpay_snapShotImage];
    }
    if ([self.indicatorDelegate respondsToSelector:@selector(didScrollTo:)]) {
        [self.indicatorDelegate didScrollTo:[self calTureIndexBy:curIndex]];
    }
}

- (NSInteger)calTureIndexBy:(NSInteger)curIndex {
    if (self.views.count < 2) {
        return curIndex;
    }
    if (curIndex == 0) {
        return (NSInteger)self.views.count - 1;
    } else if (curIndex == self.views.count + 1) {
        return 0;
    } else {
        return curIndex - 1;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (!decelerate) {
        [self correctContentOffset];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self correctContentOffset];
    [self startAutoScroll];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self correctContentOffset];
    [self startAutoScroll];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [self stopAutoScroll];
}

@end
