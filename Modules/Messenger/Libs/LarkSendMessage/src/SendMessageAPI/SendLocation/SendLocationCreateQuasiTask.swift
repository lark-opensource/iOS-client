//
//  SendLocationCreateQuasiTask.swift
//  LarkSDK
//
//  Created by ByteDance on 2022/8/5.
//

import Foundation
import RustPB // Basic_V1_QuasiContent
import FlowChart // FlowChartContext
import LarkModel // LocationContent
import ByteWebImage // LarkImageService
import LarkSDKInterface // SDKRustService

public protocol SendLocationCreateQuasiTaskContext: FlowChartContext {
    var client: SDKRustService { get }
}

public final class SendLocationCreateQuasiTask<C: SendLocationCreateQuasiTaskContext>: FlowChartTask<SendMessageProcessInput<SendLocationModel>, SendMessageProcessInput<SendLocationModel>, C> {
    override public var identify: String { "SendLocationCreateQuasiTask" }

    public override func run(input: SendMessageProcessInput<SendLocationModel>) {
        guard let client = flowContext?.client else {
            self.accept(.error(.dataError("client is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        var output = input
        let location = input.model.location
        let screenShot = input.model.screenShot

        let imageSourceRes = input.model.screenShot.jpegImageInfo()

        guard let imageData = imageSourceRes.data,
            let image = imageSourceRes.image else {
                RustSendMessageAPI.logger.error(
                    "sendm message faild[\(input.model.chatId)]: location message is not contains image data"
                )
            self.accept(.error(.dataError("imageData is nil", extraInfo: ["cid": input.message?.cid ?? ""])))
            return
        }
        var content = RustPB.Basic_V1_QuasiContent()
        /// set the screenshot
        content.image = imageData
        content.height = Int32(screenShot.size.height)
        content.width = Int32(screenShot.size.width)
        /// set the location content
        content.locationContent.latitude = location.latitude
        content.locationContent.longitude = location.longitude
        content.locationContent.image = ImageSet()
        content.locationContent.zoomLevel = location.zoomLevel
        content.locationContent.vendor = location.vendor
        content.locationContent.location = location.location
        content.locationContent.isInternal = location.isInternal

        if let (message, contextId) = try? RustSendMessageModule.createQuasiMessage(
            chatId: input.model.chatId,
            threadId: input.model.threadId ?? "",
            rootId: input.rootId ?? "",
            parentId: input.parentId ?? "",
            type: .location,
            content: content,
            client: client,
            context: input.context
        ) {
            input.stateHandler?(.getQuasiMessage(message, contextId: contextId))
            input.sendMessageTracker?.getQuasiMessage(msg: message,
                                                      context: input.context,
                                                      contextId: contextId,
                                                      size: nil,
                                                      rustCreateForSend: true,
                                                      rustCreateCost: nil,
                                                      useNativeCreate: false)
            let key = (message.content as? LarkModel.LocationContent)?.image.origin.key ?? message.cid
            LarkImageService.shared.cacheImage(image: image, resource: .default(key: key), cacheOptions: .memory)
            let coordType = content.locationContent.isInternal ? "GCJ-02" : "WGS-84"
            RustSendMessageAPI.logger.info(
                "[\(coordType)] send location info[\(input.model.chatId)]"
            )
            output.message = message
            self.accept(.success(output))
        } else {
            input.stateHandler?(.errorQuasiMessage)
            input.sendMessageTracker?.errorQuasiMessage(context: input.context)
            self.accept(.error(.bussinessError("createQuasiMessage fail", extraInfo: ["cid": input.model.cid ?? ""])))
        }
    }
}
