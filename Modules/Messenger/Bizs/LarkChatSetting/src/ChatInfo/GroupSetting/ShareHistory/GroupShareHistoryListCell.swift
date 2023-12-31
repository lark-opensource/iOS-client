//
//  GroupShareHistoryListCellAndItem.swift
//  LarkChat
//
//  Created by kongkaikai on 2019/7/28.
//

import Foundation
import UIKit
import LarkCore
import SnapKit
import LarkUIKit
import LarkTag
import EENavigator
import LKCommonsLogging
import LarkMessengerInterface
import LarkExtensions
import LarkBizAvatar

private extension UIButton {
    func setInsets(
        forContentPadding contentPadding: UIEdgeInsets,
        imageTitlePadding: CGFloat
    ) {
        self.contentEdgeInsets = UIEdgeInsets(
            top: contentPadding.top,
            left: contentPadding.left,
            bottom: contentPadding.bottom,
            right: contentPadding.right + imageTitlePadding
        )

        self.titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: imageTitlePadding,
            bottom: 0,
            right: -imageTitlePadding
        )
    }
}

final class GroupShareHistoryListCell: BaseSettingCell {
    private static let logger = Logger.log(
        GroupShareHistoryListCell.self,
        category: "LarkChat.ChatInfo.GroupShareHistoryListCell")

    // 当Button的contentEdgeInsets设置为 .zero 时，会被填充默认值；
    // stackoverflow: https://stackoverflow.com/questions/31873049/
    // how-to-remove-the-top-and-bottom-padding-of-uibutton-when-create-it-using-auto
    private static let approximateZeroInsets = UIEdgeInsets(top: 0.01, left: 0.01, bottom: 0.01, right: 0.01)

    private let checkbox = Checkbox()
    private let avatarView = BizAvatar()
    private let avatarSize: CGFloat = 37
    private let verticalStackView = UIStackView()
    private let nameAndWayStackView = UIStackView()
    private let shareNameButton = UIButton(type: .custom)
    private let shareWayLabel = UILabel()
    private let shareTargetButton = UIButton(type: .custom)
    private let timeAndVailedStackView = UIStackView()
    private let shareTimeLabel = UILabel()
    private let isVailedLabel = TagWrapperView.titleTagView(for: .shareDeactivated)
    private var borderLine = UIView()
    weak var from: UIViewController?

    /// 决定是否显示CheckBox
    var isInSelectedMode: Bool = false {
        didSet {
            checkbox.isHidden = !isInSelectedMode
            avatarView.snp.updateConstraints { (make) in
                make.left.equalTo(isInSelectedMode ? 50 : 16)
            }
            self.selectionStyle = isInSelectedMode && item?.isVailed == true ? .default : .none

            self.shareTargetButton.snp.remakeConstraints {
                $0.height.equalTo(20)
                $0.right.lessThanOrEqualToSuperview().inset(isInSelectedMode ? 0 : 34)
            }
        }
    }

    var isCheckboxOn: Bool {
        get { return self.checkbox.on }
        set {
            // 避免Item无效时，设置isCheckboxOn覆盖掉默认选中的样式
            if item?.isVailed == true {
                self.checkbox.setOn(on: newValue)
            }
        }
    }

    var item: GroupShareHistoryListItem? {
        didSet {
            updateUI()
        }
    }

    var showSharerCardAction: ((_ item: GroupShareHistoryListItem) -> Void)?
    var navi: Navigatable?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(checkbox)
        contentView.addSubview(avatarView)
        contentView.addSubview(verticalStackView)
        verticalStackView.addArrangedSubview(nameAndWayStackView)
        verticalStackView.addArrangedSubview(shareTargetButton)
        verticalStackView.addArrangedSubview(timeAndVailedStackView)

        nameAndWayStackView.addArrangedSubview(shareNameButton)
        nameAndWayStackView.addArrangedSubview(shareWayLabel)

        timeAndVailedStackView.addArrangedSubview(shareTimeLabel)
        timeAndVailedStackView.addArrangedSubview(isVailedLabel)

        checkbox.isHidden = true
        checkbox.lineWidth = 1.5
        checkbox.onCheckColor = UIColor.ud.primaryOnPrimaryFill
        checkbox.strokeColor = UIColor.ud.N300
        checkbox.onFillColor = UIColor.ud.colorfulBlue
        checkbox.isEnabled = false

        checkbox.snp.makeConstraints({ make in
            make.size.equalTo(CGSize(width: 18, height: 18))
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
        })

        avatarView.lu.addTapGestureRecognizer(action: #selector(showSharerCard), target: self, touchNumber: 1)
        avatarView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.size.equalTo(CGSize(width: avatarSize, height: avatarSize))
            make.centerY.equalToSuperview()
        }

        verticalStackView.axis = .vertical
        verticalStackView.alignment = .leading
        verticalStackView.spacing = 5
        verticalStackView.snp.makeConstraints { (make) in
            make.left.equalTo(avatarView.snp.right).offset(10)
            make.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview().inset(16)
        }

        nameAndWayStackView.axis = .horizontal
        nameAndWayStackView.alignment = .center
        nameAndWayStackView.spacing = 5

        shareNameButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        shareNameButton.titleLabel?.lineBreakMode = .byTruncatingTail
        shareNameButton.setTitleColor(UIColor.ud.N900, for: .normal)
        shareNameButton.addTarget(self, action: #selector(showSharerCard), for: .touchUpInside)
        shareNameButton.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.width.lessThanOrEqualTo(99) // 限制最大宽度
        }

        shareWayLabel.font = UIFont.systemFont(ofSize: 14)
        shareWayLabel.textColor = UIColor.ud.N500

        shareTargetButton.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        shareTargetButton.titleLabel?.lineBreakMode = .byTruncatingTail
        shareTargetButton.setTitleColor(UIColor.ud.colorfulBlue, for: .normal)
        shareTargetButton.addTarget(self, action: #selector(shareTargetTap), for: .touchUpInside)
        shareTargetButton.adjustsImageWhenHighlighted = false
        shareTargetButton.snp.makeConstraints {
            $0.height.equalTo(20)
            $0.right.lessThanOrEqualToSuperview().inset(34)
        }

        timeAndVailedStackView.axis = .horizontal
        timeAndVailedStackView.alignment = .center
        timeAndVailedStackView.spacing = 5

        shareTimeLabel.font = UIFont.systemFont(ofSize: 14)
        shareTimeLabel.textColor = UIColor.ud.N500
        borderLine = contentView.lu.addBottomBorder(leading: 16, color: UIColor.ud.commonTableSeparatorColor)
        self.selectedBackgroundView = BaseCellSelectView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateUI() {
        guard let item = self.item else { return }

        self.avatarView.setAvatarByIdentifier(item.sharerID, avatarKey: item.avatarKey, avatarViewParams: .init(sizeType: .size(avatarSize)))
        self.shareNameButton.setTitle(item.name, for: .normal)
        self.shareWayLabel.text = item.way

        if let message = item.target.dispalyMessage, !message.isEmpty {
            self.shareTargetButton.isHidden = false
            self.shareTargetButton.setTitle(message, for: .normal)
        } else {
            self.shareTargetButton.isHidden = true
        }

        if let icon = item.target.icon {
            self.shareTargetButton.setImage(icon, for: .normal)
            self.shareTargetButton.setInsets(
                forContentPadding: GroupShareHistoryListCell.approximateZeroInsets,
                imageTitlePadding: 5)
        } else {
            self.shareTargetButton.setImage(nil, for: .normal)
            self.shareTargetButton.setInsets(
                forContentPadding: GroupShareHistoryListCell.approximateZeroInsets,
                imageTitlePadding: 0)
        }

        self.shareTimeLabel.text = item.time.lf.cacheFormat(
            "group_share_history",
            formater: { $0.lf.formatedStr_v4() })
        self.isVailedLabel.isHidden = item.isVailed

        // 强制选中样式
        if item.isVailed {
            checkbox.onFillColor = UIColor.ud.colorfulBlue
            checkbox.onTintColor = UIColor.ud.colorfulBlue
            checkbox.strokeColor = UIColor.ud.N300
            self.selectionStyle = .none
        } else {
            checkbox.onFillColor = UIColor.ud.N400
            checkbox.onTintColor = UIColor.ud.N400
            checkbox.strokeColor = UIColor.ud.N400
            checkbox.setOn(on: true)
        }
        borderLine.isHidden = !item.isShowBorderLine
    }

    @objc
    private func showSharerCard() {
        guard let item = self.item else { return }
        self.showSharerCardAction?(item)
    }

    @objc
    private func shareTargetTap() {
        guard let item = self.item, let from = self.from else { return }

        switch item.target {
        case .none: break
        case .chat(let id, _):
            self.navi?.push(body: GroupCardSystemMessageJoinBody(chatId: id), from: from)
        case .chatter(let id, _):
            let body = PersonCardBody(chatterId: id)
            self.navi?.presentOrPush(
                body: body,
                wrap: LkNavigationController.self,
                from: from,
                prepareForPresent: { (vc) in
                    vc.modalPresentationStyle = .formSheet
                })
        case .doc(let url, _, _, _):
            if let docsURL = URL(string: url) {
                self.navi?.push(docsURL, from: from)
            } else {
                GroupShareHistoryListCell.logger.error("group share history, docs url error \(item.id)")
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.setAvatarByIdentifier("", avatarKey: "")
    }
}
