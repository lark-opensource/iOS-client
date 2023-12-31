//
//  TCPreviewComponent.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2021/4/23.
//

import UIKit
import Foundation
import AsyncComponent
import TangramComponent

protocol TCPreviewRenderCallback: AnyObject {
    func beforeRender()
    func afterRender()
}

public extension TCPreviewComponent {
    final class Props: ASComponentProps {
        var renderer: ComponentRenderer?
        var onTap: TCPreviewWrapperView.OnTap?
        weak var renderCallback: TCPreviewRenderCallback?

        init(renderer: ComponentRenderer?) {
            self.renderer = renderer
        }
    }
}

public final class TCPreviewComponent<C: AsyncComponent.Context>: ASComponent<TCPreviewComponent.Props, EmptyState, TCPreviewWrapperView, C> {
    public override var isSelfSizing: Bool {
        return true
    }

    public override var isLeaf: Bool {
        return true
    }

    public override var isComplex: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return props.renderer?.boundingRect.size ?? .zero
    }

    public override func create(_ rect: CGRect) -> TCPreviewWrapperView {
        let view = super.create(rect)
        // update时机会触发，create时可去除
        // props.renderer.bind(to: view.tcContainer)
        // props.renderer.render()
        return view
    }

    public override func update(view: TCPreviewWrapperView) {
        props.renderCallback?.beforeRender()
        super.update(view: view)
        // view可能被复用而不会走create，此处需要重新bind & render
        props.renderer?.bind(to: view.tcContainer)
        props.renderer?.render()
        view.onTap = props.onTap
        props.renderCallback?.afterRender()
    }
}
