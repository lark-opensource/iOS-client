//
//  DVERangeSlider.h
//  NLEEditor
//
//  Created by bytedance on 2021/6/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DVERangeSlider;

@protocol DVERangeSliderDelegate <NSObject>

- (void)slider:(DVERangeSlider *) slider leftValueChange:(CGFloat)left;
- (void)slider:(DVERangeSlider *) slider rightValueChange:(CGFloat)right;

@end

@interface DVERangeSliderBar : UIView

@end


@interface DVERangeSlider : UIView

@property (nonatomic, weak) id<DVERangeSliderDelegate> delegate;
@property (nonatomic, assign) CGFloat maxValue;

- (void)showLeftSlider;
- (void)showRightSlider;
- (void)hiddenLeftSlider;
- (void)hiddenRightSlider;

- (void)setLeftValue:(CGFloat)leftValue;
- (void)setRightValue:(CGFloat)rightValue;

@end

NS_ASSUME_NONNULL_END
