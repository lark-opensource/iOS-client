//
//  UILabel+Tappable.swift
//  LarkAI
//
//  Created by Hayden Wang on 2023/6/13.
//

import UIKit

class LabelTapGesture: UITapGestureRecognizer {
    var tapOnText: String?
    var completion: (() -> Void)?
}

extension String {

    func attributed(_ attributes: [NSAttributedString.Key: Any]?) -> NSMutableAttributedString {
        return NSMutableAttributedString(string: self, attributes: attributes)
    }

    func range(of rangeText: String) -> NSRange {
        return (self as NSString).range(of: rangeText)
    }
}

extension UILabel {

    public func addTapGesture(text: String, textAttributes: [NSAttributedString.Key: Any]? = nil,
                              tapOnText: String, tapOnTextAttributes: [NSAttributedString.Key: Any],
                              completion: @escaping () -> Void) {
        let attributedString = text.attributed(textAttributes)
        attributedString.addAttributes(tapOnTextAttributes, range: text.range(of: tapOnText))
        self.isUserInteractionEnabled = true
        self.attributedText = attributedString
        let tapgesture: LabelTapGesture = .init(target: self, action: #selector(self.tappedOnAttributedText(_:)))
        tapgesture.numberOfTapsRequired = 1
        tapgesture.tapOnText = tapOnText
        tapgesture.completion = completion
        self.addGestureRecognizer(tapgesture)
    }

    @objc
    private func tappedOnAttributedText(_ gesture: LabelTapGesture) {
        guard let text = self.text,
              let tapOnText = gesture.tapOnText,
              let completion = gesture.completion else { return }
        guard gesture.didTapAttributedTextInLabel(label: self, inRange: text.range(of: tapOnText)) else { return }
        completion()
    }
}

extension UITapGestureRecognizer {

    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        guard let attributedText = label.attributedText else { return false }
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: .zero)
        let textStorage = NSTextStorage(attributedString: attributedText)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize

        // Find the tapped character location and compare it to the specified range
        let locationOfTouchInLabel = self.location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
                                          y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x,
                                                     y: locationOfTouchInLabel.y - textContainerOffset.y)
        var indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}
