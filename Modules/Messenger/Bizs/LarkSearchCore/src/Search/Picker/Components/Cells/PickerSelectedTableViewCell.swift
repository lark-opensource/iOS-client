//
//  PickerSelectedTableViewCell.swift
//  LarkSearchCore
//
//  Created by 赵家琛 on 2021/2/3.
//

import UIKit
import Foundation
import LarkSDKInterface
import LarkUIKit
import LarkListItem
import LarkBizAvatar

protocol PickerSelectedCellPropsProtocol {
    var name: String { get }
    var info: String { get }
    var description: String { get }
    var avatarIdentifier: String { get }
    var avatarKey: String { get }
    var avatarImageURL: String? { get }
    var backupImage: UIImage? { get }
    var targetPreview: Bool { get }
    var tapHandler: () -> Void { get }
    var isMsgThread: Bool { get }
}

struct PickerSelectedCellProps: PickerSelectedCellPropsProtocol {
    let name: String
    let info: String
    let isMsgThread: Bool
    let description: String
    var avatarIdentifier: String
    var avatarKey: String
    var avatarImageURL: String?
    var backupImage: UIImage?
    let targetPreview: Bool
    let tapHandler: () -> Void
}

final class PickerSelectedTableViewCell: UITableViewCell {

    var context = ListItemContext()

    var node: ListItemNode? {
        didSet {
            guard let node else { return }
            thumbnailAvatarView.isHidden = true
            listInfoView.infoLabel.isHidden = true
            listInfoView.nameLabel.isHidden = false
            listInfoView.nameLabel.attributedText = node.title
            if node.desc != nil {
                listInfoView.infoLabel.attributedText = node.desc
                listInfoView.infoLabel.isHidden = false
            }
            iconView.isHidden = false
            iconView.icon = node.icon
        }
    }

    var didDeleteHandler: (() -> Void)?

    private lazy var thumbnailAvatarView: BizAvatar = {
        let avatarView = BizAvatar()
        avatarView.isHidden = true
        return avatarView
    }()

    private lazy var iconView: ItemIconView = {
        return ItemIconView(context: self.context)
    }()

    private var thumbnailwidth: CGFloat = 18

    private lazy var listInfoView: ListItem = {
        let listInfoView = ListItem()
        listInfoView.checkStatus = .invalid
        listInfoView.infoLabel.isHidden = true
        listInfoView.nameTag.isHidden = true
        listInfoView.additionalIcon.isHidden = true
        listInfoView.statusLabel.isHidden = true
        listInfoView.bottomSeperator.backgroundColor = UIColor.ud.commonTableSeparatorColor
        listInfoView.textContentView.spacing = 4
        listInfoView.statusLabel.setUIConfig(StatusLabel.UIConfig(font: UIFont.systemFont(ofSize: 16)))
        listInfoView.statusLabel.descriptionView.setContentCompressionResistancePriority(.required, for: .horizontal)
        listInfoView.statusLabel.descriptionView.setContentHuggingPriority(.required, for: .horizontal)
        listInfoView.statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        listInfoView.statusLabel.setContentHuggingPriority(.required, for: .horizontal)
        return listInfoView
    }()

    public lazy var rightIconStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 12
        return stackView
    }()

    public lazy var targetInfo: UIButton = {
        let targetInfo = UIButton(type: .custom)
        targetInfo.setImage(Resources.target_info, for: .normal)
        targetInfo.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        return targetInfo
    }()

    private lazy var deleteButton: UIButton = {
        let deleteButton = UIButton()
        deleteButton.setImage(Resources.LarkSearchCore.Messenger.picker_selected_close.withRenderingMode(.alwaysTemplate), for: .normal)
        deleteButton.tintColor = UIColor.ud.iconN3
        deleteButton.adjustsImageWhenHighlighted = false
        deleteButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)
        return deleteButton
    }()

    var optionIdentifier: OptionIdentifier?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none

        contentView.addSubview(listInfoView)
        contentView.addSubview(rightIconStackView)
        rightIconStackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview().offset(-Self.Layout.stackMargin)
        }
        rightIconStackView.addArrangedSubview(deleteButton)
        listInfoView.snp.makeConstraints { (make) in
            make.top.bottom.leading.equalToSuperview()
            make.trailing.lessThanOrEqualTo(rightIconStackView.snp.leading).offset(-Self.Layout.personInfoToStackMargin)
        }
        listInfoView.bottomSeperator.snp.remakeConstraints { (make) in
            make.leading.equalTo(listInfoView.nameLabel.snp.leading)
            make.height.equalTo(1 / UIScreen.main.scale)
            make.bottom.equalToSuperview()
            make.trailing.equalTo(self.snp.trailing)
        }
        listInfoView.rightMarginConstraint.update(offset: 0)
        listInfoView.avatarView.addSubview(thumbnailAvatarView)
        thumbnailAvatarView.snp.makeConstraints { make in
            make.bottom.right.equalToSuperview()
            make.size.equalTo(CGSize(width: thumbnailwidth, height: thumbnailwidth))
        }
        listInfoView.avatarView.addSubview(iconView)
        iconView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        iconView.isHidden = true
        thumbnailAvatarView.isHidden = true
    }

    fileprivate var props: PickerSelectedCellPropsProtocol? {
        didSet {
            guard let props = self.props else { return }

            listInfoView.nameLabel.text = props.name
            listInfoView.infoLabel.isHidden = props.description.isEmpty
            listInfoView.infoLabel.text = props.description
            if props.info.isEmpty {
                listInfoView.statusLabel.isHidden = true
            } else {
                listInfoView.statusLabel.isHidden = false
                listInfoView.statusLabel.set(
                    description: NSAttributedString(string: " (\(props.info))",
                                                    attributes: [.font: UIFont.systemFont(ofSize: 16),
                                                                 .foregroundColor: UIColor.ud.textPlaceholder]),
                    descriptionIcon: nil,
                    showIcon: false
                )
            }
            if props.targetPreview {
                rightIconStackView.insertArrangedSubview(targetInfo, at: 0)
                targetInfo.isHidden = false
            } else {
                targetInfo.isHidden = true
            }
            /// avater
            if !props.avatarKey.isEmpty {
                if props.isMsgThread {
                    listInfoView.avatarView.setAvatarByIdentifier("", avatarKey: "")
                    listInfoView.avatarView.image = BundleResources.LarkSearchCore.Picker.thread_msg_icon
                    thumbnailAvatarView.isHidden = false
                    thumbnailAvatarView.image = nil
                    thumbnailAvatarView.setAvatarByIdentifier(props.avatarIdentifier, avatarKey: props.avatarKey)
                } else {
                    listInfoView.avatarView.setAvatarByIdentifier(props.avatarIdentifier, avatarKey: props.avatarKey)
                    thumbnailAvatarView.isHidden = true
                }
                return
            } else if let avatarImageURL = props.avatarImageURL, !avatarImageURL.isEmpty {
                listInfoView.avatarView.avatar.bt.setImage(URL(string: avatarImageURL))
                thumbnailAvatarView.isHidden = true
                return
            } else {
                thumbnailAvatarView.isHidden = true
            }
            if let backupImage = props.backupImage {
                listInfoView.avatarView.image = backupImage
                return
            }
            listInfoView.avatarView.image = nil
        }
    }

    func setProps(_ props: PickerSelectedCellPropsProtocol) {
       self.props = props
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.props = nil
        iconView.isHidden = true
        listInfoView.avatarView.image = nil
        listInfoView.nameLabel.text = ""
        listInfoView.infoLabel.isHidden = true
        listInfoView.statusLabel.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func tapped(_ button: UIButton) {
        self.props?.tapHandler()
        self.didDeleteHandler?()
    }
}

extension PickerSelectedTableViewCell {
    final class Layout {
        //根据UI设计图而来
        static let iconWidth: CGFloat = 20
        static let personInfoToStackMargin: CGFloat = 8
        static let stackMargin: CGFloat = 16
    }
}
