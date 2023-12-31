//
//  VersionDataMananger.swift
//  SpaceKit
//
//  Created by zhongtianren on 2019/4/26.
//

import UIKit
import SKFoundation
import SpaceInterface

public protocol VersionDataDelegate: AnyObject {
    func didReceiveVersion(version: String, type: VersionDataMananger.VersionReceiveOperation)
}

public final class VersionSendOperation {
    static let beginSync = "beginSync" //通知RN开始建立长链
    static let endSync = "endSync" //通知RN结束长链
}

public final class VersionDataMananger {
    public enum VersionReceiveOperation: String {
        case versionDidUpdate //主动通知文件版本更新
        case versionDidDelete //主动通知文件有历史版本删除
    }
    let fileToken: String
    let fileType: DocsType
    public weak var delegate: VersionDataDelegate?
    public init(fileToken: String, type: DocsType) {
        self.fileToken = fileToken
        self.fileType = type
        RNManager.manager.registerRnEvent(eventNames: [.version], handler: self)
        DocsLogger.info("VersionDataMananger - beginSync, file: \(DocsTracker.encrypt(id: fileToken))")
        sendToRN(operationKey: VersionSendOperation.beginSync)
    }

    deinit {
        DocsLogger.info("VersionDataMananger - endSync, file: \(DocsTracker.encrypt(id: fileToken))")
        sendToRN(operationKey: VersionSendOperation.endSync)
    }

    func sendToRN(bodyData: [String: Any]? = nil, operationKey: String) {
        var data: [String: Any] = ["operation": operationKey,
                                   "identifier": ["token": fileToken, "type": fileType.rawValue]]
        if let bodyData = bodyData {
            data["body"] = bodyData
        }
        let composedData: [String: Any] = ["business": "version",
                                           "data": data]
        RNManager.manager.sendSpaceBusnessToRN(data: composedData)
    }
}

extension VersionDataMananger: RNMessageDelegate {
    public func compareIdentifierEquality(identifier: [String: Any]) -> Bool {
        guard let token = identifier["token"] as? String, let type = identifier["type"] as? Int else { spaceAssertionFailure("missing essential value in identifier"); return false }
        return token == fileToken && type == fileType.rawValue
    }

    public func didReceivedRNData(data: [String: Any], eventName: RNManager.RNEventName) {
        guard let operation = data["operation"] as? String,
            let body = data["body"] as? [String: Any],
            let operationType = VersionReceiveOperation(rawValue: operation)
            else { spaceAssertionFailure("no operation in data"); return }

        guard let bodyData = body["data"] as? [String: Any], let version = bodyData["version"] as? String else { spaceAssertionFailure("missing version"); return }

        delegate?.didReceiveVersion(version: version, type: operationType)
    }
}
