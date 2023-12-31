//////
//////  SendImageMsgOnScreenTask .swift
//////  LarkSDK
//////
//////  Created by JackZhao on 2022/1/9.
//////
////

import Foundation
import RustPB // Basic_V1_DynamicNetStatusResponse
import FlowChart // FlowChartContext
import LarkModel // Chatter
import ByteWebImage // ImageSourceResult
import LarkSDKInterface // SDKRustService
import LarkAIInfra // MyAIChatModeConfig

struct SendImageParams {
    let useOrigin: Bool
    let rootId: String
    let parentId: String
    let chatId: String
    let threadId: String?
}

public protocol SendImageMsgOnScreenTaskContext: FlowChartContext {
    var client: SDKRustService { get }
    var queue: DispatchQueue { get }
    var currentChatter: Chatter { get }
    var currentNetStatus: RustPB.Basic_V1_DynamicNetStatusResponse.NetStatus { get }
    func randomString(length: Int) -> String
}

public final class SendImageMsgOnScreenTask <C: SendImageMsgOnScreenTaskContext>: FlowChartTask<SendMessageProcessInput<SendImageModel>, SendMessageProcessInput<SendImageModel>, C> {
    override public var identify: String { "SendImageMsgOnScreenTask" }

    public override func run(input: SendMessageProcessInput<SendImageModel>) {
        let model = input.model
        let params = SendImageParams(useOrigin: model.useOriginal,
                                     rootId: input.rootId ?? "",
                                     parentId: input.parentId ?? "",
                                     chatId: model.chatId ?? "",
                                     threadId: model.threadId ?? "")
        if let onscreenImageSource = model.imageSource,
           let onscreenImageData = model.imageData {
            self.sendImageMessageByNative(context: input.context,
                                          input: input,
                                          imageMessageInfo: model.imageMessageInfo,
                                          onscreenImageSource: onscreenImageSource,
                                          onscreenImageData: onscreenImageData,
                                          params: params,
                                          multiSendSerialToken: input.multiSendSerialToken,
                                          stateHandler: input.stateHandler)
        }
    }

    //发送本地创建图片消息
    private func sendImageMessageByNative(
        context: APIContext?,
        input: SendMessageProcessInput<SendImageModel>,
        imageMessageInfo: ImageMessageInfo,
        onscreenImageSource: ImageSourceResult,
        onscreenImageData: Data,
        params: SendImageParams,
        multiSendSerialToken: UInt64? = nil,
        stateHandler: ((SendMessageState) -> Void)?) {
        guard let currentChatter = flowContext?.currentChatter else {
            self.accept(.error(.dataError("content or chatter is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        var output = input
        let time = Date().timeIntervalSince1970
        let cid: String = self.flowContext?.randomString(length: 10) ?? ""
        //创建本地图片消息
        let quasiMessage = SendImageMsgOnScreenTask.createImageMessageByNative(
            context: input.context,
            imageSourceResult: onscreenImageSource,
            currentChatter: currentChatter,
            useOrigin: params.useOrigin,
            cid: cid,
            rootId: params.rootId,
            lastMessagePosition: context?.lastMessagePosition,
            chatId: params.chatId,
            threadId: params.threadId,
            parentId: params.parentId,
            displayMode: input.context?.chatDisplayMode
        )

            // threadId有值：话题群 + replyInThread；position = -3：replyInThread，此if：只排除话题群场景
        if quasiMessage.threadId.isEmpty || quasiMessage.position == replyInThreadMessagePosition {
            // 当前网络还可以，端上创建的假消息上屏不需要展示loading
            if let netStatus = self.flowContext?.currentNetStatus, (netStatus == .excellent || netStatus == .evaluating) {
                quasiMessage.localStatus = .fakeSuccess
            }
        }
        stateHandler?(.getQuasiMessage(quasiMessage, contextId: context?.contextID ?? ""))
        input.sendMessageTracker?.getQuasiMessage(msg: quasiMessage,
                                                  context: input.context,
                                                  contextId: context?.contextID ?? "",
                                                  size: nil,
                                                  rustCreateForSend: false,
                                                  rustCreateCost: nil,
                                                  useNativeCreate: input.useNativeCreate)
        //把上屏图片写入缓存
        let key = (quasiMessage.content as? ImageContent)?.image.origin.key ?? quasiMessage.cid
        output.model.cid = cid
        output.model.startTime = time
        output.message = quasiMessage
        output.extraInfo["cid"] = cid
        if let onscreenImage = onscreenImageSource.image {
            LarkImageService.shared.cacheImage(image: onscreenImage, resource: .default(key: key), cacheOptions: .memory)
        }
        self.accept(.success(output))
    }

    //本地创建ImageMessage
    // swiftlint:disable function_parameter_count
    private static func createImageMessageByNative(
        context: APIContext?,
        imageSourceResult: ImageSourceResult,
        currentChatter: Chatter,
        useOrigin: Bool,
        cid: String,
        rootId: String,
        lastMessagePosition: Int32? = nil,
        chatId: String,
        threadId: String?,
        parentId: String,
        displayMode: RustPB.Basic_V1_Chat.ChatDisplayModeSetting.Enum?
    ) -> LarkModel.Message {
        // swiftlint:enable function_parameter_count
        let time = Date().timeIntervalSince1970
        var channelPb = RustPB.Basic_V1_Channel()
        channelPb.id = chatId
        channelPb.type = .chat

        var image: RustPB.Basic_V1_Image = RustPB.Basic_V1_Image()
        image.key = cid
        image.type = RustPB.Basic_V1_Image.TypeEnum.encrypted
        // 需要把image.size换成px单位
        let imageScale = imageSourceResult.image?.scale ?? 1
        image.width = (Int32)((imageSourceResult.image?.size.width ?? 0) * imageScale)
        image.height = (Int32)((imageSourceResult.image?.size.height ?? 0) * imageScale)

        var imageSet: RustPB.Basic_V1_ImageSet = RustPB.Basic_V1_ImageSet()
        imageSet.key = cid
        imageSet.origin = image
        imageSet.thumbnail = image
        imageSet.middle = image
        let imageContent = ImageContent(
            image: imageSet,
            cryptoToken: "",
            isOriginSource: useOrigin,
            originFileSize: UInt64(imageSourceResult.data?.count ?? 0)
        )
        let quasiMessage = LarkModel.Message.transform(pb: Message.PBModel())
        quasiMessage.cid = cid
        quasiMessage.id = cid
        quasiMessage.type = .image
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
        quasiMessage.content = imageContent
        quasiMessage.sourceType = .typeFromMessage
        quasiMessage.isBadged = true
        quasiMessage.threadId = threadId ?? ""
        quasiMessage.displayMode = displayMode?.transform() ?? .default
        quasiMessage.fromChatter = currentChatter
        quasiMessage.localStatus = .process
        if let partialReplyInfo: PartialReplyInfo? = context?.get(key: APIContext.partialReplyInfo) {
            quasiMessage.partialReplyInfo = partialReplyInfo
        }
        return quasiMessage
    }
}
