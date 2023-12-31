//
//  CJPaySignOnlyBindBytePayAccountResponse.h
//  CJPay-1ab6fc20
//
//  Created by wangxiaohong on 2022/9/19.
//

#import "CJPayBaseResponse.h"

#import "CJPayPassKitBaseResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySignOnlyBindBytePayResultDesc : JSONModel

@property (nonatomic, assign) NSInteger remainTime;
@property (nonatomic, copy) NSString *signStatusDesc;
@property (nonatomic, copy) NSString *serviceName;
@property (nonatomic, copy) NSString *signFailReason;
@property (nonatomic, copy) NSString *signStatus;

@end

@interface CJPaySignOnlyBindBytePayAccountResponse : CJPayPassKitBaseResponse

@property (nonatomic, assign) int remainRetryCount;
@property (nonatomic, copy) NSString  *remainLockDesc;
@property (nonatomic, copy) NSString  *signStatus;
@property (nonatomic, strong) CJPaySignOnlyBindBytePayResultDesc *resultDesc;

@end

NS_ASSUME_NONNULL_END
