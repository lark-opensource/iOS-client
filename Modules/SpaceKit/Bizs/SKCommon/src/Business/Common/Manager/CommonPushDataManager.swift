//
//  DriveCommonPushManager.swift
//  SpaceKit
//
//  Created by bupozhuang on 2019/6/17.
//

import SKFoundation
import SpaceInterface

class CommonPushSendOperation {
    static let beginSync = "beginSync"  //通知RN开始建立长链
    static let endSync = "endSync"      //通知RN结束长链
}
// 通用推送operation
public enum CommonPushReceiveOperation: String {
    case driveCommonPushChannel         // drive推送
    case groupChange                    // Wiki变更、群变更
}

public protocol CommonPushDataDelegate: AnyObject {
    func didReceiveData(response: [String: Any])
}

public final class CommonPushDataManager {
    private let fileToken: String
    private let fileType: DocsType
    private let operation: CommonPushReceiveOperation
    public weak var delegate: CommonPushDataDelegate?
    /// 记录endSync标志，防止重复
    var hasEndSync = false
    public init(fileToken: String, type: DocsType, operation: CommonPushReceiveOperation) {
        self.fileToken = fileToken
        self.fileType = type
        self.operation = operation
    }

    deinit {
        guard hasEndSync == false else {
            DocsLogger.info("CommonPushDataManager deinit return, file: \(DocsTracker.encrypt(id: fileToken))")
            return
        }
        DocsLogger.info("[common sync] CommonPushDataManager - endSync, file: \(DocsTracker.encrypt(id: fileToken))")
        sendToRN(operationKey: CommonPushSendOperation.endSync)
    }

    public func register() {
        hasEndSync = false
        RNManager.manager.registerRnEvent(eventNames: [.common], handler: self)
        sendToRN(operationKey: CommonPushSendOperation.beginSync)
        DocsLogger.info("[common sync] CommonPushDataManager - beginSync, file: \(DocsTracker.encrypt(id: fileToken))")
    }
    
    public func unRegister() {
        hasEndSync = true
        DocsLogger.info("[common sync] CommonPushDataManager - endSync, file: \(DocsTracker.encrypt(id: fileToken))")
        sendToRN(operationKey: CommonPushSendOperation.endSync)
    }
    
    public func sendToRN(bodyData: [String: Any]? = nil, operationKey: String) {
        var data: [String: Any] = ["operation": operationKey,
                                   "identifier": ["token": fileToken, "type": fileType.rawValue]]
        if let bodyData = bodyData {
            data["body"] = bodyData
        }
        let composedData: [String: Any] = ["business": "common",
                                           "data": data]
        RNManager.manager.sendSpaceBusnessToRN(data: composedData)
    }
}

extension CommonPushDataManager: RNMessageDelegate {
    public func compareIdentifierEquality(identifier: [String: Any]) -> Bool {
        guard let token = identifier["token"] as? String, let type = identifier["type"] as? Int else { spaceAssertionFailure("missing essential value in identifier"); return false }
        return token == fileToken && type == fileType.rawValue
    }

    public func didReceivedRNData(data: [String: Any], eventName: RNManager.RNEventName) {
        guard let operation = data["operation"] as? String,
            let body = data["body"] as? [String: Any],
            let operationType = CommonPushReceiveOperation(rawValue: operation) else {
                return
        }
        guard let bodyData = body["data"] as? [String: Any] else {
            spaceAssertionFailure("missing data")
            return
        }
        guard let identifierData = data["identifier"] as? [String: Any] else {
            spaceAssertionFailure("missing identifier")
            return
        }
        guard compareIdentifierEquality(identifier: identifierData) else {
            DocsLogger.info("这个 identifier: \(identifier ?? [:]) 不是我关心的")
            return
        }

        if operationType == self.operation {
            delegate?.didReceiveData(response: bodyData)
        }
    }
}
