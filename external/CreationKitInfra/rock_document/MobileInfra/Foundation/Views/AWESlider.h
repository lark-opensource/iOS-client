//
//  AWESlider.h
//  AWEStudio
//
// Created by Hao Yipeng on July 24, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import <UIKit/UIKit.h>
@class AWESlider;

// _______________________________________________________________________________________________________________

@protocol AWESliderDelegate<NSObject>

@optional
/**
 This method will be called when the value of the slider changes

 @param slider The instance of AWESlider whose value has changed
 @param value The value after the change
 */
- (void)slider:(AWESlider *)slider valueDidChanged:(float)value;


/**
 This method will be called when the slider ends sliding

 @param slider The AWESlider instance whose value has changed
 @param value The value of the final slider
 */
- (void)slider:(AWESlider *)slider didFinishSlidingWithValue:(float)value;
@end

// _______________________________________________________________________________________________________________

@interface AWESlider : UISlider

@property (nonatomic, weak) id<AWESliderDelegate> delegate;
@property (nonatomic, strong, readonly) UILabel *indicatorLabel;
@property (nonatomic, assign) CGFloat indicatorLabelBotttomMargin;
@property (nonatomic, assign) BOOL showIndicatorLabel;       // The default value is no, which is used to control whether the number is displayed or not
//@property (nonatomic, copy) NSString *formatString;          //  The formatted string is used to display on the slider. The default value is the rounded value
@property (nonatomic, copy) NSString *(^valueDisplayBlock)(void); // The formatted string is used to display on the slider. The default value is the rounded value
@property (nonatomic, strong) UIColor *indicatorLabelTextColor;

// For subclassing
- (void)handleValueChanged;
@end
