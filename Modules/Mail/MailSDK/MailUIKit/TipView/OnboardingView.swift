//
//  OnboardingView.swift
//  onboarding_demo
//
//  Created by Ryan on 2020/3/18.
//

import UIKit
import UniverseDesignColor

struct OnboardingItem {
    let title: String
    let content: String?
    let type: TargetType
    init(title: String, content: String? = nil, type: TargetType) {
        self.title = title
        self.content = content
        self.type = type
    }
}

enum TargetType {
    case point(getPoint: (() -> CGPoint))
    case rect(getRect: (() -> CGRect))
}

class TriangleView: UIView {
    let fillColor: UIColor
    let isPointUp: Bool
    static let height: CGFloat = 8
    static let width: CGFloat = 16

    init(fillColor: UIColor, isPointUp: Bool) {
        self.fillColor = fillColor
        self.isPointUp = isPointUp
        super.init(frame: .zero)
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.beginPath()
        let point1 = isPointUp ? CGPoint(x: rect.minX, y: rect.maxY) : CGPoint(x: 0, y: 0)
        let point2 = isPointUp ? CGPoint(x: rect.maxX, y: rect.maxY) : CGPoint(x: rect.maxX, y: 0)
        let point3 = isPointUp ? CGPoint(x: (rect.maxX / 2.0), y: rect.minY) : CGPoint(x: (rect.maxX / 2.0), y: rect.maxY)

        context.move(to: point1)
        context.addLine(to: point2)
        context.addLine(to: point3)
        context.closePath()
        context.setFillColor(fillColor.cgColor)
        context.fillPath()
    }
}
