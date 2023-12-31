//
//  CopyableLabel.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/27.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import UniverseDesignToast

protocol CopyableLabelDelegate: AnyObject {
    func labelTextDidCopied(_ label: CopyableLabel)
}

class CopyableLabel: UILabel {

    var copyTitle: String = ""
    var completeTitle: String = ""

    weak var delegate: CopyableLabelDelegate?

    lazy var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(customCopy(_:)))

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.sharedInit()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func sharedInit() {
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tapGesture)
    }

    @objc func showMenu(sender: AnyObject?) {
        self.becomeFirstResponder()

        let menu = UIMenuController.shared
        let customCopyMenu = UIMenuItem(title: copyTitle, action: #selector(customCopy))
        menu.menuItems = [customCopyMenu]

        if !menu.isMenuVisible {
            menu.setTargetRect(bounds, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }

    @objc private func customCopy(_ tap: UITapGestureRecognizer) {
        delegate?.labelTextDidCopied(self)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
}
