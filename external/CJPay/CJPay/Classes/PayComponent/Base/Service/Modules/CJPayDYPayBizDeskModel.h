//
//  CJPayDYPayBizDeskModel.h
//  aweme_xiaohong
//
//  Created by wangxiaohong on 2022/10/9.
//

#import <Foundation/Foundation.h>
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDYPayBizDeskModel : NSObject

@property (nonatomic, assign) BOOL isColdLaunch;
@property (nonatomic, assign) BOOL isPaymentOuterApp;
@property (nonatomic, assign) BOOL isUseMask;
@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, strong) JSONModel *response;
@property (nonatomic, assign) double lastTimestamp; // 上一次上报 event 的时间戳
@property (nonatomic, assign) BOOL isSignAndPay; //是否是签约并支付流程
@property (nonatomic, copy) NSDictionary *bizParams;

@end

NS_ASSUME_NONNULL_END
