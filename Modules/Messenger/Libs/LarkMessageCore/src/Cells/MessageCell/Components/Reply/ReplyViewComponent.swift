//
//  ReplyView.swift
//  LarkMessageCore
//
//  Created by 姚启灏 on 2019/12/23.
//

import UIKit
import Foundation
import EEFlexiable
import AsyncComponent

public final class ReplyView: UIView {

    private lazy var gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        gradient.isHidden = true
        layer.insertSublayer(gradient, at: 0)
        return gradient
    }()

    private var colors: [UIColor] = []

    public func setBackground(colors: [UIColor]) {
        self.colors = colors
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        self.setBackgroundColors()
        CATransaction.commit()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        self.setBackgroundColors()
    }

    private func setBackgroundColors() {
        gradientLayer.isHidden = colors.count < 2
        switch colors.count {
        case 1:
            backgroundColor = colors.first
        case 2...:
            backgroundColor = nil
            gradientLayer.colors = colors.map { $0.cgColor }
            gradientLayer.locations = colors.enumerated().map { NSNumber(value: Float($0.offset) / Float(colors.count - 1)) }
        default:
            backgroundColor = UIColor.clear
        }
    }
}

public final class ReplyViewComponent<C: AsyncComponent.Context>: ASComponent<ReplyViewComponent.Props, EmptyState, ReplyView, C> {
    public final class Props: ASComponentProps {
        public var bgColors: [UIColor] = []
    }

    public override init(props: ReplyViewComponent.Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
    }

    public override func create(_ rect: CGRect) -> ReplyView {
        let view = ReplyView(frame: rect)
        view.setBackground(colors: props.bgColors)
        return view
    }

    public override func update(view: ReplyView) {
        super.update(view: view)
        view.setBackground(colors: props.bgColors)
    }

}
