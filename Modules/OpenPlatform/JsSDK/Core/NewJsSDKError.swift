//
//  NewJsSDKError.swift
//  LarkWeb
//
//  Created by 武嘉晟 on 2019/9/22.
//

import Foundation

/// 错误对应的数据结构，请勿修改，如果要修改，请联系熟悉的同学
struct JSSDKErrorItem {
    /// 错误码
    fileprivate let code: Int
    /// 错误信息
    fileprivate let msg: String
    /// 可以补充后端加上的msg，也可以默认后面不拼接msg
    func description(with extraMsg: String = "") -> [String: Any] {
        return [
            "errorCode": code,
            "errorMessage": msg + extraMsg
        ]
    }
}

/// 每个API结构必须遵循的协议，请勿修改，如果要修改，请联系熟悉的同学
protocol JSSDKErrorAPI {
    /// 每个API都有对应的ID，不会重复
    static var bizAPICode: Int { get }
}

/// 业务API获取错误info的入口
struct NewJsSDKErrorAPI {
    /// 这个层级的是通用的错误类型，和API无关，比如网络错误，参数解析错误
    ///
    /// resolve服务失败
    static let resolveServiceError = unknown(extraMsg: "resolve Service failed")
    /// 请求错误
    static let requestError = JSSDKErrorItem(code: 10_001, msg: "request error")
    /// 错误的数据类型
    static let wrongDataFormat = JSSDKErrorItem(code: 10_002, msg: "wrong data format")
    /// 缺失请求参数
    static let missingRequiredArgs = JSSDKErrorItem(code: 10_003, msg: "missing required args")

    /// 错误的json
    static let badJSON = JSSDKErrorItem(code: 1002, msg: "错误的json")
    /// 未知错误
    /// - Parameter extraMsg: 额外msg
    static func unknown(extraMsg: String) -> JSSDKErrorItem {
        return JSSDKErrorItem(code: 1003, msg: extraMsg)
    }
    /// 错误的uid
    static let badUID = JSSDKErrorItem(code: 1004, msg: "错误的uid")
    /// 错误的corpid
    static let badCorpID = JSSDKErrorItem(code: 1005, msg: "错误的corpid")
    /// 创建会话出现错误
    /// - Parameter extraMsg: 额外msg
    static func createChatError(extraMsg: String) -> JSSDKErrorItem {
        return JSSDKErrorItem(code: 1006, msg: "创建会话错误: " + extraMsg)
    }
    /// 未授权
    static let unauth = JSSDKErrorItem(code: 1007, msg: "未授权")
    /// 未知的cropid
    static let unknownCropID = JSSDKErrorItem(code: 1008, msg: "未知的cropid")
    /// 错误的URL
    /// - Parameter extraMsg: 额外msg
    static func badUrl(extraMsg: String) -> JSSDKErrorItem {
        return JSSDKErrorItem(code: 1009, msg: "错误的URL: " + extraMsg)
    }
    /// rpc调用错误
    static let rpcError = JSSDKErrorItem(code: 1010, msg: "rpc调用错误")
    /// 用户中断操作
    static let userBreakError = JSSDKErrorItem(code: 1011, msg: "用户中断")
    /// 错误的参数类型
    /// - Parameter extraMsg: 额外msg
    static func badArgumentType(extraMsg: String) -> JSSDKErrorItem {
        return JSSDKErrorItem(code: 1012, msg: "错误的参数类型: " + extraMsg)
    }
    /// 非法操作
    /// - Parameter extraMsg: 额外msg
    static func invalidCommand(extraMsg: String) -> JSSDKErrorItem {
        return JSSDKErrorItem(code: 1013, msg: "非法操作: " + extraMsg)
    }
    /// 网络错误
    static let networkError = JSSDKErrorItem(code: 1014, msg: "网络错误")
    /// 参数错误
    /// - Parameter extraMsg: 额外msg
    static func invalidParameter(extraMsg: String) -> JSSDKErrorItem {
        return JSSDKErrorItem(code: 1015, msg: "Invalid Parameter: " + extraMsg)
    }
    /// 下载错误
    /// - Parameter extraMsg: 额外msg
    static func downloadFail(extraMsg: String) -> JSSDKErrorItem {
        return JSSDKErrorItem(code: 1016, msg: "Download Fail: " + extraMsg)
    }
}

/// 鉴权接口错误
extension NewJsSDKErrorAPI {
    struct Config: JSSDKErrorAPI {
        /// API ID
        static var bizAPICode: Int = 33
        /// app不存在
        /// - Parameter extraMsg: 后端msg
        static func configAppNotExist(extraMsg: String) -> JSSDKErrorItem {
            return JSSDKErrorItem(code: 333_440, msg: extraMsg)
        }
        /// 验签失败
        /// - Parameter extraMsg: 后端msg
        static func configinvalidSignature(extraMsg: String) -> JSSDKErrorItem {
            return JSSDKErrorItem(code: 333_441, msg: extraMsg)
        }
        /// app没找到有效jsapi-ticket
        /// - Parameter extraMsg: 后端msg
        static func configJsapiTicketNotExist(extraMsg: String) -> JSSDKErrorItem {
            return JSSDKErrorItem(code: 333_442, msg: extraMsg)
        }
        /// 签名已经用过一次了，无法再次使用
        /// - Parameter extraMsg: 后端msg
        static func configSignatureAlreadyUsed(extraMsg: String) -> JSSDKErrorItem {
            return JSSDKErrorItem(code: 333_443, msg: extraMsg)
        }
        /// 签名过期了
        /// - Parameter extraMsg: 后端msg
        static func configSignatureExpired(extraMsg: String) -> JSSDKErrorItem {
            return JSSDKErrorItem(code: 333_444, msg: extraMsg)
        }
        /// 存在未授权的jsapi
        /// - Parameter extraMsg: 后端msg
        static func configJsapiNotAuthorised(extraMsg: String) -> JSSDKErrorItem {
            return JSSDKErrorItem(code: 333_445, msg: extraMsg)
        }
        /// jsapi不存在
        /// - Parameter extraMsg: 后端msg
        static func configJsapiNotExist(extraMsg: String) -> JSSDKErrorItem {
            return JSSDKErrorItem(code: 333_446, msg: extraMsg)
        }
        /// 安全域名没设置
        /// - Parameter extraMsg: 后端msg
        static func configSafeDomainNotDefine(extraMsg: String) -> JSSDKErrorItem {
            return JSSDKErrorItem(code: 333_447, msg: extraMsg)
        }
        /// 页面不在安全域名内
        /// - Parameter extraMsg: 后端msg
        static func configPageMustInSafeDomain(extraMsg: String) -> JSSDKErrorItem {
            return JSSDKErrorItem(code: 333_448, msg: extraMsg)
        }
        /// 应用未安装
        /// - Parameter extraMsg: 后端msg
        static func configAppNotInstall(extraMsg: String) -> JSSDKErrorItem {
            return JSSDKErrorItem(code: 333_449, msg: extraMsg)
        }
    }
}

/// GetUserInfo
extension NewJsSDKErrorAPI {
    struct GetUserInfo: JSSDKErrorAPI {
        /// API ID
        static var bizAPICode: Int = 34
        /// 获取用户信息失败
        static let getUserInfoFail = JSSDKErrorItem(code: 343_001, msg: "Failed to get user information")
    }
}

/// DownloadFile
extension NewJsSDKErrorAPI {
    struct DownloadFile: JSSDKErrorAPI {
        /// API ID
        static var bizAPICode: Int = 35
        /// 取消下载文件
        static let cancel = JSSDKErrorItem(code: 353_001, msg: "cancel downloading file")
        /// 下载文件过大
        static let exceedsLimit = JSSDKErrorItem(code: 353_002, msg: "file size exceeds limit")

    }
}

/// openDoc
extension NewJsSDKErrorAPI {
    struct openDoc: JSSDKErrorAPI {
        /// API ID
        static var bizAPICode: Int = 36
        /// 下载失败
        /// - Parameter extraMsg: 额外msg
        static func downloadFail(extraMsg: String) -> JSSDKErrorItem {
            return JSSDKErrorItem(code: 363_001, msg: "Download Fail: " + extraMsg)
        }
        /// 当前文件格式不支持
        static let fileFormateNotSupport = JSSDKErrorItem(code: 363_002, msg: "current file format not supported")
        /// 下载超出100MB
        static let exceedsLimit = JSSDKErrorItem(code: 363_003, msg: "file size exceeds limit")
    }
}

/// GetStepCount
extension NewJsSDKErrorAPI {
    struct GetStepCount: JSSDKErrorAPI {
        /// API ID
        static var bizAPICode: Int = 37
        /// 设备不支持
        static let getStepCountDeviceNotSupport = JSSDKErrorItem(code: 373_001, msg: "The device does not support step counting")
        /// 获取步数失败
        static let getStepCountInfoFailed = JSSDKErrorItem(code: 373_002, msg: "Failed to get steps")
    }
}

/// openDetail
extension NewJsSDKErrorAPI {
    struct OpenDetail: JSSDKErrorAPI {
        /// API ID
        static var bizAPICode: Int = 38
        /// 内部错误
        static let openDetailInnerError = JSSDKErrorItem(code: 383_050, msg: "inner error")
        /// 请求错误-解密报错
        static let openDetailDecryptError = JSSDKErrorItem(code: 383_050, msg: "decrypt error")
    }
}

/// GetSystemInfo
extension NewJsSDKErrorAPI {
    struct GetSystemInfo: JSSDKErrorAPI {
        /// API ID
        static var bizAPICode: Int = 39
        /// Query DeviceID Fail
        static let queryDeviceIDFail = JSSDKErrorItem(code: 393_001, msg: "Query DeviceID Fail")
    }
}

/// getConnectedWifi
extension NewJsSDKErrorAPI {
    struct GetConnectedWifi: JSSDKErrorAPI {
        /// API ID
        static var bizAPICode: Int = 41
        /// 没有定位权限
        static let noLocation = JSSDKErrorItem(code: 413_001, msg: "have no location auth, if available iOS 13.0 , please call location method first")
        /// 没有连接Wi-Fi
        static let noWiFiConnect = JSSDKErrorItem(code: 413_002, msg: "no wifi connected")
        /// 没Wi-Fi信息
        static let noWiFiInfo = JSSDKErrorItem(code: 413_003, msg: "no wifi info")
    }
}

/// getConnectedWifi
extension NewJsSDKErrorAPI {
    struct GetGatewayIP: JSSDKErrorAPI {
        /// API ID
        static var bizAPICode: Int = 42
        /// 没有定位权限
        static let noLocation = JSSDKErrorItem(code: 423_001, msg: "have no location auth, if available iOS 13.0 , please call location method first")
        /// 没有连接Wi-Fi
        static let noWiFiConnect = JSSDKErrorItem(code: 413_002, msg: "no wifi connected")
        /// 没Wi-Fi信息
        static let noWiFiInfo = JSSDKErrorItem(code: 413_003, msg: "no wifi info")
    }
}

/// previewImage
extension NewJsSDKErrorAPI {
    struct PreviewImage: JSSDKErrorAPI {
        /// API ID
        static var bizAPICode: Int = 43
        /// urls 不合法
        static let invaildurl = JSSDKErrorItem(code: 433_001, msg: "Invalid url")
        /// method 不合法
        static let invaildMethod = JSSDKErrorItem(code: 433_003, msg: "Invalid method")
        /// urls 和 requests 为空
        static let urlsAndRequestsIsEmpty = JSSDKErrorItem(code: 433_005, msg: "urls and requests is empty")
        /// urls 和 requests 互斥
        static let urlsAndRequestsIsMutuallyExclusive = JSSDKErrorItem(code: 433_006, msg: "urls and requests is mutually exclusive")
        /// urls 为空
        static let urlIsEmpty = JSSDKErrorItem(code: 433_008, msg: "url is empty")
        /// urls 和 requests 为空
        static let requestIsEmpty = JSSDKErrorItem(code: 433_009, msg: "request is empty")
        /// method 不合法
        static let invaildBody = JSSDKErrorItem(code: 433_010, msg: "Invalid body")
    }
}

extension NewJsSDKErrorAPI {
    struct PassportLogout: JSSDKErrorAPI {
        static var bizAPICode: Int = 44
        static let interrupted = JSSDKErrorItem(code: 441_002, msg: "Logout is interrupted")

        static func failed(msg: String) -> JSSDKErrorItem {
            JSSDKErrorItem(code: 441_001, msg: msg)
        }
    }
}

/// auth mainpage
extension NewJsSDKErrorAPI {
    struct Auth: JSSDKErrorAPI {
        ///ID
        static var bizAPICode: Int = 0
        /// 未进行鉴权
        static let notAuthrized = JSSDKErrorItem(code: 100_001, msg: "invalid authentication")
        /// api不在jsApiList中
        static let apiNotInAuthrizedAPIList = JSSDKErrorItem(code: 100_002, msg: "${apiName} is not in jsApiList")
        /// api没有找到对应的处理器，99%是因为在其他个性化容器页面中调用了开平的openapi
        static let apiFindNoHandler = JSSDKErrorItem(code: 100_005, msg: "find no handler")
        /// 当前url为空，历史逻辑，不确定什么时候会出现这个情况
        static let webviewURLEmpty = JSSDKErrorItem(code: 100_006, msg: "current page url is empty")
        /// api handler 类型不对，没有实现LarkWebJSAPIHandler协议
        static let apiHandlerTypeInvalid = JSSDKErrorItem(code: 100_007, msg: "handler type is invalid")
        /// api已被加入黑名单内, 不再允许使用
        static func apiDeprecated(apiName: String) -> JSSDKErrorItem {
            return JSSDKErrorItem(code: 100_004, msg: "Deprecated API \(apiName). Please use the latest alternative instead.")
        }
    }
}

extension NewJsSDKErrorAPI {
    /// 根据后端返回的错误信息加上本地的错误模块信息返回对应的失败回调信息
    /// - Parameter api: API模块
    /// - Parameter innerCode: 接口内集成模块编号
    /// - Parameter backendCode: 后端返回错误码
    /// - Parameter backendMsg: 后端返回的错误信息
    static func customApiError(api: JSSDKErrorAPI.Type, innerCode: Int, backendCode: Int, backendMsg: String) -> JSSDKErrorItem {
        return JSSDKErrorItem(code: Int("\(api.bizAPICode)\(innerCode)\(String(String(format: "%03d", UInt(abs(backendCode))).suffix(3)))") ?? 1003, msg: backendMsg)
    }
}
