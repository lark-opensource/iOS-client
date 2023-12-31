//
//  CJPayBDCashierModule.h
//  Pods
//
//  Created by 尚怀军 on 2020/11/13.
//

#import <Foundation/Foundation.h>
#import "CJPayProtocolServiceHeader.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayBDCashierModule <CJPayWakeByUniversalPayDeskProtocol>

/**
 * 打开三方收银台界面  bizParams是由商户传入的参数
 **/
- (void)i_openBDPayDeskWithConfig:(NSDictionary<CJPayPropertyKey,NSString *> *)configDic orderParams:(nonnull NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
