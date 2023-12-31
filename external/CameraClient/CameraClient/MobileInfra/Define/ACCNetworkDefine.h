//
//  ACCNetworkDefine.h
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/9/7.
//

#ifndef ACCNetworkDefine_h
#define ACCNetworkDefine_h

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSErrorDomain const AWENetworkErrorDomain;
FOUNDATION_EXPORT NSErrorDomain const AWEApiErrorDomain;
FOUNDATION_EXPORT NSErrorDomain const AWEClientErrorDomain;
FOUNDATION_EXPORT NSString * const AWEApiErrorGetStatusMsgKey; //业务错误时,是否有statusMsg
FOUNDATION_EXPORT NSString * const AWENetworkErrorLogType;

/**
 * response content
 */
FOUNDATION_EXPORT NSString * const AWENetworkResponseKey;
FOUNDATION_EXPORT NSString * const AWENetworkErrorKey;
FOUNDATION_EXPORT NSString * const AWENetworkRespnseObjectKey;
FOUNDATION_EXPORT NSString * const AWENetworkRequestURLKey;
FOUNDATION_EXPORT NSString * const AWENetworkRequestIDKey;

/**
 * network error
 */
typedef NS_ENUM(NSInteger, ACCNetworkErrorCode)
{
    ACCNetworkErrorCodeInvalidRequestParams         = -10000,       // 非法请求参数
    
    
    ACCNetworkErrorCodeNetworkError                 = -11000,
    ACCNetworkErrorCodeInvalidJsonFormat            = -11001,       // 返回数据格式不对
    ACCNetworkErrorCodeInvalidApiModel              = -11002,       // 非法Api model格式
    ACCNetworkErrorCodeStatusError                  = -11003,       // status error
};

/**
 * 服务端返回的状态码
 */
typedef NS_ENUM(NSInteger, ACCServerStatusCode)
{
    ACCServerStatusCodeBusy                             = 4,        // 服务器打瞌睡
    ACCServerStatusCodeInvalidParam                     = 5,        // Error for invalid params, cannot retry
    ACCServerStatusCodeNotLogin                         = 8,        // 用户未登录
    ACCServerStatusCodeOperationBanned                  = 9,        // 用户被禁封使用该操作
    ACCServerStatusCodeExceedMaxCaptchaVerifyCount      = 2156,     // 图片验证码校验失败次数过多
    ACCServerStatusCodeStoryPublishTooMany              = 2200,
    ACCServerStatusCodeTooManyPeoplePublish             = 2555,     // 同时上传的人数过多
    ACCServerStatusCodeCommentNotAuthorized             = 3056,     // 该视频评论只对特定人开发
    ACCServerStatusCodeCommentClosedByUser              = 3057,     // 该视频评论已被关闭
    ACCServerStatusCodeShowSecureCaptureAlert1          = 3058,     // 显示安全组的验证码，样式1
    ACCServerStatusCodeShowSecureCaptureAlert2          = 3059,     // 显示安全组的验证码，样式2
    ACCServerStatusCodeCommentForbided                  = 3058,     // 该视频评论被禁止
    ACCServerStatusCodeShowSecureCaptureClickSelect     = 3070,     // 命中点选验证码处罚接口返回码
    ACCServerStatusCodeShowLoginAlert                   = 3071,     // 命中登录处罚接口返回码
    ACCServerStatusCodeShowSecureCaptureSlide           = 3072,     // 命中滑块验证码处罚接口返回码
    ACCServerStatusCodeShowSecondVerification           = 3299,     // 命中投稿二次验证接口返回码
    ACCServerStatusCodeUpSMSVerify                      = 40102,     //上行短信验证
    ACCServerStatusCodeDownSMSVerify                    = 40103,     //下行短信验证
    
};


#endif /* ACCNetworkDefine_h */
