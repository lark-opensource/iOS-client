//
//  TrangleView.swift
//  Pods-LarkUIKit
//
//  Created by ChalrieSu on 2018/9/5.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignTheme

public enum TrangleViewDirection {
    case up, left, right, down
}

public final class TrangleView: UIView {
    private let direction: TrangleViewDirection
    private let fillColor: UIColor

    public init(direction: TrangleViewDirection = .up, fillColor: UIColor = UIColor.ud.bgBody) {
        self.direction = direction
        self.fillColor = fillColor
        super.init(frame: .zero)
        backgroundColor = .clear
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func draw(_ rect: CGRect) {
        let path = UIBezierPath()
        switch direction {
        case .up:
            path.move(to: bounds.topCenter)
            path.addLine(to: bounds.bottomRight)
            path.addLine(to: bounds.bottomLeft)
        case .left:
            path.move(to: bounds.centerLeft)
            path.addLine(to: bounds.bottomRight)
            path.addLine(to: bounds.topRight)
        case .right:
            path.move(to: bounds.centerRight)
            path.addLine(to: bounds.bottomLeft)
            path.addLine(to: bounds.topLeft)
        case .down:
            path.move(to: bounds.bottomCenter)
            path.addLine(to: bounds.topRight)
            path.addLine(to: bounds.topLeft)
        }
        fillColor.setFill()
        path.close()
        path.fill()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
    }
}
