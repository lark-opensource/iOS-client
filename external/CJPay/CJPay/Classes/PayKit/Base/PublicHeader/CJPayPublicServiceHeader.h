//
//  CJPayPublicServiceHeader.h
//  CJPay-Example
//
//  Created by 王新华 on 2021/9/7.
//

#ifndef CJPayPublicServiceHeader_h
#define CJPayPublicServiceHeader_h

// 定制Toast
#import "CJPayToastProtocol.h"
// 定制SDK loading样式，宿主可以直接实现
#import "CJPayTopLoadingProtocol.h"
// 定义SDK内部断弱网样式
#import "CJPayErrorViewProtocol.h"
// SDK内部埋点代理，通过该代理，业务可以实现埋点上报
#import "CJPayTrackerProtocol.h"
// 日志上报代理方法
#import "CJPayLoggerProtocol.h"
// 活体识别的代理方法，
#import "CJPayFaceLivenessProtocol.h"
// SDK内部触发宿主登录的代理实现
#import "CJPayLoginProtocol.h"
// SDK 内部获取运营商登录授权的方法
#import "CJPayCarrierLoginProtocol.h"
// 支付收银台，取消支付代理回调，业务可以设置拦截弹窗。
#import "CJPayClosePayDeskAlertProtocol.h"
// 调用宿主分享方法
#import "CJPayShareProtocol.h"
// 支付SDK生命周期回调方法，主要用于处于支付过程时，需要宿主做屏蔽
#import "CJPayLifeCycleObserver.h"

#endif /* CJPayPublicServiceHeader_h */
