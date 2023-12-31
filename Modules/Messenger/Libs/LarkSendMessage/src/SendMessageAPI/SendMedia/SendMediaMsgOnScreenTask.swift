//
//  SendMediaMsgOnScreenTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/16.
//

import Foundation
import RustPB // Basic_V1_DynamicNetStatusResponse
import FlowChart // FlowChartContext
import LarkModel // Chatter
import LarkSDKInterface // SDKRustService
import LarkAIInfra // MyAIChatModeConfig

public protocol SendMediaMsgOnScreenTaskContext: FlowChartContext {
    var client: SDKRustService { get }
    var queue: DispatchQueue { get }
    var currentChatter: Chatter { get }
    var currentNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus { get }
    func randomString(length: Int) -> String
}

public final class SendMediaMsgOnScreenTask<C: SendMediaMsgOnScreenTaskContext>: FlowChartTask<SendMessageProcessInput<SendMediaModel>, SendMessageProcessInput<SendMediaModel>, C> {
    override public var identify: String { "SendMediaMsgOnScreenTask" }

    public override func run(input: SendMessageProcessInput<SendMediaModel>) {
        guard let currentChatter = flowContext?.currentChatter else {
            self.accept(.error(.dataError("content or chatter is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        var output = input
        let cid: String = flowContext?.randomString(length: 10) ?? ""
        let params = input.model.params
        //创建视频消息
        let message = SendMediaMsgOnScreenTask.createMediaMessageByNative(context: input.context,
                                                                          params: params,
                                                                          currentChatter: currentChatter,
                                                                          cid: cid,
                                                                          rootId: input.rootId ?? "",
                                                                          lastMessagePosition: input.context?.lastMessagePosition,
                                                                          parentId: input.parentId ?? "",
                                                                          displayMode: input.context?.chatDisplayMode)
        // threadId有值：话题群 + replyInThread；position = -3：replyInThread，此if：只排除话题群场景
        if message.threadId.isEmpty || message.position == replyInThreadMessagePosition {
            // 当前网络还可以，端上创建的假消息上屏不需要展示loading
            if let netStatus = self.flowContext?.currentNetStatus, (netStatus == .excellent || netStatus == .evaluating) {
                message.localStatus = .fakeSuccess
            }
        }
        input.stateHandler?(.getQuasiMessage(message, contextId: input.context?.contextID ?? ""))
        input.sendMessageTracker?.getQuasiMessage(msg: message,
                                                  context: input.context,
                                                  contextId: input.context?.contextID ?? "",
                                                  size: nil,
                                                  rustCreateForSend: false,
                                                  rustCreateCost: nil,
                                                  useNativeCreate: input.useNativeCreate)

        output.message = message
        output.extraInfo["cid"] = cid
        output.model.cid = cid
        self.accept(.success(output))
    }

    //端上创建mediaMessage
    private static func createMediaMessageByNative(context: APIContext?,
                                                  params: SendMediaParams,
                                                  currentChatter: Chatter,
                                                  cid: String,
                                                  rootId: String,
                                                  lastMessagePosition: Int32? = nil,
                                                  parentId: String,
                                                  displayMode: RustPB.Basic_V1_Chat.ChatDisplayModeSetting.Enum?) -> LarkModel.Message {
        let time = Date().timeIntervalSince1970
        var channelPb = RustPB.Basic_V1_Channel()
        channelPb.id = params.chatID
        channelPb.type = .chat

        var image: RustPB.Basic_V1_Image = RustPB.Basic_V1_Image()
        image.key = cid + "_crypto_token"
        image.type = RustPB.Basic_V1_Image.TypeEnum.encrypted
        image.width = (Int32)(params.mediaSize.width)
        image.height = (Int32)(params.mediaSize.height)

        var imageSet: RustPB.Basic_V1_ImageSet = RustPB.Basic_V1_ImageSet()
        imageSet.key = cid
        imageSet.origin = image
        imageSet.thumbnail = image
        imageSet.middle = image
        let mediaContent = MediaContent(key: cid,
                                        name: params.name,
                                        size: 0,
                                        mime: "",
                                        source: .lark,
                                        image: imageSet,
                                        duration: params.duration,
                                        url: "",
                                        authToken: nil,
                                        filePath: "",
                                        originPath: params.exportPath,
                                        compressPath: params.compressPath,
                                        isPCOriginVideo: false)
        let quasiMessage = LarkModel.Message.transform(pb: Message.PBModel())
        quasiMessage.cid = cid
        quasiMessage.id = cid
        quasiMessage.type = .media
        quasiMessage.channel = channelPb
        quasiMessage.createTime = time
        quasiMessage.createTimeMs = Int64(time) * 1000
        quasiMessage.updateTime = time
        quasiMessage.rootId = rootId
        quasiMessage.parentId = parentId
        quasiMessage.fromId = currentChatter.id
        quasiMessage.position = lastMessagePosition ?? 0
        quasiMessage.meRead = true
        quasiMessage.fromType = .user
        quasiMessage.content = mediaContent
        quasiMessage.sourceType = .typeFromMessage
        quasiMessage.isBadged = true
        quasiMessage.displayMode = displayMode?.transform() ?? .default
        quasiMessage.fromChatter = currentChatter
        quasiMessage.localStatus = .process
        if let partialReplyInfo: PartialReplyInfo? = context?.get(key: APIContext.partialReplyInfo) {
            quasiMessage.partialReplyInfo = partialReplyInfo
        }
        return quasiMessage
    }
}
