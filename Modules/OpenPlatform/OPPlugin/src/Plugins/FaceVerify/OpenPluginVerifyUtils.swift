//
//  OpenPluginVerifyUtils.swift
//  OPPlugin
//
//  Created by ByteDance on 2023/3/30.
//

import Foundation
import LarkSetting
import LarkOpenAPIModel
import OPFoundation

final class FaceVerifyUtils {
    // TODOZJX
    @FeatureGatingValue(key: "openplatform.api.split_cert_sdk_error_disable")
    static var splitCertSdkErrorDisable: Bool
    
    ///将实名SDK返回的error分为业务方调用错误和实名内部错误，方便业务方数据统计
    static func splitCertSdkError(certErrorCode errorCode: Int, msg: String) -> OpenAPIBiologyErrno{
        if Self.splitCertSdkErrorDisable {
            return .certSdkError(errorString: msg, errorCode: "\(errorCode)")
        }
        if certSdkInternalErrorList.contains(errorCode) {
            return .certSdkInternalError(code: "\(errorCode)", msg: msg)
        }
        return .certSdkBusinessError(code: "\(errorCode)", msg: msg)
    }
    
    private static let certSdkInternalErrorList = [
        -1001, //一般为参数异常
        -1004, //活体算法初始化失败
        -1005, //活体算法初始化失败
        -5003, //离线模型未下载
        -5004, //对应模型不存在
        -5010, //静默活体初始化失败
        2001, //智创服务端返回“请求被拒绝”
    ]
}
