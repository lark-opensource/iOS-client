//
//  SelectMyAIToolsTableViewCell.swift
//  LarkIMMention
//
//  Created by ByteDance on 2023/5/23.
//

import UIKit
import Foundation
import LarkUIKit
import SnapKit
import LarkListItem
import UniverseDesignIcon
import UniverseDesignColor
import LarkMessengerInterface
import LarkModel
import ByteWebImage

final class MyAIToolsSelectTableViewCell: UITableViewCell {

    var didClickInfoHandler: ((MyAIToolInfo?) -> Void)?

    private lazy var toolInfoView: ListItem = {
        let toolInfoView = ListItem()
        toolInfoView.statusLabel.isHidden = true
        toolInfoView.bottomSeperator.isHidden = true
        toolInfoView.avatarView.backgroundColor = UIColor.ud.bgBase
        toolInfoView.infoLabel.numberOfLines = 2
        return toolInfoView
    }()

    public lazy var nextInfo: UIButton = {
        let nextInfo = UIButton(type: .custom)
        let icon = UDIcon.getIconByKey(.infoOutlined, iconColor: UIColor.ud.iconN3, size: CGSize(width: Cons.nextInfoWidth, height: Cons.nextInfoWidth))
        nextInfo.setImage(icon, for: .normal)
        nextInfo.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        nextInfo.addTarget(self, action: #selector(nextInfoAction), for: .touchUpInside)
        return nextInfo
    }()

    var isSingleSelect: Bool = false
    var isSourceSearch: Bool = false

    var toolItem: MyAIToolInfo? {
        didSet {
            guard let toolItem = toolItem else { return }
            if isSourceSearch {
                let highlightedText = SearchAttributeString(searchHighlightedString: toolItem.toolName).attributeText
                toolInfoView.nameLabel.attributedText = highlightedText
            } else {
                toolInfoView.nameLabel.text = toolItem.toolName
            }
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.maximumLineHeight = 20
            paragraphStyle.minimumLineHeight = 20
            paragraphStyle.lineSpacing = 2
            paragraphStyle.alignment = .left
            paragraphStyle.lineBreakMode = .byTruncatingTail
            let attributes = [NSAttributedString.Key.font: UIFont.ud.body2,
                              NSAttributedString.Key.paragraphStyle: paragraphStyle,
                              NSAttributedString.Key.foregroundColor: UIColor.ud.textPlaceholder]
            let descAttrStr = NSMutableAttributedString(string: toolItem.toolDesc,
                                                    attributes: attributes)
            toolInfoView.infoLabel.attributedText = descAttrStr
            let completion: (UIImage?, ImageRequestResult) -> Void = { [weak self] placeholder, result in
                guard let self = self else { return }
                switch result {
                case .success(let imageResult):
                    guard let image = imageResult.image else { return }
                    self.toolInfoView.avatarView.image = image
                    self.toolInfoView.avatarView.backgroundColor = UIColor.clear
                case .failure(let error):
                    if placeholder != nil { return }
                    self.toolInfoView.avatarView.image = placeholder
                    MyAIToolsViewController.logger.error("tool Cell load avatar failed id=\(String(describing: toolItem.toolId))" +
                                                         "&key=\(String(describing: toolItem.toolAvatar))&error=\(error.localizedDescription)")
                }
            }
            let placeholder: UIImage? = Resources.imageDownloadFailed
            toolInfoView.avatarView.setAvatarByIdentifier(toolItem.toolId, avatarKey: toolItem.toolAvatar) { imageResult in
                completion(placeholder, imageResult)
            }
            updateCheckBox(selected: toolItem.isSelected, enabled: toolItem.enabled, isSingleSelect: self.isSingleSelect)
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.backgroundColor = UIColor.ud.bgBody
        contentView.backgroundColor = .clear
        setupBackgroundViews(highlightOn: true)
        contentView.addSubview(nextInfo)
        contentView.addSubview(toolInfoView)
        nextInfo.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-Cons.nextInfoMargin)
            make.size.equalTo(CGSize(width: Cons.nextInfoWidth, height: Cons.nextInfoWidth))
            make.centerY.equalToSuperview()
        }
        toolInfoView.snp.makeConstraints { (make) in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.equalTo(nextInfo.snp.leading).offset(-Cons.toolInfoMargin)
        }
        toolInfoView.contentView.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(Cons.toolInfoVMargin)
            make.bottom.equalToSuperview().inset(Cons.toolInfoVMargin)
        }
        toolInfoView.setNameStatusAndInfoStackViewSpace(Cons.contentHMargin)
    }

    private func updateCheckBox(selected: Bool, enabled: Bool, isSingleSelect: Bool) {
        self.selectionStyle = enabled ? .default : .none
        if isSingleSelect {
            toolInfoView.checkBox.isHidden = true
        } else {
            toolInfoView.checkBox.isHidden = false
            toolInfoView.checkBox.isEnabled = enabled
            toolInfoView.checkBox.isSelected = selected
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        setBackViewColor(highlighted ? UIColor.ud.fillHover : UIColor.ud.bgBody)
    }

    @objc
    private func nextInfoAction() {
        didClickInfoHandler?(toolItem)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MyAIToolsSelectTableViewCell {
    enum Cons {
        static let toolInfoVMargin: CGFloat = 12
        static let nextInfoWidth: CGFloat = 18
        static let toolInfoMargin: CGFloat = 5
        static let nextInfoMargin: CGFloat = 16
        static let contentHMargin: CGFloat = 4
    }
}
