//
//  V3CursorView.swift
//  SuiteLogin
//
//  Created by quyiming on 2020/1/5.
//

import Foundation

class V3CursorView: ShapeLayerContainerView {

    init() {
        super.init(frame: .zero)
        isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(show: Bool, animated: Bool) {
        if show {
            if let opacity = V3Animation.opacityAnimation() {
                layer.add(opacity, forKey: "kOpacityAnimation")
            }
        } else {
            layer.removeAnimation(forKey: "kOpacityAnimation")
        }
        func updateHighlight() {
            isHidden = !show
        }
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                updateHighlight()
            })
        } else {
            updateHighlight()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawCursor()
    }

    func drawCursor() {
        let path = CGPath(rect: bounds, transform: nil)
        shapeLayer?.path = path
        shapeLayer?.ud.setFillColor(UIColor.ud.primaryContentDefault)
    }

}

extension V3CursorView {
    struct Layout {
        static let cursorWidth: CGFloat = 1.5
        static let topPadding: CGFloat = 12.5
        static let bottomPadding: CGFloat = 12.5
    }
}
