//
//  BDHMJSBErrorModel.h
//  IESWebViewMonitor
//
//  Created by zhangxiao on 2021/7/26.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDHMJSBErrorModel : NSObject
// 请求 method * 必填
@property (nonatomic, copy) NSString *method;
// 请求 url * 必填
@property (nonatomic, copy) NSString *url;
// 错误码 * 必填 (errorCode != 0 代表错误)
@property (nonatomic, assign) NSInteger errorCode;
// bridge 状态码 * 必填
@property (nonatomic, assign) NSInteger bridgeCode;
// / 错误描述 * 选填
@property (nonatomic, copy) NSString *errorMsg;
// HTTP 状态码 * 选填
@property (nonatomic, assign) NSInteger httpCode;
// 请求错误码 * 选填
@property (nonatomic, assign) NSInteger requestErrorCode;
// 请求错误描述 * 选填
@property (nonatomic, copy, nullable) NSString *requestErrorMsg;


@end

NS_ASSUME_NONNULL_END
