//
//  PreviewParticipantCell.swift
//  ByteView
//
//  Created by yangyao on 2020/11/19.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.

import UIKit
import ByteViewCommon
import UniverseDesignIcon
import ByteViewNetwork
import ByteViewUI

protocol PreviewParticipantCellDelegate: AnyObject {
    func didTapNameLabel(label: UILabel)
}

final class PreviewParticipantCell: UITableViewCell {
    // 修改布局需要同步修改popoverSize计算逻辑(PreviewMeetingViewController+Participants)
    struct PopoverLayout {
        static let avatarSize: CGFloat = Display.pad ? 40 : 32
        static let nameLeftOffset: CGFloat = Display.pad ? 12 : 8
        static let nameHeight: CGFloat = Display.pad ? 22 : 20
        static let nameFont: UIFont = UIFont.systemFont(ofSize: Display.pad ? 16 : 14)
    }

    struct Layout {
        static let avatarLeftOffset: CGFloat = 16
        static let deviceSize: CGFloat = 16
        static let tagLeftOffset: CGFloat = 6
        static let tagSpacing: CGFloat = 6
        static let cellRightOffset: CGFloat = 16

        static let sponsorFont: UIFont = UIFont.systemFont(ofSize: 12, weight: .medium)
        static let sponsorInset: CGFloat = 4

        static let externalFont: UIFont = UIFont.systemFont(ofSize: 12.0, weight: .medium)
        static let externalInset: CGFloat = 4
    }

    lazy var avatarView = AvatarView()

    weak var delegate: PreviewParticipantCellDelegate?

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapNameLabel))
        label.addGestureRecognizer(tapGesture)
        return label
    }()

    lazy var sponsorLabel: PaddingLabel = {
        let label = PaddingLabel()
        label.textInsets = UIEdgeInsets(top: 0.0,
                                        left: Layout.sponsorInset,
                                        bottom: 0.0,
                                        right: Layout.sponsorInset)
        label.textColor = UIColor.ud.udtokenTagTextSBlue
        label.font = Layout.sponsorFont
        label.textAlignment = .center
        label.text = I18n.View_M_OrganizerLabel

        label.backgroundColor = UIColor.ud.udtokenTagBgBlue.withAlphaComponent(0.2)
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()

    // 外部会议标签
    private lazy var externalTagView: PaddingLabel = {
        let label = PaddingLabel()
        label.textInsets = UIEdgeInsets(top: 0.0,
                                        left: Layout.externalInset,
                                        bottom: 0.0,
                                        right: Layout.externalInset)
        label.font = Layout.externalFont
        label.textColor = UIColor.ud.udtokenTagTextSBlue
        label.backgroundColor = UIColor.ud.udtokenTagBgBlue
        label.layer.cornerRadius = 4
        label.layer.masksToBounds = true
        return label
    }()

    // 是否需要展示移动设备标志
    lazy var deviceImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        return imageView
    }()

    lazy var mobileImage: UIImage? = UDIcon.getIconByKey(.cellphoneFilled, iconColor: .ud.iconN3,
                                                         size: CGSize(width: Layout.deviceSize, height: Layout.deviceSize))

    lazy var webImage: UIImage? = BundleResources.ByteView.Meet.iconMobileWindow.ud.withTintColor(.ud.iconN3)

    lazy var pstnImage: UIImage? = UDIcon.getIconByKey(.officephoneFilled, iconColor: UIColor.ud.iconN3, size: CGSize(width: 20, height: 20))

    lazy var tagStack: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            deviceImageView,
            sponsorLabel,
            externalTagView
        ])
        stackView.spacing = Layout.tagSpacing
        stackView.axis = .horizontal
        return stackView
    }()

    lazy var separator: UIView = {
        let separator = UIView()
        separator.backgroundColor = UIColor.ud.lineDividerDefault
        return separator
    }()

    var isRelationTagEnabled = false

    var previewedParticipant: PreviewParticipantWrapper? {
        didSet {
            guard let wrapper = previewedParticipant else {
                return
            }
            let previewedParticipant = wrapper.participant
            var name = previewedParticipant.userName
            if previewedParticipant.isLarkGuest {
                if wrapper.isInterview {
                    name += I18n.View_G_CandidateBracket
                } else {
                    name += I18n.View_M_GuestParentheses
                }
            }
            nameLabel.text = name
            avatarView.setAvatarInfo(previewedParticipant.avatarInfo)
            sponsorLabel.isHidden = !previewedParticipant.isSponsor

            var deviceImage: UIImage?
            if previewedParticipant.isConveniencePSTN {
                deviceImage = pstnImage
            } else if previewedParticipant.showCallme {
                deviceImage = pstnImage
            } else if previewedParticipant.showDevice {
                switch previewedParticipant.deviceType {
                case .mobile:
                    deviceImage = mobileImage
                case .web:
                    deviceImage = webImage
                default:
                    deviceImage = nil
                }
            }
            deviceImageView.image = deviceImage
            deviceImageView.isHidden = deviceImage == nil
            if let relationText = wrapper.relationTag?.relationText {
                externalTagView.text = relationText
                externalTagView.isHidden = false
            } else {
                if isRelationTagEnabled {
                    externalTagView.isHidden = true
                } else {
                    updateExternalTag(isExternal: wrapper.isExternal)
                }
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        backgroundColor = UIColor.ud.bgFloat
        contentView.backgroundColor = .clear

        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = UIColor.ud.fillHover

        addInteraction(type: .hover)
        contentView.addSubview(avatarView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(tagStack)
        contentView.addSubview(separator)

        separator.snp.makeConstraints { (make) in
            make.height.equalTo(1.0 / self.vc.displayScale).priority(.low)
            make.left.equalTo(nameLabel).offset(0).priority(.low)
            make.right.equalToSuperview().offset(0).priority(.low)
            make.bottom.equalToSuperview().priority(.low)
        }

        avatarView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Layout.avatarLeftOffset)
            make.width.height.equalTo(40)
            make.centerY.equalToSuperview()
        }

        nameLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(avatarView.snp.right).offset(12)
            make.height.equalTo(24)
        }

        deviceImageView.snp.makeConstraints { (make) in
            make.width.height.equalTo(Layout.deviceSize)
        }

        tagStack.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(nameLabel.snp.right).offset(Layout.tagLeftOffset)
            make.height.equalTo(18)
            make.right.lessThanOrEqualToSuperview().offset(-Layout.cellRightOffset)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateRelationOrExternalTag() {
        requestRelationTagIfNeeded()
    }

    func updateExternalTag(isExternal: Bool) {
        externalTagView.isHidden = !isExternal
        externalTagView.text = isExternal ? I18n.View_G_ExternalLabel : ""
        resetLayout(isPopover: previewedParticipant?.isPopover ?? false)
    }

    func resetLayout(isPopover: Bool) {
        previewedParticipant?.isPopover = isPopover
        if isPopover {
            let hideTag = deviceImageView.isHidden && sponsorLabel.isHidden && externalTagView.isHidden
            avatarView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(Layout.avatarLeftOffset)
                make.width.height.equalTo(PopoverLayout.avatarSize)
                make.centerY.equalToSuperview()
            }
            nameLabel.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalTo(avatarView.snp.right).offset(PopoverLayout.nameLeftOffset)
                make.height.equalTo(PopoverLayout.nameHeight)
                if hideTag {
                    make.right.equalToSuperview().offset(-Layout.cellRightOffset)
                }
            }
            tagStack.isHidden = hideTag
            separator.isHidden = true
            nameLabel.font = PopoverLayout.nameFont
        } else {
            avatarView.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(Layout.avatarLeftOffset)
                make.width.height.equalTo(40)
                make.centerY.equalToSuperview()
            }
            nameLabel.snp.remakeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalTo(avatarView.snp.right).offset(12)
                make.height.equalTo(22)
            }
            separator.isHidden = true
            nameLabel.font = UIFont.systemFont(ofSize: 16)
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let fitSize = CGSize(width: nameLabel.frame.width, height: .greatestFiniteMagnitude)
        guard let text = nameLabel.text, !text.isEmpty,
              nameLabel.sizeThatFits(fitSize).height > nameLabel.frame.height + 1 else {
            return super.hitTest(point, with: event)
        }
        let labelPoint = nameLabel.convert(point, from: self)
        if nameLabel.point(inside: labelPoint, with: event) {
            return nameLabel
        } else {
            return super.hitTest(point, with: event)
        }
    }

    @objc
    func tapNameLabel() {
        delegate?.didTapNameLabel(label: nameLabel)
    }
}

extension PreviewParticipantCell {
    func requestRelationTagIfNeeded() {
        guard previewedParticipant?.isExternal == true else {
            updateExternalTag(isExternal: previewedParticipant?.isExternal ?? false)
            return
        }

        previewedParticipant?.getRelationTag { [weak self] external in
            Util.runInMainThread {
                if let external = external {
                    self?.externalTagView.text = external
                    self?.externalTagView.isHidden = false
                    self?.resetLayout(isPopover: self?.previewedParticipant?.isPopover ?? false)
                } else {
                    self?.updateExternalTag(isExternal: self?.previewedParticipant?.isExternal ?? false)
                }
            }
        }
    }
}
