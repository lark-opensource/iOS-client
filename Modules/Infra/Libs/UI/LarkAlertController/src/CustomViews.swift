//
//  CustomViews.swift
//  LarkAlertController
//
//  Created by PGB on 2019/7/14.
//

/*

import Foundation
import SnapKit
import LarkInteraction
import UniverseDesignColor

class AlertButton: UIView {
    let weight: Double
    let action: (() -> Void)

    let button = UIButton(type: .system)

    init(text: String, textColor: UIColor, weight: Int, tapAction: @escaping () -> Void) {
        action = tapAction
        self.weight = Double(weight)
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 50))

        button.addTarget(self, action: #selector(onTapped), for: .touchUpInside)
        self.backgroundColor = UIColor.ud.bgFloat

        button.setTitle(text, for: .normal)
        button.setTitleColor(textColor, for: .normal)
        button.titleLabel?.textAlignment = .center
        addSubview(button)
        button.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        // add interaction on iPad
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .hover(prefersScaledContent: false))
            )
            self.addLKInteraction(pointer)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onTapped() {
        action()
    }

}

class Line: UIView {
    init() {
        super.init(frame: .zero)
        super.backgroundColor = UIColor.ud.lineDividerDefault
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

 */
import UIKit
