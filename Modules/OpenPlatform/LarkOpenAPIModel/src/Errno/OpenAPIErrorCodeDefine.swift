//
//  OpenAPIErrorCodeDefine.swift
//  LarkOpenAPIModel
//
//  Created by lixiaorui on 2021/2/20.
//

// 这个文件最终应该自动生成

// https://bytedance.feishu.cn/docs/doccn6KwB11cn6JTARXpLeLeEvc
// 错误码构成：接口域（2位：00预留）接口子域（2位：00预留，指定）错误域（1位，指定）具体错误码（2位，000-099预留）
// 错误域：0：业务方错误，1：引擎-前端错误，2：引擎-客户端错误，3：引擎-后端错误，4：第三方依赖错误

import UIKit

/// 内部协议，不允许外部继承使用，为了在 APIError 校验传入的 Code 是来自 LarkOpenAPIModel 定义。
/// 后续可以考虑通过这个区分内外部，然后业务的错误可以共用一份协议 OpenAPIErrorCodeProtocol
protocol _OpenAPIErrorCodeProtocol {}

/// 通用的 APICode 协议
///
/// 如果使用 RawRepresentable 则要依赖 associatedtype RawValue，
/// 外部使用时需要使用 some 特性，这个在 iOS 13 之前不支持（Swift 5.1），
/// 此处通过 rawValue(Int) 约束即可。
public protocol OpenAPIErrorCodeProtocol: CustomStringConvertible, CustomDebugStringConvertible /* RawRepresentable */ {
    // errCode 取值
    var rawValue: Int { get }

    // errCode 对应的 errMsg
    var errMsg: String { get }
}

extension OpenAPIErrorCodeProtocol {
    public var description: String {
        return "errCode: \(rawValue), errMsg: \"\(errMsg)\""
    }

    public var debugDescription: String {
        return description
    }
}


/// 通用 APICode
///
/// 注意:
/// * 通用 Code 全局唯一，全局预留 0~999。
/// * 一般一个通用 Code 取值在 100~999 间。
/// * 0 统一作为 ok 使用（在 success 时作为 errCode 返回）。
/// * 0~100 间已经上线的业务 Code 保持不变。
/// * 普通 Code 约定为 7 位（已经上线的保持即可）。
public enum OpenAPICommonErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// 成功，success 时返回
    case ok                     = 0

    /// 未知错误，API 内部非预期的错误
    case unknown                = 100

    /// 框架未知错误
    case unknownException       = 101

    /// 内部错误
    case internalError          = 102

    /// API 不可用
    case unable                 = 103

    /// 参数错误
    case invalidParam           = 104

    /// 鉴权失败
    case authenFail             = 105

    /// 系统拒绝授权
    case systemAuthDeny         = 106

    /// 用户拒绝授权
    case userAuthDeny           = 107

    /// 组织拒绝授权
    case organizationAuthDeny   = 108
    
    /// errno 使用，无实际意义
    case errno                  = 999

    public var errMsg: String {
        switch self {
        case .ok:
            return "ok"
        case .unknown:
            return "unknown error"
        case .unknownException:
            return "unknwon exception"
        case .internalError:
            return "internal error"
        case .unable:
            return "feature not support"
        case .invalidParam:
            return "invalid parameter"
        case .authenFail:
            return "authentication fail"
        case .systemAuthDeny:
            return "system permission denied"
        case .userAuthDeny:
            return "user permission denied"
        case .organizationAuthDeny:
            return "organization permission denied"
        case .errno:
            return "please check errno"
        }
    }

    /*
     以前的几个 CommonErrorCode，作为参考先保持 outerMsg 一致(如果业务没有专门设置过 outerMsg)，统一转换为 internal error
    case .userCancel:
        return "user cancel"
    case .networkError:
        return "network error"
    case .internalError:
        return "internal error"
    case .serverBizError:
        return "server business error"
    */
}

// 界面相关API(接口域为18)通用ErrorCode
public enum InterfaceCommonErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    //没有文件访问权限;
    case noFileAccessPermission = 1800202

    public var errMsg: String {
        switch self {
        case .noFileAccessPermission:
            return "no file access permission"
        }
    }
}

public enum GetDeviceIDErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// auth deny
    case authDeny = 41202

    public var errMsg: String {
        switch self {
        case .authDeny:
            return "no deviceID authorization"
        }
    }
}

public enum StartDeviceCredentialErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    //开放平台-设备-业务：用户未设置锁屏密码
    case passwordNotSet = 1107001

//    /// 开放平台-设备-业务：用户取消
//    case userCancel = 1107003

    /// 开放平台-设备-业务：authContent字段为空
    case authContentEmpty = 1107003

    /// 开放平台-设备-引擎(客户端)：解锁失败
    case unlockFail = 1107002

    public var errMsg: String {
        switch self {
        case .passwordNotSet:
            return "password not set"
        case .unlockFail:
            return "unlock fail"
        case .authContentEmpty:
            return "authContent is empty"
        }
    }
}

public enum GetConnectedWifiErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// 开放平台-设备-引擎(客户端): ssid不合法
    case invalidSsid = 1703201

    case wifiNotTurnedOn = 1703001

    public var errMsg: String {
        switch self {
        case .invalidSsid:
            return "invalidSSID"
        case .wifiNotTurnedOn:
            return "wifi not turned on"
        }
    }
}

public enum OpenschemaErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case openFailed = 1901201
    case notWhite = 1901301
    case illegalSchema = 1901001

    public var errMsg: String {
        switch self {
        case .openFailed:
            return "open failed"
        case .notWhite:
            return "not white"
        case .illegalSchema:
            return "illegal schema"
        }
    }
}

public enum OpenScanCodeErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case scanCodeRunning = 1710001

    public var errMsg: String {
        switch self {
        case .scanCodeRunning:
            return "scan already running"
        }
    }
}

public enum OpenStartPasswordVerifyErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// 业务：用户取消，验证失败
    case userCancel = 1110001
    /// 业务：密码错误，验证失败
    case passwordError = 1110301
    /// 密码输入次数超限制，验证失败
    case retryTimeLimit = 1110302

    public var errMsg: String {
        switch self {
        case .userCancel:
            return "user cancel"
        case .passwordError:
            return "password error"
        case .retryTimeLimit:
            return "retry time limit"
        }
    }
}

/// Bluetooth相关接口专用错误; 接口已统一APICode.
public enum BluetoothErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// 正常
    case ok = 0
    /// 未初始化蓝牙适配器
    case notInit = 10000
    /// 当前蓝牙适配器不可用
    case notAvailable = 10001
    /// 没有找到指定设备
    case noDevice = 10002
    /// 连接失败
    case connectionFail = 10003
    /// 没有找到指定服务
    case noService = 10004
    /// 没有找到指定特征值
    case noCharacteristic = 10005
    /// 当前连接已断开
    case noConnection = 10006
    /// 当前特征值不支持此操作
    case propertyNotSupport = 10007
    /// 其余所有系统上报的异常
    case systemError = 10008
    /// Android 系统特有，系统版本低于 4.3 不支持 BLE
    case systemNotSupport = 10009
    /// 没有找到指定描述符
    case descriptorNotFound = 10010
    /// 设备 ID 不可用，或为空
    case invalidDeviceId = 10011
    /// 服务 ID 不可用，或为空
    case invalidServiceId = 10012
    /// 特征 ID 不可用，或为空
    case invalidCharacteristicId = 10013
    /// 发送的数据为空或格式错误
    case invalidData = 10014
    /// 操作超时
    case operateTimeout = 100015
    /// 缺少参数
    case parametersNeeded = 100016
    /// 写入特征值失败
    case failedToWriteCharacteristic = 100017
    /// 读取特征值失败
    case failedToReadCharacteristic = 100018

    public var errMsg: String {
        switch self {
        case .ok:
            return "ok"
        case .notInit:
            return "not init"
        case .notAvailable:
            return "device not available"
        case .noDevice:
            return "device not found"
        case .connectionFail:
            return "connection failed"
        case .noService:
            return "service not found"
        case .noCharacteristic:
            return "characteristicId not found"
        case .noConnection:
            return "no connection"
        case .propertyNotSupport:
            return "operation not available on this characteristic"
        case .systemError:
            return "system error"
        case .systemNotSupport: // Android 系统特有，系统版本低于 4.3 不支持 BLE
            return "BLE not available on this device"
        case .operateTimeout:
            return "operate time out"
        case .invalidDeviceId:
            return "invalid deviceId"
        case .descriptorNotFound:
            return "descriptor not found"
        case .invalidServiceId:
            return "invalid serviceId"
        case .invalidCharacteristicId:
            return "invalid characteristicId"
        case .invalidData:
            return "invalid data"
        case .parametersNeeded:
            return "parameters needed"
        case .failedToWriteCharacteristic:
            return "failed to write characteristic"
        case .failedToReadCharacteristic:
            return "failed to read characteristic"
        }
    }
}

/// iBeacon相关接口专用错误; 接口已统一APICode.
public enum BeaconErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case unsupport = 1716201

    case alreadyStart = 1716202

    case notStartDiscovery = 1716203

    case locationUnavailable = 1716204

    case bluetoothUnavailable = 1716205

    public var errMsg: String {
        switch self {
        case .unsupport:
            return "unsupport"
        case .alreadyStart:
            return "already start"
        case .notStartDiscovery:
            return "not startBeaconDiscovery"
        case .locationUnavailable:
            return "location service unavailable"
        case .bluetoothUnavailable:
            return "bluetooth service unavailable"
        }
    }
}

public enum ReportAnalyticsErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case failed = 01011001100

    public var errMsg: String {
        switch self {
        case .failed:
            return "failed"
        }
    }
}

/// getEnvVariable接口专用错误; 接口已统一APICode.
public enum GetEnvVariableErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case getConfigFail = 1400209

    public var errMsg: String {
        switch self {
        case .getConfigFail:
            return "get config fail"
        }
    }
}

public enum GetShowModalTipInfoErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case failed = 01011004100

    public var errMsg: String {
        switch self {
        case .failed:
            return "failed"
        }
    }
}

public enum OpenOuterURLErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case failed = 01011005100

    public var errMsg: String {
        switch self {
        case .failed:
            return "failed"
        }
    }
}

public enum ShowShareMenuErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {

    case invalidType = 01011006100

    public var errMsg: String {
        switch self {
        case .invalidType:
            return "Invalid type"
        }
    }
}

/// updateBadge接口专用错误; 接口已统一APICode.
public enum UpdateBadgeErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {

    case nonexistentBadge = 1113201

    public var errMsg: String {
        switch self {
        case .nonexistentBadge:
            return "nonexistent badge"
        }
    }
}

/// reportBadge接口专用错误; 接口已统一APICode.
public enum ReportBadgeErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {

    case nonexistentBadge = 1113201

    public var errMsg: String {
        switch self {
        case .nonexistentBadge:
            return "nonexistent badge"
        }
    }
}

/// getTenantAppScopes接口专用错误; 接口已统一APICode.
public enum GetTenantAppScopesErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {

    /// app is not visible
    case notVisible = 1113202
    /// app is not installed
    case notInstalled = 1113203

    public var errMsg: String {
        switch self {
        case .notVisible:
            return "app is not visible"
        case .notInstalled:
            return "app is not installed"
        }
    }
}

public enum GetKAInfoErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {

    case appNotInOklist = 01011008200

    public var errMsg: String {
        switch self {
        case .appNotInOklist:
            return "app not in ok list"
        }
    }
}

public enum TabBarErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// no tabBar in the current app
    case noTab = 1800201

    public var errMsg: String {
        switch self {
        case .noTab:
            return "The current app does not contain a tabbar"
        }
    }
}

/// setTabBarItem接口专用错误; 接口已统一APICode.
public enum SetTabBarItemErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {

    /// icon path not found
    case iconNotFound = 1800202

    /// selected icon path not found
    case selectedIconNotFound = 1800203

    public var errMsg: String {
        switch self {
        case .iconNotFound:
            return "icon path not found"
        case .selectedIconNotFound:
            return "selected icon path not found"
        }
    }
}

/// 备注：小程序增加addTabBarItem的API，下面设置为三端统一错误码，但是iOS这里入参错误有统一错误码，因此部分没有用到的错误码先行注释
/// 新API调用接口处没有用到的error也先行注释掉
public enum AddTabBarItemErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// no tab
//    case noTab = 1800201
    
    /// api业务中model为空
    // case getNilModel = -10001

    /// api业务中的添加tab的page path为空
    case getNilPagePath = -10002

    /// api业务中的添加tab的page text为空
    // case getNilPageText = -10003

    /// api业务中的添加tab的light icon model为空
    // case getNilLightIconModel = -10004
    
    /// api业务中的添加tab的light icon path为空
    // case getNilLightIconPath = -10005
    
    /// api业务中的添加tab的light icon selected path为空
    // case getNilLightSelectedIconPath = -10006
    
    /// api业务中的添加tab的dark icon model为空
    // case getNilDarkIconModel = -10007
    
    /// api业务中的添加tab的dark icon path为空
    // case getNilDarkIconPath = -10008
    
    /// api业务中的添加tab的dark icon selected path为空
    // case getNilTabDarkSelectedIconPath = -10009
    
    /// 已有最多5个tab，无法添加
    // case atMost5TabsCanBeAdded = -10010
    
    /// 添加tabBarItem位置不合法
    // case indexToAddItemIsInvalid = -10011
    
    /// 添加的tabBarItem的pagePath存在重复
    // case pagePathAlreadyExists = -10012

    public var errMsg: String {
        switch self {
        // case .getNilModel:
        //     return "fatal error : no request"
        case .getNilPagePath:
            return "no page path"
        //case .getNilPageText:
        //     return "no page text"
        // case .getNilLightIconModel:
        //     return "no page lightIcon"
        // case .getNilLightIconPath:
        //     return "no page lightIcon iconPath"
        // case .getNilLightSelectedIconPath:
        //     return "no page lightIcon selectedIconPath"
        // case .getNilDarkIconModel:
        //     return "no page darkIcon"
        // case .getNilDarkIconPath:
        //     return "no page darkIcon iconPath"
        // case .getNilTabDarkSelectedIconPath:
        //     return "no page darkIcon selectedIconPath"
        // case .atMost5TabsCanBeAdded:
        //     return "at most 5 tabs should be remained"
        // case .indexToAddItemIsInvalid:
        //     return "index is invalid"
        // case .pagePathAlreadyExists:
        //     return "this tab already exists"
//        case .noTab:
//            return "The current app does not contain a tabbar"
        }
    }
    
}

/// callLightService接口专用错误; 接口已统一APICode.
public enum CallLightServiceErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// 轻服务调用错误
    case cloudServiceRequestFail = 1113301

    /// 资源不存在
    case resourceNotFound = 1113302

    public var errMsg: String {
        switch self {
        case .cloudServiceRequestFail:
            return "cloud service request fail"
        case .resourceNotFound:
            return "resource not found"
        }
    }
}

/// openDocument接口专用错误; 接口已统一APICode.  待删除
public enum OpenDocumentErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {

    /// 指定云空间文档，但传入的filePath不是合法的云空间文档地址
    case spaceFileInvalid = 1401001

    case noPermission = 1401002

    public var errMsg: String {
        switch self {
        case .spaceFileInvalid:
            return "spaceFile filePath does not support"
        case .noPermission:
            return "no access permission"
        }
    }
}

public enum ShowModalErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {

    case invalidModal = 01011262101

    public var errMsg: String {
        switch self {
        case .invalidModal:
            return "invalid modal"
        }
    }

}

public enum TriggerCheckUpdateErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {

    ///
    case getOnlineVersionFail = 42201

    ///
    case noNeedUpdate = 42202

    ///
    case installPackageFail = 42203

    public var errMsg: String {
        switch self {
        case .getOnlineVersionFail:
            return "get online version fail"
        case .noNeedUpdate:
            return "no need update"
        case .installPackageFail:
            return "install package fail"
        }
    }
}
/// admin disabled gps errMsg
private let adminDisabledGPSMessage = "admin disabled gps"
public enum GetLocationErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// unable access location
    case unableAccessLocation = 70101
    
    /// invalid latitude or longitude
    case invalidResult = 70102
    
    /// location fail
    case locationFail = 70103
    /// admin disabled gps
    case adminDisabledGPS = 1000001
    
    public var errMsg: String {
        switch self {
        case .unableAccessLocation:
            return "unable access location"
        case .invalidResult:
            return "invalid result"
        case .locationFail:
            return "location fail"
        case .adminDisabledGPS:
            return adminDisabledGPSMessage
        }
    }
}

/// openSetting接口专用错误; 接口已统一APICode.
public enum OpenSettingErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case alreadyOpen = 1103001

    public var errMsg: String {
        switch self {
        case .alreadyOpen:
            return "already open"
        }
    }
}


/// startLocationUpdate接口专用错误; 接口已统一APICode.
public enum StartLocationUpdateErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// location fail
    case locationFail = 1601201

    ///  admin disabled gps
    case adminDisabledGPS  = 1000001

    public var errMsg: String {
        switch self {
        case .locationFail:
            return "location fail"
        case .adminDisabledGPS:
            return adminDisabledGPSMessage
        }
    }
}

/// getWifiList接口专用错误; 接口已统一APICode.
public enum GetWifiListErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case wifiNotTurnOn = 1700001

    case gpsNotTurnOn = 1703001

    public var errMsg: String {
        switch self {
        case .wifiNotTurnOn:
            return "wifi not turned on"
        case .gpsNotTurnOn:
            return "gps not turned on"
        }
    }
}

/// enableAccelerometer接口专用错误; 接口已统一APICode.
public enum EnableAccelerometerErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    // 业务：不支持加速度计
    case notSupport = 1707001

    // 业务：加速度计已经开启了
    case alreadyRunning = 1707002

    public var errMsg: String {
        switch self {
        case .notSupport:
            return "not support"
        case .alreadyRunning:
            return "already running"
        }
    }
}

public enum GetRecorderManagerAPIErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// invalid operationType
    case typeInvalid = 30601

    public var errMsg: String {
        switch self {
        case .typeInvalid:
            return "Operation type is error"
        }
    }

}
/// 新版 Login接口专用错误 https://bytedance.feishu.cn/wiki/wikcn7Rp4Tg4KrLl2ZwfjKMxcdg
public enum OpenAPILoginErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case serverError = 1000001
    /// 更新 session 缓存失败
    case updateSessionFailed = 1000002
    public var errMsg: String {
        switch self {
        case .serverError: return "server error"
        case .updateSessionFailed: return "update session failed"
        }
    }
}

/// checkSession接口专用错误; 接口已统一APICode.
public enum CheckSessionErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case invalidSession = 1100201

    case serverError = 1100202

    case emptySession = 1100203

    public var errMsg: String {
        switch self {
        case .invalidSession:
            return "invalid session"
        case .serverError:
            return "server error"
        case .emptySession:
            return "session is empty"
        }
    }
}

/// getUserInfo接口专用错误; 接口已统一APICode.
public enum GetUserInfoErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case invalidSession = 1100201

    case getUserInfoFail = 1102301

    public var errMsg: String {
        switch self {
        case .invalidSession:
            return "invalid session "
        case .getUserInfoFail:
            return "get user info failed"
        }
    }
}

/// transferMessage接口专用错误; 接口已统一APICode.
public enum BDPWebComponentTrasferMsgErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case channelNotFound = 1109201
    case renderNotFound = 1109202
    case workerNotFound = 1109203
    case taskNotFound = 1109204

    public var errMsg: String {
        switch self {
        case .channelNotFound:
            return "channel not found"
        case .renderNotFound:
            return "render not found"
        case .workerNotFound:
            return "worker not found"
        case .taskNotFound:
            return "task not found"
        }
    }
}

// MARK: - 剪贴板相关 API 专用错误码
// getClipboardData
public enum OpenAPIGetClipboardDataErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    // 小程序在后台，禁止调用该 API ，该 code 三端已经对齐，该API后续三端一致时注意不要更改此 code
    case inovkeInBackground = 1000001

    public var errMsg: String {
        switch self {
        case .inovkeInBackground:
            return "the app is running in the background and cannot call the API."
        }
    }
}
// setClipboardData
public enum OpenAPISetClipboardDataErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    // 小程序在后台，禁止调用该 API ，该 code 三端已经对齐，该API后续三端一致时注意不要更改此 code
    case inovkeInBackground = 1000001

    public var errMsg: String {
        switch self {
        case .inovkeInBackground:
            return "the app is running in the background and cannot call the API."
        }
    }
}

// MARK: - share API 专用错误码
// share 接口专用API错误;接口已统一APICode
public enum OpenAPIShareErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    // Lark 不支持通过 wxsdk 分享到 wx
    case canNotShareToWX = 1000001
    // (contentType == text) && content为空
    case textIsEmpty = 1000002
    // (contentType == url）&& [(url为空) or (转URL类型得到空值)]
    case urlIsInvalid = 1000003
    // (contentType == url）&& (title为空)
    case titleIsInvalid = 1000004
    // (contentType == image) && image参数转uiimage失败（转换后为空值）
    case imageIsInvalid = 1000005
    // 用户取消分享，iOS 暂时不支持该 code，因为基建无此时机
    case cancelShare = 1000006
    // 分享失败
    case shareFailed = 1000007
    
    public var errMsg: String {
        switch self {
        case .canNotShareToWX:
            return "do not support share to wechat, try use system share"
        case .textIsEmpty:
            return "content is empty"
        case .urlIsInvalid:
            return "url is invalid"
        case .titleIsInvalid:
            return "title is empty"
        case .imageIsInvalid:
            return "image is invalid"
        case .cancelShare:
            return "user cancel operation"
        case .shareFailed:
            return "share failed"
        }
    }
}

// MARK: - 活体检测相关 API 专用错误码
// 活体检测相关接口专用API错误;接口已统一APICode
public enum FaceVerifyErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case internalError              =     -1            //内部错误
    case networkError               =     -1000         //网络错误
    case unknownError               =     -1001         //未知错误
    case interrupt                  =     -1002         //活体中断，未出现活体页面用户就点击取消了
    case fail                       =     -1003         //活体识别失败
    case algorithmInitFail          =     -1004         //算法初始化失败
    case algorithmParamSettingError =     -1005         //算法参数设置失败
    case pageBack                   =     -1006         //用户取消操作
    case selectImageCancel          =     -1007         //点击取消，弹框取消
    case requestParamInvalid        =     -2000         //比对底图为空
    case cameraSaveNoPermission     =     -3000         //没有相机或存储权限
    case jsonParseFail              =     -3001         //json解析失败
    case unsupportMultiScreen       =     -3002         //不支持多屏模式
    case cameraNotSupport           =     -3003         //无法使用相机，请检查是否打开相机权限
    case missionSettingError        =     -3004         //活体设置任务失败
    case getPhotoFail               =     -3005         //相册图片获取失败
    case takePhotoFail              =     -3006         //拍照失败：拍照完成后拿到的图片是空的
    case resourceDownloadFail       =     -5000         //资源文件下载失败
    case resourceNotDownload        =     -5003         //离线下载目录不存在
    case resourceNotExist           =     -5004         //离线模型文件不存在
    case md5CheckFail               =     -5005         //离线模型校验失败
    case resourceUpdate             =     -5006         //资源文件需要更新
    case silenceInitFail            =     -5010         //静默活体初始化失败
    case silenceNotPass             =     -5011         //静默活体未通过
    case livenessVerifyInitFail     =     -5020         //人脸比对初始化失败
    case checkNotPass               =     -5021         //人脸比对未通过
    case readBaseImageFail          =     9001          //基准图读取失败
    case resourceDownloadTimeout    =     9002          //资源文件下载超时

    public var errMsg: String {
        switch self {
        case .internalError:
            return "internal error"
        case .networkError:
            return "network error"
        case .unknownError:
            return "unknown error"
        case .interrupt:
            return "interrupt"
        case .fail:
            return "fail"
        case .algorithmInitFail:
            return "algorithm init fail"
        case .algorithmParamSettingError:
            return "algorithm param setting error"
        case .pageBack:
            return "page back"
        case .selectImageCancel:
            return "select image cancel"
        case .requestParamInvalid:
            return "request param invalid"
        case .cameraSaveNoPermission:
            return "camera save no permission"
        case .jsonParseFail:
            return "json parse fail"
        case .unsupportMultiScreen:
            return "unsupport multi screen"
        case .cameraNotSupport:
            return "camera not support"
        case .missionSettingError:
            return "mission setting error"
        case .getPhotoFail:
            return "get photo fail"
        case .takePhotoFail:
            return "take photo fail"
        case .resourceDownloadFail:
            return "resource download fail"
        case .resourceNotDownload:
            return "resource not download"
        case .resourceNotExist:
            return "resource not exist"
        case .md5CheckFail:
            return "md5 check fail"
        case .resourceUpdate:
            return "resource update"
        case .silenceInitFail:
            return "silence init fail"
        case .silenceNotPass:
            return "silence not pass"
        case .livenessVerifyInitFail:
            return "liveness verify init fail"
        case .checkNotPass:
            return "check not pass"
        case .readBaseImageFail:
            return "read base image fail"
        case .resourceDownloadTimeout:
            return "resource download timeout"
        }
    }
}
// MARK: - saveImageToPhotosAlbum API 专用错误码
/// saveImageToPhotosAlbum口专用错误
/// 接口已统一 APICode (Android + iOS，PC 端该 API 的 error code 预期需要与 saveFile 对齐，【三端一致】专项PC同学： liaowenjiang.99@bytedance.com). 
public enum OpenAPISaveImageToPhotosAlbumErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// 非本地沙箱路径
    case invilidFilePath = 1000001
    /// 无读权限
    case readPermissionDenied = 1000002
    /// 不是一个文件
    case notFile = 1000003
    /// 文件不存在
    case fileNotExist = 1000004
    /// 加解密禁用操作
    case securityPermissionDenied = 1000005
    /// 传入路径文件不是图片
    case notImage = 1000006
    /// 添加系统相册失败
    case saveToSystemAlbumFailed = 1000007
    
    public var errMsg: String {
        switch self {
        case .invilidFilePath:
            return "filePath invalid."
        case .readPermissionDenied:
            return "read permission denied."
        case .notFile:
            return "not a regular file."
        case .fileNotExist:
            return "file not exists."
        case .securityPermissionDenied:
            return "security permission denied."
        case .notImage:
            return "file is not image."
        case .saveToSystemAlbumFailed:
            return "save failed."
        }
    }
}

// MARK: - openDocument API 专用错误码
public enum OpenAPIOpenDocumentErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// 非飞书云文档
    case notCloudFile = 1000001
    /// 非本地沙箱路径
    case invilidFilePath = 1000002
    /// 无读权限
    case readPermissionDenied = 1000003
    /// 文件不存在
    case fileNotExist = 1000004
    /// 不是一个文件
    case notFile = 1000005
    /// 主进程服务挂掉 - iOS 没有该 code，为了与 Android / PC 对齐，写在这里
    case mainThreadDead = 1000006
    
    public var errMsg: String {
        switch self {
        case .notCloudFile:
            return "filePath of cloudFile not support."
        case .invilidFilePath:
            return "filePath invalid."
        case .readPermissionDenied:
            return "read permission denied."
        case .fileNotExist:
            return "file not exists."
        case .notFile:
            return "not a regular file."
        case .mainThreadDead:
            return "internal service error."
        }
    }
}


// MARK: - Storage API 专用错误码
// setStorage(Sync)接口专用API错误;接口已统一APICode
public enum OpenAPISetStorageErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {

    case valueSizeExceedLimit = 1000001
    case totalStorageExceedLimit = 1000002

    public var errMsg: String {
        switch self {
        case .valueSizeExceedLimit:
            return "data size exceeds the limit."
        case .totalStorageExceedLimit:
            return "total storage size exceeds the limit."
        }
    }
}
// getStorage(Sync)接口专用API错误;接口已统一APICode
public enum OpenAPIGetStorageErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {

    case emptyValue = 1000003

    public var errMsg: String {
        switch self {
        case .emptyValue:
            return "not found"
        }
    }
}

// MARK: - getImageInfo API 专用错误码
public enum OpenAPIGetImageInfoErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// 非本地沙箱路径
    case invalidFilePath = 1000001
    /// 无读权限
    case readPermissionDenied = 1000002
    /// 不是一个文件
    case notFile = 1000003
    /// 文件不存在
    case fileNotExist = 1000004
    /// 图像尺寸异常
    case imageSizeIllegal = 1000005
    /// 转UIImage失败 [iOS]
    case formatImageDataFail = 1000006
    
    public var errMsg: String {
        switch self {
        case .invalidFilePath:
            return "filePath invalid."
        case .readPermissionDenied:
            return "read permission denied."
        case .notFile:
            return "not a regular file."
        case .fileNotExist:
            return "file not exists."
        case .imageSizeIllegal:
            return "image size illegal."
        case .formatImageDataFail:
            return "reformat image data fail."
        }
    }
}

// MARK: - FileSystem
/// 文件系统错误，接口已统一APICode
public enum OpenAPIFileSystemErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    /// 文件无读权限
    case readPermissionDenied = 1400001

    /// 文件无写权限
    case writePermissionDenied = 1400002

    /// 文件不存在
    case fileNotExists = 1400003

    /// 文件已存在
    case fileAlreadyExists = 1400004

    /// 文件夹非空
    case directoryNotEmpty = 1400005

    /// 不是文件夹
    case fileIsNotDirectory = 1400006

    /// 不是文件
    case fileIsNotRegularFile = 1400007

    /// 写入大小限制
    case totalSizeLimitExceeded = 1400008

    /// 不能同时操作路径和它的子路径
    case cannotOperatePathAndSubPathAtTheSameTime = 1400009

    /// 读取的文件内容大小超过阈值
    case readDataExceedsSizeLimit = 1400010

    /// 加解密禁用操作
    case securityPermissionDenied = 1400011

    public var errMsg: String {
        switch self {
        case .readPermissionDenied:
            return "read permission denied"
        case .writePermissionDenied:
            return "write permission denied"
        case .fileNotExists:
            return "file not exists"
        case .fileAlreadyExists:
            return "file already exists"
        case .directoryNotEmpty:
            return "directory not empty"
        case .fileIsNotDirectory:
            return "file is not directory"
        case .fileIsNotRegularFile:
            return "file is not regular file"
        case .totalSizeLimitExceeded:
            return "total size limit exceeded"
        case .cannotOperatePathAndSubPathAtTheSameTime:
            return "cannot operate path and subpath at the same time"
        case .readDataExceedsSizeLimit:
            return "read data exceeds size limit"
        case .securityPermissionDenied:
            return "security permission denied"
        }
    }
}

public enum FullScreenIpadErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {

    case notSupportScaleMode = 1800301

    public var errMsg: String {
        switch self {
        case .notSupportScaleMode:
            return "not support this scale mode"
        }
    }
}

/// 计步API专用错误码
public enum GetStepCountErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case notAvailable = 1717201

    case alreadyStart = 1717202

    public var errMsg: String {
        switch self {
        case .notAvailable:
            return "step count not available"
        case .alreadyStart:
            return "already start"
        }
    }
}

/// 评分API专用错误码
public enum GetAppReviewErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case reviewFail = 1000001

    case tooFrequency = 1000002
    
    case featureNotSupport = 103

    public var errMsg: String {
        switch self {
        case .reviewFail:
            return "request app review fail"
        case .tooFrequency:
            return "request app review too frequency"
        case .featureNotSupport:
            return "feature not support"
        }
    }
}

/// 网络 API 专用错误码
public enum NetworkAPIErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case cancelled = 1000001
    case timeout = 1000002
    case offilne = 1000003
    // 特指 rust 的 lib-net 错误
    case networkSDKError = 1000004
    case networkFail = 1000005
    case downloadFail = 1000006
    
    // 文件错误
    /// 非法文件路径
    case invalidFilePath = 1000101
    /// 无权限
    case permissionDenied = 1000102
    /// 创建用于写入的文件失败
    case createFileFail = 1000103
    /// 写入文件失败
    case writeFileFail = 1000104
    /// 文件夹或文件找不到
    case fileNotExists = 1000105
    /// 超出可写入大小
    case sizeLimit = 1000106
    
    public var errMsg: String {
        switch self {
        case .cancelled: return "Cancelled"
        case .timeout: return "Timeout"
        case .offilne: return "Offline"
        case .networkSDKError: return "Network sdk error"
        case .networkFail: return "Network fail"
        case .invalidFilePath: return "Invalid filePath"
        case .permissionDenied: return "Permission denied"
        case .createFileFail: return "Create file error"
        case .writeFileFail: return "Write file error"
        case .fileNotExists: return "No such file or directory"
        case .sizeLimit: return "Saved file size limit exceeded"
        case .downloadFail: return "Download fail"
        }
    }
}

/// 插件加载专用错误码
/// loadPlugin
public enum LoadPluginError: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {

    // 插件的meta/pkg下载失败
    case downloadFailed = 1000201

    // 插件不存在
    case pluginNotExist = 1000202

    // 无法查找到对应page
    case pageNotFound = 1000203

    // 加载插件失败
    case loadPluginFailed = 1000204

    // 插件没有可见性. (后端返回10252错误码)
    case notVisible = 1000205

    // 插件ID非法 (后端返回10200错误码)
    case invalidPluginId = 1000206

    // 插件ID合法,但version不正确 (后端返回10253错误码)
    case invalidPluginVersion = 1000207

    public var errMsg: String {
        switch self {
        case .downloadFailed:
            return "plugin download failed"
        case .pluginNotExist:
            return "plugin not exist"
        case .pageNotFound:
            return "page is not found"
        case .loadPluginFailed:
            return "load plugin failed"
        case .notVisible:
            return "no permission for plugin"
        case .invalidPluginId:
            return "invalid plugin ID"
        case .invalidPluginVersion:
            return "invalid plugin version"
        }
    }
}

/// 人脸采集专用错误码
/// acquireFaceImage
public enum AcquireFaceImageErrorCode: Int, OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    case internalError              =     -1
    case unknownError               =     -1001
    case pageBack                   =     -1006//用户取消
    case cameraNotSupport           =     -3003//无相机权限

    public var errMsg: String {
        switch self {
        case .internalError:
            return "internal error"
        case .unknownError:
            return "unknown error"
        case .pageBack:
            return "page back"
        case .cameraNotSupport:
            return "camera not support"
        }
    }
    
}

//消息卡片发送专用错误码
//错误码来源https://open.feishu.cn/document/uYjL24iN/uUjN5UjL1YTO14SN2kTN
public enum MessageCardSendErrorCode: Int,OpenAPIErrorCodeProtocol, _OpenAPIErrorCodeProtocol {
    // 用户取消
    case userCancel = -6
    // 其他类型错误暂未处理
    public var errMsg: String {
        switch self {
        case .userCancel:
            return "user cancel"
        }
    }
}
