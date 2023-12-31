//
//  MailFilterLabelCell.swift
//  MailSDK
//
//  Created by majx on 2019/7/16.
//

import Foundation
import UIKit
import LarkUIKit
import LarkInteraction
import UniverseDesignBadge
import UniverseDesignIcon

class MailFilterLabelCell: UITableViewCell {
    static let identifier = "MailFilterLabelCell"
    private var layouter = UILabel()
    private var model: MailLabelModel?

    private let selectedColor = UIColor.ud.fillFocus
    private let normalColor = UIColor.ud.bgBody

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.separatorInset = .init(top: 0, left: self.bounds.size.width, bottom: 0, right: 0)
        self.setupViews()
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(
                    effect: .hover()
                )
            )
            self.addLKInteraction(pointer)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        backgroundView = BaseCellBackgroundView()
        backgroundView?.backgroundColor = .clear
        selectedBackgroundView = nil

        backgroundColor = normalColor

        contentView.addSubview(iconView)
        contentView.addSubview(labelIcon)
        contentView.addSubview(nodeLabel)
        contentView.addSubview(pathLabel)
        contentView.addSubview(badgeLabel)
        contentView.addSubview(badgeView)
        contentView.addSubview(bottomLine)
        contentView.clipsToBounds = true
        contentView.layer.masksToBounds = true
        /// fix cell overflow before iOS13
        self.clipsToBounds = true
        self.layer.masksToBounds = true
        badgeLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        badgeView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hiddenBadge()
        enableNotify = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        iconView.frame = CGRect(x: 16, y: 0, width: 20, height: 20)
        bottomLine.frame = CGRect(x: 16, y: contentView.frame.height - 1.0 / UIScreen.main.scale,
                                  width: contentView.frame.width - 32, height: 1.0 / UIScreen.main.scale)
        var badgeWidth: CGFloat = 0.0
        var space: CGFloat = 16.0
        if !needShowBadge() {
            badgeLabel.sizeToFit()
            badgeWidth = min(badgeLabel.frame.width, 64)
            badgeLabel.frame = CGRect(x: contentView.frame.width - badgeWidth - 16, y: 0,
                                      width: badgeWidth, height: contentView.frame.height)
            space = badgeLabel.isHidden ? 16 : 16 + badgeWidth + 10
        } else {
            let badgeWidth: CGFloat = min(badgeView.frame.width, 66)
            badgeView.frame = CGRect(x: contentView.frame.width - badgeWidth - 16, y: 0,
                                      width: badgeWidth, height: contentView.frame.height)
            space = badgeView.isHidden ? 16 : 16 + badgeWidth + 10
        }
        nodeLabel.frame = CGRect(x: 46, y: 0,
                                 width: contentView.frame.width - space - 46, height: contentView.frame.height / 2)
        nodeLabel.isHidden = false
        labelIcon.frame = CGRect(x: 0, y: 0, width: 18, height: 18)
        pathLabel.frame = CGRect(x: 46, y: 0,
                                 width: contentView.frame.width - space, height: contentView.frame.height / 2)
        if let textModel = model {
            if !textModel.parentID.isEmpty && !textModel.parentID.isRoot() {
                pathLabel.text = MailLabelArrangeManager.composeText(textNames: textModel.textNames, maxWidth: pathLabel.bounds.size.width - 5, font: pathLabel.font)
                let paddingCount = max(textModel.idNames.count - 1, 0)
                iconView.frame = CGRect(x: 16 + paddingCount * 16, y: 0, width: 20, height: 20)
                let offsetX = iconView.frame.origin.x + 30
                let nodeLabelWidth = contentView.frame.width - space - offsetX
                if nodeLabelWidth <= 0 {
                    iconView.frame = .zero
                    labelIcon.frame = .zero
                    nodeLabel.isHidden = true
                } else {
                    nodeLabel.frame = CGRect(x: offsetX, y: 0,
                                             width: nodeLabelWidth, height: contentView.frame.height / 2)
                }
                pathLabel.isHidden = true
            } else {
                pathLabel.text = ""
            }
        }

        iconView.frame.centerY = contentView.bounds.centerY
        labelIcon.center = iconView.center
        nodeLabel.frame.size.height = nodeLabel.intrinsicContentSize.height
        pathLabel.frame.size.height = pathLabel.intrinsicContentSize.height
        nodeLabel.frame.centerY = contentView.bounds.centerY
        pathLabel.frame.centerY = nodeLabel.frame.maxY + 2 + pathLabel.frame.size.height / 2
    }

    // MARK: - views
    lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        return iconView
    }()

    lazy var labelIcon: MailLabelIcon = MailLabelIcon()

    lazy var badgeLabel: UILabel = {
        let badgeLabel = UILabel()
        badgeLabel.textColor = UIColor.ud.textPlaceholder
        badgeLabel.font = UIFont.systemFont(ofSize: 14.0)
        badgeLabel.isHidden = true
        return badgeLabel
    }()
    lazy var badgeView: UDBadge = {
        let badgeView = UDBadge(config: .number)
        badgeView.config.maxNumber = 9999
        badgeView.config.style = .characterBGGrey
        badgeView.isHidden = true
        return badgeView
    }()

    lazy var nodeLabel: UILabel = {
        let nodeLabel = UILabel()
        nodeLabel.textColor = UIColor.ud.textTitle
        nodeLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return nodeLabel
    }()

    lazy var pathLabel: UILabel = {
        let pathLabel = UILabel()
        pathLabel.textColor = UIColor.ud.textPlaceholder
        pathLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        return pathLabel
    }()

    lazy var bottomLine: UIView = {
        let bottomLine = UIView()
        bottomLine.backgroundColor = UIColor.ud.lineDividerDefault
        bottomLine.isHidden = true
        return bottomLine
    }()

    var isSelectedItem: Bool = false {
        didSet {
            if isSelectedItem {
                labelIcon.state = .selected
                contentView.backgroundColor = selectedColor
            } else {
                labelIcon.state = .normal
                contentView.backgroundColor = normalColor
            }
        }
    }
    var enableNotify: Bool = false {
        didSet {
            if enableNotify {
                badgeView.config.style = .characterBGRed
            } else {
                badgeView.config.style = .characterBGGrey
            }
        }
    }
}

// MARK: - config
extension MailFilterLabelCell {
    func config(_ model: MailLabelModel, isFolder: Bool = false) {
        self.model = model
        nodeLabel.text = model.text
        nodeLabel.textColor = UIColor.ud.textTitle

        if let icon = model.icon {
            iconView.isHidden = false
            labelIcon.isHidden = true
            iconView.image = icon.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = model.fontColor
        } else {
            iconView.isHidden = true
            labelIcon.isHidden = false
            labelIcon.borderColor = model.colorType.displayPickerColor(forTagList: true)
        }
        if isFolder
            || (FeatureManager.enableSystemFolder() && model.tagType == .folder) { // 支持系统label下文件夹。
            labelIcon.isHidden = true
            iconView.isHidden = false
            if model.labelId == Mail_LabelId_Stranger && FeatureManager.open(FeatureKey(fgKey: .stranger, openInMailClient: false)) {
                iconView.image = Mail_LabelId_Stranger.menuResource.iconImage
            } else {
                iconView.image = UDIcon.folderOutlined.withRenderingMode(.alwaysTemplate)
            }
        }

        // color
        if model.isSystem || isFolder || (FeatureManager.enableSystemFolder() && model.tagType == .folder) {
            iconView.tintColor = UIColor.ud.iconN1
        } else {
            let color = model.fontColor
            iconView.tintColor = color
        }

        setBadgeCount(count: model.badge,
                      style: model.badgeStyle)
        bottomLine.isHidden = (model.labelId != Mail_LabelId_Other)

        setNeedsLayout()
        layoutIfNeeded()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if isSelectedItem {
            return
        }
        let color = isSelectedItem ? selectedColor : normalColor
        contentView.backgroundColor = highlighted ? UIColor.ud.fillHover : color
    }
}

// MARK: - Badge View
extension MailFilterLabelCell {
    private func setBadgeCount(count: Int?, style: MailLabelBadgeStyle) {
        // swiftlint:disable empty_count
        guard let count = count else {
            hiddenBadge()
            return
        }
        if style == .number {
            if count == 0 {
                hiddenBadge()
            } else {
                setBadgeCount(count)
                setBadgeHidden(false)
            }
        } else {
            hiddenBadge()
        }

        self.layoutIfNeeded()
        self.setNeedsLayout()
    }
    
    func hiddenBadge() {
        badgeView.isHidden = true
        badgeView.config.number = 0
        badgeLabel.isHidden = true
        badgeLabel.text = ""
    }
    
    func setBadgeHidden(_ isHidden: Bool) {
        if needShowBadge() {
            badgeView.isHidden = isHidden
        } else {
            badgeLabel.isHidden = isHidden
        }
    }
    
    func setBadgeCount(_ count: Int) {
        if needShowBadge() {
            badgeView.config.number = count
        } else {
            if count > 9999 {
                badgeLabel.text = "999+"
            } else {
                badgeLabel.text = "\(count)"
            }
        }
    }
    
    func needShowBadge() -> Bool {
        let noticeFG = FeatureManager.open(FeatureKey.init(fgKey: .labelListNoticeRedDot, openInMailClient: true))
        if let model = model, (!model.isSystem || [Mail_LabelId_Important, Mail_LabelId_Other, Mail_LabelId_Inbox].contains(model.labelId)), noticeFG {
            return true
        } else {
            return false
        }
    }
}
