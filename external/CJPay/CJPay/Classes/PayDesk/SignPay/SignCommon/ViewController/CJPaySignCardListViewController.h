//
//  CJPaySignCardListViewController.h
//  Pods
//
//  Created by wangxiaohong on 2022/9/8.
//

#import "CJPayHalfPageBaseViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignQueryMemberPayListResponse;
@class CJPayDefaultChannelShowConfig;
@interface CJPaySignCardListViewController : CJPayHalfPageBaseViewController

@property (nonatomic, strong) CJPaySignQueryMemberPayListResponse *listResponse;
@property (nonatomic, copy) NSString *payTypeListUrl;
@property (nonatomic, copy) NSDictionary *requestParams;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *defaultShowConfig;
@property (nonatomic, copy) NSDictionary *trackParams;
@property (nonatomic, assign) BOOL isSignOnly; //区分是签约并支付流程拉起还是独立签约流程拉起，用于埋点
@property (nonatomic, copy) NSString *zgAppId;
@property (nonatomic, copy) NSString *zgMerchantId;

@property (nonatomic, copy) void(^didClickMethodBlock)(CJPayDefaultChannelShowConfig *showConfig);

@end

NS_ASSUME_NONNULL_END
