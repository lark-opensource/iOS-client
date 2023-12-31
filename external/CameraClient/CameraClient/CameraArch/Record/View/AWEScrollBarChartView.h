//
//  AWEScrollBarChartView.h
//  Pods
//
//  Created by jindulys on 2019/5/21.
//

#import <UIKit/UIKit.h>

#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

@interface AWEScrollBarChartView : UIView

/**
 *  可选的最大长度，默认15s
 */
@property (nonatomic, assign) CGFloat maxLength;

/**
 *  当前音乐的长度，例如：95s
 */
@property (nonatomic, assign) CGFloat currentLength;

/**
 *  当前选中的音乐范围，range.length一般为maxLength，当currentLength < maxLength时为currentLength
 */
@property (nonatomic, readonly) HTSAudioRange range;

@property (nonatomic, assign) CGFloat barWidth;
@property (nonatomic, assign) CGFloat space;
@property (nonatomic, strong) UIColor *drawColor;
@property (nonatomic, strong) UIColor *barDefaultColor;
@property (nonatomic, assign) CGFloat maxBarHeight;
@property (nonatomic, assign) CGFloat minBarHeight;

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) CALayer *cavasLayer;
@property (nonatomic, strong) CALayer *progressLayer;
@property (nonatomic, strong) CAShapeLayer *progressMaskLayer;


/**
 *  用于制作动画，表示音乐播放进度
 */
@property (nonatomic, assign) CGFloat time;

- (void)updateBarWithHeights:(NSArray<NSNumber *> *)heights;

- (void)addBarAtIndex:(int)i height:(CGFloat)height color:(UIColor *)color toLayer:(CALayer *)toLayer;

- (CGFloat)barCountForFullWidth;

- (void)setRangeStart:(CGFloat)location;

@end
