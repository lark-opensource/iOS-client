//
//  NativeSwitchUserCell.swift
//  LarkAccount
//
//  Created by bytedance on 2022/4/25.
//

import Foundation
import UIKit
import LKCommonsLogging

class NativeSwitchUserTableViewCell: V4SelectUserCellBase, V3SelectTenantCellProtocol {

    private static let logger = Logger.log(SelectUserTableViewCell.self, category: "SuiteLogin.NativeSwitchUserTableViewCell")

    private let enableBackgroundColor: UIColor = UIColor.ud.fillHover
    private let disableBackgroundColor: UIColor = UIColor.clear

    let avatarImageView: UIImageView = {
        let avatarImageView = UIImageView(frame: .zero)
        avatarImageView.layer.cornerRadius = Common.Layer.commonAvatarImageRadius
        avatarImageView.clipsToBounds = true
        return avatarImageView
    }()

    let titleLabel: UILabel = {
        let lbl = UILabel(frame: .zero)
        lbl.numberOfLines = 1
        lbl.font = UIFont.systemFont(ofSize: Layout.titileFontSize)
        lbl.textColor = UIColor.ud.textTitle
        lbl.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return lbl
    }()

    let subtitleLabel: UILabel = {
        let lbl = UILabel(frame: .zero)
        lbl.numberOfLines = 1
        lbl.font = UIFont.systemFont(ofSize: Layout.subtitleFontSize)
        lbl.textColor = UIColor.ud.textCaption
        return lbl
    }()

    let tagLabel: UILabel = {
        let lbl = UILabel(frame: .zero)
        lbl.numberOfLines = 1
        lbl.font = UIFont.systemFont(ofSize: Layout.subtitleFontSize)
        lbl.textColor = UIColor.ud.textPlaceholder
        return lbl
    }()

    let arrowImageView: UIImageView = {
        let imgView = UIImageView()
        let img = BundleResources.UDIconResources.rightBoldOutlined.ud.withTintColor(UIColor.ud.iconN3)
        imgView.image = img
        imgView.frame.size = img.size
        return imgView
    }()

    let container: UIView

    var data: SelectUserCellData? {
        didSet {
            updateDisplay()
        }
    }

    var isEnableCanSelect: Bool {
        return data?.isValid ?? false
    }

    func updateDisplay() {
        guard let data = data else {
            return
        }
        titleLabel.text = data.tenantName
        subtitleLabel.text = data.userName
        setImage(
            urlString: data.iconUrl,
            placeholder: data.defaultIcon
        )
        self.avatarImageView.layer.cornerRadius = Common.Layer.commonAvatarImageRadius
        if data.type == .normal {
            titleLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(avatarImageView.snp.right).offset(CL.itemSpace)
                make.bottom.equalTo(avatarImageView.snp.centerY)
            }
            setSubtitleLine(hidden: false)
        } else {
            titleLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(avatarImageView.snp.right).offset(CL.itemSpace)
                make.centerY.equalTo(avatarImageView.snp.centerY)
            }
            setSubtitleLine(hidden: true)
        }

        let status = V4UserItem.getStatus(from: data.status)
        if let tag = data.tag, !tag.isEmpty {
            tagLabel.text = tag
        } else {
            tagLabel.text = nil
            tagLabel.isHidden = true
        }

        self.enableLabelWidthConstraint?.constant = 0

        if isEnableCanSelect {
            arrowImageView.isHidden = false
            tagLabel.isHidden = true
        } else {
            arrowImageView.isHidden = true
            tagLabel.isHidden = false
        }

        // Update disabled cell
        if isEnableCanSelect {
            titleLabel.alpha = 1.0
            subtitleLabel.alpha = 1.0
            avatarImageView.alpha = 1.0
        } else {
            titleLabel.alpha = 0.5
            subtitleLabel.alpha = 0.5
            avatarImageView.alpha = 0.5
        }
    }

    func setSubtitleLine(hidden: Bool) {
        subtitleLabel.isHidden = hidden
        tagLabel.isHidden = hidden
    }

    func updateSelection(_ selected: Bool) {
        guard data != nil else {
            return
        }
        if isEnableCanSelect {
            self.container.backgroundColor = selected ? enableBackgroundColor : disableBackgroundColor
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.container = UIView()
        self.container.layer.cornerRadius = Common.Layer.commonCardContainerViewRadius
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.ud.bgFloat
        self.selectionStyle = .none
        contentView.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(Layout.shadowHeight * 2)
        }
        container.addSubview(self.avatarImageView)
        container.addSubview(self.titleLabel)
        container.addSubview(self.subtitleLabel)
        container.addSubview(self.tagLabel)
        container.addSubview(self.arrowImageView)

        avatarImageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(CL.itemSpace - Layout.shadowHeight)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: Layout.avatarWidth, height: Layout.avatarWidth))
        }

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarImageView.snp.right).offset(CL.itemSpace)
            make.bottom.equalTo(avatarImageView.snp.centerY)
        }

        subtitleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatarImageView.snp.right).offset(CL.itemSpace)
            make.top.equalTo(titleLabel.snp.bottom).offset(CL.itemSpace / 4)
        }

        tagLabel.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(CL.itemSpace)
            make.left.greaterThanOrEqualTo(subtitleLabel.snp.right).offset(CL.itemSpace)
            make.right.equalToSuperview().inset(CL.itemSpace)
            make.centerY.equalToSuperview()
        }

        arrowImageView.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualTo(titleLabel.snp.right).offset(CL.itemSpace)
            make.left.greaterThanOrEqualTo(subtitleLabel.snp.right).offset(CL.itemSpace)
            make.left.greaterThanOrEqualTo(tagLabel.snp.right).offset(CL.itemSpace)
            make.right.equalToSuperview().inset(CL.itemSpace)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: arrowImageView.frame.size.width, height: arrowImageView.frame.size.height))
        }

        subtitleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setImage(urlString: String, placeholder: UIImage) {
        guard let url = URL(string: urlString) else {
            self.avatarImageView.image = placeholder
            return
        }
        self.avatarImageView.kf.setImage(with: url,
                                         placeholder: placeholder)
    }
}

extension NativeSwitchUserTableViewCell {
    fileprivate struct Layout {
        static let verticalSpace: CGFloat = 15
        static let titileFontSize: CGFloat = 16
        static let subtitleFontSize: CGFloat = 14
        static let avatarWidth: CGFloat = 42
        static let tagItemSpace: CGFloat = 12
        static let tagHeight: CGFloat = 14
        static let nameHeight: CGFloat = 24
        static let tenantHeight: CGFloat = 20
        static let disableLabelLeft: CGFloat = 4
        static let shadowHeight: CGFloat = 2.0
        static let arrowHeight: CGFloat = 24.0
    }
}

