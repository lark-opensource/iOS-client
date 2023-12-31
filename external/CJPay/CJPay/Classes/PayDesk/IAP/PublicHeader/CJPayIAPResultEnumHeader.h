//
//  CJPayIAPResultEnumHeader.h
//  CJPay
//
//  Created by 尚怀军 on 2022/2/28.
//

#ifndef CJPayIAPResultEnumHeader_h
#define CJPayIAPResultEnumHeader_h

typedef NS_ENUM(NSInteger, CJPayIAPResultType) {
    CJPayIAPResultTypePaySuccess = 0, // 支付成功
    CJPayIAPResultTypePayFailure, // 支付失败
    CJPayIAPResultTypeFinishInApple, // 在Apple端finish 但是在财经服务器还没返回明确的结果
    CJPayIAPResultTypeCreateOrderFail,  // 下单失败
    CJPayIAPResultTypeHaveUnfinishOrder,  // 存在未完成订单
    CJPayIAPResultTypeUnknown,  //未知
};

typedef NS_ENUM(NSInteger, CJIAPStoreManagerErrorCode) {
    CJIAPStoreManagerErrorCodeUnFinishedOrder = 700,       // 700 有未完成订单
    CJIAPStoreManagerErrorCodeCreateOrderFailed,           // 701 新建订单失败
    CJIAPStoreManagerErrorCodeCacheOrderInfoFailed,        // 702 绑定订单号时失败
    CJIAPStoreManagerErrorCodeCacheAppleTransactionFailed, // 703 缓存苹果transaction时失败
    CJIAPStoreManagerErrorCodeConfirmNotSuccess,      // 704 到财经后台验证时，失败
    CJIAPStoreManagerErrorCodeRestoreWithoutIAPIDs,   // 705 调用restore，IAPIDs为空
    CJIAPStoreManagerErrorCodeHasUnconfirmedOrder,    // 706 存在未在财经后台校验通过的订单
    
    CJIAPStoreManagerErrorCodeCancelPay,             // 707 用户在支付弹窗里点击了取消
    CJIAPStoreManagerErrorCodeFetchOrderIDFailed,   //  708 财经获取订单号失败
    // IESStore 错误码映射
    CJIAPStoreManagerErrorCodeNoProducts,       // 709 未拉取到products列表
    CJIAPStoreManagerErrorCodeInvalidProduct,           // 710 购买时传入非法product
    CJIAPStoreManagerErrorCodeCannotMakePayments,       // 711 该设备无法使用IAP
    CJIAPStoreManagerErrorCodeUnverifiedTransactions,   // 712 有未验证订单，无法购买
    CJIAPStoreManagerErrorCodeCheckFinalResultFail,     // 713 获取最终结果失败
    CJIAPStoreManagerErrorCodeInvalidUserID,            // 714 没有获取到uid
    CJIAPStoreManagerErrorCodeOrderPending,             // order pending
};

typedef NS_ENUM(NSInteger, CJIAPStoreCreateOrderFailCode) {
    CJIAPStoreCreateOrderFailCodeHasUnConfirm,
    CJIAPStoreCreateOrderFailCodeHasPayingOrder,
    CJIAPStoreCreateOrderFailCodeRequestFail,
};


typedef NS_ENUM(NSInteger, CJPayIAPType) {
    CJPayIAPTypeOCSK1,              // 0 OCSK1
    CJPayIAPTypeSwiftSK1,           // 1 SwiftSK1
    CJPayIAPTypeSwiftSK2,           // 2 SwiftSK2
};

typedef NS_ENUM(NSInteger, CJPayIAPLoadingStage) {
    CJPayIAPLoadingStageOrderFinish,
    CJPayIAPLoadingStageStartPayment,
    CJPayIAPLoadingStageAppleProcess
};

#define CJPayOrderPrefix @"CJ:"
#define CJPayApplicationUserNamePrefix @"XJ:"
#define CJPayIAPErrorDomain @"com.cjpay.error"

#endif /* CJPayIAPResultEnumHeader_h */
