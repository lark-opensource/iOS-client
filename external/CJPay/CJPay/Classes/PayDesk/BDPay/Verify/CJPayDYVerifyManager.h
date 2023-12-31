//
//  CJPayDYVerifyManager.h
//  Pods
//
//  Created by wangxiaohong on 2020/2/19.
//

#import "CJPayBaseVerifyManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDYVerifyManager : CJPayBaseVerifyManager

@property (nonatomic, assign) BOOL isPayAgainRecommend; //是否是推荐二次支付验证流程

@end

NS_ASSUME_NONNULL_END
