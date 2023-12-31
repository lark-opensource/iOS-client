//
//  FromCategoryBar.swift
//  Moment
//
//  Created by bytedance on 2021/8/11.
//

import UIKit
import Foundation
import AvatarComponent
import LarkBizAvatar

final class FromCategoryBar: UIControl {
    class func sizeToFit(iconWidth: CGFloat, title: String, titleFont: UIFont, iconKey: String, enable: Bool) -> CGSize {
        let labelWidth = MomentsDataConverter.widthForString(title, font: titleFont)
        let spaceAndLabelRightMargin: CGFloat = enable ? 8 + 20 : 8 + 8
        let width = iconWidth + labelWidth + spaceAndLabelRightMargin
        let height = title.isEmpty && iconKey.isEmpty ? 0 : iconWidth
        return CGSize(width: width, height: height)
    }

    private let iconWidth: CGFloat
    var onTapped: (() -> Void)?
    private let backgroundColorNormal: UIColor
    private let backgroundColorPress: UIColor

    private lazy var icon: BizAvatar = {
        let view = BizAvatar()
        let config = AvatarComponentUIConfig(style: .square)
        view.setAvatarUIConfig(config)
        return view
    }()
    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .ud.N700
        return label
    }()

    //右侧的小三角
    private lazy var actionArrow: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = Resources.rightArrowFilled.withRenderingMode(.alwaysTemplate)
        view.tintColor = .ud.iconN2
        return view
    }()

    init(frame: CGRect, iconWidth: CGFloat,
         backgroundColorNormal: UIColor, backgroundColorPress: UIColor) {
        self.iconWidth = iconWidth
        self.backgroundColorNormal = backgroundColorNormal
        self.backgroundColorPress = backgroundColorPress
        super.init(frame: frame)
        self.backgroundColor = backgroundColorNormal
        clipsToBounds = true
        setupView()
        self.addTarget(self, action: #selector(selfTapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(icon)
        icon.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.width.height.equalTo(iconWidth)
        }
        addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(8)
            make.centerY.equalToSuperview()
        }
        addSubview(actionArrow)
        actionArrow.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-8)
            make.centerY.equalToSuperview()
            make.height.equalTo(8)
            make.width.equalTo(8)
        }
    }

    @objc
    private func selfTapped() {
        self.onTapped?()
    }

    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                self.backgroundColor = self.backgroundColorPress
            } else {
                self.backgroundColor = self.backgroundColorNormal
            }
        }
    }

    func update(title: String, iconKey: String, titleFont: UIFont, enable: Bool) {
        if iconKey.isEmpty && title.isEmpty {
            icon.snp.updateConstraints { make in
                make.width.height.equalTo(0)
            }
            actionArrow.isHidden = true
            return
        }
        icon.snp.updateConstraints { make in
            make.width.height.equalTo(iconWidth)
        }
        actionArrow.isHidden = !enable
        //entityID不传，版块头像不用缓存
        self.icon.setAvatarByIdentifier(MomentsGlobalConfigs.entityEmpty, avatarKey: iconKey, scene: .Moments)
        self.label.text = title
        self.label.font = titleFont
        self.label.textColor = enable ? .ud.N700 : .ud.textPlaceholder
    }
}
