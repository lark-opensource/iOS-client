//
//  ACCCutMusicBarChartView.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by Chen Long on 2020/9/16.
//

#import "ACCCutMusicBarChartView.h"
#import "ACCCutMusicPanelView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCPassThroughView.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCResourceHeaders.h>
#import <Masonry/View+MASAdditions.h>

static const CGFloat kBarChartViewHeight = 56.f;

static const CGFloat kEmptyMargin = 16.f;

static const CGFloat kChartBarWidth = 2.f;
static const CGFloat kChartBarSpace = 1.5f;
static const CGFloat kCharBarMaxHeight = 40.f;
static const CGFloat kCharBarMinHeight = 2.f;


@interface ACCCutMusicBarChartView () <UIScrollViewDelegate>

@property (nonatomic, assign) ACCCutMusicPanelViewStyle style;

@property (nonatomic, assign) CGFloat currentTime;
@property (nonatomic, assign) CGFloat scrollViewOriginContentSizeWidth;
@property (nonatomic, assign) CGPoint currentOffset; // 用于计算 range
@property (nonatomic, assign) CGPoint offsetBeforeLoop; // 记录手动置0前的值
@property (nonatomic, assign) BOOL shouldChangeCurrentOffset;

@property (nonatomic, strong) UIView *selectedBackgroundView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *beginLineView;
@property (nonatomic, strong) UIView *endLineView;
@property (nonatomic, strong) UIImageView *endLineIconImageView;
@property (nonatomic, strong) ACCPassThroughView *canShootAreaMaskView;

@property (nonatomic, strong) CALayer *canvasLayer;
@property (nonatomic, strong) CALayer *progressLayer;
@property (nonatomic, strong) CALayer *placeholderLayer;
@property (nonatomic, strong) CAShapeLayer *progressMaskLayer;
@property (nonatomic, strong) CAShapeLayer *placeholderMaskLayer;


@end

@implementation ACCCutMusicBarChartView

+ (CGFloat)chartViewHeight
{
    return kBarChartViewHeight;
}

+ (NSUInteger)barCountWithFullWidth
{
    return round((ACC_SCREEN_WIDTH - 2 * kEmptyMargin) / (kChartBarWidth + kChartBarSpace));
}

- (instancetype)initWithStyle:(ACCCutMusicPanelViewStyle)style
{
    if (self = [super initWithFrame:CGRectZero]) {
        _style = style;
        _shouldChangeCurrentOffset = YES;
        [self p_setupUI];
    }
    return self;
}

- (void)updateBarWithHeights:(NSArray<NSNumber *> *)heights
{
    for (CALayer *layer in [self.canvasLayer.sublayers copy]) {
        [layer removeFromSuperlayer];
    }
    for (CALayer *layer in [self.progressLayer.sublayers copy]) {
        [layer removeFromSuperlayer];
    }
    for (CALayer *layer in [self.placeholderLayer.sublayers copy]) {
        [layer removeFromSuperlayer];
    }

    // 重设 contentSize 之前记录 offset，用于计算 range
    if (self.shouldChangeCurrentOffset || !ACCBLOCK_INVOKE(self.isMusicLoopOpenBlock)) {
        self.currentOffset = self.scrollView.contentOffset;
        self.shouldChangeCurrentOffset = YES;
    }
    self.scrollViewOriginContentSizeWidth = (kChartBarWidth + kChartBarSpace) * heights.count - kChartBarSpace + kEmptyMargin * 2;
    self.scrollView.contentSize = CGSizeMake(self.scrollViewOriginContentSizeWidth, kBarChartViewHeight);
    self.canvasLayer.frame = CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height);
    self.progressLayer.frame = CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height);
    self.placeholderLayer.frame = CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height);
    [self p_adjustContentSizeIfNeeded:heights.count];

    for (int i = 0; i < heights.count; i++) {
        NSNumber *heightNumber = heights[i];
        CGFloat height = [heightNumber floatValue];
        [self p_configMusicLoopIdentifierFrameIfNeeded:i];
        [self p_addBarAtIndex:i
                       height:height
                        color:self.style == ACCCutMusicPanelViewStyleLight ? ACCResourceColor(ACCColorTextReverse4) : ACCResourceColor(ACCColorConstTextInverse)
                      toLayer:self.canvasLayer];
        [self p_addBarAtIndex:i
                       height:height
                        color:ACCResourceColor(ACCColorPrimary)
                      toLayer:self.progressLayer];
        [self p_addBarAtIndex:i
                       height:height
                        color:self.style == ACCCutMusicPanelViewStyleLight ? [UIColor colorWithWhite:0.9 alpha:1] : [UIColor colorWithWhite:0.4 alpha:1]
                      toLayer:self.placeholderLayer];
    }

    [self p_configEndLineViewHidden];
    [self p_configEndLineIconViewHidden];
    [self p_configCanShootAreaMaskViewHidden];

    [self p_updatePlaceholderLayer];
}

- (void)setRangeStart:(CGFloat)location
{
    [self setRangeStart:location animated:NO];
}

- (void)setRangeStart:(CGFloat)location animated:(BOOL)animated
{
    CGPoint contentOffset = self.scrollView.contentOffset;

    BOOL isMusicLoopOpen = ACCBLOCK_INVOKE(self.isMusicLoopOpenBlock);
    CGFloat contentWidth = MIN(self.scrollViewOriginContentSizeWidth, self.scrollView.contentSize.width) - 2 * kEmptyMargin;
    CGFloat rightDuration = isMusicLoopOpen ? self.cutDuration : self.totalDuration;
    CGFloat scale = 1;

    if (!ACC_FLOAT_EQUAL_ZERO(rightDuration)) {
        scale = contentWidth / rightDuration;
    }
    contentOffset.x = location * scale;

    if (contentOffset.x >= 0 && contentOffset.x <= self.scrollView.contentSize.width) {
        self.currentOffset = contentOffset;
        self.offsetBeforeLoop = contentOffset;
        // 循环打开的时候，不需要设置 Offset
        if (!isMusicLoopOpen) {
            [self.scrollView setContentOffset:contentOffset animated:animated];
        }
    }
}

- (void)updateTimestamp:(CGFloat)time
{
    if (time != NAN && !isnan(time)) {
        _currentTime = time;
    }
    [self setNeedsLayout];
}

- (HTSAudioRange)currentRange
{
    CGFloat offsetX = self.currentOffset.x;

    HTSAudioRange range;
    if (self.scrollView.contentSize.width != 0) {
        CGFloat scale = self.cutDuration / (ACC_SCREEN_WIDTH - 2 * kEmptyMargin);
        range.location = round(offsetX * scale);
    }

    if (ACC_FLOAT_GREATER_THAN(self.videoMusicShootRatio, 1)) {
        BOOL isMusicLoopOpen = ACCBLOCK_INVOKE(self.isMusicLoopOpenBlock);
        if (ACC_FLOAT_GREATER_THAN(self.musicMusicShootRatio, 1) && !isMusicLoopOpen) {
            range.length = self.totalDuration;
        } else {
            range.length = self.musicShootDuration;
        }
    } else {
        range.length = self.cutDuration;
    }
    return range;
}

- (void)resetContentOffsetToZero
{
    self.offsetBeforeLoop = self.currentOffset;
    // 解决分隔符不与音柱重合的 UI 问题
    self.scrollView.contentOffset = CGPointZero;
    // 手动置 0 后不需要更新到 currentOffset 中
    self.shouldChangeCurrentOffset = NO;
}

- (void)resetContentOffsetBeforeLoop
{
    self.scrollView.contentOffset = self.offsetBeforeLoop;
    self.currentOffset = self.offsetBeforeLoop;
}

- (void)resetParameters
{
    self.currentOffset = CGPointZero;
    self.offsetBeforeLoop = CGPointZero;
}

#pragma mark - Over write

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:NSStringFromSelector(@selector(currentRange))]) {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    BOOL isMusicLoopOpen = ACCBLOCK_INVOKE(self.isMusicLoopOpenBlock);
    CGFloat contentWidth = self.scrollViewOriginContentSizeWidth - 2 * kEmptyMargin;
    CGFloat rightDuration = isMusicLoopOpen ? self.cutDuration : self.totalDuration;
    CGFloat scale = 1;

    if (!ACC_FLOAT_EQUAL_ZERO(rightDuration)) {
        scale = contentWidth / rightDuration;
    }
    CGFloat width = kEmptyMargin + self.currentTime * scale;

    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, width, self.scrollView.contentSize.height)];
    self.progressMaskLayer.path = path.CGPath;
}

#pragma mark -

- (void)p_addBarAtIndex:(int)i height:(CGFloat)height color:(UIColor *)color toLayer:(CALayer *)toLayer
{
    CGFloat validHeight = MIN(1, MAX(0, height));
    validHeight = kCharBarMaxHeight * validHeight;
    validHeight = MAX(kCharBarMinHeight, validHeight);
    
    CGFloat xPos = kEmptyMargin + (kChartBarWidth + kChartBarSpace) * i;
    CGFloat yPos = (kBarChartViewHeight - validHeight) / 2.0;
    CALayer *barLayer = [[CALayer alloc] init];
    barLayer.backgroundColor = color.CGColor;
    barLayer.cornerRadius = kChartBarWidth / 2.0;
    barLayer.frame = CGRectMake(xPos, yPos, kChartBarWidth, validHeight);
    [toLayer addSublayer:barLayer];
}

#pragma mark - 音乐循环播放标识符 UI 设置

- (void)p_configMusicLoopIdentifierFrameIfNeeded:(int)currentIndex
{
    if (self.shouldShowMusicLoopComponent && currentIndex == self.firstLoopEndLocation) {
        CGFloat offsetX = kEmptyMargin + (kChartBarWidth + kChartBarSpace) * (self.firstLoopEndLocation + 1);
        CGRect endLineFrame = CGRectMake(offsetX, 0, kChartBarWidth, kBarChartViewHeight);
        self.endLineView.frame = endLineFrame;

        CGRect endLineIconFrame = CGRectMake(offsetX - 2, kBarChartViewHeight + 2, 6, 8);
        self.endLineIconImageView.frame = endLineIconFrame;

        CGRect canShootAreaMaskFrame = CGRectMake(kEmptyMargin, 0, offsetX - kEmptyMargin + 2, kBarChartViewHeight);
        self.canShootAreaMaskView.frame = canShootAreaMaskFrame;
    }
}

- (void)p_adjustContentSizeIfNeeded:(NSUInteger)heightCount
{
    BOOL currentLoopIsOn = ACCBLOCK_INVOKE(self.isMusicLoopOpenBlock);
    BOOL isMusicLongerThanMusicShoot = ACC_FLOAT_GREATER_THAN(self.musicMusicShootRatio, 1);

    if (self.shouldShowMusicLoopComponent && isMusicLongerThanMusicShoot && !currentLoopIsOn) {
        // 音乐时长大于音乐可拍时长，且循环关闭状态下，需要扩充 scrollView 的 contentSize
        CGFloat fullWidth = ACC_SCREEN_WIDTH - 2 * kEmptyMargin;
        CGFloat originWidth = (kChartBarWidth + kChartBarSpace) * heightCount - kChartBarSpace;
        CGFloat newWidth = originWidth;
        // 拍摄时长小于试听时长，此时 contentWidth 已大于 frame
        if (ACC_FLOAT_LESS_THAN(self.videoMusicRatio, 1)) {
            if (!ACC_FLOAT_EQUAL_ZERO(self.videoMusicShootRatio)) {
                CGFloat ratio = 1 - 1 / self.videoMusicShootRatio;
                newWidth += (fullWidth * ratio + 2 * kEmptyMargin);
            }
        } else {
            // 拍摄时长大于试听时长，此时 contentWidth 小于 frame
            if (!ACC_FLOAT_EQUAL_ZERO(self.musicMusicShootRatio)) {
                CGFloat ratio = 1 - 1 / self.musicMusicShootRatio;
                newWidth = originWidth * (ratio + self.videoMusicRatio) + 2 * kEmptyMargin;
            }
        }
        self.scrollView.contentSize = CGSizeMake(newWidth, self.scrollView.contentSize.height);
    }
}

- (void)p_configEndLineViewHidden
{
    BOOL currentLoopIsOn = ACCBLOCK_INVOKE(self.isMusicLoopOpenBlock);
    BOOL isMusicLongerThanMusicShoot = ACC_FLOAT_GREATER_THAN(self.musicMusicShootRatio, 1);

    self.endLineView.hidden = YES;
    if (self.shouldShowMusicLoopComponent && (currentLoopIsOn || isMusicLongerThanMusicShoot)) {
        self.endLineView.hidden = NO;
    }
}

- (void)p_configEndLineIconViewHidden
{
    BOOL currentLoopIsOn = ACCBLOCK_INVOKE(self.isMusicLoopOpenBlock);

    self.endLineIconImageView.hidden = YES;
    if (self.shouldShowMusicLoopComponent && currentLoopIsOn) {
        self.endLineIconImageView.hidden = NO;
    }
}

- (void)p_configCanShootAreaMaskViewHidden
{
    BOOL currentLoopIsOn = ACCBLOCK_INVOKE(self.isMusicLoopOpenBlock);
    BOOL isMusicLongerThanMusicShoot = ACC_FLOAT_GREATER_THAN(self.musicMusicShootRatio, 1);

    self.canShootAreaMaskView.hidden = YES;
    if (self.shouldShowMusicLoopComponent && !currentLoopIsOn && isMusicLongerThanMusicShoot) {
        self.canShootAreaMaskView.hidden = NO;
    }
}

#pragma mark - UI

- (void)p_setupUI
{
    [self addSubview:self.selectedBackgroundView];
    ACCMasMaker(self.selectedBackgroundView, {
        make.left.equalTo(self).offset(kEmptyMargin);
        make.top.centerX.bottom.equalTo(self);
    });
    
    [self addSubview:self.scrollView];
    ACCMasMaker(self.scrollView, {
        make.edges.equalTo(self);
    });
    
    [self addSubview:self.beginLineView];
    ACCMasMaker(self.beginLineView, {
        make.top.bottom.left.equalTo(self.selectedBackgroundView);
        make.width.equalTo(@(kChartBarWidth));
    });

    [self addSubview:self.endLineView];
    [self addSubview:self.endLineIconImageView];
    [self addSubview:self.canShootAreaMaskView];
    
    [self.scrollView.layer addSublayer:self.canvasLayer];
    [self.scrollView.layer addSublayer:self.progressLayer];
    [self.scrollView.layer addSublayer:self.placeholderLayer];
}

- (void)p_updatePlaceholderLayer
{
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, self.scrollView.contentSize.width, self.scrollView.contentSize.height)];
    UIBezierPath *innerPath = [UIBezierPath bezierPathWithRect:CGRectMake(self.scrollView.contentOffset.x + kEmptyMargin, 1, ACC_SCREEN_WIDTH - kEmptyMargin * 2, self.scrollView.contentSize.height - 2)];
    [path appendPath:innerPath];
    
    self.placeholderMaskLayer.path = path.CGPath;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        self.currentOffset = scrollView.contentOffset;
        [self p_notifyRangeChanged:scrollView];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.currentOffset = scrollView.contentOffset;
    [self p_notifyRangeChanged:scrollView];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self p_updatePlaceholderLayer];
}

- (void)p_notifyRangeChanged:(UIScrollView *)scrollView
{
    [self willChangeValueForKey:NSStringFromSelector(@selector(currentRange))];
    [self didChangeValueForKey:NSStringFromSelector(@selector(currentRange))];
}

#pragma mark - Setters

- (void)setChartViewScrollEnabled:(BOOL)chartViewScrollEnabled
{
    _chartViewScrollEnabled = chartViewScrollEnabled;
    self.scrollView.scrollEnabled = _chartViewScrollEnabled;
}

#pragma mark - Getters

- (UIView *)selectedBackgroundView
{
    if (!_selectedBackgroundView) {
        _selectedBackgroundView = [[UIView alloc] init];
        if (self.style == ACCCutMusicPanelViewStyleLight) {
            _selectedBackgroundView.backgroundColor = ACCResourceColor(ACCColorBGInputReverse);
        } else {
            _selectedBackgroundView.backgroundColor = ACCResourceColor(ACCColorLineSecondary);
        }
    }
    return _selectedBackgroundView;
}

- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.delegate = self;
        _scrollView.bounces = NO;
    }
    return _scrollView;
}

- (UIView *)beginLineView
{
    if (!_beginLineView) {
        _beginLineView = [[UIView alloc] init];
        if (self.style == ACCCutMusicPanelViewStyleLight) {
            _beginLineView.backgroundColor = ACCResourceColor(ACCColorTextReverse);
        } else {
            _beginLineView.backgroundColor = ACCResourceColor(ACCColorConstTextInverse);
        }
    }
    return _beginLineView;
}

- (UIView *)endLineView
{
    if (!_endLineView) {
        _endLineView = [[UIView alloc] init];
        if (self.style == ACCCutMusicPanelViewStyleLight) {
            _endLineView.backgroundColor = ACCResourceColor(ACCColorBGInverse4);
        } else {
            _endLineView.backgroundColor = ACCResourceColor(ACCColorBGReverse);
        }
        _endLineView.hidden = YES;
    }
    return _endLineView;
}

- (UIImageView *)endLineIconImageView
{
    if (!_endLineIconImageView) {
        _endLineIconImageView = [[UIImageView alloc] init];
        UIImage *iconImage = [ACCResourceImage(@"music_clip_end_line_icon") imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _endLineIconImageView.image = iconImage;
        if (self.style == ACCCutMusicPanelViewStyleLight) {
            [_endLineIconImageView setTintColor:ACCResourceColor(ACCColorTextReverse4)];
        } else {
            [_endLineIconImageView setTintColor:ACCResourceColor(ACCColorBGReverse)];
        }
        _endLineIconImageView.hidden = YES;
    }
    return _endLineIconImageView;
}

- (ACCPassThroughView *)canShootAreaMaskView
{
    if (!_canShootAreaMaskView) {
        _canShootAreaMaskView = [[ACCPassThroughView alloc] init];
        if (self.style == ACCCutMusicPanelViewStyleLight) {
            [_canShootAreaMaskView setBackgroundColor:ACCResourceColor(ACCColorBGBrand)];
        } else {
            [_canShootAreaMaskView setBackgroundColor:ACCResourceColor(ACCColorBGBrand2)];
        }
    }
    return _canShootAreaMaskView;
}

- (CALayer *)canvasLayer
{
    if (!_canvasLayer) {
        _canvasLayer = [CALayer layer];
    }
    return _canvasLayer;
}

- (CALayer *)progressLayer
{
    if (!_progressLayer) {
        _progressLayer = [CALayer layer];
        _progressLayer.mask = self.progressMaskLayer;
    }
    return _progressLayer;
}

- (CALayer *)placeholderLayer
{
    if (!_placeholderLayer) {
        _placeholderLayer = [CALayer layer];
        _placeholderLayer.mask = self.placeholderMaskLayer;
    }
    return _placeholderLayer;
}

- (CAShapeLayer *)progressMaskLayer
{
    if (!_progressMaskLayer) {
        _progressMaskLayer = [CAShapeLayer layer];
    }
    return _progressMaskLayer;
}

- (CAShapeLayer *)placeholderMaskLayer
{
    if (!_placeholderMaskLayer) {
        _placeholderMaskLayer = [CAShapeLayer layer];
        _placeholderMaskLayer.fillRule = kCAFillRuleEvenOdd;
    }
    return _placeholderMaskLayer;
}

@end
