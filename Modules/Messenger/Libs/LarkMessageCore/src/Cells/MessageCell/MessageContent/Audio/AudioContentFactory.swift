//
//  AudioContentFactory.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/10.
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

protocol AudioContentContext: AudioContentViewModelContext & AudioViewWrapperComponentContext { }

public class BaseAudioContentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return !metaModel.message.isRecalled && metaModel.message.content is AudioContent
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return AudioContentComponentBinder(
            audioViewModel: ChatAudioContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            audioActionHandler: AudioContentActionHandler(context: context)
        )
    }

    public override func registerServices(pageContainer: PageContainer) {
        /// 注册音频播放Service
        pageContainer.register(AudioActionsService.self) { [unowned self] in
            let needPutRead: Bool = self.context.scene == .mergeForwardDetail ? false : true
            return AudioActionsService(
                messageAPI: try? self.context.resolver.resolve(assert: MessageAPI.self, cache: true),
                audioPlayMediator: self.context.audioPlayMediator,
                currentChatterId: self.context.currentUserID,
                targetVC: self.context.pageAPI ?? UIViewController(),
                needPutRead: needPutRead,
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

/// 消息链接化 & 卡片转发场景
public final class MessageLinkAudioContentFactory<C: PageContext>: BaseAudioContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        let config = AudioContentConfig(
            showRedDot: false,
            hasCorner: true,
            hasBackgroundColor: true
        )
        return AudioContentComponentBinder(
            audioViewModel: ChatAudioContentViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                audioContentConfig: config
            ),
            audioActionHandler: AudioContentActionHandler(context: context),
            supportAutoPlay: false
        )
    }
}

/// 群置顶场景
public final class ChatPinAudioContentFactory<C: PageContext>: BaseAudioContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        let config = AudioContentConfig(
            showRedDot: true,
            hasCorner: true,
            hasBackgroundColor: true
        )
        return AudioContentComponentBinder(
            audioViewModel: ChatAudioContentViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                audioContentConfig: config
            ),
            audioActionHandler: AudioContentActionHandler(context: context),
            supportAutoPlay: false
        )
    }
}

/// 消息链接化详情页
public final class MessageLinkDetailAudioContentFactory<C: PageContext>: BaseAudioContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return AudioContentComponentBinder(
            audioViewModel: MergeForwardAudioContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            audioActionHandler: AudioContentActionHandler(context: context),
            supportAutoPlay: false
        )
    }
}

public final class MergeForwardAudioContentFactory<C: PageContext>: BaseAudioContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return AudioContentComponentBinder(
            audioViewModel: MergeForwardAudioContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            audioActionHandler: AudioContentActionHandler(context: context)
        )
    }
}

public final class ThreadChatAudioContentFactory<C: PageContext>: BaseAudioContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return ThreadChatAudioContentComponentBinder(
            audioViewModel: ThreadChatAudioContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            audioActionHandler: AudioContentActionHandler(context: context)
        )
    }
}

public final class ThreadDetailAudioContentFactory<C: PageContext>: BaseAudioContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return ThreadChatAudioContentComponentBinder(
            audioViewModel: ThreadDetailAudioContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            audioActionHandler: AudioContentActionHandler(context: context)
        )
    }
}

public final class MessageDetailAudioContentFactory<C: PageContext>: BaseAudioContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return MessageDetailAudioContentComponentBinder(
            audioViewModel: MessageDetailAudioContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            audioActionHandler: AudioContentActionHandler(context: context)
        )
    }
}

public final class PinAudioContentFactory<C: PageContext>: BaseAudioContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return PinAudioContentComponentBinder(
            audioViewModel: PinAudioContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            audioActionHandler: AudioContentActionHandler(context: context)
        )
    }
}

extension PageContext: AudioContentContext {
    public var audioPlayMediator: AudioPlayMediator? {
        return try? resolver.resolve(assert: AudioPlayMediator.self, cache: true)
    }

    public var audioResourceService: AudioResourceService? {
        return try? resolver.resolve(assert: AudioResourceService.self, cache: true)
    }

    public var audioToTextEnable: Bool {
        // 判断FeatureSwitch && FG
        let audioFS = self.userResolver.fg.staticFeatureGatingValue(with: .init(switch: .suiteVoice2Text))
        return self.getStaticFeatureGating(.audioToTextEnable) && audioFS
    }

    public var audioActionsService: AudioActionsService? {
        return pageContainer.resolve(AudioActionsService.self)
    }

    public var audioContentLifeService: AudioContentLifeService? {
        return pageContainer.resolve(AudioContentLifeService.self)
    }

    public var audioAPI: AudioAPI? {
        return try? resolver.resolve(assert: AudioAPI.self, cache: true)
    }
}
