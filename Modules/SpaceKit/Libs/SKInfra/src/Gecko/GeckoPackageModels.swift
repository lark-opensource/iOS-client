//
//  GeckoPackageModels.swift
//  SpaceKit
//
//  Created by Webster on 2018/11/21.
//

import Foundation

// 提供setdeviceid的接口
// channel名和初始化路径 改成字典
// 资源替换逻辑更新

public enum GeckoChannleType: Int {
    case webInfo = 0 // 支撑doc web view 的一些js, css等
    case bitable = 1 // bitable
    case unitTest = 1000
//    case undefine1 = 1001  //备用1
//    case undefine2 = 1002  //备用2

    func channelName() -> String {
        switch self {
        case .webInfo:
            return "docs_offlineRN"
        case .bitable:
            return "bitable"
        case .unitTest:
            return "unitTest"
//        default:
//            return "unknow"
        }
    }

    func identifier() -> String {
        switch self {
        case .webInfo:
            return "docs_webinfo"
        case .bitable:
            return "docs_bitable"
        case .unitTest:
            return "docs_unittest"
//        default:
//            return "unknow"
        }
    }
}


/// 不同的APP，传入的channel值不一样,对应DocsChannelInfo中的name字段
/// 套件：docs_channel
/// 单品：docs_app
public enum GeckoPackageAppChannel: String {
    //swiftlint:disable identifier_name
    case unknown
    case docs_channel // 套件（飞书App）
    case docs_app     // 单品（飞书文档App）
}

public typealias FEResourcePkgInfo = (simpleVersion: String, fullPkgVersion: String, isFullPkgReady: Bool)

//（channel类型， channel名， 初始化资源的路径）
public typealias DocsChannelInfo = (type: GeckoChannleType, name: String, path: String, zipName: String)

public struct GeckoInitConfig {
    let channels: [DocsChannelInfo]
    public let deviceId: String?
    let shouldSetUp: Bool
    public var appVersion: String?
    public init(channels: [DocsChannelInfo], deviceId: String?, setUp: Bool = false) {
        self.channels = channels
        self.deviceId = deviceId
        self.shouldSetUp = setUp
    }
}

struct GeckoPathBase {
    var frameWorkName: String?
    var bundleName: String?
    var path: String = String()

    static func pathWithString(pathInfo: String) -> GeckoPathBase {
        let infos = pathInfo.components(separatedBy: "/")
        var pathBase = GeckoPathBase()
        guard infos.count > 2 else {
            return pathBase
        }
        pathBase.frameWorkName = infos[0]
        pathBase.bundleName = infos[1]

        for index in 2..<infos.count {
            pathBase.path += "/"
            pathBase.path += infos[index]
        }

        return pathBase
    }

}

public protocol GeckoEventListener {
    func packageWillUpdate(_ gecko: GeckoPackageManager?, in channel: GeckoChannleType)
    func packageDidUpdate(_ gecko: GeckoPackageManager?, in channel: GeckoChannleType, isSuccess: Bool, needReloadRN: Bool)

}
