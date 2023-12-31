//
//  EnterpriseKeyPadLabel.swift
//  ByteView
//
//  Created by fakegourmet on 2021/10/20.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UniverseDesignColor
import Foundation
import ByteViewCommon

protocol EnterpriseKeyPadLabelDelegate: AnyObject {
    func label(_ label: EnterpriseKeyPadLabel, willChangeText text: String?) -> String?
    func label(_ label: EnterpriseKeyPadLabel, didChangeText text: String?)
    func labelDidCopyText(_ label: EnterpriseKeyPadLabel)
    func labelDidPasteText(_ label: EnterpriseKeyPadLabel)
}

extension EnterpriseKeyPadLabelDelegate {
    func label(_ label: EnterpriseKeyPadLabel, willChangeText text: String?) -> String? { nil }
    func label(_ label: EnterpriseKeyPadLabel, didChangeText text: String?) {}
    func labelDidCopyText(_ label: EnterpriseKeyPadLabel) {}
    func labelDidPasteText(_ label: EnterpriseKeyPadLabel) {}
}

class EnterpriseKeyPadLabel: UILabel {

    weak var delegate: EnterpriseKeyPadLabelDelegate?

    var labelTextDidChange: ((String?) -> Void)?

    var copyTitle = I18n.View_MV_Copy_BlackTab
    var pasteTitle = I18n.View_MV_Paste_BlackTab

    lazy var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(showMenu))

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.sharedInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.sharedInit()
    }

    func sharedInit() {
        self.adjustsFontSizeToFitWidth = true
        self.minimumScaleFactor = 0.8
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(tapGesture)
    }

    @objc func showMenu(sender: AnyObject?) {
        self.becomeFirstResponder()

        let menu = UIMenuController.shared
        guard !menu.isMenuVisible else {
            menu.setMenuVisible(false, animated: true)
            return
        }

        let customPasteMenu = UIMenuItem(title: pasteTitle, action: #selector(customPaste))
        if text?.isEmpty == false {
            let customCopyMenu = UIMenuItem(title: copyTitle, action: #selector(customCopy))
            menu.menuItems = [customCopyMenu, customPasteMenu]
        } else {
            menu.menuItems = [customPasteMenu]
        }

        if !menu.isMenuVisible {
            menu.arrowDirection = .up
            menu.setTargetRect(bounds, in: self)
            menu.setMenuVisible(true, animated: true)
        }
    }

    @objc func customCopy(_ sender: Any?) {
        delegate?.labelDidCopyText(self)
    }

    @objc func customPaste(_ sender: Any?) {
        delegate?.labelDidPasteText(self)
    }

    override var canBecomeFirstResponder: Bool {
        return true
    }

    override var text: String? {
        get {
            super.text
        }
        set {
            let newValue = delegate?.label(self, willChangeText: newValue)
            super.text = newValue
            if let string = newValue {
                attributedText = .init(string: string, config: .phoneNumber, alignment: .center, lineBreakMode: .byTruncatingHead,
                                       textColor: .ud.textTitle)
            } else {
                attributedText = nil
            }
            delegate?.label(self, didChangeText: newValue)
            labelTextDidChange?(newValue)
        }
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.inset(by: .init(top: -.greatestFiniteMagnitude,
                                      left: -.greatestFiniteMagnitude,
                                      bottom: -.greatestFiniteMagnitude,
                                      right: -.greatestFiniteMagnitude)).contains(point)
    }

    func append(_ string: String?, replaceLast: Bool = false) {
        if let text = self.text {
            if let string = string {
                if replaceLast, !text.isEmpty {
                    self.text = text[0..<text.count - 1] + string
                } else {
                    self.text = text + string
                }
            }
        } else {
            self.text = string
        }
    }

    func dropLast() {
        guard let attributedText = self.attributedText, attributedText.length > 0 else { return }
        let string = attributedText.string.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression)
        self.text = string.substring(from: 0, length: string.count - 1)
    }
}

fileprivate extension VCFontConfig {
    static let phoneNumber = VCFontConfig(fontSize: 32, lineHeight: 34, fontWeight: .medium)
}
