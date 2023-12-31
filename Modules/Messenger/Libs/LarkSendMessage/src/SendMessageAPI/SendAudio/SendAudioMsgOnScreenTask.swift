////
////  SendAudioMsgOnScreenTask.swift
////  LarkSDK
////
////  Created by JackZhao on 2022/1/16.
////

import Foundation
import RustPB // Basic_V1_DynamicNetStatusResponse
import FlowChart // FlowChartContext
import LarkModel // Chatter
import LarkSDKInterface // SDKRustService
import LarkSetting // FeatureGatingManager
import LarkAIInfra // MyAIChatModeConfig
import LarkContainer

public protocol SendAudioMsgOnScreenTaskContext: FlowChartContext {
    var client: SDKRustService { get }
    var queue: DispatchQueue { get }
    var currentChatter: Chatter { get }
    func randomString(length: Int) -> String
    var currentNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus { get }
}

public final class SendAudioMsgOnScreenTask<C: SendAudioMsgOnScreenTaskContext>: FlowChartTask<SendMessageProcessInput<SendAudioModel>, SendMessageProcessInput<SendAudioModel>, C> {
    override public var identify: String { "SendAudioMsgOnScreenTask" }

    public override func run(input: SendMessageProcessInput<SendAudioModel>) {
        guard
            let content = input.model.content,
            let currentChatter = flowContext?.currentChatter,
            let userResolver = try? Container.shared.getUserResolver(userID: currentChatter.id)
        else {
            self.accept(.error(.dataError("content or chatter is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        var output = input
        var cid: String = flowContext?.randomString(length: 10) ?? ""
        // 语音+文字场景：之前语音数据Data是在SEND_MESSAGE时传给Rust进行上传；现在做了一个优化：识别文字时也同时进行上传，所以SEND_MESSAGE/创建假消息时需要把cid赋值为uploadID（开始识别文字时得到）
        if userResolver.fg.staticFeatureGatingValue(with: "messenger.audiowithtext.recognition.and.upload"), case .data(_, let uploadID) = input.model.info.dateType, !uploadID.isEmpty {
            cid = uploadID
        }
        let info = input.model.info
        let message = SendAudioMsgOnScreenTask.createAudioMessageByNative(context: input.context,
                                                                          quasiContent: content,
                                                                          currentChatter: currentChatter,
                                                                          text: info.text,
                                                                          cid: cid,
                                                                          rootId: input.rootId ?? "",
                                                                          lastMessagePosition: input.context?.lastMessagePosition,
                                                                          chatId: input.model.chatId ?? "",
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
                                                  rustCreateForSend: nil,
                                                  rustCreateCost: nil,
                                                  useNativeCreate: input.useNativeCreate)
        output.message = message
        output.extraInfo["cid"] = cid
        output.model.cid = cid
        self.accept(.success(output))
    }

    //本地创建audioMessage
    private static func createAudioMessageByNative(context: APIContext?,
                                                  quasiContent: RustPB.Basic_V1_QuasiContent,
                                                  currentChatter: Chatter,
                                                  text: String? = nil,
                                                  cid: String,
                                                  rootId: String,
                                                  lastMessagePosition: Int32? = nil,
                                                  chatId: String,
                                                  parentId: String,
                                                  displayMode: RustPB.Basic_V1_Chat.ChatDisplayModeSetting.Enum?) -> LarkModel.Message {
        var channelPb = RustPB.Basic_V1_Channel()
        channelPb.id = chatId
        channelPb.type = .chat
        let time = Date().timeIntervalSince1970

        let audioContent = AudioContent(key: cid,
                                        duration: quasiContent.duration,
                                        size: 0,
                                        voiceText: text ?? "",
                                        hideVoice2Text: false,
                                        originSenderID: "",
                                        localUploadID: "",
                                        originTosKey: "",
                                        originSenderName: "",
                                        isFriend: false,
                                        isAudioRecognizeFinish: false,
                                        audio2TextStartTime: 0,
                                        isAudioWithText: text != nil)
        let quasiMessage = LarkModel.Message.transform(pb: Message.PBModel())
        quasiMessage.cid = cid
        quasiMessage.id = cid
        quasiMessage.type = .audio
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
        quasiMessage.content = audioContent
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
