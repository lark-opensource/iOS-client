//
//  ACCPropIndicatorView.h
//  CameraClient
//
//  Created by Shen Chen on 2020/4/1.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCPropIndicatorView : UIView
@property (nonatomic, strong) UIColor *ringTintColor;
@property (nonatomic, assign) CGFloat ringBandWidth;
@property (nonatomic, strong, readonly) UIView *tipsView;
@property (nonatomic, strong) UILabel *captureLabel;

- (void)showProgress:(BOOL)show progress:(CGFloat)value;
- (void)showProgress:(BOOL)show progress:(CGFloat)value animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
