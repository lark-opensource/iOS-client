//
//  StablePushManager.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/7/1.
//

import Foundation
import SwiftyJSON
import SKFoundation
import RxSwift
import SpaceInterface

// 信箱 tag 文档：https://bytedance.feishu.cn/docs/doccnTEglIr2ff1tluA0Ql
public enum StablePushPrefix: String {
    case permission = "PERMISSION_CHANGE_"
    case convertFile = "PARSE_FILE_"
    case previewGet = "DRIVE_PREVIEW_EVENT_"
    case wikiTree = "WIKI_TREE_"
    case like = "LIKE_"
    case notice = "NOTICE_"
    case sdkFile = "DRIVE_SDK_FILE_"
    case todo = "TODO_NOTICE_"
    case bulletin = "BULLETIN_"
    case thirdEvent = "DRIVE_THIRD_EVENT_"

    public static func notice(type: DocsType, token: String) -> String {
        return "\(Self.notice.rawValue)\(type.rawValue)_\(token)"
    }

    public func resourceType() -> String {
        let rawStr: String = self.rawValue
        guard rawStr.count > 0 else {
            spaceAssertionFailure("错误sourceType, 请抛出")
            return ""
        }
        let lastCap = rawStr.suffix(1)
        if lastCap == "_" {
            return String(rawStr.dropLast(1))
        } else {
            spaceAssertionFailure("错误sourceType, 请抛出")
            return rawStr
        }
    }
}

public struct SKPushInfo {
    let tag: String
    let resourceType: String
    let routeKey: String
    let routeType: SKPushRouteType

    public init(tag: String, resourceType: String, routeKey: String, routeType: SKPushRouteType) {
        self.tag = tag
        self.resourceType = resourceType
        self.routeKey = routeKey
        self.routeType = routeType
    }
}

public enum SKPushRouteType: String {
    case token
    case id
    case uid
    case unit
}

public enum StablePushServiceType: String {
    case permission = "DRIVE_RELIABLE_PERMISSION_CHANGE"
    case convertFile = "DRIVE_RELIABLE_FILE_CONVERTI_RESULT"
}

public protocol StablePushManagerDelegate: AnyObject {
    func stablePushManager(_ manager: StablePushManagerProtocol,
                           didReceivedData data: [String: Any],
                           forServiceType type: String,
                           andTag tag: String)
    var pushFileToken: String? { get }
    var pushFileType: Int? { get }
}

extension StablePushManagerDelegate {
    public var pushFileToken: String? { return nil }
    public var pushFileType: Int? { return nil }
}

public protocol StablePushManagerProtocol {
    func register(with handler: StablePushManagerDelegate)
    func unRegister()
}

public final class StablePushManager: StablePushManagerProtocol {
    let pushInfo: SKPushInfo
    let additionParams: [String: Any]?
    weak var delegate: StablePushManagerDelegate?
    public init(pushInfo: SKPushInfo, additionParams: [String: Any]? = nil) {
        self.pushInfo = pushInfo
        self.additionParams = additionParams
    }
    public func register(with handler: StablePushManagerDelegate) {
        delegate = handler
        var body: [String: Any] = ["tag": pushInfo.tag,
                                   "route_key": pushInfo.routeKey,
                                   "route_type": pushInfo.routeType.rawValue,
                                   "resource_type": pushInfo.resourceType,
                                   "type": "registerList",
                                   "serviceType": pushInfo.tag]
        if let additionParams = self.additionParams {
            body.merge(other: additionParams)
        }
        let data: [String: Any] = ["operation": "pushList",
                                   "body": body]
        let composedData: [String: Any] = ["business": "base",
                                           "data": data]
        RNManager.manager.sendSpaceBusnessToRN(data: composedData)
        RNManager.manager.registerRnEvent(eventNames: [.base], handler: self)
    }
    public func unRegister() {
        let body = ["tag": pushInfo.tag,
                    "route_key": pushInfo.routeKey,
                    "route_type": pushInfo.routeType.rawValue,
                    "resource_type": pushInfo.resourceType,
                    "type": "unRegisterList"]
        let data: [String: Any] = ["operation": "pushList",
                                   "body": body]
        let composedData: [String: Any] = ["business": "base",
                                           "data": data]
        RNManager.manager.sendSpaceBusnessToRN(data: composedData)
    }
}

extension StablePushManager: RNMessageDelegate {
    public func didReceivedRNData(data: [String: Any], eventName: RNManager.RNEventName) {
        guard eventName == .base,
            let serviceType = JSON(data)["operation"].string,
              serviceType == self.pushInfo.tag
            else { return }
        delegate?.stablePushManager(self,
                                    didReceivedData: data,
                                    forServiceType: serviceType,
                                    andTag: serviceType)
    }

    public func compareIdentifierEquality(identifier: [String: Any]) -> Bool {
        guard let token = identifier["token"] as? String,
            let type = identifier["type"] as? Int else {
            spaceAssertionFailure("missing essential value in identifier")
            return false
        }
        if let fileToeken = delegate?.pushFileToken,
            let fileType = delegate?.pushFileType {
            return token == fileToeken && fileType == type
        }
        return true
    }
}

extension StablePushManager: ReactiveCompatible {}

//extension Reactive where Base: StablePushManager {
//
//    private class ClosureDelegate: StablePushManagerDelegate {
//
//        private var handler: (_ data: [String: Any], _ serviceType: String, _ tag: String) -> Void
//
//        init(handler: @escaping (_ data: [String: Any], _ serviceType: String, _ tag: String) -> Void) {
//            self.handler = handler
//            DocsLogger.info("StablePushManager ClosureDelegate init")
//        }
//
//        deinit {
//            DocsLogger.info("StablePushManager ClosureDelegate deinit")
//        }
//
//        func unregister() {
//            handler = { _, _, _ in }
//        }
//
//        func stablePushManager(_ manager: StablePushManager,
//                               didReceivedData data: [String: Any],
//                               forServiceType type: String,
//                               andTag tag: String) {
//            handler(data, type, tag)
//        }
//    }
//}
