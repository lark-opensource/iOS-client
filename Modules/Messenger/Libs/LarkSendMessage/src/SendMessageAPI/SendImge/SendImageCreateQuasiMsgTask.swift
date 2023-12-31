////
////  SendImageCreateQuasiMsgTask.swift
////  LarkSDK
////
////  Created by JackZhao on 2022/1/9.
////
//

import UIKit
import Foundation
import RustPB // Basic_V1_CreateScene
import FlowChart // FlowChartTask
import ByteWebImage // ImageSourceResult

public typealias SendImageCreateQuasiMsgTaskContext = SendImageMsgOnScreenTaskContext

// rust发图片
public final class SendImageCreateQuasiMsgTask<C: SendImageCreateQuasiMsgTaskContext>: FlowChartTask<SendMessageProcessInput<SendImageModel>, SendMessageProcessInput<SendImageModel>, C> {
    override public var identify: String { "SendImageCreateQuasiMsgTask" }

    public override func run(input: SendMessageProcessInput<SendImageModel>) {
        let model = input.model
        // 仅在单测中beforeCreateQuasiMsgHandler有值
        #if ALPHA
        if let beforeCreateQuasiMsgHandler = RustSendMessageAPI.beforeCreateQuasiMsgHandler {
            beforeCreateQuasiMsgHandler()
        }
        #endif
        let params = SendImageParams(useOrigin: model.useOriginal,
                                     rootId: input.rootId ?? "",
                                     parentId: input.parentId ?? "",
                                     chatId: model.chatId ?? "",
                                     threadId: model.threadId ?? "")
        flowContext?.queue.async { [weak self] in
            guard let self = self else { return }
            if let onscreenImageSource = model.imageSource,
               let onscreenImageData = model.imageData {
                self.sendImageMessageByRust(context: input.context,
                                            input: input,
                                            imageMessageInfo: model.imageMessageInfo,
                                            onscreenImageSource: onscreenImageSource,
                                            onscreenImageData: onscreenImageData,
                                            params: params,
                                            createScene: model.createScene,
                                            stateHandler: input.stateHandler)
            } else {
                self.accept(.error(.dataError("data is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            }
        }
    }
}

extension SendImageCreateQuasiMsgTask {
    //发送rust创建图片消息
    private func sendImageMessageByRust(
        context: APIContext?,
        input: SendMessageProcessInput<SendImageModel>,
        imageMessageInfo: ImageMessageInfo,
        onscreenImageSource: ImageSourceResult,
        onscreenImageData: Data,
        params: SendImageParams,
        multiSendSerialToken: UInt64? = nil,
        createScene: Basic_V1_CreateScene? = nil,
        stateHandler: ((SendMessageState) -> Void)?) {
        guard let client = flowContext?.client else {
            self.accept(.error(.dataError("client is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        let time = input.model.startTime ?? Date().timeIntervalSince1970
        var output = input
        // 获取原图数据
        let originImage: UIImage? = imageMessageInfo.sendImageSource.originImage.image
        let originImageData = imageMessageInfo.sendImageSource.originImage.data
        if let originImageData = originImageData,
           let originImage = originImage {
            // 创建假消息，使用原图数据创建假消息，后续也不需要updateQuasiMessage了
            var originContent = RustPB.Basic_V1_QuasiContent()
            originContent.isOriginSource = params.useOrigin
            originContent.image = originImageData
            // 需要把image.size换成px单位
            originContent.width = Int32(originImage.size.width * originImage.scale)
            originContent.height = Int32(originImage.size.height * originImage.scale)
            let start = CACurrentMediaTime()
            guard let (message, contextId) = try? RustSendMessageModule.createQuasiMessage(
                chatId: params.chatId,
                threadId: params.threadId ?? "",
                rootId: params.rootId,
                parentId: params.parentId,
                type: .image,
                content: originContent,
                imageCompressedSize: 0,
                uploadID: input.model.cid ?? "", // 这里应该传参给cid，目前没问题的原因：Rust内部会优先取uploadID再取cid赋值给cid
                position: context?.lastMessagePosition,
                client: client,
                createScene: createScene,
                context: context) else {
                self.accept(.error(.bussinessError("createQuasiMessage fail", extraInfo: ["cid": input.message?.cid ?? ""])))
                stateHandler?(.errorQuasiMessage)
                return
            }
            stateHandler?(.getQuasiMessage(message, contextId: contextId, processCost: imageMessageInfo.imageSize, rustCreateForSend: true, rustCreateCost: (CACurrentMediaTime() - start)))
            input.sendMessageTracker?.getQuasiMessage(msg: message,
                                                      context: input.context,
                                                      contextId: contextId,
                                                      size: imageMessageInfo.imageSize,
                                                      rustCreateForSend: true,
                                                      rustCreateCost: CACurrentMediaTime() - start,
                                                      useNativeCreate: input.useNativeCreate)
            // 把上屏图写入缓存
            if let image = onscreenImageSource.image {
                LarkImageService.shared.cacheImage(image: image, resource: .default(key: message.cid), cacheOptions: .memory)
            }
            // 进行埋点数据的存储
            input.sendMessageTracker?.cacheImageExtraInfo(cid: message.cid,
                                                          imageInfo: input.model.imageMessageInfo,
                                                          useOrigin: input.model.useOriginal)
            // 把原图写入缓存
            let originImageCacheKey = "\(RustSendMessageAPI.originImageCachePre ?? "")_\(message.cid)"
            LarkImageService.shared.cacheImage(image: originImage, resource: .default(key: originImageCacheKey), cacheOptions: .memory)
            //把相关指标传递给sdk
            let map: [String: Float] = ["ee.lark.ios.pic.send": 0.0, "display_cost": Float(CFAbsoluteTimeGetCurrent() - time), "size": Float(originImageData.count)]
            self.sendMetricsToSDK(map: map, cid: input.message?.cid ?? "")
            output.processCost = imageMessageInfo.sendImageSource.originImage.compressCost
            output.message = message
            output.extraInfo["cid"] = message.cid ?? ""
            self.accept(.success(output))
        }
    }

    private func sendMetricsToSDK(map: [String: Float], cid: String) {
        guard let client = flowContext?.client else {
            self.accept(.error(.dataError("client is nil", extraInfo: ["cid": cid])))
            return
        }
        var request = RustPB.Basic_V1_SendMetricsRequest()
        request.key2Value = map
        _ = client.sendAsyncRequest(request)
    }
}
