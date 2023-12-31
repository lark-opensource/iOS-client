//
//  DefaultContentViewModel.swift
//  LarkThread
//
//  Created by liuwanlin on 2019/1/29.
//

import Foundation

// swiftlint:disable line_length
public final class DefaultContentViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ViewModelContext>: MessageSubViewModel<M, D, C> {
    public override var identifier: String {
        return "default"
    }

    override public var contentConfig: ContentConfig? {
        let threadStyleConfig = ThreadStyleConfig(addBorderBySelf: true)
        return ContentConfig(selectedEnable: false,
                             threadStyleConfig: threadStyleConfig)
    }
}
// swiftlint:enable line_length
