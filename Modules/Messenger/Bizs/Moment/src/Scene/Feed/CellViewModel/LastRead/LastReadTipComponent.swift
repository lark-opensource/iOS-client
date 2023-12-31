//
//  LastReadTipComponent.swift
//  Moment
//
//  Created by liluobin on 2023/9/20.
//

import Foundation
import AsyncComponent
import UIKit

final class LastReadTipComponent<C: AsyncComponent.Context>: ASComponent<LastReadTipComponent.Props, EmptyState, LastReadTipView, C> {

    final class Props: ASComponentProps {
        var tap: (() -> Void)?
    }

    override var isSelfSizing: Bool {
        return true
    }

    override var isComplex: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        return CGSize(width: size.width, height: LastReadTipView.heightForSize(size))
    }

    override func update(view: LastReadTipView) {
        super.update(view: view)
        view.tapCallBack = props.tap
    }
}
