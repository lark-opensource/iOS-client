//
//  UIViewController+CJTransition.h
//  CJPay
//
//  Created by 王新华 on 11/17/19.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CJTransitionDirection) {
    CJTransitionDirectionNone,
    CJTransitionDirectionFromBottom,
    CJTransitionDirectionFromRight,
};

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController(CJTransition)

@property (nonatomic, assign) BOOL cjAllowTransition;
@property (nonatomic, assign) CJTransitionDirection cjTransitionDirection;
@property (nonatomic, assign) BOOL cjTransitionNeedShowMask;

// 控制接管转场以后是不是真正需要动画
@property (nonatomic, assign) BOOL cjNeedAnimation;
// 控制需不需要漏出下边的view
@property (nonatomic, assign) BOOL cjShouldShowBottomView;
@property (nonatomic, copy) NSString *cjVCIdentify;

@end

NS_ASSUME_NONNULL_END
