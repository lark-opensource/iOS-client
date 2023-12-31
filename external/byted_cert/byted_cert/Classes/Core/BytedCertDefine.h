//
//  BytedCertDefine.h
//  AFgzipRequestSerializer
//
//  Created by xunianqiang on 2020/2/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 新版SDK参数key定义
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertParamAppId;  /// app id
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertParamScene;  /// 场景
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertParamTicket; /// 一次完整业务流程的票据
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertParamMode;   /// 流程mode，用于h5区分流程，1：身份验证，0：实名认证、身份认证
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertParamAppVersion;
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertParamCacheRootDirectory;
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertParamDeviceId;
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertParamImageCompare;
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertParamActionNum;

FOUNDATION_EXPORT NSString *_Nonnull const BytedCertLivenessType;

FOUNDATION_EXPORT NSString *_Nonnull const BytedCertParamIdentityCode; /// 身份证号码
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertParamIdentityName; /// 身份证姓名

//活体检测接口

/// jsb获取req_order_no格式定义
/*
 jsb定义如下：
 app.fetchFinishReqTicket
 参数：
 {
 uid : string,
 mode: int
 }
 返回值：
 {
 ticket : string
 }
 // 旧版
 app.fetchFinishReqOrderNo
 参数：
 {
    uid : string,
    merchant_id : string
    mode : int
 }
 返回值：
 {
    req_order_no : string
 }
*/
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertJSBFetchReqOrderNoName; /// jsb名称
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertJSBFetchReqOrderNoKey;  /// 请求号key

/// 流程结束参数定义
/*
eg: data:{
    error_code: status_code,
    error_msg:fail_msg,
    ext_data:{
        name,
        idNumber,
        mode,
        req_order_no,
        merchant_id,
        uid
    }
}
*/
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertJSBParamsErrorCode; /// error_code
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertJSBParamsErrorMsg;  /// error_msg
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertJSBParamsExtData;   /// ext_data
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertJSBParamsName;      /// name
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertJSBParamsIdNumber;  /// idNumber


//美颜强度定义
FOUNDATION_EXPORT int const BytedCertBeautyClose;
FOUNDATION_EXPORT int const BytedCertBeautyMiddle;

FOUNDATION_EXPORT NSString *_Nonnull const BytedCertParamTargetOffline;
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertParamTargetReflection;
FOUNDATION_EXPORT NSString *_Nonnull const BytedCertParamTargetAudio;


typedef NS_ENUM(NSUInteger, BytedCertProgressType) {
    BytedCertProgressTypeIdentityAuth = 0,   /// 实名认证
    BytedCertProgressTypeIdentityVerify = 1, /// 身份验证
};

typedef NSString *BytedCertLiveType NS_EXTENSIBLE_STRING_ENUM;
FOUNDATION_EXPORT BytedCertLiveType _Nonnull const BytedCertLiveTypeAction;     // 动作活体
FOUNDATION_EXPORT BytedCertLiveType _Nonnull const BytedCertLiveTypeReflection; // 炫彩活体
FOUNDATION_EXPORT BytedCertLiveType _Nonnull const BytedCertLiveTypeVideo;      // 视频活体
FOUNDATION_EXPORT BytedCertLiveType _Nonnull const BytedCertLiveTypeStill;      // 静默活体
FOUNDATION_EXPORT BytedCertLiveType _Nonnull const BytedCertLiveTypeQuality;    // 人脸采集


NS_ASSUME_NONNULL_END
