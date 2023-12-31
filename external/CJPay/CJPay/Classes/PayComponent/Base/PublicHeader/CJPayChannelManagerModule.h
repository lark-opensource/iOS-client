//
//  CJPayChannelManagerModule.h
//  CJPay
//
//  Created by wangxinhua on 2020/7/16.
//

#ifndef CJPayChannelManagerModule_h
#define CJPayChannelManagerModule_h
#import "CJPaySDKDefine.h"
#import "CJPayProtocolServiceHeader.h"

@class CJPayBasicChannel;
@protocol CJPayChannelManagerModule <CJPayWakeByUniversalPayDeskProtocol>

- (NSString *)i_wxH5PayReferUrlStr;
- (void)i_registerWXH5PayReferUrlStr:(NSString *)urlstr;
- (void)i_registerWXUniversalLink:(NSString *)wxUniversalLink;
/**
*  判断 URL 收银台是否可以处理
*
*  @param url 获取的 URL
*
*  @return 如果可以处理返回 YES，反之为 NO
*/
- (BOOL)i_canProcessURL:(NSURL *)url;
- (BOOL)i_canProcessUserActivity:(NSUserActivity *)userActivity;

- (void)i_payActionWithChannel:(CJPayChannelType)channelType
                      dataDict:(NSDictionary *)dataDict
               completionBlock:(void (^) (CJPayChannelType channelType, CJPayResultType resultType, NSString *errorCode))completionBlock;
@end

#endif /* CJPayChannelManagerModule_h */
