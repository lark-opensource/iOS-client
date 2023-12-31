//
//  MentionItemCell.swift
//  LarkMention
//
//  Created by Yuri on 2022/5/30.
//

import Foundation
import UIKit
import LarkUIKit
import SnapKit
import UniverseDesignLoading
import UniverseDesignIcon
import UniverseDesignCheckBox
import LarkTag
import LarkFeatureGating

final class MentionItemCell: UITableViewCell {
    
    private let horizontalStackView = UIStackView()
    private let verticalStackView = UIStackView()
    private let skeletonStackView = UIStackView()
    private var avatarView = MentionAvatarView()
    private let descLabel = UILabel()
    private var organizationTag = TagWrapperView()
    
    private var nameSkeletonView = UIView()
    private let descSkeletonView = UIView()
    
    private let nameContentView = MentionNameStatusView()
    @FeatureGating("arch.user.organizationnametag") private var organizationTagFG: Bool
    
    let checkBox = UDCheckBox(boxType: .multiple)
    var isSkeleton: Bool = false {
        didSet {
            isSkeleton ? showSkeleton() : hideSkeleton()
        }
    }
    
    var item: PickerOptionType? {
        didSet {
            guard var item = item else { return }
            let isEnableMultiChanged = item.isEnableMultipleSelect != oldValue?.isEnableMultipleSelect
            let isSelectChanged = item.isMultipleSelected != oldValue?.isMultipleSelected
            if isEnableMultiChanged || isSelectChanged {
                updateCheckBox(item.isEnableMultipleSelect)
            }
            if item.avatarID != oldValue?.avatarID {
                avatarView.setAvatarBy(by: item.avatarID ?? "",
                                       avatarKey: item.avatarKey ?? "")
            }
            
            // 为文档设置不一样的图标
            if case .doc(let meta) = item.meta {
                avatarView.setAvatarImage(image: meta.image)
            }
            if case .wiki(let meta) = item.meta {
                avatarView.setAvatarImage(image: meta.image)
            }
            if organizationTagFG {
                addTagOrDescLabel(by: item)
                item = removeExternalTag(by: item)
            } else {
                addDescLabel(by: item)
            }
            nameContentView.update(item: item)
        }
    }
    
    private func addTagOrDescLabel(by item: PickerOptionType) {
        if let tags = item.tags, tags.contains(.external),
            item.type == .chatter {
            verticalStackView.removeArrangedSubview(descLabel)
            descLabel.removeFromSuperview()
            if organizationTag.superview == nil {
                verticalStackView.addArrangedSubview(organizationTag)
            }
            if let desc = item.desc, !desc.string.isEmpty {
                organizationTag.setElements([Tag(title: item.desc?.string, style: .blue, type: .organization, size: .mini)])
            } else {
                organizationTag.setElements([Tag(type: .organization, style: .blue, size: .mini)])
            }
        } else {
            verticalStackView.removeArrangedSubview(organizationTag)
            organizationTag.removeFromSuperview()
            if let desc = item.desc, !desc.string.isEmpty {
                if descLabel.superview == nil {
                    verticalStackView.addArrangedSubview(descLabel)
                }
                descLabel.attributedText = item.desc
            } else {
                verticalStackView.removeArrangedSubview(descLabel)
                descLabel.removeFromSuperview()
            }
        }
    }
    
    private func addDescLabel(by item: PickerOptionType) {
        if let desc = item.desc, !desc.string.isEmpty {
            if descLabel.superview == nil {
                verticalStackView.addArrangedSubview(descLabel)
            }
            descLabel.attributedText = item.desc
        } else {
            verticalStackView.removeArrangedSubview(descLabel)
            descLabel.removeFromSuperview()
        }
    }
    
    private func removeExternalTag(by item: PickerOptionType) -> PickerOptionType {
        var item = item
        if var tags = item.tags, item.type == .chatter,
           let index = tags.firstIndex(of: .external) {
            tags.remove(at: index)
            item.tags = tags
        }
        return item
    }
    
    private func updateCheckBox(_ isEnableMultipleSelect: Bool) {
        checkBox.removeFromSuperview()
        horizontalStackView.removeArrangedSubview(checkBox)
        if isEnableMultipleSelect {
            horizontalStackView.insertArrangedSubview(checkBox, at: 0)
            guard let item = item else { return }
            checkBox.isSelected = item.isMultipleSelected
        }
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
        setupAvatarStack()
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
    }
    
    private func setupAvatarStack() {
        horizontalStackView.axis = .horizontal
        horizontalStackView.alignment = .center
        horizontalStackView.distribution = .fill
        horizontalStackView.spacing = 12
        contentView.addSubview(horizontalStackView)
        horizontalStackView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.bottom.equalToSuperview()
        }
        
        checkBox.isUserInteractionEnabled = false
        checkBox.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 20, height: 20))
        }
        
        avatarView.layer.cornerRadius = 18
        avatarView.clipsToBounds = true
        avatarView.snp.makeConstraints {
            $0.size.equalTo(CGSize(width: 36, height: 36))
        }
        avatarView.setAvatarBy(by: "", avatarKey: "")
        horizontalStackView.addArrangedSubview(avatarView)
        
        verticalStackView.axis = .vertical
        verticalStackView.alignment = .leading
        verticalStackView.distribution = .equalSpacing
        verticalStackView.spacing = 0
        horizontalStackView.addArrangedSubview(verticalStackView)
        
        skeletonStackView.axis = .vertical
        skeletonStackView.alignment = .leading
        skeletonStackView.distribution = .equalSpacing
        skeletonStackView.spacing = 10
        contentView.addSubview(skeletonStackView)
        skeletonStackView.snp.makeConstraints {
            $0.leading.equalTo(verticalStackView)
            $0.centerY.equalTo(verticalStackView)
        }
    }
    
    private func setupContentStack() {
        verticalStackView.addArrangedSubview(nameContentView)
        nameContentView.snp.makeConstraints {
            $0.height.equalTo(22)
        }
        
        descLabel.textColor = UIColor.ud.textPlaceholder
        descLabel.font = UIFont.systemFont(ofSize: 12)
        verticalStackView.addArrangedSubview(descLabel)
        descLabel.snp.makeConstraints {
            $0.height.equalTo(18)
        }
        organizationTag.snp.makeConstraints {
            $0.height.equalTo(18)
        }
    }
    
    private func setupSkeletonView() {
        nameSkeletonView = UIView()
        nameSkeletonView.layer.cornerRadius = 4
        nameSkeletonView.clipsToBounds = true
        skeletonStackView.addArrangedSubview(nameSkeletonView)
        nameSkeletonView.snp.makeConstraints {
            $0.height.equalTo(12)
            $0.width.equalTo(84)
        }
        
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
    }
    
    func hideSkeleton() {
        avatarView.hideUDSkeleton()
        nameSkeletonView.hideUDSkeleton()
        descSkeletonView.hideUDSkeleton()
    }
    
    // dark mode
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard #available(iOS 13.0, *) else { return }
        guard self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        guard self.isSkeleton else { return }
        hideSkeleton()
        showSkeleton()
    }
}
