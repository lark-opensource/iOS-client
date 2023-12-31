//
//  FileSecretPushManager.swift
//  SKCommon
//
//

import Foundation
import SKFoundation
import RxSwift
import SKCommon
import SpaceInterface

public protocol FileSecretPushDelegate: AnyObject {
    func secretDidChanged(token: String, type: Int)
}

public final class FileSecretPushManager {
    private let fileToken: String
    private let type: DocsType
    private let pushManager: StablePushManager

    public weak var delegate: FileSecretPushDelegate?

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

    public func start(with delegate: FileSecretPushDelegate?) {
        self.delegate = delegate
        pushManager.register(with: self)
    }
}

extension FileSecretPushManager: StablePushManagerDelegate {
    public func stablePushManager(_ manager: StablePushManagerProtocol, didReceivedData data: [String: Any], forServiceType type: String, andTag tag: String) {
        guard isUpdateSecNotice(noticeData: data) else { return }
        delegate?.secretDidChanged(token: self.fileToken, type: self.type.rawValue)
    }
    private func isUpdateSecNotice(noticeData: [String: Any]) -> Bool {
        guard let body = noticeData["body"] as? [String: Any],
              let data = body["data"] as? String, data.contains("update_sec") else {
            return false
        }
        return true
    }
}

extension FileSecretPushManager: ReactiveCompatible {}
