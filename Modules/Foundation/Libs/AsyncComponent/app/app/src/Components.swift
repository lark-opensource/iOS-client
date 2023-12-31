//
//  Components.swift
//  AsyncComponentDev
//
//  Created by qihongye on 2019/1/29.
//

import Foundation
import UIKit
import AsyncComponent
import UniverseDesignTheme

public class CornerRadiusComponent<C: Context>: ASComponent<ASComponentProps, EmptyState, CornerRadiusView, C> {
    public override func update(view: CornerRadiusView) {
        super.update(view: view)
        view.updateLayer(strokeColor: UIColor.blue, lineWidth: 2)
    }
}

class AvatarComponent<C: AsyncComponent.Context>: ASComponent<ASComponentProps, EmptyState, UIImageView, C> {
    override func update(view: UIImageView) {
        super.update(view: view)
    }
}

class UILabelProps: ASComponentProps {
    var text: String?
    var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    var numberOfLines: Int = 1
}

class UILabelComponent: ASComponent<UILabelProps, EmptyState, UILabel, EmptyContext> {
    override var isSelfSizing: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        guard let text = props.text else {
            return .zero
        }
        return NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: props.font])
            .componentTextSize(for: size, limitedToNumberOfLines: props.numberOfLines)
    }

    override func update(view: UILabel) {
        super.update(view: view)
        view.font = props.font
        view.text = props.text
        view.numberOfLines = props.numberOfLines
    }
}

class MyButton: UIControl {
    lazy var view: UIImageView = {
        return UIImageView()
    }()

    override var frame: CGRect {
        didSet {
            self.view.frame = CGRect(origin: .zero, size: frame.size)
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(view)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UIButtonComponent: ASComponent<UIButtonComponent.Props, EmptyState, MyButton, EmptyContext> {
    class Props: ASComponentProps {
        var title: String?
        var titleFont: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
        var touchUpInside: ((UIGestureRecognizer) -> Void)?
    }

    override var isSelfSizing: Bool {
        return true
    }

    override var isComplex: Bool {
        return true
    }

    override func sizeToFit(_ size: CGSize) -> CGSize {
        return CGSize(width: 24, height: 24)
    }

    override func update(view: MyButton) {
        super.update(view: view)
        if #available(iOS 13, *) {
            view.layer.backgroundColor = UIColor(dynamicProvider: { traitCollection in
                switch traitCollection.userInterfaceStyle {
                case .dark:
                    return UIColor.red
                default:
                    return UIColor.green
                }
            }).cgColor
        }
        view.removeTarget(nil, action: nil, for: .touchUpInside)
        view.addTarget(self, action: #selector(touchUpInside(sender:)), for: .touchUpInside)
    }

    @objc
    private func touchUpInside(sender: UIGestureRecognizer) {
        props.touchUpInside?(sender)
    }
}
