//
//  BDXLynxSwiperView.h
//  BDXElement
//
//  Created by bill on 2020/3/20.
//

#import <UIKit/UIKit.h>
#import <Lynx/LynxUIView.h>

#import "BDXLynxSwiperPageView.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDXLynxSwiperView : UIView

- (void)setupControl;

- (void)changeStyleWithType:(BDXLynxSwiperTransformLayoutType)type;
- (void)sliderValueChangeWithType:(BDXLynxSwiperTransformLayoutType)type;
- (void)switchLayoutFrameWithType:(BDXLynxSwiperTransformLayoutType)type;

@property (nonatomic, strong) BDXLynxSwiperPageView *pagerView;

// swiper properties
@property (nonatomic, assign) BDXLynxSwiperTransformLayoutType layoutType;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) CGFloat previousMargin;
@property (nonatomic, assign) CGFloat nextMargin;
@property (nonatomic, assign) CGFloat previousMarginCompatible;
@property (nonatomic, assign) CGFloat nextMarginCompatible;
@property (nonatomic, assign) CGFloat itemWidthScale;
@property (nonatomic, assign) CGFloat itemHeightScale;
@property (nonatomic, assign) CGFloat itemHeight;
@property (nonatomic, assign) CGFloat itemWidth;
@property (nonatomic, assign) CGFloat startMargin;
@property (nonatomic, assign) CGFloat endMargin;
@property (nonatomic, assign) CGFloat maxXScale;
@property (nonatomic, assign) CGFloat minXScale;
@property (nonatomic, assign) CGFloat maxYScale;
@property (nonatomic, assign) CGFloat minYScale;
@property (nonatomic, assign) CGFloat normTranslationFactor;

@property (nonatomic, assign) BOOL showDots;
@property (nonatomic, assign) BOOL isInfiniteLoop;
@property (nonatomic, assign) BOOL isAutoPlay;
@property (nonatomic, assign) BOOL hidelabel;
@property (nonatomic, assign) BOOL isHorizonCenter;
@property (nonatomic, assign) BOOL isVerticalCenter;
@property (nonatomic, assign) BOOL isCircle; // 是否循环播放
@property (nonatomic, assign) BOOL isTouchable; // 是否监听触摸事件
@property (nonatomic, assign) BOOL smoothScroll; // 是否开启动画
@property (nonatomic, assign) BOOL bounces;
@property (nonatomic, assign) BOOL vertical;

@property (nonatomic, assign) CGFloat autoScrollInterval;
@property (nonatomic, assign) CGFloat animationDuration;

@property (nonatomic, strong) NSString *dotsColor;
@property (nonatomic, strong) NSString *activeDotsColor;
@property (nonatomic, strong) NSString *swiperMode;

@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSString *currentIndexId;

@property (nonatomic, assign) NSInteger maxMultiItems;

@property (nonatomic, strong) NSArray *datas;

@end

@interface BDXLynxUISwiper : LynxUI <BDXLynxSwiperView *>

// swiper properties
@property (nonatomic, assign) BDXLynxSwiperTransformLayoutType layoutType;
@property (nonatomic, assign) CGFloat itemSpacing;
@property (nonatomic, assign) CGFloat itemHeight;
@property (nonatomic, assign) CGFloat itemWidth;
@property (nonatomic, assign) CGFloat startMargin;
@property (nonatomic, assign) CGFloat endMargin;
@property (nonatomic, assign) CGFloat previousMargin;
@property (nonatomic, assign) CGFloat nextMargin;

@property (nonatomic, assign) CGFloat itemWidthScale;
@property (nonatomic, assign) CGFloat itemHeightScale;

@property (nonatomic, assign) BOOL showDots;
@property (nonatomic, assign) BOOL isInfiniteLoop;
@property (nonatomic, assign) BOOL isAutoPlay;
@property (nonatomic, assign) BOOL hidelabel;
@property (nonatomic, assign) BOOL isHorizonCenter;
@property (nonatomic, assign) BOOL isVerticalCenter;
@property (nonatomic, assign) BOOL isCircle; // 是否循环播放
@property (nonatomic, assign) BOOL isTouchable; // 是否监听触摸事件
@property (nonatomic, assign) BOOL smoothScroll; // 是否开启动画
@property (nonatomic, assign) BOOL bounces;
@property (nonatomic, assign) BOOL vertical;

@property (nonatomic, assign) CGFloat autoScrollInterval;
@property (nonatomic, assign) CGFloat animationDuration;

@property (nonatomic, strong) NSString *dotsColor;
@property (nonatomic, strong) NSString *activeDotsColor;
@property (nonatomic, strong) NSString *swiperMode;

@property (nonatomic, assign) NSInteger currentIndex;
@property (nonatomic, strong) NSString *currentIndexId;

@property (nonatomic, assign) NSInteger maxMultiItems;

@end
 
NS_ASSUME_NONNULL_END
