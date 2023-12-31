//
//  CJPayMemCreateBizOrderResponse.h
//  Pods
//
//  Created by wangxiaohong on 2020/10/13.
//

#import "CJPayBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignCardMap;
@class CJPayBizAuthInfoModel;
@class CJPayUserInfo;
@class CJPayBindPageInfoResponse;
@class CJPayBindCardSharedDataModel;
@class CJPayBindCardRetainInfo;
@interface CJPayMemCreateBizOrderResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *memberBizUrl;
@property (nonatomic, copy) NSString *memberBizOrderNo;
@property (nonatomic, strong) CJPaySignCardMap *signCardMap;
@property (nonatomic, strong) CJPayBindCardRetainInfo *retainInfoModel;

@property (nonatomic ,strong) CJPayBizAuthInfoModel *bizAuthInfoModel;
@property (nonatomic ,strong) CJPayBindPageInfoResponse *bindPageInfoResponse;
- (CJPayUserInfo *)generateUserInfo;
- (NSString *)protocolDescription;
- (NSString *)buttonDescription;
- (CJPayBindCardSharedDataModel *)buildCommonModel;
@end

NS_ASSUME_NONNULL_END
