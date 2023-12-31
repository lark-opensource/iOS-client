//
//  GroupGuideActionButton.swift
//  LarkMessageCore
//
//  Created by Zigeng on 2022/11/2.
//

import UIKit
import Foundation
import AsyncComponent
import LarkUIKit
import ByteWebImage
import UniverseDesignTheme

final class GroupGuideActionButtonComponent<C: AsyncComponent.Context>: ASComponent<GroupGuideActionButtonComponent.Props, EmptyState, GroupGuideActionButton, C> {
    final class Props: ASComponentProps {
        let lmIcon: ImagePassThrough
        let dmIcon: ImagePassThrough
        let title: String
        let onTapped: GroupGuideActionButton.TapCallback
        let hitTestEdgeInsets: UIEdgeInsets = UIEdgeInsets(top: -9, left: -9, bottom: -9, right: -9)

        init() {
            self.lmIcon = ImagePassThrough()
            self.dmIcon = ImagePassThrough()
            self.title = ""
            self.onTapped = {}
        }

        init(text: String,
             lmIcon: ImagePassThrough,
             dmIcon: ImagePassThrough,
             onTapped: @escaping GroupGuideActionButton.TapCallback) {
            self.lmIcon = lmIcon
            self.dmIcon = dmIcon
            self.title = text
            self.onTapped = onTapped
        }
    }

    override var isSelfSizing: Bool {
        return true
    }

    override var isComplex: Bool {
        return true
    }

    public override func create(_ rect: CGRect) -> GroupGuideActionButton {
        return GroupGuideActionButton(frame: rect)
    }

    override func update(view: GroupGuideActionButton) {
        super.update(view: view)
        view.backgroundColor = UIColor.ud.bgBody
        view.update(title: props.title, lmIcon: props.lmIcon, dmIcon: props.dmIcon, onTapped: props.onTapped)
        view.hitTestEdgeInsets = props.hitTestEdgeInsets
    }
}

public final class GroupGuideActionButton: UIControl {
    public typealias TapCallback = (() -> Void)

    private lazy var icon: UIImageView = {
        let icon = UIImageView(frame: .zero)
        return icon
    }()

    private lazy var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 1
        /// 这里只展示一行，尽可能多的展示内容
        // swiftlint:disable ban_linebreak_byChar
        label.lineBreakMode = .byCharWrapping
        // swiftlint:enable ban_linebreak_byChar
        label.textColor = GroupGuideConfig.buttonTextColor
        label.font = GroupGuideConfig.buttonTextFont
        return label
    }()

    private var onTapped: TapCallback?

    private let layoutGuide = UILayoutGuide()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(icon)
        self.addSubview(label)
        self.addLayoutGuide(layoutGuide)
        layout()
        addTarget(self, action: #selector(selfTapped), for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var isDarkMode: Bool {
        if #available(iOS 13.0, *) {
            return UDThemeManager.getRealUserInterfaceStyle() == .dark
        } else {
            return false
        }
    }

    public func update(title: String, lmIcon: ImagePassThrough, dmIcon: ImagePassThrough, onTapped: @escaping TapCallback) {
        self.onTapped = onTapped
        self.label.text = title
        self.label.lineBreakMode = .byTruncatingTail
        let imageKey = (self.isDarkMode ? dmIcon.key : lmIcon.key) ?? ""
        self.icon.bt.setLarkImage(
            with: .default(key: imageKey),
            passThrough: self.isDarkMode ? dmIcon : lmIcon,
            completion: { [weak self] result in
                switch result {
                case .success:
                    self?.icon.snp.updateConstraints { make in
                        make.size.equalTo(GroupGuideConfig.buttonIconSize)
                    }
                case .failure:
                    self?.icon.snp.updateConstraints { make in
                        make.size.equalTo(CGSize(width: 0, height: 0))
                    }
                }
            })
    }

    private func layout() {
        icon.snp.remakeConstraints { make in
            make.size.equalTo(GroupGuideConfig.buttonIconSize)
            make.left.equalTo(layoutGuide.snp.left).offset(GroupGuideConfig.buttonMargin)
            make.centerY.equalToSuperview()
        }
        label.snp.remakeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(GroupGuideConfig.iconLabelPadding)
            make.centerY.equalToSuperview()
            make.right.equalTo(layoutGuide.snp.right).offset(-GroupGuideConfig.buttonMargin)
        }
        layoutGuide.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.left.greaterThanOrEqualToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @objc
    private func selfTapped() {
        self.onTapped?()
    }
}
