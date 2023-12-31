//
//  CJPayVerifyPassCodeResponse.h
//  CJPay
//
//  Created by 王新华 on 2019/5/22.
//

#import "CJPayBaseResponse.h"
#import "CJPayErrorButtonInfo.h"
#import "CJPayPassKitBaseResponse.h"
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayVerifyPassCodeResponse : CJPayPassKitBaseResponse

@property (nonatomic, assign) int remainRetryCount;
@property (nonatomic, assign) int remainLockTime;
@property (nonatomic, copy) NSString  *remainLockDesc;

@end

NS_ASSUME_NONNULL_END
