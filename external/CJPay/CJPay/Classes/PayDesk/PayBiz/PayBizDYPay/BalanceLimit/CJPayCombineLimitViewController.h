//
//  CJPayCombineLimitViewController.h
//  Pods
//
//  Created by wangxiaohong on 2021/4/15.
//

#import "CJPayPopUpBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayCombinePayLimitModel;
@interface CJPayCombineLimitViewController : CJPayPopUpBaseViewController

+ (instancetype)createWithModel:(id)model actionBlock:(void (^)(BOOL isClose))actionBlock;

@end

NS_ASSUME_NONNULL_END
