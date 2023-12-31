//
//  VideoContentFactory.swift
//  LarkMessageCore
//
//  Created by liuwanlin on 2019/5/30.
//

import UIKit
import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import LarkSDKInterface
import LarkSendMessage
import LarkMessengerInterface
import RustPB
import LarkUIKit
import LarkAssetsBrowser

public protocol VideoContentContext: PageContext {
    var scene: ContextScene { get }
    var downloadFileScene: RustPB.Media_V1_DownloadFileScene? { get }

    func cancelUpload(_ message: Message) -> Observable<Void>
    func progressValue(key: String) -> Observable<Progress>
    func filter<M: CellMetaModel, D: CellMetaModelDependency, T: PageContext>(_ predicate: (MessageCellViewModel<M, D, T>) -> Bool) -> [MessageCellViewModel<M, D, T>]
    func getVideoCompressProgress(_ message: Message) -> Observable<Double>
    func isMe(_ id: String) -> Bool
    func checkPermissionPreview(chat: Chat, message: Message) -> (Bool, ValidateResult?)
    func checkPreviewAndReceiveAuthority(chat: Chat, message: Message) -> PermissionDisplayState
    func handlerPermissionPreviewOrReceiveError(receiveAuthResult: DynamicAuthorityEnum?,
                                                previewAuthResult: ValidateResult?,
                                                resourceType: SecurityControlResourceType)
    func getChatAlbumDataSourceImpl(chat: Chat, isMeSend: @escaping (String) -> Bool) -> LKMediaAssetsDataSource
}

public class BaseVideoContentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .content
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is MediaContent
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return VideoContentComponentBinder(
            videoViewModel: ChatVideoContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            videoActionHandler: ChatVideoContentActionHandler(context: context)
        )
    }
}

// 消息链接化场景
public final class MessageLinkVideoContentFactory<C: PageContext>: BaseVideoContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        var config = VideoContentConfig()
        // 消息链接化场景保存到云盘会失败，先屏蔽入口
        config.showSaveToCloud = false
        return VideoContentComponentBinder(
            videoViewModel: MessageLinkVideoContentViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                config: config
            ),
            videoActionHandler: MergeForwardDetailVideoContentActionHandler(context: context)
        )
    }
}

// 消息链接化详情页
public final class MessageLinkDetailVideoContentFactory<C: PageContext>: BaseVideoContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        var config = VideoContentConfig()
        // 消息链接化场景保存到云盘会失败，先屏蔽入口
        config.showSaveToCloud = false
        return VideoContentComponentBinder(
            videoViewModel: MergeForwardDetailVideoContentViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                config: config
            ),
            videoActionHandler: MergeForwardDetailVideoContentActionHandler(context: context)
        )
    }

}

public final class ThreadChatVideoContentFactory<C: PageContext>: BaseVideoContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return ThreadVideoContentComponentBinder(
            videoViewModel: ThreadChatVideoContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            videoActionHandler: ThreadChatVideoContentActionHandler(context: context)
        )
    }

}

public final class ThreadDetailVideoContentFactory<C: PageContext>: BaseVideoContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return ThreadVideoContentComponentBinder(
            videoViewModel: ThreadDetailVideoContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            videoActionHandler: ThreadDetailVideoContentActionHandler(context: context)
        )
    }

}

public final class MergeForwardVideoContentFactory<C: PageContext>: BaseVideoContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return VideoContentComponentBinder(
            videoViewModel: MergeForwardDetailVideoContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            videoActionHandler: MergeForwardDetailVideoContentActionHandler(context: context)
        )
    }

}

public final class MessageDetailVideoContentFactory<C: PageContext>: BaseVideoContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return MessageDetailVideoContentComponentBinder(
            videoViewModel: MessageDetailVideoContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            videoActionHandler: MessageDetailVideoContentActionHandler(context: context)
        )
    }

}

public final class PinVideoContentFactory<C: PageContext>: BaseVideoContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return PinVideoContentComponentBinder(
            videoViewModel: PinVideoContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            videoActionHandler: PinVideoContentActionHandler(context: context)
        )
    }

}

extension PageContext: VideoContentContext {
    public func cancelUpload(_ message: Message) -> Observable<Void> {
        try? resolver.resolve(assert: VideoMessageSendService.self, cache: true).cancel(messageCID: message.cid, isDelete: false)
        return (try? resolver.resolve(assert: SecurityFileAPI.self, cache: true))?
            .cancelUploadFiles(cids: [message.cid], type: .message) ?? .empty()
    }

    public func getVideoCompressProgress(_ message: Message) -> Observable<Double> {
        return (try? resolver.resolve(assert: VideoMessageSendService.self, cache: true))?
            .compressProgessObservable(key: message.id) ?? .empty()
    }
}
