//
//  CellLifeCycleObseverDemo.swift
//  LarkMessageBase
//
//  Created by zc09v on 2022/4/27.
//

import Foundation

public final class CellLifeCycleObseverDemo: CellLifeCycleObsever {
    public init() {
    }

    public func initialized(metaModel: CellMetaModel, context: PageContext) {
    }

    public func willDisplay(metaModel: CellMetaModel, context: PageContext) {
        if !metaModel.message.getTextPostEnableUrls().isEmpty {
            print("CellLifeCycleObsever url \(metaModel.message.getTextPostEnableUrls().count)")
        } else {
            print("CellLifeCycleObsever url empty")
        }
    }
}
