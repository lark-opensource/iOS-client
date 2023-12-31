//
//  LarkWebViewMonitorCode.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/1.
//
// 统一WebView MonitorCode定义
// - 参考文档 ：https://bytedance.feishu.cn/base/bascnJdCxqgg8VhCbB3frr0N0sf?table=tblfyP93EMqAfhDq&view=vewTf0ews2

import Foundation
import ECOProbe

/// Base层MonitorCode
class BaseMonitorCode: OPMonitorCode {
    private static let domain = "client.larkwebview.base"

    static let loadUrlStart = BaseMonitorCode(code: 20001, level: OPMonitorLevelNormal, message: "load url start")
    static let loadUrlEnd = BaseMonitorCode(code: 20002, level: OPMonitorLevelNormal, message: "load url end")
    static let createWebView = BaseMonitorCode(code: 20009, level: OPMonitorLevelNormal, message: "create webView")
    static let destroyWebView = BaseMonitorCode(code: 20015, level: OPMonitorLevelNormal, message: "destroy webView")
    static let loadUrlCommit = BaseMonitorCode(code: 20018, level: OPMonitorLevelNormal, message: "load url commit")
    static let loadUrlOverride = BaseMonitorCode(code: 20019, level: OPMonitorLevelNormal, message: "load url override")
    static let loadUrlCancel = BaseMonitorCode(code: 20020, level: OPMonitorLevelNormal, message: "load url cancel")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: Self.domain, code: code, level: level, message: message)
    }
}

/// Bridge层MonitorCode
class BridgeMonitorCode: OPMonitorCode {
    private static let domain = "client.larkwebview.bridge"

    /// 执行JS方法的参数不合法
    static let invalidJsParams = BridgeMonitorCode(code: 10000, level: OPMonitorLevelError, message: "invalid_js_params")

    /// JS方法名为空
    static let jsFunctionNameEmpty = BridgeMonitorCode(code: 10001, level: OPMonitorLevelError, message: "js_function_name_empty")

    /// 组装APIMessage失败
    static let buildApiMessageFailed = BridgeMonitorCode(code: 10002, level: OPMonitorLevelError, message: "build_api_message_failed")

    /// 未找到APIHandler
    static let noApiHandler = BridgeMonitorCode(code: 10004, level: OPMonitorLevelError, message: "no_api_handler")

    /// 构造JS字符串错误
    static let buildJsStringFailed = BridgeMonitorCode(code: 10008, level: OPMonitorLevelError, message: "build_js_string_failed")

    /// JS执行错误
    static let evaluateJsError = BridgeMonitorCode(code: 10009, level: OPMonitorLevelError, message: "evaluate_js_error")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: Self.domain, code: code, level: level, message: message)
    }
}

/// Pool层MonitorCode
class PoolMonitorCode: OPMonitorCode {
    private static let domain = "client.larkwebview.pool"

    /// 重复注册Pool
    static let registerExistingIdentifier = PoolMonitorCode(code: 30000, level: OPMonitorLevelError, message: "register_existing_identifier")
    /// identifier do not exist
    static let identifierNotExist = PoolMonitorCode(code: 30001, level: OPMonitorLevelError, message: "identifier_not_exist")
    static let webviewTypeError = PoolMonitorCode(code: 30002, level: OPMonitorLevelError, message: "must be a LarkWebView")

    private init(code: Int, level: OPMonitorLevel, message: String) {
        assertionFailure(message)
        super.init(domain: Self.domain, code: code, level: level, message: message)
    }
}

/// 品质层MonitorCode
class QualityMonitorCode: OPMonitorCode {
    private static let domain = "client.larkwebview.quality"

    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: Self.domain, code: code, level: level, message: message)
    }

    /// 安全链接检测
    static let seclinkCheck = QualityMonitorCode(code: 40003, level: OPMonitorLevelError, message: "seclink check")
    /// 全流程埋点, 性能数据
    static let performanceTiming = QualityMonitorCode(code: 40009, level: OPMonitorLevelNormal, message: "performance timing")
    /// 全流程埋点, 性能数据
    static let webViewProcessGone = QualityMonitorCode(code: 40010, level: OPMonitorLevelError, message: " webview process gone")
}

/// 白屏检测 MonitorCode
class BlankDetectMonitorCode: OPMonitorCode {
    private static let domain = "client.larkwebview.blankdetect"
    
    private init(code: Int, level: OPMonitorLevel, message: String) {
        super.init(domain: Self.domain, code: code, level: level, message: message)
    }
    
    /// WebView 拍照失败
    static let takeSnapshotNoImage = BlankDetectMonitorCode(code: 50000, level: OPMonitorLevelError, message: "take snapshot has no image")
    
    /// 图片尺寸不合法
    static let imageSizeInvaild = BlankDetectMonitorCode(code: 50001, level: OPMonitorLevelError, message: "image size invaild, width and height is not > 0")
    
    /// 图片无法转换为 CGImage
    static let noCGImage = BlankDetectMonitorCode(code: 50002, level: OPMonitorLevelError, message: "image cannot trans to cgimage")
    
    /// 生成 CGContext 失败
    static let initCGContextError = BlankDetectMonitorCode(code: 50003, level: OPMonitorLevelError, message: "init CGContext error")
    
    /// CGContext 无 image data
    static let contextHasNoImageData = BlankDetectMonitorCode(code: 50004, level: OPMonitorLevelError, message: "context has no image data")
    
    ///未检测到纯色
    static let failToDetectPureColor = BlankDetectMonitorCode(code: 50005, level: OPMonitorLevelError, message: "fail to detect purecolor")

    ///未检测到DOM
    static let failToCheckContentDOM = BlankDetectMonitorCode(code: 50006, level: OPMonitorLevelError, message: "fail to check content DOM")

}
