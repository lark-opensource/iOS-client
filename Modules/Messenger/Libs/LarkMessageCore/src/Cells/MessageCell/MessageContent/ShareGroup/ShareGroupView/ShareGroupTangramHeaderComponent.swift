//
//  ShareGroupTangramHeaderComponent.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2023/6/21.
//

import Foundation
import TangramUIComponent
import AsyncComponent
import LarkTag

final public class ShareGroupTangramHeaderComponentProps: ASComponentProps {
    public var text: String = ""
    public var tag: Tag?
    public var titleNumberOfLines: Int = 1
}

public final class ShareGroupTangramHeaderComponent<C: Context>: ASComponent<ShareGroupTangramHeaderComponentProps, EmptyState, TangramHeaderView, C> {
    public override func create(_ rect: CGRect) -> TangramHeaderView {
        return TangramHeaderView(frame: rect)
    }

    public override func update(view: TangramHeaderView) {
        super.update(view: view)
        view.configure(with: self.headerConfig(), width: view.frame.width)
    }

    public override var isSelfSizing: Bool {
        return true
    }

    public override var isComplex: Bool {
        return true
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return TangramHeaderView.sizeThatFit(config: self.headerConfig(),
                                             size: size)
    }

    private func headerConfig() -> TangramHeaderConfig {
        return TangramHeaderConfig(title: props.text,
                                   titleColor: UIColor.ud.textTitle,
                                   titleNumberOfLines: props.titleNumberOfLines,
                                   iconProvider: nil,
                                   headerTag: TangramHeaderConfig.HeaderTag(tagType: props.tag?.type),
                                   theme: .light,
                                   showMenu: false,
                                   menuTapHandler: nil,
                                   customView: nil,
                                   customViewSize: .zero)
    }
}
