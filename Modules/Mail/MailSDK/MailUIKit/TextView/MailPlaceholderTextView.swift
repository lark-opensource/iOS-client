//
//  MailPlaceholderTextView.swift
//  MailSDK
//
//  Created by 谭志远 on 2019/12/30.
//

import Foundation
import UIKit

@IBDesignable
class MailPlaceholderTextView: UITextView {
    let placeholderLabel: UILabel = UILabel()
    private var placeholderLabelConstraints = [NSLayoutConstraint]()

    private struct Constants {
        static let defaultiOSPlaceholderColor = UIColor(red: 0.0, green: 0.0, blue: 0.0980392, alpha: 0.22)
    }

    override var font: UIFont? {
        didSet {
            if placeholderFont == nil {
                placeholderLabel.font = font
            }
        }
    }

    var placeholderFont: UIFont? {
        didSet {
            let font = (placeholderFont != nil) ? placeholderFont : self.font
            placeholderLabel.font = font
        }
    }

    override var text: String? {
      didSet {
          textDidChange()
      }
    }

    override var textAlignment: NSTextAlignment {
        didSet {
            placeholderLabel.textAlignment = textAlignment
        }
    }

    override var textContainerInset: UIEdgeInsets {
        didSet {
            updateConstraintsForPlaceholderLabel()
        }
    }

    override var attributedText: NSAttributedString? {
        didSet {
            textDidChange()
        }
    }

    @IBInspectable var placeholder: String = "" {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    @IBInspectable var placeholderColor: UIColor = MailPlaceholderTextView.Constants.defaultiOSPlaceholderColor {
        didSet {
            placeholderLabel.textColor = placeholderColor
        }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        #if swift(>=4.2)
        let notificationName = UITextView.textDidChangeNotification
        #else
        let notificationName = Notification.Name.UITextViewTextDidChange
        #endif
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: notificationName, object: nil)

        placeholderLabel.font = font
        placeholderLabel.numberOfLines = 0
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.textAlignment = textAlignment
        placeholderLabel.backgroundColor = UIColor.clear
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = placeholder

        addSubview(placeholderLabel)
        updateConstraintsForPlaceholderLabel()
    }

    deinit {
      #if swift(>=4.2)
        let notificationName = UITextView.textDidChangeNotification
      #else
        let notificationName = Notification.Name.UITextViewTextDidChange
      #endif
        NotificationCenter.default.removeObserver(self, name: notificationName, object: nil)
    }

    @objc
    private func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }

    override func layoutSubviews() {
       super.layoutSubviews()
       placeholderLabel.preferredMaxLayoutWidth = textContainer.size.width - textContainer.lineFragmentPadding * 2.0
    }

    private func updateConstraintsForPlaceholderLabel() {
        var newConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-(\(textContainerInset.left + textContainer.lineFragmentPadding))-[placeholder]",
            options: [],
            metrics: nil,
            views: ["placeholder": placeholderLabel])
        newConstraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-(\(textContainerInset.top))-[placeholder]",
            options: [],
            metrics: nil,
            views: ["placeholder": placeholderLabel])
        newConstraints.append(
            NSLayoutConstraint(
                item: placeholderLabel,
                attribute: .width,
                relatedBy: .equal,
                toItem: self,
                attribute: .width,
                multiplier: 1.0,
                constant: -(textContainerInset.left + textContainerInset.right + textContainer.lineFragmentPadding * 2.0))
        )
        removeConstraints(placeholderLabelConstraints)
        addConstraints(newConstraints)
        placeholderLabelConstraints = newConstraints
    }
}
