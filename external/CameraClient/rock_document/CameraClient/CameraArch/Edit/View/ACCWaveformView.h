//
//  ACCWaveformView.h
//  Pods
//
//  Created by Shen Chen on 2020/7/6.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCWaveformView : UIView
@property (nonatomic, strong, readonly) NSMutableArray<CALayer *> *barLayers;
@property (nonatomic, strong) UIColor *defaultColor;
- (NSInteger)barCountForWidth:(CGFloat)width;
- (NSInteger)indexOfSucceedingBarWithPosition:(CGFloat)position;
- (void)updateWithAmplitudes:(NSArray<NSNumber *> *)amplitudes;
- (void)setBarColor:(UIColor *)color atIndex:(NSInteger)index;
- (UIColor *)defaultColor;
@end

NS_ASSUME_NONNULL_END
