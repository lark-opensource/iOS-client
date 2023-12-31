//
//  SearchTableHeaderView.swift
//  Lark
//
//  Created by 刘晚林 on 2017/3/24.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import SnapKit
import FigmaKit
import LarkSearchCore

protocol SearchHeaderProtocol: UITableViewHeaderFooterView, KeyBoardFocusable {
    func set(viewModel: SearchHeaderViewModel)
}

final class SearchTableHeaderView: UITableViewHeaderFooterView, SearchHeaderProtocol {
    var viewModel: SearchHeaderViewModel?

    private let iconView = UIImageView()
    private let actionLabel = UILabel()
    private let divider = UIView()
    fileprivate var titleLabel = UILabel()
    fileprivate var noResultTitle = UILabel()
    private let container = UIView()
    private let content = UIView()
    private let headCorner = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        headCorner.backgroundColor = UIColor.ud.bgBody
        container.backgroundColor = UIColor.ud.bgBody
        headCorner.roundCorners(corners: [.topLeft, .topRight], radius: 8.0)
        self.contentView.addSubview(headCorner)
        headCorner.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled ? 8 : 12)
        }
        contentView.clipsToBounds = true
        contentView.addSubview(container)
        container.addSubview(content)
        content.addSubview(iconView)
        content.addSubview(titleLabel)
        container.addSubview(divider)
        content.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(divider.snp.top).offset(-7)
            make.top.bottom.equalTo(titleLabel)
        }

        container.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(headCorner.snp.bottom)
        }

        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.textColor = UIColor.ud.textTitle

        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            if SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled {
                make.height.equalTo(20)
            }
            make.centerY.equalToSuperview()
        }

        divider.backgroundColor = UIColor.ud.lineDividerDefault

        divider.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(2)
            make.height.equalTo(1)
        }

        actionLabel.font = UIFont.systemFont(ofSize: 14)
        actionLabel.textColor = UIColor.ud.textLinkNormal
        content.addSubview(actionLabel)
        actionLabel.snp.makeConstraints { (make) in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalTo(titleLabel)
        }
        container.lu.addTapGestureRecognizer(action: #selector(didClickHeader), target: self)

        noResultTitle.isHidden = true
        contentView.addSubview(noResultTitle)
        noResultTitle.textColor = UIColor.ud.textDisable
        noResultTitle.font = UIFont.systemFont(ofSize: 14)
        noResultTitle.snp.makeConstraints { (make) in
            make.top.equalToSuperview().inset(53)
            make.centerX.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(viewModel: SearchHeaderViewModel) {
        self.viewModel = viewModel
        viewModel.shouldEnableActionButton = { [weak self] enableShowMore in
            self?.setActionEnable(enableShowMore)
        }
        setContent(icon: viewModel.icon,
                   title: viewModel.title,
                   label: viewModel.label,
                   actionText: viewModel.actionText,
                   titleColor: viewModel.titleColor,
                   contentConstraint: viewModel.contentConstraint)
    }

    private func setContent(avatarKey: String,
                    title: String,
                    label: String? = nil,
                    titleColor: UIColor = UIColor.ud.textTitle,
                    contentConstraint: ((ConstraintMaker) -> Void)? = nil) {
        // 暂时没有 icon 所以用不到 avatarKey/avatarId
        setContent(icon: nil, title: title, label: label, actionText: BundleI18n.LarkSearch.Lark_Legacy_LoadMore, titleColor: titleColor, contentConstraint: contentConstraint)
    }

    func setContent(icon: UIImage? = nil,
                    title: String,
                    label: String? = nil,
                    actionText: String,
                    titleColor: UIColor = UIColor.ud.textTitle,
                    contentConstraint: ((ConstraintMaker) -> Void)? = nil) {
        reset()

        if let icon = icon {
            iconView.snp.remakeConstraints { make in
                make.left.equalToSuperview().inset(16)
                make.centerY.equalToSuperview()
                make.size.equalTo(CGSize(width: 16, height: 16))
            }
            titleLabel.snp.remakeConstraints { make in
                make.left.equalTo(iconView.snp.right).offset(4)
                if SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled {
                    make.height.equalTo(20)
                }
                make.centerY.equalToSuperview()
            }
            iconView.image = icon
        }
        if title.isEmpty {
            content.isHidden = true
            divider.isHidden = true
        } else {
            content.isHidden = false
            divider.isHidden = false
            titleLabel.text = title
            titleLabel.textColor = titleColor
        }

        noResultTitle.text = label
        noResultTitle.isHidden = (label == nil)
        actionLabel.text = actionText
        if let contentConstraint = contentConstraint {
            titleLabel.snp.remakeConstraints(contentConstraint)
        }
    }

    private func reset() {
        iconView.image = nil
        iconView.snp.removeConstraints()
        titleLabel.snp.remakeConstraints { (make) in
            make.left.equalTo(16)
            if SearchFeatureGatingKey.mainTabViewMoreAdjust.isEnabled {
                make.height.equalTo(20)
            }
            make.centerY.equalToSuperview()
        }
    }

    @objc
    private func didClickHeader() {
        viewModel?.headerTappingAction(self)
    }

    private func setActionEnable(_ enable: Bool) {
        actionLabel.isHidden = !enable
        container.isUserInteractionEnabled = enable
    }

    func setFocused(_ focused: Bool, animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.25) {
                self.actionLabel.backgroundColor = focused ? UIColor.ud.fillFocus : UIColor.ud.bgBody
            }
        } else {
            actionLabel.backgroundColor = focused ? UIColor.ud.fillFocus : UIColor.ud.bgBody
        }
    }
}
