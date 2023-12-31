//
//  SendMediaProcess.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/7/29.
//

import UIKit
import Foundation
import LarkModel // Message
import RustPB // Basic_V1_CreateScene
import LarkAccountInterface
import LarkStorage // IsoPath
import LarkCache // Cache

private let sendVideoDomain = Domain.biz.messenger.child("SendVideo")
public func sendVideoRootPath(userID: String) -> IsoPath {
    return .in(space: .user(id: userID), domain: sendVideoDomain).build(.cache)
}
public func sendVideoCache(userID: String) -> Cache {
    return CacheManager.shared.cache(
        rootPath: sendVideoRootPath(userID: userID),
        cleanIdentifier: "library/Caches/messenger/user_id/videoCache"
    )
}

public struct SendMediaParams {
    /// 待发送视频路径
    public var exportPath: String
    /// 待发送视频转码后的路径
    public var compressPath: String
    public var name: String
    public var image: UIImage
    public var duration: Int32
    public var parentMessage: LarkModel.Message?
    public var chatID: String
    public var threadID: String?
    public var imageData: Data?
    public var mediaSize: CGSize
    public var createScene: Basic_V1_CreateScene?

    public init(
        exportPath: String,
        compressPath: String,
        name: String,
        image: UIImage,
        imageData: Data?,
        mediaSize: CGSize,
        duration: Int32,
        chatID: String,
        threadID: String?,
        parentMessage: LarkModel.Message?,
        createScene: Basic_V1_CreateScene?
    ) {
        self.exportPath = exportPath
        self.compressPath = compressPath
        self.name = name
        self.image = image
        self.imageData = imageData
        self.mediaSize = mediaSize
        self.duration = duration
        self.chatID = chatID
        self.threadID = threadID
        self.parentMessage = parentMessage
        self.createScene = createScene
    }
}

extension RustSendMessageAPI {
    func getSendMediaProcess() -> SerialProcess<SendMessageProcessInput<SendMediaModel>, RustSendMessageAPI> {
        let formatInputProcess = SerialProcess(SendMediaFormatInputTask(context: self), context: self)
        let nativeCreateAndSendProcess = SerialProcess(
            [SendMediaMsgOnScreenTask(context: self),
             SendMediaDealTask(context: self),
             SendMediaCreateQuasiMsgTask(context: self),
             SendMessageTask(context: self)],
            context: self)

        let rustCreateAndSendProcess = SerialProcess(
            [SendMediaCreateQuasiMsgTask(context: self),
             SendMediaDealTask(context: self),
             SendMessageTask(context: self)],
            context: self)

        return SerialProcess(
            [formatInputProcess,
             ConditionProcess(context: self) { [weak self] (input)  in
                 guard let self = self else { return nil }
                 var input = input
                 input.useNativeCreate = self.quasiMsgCreateByNative(context: input.context)
                 if input.useNativeCreate {
                     return (nativeCreateAndSendProcess, input)
                 }
                 return (rustCreateAndSendProcess, input)
             }],
        context: self)
    }
}

public struct SendMediaModel: SendMessageModelProtocol {
    var params: SendMediaParams
    var cid: String?
    var content: QuasiContent?
    var handler: SendMessageAPI.PreprocessingHandler?
    public var stateHandler: ((SendMessageState) -> Void)?
    var createScene: Basic_V1_CreateScene?
}

public protocol SendMediaProcessContext: SendMediaMsgOnScreenTaskContext,
                                         SendMediaFormatInputTaskContext {}

extension RustSendMessageAPI: SendMediaProcessContext {}
