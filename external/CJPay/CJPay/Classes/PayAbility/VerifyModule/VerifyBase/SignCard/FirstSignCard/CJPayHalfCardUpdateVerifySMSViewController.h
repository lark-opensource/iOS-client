//
//  CJPayHalfCardUpdateVerifySMSViewController.h
//  Pods
//
//  Created by wangxiaohong on 2020/4/12.
//

#import "CJPayHalfVerifySMSViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPaySignSMSResponse;
@class CJPayCardUpdateModel;
@class CJPaySendSMSResponse;
typedef void(^CJPayCardSignSuccessCompletion)(CJPaySignSMSResponse *response);

@interface CJPayHalfCardUpdateVerifySMSViewController : CJPayHalfVerifySMSViewController

@property (nonatomic, strong) CJPayCardUpdateModel *cardUpdateModel;
@property (nonatomic, strong) CJPaySendSMSResponse *sendSMSResponse;
@property (nonatomic, copy) NSDictionary *ulBaseReqquestParam;
@property (nonatomic, copy) NSDictionary *sendSMSBizParam;
@property (nonatomic, copy) CJPayCardSignSuccessCompletion cardSignSuccessCompletion;

@end

NS_ASSUME_NONNULL_END
