//
//  CategoryAdminInfoView.swift
//  Moment
//
//  Created by bytedance on 2021/9/15.
//

import Foundation
import UIKit
import LarkBizAvatar
import AvatarComponent
final class CategoryAdminInfoContainerView: UIView {
    private let lineHeight: CGFloat = 20
    private let lineSpace: CGFloat = 2
    private let itemSpace: CGFloat = 8

    private let onAvatarTapped: ((MomentUser) -> Void)
    var layoutChangeCallBack: (() -> Void)?
    var data: [MomentUser]? {
        didSet {
            setupView()
            updateUI()
        }
    }

    lazy var label: CategoryAdminLabel = {
        let label = CategoryAdminLabel(frame: .zero)
        label.frame = CGRect(x: 0, y: 0, width: label.suggestedWidth, height: lineHeight)
        return label
    }()
    var adminInfoViews = [CategoryAdminInfoView]()
    init(frame: CGRect, onAvatarTapped: @escaping ((MomentUser) -> Void)) {
        self.onAvatarTapped = onAvatarTapped
        super.init(frame: frame)
        addSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func layoutSubviews() {
        super.layoutSubviews()
        updateUI()
        layoutChangeCallBack?()
    }
    func setupView() {
        guard let data = data else {
            return
        }
        for view in adminInfoViews where view.superview != nil {
            view.removeFromSuperview()
        }
        adminInfoViews.removeAll()
        for item in data {
            let view = CategoryAdminInfoView(frame: .zero, onAvatarTapped: onAvatarTapped)
            view.item = item
            adminInfoViews.append(view)
            addSubview(view)
        }
    }
    func updateUI() {
        if bounds.width <= 0 {
            return
        }
        var lines: CGFloat = 0
        //当前布局的行 已经占用的宽度
        var currentTotalWidth: CGFloat = label.suggestedWidth + itemSpace
        for view in adminInfoViews {
            let viewWidth = min(view.suggestedWidth, bounds.width)
            if currentTotalWidth + viewWidth > bounds.width {
                currentTotalWidth = 0
                lines += 1
            }
            view.frame = CGRect(x: currentTotalWidth, y: (lineHeight + lineSpace) * lines, width: viewWidth, height: lineHeight)
            currentTotalWidth += viewWidth + itemSpace
        }
    }
}

final class CategoryAdminInfoView: UIView {
    private let onAvatarTapped: ((MomentUser) -> Void)
    init(frame: CGRect, onAvatarTapped: @escaping ((MomentUser) -> Void)) {
        self.onAvatarTapped = onAvatarTapped
        super.init(frame: frame)
        setupView()
    }
    private(set) var suggestedWidth: CGFloat = 0
    var item: MomentUser? {
        didSet {
            updateUI()
        }
    }
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        label.font = UIFont.systemFont(ofSize: 12)
        label.backgroundColor = .clear
        return label
    }()
    private lazy var avatar: BizAvatar = {
        let view = BizAvatar()
        let config = AvatarComponentUIConfig(style: .circle)
        view.setAvatarUIConfig(config)
        return view
    }()
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func setupView() {
        lu.addTapGestureRecognizer(action: #selector(tapEvent))
        addSubview(avatar)
        addSubview(titleLabel)
        avatar.snp.makeConstraints { make in
            make.width.height.equalTo(14)
            make.left.centerY.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(avatar.snp.right).offset(4)
            make.right.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }
    private func updateUI() {
        guard let item = item else {
            return
        }
        titleLabel.text = item.displayName
        self.avatar.setAvatarByIdentifier(item.userID, avatarKey: item.avatarKey, scene: .Moments)
        calculateWidth()
    }

    private func calculateWidth() {
        guard let item = item else {
            return
        }
        let labelWidth = MomentsDataConverter.widthForString(item.displayName, font: titleLabel.font)
        suggestedWidth = labelWidth + 14 + 4
    }
    @objc
    private func tapEvent() {
        guard let item = item else {
            return
        }
        self.onAvatarTapped(item)
    }
}

final class CategoryAdminLabel: UILabel {
    var suggestedWidth: CGFloat = 0
    override init(frame: CGRect) {
        super.init(frame: frame)
        textColor = UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.8)
        font = UIFont.systemFont(ofSize: 12)
        text = BundleI18n.Moment.Lark_Moments_Administrator
        backgroundColor = .clear
        suggestedWidth = MomentsDataConverter.widthForString(text ?? "", font: font)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
