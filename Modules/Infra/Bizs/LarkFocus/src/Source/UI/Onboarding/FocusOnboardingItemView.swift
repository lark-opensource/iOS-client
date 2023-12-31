//
//  FocusOnboardingItemView.swift
//  LarkFocus
//
//  Created by Hayden Wang on 2021/9/21.
//

import Foundation
import UIKit

final class FocusOnboardingItemView: UIView {

    var tappableRange: NSRange?
    var tapHandler: (() -> Void)?

    func set(icon: UIImage, title: String, detail: String, tappableText: String? = nil, tapHandler: (() -> Void)? = nil) {
        imageView.image = icon
        titleLabel.text = title
        // 标记高亮文字
        if let tappableText = tappableText {
            let attributedDetail = NSMutableAttributedString(string: detail + " " + tappableText)
            let range = attributedDetail.mutableString.range(of: tappableText, options: .caseInsensitive)
            self.tappableRange = range
            self.tapHandler = tapHandler
            attributedDetail.addAttribute(.foregroundColor, value: UIColor.ud.primaryContentDefault, range: range)
            detailLabel.attributedText = attributedDetail
            detailLabel.isUserInteractionEnabled = true
            detailLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapDetailLabel(_:))))
        } else {
            let attributedDetail = NSMutableAttributedString(string: detail)
            detailLabel.attributedText = attributedDetail
        }
    }

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    private lazy var detailLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(detailLabel)
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.leading.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(16)
            make.top.trailing.equalToSuperview()
        }
        detailLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.bottom.trailing.equalToSuperview()
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
    }

    @objc
    private func didTapDetailLabel(_ gesture: UITapGestureRecognizer) {
        guard let range = tappableRange else { return }
        guard gesture.didTapAttributedTextInLabel(label: detailLabel, inRange: range) else { return }
        tapHandler?()
    }
}

extension UITapGestureRecognizer {

    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)

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

        let textContainerOffset = CGPoint(
            x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x,
            y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y
        )

        let locationOfTouchInTextContainer = CGPoint(
            x: locationOfTouchInLabel.x - textContainerOffset.x,
            y: locationOfTouchInLabel.y - textContainerOffset.y
        )
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}
