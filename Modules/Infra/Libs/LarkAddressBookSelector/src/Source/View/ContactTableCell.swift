//
//  ContactTableCell.swift
//  LarkAddressBookSelector
//
//  Created by zhenning on 2020/4/27.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa
import LarkUIKit
import UniverseDesignTag
import UniverseDesignColor

final class ContactTableCell: UITableViewCell {

    var cellViewModel: ContactCellViewModel? {
        didSet {
            if let viewModel = cellViewModel {
                self.updateCell(viewModel: viewModel)
            }
        }
    }
    private lazy var checkBox: Checkbox = {
        let box = Checkbox()
        box.onCheckColor = UIColor.ud.primaryOnPrimaryFill
        box.onFillColor = UIColor.ud.primaryContentDefault
        box.strokeColor = UIColor.ud.N500
        box.lineWidth = 1.5
        box.isUserInteractionEnabled = false
        return box
    }()
    private lazy var gradientThumbnailContainer: UIView = {
        let view = UIView(frame: .zero)
        view.layer.addSublayer(self.gradientLayer)
        view.layer.cornerRadius = 24
        view.layer.masksToBounds = true
        return view
    }()
    private lazy var gradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = .zero
        gradientLayer.colors = [UIColor.ud.color(97, 150, 255).cgColor, UIColor.ud.color(64, 127, 255).cgColor]
        return gradientLayer
    }()
    private lazy var profileThumbnailView: UILabel = {
        let view = UILabel(frame: .zero)
        view.backgroundColor = UIColor.clear
        view.textAlignment = NSTextAlignment.center
        view.textColor = UIColor.white
        view.font = UIFont.boldSystemFont(ofSize: 19.5)
        return view
    }()
    private lazy var profileThumbnailImageView: UIImageView = {
        let view = UIImageView(frame: .zero)
        view.layer.cornerRadius = 24
        view.layer.masksToBounds = true
        view.isHidden = true
        return view
    }()
    private lazy var nameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()
    private lazy var subTitleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = NSTextAlignment.left
        label.lineBreakMode = NSLineBreakMode.byTruncatingTail
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    private lazy var tagView: UDTag = {
        let tagView = UDTag(text: "",
                            textConfig: UDTagConfig.TextConfig(padding: UIEdgeInsets(top: 1,
                                                                                     left: 5,
                                                                                     bottom: 1,
                                                                                     right: 5),
                                                               font: .systemFont(ofSize: 11),
                                                               cornerRadius: 2,
                                                               textAlignment: .center,
                                                               textColor: UIColor.ud.udtokenTagTextSBlue,
                                                               backgroundColor: UIColor.ud.udtokenTagBgBlue,
                                                               height: 16))
        tagView.isHidden = true
        return tagView
    }()
    private var textRightConstraint: SnapKit.Constraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        if Display.pad {
            // iPad 因为有键盘选中需求，所以要加上选中样式
            selectedBackgroundView = BaseCellSelectView()
        } else {
            // UI 交互规范的结果是因为有勾选按钮，所以去掉选中样式
            self.selectionStyle = .none
        }
        self.layoutCellSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateCell(viewModel: ContactCellViewModel) {
        let contact = viewModel.contact
        self.checkBox.isHidden = (viewModel.contactSelectType == .single)
        self.checkBox.snp.updateConstraints { (make) in
            make.left.width.height.equalTo(viewModel.contactSelectType == .single ? 0 : 18)
        }
        let enabled = !viewModel.blocked
        self.checkBox.offFillColor = enabled ? UIColor.clear : UIColor.ud.N200
        self.checkBox.strokeColor = enabled ? UIColor.ud.N500 : UIColor.ud.N400
        self.checkBox.setOn(on: viewModel.selected)
        self.nameLabel.text = contact.fullName
        self.subTitleLabel.text = viewModel.content
        if let tagData = viewModel.contactTag, case .text(var config) = tagView.config {
            config.backgroundColor = tagData.backgroundColor
            config.font = tagData.font
            config.textColor = tagData.textColor
            tagView.updateUI(textConfig: config)
            tagView.isHidden = false
            tagView.text = tagData.tagContent
        } else {
            tagView.isHidden = true
            tagView.text = nil
        }
        switch viewModel.profileType {
        case .image:
            self.profileThumbnailImageView.image = contact.thumbnailProfileImage
            self.profileThumbnailImageView.isHidden = false
            self.gradientThumbnailContainer.isHidden = true
        case .text:
            self.profileThumbnailView.text = contact.pinyinHead
            self.gradientThumbnailContainer.isHidden = false
            self.profileThumbnailImageView.isHidden = true
        }
        // 更新约束
        updateLayout()
    }

    private func layoutCellSubviews() {
        self.contentView.backgroundColor = UIColor.ud.bgBody
        self.contentView.addSubview(self.checkBox)
        self.contentView.addSubview(self.gradientThumbnailContainer)
        self.gradientThumbnailContainer.addSubview(self.profileThumbnailView)
        self.contentView.addSubview(self.profileThumbnailImageView)
        self.contentView.addSubview(self.nameLabel)
        self.contentView.addSubview(self.subTitleLabel)
        self.contentView.addSubview(self.tagView)

        self.checkBox.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(Layout.horizontalMargin)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(18)
        }
        self.gradientThumbnailContainer.snp.makeConstraints { (make) in
            make.left.equalTo(self.checkBox.snp.right).offset(Layout.horizontalMargin)
            make.width.height.equalTo(48)
            make.centerY.equalToSuperview()
        }
        self.profileThumbnailView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.profileThumbnailImageView.snp.makeConstraints { (make) in
            make.left.equalTo(self.checkBox.snp.right).offset(Layout.horizontalMargin)
            make.width.height.equalTo(48)
            make.centerY.equalToSuperview()
        }
        self.nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.profileThumbnailView.snp.right).offset(12)
            make.top.equalToSuperview().offset(12)
            make.bottom.equalTo(self.profileThumbnailView.snp.centerY)
            make.right.equalToSuperview().offset(-16)
        }
        self.subTitleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.nameLabel)
            make.top.equalTo(self.nameLabel.snp.bottom)
            make.bottom.equalToSuperview().offset(-12)
            self.textRightConstraint = make.right.equalToSuperview().offset(-Layout.horizontalMargin).constraint
        }
        self.tagView.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-Layout.horizontalMargin)
            make.centerY.equalToSuperview()
        }

        self.layoutIfNeeded()
        self.gradientLayer.frame = self.profileThumbnailView.bounds
    }

    private func updateLayout() {
        if tagView.isHidden {
            self.nameLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(self.profileThumbnailView.snp.right).offset(12)
                make.top.equalToSuperview().offset(12)
                make.bottom.equalTo(self.profileThumbnailView.snp.centerY)
                make.right.equalToSuperview().offset(-Layout.horizontalMargin)
            }
            self.subTitleLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(self.nameLabel)
                make.top.equalTo(self.nameLabel.snp.bottom)
                make.bottom.equalToSuperview().offset(-12)
                make.right.equalToSuperview().offset(-Layout.horizontalMargin)
            }
        } else {
            self.nameLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(self.profileThumbnailView.snp.right).offset(12)
                make.top.equalToSuperview().offset(12)
                make.bottom.equalTo(self.profileThumbnailView.snp.centerY)
                make.right.equalTo(self.tagView.snp.left).offset(-Layout.horizontalMargin)
            }
            self.subTitleLabel.snp.remakeConstraints { (make) in
                make.left.equalTo(self.nameLabel)
                make.top.equalTo(self.nameLabel.snp.bottom)
                make.bottom.equalToSuperview().offset(-12)
                make.right.equalTo(self.tagView.snp.left).offset(-Layout.horizontalMargin)
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.checkBox.setOn(on: false, animated: false)
        self.profileThumbnailImageView.isHidden = true
        self.gradientThumbnailContainer.isHidden = true
    }
}

extension ContactTableCell {
    enum Layout {
        static let horizontalMargin: CGFloat = 16
        static let tagMargin: CGFloat = 8
    }
}
