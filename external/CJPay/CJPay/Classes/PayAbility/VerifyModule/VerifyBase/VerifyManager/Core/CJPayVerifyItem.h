//
//  CJPayVerifyItem.h
//  CJPay
//
//  Created by 王新华 on 7/18/19.
//

#import <Foundation/Foundation.h>
#import "CJPayOrderConfirmResponse.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayVerifyManagerHeader.h"
#import "CJPayTrackerProtocol.h"
#import "CJPayRetainUtilModel.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayBaseVerifyManager;

typedef NSString * CJPayVerifyEventKey;
extern CJPayVerifyEventKey const CJPayVerifyEventRecommandVerifyKey;// 字符串类型，收银台title
extern CJPayVerifyEventKey const CJPayVerifyEventSwitchToPassword; // 切换为密码验证
extern CJPayVerifyEventKey const CJPayVerifyEventSwitchToBio; // 切换为面容/指纹验证

@interface CJPayEvent : NSObject

@property (nonatomic, copy) CJPayVerifyEventKey name;
@property (nonatomic, copy) id data;
@property (nonatomic, assign) BOOL boolData;
@property (nonatomic, copy) NSString *stringData;
@property (nonatomic, copy) NSString *verifySource; //记录验证组件的上级来源
@property (nonatomic, assign) CJPayVerifyType verifySourceType; // 记录验证组件的上级来源类型

- (instancetype)initWithName:(CJPayVerifyEventKey )name data:(nullable id)data;

@end

@interface CJPayVerifyItem : NSObject

@property (nonatomic, weak) CJPayBaseVerifyManager *manager;
@property (nonatomic, assign) CJPayVerifyType verifyType;
@property (nonatomic, copy) NSString *verifySource; //标记调起验证组件的上级来源

- (void)bindManager:(CJPayBaseVerifyManager *)manager;
- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event;
- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response;
- (void)handleVerifyResponse:(CJPayOrderConfirmResponse *)response;
- (nullable NSDictionary *)getLatestCacheData;
- (void)receiveEvent:(CJPayEvent *)event;
- (void)notifyWakeVerifyItemFail;
- (void)notifyVerifyCancel;

- (NSString *)checkTypeName;

/**
 由子类继承，具体返回值如下：
 0: 支付(数字)密码验证、
 1：指纹密码验证、
 2:面容、
 3:免密支付、
 5:免验密码(在没有开通免密支付时免验密码，仅用在二次支付)、
 100：补签约
 */
- (NSString *)checkType;
- (NSString *)handleSourceType; //获取加验来源进行埋点上报
- (CJPayRetainUtilModel *)buildRetainUtilModel;

@end

@interface CJPayVerifyItem(TrackerProtocol)<CJPayTrackerProtocol>

@end

NS_ASSUME_NONNULL_END
