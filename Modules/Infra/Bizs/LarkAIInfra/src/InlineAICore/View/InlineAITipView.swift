//
//  InlineAITipView.swift
//  LarkInlineAI
//
//  Created by Guoxinyi on 2023/4/26.
//

import Foundation
import UIKit
import UniverseDesignColor
import UniverseDesignIcon

class InlineAITipView: InlineAIItemBaseView {
    
    struct Layout {
        static let topMargin: CGFloat = 12
        static let bottomMargin: CGFloat = 4
        static let thumbsIconSize: CGSize = CGSize(width: 18, height: 18)
        static let iconLeft: CGFloat = 0
        static let iconSize: CGSize = CGSize(width: 16, height: 16)
        static let textLeft: CGFloat = 4
        static let textRightWithButton: CGFloat = 76
        static let textRightWithoutButton: CGFloat = 8
    }
    
    lazy var iconView: UIImageView = {
        let icon = UIImageView(frame: .zero)
        icon.image = UDIcon.getIconByKey(.infoOutlined, iconColor: UDColor.iconDisabled)
        return icon
    }()
    
    lazy var paragraphStyle: NSMutableParagraphStyle = {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 6
        return style
    }()

    lazy var tipLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UDColor.textDisabled
        label.numberOfLines = 0
        return label
    }()
    
    var leftRightInset: CGFloat = 0
    
    lazy var thumbsupButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UDIcon.getIconByKey(.thumbsupOutlined, iconColor: UDColor.iconN3, size: Layout.thumbsIconSize), for: .normal)
        btn.setImage(UDIcon.getIconByKey(.thumbsupFilled, iconColor: UDColor.yellow, size: Layout.thumbsIconSize), for: .selected)
        btn.addTarget(self, action: #selector(didClickThumbUpBtn), for: .touchUpInside)
        btn.hitTestEdgeInsets = .init(top: -12, left: -12, bottom: -8, right: -8)
        return btn
    }()
    
    lazy var thumbsdownButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UDIcon.getIconByKey(.thumbdownOutlined, iconColor: UDColor.iconN3, size: Layout.thumbsIconSize), for: .normal)
        btn.setImage(UDIcon.getIconByKey(.thumbdownFilled, iconColor: UDColor.iconN3, size: Layout.thumbsIconSize), for: .selected)
        btn.addTarget(self, action: #selector(didClickThumbDownBtn), for: .touchUpInside)
        btn.hitTestEdgeInsets = .init(top: -12, left: -8, bottom: -8, right: -12)
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UDColor.bgFloat
        
        self.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.left.equalTo(Layout.iconLeft)
            make.width.height.equalTo(Layout.iconSize)
            make.top.equalToSuperview().offset(Layout.topMargin)
        }
        
        self.addSubview(thumbsdownButton)
        thumbsdownButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-2)
            make.size.equalTo(Layout.thumbsIconSize)
            make.centerY.equalTo(iconView)
        }
        
        self.addSubview(thumbsupButton)
        thumbsupButton.snp.makeConstraints { make in
            make.right.equalTo(thumbsdownButton.snp.left).offset(-16)
            make.size.equalTo(Layout.thumbsIconSize)
            make.centerY.equalTo(iconView)
        }
        
        
        self.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(Layout.textLeft)
            make.right.equalToSuperview().inset(Layout.textRightWithoutButton)
            make.height.equalTo(18)
            make.top.equalToSuperview().offset(Layout.topMargin)
            make.bottom.equalToSuperview().inset(Layout.bottomMargin)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var showThumbs = false
    
    
    func getDisplayHeight() -> CGFloat {
        let height = caculateTextHeight() + Layout.topMargin + Layout.bottomMargin
        if showThumbs {
            return max(height, 32)
        } else {
            return height
        }
    }
    
    func updateTipContent(showTip: Bool, text: String, showThumbs: Bool, thumbsUp: Bool, thumbsDown: Bool) {
        tipLabel.isHidden = !showTip
        iconView.isHidden = !showTip
        thumbsupButton.isHidden = !showThumbs
        thumbsdownButton.isHidden = !showThumbs
        tipLabel.attributedText = NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: 12), .paragraphStyle: paragraphStyle])
        self.showThumbs = showThumbs
        if showThumbs {
            thumbsupButton.isSelected = thumbsUp
            thumbsdownButton.isSelected = thumbsDown
        }
        tipLabel.snp.updateConstraints { make in
            let inset = showThumbs ? Layout.textRightWithButton : Layout.textRightWithoutButton
            make.right.equalToSuperview().inset(inset)
            make.height.equalTo(self.caculateTextHeight())
        }
    }
    
    private func caculateTextHeight() -> CGFloat {
        guard let text = tipLabel.text,
              let font = tipLabel.font,
              let superview = self.superview else {
            return 18
        }
        var selfWidth = superview.bounds.size.width - leftRightInset * 2
        if let panelWidth = self.panelWidth {
            selfWidth = panelWidth - leftRightInset * 2
        }
        
        let textRight = showThumbs ? Layout.textRightWithButton : Layout.textRightWithoutButton
        let boundingWidth = selfWidth - (Layout.iconLeft + Layout.iconSize.width + Layout.textLeft + textRight)
        let textHeight = text.boundingRect(with: CGSize(width: boundingWidth, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: [.font: font, .paragraphStyle: paragraphStyle], context: nil).size.height + 2
        return max(textHeight, 16)
    }
    
    @objc
    private func didClickThumbUpBtn() {
        let selected = thumbsupButton.isSelected
        thumbsdownButton.isSelected = false
        thumbsupButton.isSelected = !selected
        eventRelay.accept(.clickThumbUp(isSelected: thumbsupButton.isSelected))
    }
    
    @objc
    private func didClickThumbDownBtn() {
        let selected = thumbsdownButton.isSelected
        thumbsupButton.isSelected = false
        thumbsdownButton.isSelected = !selected
        eventRelay.accept(.clickThumbDown(isSelected: thumbsdownButton.isSelected))
    }
}
