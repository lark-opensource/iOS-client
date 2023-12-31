//
//  KeyboardExpandButton.swift
//  LarkKeyboardView
//
//  Created by liluobin on 2023/3/10.
//

import UIKit
import LarkInteraction

public class KeyboardExpandButton: UIButton {
    var buttonTapped: ((UIButton) -> Void)?

    public init(buttonTapped: ((UIButton) -> Void)?) {
        self.buttonTapped = buttonTapped
        super.init(frame: .zero)
        let normalImage: UIImage = Resources.expand
        let selectedImage: UIImage = Resources.expand_selected
        setImage(normalImage, for: .normal)
        setImage(selectedImage, for: .selected)
        setImage(selectedImage, for: .highlighted)
        self.addTarget(self, action: #selector(expandButtonTapped), for: .touchUpInside)
        if #available(iOS 13.4, *) {
            self.lkPointerStyle = PointerStyle(
                effect: .highlight,
                shape: .roundedSize({ (_, _) -> (CGSize, CGFloat) in
                    return (Cons.buttonHotspotSize, 8)
                }),
                targetProvider: .init { (interaction, _) -> UITargetedPreview? in
                    guard let view = interaction.view, let superview = view.superview?.superview else {
                        return nil
                    }
                    let targetCenter = view.convert(view.bounds.center, to: superview)
                    let target = UIPreviewTarget(container: superview, center: targetCenter)
                    let parameters = UIPreviewParameters()
                    return UITargetedPreview(
                        view: view,
                        parameters: parameters,
                        target: target
                    )
                })
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func expandButtonTapped() {
        self.buttonTapped?(self)
    }
}

extension KeyboardExpandButton {
    enum Cons {
        static var buttonHotspotSize: CGSize { .square(44) }
    }
}
