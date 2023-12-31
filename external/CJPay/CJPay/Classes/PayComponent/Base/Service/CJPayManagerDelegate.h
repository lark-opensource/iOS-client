//
//  CJPayManagerDelegate.h
//  CJPay
//
//  Created by wangxinhua on 2020/7/13.
//

#ifndef CJPayManagerDelegate_h
#define CJPayManagerDelegate_h

#import "CJBizWebDelegate.h"

// CJPayManagerResultFailed，CJPayManagerResultSuccess，CJPayManagerResultTimeout，CJPayManagerResultProcessing 这几个错误全是查询支付结果返回的结果。
// CJPayManagerResultError 可能网络问题，导致SDK不能查询到准确的支付状态。
typedef NS_ENUM(NSInteger, CJPayManagerResultType) {
    CJPayManagerResultCancel = 0, // 取消支付，confirm 未返回成功时点击了关闭收银台
    CJPayManagerResultFailed = 1, // 支付失败
    CJPayManagerResultSuccess = 2, // 支付成功
    CJPayManagerResultTimeout = 3, // 订单超时
    CJPayManagerResultProcessing = 4, // 支付处理中
    CJPayManagerResultError = 5, // 未知错误
    CJPayManagerResultOpenFailed = 6, // 调起收银台失败
    CJPayManagerResultInsufficientBalance = 7, // 支付余额不足
};

@class CJPayOrderResultResponse;
@protocol CJPayManagerDelegate<CJBizWebDelegate>

/**
 * 是否成功调起收银台的回调
 * isSuccess 是否成功调起
 **/

- (void)callPayDesk:(BOOL)isSuccess;

/**
 收银台的回调

 @param resultType 返回收银台关闭时的状态码
 @param response 收银台最终支付结果的Response。为服务端返回值，在没有走到查询支付结果接口是可能没有值。一般CJPayManagerResultProcessing, CJPayManagerResultTypeTimeout, CJPayManagerResultSuccess 时response有值，其他情况可能没有值。
 CJPayManagerResultCancel 为用户主动关闭收银台。CJPayManagerResultError 错误可能网络是网络原因
 */
- (void)handleCJPayManagerResult:(CJPayManagerResultType) resultType payResult:(nullable id)response;

@end

#endif /* CJPayManagerDelegate_h */
