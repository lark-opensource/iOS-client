//
//  CJPayBytePayBalanceLimitView.h
//  Pods
//
//  Created by wangxiaohong on 2021/4/14.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CJPayCombinePayLimitModel;
@interface CJPayBytePayBalanceLimitView : UIView

@property (nonatomic, copy) void(^closeClickBlock)(void);
@property (nonatomic, copy) void(^confirmPayBlock)(void);

- (void)updateWithButtonModel:(CJPayCombinePayLimitModel *)model;

@end

NS_ASSUME_NONNULL_END
