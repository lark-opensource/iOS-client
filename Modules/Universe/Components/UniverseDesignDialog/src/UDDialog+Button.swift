//
//  UDDialog+Button.swift
//  UniverseDesignDialog
//
//  Created by 姚启灏 on 2020/10/14.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignColor

public enum UDButtonPriority: Int {
    case priority
    case destructive
    case secondary
}

/// UDDialog Button Layout Style
public enum UDDialogButtonLayoutStyle {
    /// normal
    case normal
    /// horizontal
    case horizontal
    /// vertical
    case vertical
}

class UDDialogButton: UIView {
    let action: (() -> Void)
    let text: String
    let priority: UDButtonPriority

    let button = UIButton(type: .custom)

    init(text: String,
         textColor: UIColor,
         normalBgColor: UIColor = .clear,
         pressBgColor: UIColor = UDColor.fillPressed,
         priority: UDButtonPriority,
         tapAction: @escaping () -> Void) {
        self.action = tapAction
        self.text = text
        self.priority = priority
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 50))

        button.addTarget(self, action: #selector(onTapped), for: .touchUpInside)
        button.setTitle(text, for: .normal)
        button.setTitleColor(textColor, for: .normal)
        button.titleLabel?.textAlignment = .center
        button.setBackgroundImage(UIColor.ud.image(with: normalBgColor,
                                                   size: CGSize(width: 1, height: 1),
                                                   scale: UIScreen.main.scale),
                                  for: .normal)
        button.setBackgroundImage(UIColor.ud.image(with: pressBgColor,
                                                   size: CGSize(width: 1, height: 1),
                                                   scale: UIScreen.main.scale),
                                  for: .highlighted)
        addSubview(button)
        button.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        button.titleLabel?.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().inset(20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func isOverWidth(maxWidth: CGFloat) -> Bool {
        guard let font = button.titleLabel?.font else { return false }
        let rect = NSString(string: text).boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: 50),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font ], context: nil)
        let textWidth = ceil(rect.width)

        return textWidth > maxWidth - 2*20
    }

    @objc
    private func onTapped() {
        action()
    }
}
