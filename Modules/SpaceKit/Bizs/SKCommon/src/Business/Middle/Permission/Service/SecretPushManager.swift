//
//  SecretPushManager.swift
//  SKCommon
//
//

import Foundation
import SKFoundation
import RxSwift
import SpaceInterface

public protocol SecretPushDelegate: AnyObject {
    func secretDidChanged(token: String, type: Int)
}

public final class SecretPushManager {
    private let fileToken: String
    private let type: DocsType
    private let pushManager: StablePushManager

    public weak var delegate: SecretPushDelegate?

    public init(fileToken: String, type: DocsType) {
        self.fileToken = fileToken
        self.type = type
        let tag = StablePushPrefix.notice(type: type, token: fileToken)
        let params: [String: Any] = ["subtype": "SEC_UPDATE"]
        let pushInfo = SKPushInfo(tag: tag,
                                  resourceType: StablePushPrefix.notice.resourceType(),
                                  routeKey: fileToken,
                                  routeType: SKPushRouteType.token)
        pushManager = StablePushManager(pushInfo: pushInfo, additionParams: params)
    }

    deinit {
        pushManager.unRegister()
    }

    public func start(with delegate: SecretPushDelegate?) {
        self.delegate = delegate
        pushManager.register(with: self)
    }
}

extension SecretPushManager: StablePushManagerDelegate {
    public func stablePushManager(_ manager: StablePushManagerProtocol, didReceivedData data: [String: Any], forServiceType type: String, andTag tag: String) {
        delegate?.secretDidChanged(token: self.fileToken, type: self.type.rawValue)
    }
}

extension SecretPushManager: ReactiveCompatible {}
