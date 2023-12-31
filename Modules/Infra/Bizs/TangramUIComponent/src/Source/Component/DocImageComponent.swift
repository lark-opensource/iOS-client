//
//  DocImageComponent.swift
//  TangramUIComponent
//
//  Created by 袁平 on 2021/12/2.
//

import Foundation
import TangramComponent
import TangramUIComponent

public final class DocImageComponentProps: Props {
    public var setImageTask: EquatableWrapper<ImageViewAlignedWrapper.SetImageTask?> = .init(value: nil)
    /// identifier相同时，复用不再触发刷新
    public var identifier: String?

    public init() {}

    public func clone() -> DocImageComponentProps {
        let clone = DocImageComponentProps()
        clone.setImageTask = setImageTask
        clone.identifier = identifier
        return clone
    }

    public func equalTo(_ old: Props) -> Bool {
        guard let old = old as? DocImageComponentProps else { return false }
        return old.setImageTask == setImageTask &&
            old.identifier == identifier
    }
}

public final class DocImageComponent<C: Context>: RenderComponent<DocImageComponentProps, ImageViewAlignedWrapper, C> {
    public override func create(_ rect: CGRect) -> ImageViewAlignedWrapper {
        let view = super.create(rect)
        view.realImageView.ud.setMaskView()
        return view
    }

    public override func update(_ view: ImageViewAlignedWrapper) {
        super.update(view)
        view.setImage(identifier: props.identifier, task: props.setImageTask.value)
    }
}
