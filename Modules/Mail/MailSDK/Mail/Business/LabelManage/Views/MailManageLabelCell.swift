//
//  MailManageLabelCell.swift
//  MailSDK
//
//  Created by majx on 2019/10/28.
//

import Foundation
import RxSwift
import RxCocoa
import UniverseDesignButton
import LarkInteraction
import UniverseDesignEmpty
import UniverseDesignIcon

protocol MailManageLabelCellDelegate: AnyObject {
    func didClickEditLabel(_ model: MailFilterLabelCellModel?)
    func didClickDeleteLabel(_ model: MailFilterLabelCellModel?)
    func didClickEditFolder(_ model: MailFilterLabelCellModel?)
    func didClickDeleteFolder(_ model: MailFilterLabelCellModel?)
}

protocol MailManageEmptyCellDelegate: AnyObject {
    func didClickCreateLabel()
    func didClickCreateFolder()
}

class MailManageLabelCell: UITableViewCell {
    private var model: MailFilterLabelCellModel?
    private var disposeBag = DisposeBag()
    weak var delegate: MailManageLabelCellDelegate?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        backgroundColor = ModelViewHelper.listColor()
        contentView.addSubview(iconView)
        contentView.addSubview(labelIcon)
        contentView.addSubview(editButton)
        contentView.addSubview(deleteButton)
        contentView.addSubview(nodeLabel)
        contentView.addSubview(pathLabel)
        contentView.addSubview(pressView)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        iconView.frame = CGRect(x: 16, y: 0, width: 20, height: 20)
        nodeLabel.frame = CGRect(x: iconView.frame.maxX + 12,
                                  y: 0,
                                  width: contentView.frame.width - 158,
                                  height: contentView.frame.height)
        nodeLabel.isHidden = false
        pathLabel.frame = CGRect(x: iconView.frame.maxX + 12,
                                 y: 0,
                                 width: contentView.frame.width - 158,
                                 height: contentView.frame.height)
        labelIcon.frame = CGRect(x: 16, y: 0, width: 18, height: 18)
        editButton.frame = CGRect(x: contentView.frame.width - 90, y: 0, width: 40, height: 40)
        deleteButton.frame = CGRect(x: contentView.frame.width - 46, y: 0, width: 40, height: 40)
        nodeLabel.frame.size.height = nodeLabel.intrinsicContentSize.height
        pathLabel.frame.size.height = pathLabel.intrinsicContentSize.height
        if let textModel = model {
            if !textModel.parentID.isEmpty && !textModel.parentID.isRoot() {
                pathLabel.text = MailLabelArrangeManager.composeText(textNames: textModel.idNames, maxWidth: pathLabel.bounds.size.width - 5, font: pathLabel.font)
                let paddingCount = max(textModel.idNames.count - 1, 0)
                iconView.frame = CGRect(x: 16 + paddingCount * 24, y: 0, width: 20, height: 20)
                let offsetX = iconView.frame.origin.x + 30
                let nodeLabelWidth = contentView.frame.width - offsetX - 110
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
//        labelIcon.center = iconView.center
        nodeLabel.frame.centerY = contentView.bounds.centerY
        pathLabel.frame.centerY = nodeLabel.frame.maxY + 2 + pathLabel.frame.size.height / 2
        editButton.frame.centerY = contentView.bounds.centerY
        deleteButton.frame.centerY = contentView.bounds.centerY
//        labelIcon.frame.centerY = iconView.frame.centerY
        labelIcon.center = iconView.center
        pressView.frame = CGRect(x: 6, y: 0, width: contentView.frame.width - 12, height: contentView.frame.height)
    }

    // MARK: - views
    lazy var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        return iconView
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
    lazy var pressView: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.fillHover
        view.layer.cornerRadius = 6
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()

    lazy var labelIcon: MailLabelIcon = MailLabelIcon()

    lazy var editButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.editOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ud.iconN2
        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            if self.model?.tagType == .label {
                self.delegate?.didClickEditLabel(self.model)
            }
            if self.model?.tagType == .folder {
                self.delegate?.didClickEditFolder(self.model)
            }
        }).disposed(by: disposeBag)
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(
                    effect: .highlight
                )
            )
            button.addLKInteraction(pointer)
        }
        return button
    }()

    lazy var deleteButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.deleteTrashOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ud.iconN2
        button.imageEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        button.rx.tap.subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            if self.model?.tagType == .label {
                self.delegate?.didClickDeleteLabel(self.model)
            }
            if self.model?.tagType == .folder {
                self.delegate?.didClickDeleteFolder(self.model)
            }
        }).disposed(by: disposeBag)
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: PointerStyle(
                    effect: .highlight
                )
            )
            button.addLKInteraction(pointer)
        }
        return button
    }()

    func showPressStatus() {
        pressView.isHidden = false
        Observable.just(())
            .delay(.seconds(timeIntvl.pressDismiss), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                self?.pressView.isHidden = true
            }).disposed(by: disposeBag)
    }
}

// MARK: - config
extension MailManageLabelCell {
    func config(_ model: MailFilterLabelCellModel) {
        self.model = model
        nodeLabel.text = model.text
        if let icon = model.icon {
            iconView.isHidden = false
            labelIcon.isHidden = true
            iconView.image = icon.withRenderingMode(.alwaysTemplate)
            iconView.tintColor = model.colorType.displayPickerColor(forTagList: true)
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
        if model.isSystem {
            self.iconView.tintColor = UIColor.ud.iconN1
            editButton.isHidden = true
            deleteButton.isHidden = true
        } else {
            editButton.isHidden = false
            deleteButton.isHidden = false
        }
        // 配置accessibilityIdentifier
        nodeLabel.accessibilityIdentifier = MailAccessibilityIdentifierKey.LabelManageCellNameKey + model.text
        deleteButton.accessibilityIdentifier = MailAccessibilityIdentifierKey.LabelManageCellDeleteKey + model.text
        editButton.accessibilityIdentifier = MailAccessibilityIdentifierKey.LabelManageCellEditKey + model.text
        setNeedsLayout()
        layoutIfNeeded()
    }
}

class MailManageLabelEmptyCell: UITableViewCell {

    private var emptyIcon: UIImageView = {
        let emptyIcon = UIImageView()
        emptyIcon.image = Resources.mail_empty_icon
        return emptyIcon
    }()
    private var emptyIntroLabel: UILabel = {
        let emptyIntroLabel = UILabel()
        emptyIntroLabel.textAlignment = .center
        emptyIntroLabel.textColor = UIColor.ud.textCaption
        emptyIntroLabel.font = UIFont.systemFont(ofSize: 14)
        return emptyIntroLabel
    }()
//    private var createTagButton = UIButton(type: .custom)
    private lazy var createTagButton: UDButton = {
        let config = UDButtonUIConifg.primaryBlue
        let button = UDButton(config)
        return button
    }()

    weak var delegate: MailManageEmptyCellDelegate?
    private var type: MailTagType = .label

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        self.setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        backgroundColor = ModelViewHelper.listColor()

        contentView.addSubview(emptyIcon)
        emptyIcon.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-10)
            make.width.height.equalTo(100)
        }

        contentView.addSubview(emptyIntroLabel)
        emptyIntroLabel.snp.makeConstraints { (make) in
            make.top.equalTo(emptyIcon.snp.bottom).offset(12)
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
        }
    }

    func config(_ tagType: MailTagType) {
        self.type = tagType
        if tagType == .label {
            emptyIntroLabel.text = BundleI18n.MailSDK.__Mail_Manage_EmptyFolderLabel.toTagName(.label)
            createTagButton.setAttributedTitle(NSAttributedString(string: BundleI18n.MailSDK.__Mail_Manage_CreateFolderLabel.toTagName(.label)), for: .normal)
        } else {
            emptyIntroLabel.text = BundleI18n.MailSDK.__Mail_Manage_EmptyFolderLabel.toTagName(.folder)
            createTagButton.setAttributedTitle(NSAttributedString(string: BundleI18n.MailSDK.__Mail_Manage_CreateFolderLabel.toTagName(.folder)), for: .normal)
        }
    }
}
