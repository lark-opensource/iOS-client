//
//  CJPayChannelManager.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/29.
//

#import <Foundation/Foundation.h>
#import "CJPayBasicChannel.h"

@interface CJPayChannelManager : NSObject

+ (instancetype)sharedInstance;

//可选，要支持ApplePay 需要传入ApplePay提供的MerchantID
@property (nonatomic,copy) NSString *appleMerchantID;
// 使用H5微信支付时，为了回调到app，需要配置该字段
//1. info.plist 中增加URL types，URL schemes值默认为：tp-pay.snssdk.com。每个宿主App需要设置不同的URL schemes值，由财经分配。
@property (nonatomic,copy) NSString *h5PayReferUrl;
@property (nonatomic,copy) NSString *h5PayCustomUserAgent;
@property (nonatomic,copy) NSString *wxUniversalLink;

- (BOOL)canProcessWithURL:(NSURL *)URL;
- (BOOL)canProcessUserActivity:(NSUserActivity *)activity;

/**
 吊起支付
 ---version 4.0---
 @param type 选择的支付渠道类型
 @param dataDict 吊起支付时传入的参数
 @param completionBlock 支付完成时的回调
 */
- (void)payActionWithType:(CJPayChannelType)type
                 dataDict:(NSDictionary *)dataDict
          completionBlock:(CJPayCompletion)completionBlock;

- (void)registerChannelClass:(Class<CJPayChannelProtocol>)channelCls channelType:(CJPayChannelType)channelType;

@end
