//
//  CJPayBindCardFetchUrlResponse.h
//  Pods
//
//  Created by youerwei on 2022/4/25.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignCardMap;
@class CJPayBizAuthInfoModel;
@class CJPayBindPageInfoResponse;
@interface CJPayBindCardFetchUrlResponse : CJPayBaseResponse

@property (nonatomic, strong) CJPaySignCardMap *signCardMap;
@property (nonatomic, strong) CJPayBizAuthInfoModel *bizAuthInfoModel;
@property (nonatomic ,strong) CJPayBindPageInfoResponse *bindPageInfoResponse;
// 绑卡结果页url
@property (nonatomic, copy) NSString *endPageUrl;

@end

NS_ASSUME_NONNULL_END
