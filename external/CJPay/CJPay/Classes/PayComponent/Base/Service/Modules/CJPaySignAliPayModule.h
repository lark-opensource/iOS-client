//
//  CJPaySignAliPayModule.h
//  Pods
//
//  Created by 易培淮 on 2022/3/31.
//


#ifndef CJPaySignAliPayModule_h
#define CJPaySignAliPayModule_h
#import "CJPaySDKDefine.h"
#import "CJPayProtocolServiceHeader.h"

@protocol CJPaySignAliPayModule <CJPayWakeByUniversalPayDeskProtocol>

- (void)i_signActionWithDataDict:(NSDictionary *)dataDict completionBlock:(void(^)(NSDictionary *resultDic))completionBlock;

@end

#endif /* CJPaySignAliPayModule_h */
