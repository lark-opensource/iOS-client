//
//  SelectTranslateFactory.swift
//  LarkAI
//
//  Created by ByteDance on 2022/8/26.
//

import UIKit
import Foundation
import LarkMessageBase
import LarkContainer
import LarkSearchCore
import AsyncComponent

public final class SelectTranslateFactory<C: PageContext>: MessageSubFactory<C> {
    public override class var subType: SubType {
        return .selectTranslate
    }
    public override func canCreate<M: CellMetaModel>(with metaModel: M) -> Bool {
        return AIFeatureGating.selectTranslate.isUserEnabled(userResolver: context.userResolver)
    }

    public override func create<M: CellMetaModel, D: CellMetaModelDependency>(with metaModel: M, metaModelDependency: D) -> MessageSubViewModel<M, D, C> {
        return SelectTranslateViewModel(
            metaModel: metaModel,
            metaModelDependency: metaModelDependency,
            context: context,
            binder: SelectTranslateBinder<M, D, C>(context: context)
        )
    }

}

final public class SelectTranslateViewModel<M: CellMetaModel, D: CellMetaModelDependency, C: ViewModelContext>: MessageSubViewModel<M, D, C> {
    public override init(metaModel: M, metaModelDependency: D, context: C, binder: ComponentBinder<C>) {
        super.init(metaModel: metaModel, metaModelDependency: metaModelDependency, context: context, binder: binder)
    }

    public override func update(metaModel: M, metaModelDependency: D?) {
        super.update(metaModel: metaModel, metaModelDependency: metaModelDependency)
    }
}

final class SelectTranslateBinder<M: CellMetaModel, D: CellMetaModelDependency, C: ViewModelContext>: ComponentBinder<C> {
    public override var component: ComponentWithContext<C> {
        return UIViewComponent<C>(props: .empty, style: ASComponentStyle())
    }
}
