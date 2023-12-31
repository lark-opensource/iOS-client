//
//  CJPayMerchantInfo.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/21.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

//商户信息
@interface CJPayMerchantInfo : JSONModel

@property (nonatomic,copy)NSString *merchantId;
@property (nonatomic,copy)NSString *merchantName;
@property (nonatomic,copy, nullable)NSString *merchantShortName;
@property (nonatomic,copy)NSString *merchantShortToCustomer;
@property (nonatomic,copy)NSString *appId;
@property (nonatomic,copy)NSString *intergratedMerchantId; // 仅追光系统会返回该参数，标识对应的聚合的商户号
@property (nonatomic, copy, nullable) NSString *jhAppId;

@end
