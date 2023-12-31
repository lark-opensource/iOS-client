//
//  ImagePreloader+Chat.swift
//  LarkMessageCore
//
//  Created by Saafo on 2023/1/3.
//

import ByteWebImage
import Foundation
import LarkMessageBase
import LarkModel
import LarkContainer

public final class ChatImageCellLifeCycleObserver: CellLifeCycleObsever {
    public init() {}

    public func initialized(metaModel: CellMetaModel, context: PageContext) {
        guard LarkImageService.shared.imagePreloadConfig.preloadEnable else { return }
        let chat = metaModel.getChat()
        let message = metaModel.message
        guard !chat.isCrypto &&
                !message.isRecalled &&
                !message.isDeleted &&
                (message.localStatus == .success) &&
                [.image, .media, .post].contains(message.type) else { return }
        ImagePreloader.shared.preload(scene: .chat, sceneID: chat.id, message: message)
    }
}
