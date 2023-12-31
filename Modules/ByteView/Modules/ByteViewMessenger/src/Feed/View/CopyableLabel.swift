//
//  CopyableLabel.swift
//  ByteViewMessenger
//
//  Created by lutingting on 2022/9/19.
//

import Foundation

protocol CopyableLabelDelegate: AnyObject {
    func labelTextDidCopied(_ label: CopyableLabel)
}

class CopyableLabel: UILabel {

    var copyTitle: String = ""
    var completeTitle: String = ""

    weak var delegate: CopyableLabelDelegate?

    lazy var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.customCopy))

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

    @objc func customCopy(_ sender: Any?) {
        delegate?.labelTextDidCopied(self)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }
}
