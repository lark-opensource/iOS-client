//
//  TMAVideoRateSelectionView.h
//  OPPluginBiz
//
//  Created by zhujingcheng on 2/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TMAVideoGradientView : UIView

- (CAGradientLayer *)gradientLayer;

@end

@interface TMAVideoRateSelectionView : TMAVideoGradientView

@property (nonatomic, copy) void(^tapAction)(CGFloat rate);

- (instancetype)initWithSelections:(NSArray<NSNumber *> *)selections currentSelection:(nullable NSNumber *)currentSelection;

- (CGRect)untouchableArea;

@end


NS_ASSUME_NONNULL_END
