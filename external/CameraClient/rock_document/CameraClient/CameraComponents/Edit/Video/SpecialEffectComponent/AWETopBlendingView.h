//
//  AWETopBlendingView.h
//  CameraClient
//
//  Created by Shen Chen on 2020/1/22.
//

#import <UIKit/UIKit.h>
#import "AWEVideoEffectRangeView.h"

NS_ASSUME_NONNULL_BEGIN

@class AWETopBlendingView;

@interface AWETopBlendingViewItem : NSObject <NSCopying, AWEVideoEffectRangeProtocol>
@property (nonatomic, assign) CGFloat from;
@property (nonatomic, assign) CGFloat to;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, assign) CGFloat zorder;
@property (nonatomic, weak) AWETopBlendingView *blendingView;
- (instancetype)initWithColor:(UIColor *)color fromPosition:(CGFloat)from toPostion:(CGFloat)to;
- (void)updateNormalizedRangeFrom:(CGFloat)start to:(CGFloat)end;
- (void)removeFromContainer;
@end


@interface AWETopBlendingView : UIView
- (void)addItem:(AWETopBlendingViewItem *)item;
- (void)removeItem:(AWETopBlendingViewItem *)item;
@end

NS_ASSUME_NONNULL_END
