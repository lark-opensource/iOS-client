//
//  BDTuringTwiceVerifyModel.h
//  BDTuring
//
//  Created by yanming.sysu on 2020/11/30.
//

#import "BDTuringVerifyModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDTuringTwiceVerifyModel : BDTuringVerifyModel

/// 经过 决策透传parameter 转换后的参数
@property (nonatomic, copy) NSDictionary *params; // 请求参数，key: kBDTuringTVecisionConfig，kBDTuringTVMobile，kBDTuringTVScene

/// 决策透传
+ (nullable instancetype)modelWithParameter:(NSDictionary *)parameter;

@end

NS_ASSUME_NONNULL_END
