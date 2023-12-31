//
//  RNCommonDataManager .swift
//  SpaceKit
//
//  Created by xurunkang on 2019/6/17.
//  

import SKFoundation
import HandyJSON
import SpaceInterface

public enum CommonSendOperation: String {
    case beginSync  //通知RN开始建立长链
    case endSync    //通知RN结束长链

    case getReactionDetail // 获取完整 reaction 详情
    case addReaction // 增加表情
    case setReactionDetailPanelStatus // 设置详情面板状态
    case removeReaction // 删除表情
}

enum CommonReceiveOperation: String {
    case response
}

// 这个类用来处理Reaction交互

public final class RNCommonDataManager {
    
    /// rn reaction body
    public struct Reaction {
        
        public let referType: String?
        public let referKey: String?
        public let reactionKey: String?
        public var status: Int?
        public var replyId: String?
        
        public init(referType: String?, referKey: String?, reactionKey: String?, status: Int? = nil, replyId: String? = nil) {
            self.referType = referType
            self.referKey = referKey
            self.reactionKey = reactionKey
            self.status = status
            self.replyId = replyId
        }
    }
    
    public enum Business: String {
        case comment
        case common
    }
    
    let fileToken: String
    let fileType: Int
    let extraId: String //长链特别标识，因为ipad上有多webview打开相同文档的情况，所以增加一个extra标识
    public typealias ResponseCallback = (ReactionCacllBackData) -> Void
    private var callbackDic = [String: ResponseCallback]()
    private let serialQueue = DispatchQueue(label: "com.bytedance.net.RNCommonDataManager")


    public init(fileToken: String, type: Int, extraId: String? = nil) {
        self.fileToken = fileToken
        self.fileType = type
        self.extraId = extraId ?? ""
        RNManager.manager.registerRnEvent(eventNames: [.comment], handler: self)
        sendToRN(bodyData: nil, operationKey: CommonSendOperation.beginSync.rawValue, requestId: nil, business: .common)
    }

    deinit {
        sendToRN(bodyData: nil, operationKey: CommonSendOperation.endSync.rawValue, requestId: nil, business: .common)
    }
   
    /// business：reaction已经从common转到comment，但是beginSync，endSync还是需要用到common
    public func sendToRN(bodyData: [String: Any]? = nil, operationKey: String, requestId: String? = nil, business: Business = .comment) {
        guard fileToken.isEmpty == false else {
            DocsLogger.error("common manager token is empty", component: LogComponents.comment, traceId: extraId)
            return
        }
        var data: [String: Any] = ["operation": operationKey,
                                   "identifier": ["token": fileToken,
                                                  "type": fileType,
                                                  "extraId": extraId]]
        if let bodyData = bodyData {
            data["body"] = bodyData
        }
        if let requestId = requestId {
            data["header"] = ["requestId": requestId]
        }
        let composedData: [String: Any] = ["business": business.rawValue,
                                           "data": data]
        if operationKey == CommonSendOperation.beginSync.rawValue ||
            operationKey == CommonSendOperation.endSync.rawValue {
            DocsLogger.info("[common sync] op:\(operationKey) token:\(fileToken.encryptToken)", component: LogComponents.comment, traceId: extraId)
        }
        RNManager.manager.sendSpaceBusnessToRN(data: composedData)
    }

    /// 增加 reaction
    public func addReaction(_ reaction: RNCommonDataManager.Reaction, response: ResponseCallback? = nil) {
        updateReaction(reaction, operation: .addReaction) { (data) in
            data.isNewReaction = true
            response?(data)
        }
    }

    /// 增加 reaction
    public func removeReaction(_ reaction: RNCommonDataManager.Reaction, response: ResponseCallback? = nil) {
        updateReaction(reaction, operation: .removeReaction) { (data) in
            data.isNewReaction = false
            response?(data)
        }
    }
    
    private func updateReaction(_ reaction: RNCommonDataManager.Reaction, operation: CommonSendOperation, response: ResponseCallback? = nil) {
        let data = [
            "reactionKey": reaction.reactionKey ?? "",
            "replyId": reaction.replyId ?? ""
            ] as [String: Any]

        let requestId: String? = (response != nil) ? generateRequestID(response: response!) : nil
        sendToRN(bodyData: data,
                 operationKey: operation.rawValue,
                 requestId: requestId)
    }
    
    /// 获取 reaction 详情
    public func getReactionDetail(_ commentReaction: CommentReactionInfoType, response: ResponseCallback? = nil) {
        let data = [
            "referType": commentReaction.referType as Any,
            "referKey": commentReaction.referKey as Any
            ]
        let response: ((ReactionCacllBackData) -> Void) = { [weak self] res in
            self?._notifyReaction(res, response: response)
        }
        let requestId: String = generateRequestID(response: response)
        sendToRN(bodyData: data,
                 operationKey: CommonSendOperation.getReactionDetail.rawValue,
                 requestId: requestId)
    }

    /// 设置 Reaction Detail 面板状态
    public func setReactionDetailPanelStatus(_ reaction: RNCommonDataManager.Reaction) {
        let data = [
            "referType": reaction.referType ?? "",
            "referKey": reaction.referKey ?? "",
            "status": reaction.status ?? ""
            ] as [String: Any]

        sendToRN(bodyData: data,
                 operationKey: CommonSendOperation.setReactionDetailPanelStatus.rawValue)
    }

    public func generateRequestID(response: @escaping ResponseCallback) -> String {
        let requestId = "\(Date().timeIntervalSince1970)_reaction"
        callbackDic[requestId] = response
        return requestId
    }

    func handleResponse(response: ReactionCacllBackData, requestId: String) {
        if let callback = callbackDic[requestId] {
            callback(response)
            callbackDic[requestId] = nil
        } else {
            DocsLogger.info("reaction handleResponse. receive response but missing callback")
        }
    }

}

extension RNCommonDataManager: RNMessageDelegate {
    public func didReceivedRNData(data: [String: Any], eventName: RNManager.RNEventName) {
        guard eventName == .comment else { return }

        /// 4.3改成返回response
        guard let operationStr = data["operation"] as? String, let operation = CommonReceiveOperation(rawValue: operationStr) else {
            DocsLogger.info("缺少 operation 字段, 无法解析")
            return
        }

        DocsLogger.info("RNCommonDataManager, receive response eventName: \(eventName), operation=\(operationStr)")

        switch operation {
        case .response:
            if let body = data["body"] as? [String: Any], let header = data["header"] as? [String: Any], let requestId = header["requestId"] as? String {
                if requestId.hasSuffix("_reaction") {
                    serialQueue.async {
                        guard let responseModel = ReactionCacllBackData.deserialize(from: body) else {
                            DocsLogger.error("ReactionCacllBackData deserialize fail", component: LogComponents.comment)
                            return
                        }
                        responseModel.rawData = body
                        DispatchQueue.main.async {
                            self.handleResponse(response: responseModel, requestId: requestId)
                        }
                    }
                }
            }
        }
    }
}

private extension RNCommonDataManager {
    private func _notifyReaction(_ model: ReactionCacllBackData, response: ResponseCallback? = nil) {
        guard let referType = model.referType,
              let referKey = model.referKey,
              let data = model.data as? [[String: Any]] else {
            return
        }

        let reactions = data.map { (reaction) -> CommentReaction? in
            guard let rData = try? JSONSerialization.data(withJSONObject: reaction, options: []) else { return nil }
            return try? JSONDecoder().decode(CommentReaction.self, from: rData)
        }.compactMap { $0 }
        let userInfo = [
            ReactionNotificationKey.referKey: referKey,
            ReactionNotificationKey.referType: referType,
            ReactionNotificationKey.reactions: reactions
            ] as [ReactionNotificationKey: Any]

        // 通知详情面板
        NotificationCenter.default.post(name: Notification.Name.ReactionShowDetail,
                                        object: nil,
                                        userInfo: userInfo)
        model.reactions = reactions
        response?(model)
    }
}


extension ReactionCacllBackData: HandyJSON {}
