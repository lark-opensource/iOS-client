//
//  IMMentionItemCell.swift
//  LarkIMMention
//
//  Created by jiangxiangrui on 2022/7/21.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import UniverseDesignLoading
import UniverseDesignIcon
import UniverseDesignCheckBox

final class IMMentionItemCell: UITableViewCell {
    private let stackView = UIStackView()
    
    private let avatarContainer = UIStackView()
    private let mainContainer = UIStackView()
    private let contentContainer = UIStackView()
    private let accessoryContainer = UIStackView()
    
    private var avatarView = IMMentionAvatarView()
    private let descLabel = UILabel()
    private let nameContentView = IMMentionNameStatusView()
    
    private let skeletonStackView = UIStackView()
    private var nameSkeletonView = UIView()
    private let descSkeletonView = UIView()
    var showDeleteBtn = false
    
    let checkBox = UDCheckBox(boxType: .multiple)
    let deleteBtn = UIButton()
    
    var node: MentionItemNode? {
        didSet {
            guard let node = node else { return }
            if node.isMultiSelected != oldValue?.isMultiSelected {
                update(multiSelected: node.isMultiSelected)
            }
            if node.isSelected != oldValue?.isSelected {
                checkBox.isSelected = node.isSelected
            }
            if node.isSkeleton != oldValue?.isSkeleton {
                node.isSkeleton ? showSkeleton() : hideSkeleton()
            }
            switch node.avatar {
            case .remote(let id, let key):
                avatarView.setAvatarBy(by: id, avatarKey: key)
            case .local(let image):
                avatarView.setAvatar(image: image)
            case .none:
                avatarView.setAvatar(image: nil)
            }
            if node.desc != oldValue?.desc {
                update(desc: node.desc)
            }
            nameContentView.node = node
        }
    }
    
    private func update(desc: NSAttributedString?) {
        if let desc = desc, !desc.string.isEmpty { // 有值
            descLabel.isHidden = false
            descLabel.attributedText = desc
        } else {
            descLabel.isHidden = true
        }
    }
    
    private func update(multiSelected: Bool) {
        checkBox.isHidden = !multiSelected
    }
    
    // MARK: - UI
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        self.backgroundColor = UIColor.ud.bgBody
        setupSelectedViews()
        
        avatarContainer.axis = .horizontal
        avatarContainer.alignment = .center
        avatarContainer.distribution = .fill
        avatarContainer.spacing = 12
        contentView.addSubview(avatarContainer)
        avatarContainer.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.height.equalToSuperview()
        }
        
        setupAvatarStack()
        
        mainContainer.axis = .horizontal
        mainContainer.alignment = .center
        mainContainer.distribution = .fill
        mainContainer.spacing = 12
        contentView.addSubview(mainContainer)
        mainContainer.snp.makeConstraints {
            $0.leading.equalTo(avatarContainer.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().inset(16)
            $0.top.bottom.equalToSuperview()
        }
        
        contentContainer.axis = .vertical
        contentContainer.alignment = .leading
        contentContainer.distribution = .equalSpacing
        contentContainer.spacing = 0
        mainContainer.addArrangedSubview(contentContainer)
        
        accessoryContainer.axis = .horizontal
        accessoryContainer.isHidden = true
        mainContainer.addArrangedSubview(accessoryContainer)
        
        
        deleteBtn.setImage(UDIcon.getIconByKey(.closeSmallOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN3), for: .normal)
        deleteBtn.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 40, height: 40))
        }
        accessoryContainer.addArrangedSubview(deleteBtn)
        
        setupContentStack()
        setupSkeletonView()
    }
    
    // 设置选中按压时的背景视图
    private func setupSelectedViews() {
        let selectedView = UIView()
        self.selectedBackgroundView = selectedView
        self.selectedBackgroundView?.backgroundColor = UIColor.ud.fillPressed
        self.selectedBackgroundView?.layer.cornerRadius = 8
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let frame = self.contentView.frame.inset(by: UIEdgeInsets(top: 1, left: 6, bottom: 1, right: 6))
        self.selectedBackgroundView?.frame = frame
        if node?.isSkeleton == true {
            showSkeleton()
        }
    }
    
    private func setupAvatarStack() {
        checkBox.isUserInteractionEnabled = false
        checkBox.isHidden = true
        avatarContainer.addArrangedSubview(checkBox)
        checkBox.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 20, height: 20))
        }
        
        avatarView.isSkeletonable = true
        avatarView.layer.cornerRadius = 20
        avatarView.clipsToBounds = true
        avatarView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 40, height: 40))
        }
        avatarView.setContentHuggingPriority(.required, for: .horizontal)
        avatarContainer.addArrangedSubview(avatarView)
        
    }
    
    private func setupContentStack() {
        contentContainer.addArrangedSubview(nameContentView)
        nameContentView.snp.makeConstraints {
            $0.height.equalTo(22)
        }
        
        descLabel.textColor = UIColor.ud.textPlaceholder
        descLabel.font = UIFont.systemFont(ofSize: 12)
        descLabel.isHidden = true
        contentContainer.addArrangedSubview(descLabel)
        descLabel.snp.makeConstraints {
            $0.height.equalTo(18)
        }
    }
    
    private func setupSkeletonView() {
        skeletonStackView.axis = .vertical
        skeletonStackView.alignment = .leading
        skeletonStackView.distribution = .equalSpacing
        skeletonStackView.spacing = 10
        contentView.addSubview(skeletonStackView)
        skeletonStackView.snp.makeConstraints {
            $0.leading.equalTo(avatarContainer.snp.trailing).offset(12)
            $0.centerY.equalTo(contentContainer)
        }
        
        nameSkeletonView.isSkeletonable = true
        nameSkeletonView.layer.cornerRadius = 4
        nameSkeletonView.clipsToBounds = true
        skeletonStackView.addArrangedSubview(nameSkeletonView)
        nameSkeletonView.snp.makeConstraints {
            $0.height.equalTo(12)
            $0.width.equalTo(84)
        }
        
        descSkeletonView.isSkeletonable = true
        descSkeletonView.layer.cornerRadius = 4
        descSkeletonView.clipsToBounds = true
        skeletonStackView.addArrangedSubview(descSkeletonView)
        descSkeletonView.snp.makeConstraints {
            $0.width.equalTo(180)
            $0.height.equalTo(10)
        }
    }
    
    func showSkeleton() {
        contentView.layoutIfNeeded()
        avatarView.showUDSkeleton()
        nameSkeletonView.showUDSkeleton()
        descSkeletonView.showUDSkeleton()
        mainContainer.isHidden = true
        skeletonStackView.isHidden = false
    }
    
    func hideSkeleton() {
        avatarView.hideUDSkeleton()
        nameSkeletonView.hideUDSkeleton()
        descSkeletonView.hideUDSkeleton()
        mainContainer.isHidden = false
        skeletonStackView.isHidden = true
        
    }
    
    func setDeleteBtn() {
        accessoryContainer.isHidden = false
    }
    
    // dark mode
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        guard self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        guard node?.isSkeleton == true else { return }
        hideSkeleton()
        showSkeleton()
    }
}
