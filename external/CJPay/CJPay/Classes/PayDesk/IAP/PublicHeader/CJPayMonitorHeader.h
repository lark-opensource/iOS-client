//
//  CJPayMonitorHeader.h
//  CJPay-IAP
//
//  Created by 尚怀军 on 2022/4/11.
//

#ifndef CJPayMonitorHeader_h
#define CJPayMonitorHeader_h

typedef NS_ENUM(NSUInteger, CJPayIAPStage) {
    CJPayIAPStageInit, // init
    CJPayIAPStageWakeup, // start IAP
    CJPayIAPStageRequestProducts, // request products
    CJPayIAPStageCreateBizOrder, // biz order
    CJPayIAPStageStartPayment,
    CJPayIAPStageReceiveTransaction, // send transaction
    CJPayIAPStageVerifyTransaction, // verify transaction
    CJPayIAPStageCallbackResult, // iap callback to biz
};

#endif /* CJPayMonitorHeader_h */
