//
//  AWEVideoEffectRangeView.h
//  Pods
//
//  Created by zhangchengtao on 2019/3/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol AWEVideoEffectRangeProtocol <NSObject>
- (void)updateNormalizedRangeFrom:(CGFloat)start to:(CGFloat)end;
- (void)removeFromContainer;
@end

typedef NS_ENUM(NSInteger, AWEVideoEffectScalableRangeViewFrameChangeType) {
    AWEVideoEffectScalableRangeViewFrameChangeTypeHead = 0, // head
    AWEVideoEffectScalableRangeViewFrameChangeTypeBody = 1, // body
    AWEVideoEffectScalableRangeViewFrameChangeTypeTail = 2, // tail
};

@protocol AWEVideoEffectScalableRangeViewDelegate;

// 可升缩特效区间视图（道具类型特效的人脸识别的区间可以拖动和改变长度）
@interface AWEVideoEffectScalableRangeView : UIView <AWEVideoEffectRangeProtocol>

@property (nonatomic, weak) id<AWEVideoEffectScalableRangeViewDelegate> delegate;

@property (nonatomic, strong) UIColor *effectColor;

@property (nonatomic, assign) BOOL useEnhancedHandle;

@property (nonatomic) CGFloat leftBoundary;

@property (nonatomic) CGFloat rightBoundary;

@property (nonatomic) CGFloat minLength;

@property (nonatomic, assign) CGSize containerSize;

- (instancetype)initWithFrame:(CGRect)frame panTouchPositionProhibits:(NSArray *)panTouchPositionProhibits;

- (void)updateNormalizedRangeFrom:(CGFloat)start to:(CGFloat)end;
- (void)removeFromContainer;

@end

@protocol AWEVideoEffectScalableRangeViewDelegate <NSObject>

@optional

- (CGFloat)rangeViewFrame:(CGRect)rangeViewFrame couldChangeFrameWithType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType;

- (void)rangeView:(AWEVideoEffectScalableRangeView *)rangeView willChangeFrameWithType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType;

- (void)rangeView:(AWEVideoEffectScalableRangeView *)rangeView didChangeFrameWithType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType;

- (void)rangeView:(AWEVideoEffectScalableRangeView *)rangeView didFinishChangeFrameWithType:(AWEVideoEffectScalableRangeViewFrameChangeType)changeType;

@end

NS_ASSUME_NONNULL_END
