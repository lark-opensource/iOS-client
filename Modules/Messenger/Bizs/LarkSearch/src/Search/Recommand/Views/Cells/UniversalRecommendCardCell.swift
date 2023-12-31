//
//  UniversalRecommendCardCell.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/19.
//

import UIKit
import Foundation
import LarkBizAvatar
import AvatarComponent
import FigmaKit
import LarkSearchCore
import LarkListItem
import LarkAccountInterface

final class UniversalRecommendCardCell: UITableViewCell, SearchCellProtocol {
    var didSelectItem: ((Int) -> Void)?

    private lazy var stackView: UIStackView = buildStackView()

    static var cellHeight: CGFloat {
        return 74 + 12 // 74 是卡片高度， 12是卡片间距
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        selectionStyle = .none
        backgroundColor = nil
        backgroundView = UIView()
        contentView.backgroundColor = UIColor.ud.bgBody
    }

    func setup(withViewModel viewModel: SearchCellPresentable, currentAccount: User?) {
        guard let vm = viewModel as? UniversalRecommendCardCellPresentable else { return }
        didSelectItem = vm.didSelectItem
        for index in 0 ..< vm.items.count {
            let item = vm.items[index]
            let view = ItemView(title: item.title,
                                avatarId: item.avatarId,
                                avatarKey: item.avatarKey,
                                iconStyle: vm.iconStyle,
                                index: index)
            view.didSelectItem = didSelectItem
            stackView.addArrangedSubview(view)
        }

        if vm.items.count < vm.totalItems {
            for _ in vm.items.count ..< vm.totalItems {
                stackView.addArrangedSubview(UIView())
            }
        }
        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(12)
        }
    }

    private func buildStackView() -> UIStackView {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fillEqually
        return view
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stackView.removeFromSuperview()
        stackView = buildStackView()
    }

    @objc
    private func touch(item: UIView) {
    }

}

extension UniversalRecommendCardCell {
    enum FoldType {
        case none, fold, unfold
    }

    final class ItemView: NiblessView {
        var didSelectItem: ((Int) -> Void)?

        private lazy var button: UIButton = {
            let button = UIButton(type: .system)
            button.backgroundColor = .clear
            button.addTarget(self, action: #selector(touchItem), for: .touchUpInside)
            button.addTarget(self, action: #selector(touchDown), for: .touchDown)
            button.addTarget(self, action: #selector(touchUpOutside), for: .touchUpOutside)
            return button
        }()

        private lazy var iconView: BizAvatar = {
            var config = AvatarComponentUIConfig()
            let view = BizAvatar()
            config.style = .square
            view.layer.masksToBounds = true
            view.isUserInteractionEnabled = false
            view.setAvatarByIdentifier(avatarId, avatarKey: avatarKey)
            view.setAvatarUIConfig(config)
            return view
        }()

        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.attributedText = SearchAttributeString(searchHighlightedString: title).attributeText
            label.font = .systemFont(ofSize: 12)
            label.textColor = .ud.textCaption
            label.numberOfLines = 1
            label.isUserInteractionEnabled = false
            label.textAlignment = .center
            return label
        }()

        private let title: String
        private let avatarId: String
        private let avatarKey: String
        private let iconStyle: UniversalRecommend.IconStyle
        let index: Int

        init(title: String, avatarId: String, avatarKey: String, iconStyle: UniversalRecommend.IconStyle, index: Int) {
            self.title = title
            self.avatarId = avatarId
            self.avatarKey = avatarKey
            self.iconStyle = iconStyle
            self.index = index
            super.init(frame: .zero)

            setupView()
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            if iconView.frame.height > frame.height * 0.65 {
                iconView.snp.remakeConstraints { make in
                    make.height.equalToSuperview().multipliedBy(0.65)
                    make.width.equalTo(iconView.snp.height)
                    make.top.equalToSuperview()
                    make.centerX.equalToSuperview()
                }
            }

            switch iconStyle {
            case .circle:
                iconView.layer.borderWidth = 1 / UIScreen.main.scale
                iconView.layer.borderColor = UIColor.ud.N900.withAlphaComponent(0.15).cgColor
                iconView.layer.cornerRadius = iconView.frame.height / 2
            case .rectangle:
                iconView.layer.ux.setSmoothCorner(
                  radius: 12,
                  corners: .allCorners,
                  smoothness: .max
                )
                iconView.layer.ux.setSmoothBorder(width: 1 / UIScreen.main.scale, color: UIColor.ud.N900.withAlphaComponent(0.15))
            case .noQuery:
                break
            }
        }

        @objc
        private func touchItem() {
            alpha = 1
            didSelectItem?(index)
        }

        @objc
        private func touchDown() {
            alpha = 0.75
        }

        @objc
        private func touchUpOutside() {
            alpha = 1
        }

        private func setupView() {
            backgroundColor = .ud.bgBody

            addSubview(button)
            addSubview(iconView)
            addSubview(titleLabel)

            button.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            iconView.snp.makeConstraints { make in
                make.width.equalToSuperview().multipliedBy(0.6)
                make.height.equalTo(iconView.snp.width)
                make.top.equalToSuperview()
                make.centerX.equalToSuperview()
            }

            titleLabel.snp.makeConstraints { make in
                make.left.right.bottom.equalToSuperview()
            }
        }

        struct UIConfig {
            static var titleLabelTopPadding: CGFloat { return 8 }
            static var cornerRadius: CGFloat { return 6 }
        }
    }
}
