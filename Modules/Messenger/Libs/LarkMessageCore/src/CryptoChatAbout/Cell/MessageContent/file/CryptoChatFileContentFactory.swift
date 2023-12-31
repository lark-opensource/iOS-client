//
//  CryptoChatFileContentFactory.swift
//  LarkMessageCore
//
//  Created by zc09v on 2022/1/24.
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
import RustPB

public class CryptoChatFileContentFactory<C: PageContext>: MessageSubFactory<C> {

    public override class var subType: SubType {
        return .content
    }

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return metaModel.message.content is FileContent
    }

    public override var canCreateBinder: Bool {
        return true
    }

    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return CryptoChatFileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: CryptoChatFileContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            fileAndFolderActionHandler: CryptoChatFileActionHandler(context: context)
        )
    }
}

public final class CryptoMessageDetailFileContentFactory<C: PageContext>: CryptoChatFileContentFactory<C> {
    public override func createBinder<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> NewComponentBinder<M, D, C> {
        return CryptoChatMessageDetailFileAndFolderContentComponentBinder(
            context: context,
            fileAndFolderViewModel: CryptoChatFileContentViewModel(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context),
            fileAndFolderActionHandler: CryptoChatFileActionHandler(context: context)
        )
    }
}
