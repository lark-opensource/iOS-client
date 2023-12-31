//
//  AWECircularProgressView.h
//  Pods
//
//  Created by jindulys on 2019/5/13.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWECircularProgressView : UIView

// Progress
@property (nonatomic, assign) CGFloat progress;

// Colour of Progress Bar
@property (nonatomic, strong) UIColor *progressTintColor;

// Background colour of the Progress bar
@property (nonatomic, strong) UIColor *progressBackgroundColor;

// Line width
@property (nonatomic, assign) CGFloat lineWidth;

// Wide background
@property (nonatomic, assign) CGFloat backgroundWidth;

// Progress bar radius
@property (nonatomic, assign) CGFloat progressRadius;
// Background radius
@property (nonatomic, assign) CGFloat backgroundRadius;
@end

NS_ASSUME_NONNULL_END
