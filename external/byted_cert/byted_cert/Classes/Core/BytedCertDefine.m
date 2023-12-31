//
//  BytedCertDefine.m
//  AFgzipRequestSerializer
//
//  Created by xunianqiang on 2020/2/11.
//

#import "BytedCertDefine.h"

///// 旧版SDK参数
//NSString * const BytedCertJSBParamMode = @"mode";
//NSString * const BytedCertJSBParamUid = @"uid";
//NSString * const BytedCertJSBParamSecUid = @"sec_user_id";
//NSString * const BytedCertJSBParamMerchantId = @"merchant_id";
//NSString * const BytedCertJSBParamMerchantAppId = @"merchant_app_id";
//NSString * const BytedCertJSBParamBusitype = @"busi_type";
//NSString * const BytedCertJSBParamSource = @"source";

/// 新版SDK参数
NSString *const BytedCertParamAppId = @"aid";             /// app id
NSString *const BytedCertParamScene = @"scene";           /// 场景
NSString *const BytedCertParamTicket = @"ticket";         /// 一次完整业务流程的票据
NSString *const BytedCertParamMode = @"mode";             /// 流程mode，用于h5区分流程，1：身份验证，0：实名认证、身份认证
NSString *const BytedCertLivenessType = @"liveness_type"; ///  活体类型

NSString *const BytedCertParamIdentityCode = @"identity_code"; /// 身份证号码
NSString *const BytedCertParamIdentityName = @"identity_name"; /// 身份证姓名

/// 端上jsb获取req_order_no格式定义
NSString *const BytedCertJSBFetchReqOrderNoName = @"app.fetchFinishReqTicket";
NSString *const BytedCertJSBFetchReqOrderNoKey = @"ticket";

/// 流程结束参数定义
NSString *const BytedCertJSBParamsErrorCode = @"error_code"; /// error_code
NSString *const BytedCertJSBParamsErrorMsg = @"error_msg";
;                                                        /// error_msg
NSString *const BytedCertJSBParamsExtData = @"ext_data"; /// ext_data
NSString *const BytedCertJSBParamsName = @"name";
; /// name
NSString *const BytedCertJSBParamsIdNumber = @"idNumber";
; /// idNumber

//美颜强度定义
int const BytedCertBeautyClose = 0;
int const BytedCertBeautyMiddle = 40;

NSString *const BytedCertParamImageCompare = @"image_compare";
NSString *const BytedCertParamActionNum = @"action_num";

NSString *const BytedCertParamAppVersion = @"app_version";
NSString *const BytedCertParamCacheRootDirectory = @"cache_root_directory";
NSString *const BytedCertParamAppName = @"app_name";
NSString *const BytedCertParamDeviceId = @"device_id";

NSString *const BytedCertParamTargetOffline = @"offline";
NSString *const BytedCertParamTargetReflection = @"reflection";
NSString *const BytedCertParamTargetAudio = @"audio";


BytedCertLiveType const BytedCertLiveTypeAction = @"motion";
BytedCertLiveType const BytedCertLiveTypeReflection = @"reflection";
BytedCertLiveType const BytedCertLiveTypeVideo = @"video";
BytedCertLiveType const BytedCertLiveTypeStill = @"still";
BytedCertLiveType const BytedCertLiveTypeQuality = @"quality";
