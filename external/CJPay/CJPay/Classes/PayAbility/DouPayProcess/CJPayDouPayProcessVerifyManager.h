//
//  CJPayDouPayProcessVerifyManager.h
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/5/31.
//

#import "CJPayBaseVerifyManager.h"
#import "CJPayBindCardSharedDataModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDouPayProcessVerifyManager : CJPayBaseVerifyManager

@property (nonatomic, copy) NSDictionary *extParams;
@property (nonatomic, assign) CJPayLynxBindCardBizScence lynxBindCardBizScence;

// 返回给电商的性能统计，时间戳
- (NSDictionary *)getPerformanceInfo;

@end

NS_ASSUME_NONNULL_END
