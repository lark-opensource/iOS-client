//
//  UASDKErrorCode.h
//  TYRZSDK
//
//  Created by 谢鸿标 on 2018/10/24.
//  Copyright © 2018 com.CMCC.iOS. All rights reserved.
//

#ifndef UASDKErrorCode_h
#define UASDKErrorCode_h

#import <Foundation/Foundation.h>

typedef NSString *UASDKErrorCode;

//成功
static UASDKErrorCode const UASDKErrorCodeSuccess                = @"103000";
//数据解析异常
static UASDKErrorCode const UASDKErrorCodeProcessException       = @"200021";
//无网络
static UASDKErrorCode const UASDKErrorCodeNoNetwork              = @"200022";
//请求超时
static UASDKErrorCode const UASDKErrorCodeRequestTimeout         = @"200023";
//未知错误
static UASDKErrorCode const UASDKErrorCodeUnknownError           = @"200025";
//蜂窝未开启或不稳定
static UASDKErrorCode const UASDKErrorCodeNonCellularNetwork     = @"200027";
//网络请求出错(HTTP Code 非200)
static UASDKErrorCode const UASDKErrorCodeRequestError           = @"200028";
//非移动网关重定向失败
static UASDKErrorCode const UASDKErrorCodeWAPRedirectFailed      = @"200038";
//无SIM卡
static UASDKErrorCode const UASDKErrorCodePhoneWithoutSIM        = @"200048";
//Socket创建或发送接收数据失败
static UASDKErrorCode const UASDKErrorCodeSocketError            = @"200050";
//服务端返回数据异常
static UASDKErrorCode const UASDKErrorCodeExceptionData          = @"200064";
//CA根证书校验失败
static UASDKErrorCode const UASDKErrorCodeCAAuthFailed           = @"200072";
//服务器繁忙
static UASDKErrorCode const UASDKErrorCodeServerBusy             = @"200082";
//ppLocation为空
static UASDKErrorCode const UASDKErrorCodeLocationError          = @"200086";
//当前网络不支持取号
static UASDKErrorCode const UASDKErrorCodeUnsupportedNetwork     = @"200096";

/**
 获取错误码描述

 @param code 错误码
 @return 返回对应描述
 */
FOUNDATION_EXPORT NSString *UASDKErrorDescription(UASDKErrorCode code);

#endif /* UASDKErrorCode_h */
