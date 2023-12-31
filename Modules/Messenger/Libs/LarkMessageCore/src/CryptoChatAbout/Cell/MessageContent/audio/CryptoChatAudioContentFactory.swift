//
//  CryptoChatAudioContentFactory.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/1/18.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import LarkSetting
import LarkAccountInterface
import LarkSDKInterface
import LarkMessengerInterface
import LarkKAFeatureSwitch
import LarkUIKit

public class CryptoChatAudioContentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return !metaModel.message.isRecalled && metaModel.message.content is AudioContent && !metaModel.message.isSecretChatDecryptedFailed
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return CryptoChatAudioContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: CryptoChatAudioContentComponentBinder<M, D, C>(context: context))
    }

    public override func registerServices(pageContainer: PageContainer) {
        /// 注册音频播放Service
        pageContainer.register(AudioActionsService.self) { [unowned self] in
            return AudioActionsService(
                messageAPI: try? self.context.resolver.resolve(assert: MessageAPI.self, cache: true),
                audioPlayMediator: self.context.audioPlayMediator,
                currentChatterId: self.context.userID,
                targetVC: self.context.pageAPI ?? UIViewController(),
                needPutRead: true,
                showNewTips: self.context.userResolver.fg.staticFeatureGatingValue(with: "messenger.input.audio.playby.improvements")
            )
        }

        /// 注册生命周期Service
        pageContainer.register(AudioContentLifeService.self) { [unowned self] in
            return AudioContentLifeService(
                pushCenter: self.context.resolver.userPushCenter,
                messageBurnService: try? self.context.resolver.resolve(assert: MessageBurnService.self, cache: true),
                audioPlayMediator: try? self.context.resolver.resolve(assert: AudioPlayMediator.self),
                controllerProvider: { [weak self] in
                    return self?.context.pageAPI
                }
            )
        }
    }
}

public final class CryptoMessageDetailAudioContentFactory<C: PageContext>: CryptoChatAudioContentFactory<C> {
    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return CryptoChatMessageDetailAudioContentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: CryptoChatMessageDetailAudioContentComponentBinder<M, D, C>(context: context))
    }
}
