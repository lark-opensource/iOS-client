//
//  BubbleView.swift
//  LarkMessageCore
//
//  Created by qihongye on 2019/5/18.
//

import UIKit
import Foundation
import AsyncComponent
import UniverseDesignTheme

public class BubbleView: CornerRadiusView {
    public override init(frame: CGRect) {
        super.init(frame: .zero)
        self.accessibilityIdentifier = "bubble_view"
        self.isUserInteractionEnabled = true
        self.cornerRadiusLayer.isHidden = false
        self.updateConfig(BorderRadius(topLeft: 8))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func updateConfig(_ config: BorderRadius) {
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        super.updateConfig(config)
        CATransaction.commit()
    }

    public override func updateLayer(strokeColor: UIColor = UIColor.ud.staticBlack,
                                     fillColor: UIColor? = nil,
                                     lineWidth: CGFloat = 1,
                                     showBoder: Bool = false) {
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        super.updateLayer(strokeColor: strokeColor, fillColor: fillColor, lineWidth: lineWidth, showBoder: showBoder)
        CATransaction.commit()
    }

    override public func layoutSubviews() {
        CATransaction.begin()
        CATransaction.setValue(true, forKey: kCATransactionDisableActions)
        super.layoutSubviews()
        CATransaction.commit()
    }

    public func update(changeTopLeftRadius: Bool = false, changeBottomLeftRadius: Bool = false) {
        let config = BorderRadius(topLeft: changeTopLeftRadius ? 2 : 8,
                                  topRight: 8,
                                  bottomRight: 8,
                                  bottomLeft: changeBottomLeftRadius ? 2 : 8)
        self.updateConfig(config)
    }

    public func update(changeTopRightRadius: Bool = false, changeBottomRightRadius: Bool = false) {
        let config = BorderRadius(topLeft: 8,
                                  topRight: changeTopRightRadius ? 2 : 8,
                                  bottomRight: changeBottomRightRadius ? 2 : 8,
                                  bottomLeft: 8)
        self.updateConfig(config)
    }
}

// 气泡的高亮前景View
public final class HighlightFrontBubbleView: BubbleView, CanHighlightFront {
    public func setHighlighted(_ isHighlighted: Bool) {
        if isHighlighted {
            cornerRadiusLayer.opacity = 0.08
            cornerRadiusLayer.ud.setFillColor(.ud.N900)
            self.isHidden = false
        } else {
            self.isHidden = true
            cornerRadiusLayer.opacity = 0
            cornerRadiusLayer.ud.setFillColor(.clear)
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.accessibilityIdentifier = "bubble_highlight_view"
        self.cornerRadiusLayer.opacity = 0
        self.isHidden = true
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        return nil
    }
}

// 除会话外场景的 前景高亮View
public final class HighlightFrontRectangleView: UIView, CanHighlightFront {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.alpha = 0
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public func setHighlighted(_ isHighlighted: Bool) {
        self.alpha = isHighlighted ? 0.08 : 0
    }
}

public protocol CanHighlightFront {
    func setHighlighted(_ isHighlighted: Bool)
}
