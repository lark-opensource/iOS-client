//
//  JoinRoomNameLabel.swift
//  ByteView
//
//  Created by kiri on 2023/3/13.
//

import Foundation
import UniverseDesignIcon
import ByteViewCommon
import ByteViewUI

final class JoinRoomNameLabel: UIView {
    private let textStyle: VCFontConfig = .body
    private(set) lazy var scanAgainButton: UIButton = JoinRoomScanAgainButton()
    private(set) lazy var textLabel = AttachmentLabel()
    private lazy var scanAgainWidth: CGFloat = 28 + I18n.View_G_ScanAgain_ClickText.vc.boundingWidth(height: 20, config: .bodyAssist)
    private let minHeight: CGFloat

    init(minHeight: CGFloat = 0) {
        self.minHeight = minHeight
        super.init(frame: CGRect(x: 0, y: 0, width: 100, height: max(22, minHeight)))
        addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets.zero)
            make.height.equalTo(max(22, minHeight))
        }

        self.textLabel.backgroundColor = .clear
        self.textLabel.contentFont = textStyle.font
        self.textLabel.preferredMaxLayoutWidth = 320
        self.textLabel.numberOfLines = 0
        self.textLabel.textAlignment = .center
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var preferredMaxLayoutWidth: CGFloat {
        get { textLabel.preferredMaxLayoutWidth }
        set { textLabel.preferredMaxLayoutWidth = newValue }
    }

    private(set) var contentHeight: CGFloat = 0
    private var textLabelHeight: CGFloat = 0
    func setName(_ name: String?, buttonType: ButtonType?, textColor: UIColor? = nil) {
        self.textLabel.reset()
        guard var name = name else { return }
        if buttonType != nil {
            name += "  "
        }
        let color = textColor ?? .ud.textTitle
        self.textLabel.addAttributedString(NSAttributedString(string: name, config: textStyle, textColor: color))
        if let buttonType = buttonType {
            switch buttonType {
            case .scanAgain:
                let buttonSize = CGSize(width: scanAgainWidth, height: 20)
                scanAgainButton.frame = CGRect(origin: .zero, size: buttonSize)
                self.textLabel.addArrangedSubview(scanAgainButton) {
                    $0.margin = .init(top: 0, left: -4, bottom: 0, right: 0)
                    $0.size = buttonSize
                }
            }
        }
        self.textLabel.reload()
        self.updateHeightConstraints()
    }

    func updateHeightConstraints() {
        if self.preferredMaxLayoutWidth > 0 {
            let maxHeight: CGFloat = textLabel.numberOfLines > 0 ? textStyle.lineHeight * CGFloat(textLabel.numberOfLines) : .greatestFiniteMagnitude
            // 会fit出23/45/68之类的高度
            let fitSize = textLabel.sizeThatFits(CGSize(width: textLabel.preferredMaxLayoutWidth, height: maxHeight))
            let textHeight = max(minHeight, fitSize.height)
            let contentHeight = textHeight > minHeight ? ((round(textHeight / textStyle.lineHeight)) * textStyle.lineHeight) : minHeight
            if self.textLabelHeight != textHeight || self.contentHeight != contentHeight {
                self.textLabelHeight = textHeight
                self.contentHeight = contentHeight
                let offset = contentHeight - textHeight
                let insets = UIEdgeInsets(top: 0, left: 0, bottom: offset, right: 0)
                self.textLabel.snp.updateConstraints { make in
                    make.edges.equalToSuperview().inset(insets)
                    make.height.equalTo(textHeight)
                }
            }
        }
    }

    private func calcLabelHeight() -> CGFloat {
        let maxHeight = textLabel.numberOfLines > 0 ? textStyle.lineHeight * CGFloat(textLabel.numberOfLines) : .greatestFiniteMagnitude
        let fitSize = textLabel.sizeThatFits(CGSize(width: textLabel.preferredMaxLayoutWidth, height: maxHeight))
        return max(minHeight, fitSize.height) // 会fit出23/45/68之类的高度。。
    }

    enum ButtonType {
        case scanAgain
    }
}

private final class JoinRoomScanAgainButton: UIButton {
    convenience init() {
        self.init(type: .custom)
        let iconSize = CGSize(width: 16, height: 16)
        self.setImage(UDIcon.getIconByKey(.refreshOutlined, iconColor: .ud.primaryContentDefault, size: iconSize), for: .normal)
        let font = VCFontConfig.bodyAssist.font
        self.setAttributedTitle(NSAttributedString(string: I18n.View_G_ScanAgain_ClickText, attributes: [.font: font, .baselineOffset: -0.5, .foregroundColor: UIColor.ud.primaryContentDefault]), for: .normal)
        self.vc.setBackgroundColor(UIColor.clear, for: .normal)
        self.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgPriPressed, for: .highlighted)
        self.addInteraction(type: .highlight)
        self.adjustsImageWhenHighlighted = false
        self.layer.cornerRadius = 6.0
        self.layer.masksToBounds = true
        self.imageEdgeInsets = .init(top: 0, left: -4, bottom: 0, right: 4)
        self.contentEdgeInsets = .init(top: 0, left: 8, bottom: 0, right: 4)
    }
}
