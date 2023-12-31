//
//  FolderContentFactory.swift
//  LarkMessageCore
//
//  Created by 赵家琛 on 2021/4/16.
//

import Foundation
import LarkModel
import LarkMessageBase
import RxSwift
import LarkInteraction
import LarkMessengerInterface
import LarkSDKInterface
import LarkContainer
import MobileCoreServices
import LarkKAFeatureSwitch
import LarkSetting
import RustPB

public class FolderContentFactory<C: PageContext>: MessageSubFactory<C> {

    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is FolderContent
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return FileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: FolderContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            fileAndFolderActionHandler: FolderContentActionHandler(context: context)
        )
    }
}

// 合并转发页面在消息链接化场景有些特殊处理（见VM）
public final class MergeForwardFolderContentFactory<C: PageContext>: FolderContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return FileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: MergeForwardFolderContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            fileAndFolderActionHandler: FolderContentActionHandler(context: context)
        )
    }
}

// 消息链接化场景
public final class MessageLinkFolderContentFactory<C: PageContext>: FolderContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return FileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: FolderContentViewModel(
                metaModel: metaModel,
                metaModelDependency: metaModelDependency,
                context: context,
                fileAndFolderConfig: FileAndFolderConfig(
                    useLocalChat: true,
                    canViewInChat: false,
                    canForward: false,
                    canSearch: false,
                    canSaveToDrive: false,
                    canOfficeClick: false
                )
            ),
            fileAndFolderActionHandler: FolderContentActionHandler(context: context)
        )
    }
}

// 群置顶场景
public final class ChatPinFolderContentFactory<C: PageContext>: FolderContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return FileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: FolderContentViewModel(metaModel: metaModel,
                                                           metaModelDependency: metaModelDependency,
                                                           context: context,
                                                           fileAndFolderConfig: FileAndFolderConfig(showBottomBorder: false)),
            fileAndFolderActionHandler: FolderContentActionHandler(context: context)
        )
    }
}

public final class ThreadFolderContentFactory<C: PageContext>: FolderContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return MessageDetailFileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: FolderContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            fileAndFolderActionHandler: FolderContentActionHandler(context: context)
        )
    }
}

public final class MessageDetailFolderContentFactory<C: PageContext>: FolderContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return MessageDetailFileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: FolderContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            fileAndFolderActionHandler: FolderContentActionHandler(context: context)
        )
    }
}

public final class PinFolderContentFactory<C: PageContext>: FolderContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return PinFileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: FolderContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            fileAndFolderActionHandler: FolderContentActionHandler(context: context)
        )
    }
}
