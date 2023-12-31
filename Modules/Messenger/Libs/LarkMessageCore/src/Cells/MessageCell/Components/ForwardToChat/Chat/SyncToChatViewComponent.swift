//
//  SyncToChatViewComponent.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2023/8/15.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent

public final class SyncToChatView: UIView {

    private lazy var gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        gradient.isHidden = true
        layer.insertSublayer(gradient, at: 0)
        return gradient
    }()

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        backgroundColor = UIColor.clear
    }
}

public final class SyncToChatViewComponent<C: AsyncComponent.Context>: ASComponent<SyncToChatViewComponent.Props, EmptyState, SyncToChatView, C> {
    public final class Props: ASComponentProps {
    }
}
