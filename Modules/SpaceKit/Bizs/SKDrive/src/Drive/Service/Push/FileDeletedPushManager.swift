//
//  FileDeletedPushManager.swift
//  SKCommon
//
//  Created by Weston Wu on 2021/5/17.
//

import Foundation
import SKFoundation
import RxSwift
import SKCommon
import SpaceInterface

public protocol FileDeletedPushDelegate: AnyObject {
    func fileDidDeleted()
}

public final class FileDeletedPushManager {
    private let fileToken: String
    private let type: DocsType
    private let pushManager: StablePushManager

    public weak var delegate: FileDeletedPushDelegate?

    public init(fileToken: String, type: DocsType) {
        self.fileToken = fileToken
        self.type = type
        let tag = StablePushPrefix.notice(type: type, token: fileToken)
        let params: [String: Any] = ["subtype": "DELETE"]
        let pushInfo = SKPushInfo(tag: tag,
                                  resourceType: StablePushPrefix.notice.resourceType(),
                                  routeKey: fileToken,
                                  routeType: SKPushRouteType.token)
        pushManager = StablePushManager(pushInfo: pushInfo, additionParams: params)
    }

    deinit {
        pushManager.unRegister()
    }

    public func start(with delegate: FileDeletedPushDelegate?) {
        self.delegate = delegate
        pushManager.register(with: self)
    }
}

extension FileDeletedPushManager: StablePushManagerDelegate {
    public func stablePushManager(_ manager: StablePushManagerProtocol, didReceivedData data: [String: Any], forServiceType type: String, andTag tag: String) {
        if isUpdateSecNotice(noticeData: data) { return }
        delegate?.fileDidDeleted()
    }
    private func isUpdateSecNotice(noticeData: [String: Any]) -> Bool {
        guard let body = noticeData["body"] as? [String: Any],
              let data = body["data"] as? String, data.contains("update_sec") else {
            return false
        }
        return true
    }
}

extension FileDeletedPushManager: ReactiveCompatible {}
