//
//  UrgentComponent.swift
//  LarkMessageCore
//
//  Created by 姚启灏 on 2019/9/8.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable

public final class UrgentComponent<C: Context>: ASComponent<ASComponentProps, EmptyState, CornerRadiusView, C> {

    private var urgent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        props.setImage = { $0.set(
            image: BundleResources.urgentIconLight
        )}

        let style = ASComponentStyle()
        style.position = .absolute
        style.width = 27
        style.height = 27
        style.left = 0
        style.top = 0
        return UIImageViewComponent<C>(props: props, style: style)
    }()

    public override init(props: ASComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.flexDirection = .column
        style.ui.masksToBounds = true
        super.init(props: props, style: style, context: context)
        setSubComponents([
            urgent
        ])
    }

    public override func create(_ rect: CGRect) -> CornerRadiusView {
        let view = CornerRadiusView()
        return view
    }

    public override func update(view: CornerRadiusView) {
        view.backgroundColor = UIColor.clear
        super.update(view: view)
    }
}
