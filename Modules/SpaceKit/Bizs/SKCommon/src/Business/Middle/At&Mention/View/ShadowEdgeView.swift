//
//  ShadowEdgeView.swift
//  Alamofire
//
//  Created by weidong fu on 18/3/2018.
//

import Foundation
import SKFoundation
import UniverseDesignColor

class ShadowEdgeView: UIView {
    enum Position: Int {
        case top
        case left
        case bottom
        case right
    }
    let position: Position
    init(frame: CGRect, color: UIColor = UIColor.ud.N1000, position: ShadowEdgeView.Position = .top) {
        self.position = position
        super.init(frame: frame)
        self.backgroundColor = color
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        configShadow()
    }

    fileprivate func configShadow() {
        self.layer.shadowColor = UIColor.ud.N1000.cgColor
        self.layer.shadowOpacity = 0.8
        self.layer.shadowRadius = 5
        self.layer.shadowOffset = CGSize(width: 0, height: 0)
        let path = UIBezierPath()
        switch position {
        case .top:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -1))
            path.addLine(to: CGPoint(x: self.frame.size.width, y: -1))
            path.addLine(to: CGPoint(x: self.frame.size.width, y: 0))
        case .left:
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 0, y: self.frame.size.height))
            path.addLine(to: CGPoint(x: 1, y: self.frame.size.height))
            path.addLine(to: CGPoint(x: 1, y: 0))
        default:
            spaceAssertionFailure("Unsupported")
        }
        self.layer.shadowPath = path.cgPath
    }
}
