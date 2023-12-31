//
//  AWEVideoEffectMixTimeBar.m
//  Aweme
//
//  Created by Liu Bing on 4/10/17.
//  Copyright © 2017 Bytedance. All rights reserved.
//

#import "AWEVideoEffectMixTimeBar.h"
#import "AWETopBlendingView.h"
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CameraClient/UIImage+ACCUIKit.h>
#import <CreativeKit/ACCMacros.h>

static CGFloat kPlayerControlWidth = 44;
const CGFloat KScalableRangeViewPadding = 12;
static NSInteger kEffectRangeViewTag = 1000;

@interface AWEVideoEffectMixTimeBar () <AWEVideoEffectScalableRangeViewDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSString *, UIView *> *fragmentsContainers; //滤镜特效生效区间容器
@property (nonatomic, strong) NSMutableDictionary<IESMMEffectTimeRange*, NSObject<AWEVideoEffectRangeProtocol> *> *effectRangeViewMap;
@property (nonatomic, strong) AWEVideoPlayControl *willMovingView;
@property (nonatomic, strong) AWEVideoPlayControl *movingView;
@property (nonatomic, assign) CGPoint touchBeganPoint;
@property (nonatomic, assign) CGPoint originalPoint;
@property (nonatomic, strong) AWEVideoEffectScalableRangeView *toolEffectRangeView;
@property (nonatomic, assign) BOOL isShowingToolEffectRangeView; // 正在显示toolEffectRangeView

//for the moment, tab "time" is diff from other tab,  create unique rangeView for it
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIView *> *timeFragmentsContainers; //time effect view contianer
@property (nonatomic, strong) NSMutableDictionary<IESMMEffectTimeRange*, NSObject<AWEVideoEffectRangeProtocol>  *> *timeEffectRangeViewMap;
@property (nonatomic, strong) AWEVideoEffectScalableRangeView *timeEffectRangeView;
@property (nonatomic, assign) BOOL isShowingTimeEffectRangeView; // judge whether to display timeEffectRangeView

@end

@implementation AWEVideoEffectMixTimeBar

#pragma mark - Init & Dealloc

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _effectRangeViewMap = @{}.mutableCopy;
        _timeEffectRangeViewMap = @{}.mutableCopy;
        
        [self addSubview:self.timeReverseMask];
        [self addSubview:self.playProgressControl];
        [self addSubview:self.timeSelectControl];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    _timeReverseMask.frame = self.bounds;
}

#pragma mark - Public

- (void)animateElements
{
    for (UIView *view in self.subviews) {
        if (view.alpha == 1.0) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.fromValue = @(1);
            animation.toValue = @(0);
            animation.autoreverses = YES;
            animation.duration = 0.3;
            [view.layer addAnimation:animation forKey:@"animation"];
        }
    }
}

- (void)updateShowingToolEffectRangeViewIfNeededWithCategoryKey:(NSString *)categoryKey effectSelected:(BOOL)selected {
    __block BOOL found = NO;
    [self.fragmentsContainers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, UIView * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:categoryKey]) { // 在字典中找到当前所处的tab
            obj.alpha = 1.0;
            self.isShowingToolEffectRangeView = [key isEqualToString:@"sticker"];
            UIView *EffectRangeView = [obj viewWithTag:kEffectRangeViewTag];
            [self p_updateToolEffectRangeView:EffectRangeView];
            found = YES;
        } else {
            obj.alpha = 0.0;
        }
    }];
    if (!found || !selected) {
        // 当前没有活跃的tab || 没有被选中的特效
        self.isShowingToolEffectRangeView = NO;
        [self p_updateToolEffectRangeView:nil];
    }
}

- (void)updateShowingTimeEffectRangeViewIfNeededWithType:(HTSPlayerTimeMachineType)type {
    __block BOOL found = NO;
    [self.timeFragmentsContainers enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, UIView * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([key isEqualToString:@"time"]) { // 在字典中找到当前所处的tab
            if (type == HTSPlayerTimeMachineTimeTrap || type == HTSPlayerTimeMachineRelativity) {
                self.isShowingTimeEffectRangeView = YES;
                obj.alpha = 1.0;
                found = YES;
            } else {
                self.isShowingTimeEffectRangeView = NO;
                obj.alpha = 0.0;
            }
            UIView *EffectRangeView = [obj viewWithTag:kEffectRangeViewTag];
            [self p_updateTimeEffectRangeView:EffectRangeView];
        } else {
            obj.alpha = 0.0;
        }
    }];
    if (!found) {
        // 当前没有活跃的tab || 没有被选中的特效
        self.isShowingTimeEffectRangeView = NO;
        [self p_updateTimeEffectRangeView:nil];
    }
}

-(void)setUpTimeEffectRangeViewAlpha:(CGFloat)alpha {
    if (self.timeEffectRangeView) {
        self.timeEffectRangeView.alpha = alpha;
    }
}

//create or refresh Time EffectRangeView
- (void)refreshTimeEffectRangeViewWithRange:(IESMMEffectTimeRange *)timeEffectRange totalDuration:(CGFloat)totalDuration
{
    if (totalDuration <= 0.00000001) {
        return;
    }
    
    // create a fake category name
    NSString *category = @"time";
    
    // Container
    UIView *timeFragmentsContainer = [self.timeFragmentsContainers objectForKey:category];
    if (!timeFragmentsContainer) {
        timeFragmentsContainer = [UIView new];
        timeFragmentsContainer.frame = self.bounds;
        timeFragmentsContainer.backgroundColor = [UIColor clearColor];
        [self.timeFragmentsContainers setObject:timeFragmentsContainer forKey:category];
        [self insertSubview:timeFragmentsContainer belowSubview:self.playProgressControl];
    }
    
    // Effect fragment
    NSObject<AWEVideoEffectRangeProtocol> *timeEffectRangeView = self.timeEffectRangeViewMap[timeEffectRange];
    if (!timeEffectRangeView) {
        if (![timeFragmentsContainer isKindOfClass:AWETopBlendingView.class]) {
            AWEVideoEffectScalableRangeView *rangeView = [[AWEVideoEffectScalableRangeView alloc] init];
            timeEffectRangeView = rangeView;
            rangeView.useEnhancedHandle = YES;
            [rangeView setEffectColor:ACCResourceColor(ACCColorPrimary)];
            rangeView.leftBoundary = -KScalableRangeViewPadding; // rangeView最左端的padding
            rangeView.rightBoundary = CGRectGetWidth(self.bounds) + KScalableRangeViewPadding; // rangeView最右端的距离
            rangeView.minLength = MAX(CGRectGetWidth(self.bounds) * 1/totalDuration, 1.0f) + 2 * KScalableRangeViewPadding;;
            rangeView.containerSize = CGSizeMake(self.bounds.size.width, [AWEVideoEffectMixTimeBar timeBarHeight]);
            rangeView.tag = kEffectRangeViewTag;
            rangeView.delegate = self;
            [timeFragmentsContainer addSubview:rangeView];
        } else {
            AWETopBlendingView *topBlendingView = (AWETopBlendingView *)timeFragmentsContainer;
            // 获取特效的颜色
            NSString *effectId = timeEffectRange.effectPathId;
            if (timeEffectRange.effectType  != IESEffectFilterNone) {
                if ([self.delegate respondsToSelector:@selector(effectIdWithEffectType:)]) {
                    effectId = [self.delegate effectIdWithEffectType:timeEffectRange.effectType];
                }
            }
            UIColor *effectColor = [self.delegate effectColorWithEffectId:effectId];
            
            CGFloat fromPosition = MAX(0.0, timeEffectRange.startTime / totalDuration);
            CGFloat toPosition = MIN(1.0, timeEffectRange.endTime / totalDuration);
            AWETopBlendingViewItem *item = [[AWETopBlendingViewItem alloc] initWithColor:effectColor
                                                                            fromPosition:fromPosition
                                                                               toPostion:toPosition];
            timeEffectRangeView = item;
            [topBlendingView addItem:item];
        }
        self.timeEffectRangeViewMap[timeEffectRange] = timeEffectRangeView;
    }
   
    if ([timeEffectRangeView isKindOfClass:AWEVideoEffectScalableRangeView.class]) {
        [self p_updateTimeEffectRangeView:(AWEVideoEffectScalableRangeView *)timeEffectRangeView];
    }
    
    CGFloat fromPosition = MAX(0.0, timeEffectRange.startTime / totalDuration);
    CGFloat toPosition = MIN(1.0, timeEffectRange.endTime / totalDuration);
    [timeEffectRangeView updateNormalizedRangeFrom:fromPosition to:toPosition];
    [timeFragmentsContainer setNeedsLayout];
}

#pragma mark - Private
- (void)p_updateTimeEffectRangeView:(UIView *)EffectRangeView {
    // 每次更新EffectRangeView，设置timeEffectRangeView的状态，因为timeEffectRangeView只有一个
    if ([EffectRangeView isKindOfClass:[AWEVideoEffectScalableRangeView class]] && self.isShowingTimeEffectRangeView) {
        self.timeEffectRangeView = (AWEVideoEffectScalableRangeView *)EffectRangeView;
    } else if (!self.isShowingTimeEffectRangeView) {
        self.timeEffectRangeView = nil;
    }
}

- (void)p_updateToolEffectRangeView:(UIView *)EffectRangeView {
    // 每次更新EffectRangeView，设置toolEffectRangeView的状态，因为toolEffectRangeView只有一个
    if ([EffectRangeView isKindOfClass:[AWEVideoEffectScalableRangeView class]] && self.isShowingToolEffectRangeView) {
        self.toolEffectRangeView = (AWEVideoEffectScalableRangeView *)EffectRangeView;
    } else if (!self.isShowingToolEffectRangeView) {
        self.toolEffectRangeView = nil;
    }
}

#pragma mark - Frame Preview

- (void)refreshBarWithImageArray:(NSArray<UIImage *> *)imageArray
{

    CGSize size = CGSizeMake([AWEVideoEffectMixTimeBar timeBarHeight] * imageArray.count, [AWEVideoEffectMixTimeBar timeBarHeight]);
    CGFloat scale = [UIScreen mainScreen].scale;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, scale);
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, size.height);
    CGContextConcatCTM(currentContext, flipVertical);
    
    CGContextSaveGState(currentContext);
    
    CGRect clippedRect = CGRectMake(0, 0, size.width, size.height);
    CGContextClipToRect( currentContext, clippedRect);
    
    CGFloat height = imageArray.firstObject.size.height / scale;
    
    [imageArray enumerateObjectsUsingBlock:^(UIImage * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CGRect drawRect = CGRectMake([AWEVideoEffectMixTimeBar timeBarHeight] * idx,
                                     - (height - [AWEVideoEffectMixTimeBar timeBarHeight]) /2.0,
                                     [AWEVideoEffectMixTimeBar timeBarHeight],
                                     height);
        CGContextDrawImage(currentContext, drawRect, obj.CGImage);
    }];
    
    CGPathRef path = CGPathCreateWithRect(self.bounds, NULL);
    CGContextSetLineWidth(currentContext, 1.0);
    CGContextSetStrokeColorWithColor(currentContext, ACCUIColorFromRGBA(0xffffff, 0.5).CGColor);
    CGContextAddPath(currentContext, path);
    CGContextDrawPath(currentContext,kCGPathStroke);
    
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    CGPathRelease(path);
    
    UIGraphicsEndImageContext();
    if (resultImage) {
        acc_dispatch_main_async_safe(^{
            self.backgroundColor = [UIColor colorWithPatternImage:resultImage];
        });
    }
}

#pragma mark - Effect Fragment

- (void)refreshBarWithEffectArray:(NSArray<IESMMEffectTimeRange*> *)effectArray
                    totalDuration:(CGFloat)totalDuration
{
    NSDictionary<IESMMEffectTimeRange *, NSObject<AWEVideoEffectRangeProtocol> *> *effectRangeViewMapCopy = [self.effectRangeViewMap copy];
    [effectRangeViewMapCopy enumerateKeysAndObjectsUsingBlock:^(IESMMEffectTimeRange * _Nonnull key, NSObject<AWEVideoEffectRangeProtocol> * _Nonnull obj, BOOL * _Nonnull stop) {
        if (key != self.currentEffectTimeRange) {
            if (![effectArray containsObject:key]) {
                [obj removeFromContainer];
                if (@available(iOS 9.0, *)) {
                    [self.effectRangeViewMap removeObjectForKey:key];
                } else { // avoid to release current effectRangeView immediately in iOS8 which leads to EXC_BAD_ACCESS crash on following system UIEvent handling
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.effectRangeViewMap removeObjectForKey:key];
                    });
                }
            }
        }
    }];
    
    [effectArray enumerateObjectsUsingBlock:^(IESMMEffectTimeRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self refreshEffectRangeViewWithRange:obj totalDuration:totalDuration];
    }];
}

- (void)refreshEffectRangeViewWithRange:(IESMMEffectTimeRange *)effectRange totalDuration:(CGFloat)totalDuration
{
    if (totalDuration <= 0.00000001) {
        return;
    }
    
    // 特效所属分类
    NSString *category = [self.delegate effectCategoryWithEffectId:effectRange.effectPathId];
    if (!category) {
        return;
    }
    
    // Container
    UIView *fragmentsContainer = [self.fragmentsContainers objectForKey:category];
    if (!fragmentsContainer) {
        fragmentsContainer = [category isEqualToString:@"sticker"] ? [UIView new] : [AWETopBlendingView new];
        fragmentsContainer.frame = self.bounds;
        fragmentsContainer.backgroundColor = [UIColor clearColor];
        [self.fragmentsContainers setObject:fragmentsContainer forKey:category];
        [self insertSubview:fragmentsContainer belowSubview:self.playProgressControl];
    }
    
    // Effect fragment
    NSObject<AWEVideoEffectRangeProtocol> *effectRangeView = self.effectRangeViewMap[effectRange];
    if (!effectRangeView) {
        if (![fragmentsContainer isKindOfClass:AWETopBlendingView.class]) {
            AWEVideoEffectScalableRangeView *rangeView = [AWEVideoEffectScalableRangeView new];
            effectRangeView = rangeView;
            rangeView.useEnhancedHandle = YES;
            [rangeView setEffectColor:ACCResourceColor(ACCColorPrimary)];
            rangeView.leftBoundary = -KScalableRangeViewPadding; // rangeView最左端的padding
            rangeView.rightBoundary = CGRectGetWidth(self.bounds) + KScalableRangeViewPadding; // rangeView最右端的距离
            rangeView.minLength = MAX(CGRectGetWidth(self.bounds) * 1/totalDuration, 1.0f) + 2 * KScalableRangeViewPadding;
            rangeView.containerSize = CGSizeMake(self.bounds.size.width, [AWEVideoEffectMixTimeBar timeBarHeight]);
            rangeView.tag = kEffectRangeViewTag;
            rangeView.delegate = self;
            [fragmentsContainer addSubview:rangeView];
        } else {
            AWETopBlendingView *topBlendingView = (AWETopBlendingView *)fragmentsContainer;
            // 获取特效的颜色
            NSString *effectId = effectRange.effectPathId;
            if (effectRange.effectType  != IESEffectFilterNone) {
                if ([self.delegate respondsToSelector:@selector(effectIdWithEffectType:)]) {
                    effectId = [self.delegate effectIdWithEffectType:effectRange.effectType];
                }
            }
            UIColor *effectColor = [self.delegate effectColorWithEffectId:effectId];
            
            CGFloat fromPosition = MAX(0.0, effectRange.startTime / totalDuration);
            CGFloat toPosition = MIN(1.0, effectRange.endTime / totalDuration);
            AWETopBlendingViewItem *item = [[AWETopBlendingViewItem alloc] initWithColor:effectColor
                                                                            fromPosition:fromPosition
                                                                               toPostion:toPosition];
            effectRangeView = item;
            [topBlendingView addItem:item];
        }
        self.effectRangeViewMap[effectRange] = effectRangeView;
    }
    if ([effectRangeView isKindOfClass:AWEVideoEffectScalableRangeView.class]) {
        [self p_updateToolEffectRangeView:(AWEVideoEffectScalableRangeView *)effectRangeView];
    }
    
    CGFloat fromPosition = MAX(0.0, effectRange.startTime / totalDuration);
    CGFloat toPosition = MIN(1.0, effectRange.endTime / totalDuration);
    [effectRangeView updateNormalizedRangeFrom:fromPosition to:toPosition];
    [fragmentsContainer setNeedsLayout];
}

#pragma mark - AWEVideoEffectScalableRangeViewDelegate

- (CGFloat)rangeViewFrame:(CGRect)rangeViewFrame couldChangeFrameWithType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType
{
    const CGFloat totalWidth = self.bounds.size.width;
    if (totalWidth > 0) {
        // 注意因为scalableRangeView有额外的padding，from需要由origin再加入padding去补偿
        const CGFloat from = (rangeViewFrame.origin.x + KScalableRangeViewPadding) / totalWidth;
        // 注意因为scalableRangeView有额外的padding，to需要由width再减右padding去补偿
        const CGFloat to = (rangeViewFrame.origin.x + rangeViewFrame.size.width - KScalableRangeViewPadding) / totalWidth;
        
        const CGFloat proportion = rangeViewFrame.size.width/totalWidth;
        
        if ([self.delegate respondsToSelector:@selector(userCouldChangeRangeViewEffectRange:rangeTo:proportion:changeType:inTimeEffectView:)]) {
            CGFloat maxLength = [self.delegate userCouldChangeRangeViewEffectRange:from rangeTo:to proportion:proportion changeType:changeType inTimeEffectView:self.isShowingTimeEffectRangeView];
            if (maxLength > 0) {
                return maxLength * totalWidth + 2 * KScalableRangeViewPadding;
            }
        }
    }
    return -1;
}

// 用户修改AWEVideoEffectScalableRangeView的区间开始的回调
- (void)rangeView:(AWEVideoEffectScalableRangeView *)rangeView willChangeFrameWithType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType
{
    if ([self.delegate respondsToSelector:@selector(userWillChangeRangeViewEffectRangeInTimeEffectView:)]) {
        [self.delegate userWillChangeRangeViewEffectRangeInTimeEffectView:self.isShowingTimeEffectRangeView];
    }
}

// 用户修改AWEVideoEffectScalableRangeView的区间中的回调
- (void)rangeView:(AWEVideoEffectScalableRangeView *)rangeView didChangeFrameWithType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType
{
    const CGFloat totalWidth = self.bounds.size.width;
    if (totalWidth > 0) {
        const CGRect frame = rangeView.frame;
        // 注意因为scalableRangeView有额外的padding，from需要由origin再加入padding去补偿
        const CGFloat from = (frame.origin.x + KScalableRangeViewPadding) / totalWidth;
        // 注意因为scalableRangeView有额外的padding，to需要由width再减右padding去补偿
        const CGFloat to = (frame.origin.x + frame.size.width - KScalableRangeViewPadding) / totalWidth;
        
        const CGFloat proportion = (rangeView.frame.size.width - 2 * KScalableRangeViewPadding)/totalWidth;
        
        if ([self.delegate respondsToSelector:@selector(userDidChangeRangeViewEffectRange:rangeTo:proportion:changeType:inTimeEffectView:)]) {
            [self.delegate userDidChangeRangeViewEffectRange:from rangeTo:to proportion:proportion changeType:changeType inTimeEffectView:self.isShowingTimeEffectRangeView];
        }
    }
}

// 用户修改AWEVideoEffectScalableRangeView的区间完成后回调，区间调整分三种：头部改变，整体拖动，尾巴改变
- (void)rangeView:(AWEVideoEffectScalableRangeView *)rangeView didFinishChangeFrameWithType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType
{
    const CGFloat totalWidth = self.bounds.size.width;
    if (totalWidth > 0) {
        const CGRect frame = rangeView.frame;
        // 注意因为scalableRangeView有额外的padding，from需要由origin再加入padding去补偿
        const CGFloat from = (frame.origin.x + KScalableRangeViewPadding) / totalWidth;
        // 注意因为toolEffectRangeView有额外的padding，to需要由width再减右padding去补偿
        const CGFloat to = (frame.origin.x + frame.size.width - KScalableRangeViewPadding) / totalWidth;
        if ([self.delegate respondsToSelector:@selector(userDidFinishChangeRangeViewEffectRange:rangeTo:changeType:inTimeEffectView:)]) {
            [self.delegate userDidFinishChangeRangeViewEffectRange:from rangeTo:to changeType:changeType inTimeEffectView:self.isShowingTimeEffectRangeView];
        }
    }
}

#pragma mark - Control Location

- (CGFloat)getLocationWithTime:(CGFloat)time totalDuration:(CGFloat)totalDuration
{
    if (time <= 0 || totalDuration <= 0) {
        return 0;
    }
    
    CGFloat width = CGRectGetWidth(self.bounds);
    
    if (width == 0) {
        width = CGRectGetWidth([UIScreen mainScreen].bounds);
    }
    
    return width * MAX(0, MIN(1, (time / totalDuration)));
}

- (void)updateView:(UIView *)view toLocation:(CGFloat)location
{
    CGRect frame = view.frame;
    frame.origin.x = location;
    view.frame = frame;
}

- (void)updatePlayProgressWithTime:(CGFloat)time totalDuration:(CGFloat)totalDuration
{
    if (self.movingView == self.playProgressControl) {
        return;
    }
    
    if (self.currentEffectTimeRange) {
        self.currentEffectTimeRange.endTime = time;
        if (self.currentEffectTimeRange.endTime >= self.currentEffectTimeRange.startTime) {
            [self refreshEffectRangeViewWithRange:self.currentEffectTimeRange totalDuration:totalDuration];
        }
    }

    
    CGFloat location = [self getLocationWithTime:time totalDuration:totalDuration];
    
    [self updateView:self.playProgressControl toLocation:location - kPlayerControlWidth/2.0];
}

- (void)updateSelectTime:(CGFloat)time totalDuration:(CGFloat)totalDuration
{
    if (self.movingView == self.timeSelectControl) {
        return;
    }
    
    CGFloat location = [self getLocationWithTime:time totalDuration:totalDuration];
    [self updateView:self.timeSelectControl toLocation:location - kPlayerControlWidth/2.0];
}

#pragma mark - Touches

- (double)getMovingViewProgress
{
    double progress = self.movingView.center.x / CGRectGetWidth(self.bounds);
    
    return progress;
}

- (CGFloat)getPlayControlViewProgress
{
    double progress = self.playProgressControl.center.x / CGRectGetWidth(self.bounds);
    return progress;
}

- (void)sendControlDidMoveAction
{
    if ([self.delegate respondsToSelector:@selector(userDidMoveTimeBarControl:progress:)]) {
        
        [self.delegate userDidMoveTimeBarControl:self.movingView
                                        progress:[self getMovingViewProgress]];
    }
}

- (void)userDidMoveControl
{
    [self sendControlDidMoveAction];
    
    if ([self.delegate respondsToSelector:@selector(userDidFinishMoveTimeBarControl:progress:)]) {
        [self.delegate userDidFinishMoveTimeBarControl:self.movingView
                                              progress:[self getMovingViewProgress]];
    }
    
    self.movingView.selected = NO;
    self.movingView = nil;
    self.willMovingView = nil;
}

- (void)updateMovingControlWithTouches:(NSSet<UITouch *> *)touches
{
    double offset = [touches.anyObject locationInView:self].x - self.touchBeganPoint.x;
    double left = self.originalPoint.x + offset;
    double centerX = left + kPlayerControlWidth/2.0;
    
    if (centerX < 0) {
        left = left + (0 - centerX);
    }
    CGFloat width = CGRectGetWidth(self.bounds);
    if (centerX > width) {
        left = width - kPlayerControlWidth/2.0;
    }
    [self updateView:self.movingView toLocation:left];
    
    [self sendControlDidMoveAction];
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect touchArea = CGRectInset(self.bounds, -18, -18);
    
    if (CGRectContainsPoint(touchArea, point)) {
        double progressDiff  = ABS(point.x - self.playProgressControl.center.x);
        double selectDiff  = ABS(point.x - self.timeSelectControl.center.x);
        double touchDiff = 44;
        
        if (progressDiff < touchDiff) {
            if (self.playProgressControl.canMove) {
                self.willMovingView = self.playProgressControl;
            }
        }
        
        if (selectDiff < touchDiff && self.timeSelectControl.canMove) {
            if (self.willMovingView) {
                if (selectDiff < progressDiff) {
                    self.willMovingView = self.timeSelectControl;
                }
            } else {
                self.willMovingView = self.timeSelectControl;
            }
        }
        
        if (self.willMovingView) {
            return self;
        }
        if (self.isShowingToolEffectRangeView) {
            // 如果是展示了道具特效view，则返回道具特效view去处理,这是因为特效view可能落在timebar之外
            return self.toolEffectRangeView;
        }
        if (self.isShowingTimeEffectRangeView) {
            return self.timeEffectRangeView;
        }
    }
    
    return [super hitTest:point withEvent:event];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    if (self.willMovingView) {
        self.movingView = self.willMovingView;
        self.touchBeganPoint = [touches.anyObject locationInView:self];
        self.originalPoint = self.movingView.frame.origin;
        self.movingView.selected = YES;
        if ([self.delegate respondsToSelector:@selector(userWillMoveTimeBarControl:progress:)]) {
            [self.delegate userWillMoveTimeBarControl:self.movingView progress:0];
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    if (self.movingView) {
        [self updateMovingControlWithTouches:touches];
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    if (self.movingView) {
        [self updateMovingControlWithTouches:touches];
        [self userDidMoveControl];
    }
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    if (self.movingView) {
        [self updateMovingControlWithTouches:touches];
        [self userDidMoveControl];
    }
}

#pragma mark -

- (void)setUpPlayProgressControlTintColor:(BOOL)isToolEffect
{
    if (isToolEffect) {
        UIImage *image = ACCResourceImage(@"buteffecttimepoint");
        image = [image acc_ImageWithTintColor:[UIColor whiteColor]];
        [self.playProgressControl setImage:image];
    } else {
        UIImage *image = ACCResourceImage(@"buteffecttimepoint");
        image = [image acc_ImageWithTintColor:[UIColor whiteColor]];
        [self.playProgressControl setImage:image];
    }
}

#pragma mark - Getter & Setter

- (AWEVideoPlayControl *)playProgressControl
{
    if (!_playProgressControl) {
        _playProgressControl = [[AWEVideoProgressControl alloc] init];
        _playProgressControl.frame = CGRectMake(0, ([AWEVideoEffectMixTimeBar timeBarHeight] - kPlayerControlWidth)/2.0, kPlayerControlWidth, kPlayerControlWidth);
        UIImage *image = ACCResourceImage(@"buteffecttimepoint");

        [_playProgressControl setImage:image];
        _playProgressControl.isAccessibilityElement = YES;
    }
    return _playProgressControl;
}

- (AWETimeSelectControl *)timeSelectControl
{
    if (!_timeSelectControl) {
        _timeSelectControl = [AWETimeSelectControl new];
        _timeSelectControl.frame = CGRectMake(0, ([AWEVideoEffectMixTimeBar timeBarHeight] - kPlayerControlWidth)/2.0, kPlayerControlWidth, kPlayerControlWidth);
        [_timeSelectControl setImageWithName:@"iconEffectRepeat"];
    }
    return _timeSelectControl;
}

- (UIView *)timeReverseMask
{
    if (!_timeReverseMask) {
        _timeReverseMask = [UIView new];
        _timeReverseMask.frame = self.bounds;
    }
    return _timeReverseMask;
}

- (NSMutableDictionary<NSString *, UIView *> *)fragmentsContainers {
    if (!_fragmentsContainers) {
        _fragmentsContainers = [[NSMutableDictionary alloc] init];
    }
    return _fragmentsContainers;
}

- (NSMutableDictionary<NSString *, UIView *> *)timeFragmentsContainers {
    if (!_timeFragmentsContainers) {
        _timeFragmentsContainers = [[NSMutableDictionary alloc] init];
    }
    return _timeFragmentsContainers;
}

+ (CGFloat)timeBarHeight
{
    return 36;
}
@end
