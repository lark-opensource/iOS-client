//
//  SendMediaDealTask.swift
//  LarkSDK
//
//  Created by JackZhao on 2022/1/21.
//

import Foundation
import LarkModel // MediaContent
import ByteWebImage // LarkImageService

public final class SendMediaDealTask<C: SendMessageDealTaskContext>: SendMessageDealTask<SendMediaModel, C> {
    override public var identify: String { "SendMediaDealTask" }

    public override func run(input: SendMessageProcessInput<SendMediaModel>) {
        var ouput = input
        let params = input.model.params
        let message = input.message
        guard let message = input.message else {
            RustSendMessageAPI.logger.error("can`t send message")
            return
        }
        // 由于SDK无法提供发送前后Key的关系，所以使用Key和CID各缓存一份，这样就可以避免设置图片上墙或者转存缓存失败
        if let key = (message.content as? LarkModel.MediaContent)?.image.origin.key {
            LarkImageService.shared.cacheImage(image: params.image, resource: .default(key: key), cacheOptions: .memory)
        }
        LarkImageService.shared.cacheImage(image: params.image, resource: .default(key: message.cid), cacheOptions: .memory)
        // track send message
        LarkSendMessageTracker.trackStartSendMessage(token: message.cid)
        RustSendMessageAPI.logger.debug("start to send message：\(message.cid)")
        flowContext?.dealSendingMessage(message: message, replyInThread: input.replyInThread, parentMessage: input.parentMessage, chatFromWhere: input.context?.get(key: APIContext.chatFromWhere))
        self.accept(.success(ouput))
    }
}
