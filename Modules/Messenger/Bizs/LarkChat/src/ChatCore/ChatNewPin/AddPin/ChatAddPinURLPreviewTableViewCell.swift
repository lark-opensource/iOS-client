//
//  ChatAddPinURLPreviewTableViewCell.swift
//  LarkChat
//
//  Created by zhaojiachen on 2023/6/5.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignCheckBox
import UniverseDesignLoading

final class ChatAddPinURLPreviewTableViewCell: UITableViewCell {

    static var reuseIdentifier: String { return String(describing: ChatAddPinURLPreviewTableViewCell.self) }

    private lazy var bgView: UIView = {
        let bgView = UIView()
        bgView.backgroundColor = UIColor.ud.bgBody
        bgView.layer.cornerRadius = 12
        return bgView
    }()

    lazy var containerView: UIView = {
        let containerView = UIView()
        return containerView
    }()

    private lazy var editButton: ExpandEditButton = {
        let moreButton = ExpandEditButton()
        moreButton.setBackgroundImage(UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.iconN3), for: .normal)
        moreButton.setBackgroundImage(UDIcon.getIconByKey(.editOutlined, size: CGSize(width: 18, height: 18)).ud.withTintColor(UIColor.ud.iconN3), for: .highlighted)
        moreButton.addTarget(self, action: #selector(clickEdit(_:)), for: .touchUpInside)
        return moreButton
    }()

    private class ExpandEditButton: UIButton {
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
            let relativeFrame = self.bounds
            let hitFrame = relativeFrame.inset(by: UIEdgeInsets(top: -16, left: -16, bottom: -16, right: -16))
            return hitFrame.contains(point)
        }
    }

    private var editHandler: (() -> Void)?
    private var toggleCheckStatus: (() -> Bool)?

    private lazy var checkBox: UDCheckBox = {
        let checkBox = UDCheckBox(boxType: .multiple)
        checkBox.tapCallBack = { [weak self] _ in
            self?.check()
        }
        checkBox.respondsToUserInteractionWhenDisabled = true
        return checkBox
    }()

    private var isSkeleton: Bool = false
    private lazy var skeletonView: UIView = {
        let skeletonView = UIView()
        skeletonView.layer.masksToBounds = true
        skeletonView.layer.cornerRadius = 8
        return skeletonView
    }()

    private var tapIdentify: String?
    var canHandleEvent: Bool {
        self.tapIdentify == self.previewToken
    }
    private var previewToken: String?

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(check))
        titleLabel.addGestureRecognizer(tapGesture)
        return titleLabel
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UIColor.clear
        self.selectionStyle = .none
        self.contentView.addSubview(bgView)
        bgView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(ChatAddPinURLPreviewCellUIConfig.bgHorizontalMargin)
            make.top.bottom.equalToSuperview().inset(8)
        }

        bgView.addSubview(checkBox)
        bgView.addSubview(titleLabel)
        bgView.addSubview(editButton)
        bgView.addSubview(containerView)
        bgView.addSubview(skeletonView)
        checkBox.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.equalToSuperview().inset(14)
            make.size.equalTo(20)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(checkBox.snp.right).offset(12)
            make.centerY.equalTo(checkBox)
            make.right.lessThanOrEqualTo(editButton.snp.left).offset(-12)
        }
        editButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.size.equalTo(20)
            make.centerY.equalTo(checkBox)
        }
        containerView.snp.makeConstraints { make in
            make.right.left.equalToSuperview().inset(ChatAddPinURLPreviewCellUIConfig.containerHorizontalMargin)
            make.top.equalTo(checkBox.snp.bottom).offset(14)
            make.height.equalTo(0)
        }
        skeletonView.snp.makeConstraints { make in
            make.right.left.equalToSuperview().inset(16)
            make.top.equalTo(checkBox.snp.bottom).offset(14)
            make.height.equalTo(ChatAddPinURLPreviewCellUIConfig.skeletonHieght)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if isSkeleton {
            skeletonView.isHidden = false
            skeletonView.layoutIfNeeded()
            skeletonView.showUDSkeleton()
        } else {
            skeletonView.isHidden = true
            skeletonView.hideUDSkeleton()
        }
    }

    func set(title: String,
             selected: Bool,
             disabelCheck: Bool,
             isSkeleton: Bool,
             toggleCheckStatus: @escaping () -> Bool,
             editHandler: @escaping () -> Void,
             previewToken: String) {
        self.titleLabel.text = title
        self.checkBox.isEnabled = !disabelCheck
        self.checkBox.isSelected = selected
        self.isSkeleton = isSkeleton
        self.toggleCheckStatus = toggleCheckStatus
        self.editHandler = editHandler
        self.previewToken = previewToken
    }

    @objc
    private func clickEdit(_ button: UIButton) {
        guard canHandleEvent else { return }
        self.editHandler?()
    }

    @objc
    private func check() {
        guard canHandleEvent else { return }
        self.checkBox.isSelected = self.toggleCheckStatus?() ?? false
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        if view != nil {
            self.tapIdentify = self.previewToken
        }
        return view
    }

}

struct ChatAddPinURLPreviewCellUIConfig {
    static let skeletonHieght: CGFloat = 175
    static let bgHorizontalMargin: CGFloat = 16
    static let containerHorizontalMargin: CGFloat = 16
    static var contentHorizontalMargin: CGFloat {
        return containerHorizontalMargin * 2 + bgHorizontalMargin * 2
    }
}
