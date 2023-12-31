//
//  MailEditLabelCell.swift
//  MailSDK
//
//  Created by majx on 2019/7/17.
//

import Foundation
import UIKit
import UniverseDesignCheckBox
import UniverseDesignIcon

class MailEditLabelCell: UITableViewCell {
    private var model: MailLabelModel?
    enum EditLabelStatus {
        case uncheck
        case checked
        case semiChecked
    }
    var status: EditLabelStatus = .uncheck {
        didSet {
            switch status {
            case .uncheck:
                optionButton.updateUIConfig(boxType: .multiple, config: UDCheckBoxUIConfig())
                optionButton.isSelected = false
            case .semiChecked:
                optionButton.updateUIConfig(boxType: .mixed, config: UDCheckBoxUIConfig())
                optionButton.isSelected = true
            case .checked:
                optionButton.updateUIConfig(boxType: .multiple, config: UDCheckBoxUIConfig())
                optionButton.isSelected = true
            }
        }
    }
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
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.setupViews()
    }
    var hiddenIcon: Bool = false {
        didSet {
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }

    var defaultPadding: Int = 16
    var customPaddingCount: Int?

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        backgroundColor = ModelViewHelper.listColor()
        contentView.addSubview(iconView)
        contentView.addSubview(labelIcon)
        contentView.addSubview(optionButton)
        contentView.addSubview(nodeLabel)
        contentView.addSubview(pathLabel)
        contentView.addSubview(selectIcon)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        hiddenIcon = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        iconView.frame = CGRect(x: defaultPadding, y: 0, width: 20, height: 20)
        nodeLabel.frame = CGRect(x: iconView.frame.maxX + 12,
                                  y: 0,
                                  width: contentView.frame.width - 96,
                                  height: contentView.frame.height)
        nodeLabel.isHidden = false
        pathLabel.frame = CGRect(x: iconView.frame.maxX + 12,
                                 y: 0,
                                 width: contentView.frame.width - 96,
                                 height: contentView.frame.height)

        optionButton.frame = CGRect(x: contentView.frame.width - 16 - 20, y: 0, width: 20, height: 20)
        labelIcon.frame = CGRect(x: 16, y: 0, width: 18, height: 18)
        nodeLabel.frame.size.height = nodeLabel.intrinsicContentSize.height
        pathLabel.frame.size.height = pathLabel.intrinsicContentSize.height
        if let textModel = model {
            if !textModel.parentID.isEmpty && !textModel.parentID.isRoot() {
                pathLabel.text = MailLabelArrangeManager.composeText(textNames: textModel.textNames, maxWidth: pathLabel.bounds.size.width - 5, font: pathLabel.font)
                var paddingCount = max(textModel.idNames.count - 1, 0)
                if let customPadding = customPaddingCount {
                    paddingCount = customPadding
                }

                iconView.frame = CGRect(x: defaultPadding + paddingCount * 24, y: 0, width: 20, height: 20)
                let offsetX = iconView.frame.origin.x + 30
                let nodeLabelWidth = contentView.frame.width - offsetX - 52
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
        if hiddenIcon {
            iconView.isHidden = true
            nodeLabel.frame = CGRect(x: 16, y: 0, width: contentView.frame.width - 52, height: contentView.frame.height)
        }
        iconView.frame.centerY = contentView.bounds.centerY
        labelIcon.center = iconView.center //  frame.centerY = contentView.bounds.centerY
        optionButton.frame.centerY = contentView.bounds.centerY
        nodeLabel.frame.centerY = contentView.bounds.centerY
        pathLabel.frame.centerY = nodeLabel.frame.maxY + 2 + pathLabel.frame.size.height / 2
        selectIcon.frame = CGRect(x: contentView.frame.width - 20 - 18, y: 0, width: 16, height: 12)
        selectIcon.frame.centerY = contentView.bounds.centerY
        contentView.backgroundColor = isHighlighted ? UIColor.ud.fillHover : ModelViewHelper.listColor()
    }

    func hiddenOptionButton(_ hidden: Bool) {
        optionButton.isHidden = hidden
    }

    func setDisable(_ disable: Bool) {
        iconView.tintColor = disable ? UIColor.ud.iconDisabled : UIColor.ud.textTitle
        nodeLabel.textColor = disable ? UIColor.ud.textDisabled : UIColor.ud.textTitle
    }

    override var isSelected: Bool {
        didSet {
            if !optionButton.isHidden {
                selectIcon.isHidden = true
            }
        }
    }
    var hideSelectIcon: Bool = true {
        didSet {
            if !optionButton.isHidden {
                selectIcon.isHidden = true
            } else {
                selectIcon.isHidden = hideSelectIcon
            }
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        contentView.backgroundColor = highlighted ? UIColor.ud.fillHover : ModelViewHelper.listColor()
    }

    // MARK: - views
    lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        return iconView
    }()

    lazy var labelIcon: MailLabelIcon = MailLabelIcon()
//
//    lazy var optionButton: UIButton = {
//        let button = UIButton(type: .custom)
//        // button.setImage(Resources.mail_cell_option, for: .normal)
//        button.isUserInteractionEnabled = false
//        return button
//    }()

    lazy var optionButton: UDCheckBox = {
        let v = UDCheckBox(boxType: .multiple, config: UDCheckBoxUIConfig(), tapCallBack: nil)
        v.isUserInteractionEnabled = false
        return v
    }()

    private var selectIcon: UIImageView = {
        let selectIcon = UIImageView()
        selectIcon.image = Resources.mail_tag_confirm
        selectIcon.contentMode = .scaleAspectFit
        selectIcon.isHidden = true
        return selectIcon
    }()
}

// MARK: - config
extension MailEditLabelCell {
    func config(_ model: MailLabelModel, paddingCount: Int? = nil) {
        self.model = model
        self.customPaddingCount = paddingCount
        nodeLabel.text = model.text
        if let icon = model.icon {
            iconView.isHidden = false
            labelIcon.isHidden = true
            iconView.image = icon.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = model.isSystem ? UIColor.ud.iconN1 : model.colorType.displayPickerColor(forTagList: true)
        } else {
            iconView.isHidden = true
            labelIcon.isHidden = false
            labelIcon.borderColor = model.colorType.displayPickerColor(forTagList: true)
        }
        if model.tagType == .folder {
            labelIcon.isHidden = true
            iconView.isHidden = false
            iconView.image = UDIcon.folderOutlined.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = UIColor.ud.iconN1
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
}
