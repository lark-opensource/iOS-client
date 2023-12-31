//
//  UltrawaveDoubleCheckView.swift
//  ByteView
//
//  Created by Tobb Huang on 2021/6/21.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import Action
import RichLabel
import ByteViewUI

class UltrawaveDoubleCheckView: UIView {

    struct Layout {
        static let wrongCodeFont: UIFont = UIFont.systemFont(ofSize: 14, weight: .regular)
    }

    private lazy var externalWidth = externalString.vc.boundingWidth(height: .greatestFiniteMagnitude, font: .systemFont(ofSize: 12, weight: .medium))
    lazy var externalLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: externalString, config: .assist)
        label.textColor = UIColor.ud.udtokenTagTextSRed
        label.backgroundColor = UIColor.ud.udtokenTagBgRed
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 4
        label.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 999.0), for: .horizontal)
        return label
    }()

    private lazy var titleFont = UIFont.systemFont(ofSize: 20, weight: .medium)
    private lazy var titleParagraphStyle: NSParagraphStyle = {
        let lineHeight: CGFloat = 28
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = lineHeight
        style.maximumLineHeight = lineHeight
        style.lineBreakMode = .byWordWrapping
        return style
    }()

    lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 12
        return view
    }()

    lazy var nameLabel: AttachmentLabel = {
        let label = AttachmentLabel()
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 0
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.contentFont = titleFont
        label.contentParagraphStyle = titleParagraphStyle
        return label
    }()

    lazy var wrongCodeLabel: LKLabel = {
        let label = LKLabel()
        label.font = Layout.wrongCodeFont
        label.numberOfLines = 0
        label.backgroundColor = UIColor.clear
        label.textAlignment = .center
        return label
    }()

    private let externalString: String

    init(roomName: String, isExternal: Bool, externalString: String, showManualInput: Bool, handler: @escaping (() -> Void)) {
        self.externalString = externalString
        super.init(frame: .zero)

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(nameLabel)
        stackView.addArrangedSubview(wrongCodeLabel)

        nameLabel.addAttributedString(NSMutableAttributedString(string: roomName,
                                                                config: .h2,
                                                                alignment: .center,
                                                                lineBreakMode: .byWordWrapping,
                                                                textColor: UIColor.ud.textTitle))
        nameLabel.addArrangedSubview(externalLabel) {
            $0.margin = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
            $0.size = CGSize(width: self.externalWidth + 8, height: 18)
        }
        nameLabel.preferredMaxLayoutWidth = ByteViewDialog.calculatedContentWidth()
        externalLabel.isHidden = !isExternal
        nameLabel.reload()

        wrongCodeLabel.isHidden = !showManualInput
        if showManualInput {
            handleTextWithLineBreak(handler: handler)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func handleTextWithLineBreak(handler: @escaping (() -> Void)) {
        var text = I18n.View_G_ShareScreen_NotThisRoomEnterCodeID_Text
        let maxWidth = ByteViewDialog.calculatedContentWidth()
        if let (content, range) = StringUtil.handleTextWithLineBreak(text, font: Layout.wrongCodeFont, maxWidth: maxWidth) {
            text = content
            let attributes = [NSAttributedString.Key.foregroundColor: UIColor.ud.colorfulBlue,
                              NSAttributedString.Key.backgroundColor: UIColor.clear,
                              NSAttributedString.Key.font: Layout.wrongCodeFont]
            var link = LKTextLink(range: range,
                                  type: .link,
                                  attributes: attributes,
                                  activeAttributes: attributes,
                                  inactiveAttributes: attributes)
            link.linkTapBlock = { (_, _) in
                handler()
            }
            wrongCodeLabel.removeLKTextLink()
            wrongCodeLabel.addLKTextLink(link: link)
        }
        wrongCodeLabel.attributedText = NSAttributedString.init(string: text,
                                                                config: .bodyAssist,
                                                                alignment: .center,
                                                                lineBreakMode: .byWordWrapping,
                                                                textColor: UIColor.ud.textPlaceholder)
    }
}
