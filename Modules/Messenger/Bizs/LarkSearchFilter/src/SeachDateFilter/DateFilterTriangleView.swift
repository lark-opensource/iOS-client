//
//  DateFilterTriangleView.swift
//  LarkSearch
//
//  Created by SuPeng on 4/18/19.
//

import UIKit
import Foundation

final class DateFilterTriangleView: UIView {

    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.clear
        self.isOpaque = false
    }

    var color: UIColor = UIColor.clear {
        didSet {
            self.setNeedsDisplay()
        }
    }

    var style: DateFilerItemViewStyle = .left {
        didSet {
            self.setNeedsDisplay()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        let aPath = UIBezierPath()
        switch style {
        case .left:
            aPath.lineWidth = 1.0 / UIScreen.main.scale
            aPath.move(to: .zero)
            aPath.addLine(to: CGPoint(x: rect.size.width, y: 0))
            aPath.addLine(to: CGPoint(x: 0, y: rect.size.height))
        case .right:
            aPath.lineWidth = 1.0 / UIScreen.main.scale
            aPath.move(to: CGPoint(x: rect.size.width, y: 0))
            aPath.addLine(to: CGPoint(x: 0, y: rect.size.height))
            aPath.addLine(to: CGPoint(x: rect.size.width, y: rect.size.height))
        }
        aPath.close()
        color.setFill()
        aPath.fill()
    }
}
