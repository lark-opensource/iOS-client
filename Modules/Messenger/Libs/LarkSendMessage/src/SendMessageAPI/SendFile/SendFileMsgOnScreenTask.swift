//
//  SendFileByNativeSubProcess.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/8.
//

import Foundation
import RustPB // Basic_V1_DynamicNetStatusResponse
import FlowChart // FlowChartTask
import LarkModel // Message
import LarkSDKInterface // SDKRustService
import LarkAIInfra // MyAIChatModeConfig

private typealias Path = LarkSDKInterface.PathWrapper

public protocol SendFileMsgOnScreenTaskContext: FlowChartContext {
    var client: SDKRustService { get }
    var queue: DispatchQueue { get }
    var currentChatter: Chatter { get }
    func addPendingMessages(id: String, value: (message: LarkModel.Message, filePath: String, deleteFileWhenFinish: Bool))
    func randomString(length: Int) -> String
    var currentNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus { get }
}

// native发文件
public final class SendFileMsgOnScreenTask<C: SendFileMsgOnScreenTaskContext>: FlowChartTask<SendMessageProcessInput<SendFileModel>, SendMessageProcessInput<SendFileModel>, C> {
    override public var identify: String { "SendFileMsgOnScreenTask" }

    public override func run(input: SendMessageProcessInput<SendFileModel>) {
        guard let currentChatter = flowContext?.currentChatter else {
            self.accept(.error(.dataError("content or chatter is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        var output = input
        let model = input.model
        let uuid: String = flowContext?.randomString(length: 10) ?? ""
        let cid = "lan-trans:\(uuid)"
        let nativeMessage = SendFileMsgOnScreenTask.createFileMessageByNative(context: input.context,
                                                                              cid: cid,
                                                                              currentChatter: currentChatter,
                                                                              path: input.model.path,
                                                                              name: input.model.name,
                                                                              rootId: input.rootId ?? "",
                                                                              parentId: input.parentId ?? "",
                                                                              lastMessagePosition: input.context?.lastMessagePosition,
                                                                              chatId: input.model.chatId,
                                                                              displayMode: input.context?.chatDisplayMode)
        // threadId有值：话题群 + replyInThread；position = -3：replyInThread，此if：只排除话题群场景
        if nativeMessage.threadId.isEmpty || nativeMessage.position == replyInThreadMessagePosition {
            // 当前网络还可以，端上创建的假消息上屏不需要展示loading
            if let netStatus = self.flowContext?.currentNetStatus, (netStatus == .excellent || netStatus == .evaluating) {
                nativeMessage.localStatus = .fakeSuccess
            }
        }
        let contextId = input.context?.contextID ?? ""
        input.stateHandler?(.getQuasiMessage(nativeMessage, contextId: contextId))
        input.sendMessageTracker?.getQuasiMessage(msg: nativeMessage,
                                                  context: input.context,
                                                  contextId: contextId,
                                                  size: nil,
                                                  rustCreateForSend: nil,
                                                  rustCreateCost: nil,
                                                  useNativeCreate: input.useNativeCreate)
        output.message = nativeMessage
        output.model.cid = cid
        output.extraInfo["cid"] = cid
        self.accept(.success(output))
    }

    //本地创建fileMessage
    private static func createFileMessageByNative(context: APIContext?,
                                                 cid: String,
                                                 currentChatter: Chatter,
                                                 path: String,
                                                 name: String,
                                                 rootId: String,
                                                 parentId: String,
                                                 lastMessagePosition: Int32? = nil,
                                                 chatId: String,
                                                 size: Int64? = nil,
                                                 displayMode: RustPB.Basic_V1_Chat.ChatDisplayModeSetting.Enum?) -> LarkModel.Message {
        var channelPb = RustPB.Basic_V1_Channel()
        channelPb.id = chatId
        channelPb.type = .chat
        let time = Date().timeIntervalSince1970

        // 假消息使用正确文件大小
        var fileSize: Int64 = 0
        if let size = size {
            fileSize = size
        } else if Path(path).exists,
                  let size = Path(path).fileSize {
            fileSize = Int64(min(size, UInt64(Int64.max)))
        }
        let fileContent = FileContent(key: cid,
                                      name: name,
                                      size: fileSize,
                                      mime: "",
                                      filePath: path,
                                      cacheFilePath: "",
                                      fileSource: Basic_V1_File.Source.unknown,
                                      namespace: "",
                                      isInMyNutStore: false,
                                      lanTransStatus: FileContent.LanTransStatus.accept,
                                      hangPoint: nil,
                                      fileAbility: .unknownSupportState,
                                      filePermission: .unknownCanState,
                                      fileLastUpdateUserId: 0,
                                      fileLastUpdateTimeMs: 0,
                                      filePreviewStage: .normal)
        let quasiMessage = LarkModel.Message.transform(pb: Message.PBModel())
        quasiMessage.cid = cid
        quasiMessage.id = cid
        quasiMessage.type = .file
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
        quasiMessage.content = fileContent
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
