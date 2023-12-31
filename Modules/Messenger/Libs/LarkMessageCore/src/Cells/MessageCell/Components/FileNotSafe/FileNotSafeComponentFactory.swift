//
//  FileNotSafeComponentFactory.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2022/11/14.
//

import Foundation
import LarkModel
import LarkMessageBase
import LarkAccountInterface
import LarkSetting
import LKCommonsLogging

public protocol FileNotSafeComponentContext: FileNotSafeComponentViewModelContext { }

extension PageContext: FileNotSafeComponentContext { }

public final class FileNotSafeComponentFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .riskFile
    }

    var logger = Logger.log(FileNotSafeComponentFactory.self)

    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        let shouldDetectFile = self.context.getStaticFeatureGating("messenger.file.detect")
        if !shouldDetectFile {
            return false
        }
        let message = metaModel.message
        if message.isRecalled || message.dlpState == .dlpBlock || message.riskObjectKeys.isEmpty {
            return false
        }
        return true
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        self.logger.info("fileSafe: create messageid:\(metaModel.message.id)")
        return FileNotSafeComponentViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: FileNotSafeComponentBinder<M, D, C>(context: context)
        )
    }
}
