//
//  OPVideoControlSlider.h
//  OPPluginBiz
//
//  Created by zhujingcheng on 2/12/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class OPVideoControlSlider;

@protocol OPVideoControlSliderDelegate <NSObject>

- (void)videoSliderTouchBegan:(CGFloat)value;
- (void)videoSliderValueChanged:(CGFloat)value;
- (void)videoSliderTouchEnded:(CGFloat)value;
- (void)videoSliderSingleTapGestureRecognized:(UITapGestureRecognizer *)recognizer;

@end

@interface OPVideoControlSlider : UIView

@property (nonatomic, weak) id<OPVideoControlSliderDelegate> delegate;

- (void)showDraggingTime:(NSString *)time;
- (void)hideDraggingTime;
- (void)updateBufferingProgress:(CGFloat)bufferingProgress;
- (void)highlightSlider:(BOOL)highlight;
- (void)updateCurrentValue:(CGFloat)value;
- (CGFloat)currentValue;
- (void)reset;

@end

NS_ASSUME_NONNULL_END
