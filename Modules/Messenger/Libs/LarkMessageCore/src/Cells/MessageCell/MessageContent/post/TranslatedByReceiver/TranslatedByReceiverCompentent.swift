//
//  TranslatedByReceiverCompentent.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2019/6/23.
//

import UIKit
import Foundation
import AsyncComponent

public final class TranslatedByReceiverCompentent<C: AsyncComponent.Context>: ASComponent<TranslatedByReceiverCompentent.Props, EmptyState, TappedView, C> {
    public final class Props: ASComponentProps {
        public var tapHandler: (() -> Void)?
    }

    private lazy var autoTranslatedByReceiver: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { $0.set(image: Resources.auto_translated_icon) }

        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.cornerRadius = 16.auto() / 2
        style.border = Border(BorderEdge(width: 1, color: UIColor.ud.primaryOnPrimaryFill, style: .solid))
        return UIImageViewComponent<C>(props: props, style: style, context: context)
    }()

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignItems = .center
        style.alignContent = .stretch
        style.justifyContent = .center

        setSubComponents([self.autoTranslatedByReceiver])
    }

    public override func create(_ rect: CGRect) -> TappedView {
        let view = TappedView(frame: rect)
        view.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        view.initEvent()
        view.isUserInteractionEnabled = true
        return view
    }

    public override func update(view: TappedView) {
        super.update(view: view)
        view.isUserInteractionEnabled = true
        view.onTapped = { [weak self] _ in
            guard let `self` = self else { return }
            self.props.tapHandler?()
        }
    }
}
